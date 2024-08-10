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

#include "BS_thread_pool.hpp"


BS::thread_pool mcts_workers;


BattleMCTSNode::BattleMCTSNode(BattleManagerFastCpp bm, BattleMCTSManager* manager, BattleMCTSNode* parent) 
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

    //std::lock_guard lock(local_mutex);

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

    //std::lock_guard lock(local_mutex);
    
    auto [move, heur_chosen] = bm.get_random_move(HEURISTIC_PROBABILITY);

    if(children.count(move) == 0) {
        children.emplace(std::piecewise_construct,
                std::forward_as_tuple(move), 
                std::forward_as_tuple(bm, manager, this)
        );
        auto& child = children.at(move);
        child.bm.play_move(move);
        child.mcts_iterations = mcts_iterations;

        if(heur_chosen) {
            auto prior_reward = mcts_iterations * float(HEURISTIC_PRIOR_REWARD_PER_ITERATION);
            child.visits += prior_reward;
            child.reward += prior_reward;
        }
    }
}

BattleResult _simulate_thread(BattleManagerFastCpp bmnew, int max_sim_iterations) {
    BattleResult result;
    Move move;
    int i = 0;

    do {
        move = bmnew.get_random_move(HEURISTIC_PROBABILITY).first;
        i++;
    } while((result = bmnew.play_move(move)).winner_team == -1 && i < max_sim_iterations);

    return result;
}

BattleResult BattleMCTSNode::simulate(int max_sim_iterations, int simulations) {
    BattleResult ret;

    if(bm.is_battle_finished()) {
        return bm.get_result();
    }

    std::vector<std::future<BattleResult>> results;

    for(int i = 0; i < simulations; i++) {
        results.push_back(mcts_workers.submit_task([*this, max_sim_iterations]() {
            return _simulate_thread(bm, max_sim_iterations);
        }));
    }

    for(auto& fut : results) {
        auto result = fut.get();
        for(int i = 0; i < ret.total_scores.size(); i++) {
            ret.total_scores[i] += result.total_scores[i];
        }
    }

    return ret;
}

void BattleMCTSNode::backpropagate(BattleResult& result, int new_visits) {
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
        // TODO better reward maximizing enemy losses in case of failure
        reward += ally_score / (ally_score+enemy_score);
    }
    else {
        WARN_PRINT("MCTS ally_score = enemy_score = 0");
        reward += 0.5f;
    }
    //reward += result.winner_team == current_team ? 1.0f : (result.winner_team == -1 ? 0.5f : 0.0f);
    visits += new_visits;

    if(parent) {
        parent->backpropagate(result, new_visits);
    }
}

bool BattleMCTSNode::is_explored() {
    return bm.get_move_count() == children.size();
}

void BattleMCTSManager::iterate(int iterations, int max_threads) {
    root->mcts_iterations = iterations;
    root->iterate(iterations, 0);
    emit_signal("complete");
}

void BattleMCTSNode::iterate(int iterations, int depth) {

    auto tmp_parent = parent;
    parent = nullptr; // Block backpropagation during this procedure

    int burst = MAX_MCTS_BURST;
    iterate_self(iterations);
    /*
    while(iterations > 0) {
        // end of the tree
        if(bm.get_move_count() == 0) {
            break;
        }

        if(!is_explored() || depth == 0) {
            iterate_self(burst);
            iterations -= burst;
            continue;
        }

        auto next_depth = std::thread::hardware_concurrency() > children.size() ? 2 : (depth + 1);

        //std::vector<std::thread> threads;
        std::vector<std::future<void>> futures;

        // Process each subtree in a separate thread
        for(auto& [move, node] : children) {
            auto next_burst = (next_depth == 1 && node.is_explored()) ? burst * node.children.size() : burst;
            threads.emplace_back([&]() {
            //futures.emplace_back(
                //mcts_workers.submit_task([&]() {
                    printf("Doing %d->%d,%d\n", move.unit, move.pos.x, move.pos.y);
                    node.iterate(next_burst, next_depth);
                    printf("Done %d->%d,%d\n", move.unit, move.pos.x, move.pos.y);
                //})
            );
            iterations -= next_burst;
        }

        printf("Waiting\n");
        mcts_workers.wait();
        printf("Waiteded\n");


        // Backpropagate manually
        reward = 0.0f; visits = 0.0f;
        for(auto& [move, node] : children) {
            reward += node.reward;
            visits += node.visits;
        }

    }
    */
    std::swap(tmp_parent, parent);
}

void BattleMCTSNode::iterate_self(int iterations) {

    auto visits = MAX_SIMULATIONS_PER_VISIT;

    for(int i = 0; i < iterations; i+=visits) {
        BattleResult result;
        BattleMCTSNode* node = this, *temp_node;

        {
            //std::shared_lock rlock(rwlock);

            while((temp_node = node->select().second) != nullptr) {
                node = temp_node;
            }

            node->expand();
            result = node->simulate(MAX_SIM_ITERATIONS, visits);    
        }

        {
            //std::unique_lock wlock(rwlock);
            node->backpropagate(result, visits);

            if(result.winner_team == manager->army_team) {
                this->wins++;
            }
            else if(result.winner_team == -1) {
                this->draws++;
            }
            else {
                this->loses++;
            }
        }
    }
}

Move BattleMCTSManager::get_optimal_move(int nth_best_move) {
    // TODO? nth best move
    
    if(nth_best_move != 0) {
        ERR_PRINT_ONCE_ED("ERROR - Nth best move is not implemented for BattleMCTSManager yet");
    }

    for(auto& [move, node] : root->children) {
        auto& hm = root->bm.get_heuristically_good_moves();
        bool heur_move = std::find(hm.begin(), hm.end(), move) != hm.end();
        printf("Child %c %d->%d,%d UCT=%f, R/V=%f (reward: %f, visits: %f)\n", 
                heur_move ? 'H':' ', move.unit, move.pos.x, move.pos.y, 
                node.uct(), node.reward / node.visits, node.reward, node.visits
        );
    }
    printf("%i/%i/%i\n", root->wins, root->draws, root->loses);

    float max_ratio = -1.0f;
    Move chosen;

    for(auto& [move, node] : root->children) {
        if(node.reward / node.visits > max_ratio) {
            chosen = move;
            max_ratio = node.reward / node.visits;
        }
    }

    return chosen;
}

int BattleMCTSManager::get_optimal_move_unit(int nth_best_move) {
    return get_optimal_move(nth_best_move).unit;
}

Vector2i BattleMCTSManager::get_optimal_move_position(int nth_best_move) {
    return Vector2i(get_optimal_move(nth_best_move).pos.x, get_optimal_move(nth_best_move).pos.y);
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
    ClassDB::bind_method(D_METHOD("get_optimal_move_unit"), &BattleMCTSManager::get_optimal_move_unit, "nth_best_move");
    ClassDB::bind_method(D_METHOD("get_optimal_move_position"), &BattleMCTSManager::get_optimal_move_position, "nth_best_move");

    ClassDB::bind_method(D_METHOD("iterate"), &BattleMCTSManager::iterate, "iterations", "max_threads");

    ClassDB::bind_method(D_METHOD("set_root"), &BattleMCTSManager::set_root, "battle_manager");
    ADD_SIGNAL(MethodInfo("complete"));
}

