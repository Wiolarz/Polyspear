#ifndef DATA_H
#define DATA_H

#ifdef WIN32
#include "windows.h"
#endif

#include <stdint.h>
#include <stdio.h>
#include <array>

#include "godot_cpp/variant/vector2i.hpp"
#include "godot_cpp/variant/string.hpp"


enum class UnitStatus: uint8_t {
	SUMMONING,
	ALIVE,
	DEAD
};

enum class BattleState: uint8_t {
	INITIALIZING,
	SUMMONING,
	ONGOING,
	SACRIFICE,
	FINISHED
};

enum class MovePhase: uint8_t {
	TURN,
	LEAP,
	PASSIVE
};

struct Position {
	int8_t x{};
	int8_t y{};

	inline Position() : x(0), y(0) {};
	inline Position(int8_t x, int8_t y) : x(x), y(y) {};
	inline Position(godot::Vector2i p) : x(p.x), y(p.y) {};

	inline Position operator+(const Position& other) const {
		return Position(x + other.x, y + other.y);
	}

	inline Position operator-(const Position& other) const {
		return Position(x - other.x, y - other.y);
	}

	inline Position operator*(const int mult) const {
		return Position(x * mult, y * mult);
	}

	std::strong_ordering operator<=>(const Position& other) const = default;

	inline bool is_in_line_with(Position other) const {
		auto delta = *this - other;
		return delta.x == -delta.y || delta.x == 0 || delta.y == 0;
	}

};

class Symbol {
	uint8_t _attack_strength = 0;
	uint8_t _defense_strength = 0;
	uint8_t _push_strength = 0;
	uint8_t _ranged_reach = 0;
	uint8_t _flags = 0;

public:
	static const uint8_t FLAG_COUNTER_ATTACK = 0x01;
	static const uint8_t FLAG_PARRY = 0x02;
	static const uint8_t FLAG_PARRY_BREAK = 0x04;
	
	static const int MIN_SHIELD_DEFENSE = 2;

	Symbol() = default;
	Symbol(uint8_t attack_strength, uint8_t defense_strength, uint8_t push_force, uint8_t ranged_reach, uint8_t flags) 
		: _attack_strength(attack_strength),
		_defense_strength(defense_strength),
		_push_strength(push_force),
		_ranged_reach(ranged_reach),
		_flags(flags) 
	{

	}

	inline int get_attack_force() {
		return _attack_strength;
	}

	inline int get_counter_force() {
		return (_flags & FLAG_COUNTER_ATTACK) ? _attack_strength : 0;
	}

	inline int get_defense_force() {
		return _defense_strength;
	}

	inline int get_bow_force() {
		return (_ranged_reach > 1) ? _attack_strength : 0;
	}

	inline int get_reach() {
		return _ranged_reach;
	}
	
	inline int get_push_force() {
		return _push_strength;
	}

	inline bool protects_against(Symbol other, MovePhase phase) {
		// Parry disables melee attacks
		if(other.get_bow_force() <= 0 && (parries() && !other.breaks_parry())) {
			return true;
		}
		
		int other_force = (phase == MovePhase::PASSIVE) ? other.get_counter_force() : other.get_attack_force();
		return other_force <= get_defense_force();
	}

	inline bool holds_ground_against(Symbol other, MovePhase phase) {
		return protects_against(other, phase) && other.get_push_force() <= 0;
	}

	inline bool dies_to(Symbol other, MovePhase phase) {
		return !protects_against(other, phase);
	}

	inline bool parries() {
		return (_flags & FLAG_PARRY);
	}

	inline bool breaks_parry() {
		return (_flags & FLAG_PARRY_BREAK);
	}

	inline void print() {
		printf("a%dc%dd%d", get_attack_force(), get_counter_force(), get_defense_force());
	}
};

class Tile {
	static const uint8_t PASSABLE = 0x1;
	static const uint8_t WALL = 0x2;
	static const uint8_t SWAMP = 0x4;
	static const uint8_t FORBIDDEN = 0x8;
	static const uint8_t MANA_WELL = 0x10;
	static const uint8_t PIT = 0x20;
	static const uint8_t HILL = 0x40;
	static const uint8_t SPAWN = 0x80;

	uint8_t _flags = FORBIDDEN | WALL;
	int8_t _army = -1; // Spawning army for spawning tiles, controlling army for mana wells
	uint8_t _spawning_direction{};

public:
	Tile() = default;
	Tile(bool passable, bool wall, bool swamp, bool mana_well, bool pit, bool hill, int army, unsigned direction) :
		_flags(
			(passable ? PASSABLE : 0)
		  | (wall ? WALL : 0)
		  | (swamp ? SWAMP : 0)
		  | (mana_well ? MANA_WELL : 0)
		  | (pit ? PIT : 0)
		  | (hill ? HILL : 0)
		  | ((!mana_well && army >= 0) ? SPAWN : 0)
		),
		_army(army),
		_spawning_direction(direction)
	{}
	
	inline bool is_passable() {
		return (_flags & PASSABLE) != 0;
	}

	inline bool is_wall() {
		return (_flags & WALL) != 0;
	}

	inline bool is_swamp() {
		return (_flags & SWAMP) != 0;
	}

	inline bool is_mana_well() {
		return (_flags & MANA_WELL) != 0;
	}

	inline bool is_hill() {
		return (_flags & HILL) != 0;
	}

	inline bool is_pit() {
		return (_flags & PIT) != 0;
	}

	inline bool is_spawn() {
		return (_flags & SPAWN) != 0;
	}

	inline int get_spawning_army() {
		return is_spawn() ? _army : -1;
	}

	inline int get_controlling_army() {
		return is_mana_well() ? _army : -1;
	}

	inline void set_controlling_army(int army_id) {
		ERR_FAIL_COND_MSG(!is_mana_well(), "Only mana well tiles can be controlled as an army");
		_army = army_id;
	}

	inline unsigned get_spawn_rotation() {
		return _spawning_direction;
	}
};

const std::array<Position, 6> DIRECTIONS = {
	Position(-1, 0),
	Position(0, -1),
	Position(1, -1),
	Position(1, 0),
	Position(0, 1),
	Position(-1, 1),  // non-axes - -1,-1; 1,1
};


inline int get_rotation(Position origin, Position relative) {
	auto pos = relative - origin;
	for(int i = 0; i < 6; i++) {
		if(DIRECTIONS[i] == pos) {
			return i;
		}
	}
	return 6;
}

inline int flip(int rot) {
	return (rot + 3) % 6;
}

#endif
