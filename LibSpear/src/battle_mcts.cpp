#include "battle_mcts.hpp"

#include <math.h>
#include <assert.h>
#include <limits>
#include <utility>
#include <random>
#include <algorithm>

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
    
    // is it better to expand a single node or all nodes?
    auto move = bm.get_random_move(0.0f);

    if(children.count(move) == 0) {
        children.insert({move, BattleMCTSNode(bm, manager, this)});
        children.at(move).bm.play_move(move);
    }
}

//int todo_a = 0;

int BattleMCTSNode::simulate(int parent_mcts_iterations, int max_sim_iterations) {
    if(bm.is_battle_finished()) {
        return bm.get_winner_team();
    }


    BattleManagerFast bmnew = bm;
    int winner_team;
    Move move;
    int i = 0;
    int nested_mcts_div = 10; // multiplied for deeper playouts by a constant
    
    do {
        // In plain MCTS moves in playouts are chosen randomly.
        // This biases the bot towards optimistic scenarios where e.g. a unit is moving to an 
        // obviously dangerous position, but because further playouts are chosen randomly, 
        // the bot is optimistically assuming that the player is more likely to perform a
        // random, dumb move than in reality.
        // Therefore to improve effectiveness, we need to fix this problem by possibly either:
        //  1. Heuristics
        //  2. Smaller nested MCTS simulations determining a move distribution
        // limiting obvious dumb moves on the playout graph.

        // todo not here, but precalculate in select()

        /*auto move_count = bmnew.get_move_count();
        auto total_complexity = parent_mcts_iterations * max_sim_iterations * move_count;

        if(parent_mcts_iterations/move_count/nested_mcts_div > MIN_NESTED_MCTS_ITERATIONS_PER_MOVE) {
            BattleMCTSManager nested{};
            BattleManagerFast bmnested = bmnew;

            nested.set_root(&bmnested);
            nested._iterate(
                    parent_mcts_iterations/move_count/nested_mcts_div, 
                    max_sim_iterations*3/4///move_count/nested_mcts_div
            );

            move = nested.get_optimal_move(0);
            if(move == Move()) {
                move = bmnew.get_random_move();
            }
            nested_mcts_div *= 100000;
        }
        else */
        move = bmnew.get_random_move(HEURISTIC_PROBABIlITY);
        
        //printf("Simulating: %i %i %i\n", todo_a++, parent_mcts_iterations, nested_mcts_div);

        i++;
    } while((winner_team = bmnew.play_move(move).winner_team) == -1 && i < max_sim_iterations);

    return winner_team;
}

void BattleMCTSNode::backpropagate(float new_visit, float new_reward) {
    visits += new_visit;
    reward += new_reward;

    if(parent) {
        parent->backpropagate(new_visit, new_reward);
    }
}

bool BattleMCTSNode::is_explored() {
    return bm.get_move_count() == children.size();
}

void BattleMCTSManager::iterate(int iterations) {
    _iterate(iterations);
}

void BattleMCTSManager::_iterate(int iterations, int max_sim_iterations) {
    printf("iterating %i %i \n", iterations, max_sim_iterations);
    for(int i = 0; i < iterations; i++) {
        BattleMCTSNode* node = root, *temp_node;
        int tree_level = 0;
        while((temp_node = node->select().second) != nullptr) {
            node = temp_node;
            tree_level++;
        }

        node->expand();
        auto winner = node->simulate(iterations, max_sim_iterations);
        auto reward = winner == army_team ? 1.0f : (winner == -1 ? 0.5f : 0.0f);
        auto visit = 1.0f;

        node->backpropagate(visit, reward);
        
        if(winner == army_team) {
            root->wins++;
        }
        else if(winner == -1) {
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
        printf("Child %c %d->%d,%d = %f (reward: %f, visits: %f, %i/%i/%i)\n", heur_move ? 'H':' ', move.unit, move.pos.x, move.pos.y, node.uct(), node.reward, node.visits, root->wins, root->draws, root->loses);
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
    army_team = bm->get_army_team(bm->get_current_participant());
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

