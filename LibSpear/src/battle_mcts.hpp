#ifndef BATTLE_MCTS_HPP
#define BATTLE_MCTS_HPP

#ifdef WIN32
#include "windows.h"
#endif

#include "fast_battle_manager.hpp"
#include <optional>
#include <unordered_map>

const int MAX_SIM_ITERATIONS = 70;
const float HEURISTIC_PROBABILITY = 0.85f;
const float HEURISTIC_PRIOR_REWARD_PER_ITERATION = 0.05f;
const int MAX_MCTS_BURST = 200;
const int MAX_SIMULATIONS_PER_VISIT = 40;


class BattleMCTSManager;

class BattleMCTSNode {
    BattleMCTSManager* manager = nullptr;
    BattleMCTSNode* parent = nullptr;
    std::unordered_map<Move, BattleMCTSNode> children{};
    BattleManagerFastCpp bm;

    unsigned mcts_iterations = 0;
    float reward = 0.0f;
    float visits = 0.0f;
    unsigned draws = 0;
    unsigned wins = 0;
    unsigned loses = 0;

    friend class BattleMCTSManager;

public:
    BattleMCTSNode(BattleManagerFastCpp bm, BattleMCTSManager* manager, BattleMCTSNode* parent);
    ~BattleMCTSNode() = default;

    float uct() const;
    bool is_explored();

    void iterate(int iterations, int depth = 0);
    void iterate_self(int iterations);

    /// Select the currently best child. May return nullptr as the second return value
    std::pair<Move, BattleMCTSNode*> select();
    /// Find a new child node
    void expand();
    /// Simulate a number of complete playouts in parallel
    BattleResult simulate(int max_sim_iterations, int simulations);
    /// Backpropagate the result
    void backpropagate(BattleResult& result, int new_visits);
};


class BattleMCTSManager : public Node {
    GDCLASS(BattleMCTSManager, Node);

    // i wanted it to not be a pointer, but c++ was stronger
    BattleMCTSNode* root = nullptr;
    int army_team;
    int army_id;

    // TODO parameters
    //int max_sim_iterations;

    friend class BattleMCTSNode;
    
protected:
    static void _bind_methods();

public:
    BattleMCTSManager() = default;
    virtual ~BattleMCTSManager() override;

    void set_root(BattleManagerFastCpp* bm);

    void iterate(int iterations = 1, int max_threads = 1);

    /// Get the optimal move. Return zero unit/position on fail
    Move get_optimal_move(int nth_best_move);

    int get_optimal_move_unit(int nth_best_move = 0);
    Vector2i get_optimal_move_position(int nth_best_move = 0);
};



#endif
