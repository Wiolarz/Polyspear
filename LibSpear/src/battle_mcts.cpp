#include "battle_mcts.hpp"

#include <math.h>
#include <assert.h>
#include <limits>
#include <utility>
#include <random>
#include <algorithm>
#include <numeric>
#include <thread>
#include <signal.h>
#include <chrono>

#include "BS_thread_pool.hpp"


BS::thread_pool mcts_workers;


BattleMCTSNode::BattleMCTSNode(BattleManagerFastCpp bm, BattleMCTSManager* manager, BattleMCTSNode* parent) 
    : _bm(bm),
      _manager(manager),
      _parent(parent)
{
    
}

float BattleMCTSNode::uct() const {
    const auto coeff = sqrt(2);

    if(abs(_visits) < 1e-5f) {
        // not explored, a large number to force exploring it
        // idea - dither - this + a tiny bit of pseudorandom noise to select a random node vs first/last found
        return 10000.0f;
    }
    auto parent_visits = _parent ? _parent->_visits : _visits;
    return (_reward/_visits) + coeff * sqrt(log2(parent_visits) / _visits);
}

std::pair<Move, BattleMCTSNode*> BattleMCTSNode::select() {
    if(!is_explored()) {
        return std::make_pair(Move(), nullptr);
    }

    float uct_max = -std::numeric_limits<float>::infinity();
    BattleMCTSNode* uct_max_idx = nullptr;
    Move best_move;

    for(auto& [move, node] : _children) {
        auto uct = node.uct();
        if(uct >= uct_max) {
            uct_max = uct;
            uct_max_idx = &node;
            best_move = move;
        }
    }

    return std::make_pair(best_move, uct_max_idx);
}

void BattleMCTSNode::expand() {
    if(_bm.is_battle_finished()) {
        return;
    }

    auto [move, heur_chosen] = _bm.get_random_move(_manager->heuristic_probability);

    if(_children.count(move) == 0) {
        _children.emplace(std::piecewise_construct,
                std::forward_as_tuple(move), 
                std::forward_as_tuple(_bm, _manager, this)
        );
        auto& child = _children.at(move);
        child._bm.play_move(move);
        child._mcts_iterations = _mcts_iterations;

        if(heur_chosen) {
            auto prior_reward = _mcts_iterations * float(_manager->heuristic_prior_reward_per_iteration);
            child._visits += prior_reward;
            child._reward += prior_reward;
        }
    }
}

BattleResult _simulate_thread(BattleManagerFastCpp bmnew, const BattleMCTSManager& mcts) {
    BattleResult result;
    Move move;
    int i = 0;

    do {
        move = bmnew.get_random_move(mcts.heuristic_probability).first;
        i++;
    } while((result = bmnew.play_move(move)).winner_team == -1 && i < mcts.max_sim_iterations);

    return result;
}

BattleResult BattleMCTSNode::simulate(int max_sim_iterations, int simulations) {
    BattleResult ret;

    if(_bm.is_battle_finished()) {
        return _bm.get_result();
    }

    std::vector<std::future<BattleResult>> results;

    for(int i = 0; i < simulations; i++) {
        results.push_back(mcts_workers.submit_task([*this]() {
            return _simulate_thread(_bm, *this->_manager);
        }));
    }

    for(auto& fut : results) {
        auto result = fut.get();
        for(int i = 0; i < ret.total_scores.size(); i++) {
            ret.total_scores[i] += result.total_scores[i];
            ret.max_scores[i] += result.max_scores[i];
        }
    }

    return ret;
}

void BattleMCTSNode::backpropagate(BattleResult& result, int new_visits) {
    auto current_team = _bm.get_army_team(_bm.get_previous_participant());
    auto ally_score = 0.0f, enemy_score = 0.0f;
    auto max_ally_score = 0.0f, max_enemy_score = 0.0f;

    for(int i = 0; i < result.total_scores.size(); i++) {
        if(_bm.get_army_team(i) == current_team) {
            ally_score += result.total_scores[i];
            max_ally_score += result.max_scores[i];
        }
        else {
            enemy_score += result.total_scores[i];
            max_enemy_score += result.max_scores[i];
        }
    }

    auto reward_add = (ally_score + max_enemy_score - enemy_score) / (max_ally_score+max_enemy_score); 
    // just in case
    if(reward_add < 0.0f || std::isnan(reward_add) || std::isinf(reward_add)) {
        WARN_PRINT("invalid reward");
        _reward += 0.5f;
    }
    else {
        _reward += reward_add;
    }
    _visits += new_visits;

    if(_parent) {
        _parent->backpropagate(result, new_visits);
    }
}

bool BattleMCTSNode::is_explored() {
    return _bm.get_move_count() == _children.size();
}

void BattleMCTSManager::iterate(int iterations) {
    emit_signal("_assert_params_are_set");
    root->_mcts_iterations = iterations;
    root->iterate(iterations);
    emit_signal("complete");
}

void BattleMCTSNode::iterate(int iterations) {

    auto visits = _manager->max_playouts_per_visit;
    auto begin = std::chrono::high_resolution_clock::now();

    for(int i = 0; i < iterations; i+=visits) {
        BattleMCTSNode* node = this, *temp_node;

        while((temp_node = node->select().second) != nullptr) {
            node = temp_node;
        }

        node->expand();
        BattleResult result = node->simulate(_manager->max_sim_iterations, visits);    

        node->backpropagate(result, visits);

        if(result.winner_team == _manager->army_team) {
            this->_wins++;
        }
        else if(result.winner_team == -1) {
            this->_draws++;
        }
        else {
            this->_loses++;
        }
    }
    
    auto end = std::chrono::high_resolution_clock::now();
    std::chrono::duration<float> seconds = end - begin;
    printf("Iterate finished in %fs\n", seconds.count());
}

Move BattleMCTSManager::get_optimal_move(int nth_best_move) {
    // TODO? nth best move
    
    if(nth_best_move != 0) {
        ERR_PRINT_ONCE_ED("ERROR - Nth best move is not implemented for BattleMCTSManager yet");
    }

    for(auto& [move, node] : root->_children) {
        auto& hm = root->_bm.get_heuristically_good_moves();
        bool heur_move = std::find(hm.begin(), hm.end(), move) != hm.end();
        printf("Child %c %d->%d,%d UCT=%f, R/V=%f (reward: %f, visits: %f)\n", 
                heur_move ? 'H':' ', move.unit, move.pos.x, move.pos.y, 
                node.uct(), node._reward / node._visits, node._reward, node._visits
        );
    }
    printf("%i/%i/%i\n", root->_wins, root->_draws, root->_loses);

    float max_ratio = -1.0f;
    Move chosen;

    for(auto& [move, node] : root->_children) {
        if(node._reward / node._visits > max_ratio) {
            chosen = move;
            max_ratio = node._reward / node._visits;
        }
    }

    return chosen;
}

godot::Array BattleMCTSManager::get_optimal_move_gd(int nth_best_move) {
    return get_optimal_move(nth_best_move).as_libspear_tuple();
}

void BattleMCTSManager::set_root(BattleManagerFastCpp* bm) {
    root = new BattleMCTSNode(*bm, this, nullptr);
    army_id = bm->get_current_participant();
    army_team = bm->get_army_team(army_id);
}

BattleMCTSManager::~BattleMCTSManager() {
    if(root) {
        delete root;
    }
}

void BattleMCTSManager::_bind_methods() {
    ClassDB::bind_method(D_METHOD("get_optimal_move", "nth_best_move"), &BattleMCTSManager::get_optimal_move_gd);
    ClassDB::bind_method(D_METHOD("iterate", "iterations"), &BattleMCTSManager::iterate);
    ClassDB::bind_method(D_METHOD("set_root", "battle_manager"), &BattleMCTSManager::set_root);

    ADD_SIGNAL(MethodInfo("complete"));
    ADD_SIGNAL(MethodInfo("_assert_params_are_set"));

    BIND_MCTS_PARAMETER(Variant::INT, max_sim_iterations);
    BIND_MCTS_PARAMETER(Variant::FLOAT, heuristic_probability);
    BIND_MCTS_PARAMETER(Variant::FLOAT, heuristic_prior_reward_per_iteration);
    BIND_MCTS_PARAMETER(Variant::INT, max_playouts_per_visit);
}

