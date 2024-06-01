#ifndef FAST_BATTLE_MANAGER_H
#define FAST_BATTLE_MANAGER_H

#ifdef WIN32
#include "windows.h"
#endif

#include "godot_cpp/classes/node.hpp"
#include "godot_cpp/core/class_db.hpp"
#include "godot_cpp/variant/vector2i.hpp"
#include <stdint.h>
#include <array>
#include <vector>
#include <algorithm>

#include "data.hpp"
#include "tile_grid_fast.hpp"


using namespace godot;


class BattleManagerFast;
class BattleMCTSManager;

struct Unit {
    UnitStatus status = UnitStatus::DEAD;
    Position pos;
    uint8_t rotation;
    std::array<Symbol, 6> sides;

    inline void rotate(int times) {
        rotation = (6-rotation + times) % 6;
    }

    inline Symbol symbol_at_side(int side) {
        return sides[(6-rotation + side) % 6];
    }
};

struct Army {
    int team;
    std::array<Unit, 5> units;

    Unit* get_unit(Position coord);
    int find_summon_id(int from = 0);
};

using ArmyList = std::array<Army, 2>;


struct Move {
    uint8_t unit;
    Position pos;

    Move() = default;
    bool operator==(const Move& other) const {
        return unit == other.unit && pos == other.pos;
    }
};

template<>
struct std::hash<Move> {
    const std::size_t operator()(const Move& move) const {
        auto h1 = std::hash<unsigned>{}(move.unit);
        auto h2 = std::hash<unsigned>{}(move.pos.x);
        auto h3 = std::hash<unsigned>{}(move.pos.y);
        return h1 ^ (h2 << 1) ^ (h3 << 2);
    }
};


// idea - BattleManagerFastWrapper as multiple inheritance of internal BattleManagerFast and godot Node if it turns out that Node itself is expensive
class BattleManagerFast : public Node {
    GDCLASS(BattleManagerFast, Node);

    int x,y;
    int current_participant;
    BattleState state = BattleState::SUMMONING;
    ArmyList armies;
    TileGridFast* tiles;
    //BattleMCTSManager* mcts;
    std::vector<Move> moves;
    bool moves_dirty = true;

    Unit* _get_unit(Position coord);
    Tile* _get_tile(Position coord);

    int _process_unit(Unit& unit, Army& army, bool process_kills = true);
    int _process_bow(Unit& unit, Army& enemy_army);

    void _refresh_legal_moves();
    int _play_move(unsigned unit, Vector2i move);

protected:
    static void _bind_methods();

public:
    BattleManagerFast() = default;
    ~BattleManagerFast() = default;

    void insert_unit(int army, int idx, Vector2i pos, int rotation, bool is_summoning); /// Add a unit in a summoning state
    void set_army_team(int army, int team); /// Set army's team - required
    void set_unit_symbol(int army, int unit, int symbol, int symbol_id); /// Add symbol for a specified unit
    void set_tile_grid(TileGridFast* tilegrid);
    void set_current_participant(int army);
    void force_battle_ongoing();
    
    int play_move(Move move);
    int play_move_gd(unsigned unit, Vector2i move);

    /// Get legal moves iterator for current participant
    const std::vector<Move>& get_legal_moves();
    Move get_random_move();
    int get_move_count();

    bool is_occupied(Position pos, int team) const;

    // Getters, primarily for testing correctness with regular BattleManager
    inline Vector2i get_unit_position(int army, int unit) const {
        auto p = armies[army].units[unit].pos; 
        return Vector2i(p.x, p.y);
    }

    inline int get_unit_rotation(int army, int unit) const {
        return armies[army].units[unit].rotation;
    }

    inline bool is_unit_alive(int army, int unit) const {
        return armies[army].units[unit].status == UnitStatus::ALIVE;
    }

    inline bool is_unit_being_summoned(int army, int unit) const {
        return armies[army].units[unit].status == UnitStatus::SUMMONING;
    }

    inline int get_current_participant() const {
        return current_participant;
    }

    inline bool is_battle_finished() const {
        return state == BattleState::FINISHED;
    }

    inline int get_army_team(int army) const {
        return armies[army].team;
    }
};


#endif
