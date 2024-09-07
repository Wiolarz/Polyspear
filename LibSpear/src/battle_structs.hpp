#ifndef BATTLE_STRUCTS_H
#define BATTLE_STRUCTS_H

#include <stdint.h>
#include <array>
#include <vector>
#include <algorithm>

#include "data.hpp"

const unsigned MAX_ARMIES = 4;
const unsigned MAX_UNITS_IN_ARMY = 5;

class BattleManagerFastCpp;
class BattleMCTSManager;

using Score = int16_t;

struct BattleResult {
    int8_t winner_team = -1;
    std::array<Score, MAX_ARMIES> max_scores{0};
    std::array<Score, MAX_ARMIES> total_scores{0};
    std::array<Score, MAX_ARMIES> score_gained{0};
    std::array<Score, MAX_ARMIES> score_lost{0};
};

struct Unit {
    UnitStatus status = UnitStatus::DEAD;
    Position pos{};
    uint8_t rotation{};
    uint8_t score = 2;
    uint8_t mana = 0;
    std::array<Symbol, 6> sides{};

    inline Symbol symbol_at_abs_side(int side) const {
        return sides[(6-rotation + side) % 6];
    }
};

struct Army {
    int8_t id = 0;
    int8_t team = -1;

    uint16_t mana_points;
    uint16_t cyclone_timer;

    std::array<Unit, MAX_UNITS_IN_ARMY> units{};

    Unit* get_unit(Position coord);
    int find_unit_id_to_summon(int from = 0);
    bool is_defeated();
};

using ArmyList = std::array<Army, MAX_ARMIES>;

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


enum class TeamRelation {
    ALLY,
    ENEMY
};

#endif //BATTLE_STRUCTS_H
