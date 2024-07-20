#include "battle_mcts.hpp"

#include <math.h>
#include <assert.h>
#include <limits>
#include <utility>
#include <random>
#include <algorithm>
#include <numeric>

#include <signal.h>


BattleMCTSNode::BattleMCTSNode(BattleManagerFast bm, BattleMCTSManager* manager, BattleMCTSNode* parent) 
    : bm(bm),
      manager(manager),
      parent(parent)
{
    
}

float BattleMCTSNode::uct() const {
    const auto coeff = sqrt(2);

    if(abs(visits) < 1e-5f) {
        // not explored, a large number to force exploring it
        // idea - dither - this + a tiny bit of pseudorandom noise to select a random node vs first/last found
        return 10000.0f;
    }
    auto parent_visits = parent ? parent->visits : visits;
    return (reward/visits) + coeff * sqrt(log2(parent_visits) / visits);
}

std::pair<Move, BattleMCTSNode*> BattleMCTSNode::select() {
    if(!is_explored()) {
        return std::make_pair(Move(), nullptr);
    }

    float uct_max = -std::numeric_limits<float>::infinity();
    BattleMCTSNode* uct_max_idx = nullptr;
    Move best_move;

    for(auto& [move, node] : children) {
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
    if(bm.is_battle_finished()) {
        return;
    }
    
    auto move = bm.get_random_move(0.85f);

    if(children.count(move) == 0) {
        children.insert({move, BattleMCTSNode(bm, manager, this)});
        children.at(move).bm.play_move(move);
    }
}

BattleResult BattleMCTSNode::simulate(int max_sim_iterations) {
    BattleResult result;
    BattleManagerFast bmnew = bm;
    Move move;
    int i = 0;

    if(bm.is_battle_finished()) {
        return bm.get_result();
    }
    
    do {
        move = bmnew.get_random_move(HEURISTIC_PROBABIlITY);
        i++;
    } while((result = bmnew.play_move(move)).winner_team == -1 && i < max_sim_iterations);

    return result;
}

void BattleMCTSNode::backpropagate(BattleResult& result) {
    auto current_team = bm.get_army_team(bm.get_previous_participant());
    auto ally_score = 0.0f, enemy_score = 0.0f;

    for(int i = 0; i < result.total_scores.size(); i++) {
        if(bm.get_army_team(i) == current_team) {
            ally_score += result.total_scores[i];
        }
        else {
            enemy_score += result.total_scores[i];
        }
    }

    // there's a bug somewhere, temporary fix
    if(ally_score + enemy_score >= 0.001f) {
        reward += ally_score / (ally_score+enemy_score);
    }
    else {
        WARN_PRINT("MCTS ally_score = enemy_score = 0");
        reward += 0.5f;
    }

    if(std::isnan(reward)) {
        raise(SIGINT);
    }
    //reward += result.winner_team == current_team ? 1.0f : (result.winner_team == -1 ? 0.5f : 0.0f);
    visits += 1.0f;

    if(parent) {
        parent->backpropagate(result);
    }
}

bool BattleMCTSNode::is_explored() {
    return bm.get_move_count() == children.size();
}

void BattleMCTSManager::iterate(int iterations) {
    _iterate(iterations);
}

void BattleMCTSManager::_iterate(int iterations, int max_sim_iterations) {
    for(int i = 0; i < iterations; i++) {
        BattleMCTSNode* node = root, *temp_node;
        int tree_level = 0;
        while((temp_node = node->select().second) != nullptr) {
            node = temp_node;
            tree_level++;
        }

        node->expand();
        auto result = node->simulate(max_sim_iterations);
        node->backpropagate(result);
        
        if(result.winner_team == army_team) {
            root->wins++;
        }
        else if(result.winner_team == -1) {
            root->draws++;
        }
        else {
            root->loses++;
        }
    }
}

Move BattleMCTSManager::get_optimal_move(int nth_best_move) {
    // TODO nth best move
    
    if(nth_best_move != 0) {
        ::godot::_err_print_error(FUNCTION_STR, __FILE__, __LINE__, "ERROR - Nth best move is not implemented for BattleMCTSManager yet");
    }

    for(auto& [move, node] : root->children) {
        auto& hm = root->bm.get_heuristically_good_moves();
        bool heur_move = std::find(hm.begin(), hm.end(), move) != hm.end();
        printf("Child %c %d->%d,%d = %f (reward: %f, visits: %f, %i/%i/%i)\n", 
                heur_move ? 'H':' ', move.unit, move.pos.x, move.pos.y, node.uct(), 
                node.reward, node.visits, root->wins, root->draws, root->loses
        );
    }
    printf("\n");

    return root->select().first;
}

int BattleMCTSManager::get_optimal_move_unit(int nth_best_move) {
    return get_optimal_move(nth_best_move).unit;
}

Vector2i BattleMCTSManager::get_optimal_move_position(int nth_best_move) {
    return Vector2i(get_optimal_move(nth_best_move).pos.x, get_optimal_move(nth_best_move).pos.y);
}


void BattleMCTSManager::set_root(BattleManagerFast* bm) {
    root = new BattleMCTSNode(*bm, this, nullptr);
    army_id = bm->get_current_participant();
    army_team = bm->get_army_team(army_id);
}

// TODO apparently this crashes godot editor
/*BattleMCTSManager::~BattleMCTSManager() {
    if(root) {
        delete root;
    }
}*/

void BattleMCTSManager::_bind_methods() {
    ClassDB::bind_method(D_METHOD("get_optimal_move_unit"), &BattleMCTSManager::get_optimal_move_unit, "nth_best_move");
    ClassDB::bind_method(D_METHOD("get_optimal_move_position"), &BattleMCTSManager::get_optimal_move_position, "nth_best_move");

    ClassDB::bind_method(D_METHOD("iterate"), &BattleMCTSManager::iterate, "iterations");

    ClassDB::bind_method(D_METHOD("set_root"), &BattleMCTSManager::set_root, "battle_manager");
}

