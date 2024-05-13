#ifndef FAST_BATTLE_MANAGER_H
#define FAST_BATTLE_MANAGER_H

#ifdef WIN32
#include "windows.h"
#endif

#include "godot_cpp/classes/node.hpp"
#include "godot_cpp/core/class_db.hpp"
#include <stdint.h>
#include <array>
#include <vector>


using namespace godot;


struct Position {
    uint8_t x;
    uint8_t y;

    inline Position() : x(0), y(0) {};
    inline Position(uint8_t x, uint8_t y) : x(x), y(y) {};
    inline Position operator+(const Position& other) {
        return Position(x + other.x, y + other.y);
    }
    inline bool operator==(const Position& other) {
        return x == other.x && y == other.y;
    }
};


enum class Symbol: uint8_t {
    EMPTY,
    ATTACK_WITH_COUNTER,
    ATTACK,
    SHIELD,
    BOW,
    PUSH
};

enum class UnitStatus: uint8_t {
    SUMMONING,
    ALIVE,
    DEAD
};

enum class BattleState: uint8_t {
    SUMMONING,
    ONGOING,
    FINISHED
};

enum class Tile: uint8_t {
    PASSABLE,
    IMPASSABLE
};


struct Unit {
    UnitStatus status;
    Position pos;
    uint8_t rotation;
    std::array<Symbol, 6> sides;

    inline void rotate(int times) {
        rotation = (rotation + times) % 6;
    }

    inline Symbol& symbol_at_side(int side) {
        return sides[(rotation + side) % 6];
    }
};

struct Army {
    int team;
    std::array<Unit, 5> units;

    Unit* get_unit(Position coord);
};

using ArmyList = std::array<Army, 2>;
using TileList = std::vector<Tile>;


struct MoveResult {
    int winner; /// -1 - no winner, nonzero - winner id
};


const std::array<Position, 6> DIRECTIONS = {
	Position(-1, 0),
	Position(0, -1),
	Position(1, -1),
	Position(1, 0),
	Position(0, 1),
	Position(-1, 1),
};


class BattleManagerFast : public Node {
    GDCLASS(BattleManagerFast, Node);

    int x,y;
    int current_participant;
    ArmyList army;
    std::vector<Tile> tiles;

    Unit* get_unit(Position coord, int team = -1);
    Tile* get_tile(Position coord);

    int process_kills(unsigned unit);

protected:
    static void _bind_methods();

public:
    ~BattleManagerFast() = default;

    void add_unit();
    void add_unit_symbol();
    void set_tile();
    void set_map_size(unsigned x, unsigned y);

    inline int get_current_participant() {return current_participant;};
    MoveResult play_move(unsigned unit, Position pos);
    
};


#endif
