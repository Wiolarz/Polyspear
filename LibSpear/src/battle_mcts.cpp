#include "battle_mcts.hpp"

#include <math.h>
#include <assert.h>
#include <limits>
#include <utility>
#include <random>

#include <signal.h>


BattleMCTSNode::BattleMCTSNode(BattleManagerFast bm, BattleMCTSManager* manager, BattleMCTSNode* parent) 
    : bm(bm),
      manager(manager),
      parent(parent)
{
    
}

float BattleMCTSNode::uct() const {
    const auto coeff = 5*sqrt(2);

    if(abs(visits) < 1e-5f) {
        // not explored, a large number to force exploring it
        // idea - dither - this + a tiny bit of pseudorandom noise to select a random node vs first/last found
        return 10000.0f;
    }
    auto parent_visits = parent ? parent->visits : visits;
    auto xd = (reward/visits) + coeff * sqrt(log2(parent_visits) / visits);
    //printf("xd:%f\n   r%f v%f pv%f, ", xd, reward, visits, parent_visits);
    return xd;
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
    auto move = bm.get_random_move();

    if(children.count(move) == 0) {
        children.insert({move, BattleMCTSNode(bm, manager, this)});
        children.at(move).bm.play_move(move);
    }
}

int BattleMCTSNode::simulate() {
    if(bm.is_battle_finished()) {
        return bm.get_winner();
    }

    BattleManagerFast bmnew = bm;
    int winner_team;
    Move move;
    int i = 0;
    
    do {
        move = bmnew.get_random_move();
        i++;
    } while((winner_team = bmnew.play_move(move)) == -1 && i < MAX_SIM_ITERATIONS);

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
    int unknowns = 0;
    for(int i = 0; i < iterations; i++) {
        BattleMCTSNode* node = root, *temp_node;
        int tree_level = 0;
        while((temp_node = node->select().second) != nullptr) {
            node = temp_node;
            tree_level++;
        }

        node->expand();
        auto winner = node->simulate();
        auto reward = winner == army_team ? 1.0f : (winner == -1 ? 0.5f : 0.0f);
        if(winner == -1) unknowns++;
        auto visit = 1.0f;

        node->backpropagate(visit, reward);
    }
    printf("Unknowns - %d", unknowns);
}

Move BattleMCTSManager::get_optimal_move(int nth_best_move) {
    // TODO nth best move
    
    if(nth_best_move != 0) {
        ::godot::_err_print_error(FUNCTION_STR, __FILE__, __LINE__, "ERROR - Nth best move is not implemented for BattleMCTSManager yet");
    }

    for(auto& [move, node] : root->children) {
        printf("Child %d->%d,%d = %f (reward: %f, visits: %f)\n", move.unit, move.pos.x, move.pos.y, node.uct(), node.reward, node.visits);
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
    ClassDB::bind_method(D_METHOD("get_optimal_move_unit"), &BattleMCTSManager::get_optimal_move_unit);
    ClassDB::bind_method(D_METHOD("get_optimal_move_position"), &BattleMCTSManager::get_optimal_move_position);

    ClassDB::bind_method(D_METHOD("iterate"), &BattleMCTSManager::iterate);

    ClassDB::bind_method(D_METHOD("set_root"), &BattleMCTSManager::set_root);
}

