#ifndef BATTLE_MCTS_HPP
#define BATTLE_MCTS_HPP

#ifdef WIN32
#include "windows.h"
#endif

#include "fast_battle_manager.hpp"
#include <optional>
#include <unordered_map>


class BattleMCTSManager;

class BattleMCTSNode {
    BattleMCTSManager* manager;
    BattleMCTSNode* parent;
    std::unordered_map<Move, BattleMCTSNode> children;
    BattleManagerFast bm;
    std::optional<MoveIterator> moveiter;

    float reward;
    float visits;

    friend class BattleMCTSManager;

public:
    BattleMCTSNode(BattleManagerFast bm, BattleMCTSManager* manager);
    ~BattleMCTSNode() = default;

    void set_bm(BattleManagerFast bm);

    float uct() const;
    bool is_explored() const;

    /// Select the currently best child. May return nullptr as the second return value
    std::pair<Move, BattleMCTSNode*> select();
    /// Find a new child node
    void expand();
    /// Simulate a complete playout until either decided, 
    int simulate();
    void backpropagate(float new_visit, float new_reward);
};


class BattleMCTSManager : public Node {
    GDCLASS(BattleMCTSManager, Node);

    // i wanted it to not be a pointer, but c++ was stronger
    BattleMCTSNode* root;
    int army;

    friend class BattleMCTSNode;
    
protected:
    static void _bind_methods();

public:
    BattleMCTSManager() = default;
    // TODO what the fuck it crashes godot editor
    //virtual ~BattleMCTSManager() override;
    void set_root(BattleManagerFast* bm);

    void iterate(int iterations = 1);

    /// Get the optimal move. Return zero unit/position on fail
    Move get_optimal_move(int nth_best_move);

    int get_optimal_move_unit(int nth_best_move = 0);
    Vector2i get_optimal_move_position(int nth_best_move = 0);
};



#endif
