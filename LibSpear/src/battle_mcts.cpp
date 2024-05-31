#include "battle_mcts.hpp"

#include <math.h>
#include <assert.h>
#include <limits>
#include <utility>


BattleMCTSNode::BattleMCTSNode(BattleManagerFast bm, BattleMCTSManager* manager) 
    : bm(bm),
      moveiter(bm.get_legal_moves()),
      manager(manager)
{
    
}

float BattleMCTSNode::uct() const {
    auto coeff = sqrt(2);

    if(abs(visits) < 1e-5f) {
        return -std::numeric_limits<float>::infinity();
    }
    auto parent_visits = parent ? parent->visits : 0.0;
    return reward/visits + coeff * sqrt(log2(parent_visits) / visits);
}

std::pair<Move, BattleMCTSNode*> BattleMCTSNode::select() {
    float uct_max = 0.0;
    BattleMCTSNode* uct_max_idx = nullptr;
    Move best_move;

    for(auto& [move, node] : children) {
        auto uct = node.uct();
        if(uct > uct_max) {
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
        children.insert({move, BattleMCTSNode(bm, manager)});
        children.at(move).bm.play_move(move);
    }
}

int BattleMCTSNode::simulate() {
    if(bm.is_battle_finished()) {
        return -1;
    }

    BattleManagerFast bmnew = bm;
    int winner_team;
    Move move;

    do {
        move = bmnew.get_random_move();
    } while((winner_team = bmnew.play_move(move)) == -1);

    return winner_team;
}

void BattleMCTSNode::backpropagate(float new_visit, float new_reward) {
    visits += new_visit;
    reward += new_reward;

    if(parent) {
        parent->backpropagate(new_visit, new_reward);
    }
}

bool BattleMCTSNode::is_explored() const {
    return bm.get_move_count() == children.size();
}


void BattleMCTSManager::iterate(int iterations) {
    for(int i = 0; i < iterations; i++) {
        BattleMCTSNode* node = root, *temp_node;
        while((temp_node = root->select().second) != nullptr) {
            node = temp_node;
        }

        node->expand();
        auto winner = node->simulate();
        auto reward = winner == army ? 1.0f : 0.0f;
        auto visit = 1.0f;

        node->backpropagate(visit, reward);
    }
}

Move BattleMCTSManager::get_optimal_move(int nth_best_move) {
    // TODO nth best move
    
    if(nth_best_move != 0) {
        ::godot::_err_print_error(FUNCTION_STR, __FILE__, __LINE__, "ERROR - Nth best move is not implemented for BattleMCTSManager yet");
    }

    return root->select().first;
}

int BattleMCTSManager::get_optimal_move_unit(int nth_best_move) {
    return get_optimal_move(nth_best_move).unit;
}

Vector2i BattleMCTSManager::get_optimal_move_position(int nth_best_move) {
    return Vector2i(get_optimal_move(nth_best_move).pos.x, get_optimal_move(nth_best_move).pos.y);
}


void BattleMCTSManager::set_root(BattleManagerFast* bm) {
    root = new BattleMCTSNode(*bm, this);
    army = bm->get_current_participant();
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

