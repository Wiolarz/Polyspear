#ifndef BATTLE_MCTS_HPP
#define BATTLE_MCTS_HPP

#ifdef WIN32
#include "windows.h"
#endif

#include "fast_battle_manager.hpp"
#include <optional>
#include <unordered_map>

#include "godot_cpp/core/object.hpp"


#define DEFINE_MCTS_PARAMETER(type, name) \
    type name = -1; \
    inline type get_##name () const {return name;} \
    inline void set_##name (const type new_##name) {name = new_##name;} 

#define BIND_MCTS_PARAMETER(variant, name) \
    ClassDB::bind_method(D_METHOD("set_" #name, "new_" #name), &BattleMCTSManager::set_##name); \
    ClassDB::bind_method(D_METHOD("get_" #name), &BattleMCTSManager::get_##name); \
    ADD_PROPERTY(PropertyInfo(variant, #name), "set_" #name, "get_" #name); 


class BattleMCTSManager;

class BattleMCTSNode {
    BattleMCTSManager* _manager = nullptr;
    BattleMCTSNode* _parent = nullptr;
    std::unordered_map<Move, BattleMCTSNode> _children{};
    BattleManagerFastCpp _bm;

    unsigned _mcts_iterations = 0;
    float _reward = 0.0f;
    float _visits = 0.0f;
    unsigned _draws = 0;
    unsigned _wins = 0;
    unsigned _loses = 0;

    friend class BattleMCTSManager;

public:
    BattleMCTSNode(BattleManagerFastCpp bm, BattleMCTSManager* manager, BattleMCTSNode* parent);
    ~BattleMCTSNode() = default;

    float uct() const;
    bool is_explored();

    void iterate(int iterations);

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

    DEFINE_MCTS_PARAMETER(int, max_sim_iterations);
    DEFINE_MCTS_PARAMETER(float, heuristic_probability);
    DEFINE_MCTS_PARAMETER(float, heuristic_prior_reward_per_iteration);
    DEFINE_MCTS_PARAMETER(int, max_playouts_per_visit);

    // i wanted it to not be a pointer, but c++ was stronger
    BattleMCTSNode* root = nullptr;
    int army_team;
    int army_id;

    friend BattleResult _simulate_thread(BattleManagerFastCpp bm, const BattleMCTSManager& mcts);
    friend class BattleMCTSNode;
    
protected:
    static void _bind_methods();

public:
    BattleMCTSManager() = default;
    virtual ~BattleMCTSManager() override;

    void set_root(BattleManagerFastCpp* bm);

    void iterate(int iterations = 1);

    /// Get the optimal move. Return zero unit/position on fail
    Move get_optimal_move(int nth_best_move);

    int get_optimal_move_unit(int nth_best_move = 0);
    Vector2i get_optimal_move_position(int nth_best_move = 0);
};



#endif
