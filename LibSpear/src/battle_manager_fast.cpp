#include "battle_manager_fast.hpp"
#include "godot_cpp/core/class_db.hpp"
#include "godot_cpp/core/error_macros.hpp"
 
#include <cstdlib>
#include <random>
#include <csignal>


void BattleManagerFast::finish_initialization() {
	BM_ASSERT(_state == BattleState::INITIALIZING, "BMFast already initialized");
	BM_ASSERT(_big_cyclone_counter_value != -1, "Uninitialized big cyclone counter");
	BM_ASSERT(_small_cyclone_counter_value != -1, "Uninitialized small cyclone counter");
	BM_ASSERT(_cyclone_mana_threshold != -1, "Uninitialized cyclone mana threshold");
	BM_ASSERT(_mana_well_power != -1, "Uninitialized mana well power");

	_state = BattleState::SUMMONING;
	for(unsigned i = 0; i < _armies.size(); i++) {
		if(_armies[i].is_defeated()) {
			continue;
		}
		BM_ASSERT(_armies[i].cyclone_timer != Army::CYCLONE_UNINITIALIZED, "Uninitialized cyclone timer in army {}", i);
		BM_ASSERT(_armies[i].team != -1, "Uninitialized team id in army {}", i);

		_armies[i].id = i;

		for(auto& unit: _armies[i].units) {
			if(unit.status != UnitStatus::DEAD) {
				_result.total_scores[i] += unit.score;
				_result.max_scores[i]	+= unit.score;
				_armies[i].mana_points += unit.mana;
			}
		}
	}

	for(int y = 0; y < _tiles.get_dims().y; y++) {
		for(int x = 0; x < _tiles.get_dims().x; x++) {
			auto pos = Position(x,y);
			auto army_id = _tiles.get_tile(pos).get_controlling_army();

			if(army_id != -1) {
				_armies[army_id].mana_points += _mana_well_power;
			}
		}
	}

	_unit_cache.update_armies(_armies);
	_update_mana_target();
}

int BattleManagerFastCpp::play_move(godot::Array libspear_tuple) {
	bm.play_move(Move(libspear_tuple));
	return bm._result.winner_team;
}

int BattleManagerFastCpp::play_moves(godot::Array libspear_tuples) {
	for(int i = 0; i < libspear_tuples.size(); i++) {
		play_move(libspear_tuples[i]);
	}
	return bm._result.winner_team;
}

void BattleManagerFast::play_move(Move move) {
	_moves_dirty = true;
	_heuristic_moves_dirty = true;

	_result.winner_team = -1;
	_result.score_gained.fill(0);
	_result.score_lost.fill(0);

	_previous_army = _current_army;

	BM_ASSERT(_state != BattleState::INITIALIZING, "Please call finish_initialization() before playing a move");
	CHECK_UNIT(move.unit,);
	CHECK_ARMY(_current_army,);
	
	UnitID uid = UnitID(_current_army, move.unit);
	auto& unit = _armies[_current_army].units[move.unit];

	if(_state == BattleState::SUMMONING) {
		BM_ASSERT(unit.status == UnitStatus::SUMMONING, "Unit id {} is not in summoning state", move.unit);
		BM_ASSERT(_tiles.get_tile(move.pos).get_spawning_army() == _current_army,
				"Target spawn {},{} does not belong to current army", move.pos.x, move.pos.y
		);

		_move_unit(uid, move.pos);
		unit.rotation = _tiles.get_tile(move.pos).get_spawn_rotation();
		unit.status = UnitStatus::ALIVE;

		bool end_summon = true;
		for(int i = (_current_army+1) % _armies.size(); i != _current_army; i = (i+1)%_armies.size()) {
			if(_armies[i].find_unit_id_to_summon() != -1) {
				_current_army = i;
				end_summon = false;
				break;
			}
		}

		if(end_summon) {
			_current_army = 0;
			_state = BattleState::ONGOING;
		}
	}
	else if(_state == BattleState::ONGOING) {
		if(move.spell_id == Move::NO_SPELL) {
			auto rot_new = get_rotation(unit.pos, move.pos);
			auto old_pos = unit.pos;

			if(_tiles.get_tile(move.pos).is_pit()) {
				move.pos = move.pos + Vector2i(DIRECTIONS[rot_new].x, DIRECTIONS[rot_new].y);
			}

			BM_ASSERT(unit.status == UnitStatus::ALIVE, "Trying to move a non-alive unit {} to position {},{}", move.unit, move.pos.x, move.pos.y);
			BM_ASSERT(rot_new != 6, "Target position {},{} is not a neighbor", move.pos.x, move.pos.y);

			unit.rotation = rot_new;
			_process_unit(uid, MovePhase::TURN);
			
			if(unit.status == UnitStatus::ALIVE && unit.pos == old_pos) {
				_move_unit(uid, move.pos);
				_process_unit(uid, MovePhase::LEAP);
			}
		}
		else {
			_process_spell(uid, move.spell_id, move.pos);
		}

		_next_army();

		if(_previous_army > _current_army) {
			_update_turn_end();

			_armies[_cyclone_target].cyclone_timer--;
			if(_armies[_cyclone_target].cyclone_timer <= 0) {
				_current_army = _cyclone_target;
				_state = BattleState::SACRIFICE;
			}
		}
	}
	else if(_state == BattleState::SACRIFICE) {
		BM_ASSERT(unit.status == UnitStatus::ALIVE, "Invalid sacrifice id {}", move.unit);
		_kill_unit(uid, NO_UNIT);
		_update_mana(); // also called in _kill_unit, but here to prevent an edge case when killed unit has 0 mana
		_current_army = MAX_ARMIES-1;
		_next_army();
		_state = get_winner_team() < 0 ? BattleState::ONGOING : BattleState::FINISHED;
	}
	else {
		BM_ASSERT(false, "Battle already ended, did not expect that");
	}

	_update_move_end();
	_result.winner_team = get_winner_team();

	// Test whether all cache updates are correct
	if(_debug_internals) {
		BM_ASSERT(_unit_cache.self_test(_armies), "Cache mismatch detected");
	}

	return;
}


void BattleManagerFast::_process_unit(UnitID unit_id, MovePhase phase) {
	auto [unit, army] = _get_unit(unit_id).value();

	// Passive phase
	for(int side = 0; side < 6; side++) {
		auto pos = unit.pos + DIRECTIONS[side];
		auto neighbor_id = _unit_cache.get(pos);
		auto neighbor_opt = _get_unit(neighbor_id);

		if(!neighbor_opt.has_value()) {
			continue;
		}

		auto [neighbor, enemy_army] = neighbor_opt.value();

		if(neighbor.status != UnitStatus::ALIVE || enemy_army.team == army.team) {
			continue;
		}

		auto unit_symbol = unit.symbol_when_rotated(side);
		auto neighbor_symbol = neighbor.symbol_when_rotated(flip(side));

		// enemy's counter/spear
		if(unit_symbol.dies_to(neighbor_symbol, MovePhase::PASSIVE)) {
			_kill_unit(unit_id, neighbor_id);
			return;
		}

		// unit's passive spear
		if(neighbor_symbol.dies_to(unit_symbol, MovePhase::PASSIVE)) {
			_kill_unit(neighbor_id, unit_id);
		}
	}
	
	if(phase == MovePhase::PASSIVE) {
		return;
	}

	// Active phase
	for(int side = 0; side < 6; side++) {
		auto pos = unit.pos + DIRECTIONS[side];
		auto neighbor_id = _unit_cache.get(pos);
		auto neighbor_opt = _get_unit(neighbor_id);

		if(!neighbor_opt.has_value()) {
			continue;
		}

		auto [neighbor, enemy_army] = neighbor_opt.value();

		if(neighbor.status != UnitStatus::ALIVE || enemy_army.team == army.team) {
			continue;
		}

		auto unit_symbol = unit.symbol_when_rotated(side);
		auto neighbor_symbol = neighbor.symbol_when_rotated(flip(side));
	
		if(neighbor_symbol.dies_to(unit_symbol, phase)) {
			_kill_unit(neighbor_id, unit_id);
		}

		auto direction = neighbor.pos - unit.pos;
		auto push_force = unit_symbol.get_push_force();
		if(neighbor.status != UnitStatus::DEAD && push_force > 0) {
			_process_push(neighbor_id, unit_id, direction, push_force);
		}
	}

	_process_bow(unit_id, phase);
}

void BattleManagerFast::_process_push(UnitID pushed, UnitID pusher, Position direction, uint8_t max_power) {
	auto pushed_opt = _get_unit(pushed);
	BM_ASSERT(pushed_opt.has_value(), "Invalid pushed unit id {}", pushed.unit);
	auto [pushed_unit, pushed_army] = pushed_opt.value();

	auto pos = pushed_unit.pos;

	for(int power = 1; power <= max_power; power++) {
		pos = pos + direction;

		if(_get_unit(pos).has_value() || _tiles.get_tile(pos).is_pit()) {
			_kill_unit(pushed, pusher);
			return;
		}
		
		if(!(_tiles.get_tile(pos).is_passable())) {
			if(power == 1 || power < max_power) {
				_kill_unit(pushed, pusher);
				return;
			}
			else {
				pos = pos - direction;
				break;
			}
		}
	}

	_move_unit(pushed, pos);
	_process_unit(pushed, MovePhase::PASSIVE);
}

void BattleManagerFast::_process_bow(UnitID unit_id, MovePhase phase) {
	auto [unit, army] = _get_unit(unit_id).value();

	for(int i = 0; i < 6; i++) {
		auto symbol = unit.symbol_when_rotated(i);
		if(symbol.get_bow_force() == 0) {
			continue;
		}

		auto iter = DIRECTIONS[i];
		auto pos = unit.pos + iter;

		for(int range = 1; range <= symbol.get_reach(); range++) {
			auto other_id = _unit_cache.get(pos);
			auto other_unit_opt = _get_unit(other_id);

			if(!other_unit_opt.has_value()) {
				pos = pos + iter;
				continue;
			}
			auto [other, other_army] = other_unit_opt.value();

			if(other_army.team == army.team) {
				break;
			}

			if(other.symbol_when_rotated(flip(i)).dies_to(symbol, phase)) {
				_kill_unit(other_id, unit_id);
				break;
			}

			if(_tiles.get_tile(pos).is_wall()) {
				break; // Can't shoot past walls, but can shoot enemies on hills
			}
			
			pos = pos + iter;
		}
	}
}

void BattleManagerFast::_process_spell(UnitID uid, int8_t spell_id, Position target) {
	auto& spell = _spells[spell_id];
	auto uid2 = _unit_cache.get(target);
	auto caster_team = get_army_team(uid.army);

	switch(spell.state) {
		case BattleSpell::State::FIREBALL:
			{
				// const size array - enough to hold target's surroundings
				std::array<UnitID, 7> ally_targets;
				int last_ally_target = 0;

				if(uid2 != NO_UNIT) {
					if(get_army_team(uid2.army) == caster_team) {
						ally_targets[last_ally_target++] = uid2;
					}
					else {
						_kill_unit(uid2, uid);
					}
				}

				for(auto i : DIRECTIONS) {
					auto pos = target + i;
					auto neighbor_id = _unit_cache.get(pos);
					if(neighbor_id != NO_UNIT) {
						if(get_army_team(neighbor_id.army) == caster_team) {
							ally_targets[last_ally_target++] = neighbor_id;
						}
						else {
							_kill_unit(neighbor_id, uid);
						}
					}
				}

				if(get_winner_team() < 0) {
					for(auto ally_id : ally_targets) {
						if(ally_id == NO_UNIT) {
							break;
						}
						_kill_unit(ally_id, uid);
					}
				}
			}
			break;
		case BattleSpell::State::TELEPORT:
			_move_unit(uid, target);
			_process_unit(uid, MovePhase::LEAP);
			break;
		case BattleSpell::State::VENGEANCE:
			{
				auto unit = _get_unit(uid2);
				BM_ASSERT(unit.has_value(), "Unknown unit id for vengeance spell");
				unit.value().unit.try_apply_effect(Unit::FLAG_EFFECT_VENGEANCE);
			}
			break;
		case BattleSpell::State::MARTYR:
			{
				auto unit1 = _get_unit(uid);
				auto unit2 = _get_unit(uid2);
				BM_ASSERT(unit1.has_value(), "Unknown unit id for martyr spell");
				BM_ASSERT(unit2.has_value(), "Unknown unit id for martyr spell");
				unit1.value().unit.try_apply_martyr(uid2);
				unit2.value().unit.try_apply_martyr(uid);
			}
			break;
		case BattleSpell::State::NONE:
		case BattleSpell::State::SENTINEL:
			BM_ASSERT(false, "Invalid spell id chosen in a move");
			return;
		default:
			BM_ASSERT(false, "Invalid spell type");
			return;
	}
	spell.state = BattleSpell::State::NONE;
	spell.unit = NO_UNIT;
}

void BattleManagerFast::_update_turn_end() {
	if(get_winner_team() >= 0) {
		return;
	}

	for(unsigned army_id = 0; army_id < _armies.size(); army_id++) {
		for(unsigned unit_id = 0; unit_id < _armies[army_id].units.size(); unit_id++) {
			auto uid = UnitID(army_id, unit_id);
			auto unitref = _get_unit(uid);
			
			if(unitref.has_value() && unitref.value().unit.status != UnitStatus::DEAD) {
				unitref.value().unit.on_turn_end();
			}
		}
	}
}

void BattleManagerFast::_update_move_end() {
	if(get_winner_team() >= 0) {
		return;
	}

	for(unsigned army_id = 0; army_id < _armies.size(); army_id++) {
		for(unsigned unit_id = 0; unit_id < _armies[army_id].units.size(); unit_id++) {
			auto uid = UnitID(army_id, unit_id);
			auto [unit, _army] = _get_unit(uid).value();

			if(unit.status == UnitStatus::DEAD) {
				continue;
			}

			if(unit.is_effect_active(Unit::FLAG_EFFECT_DEATH_MARK)) {
				_kill_unit(uid, NO_UNIT);
				continue;
			}
		}
	}
}

void BattleManagerFast::_update_mana_target() {
	auto [worst_idx, _] = _get_cyclone_worst_and_best_idx();
	_cyclone_target = worst_idx;
}

void BattleManagerFast::_update_mana() {
	auto [worst_idx, best_idx] = _get_cyclone_worst_and_best_idx();
	_cyclone_target = worst_idx;

	// Special case - while initializing don't modify cyclone counter
	if(_state == BattleState::INITIALIZING) {
		return;
	}

	auto mana_difference = _armies[best_idx].mana_points - _armies[worst_idx].mana_points;
	int16_t new_cyclone_counter = mana_difference > _cyclone_mana_threshold
		? _small_cyclone_counter_value : _big_cyclone_counter_value;
	
	// Cyclone killed a unit or got lower - resetting
	if(_armies[worst_idx].cyclone_timer == 0 || _armies[worst_idx].cyclone_timer > new_cyclone_counter) {
		_armies[worst_idx].cyclone_timer = new_cyclone_counter;
	}
}

std::pair<size_t, size_t> BattleManagerFast::_get_cyclone_worst_and_best_idx() const {
	int best_idx = -1, worst_idx = -1;

	for(unsigned i = 0; i < _armies.size(); i++) {
		if(!_armies[i].is_defeated()) {
			worst_idx = i;
			break;
		}
	}

	for(int i = _armies.size()-1; i >= 0; i--) {
		if(!_armies[i].is_defeated()) {
			best_idx = i;
			break;
		}
	}

	for(unsigned i = 0; i < _armies.size(); i++) {
		if(_armies[i].is_defeated()) {
			continue;
		}
		
		if(_armies[i].mana_points > _armies[best_idx].mana_points) {
			best_idx = i;
		}

		if(_armies[i].mana_points < _armies[worst_idx].mana_points) {
			worst_idx = i;
		}
	}
	return std::make_pair(worst_idx, best_idx);
}

int BattleManagerFast::get_winner_team() {

	if(_state == BattleState::SUMMONING) {
		return -1;
	}

	int last_team_alive = -2;
	int teams_alive = MAX_ARMIES;
	std::array<int, MAX_ARMIES> armies_in_teams_alive = {0,0,0,0};

	for(unsigned i = 0; i < _armies.size(); i++) {
		if(!_armies[i].is_defeated()) {
			armies_in_teams_alive[_armies[i].team] += 1;
		}
	}
	
	for(unsigned i = 0; i < MAX_ARMIES; i++) {
		if(armies_in_teams_alive[i] == 0) {
			teams_alive--;
		}
		else {
			last_team_alive = i;
		}
	}

	BM_ASSERT_V(teams_alive > 0, -2, "No teams alive after battle, should not be possible");

	if(teams_alive == 1) {
		_state = BattleState::FINISHED;
		return last_team_alive;
	}

	return -1;
}


const std::vector<Move>& BattleManagerFast::get_legal_moves() {
	if(_moves_dirty) {
		_refresh_legal_moves();
		_moves_dirty = false;
	}
	return _moves;
}

const std::vector<Move>& BattleManagerFast::get_heuristically_good_moves() {
	if(_heuristic_moves_dirty) {
		_refresh_heuristically_good_moves();
		_heuristic_moves_dirty = false;
	}
	if(_heuristic_moves.empty()) {
		return get_legal_moves();
	}
	return _heuristic_moves;
}

void BattleManagerFast::_next_army() {
	int limit = _current_army;
	do {
		_current_army = (_current_army+1) % _armies.size();
	} while(_armies[_current_army].is_defeated() && _current_army != limit);
}

void BattleManagerFast::_refresh_legal_moves() {
	_moves.clear();
	_moves.reserve(64);

	auto& army = _armies[_current_army];
	auto spawns = _tiles.get_spawns(_current_army);

	Move move;

	if(_state == BattleState::SUMMONING) {
		for(auto& spawn : spawns) {
			if(is_occupied(spawn, army, TeamRelation::ALLY)) {
				continue;
			}

			for(unsigned i = 0; i < army.units.size(); i++) {
				if(army.units[i].status != UnitStatus::SUMMONING) {
					continue;
				}

				move.unit = i;
				move.pos = spawn;
				_moves.push_back(move);
			}
		}
	}
	else if(_state == BattleState::ONGOING) {

		for(unsigned unit_id = 0; unit_id < army.units.size(); unit_id++) {
			auto& unit = army.units[unit_id];
			if(unit.status != UnitStatus::ALIVE) {
				continue;
			}

			for(int side = 0; side < 6; side++) {
				move.unit = unit_id;
				move.pos = unit.pos + DIRECTIONS[side];

				bool going_across_pit = _tiles.get_tile(move.pos).is_pit();
				if(going_across_pit) {
					if(side == unit.rotation) {
						move.pos = move.pos + DIRECTIONS[side];
					}
					else {
						continue;
					}
				}

				auto tile = _tiles.get_tile(move.pos);
				if(!(tile.is_passable()) && !(tile.is_hill() && side == unit.rotation && !going_across_pit)) {
					continue;
				}
				
				if(auto unit_opt = _get_unit(move.pos); unit_opt.has_value()) {
					auto [other_unit, other_army] = unit_opt.value();
					if(other_army.team == army.team || going_across_pit) {
						continue;
					}

					auto neighbor_symbol = other_unit.symbol_when_rotated(flip(side));
					auto unit_symbol = unit.front_symbol();

					if(neighbor_symbol.holds_ground_against(unit_symbol, MovePhase::LEAP)) {
						continue;
					}
				}

				// Align so that it is consistent with GDScript moves
				if(going_across_pit) {
					move.pos = move.pos - DIRECTIONS[side];
				}

				_moves.push_back(move);
			}
		}
		_spells_append_moves();
	}
	else if(_state == BattleState::SACRIFICE) {
		move.pos = Position();
		for(unsigned i = 0; i < army.units.size(); i++) {
			if(army.units[i].status == UnitStatus::ALIVE) {
				move.unit = i;
				_moves.push_back(move);
			}
		}
	}
	// else battle finished, no moves possible
}

void BattleManagerFast::_spells_append_moves() {
	for(unsigned i = 0; i < _spells.size(); i++) {
		auto& spell = _spells[i];
		if(spell.unit.army != _current_army || !_get_unit(spell.unit).has_value()) {
			continue;
		}
		if(spell.state == BattleSpell::State::SENTINEL) {
			break;
		}

		auto [unit, army] = _get_unit(spell.unit).value();
		if(unit.status == UnitStatus::DEAD) {
			spell.state = BattleSpell::State::NONE;
		}

		switch(spell.state) {
			case BattleSpell::State::TELEPORT:
				_append_moves_line(spell.unit, i, unit.pos, unit.rotation, 1, 3);
				break;
			case BattleSpell::State::FIREBALL:
				_append_moves_all_tiles(spell.unit, i, true);
				break;
			case BattleSpell::State::VENGEANCE:
				_append_moves_unit(spell.unit, i, TeamRelation::ME, true);
				break;
			case BattleSpell::State::MARTYR:
				_append_moves_unit(spell.unit, i, TeamRelation::ME, false);
				break;
			case BattleSpell::State::NONE:
			case BattleSpell::State::SENTINEL:
				break;
		}
	}
}

void BattleManagerFast::_refresh_heuristically_good_moves() {
	_heuristic_moves.clear();
	_heuristic_moves.reserve(64);

	if(_state == BattleState::SUMMONING) {
		_refresh_heuristically_good_summon_moves();
		return;
	}

	auto& army = _armies[_current_army];

	bool killing_move_found = false;

	for(auto& m : get_legal_moves()) {
		auto bm = *this;
		bm.play_move(m);
		auto result = bm.get_result();

		// Always win the game if possible and avoid defeats
		if(result.winner_team == army.team) {
			_heuristic_moves.clear();
			_heuristic_moves.push_back(m);
			return;
		}
		else if(result.winner_team != -1) {
			continue;
		}

		// If a move kills an enemy unit, prioritize killing move
		if(result.score_gained[_current_army] > 0) {
			if(!killing_move_found) {
				killing_move_found = true;
				_heuristic_moves.clear();
			}
			_heuristic_moves.push_back(m);
		}

		// If no killing move found, prioritize moves that don't result in a loss
		if(result.score_lost[_current_army] == 0 && !killing_move_found) {
			_heuristic_moves.push_back(m);
		}
	}
}

void BattleManagerFast::_refresh_heuristically_good_summon_moves() {
	auto& army = _armies[_current_army];

	bool enemy_has_unsummoned_bowman = false;
	for(auto& enemy_army : _armies) {
		if(enemy_army.team == army.team) {
			continue;
		}

		for(auto& enemy : enemy_army.units) {
			if(enemy.status == UnitStatus::SUMMONING && enemy.front_symbol().get_bow_force() > 0) {
				enemy_has_unsummoned_bowman = true;
				break;
			}
		}
	}

	// Avoid enemy bowman/find free bowman kills
	for(auto& m : get_legal_moves()) {
		auto& unit = army.units[m.unit];

		bool is_bowman = unit.front_symbol().get_bow_force() > 0;
		// Behavior when the spawn position is empty
		// At this moment assumes every spawn is not safe from bowman - good for now, but TODO?
		
		// Default - empty tile
		int move_score = (enemy_has_unsummoned_bowman || is_bowman) ? 0 : 1;

		for(unsigned enemy_army_id = 0; enemy_army_id < _armies.size(); enemy_army_id++) {
			auto& enemy_army = _armies[enemy_army_id];

			if(enemy_army.team == army.team) {
				continue;
			}

			for(auto& enemy : enemy_army.units) {
				bool can_shoot_enemy	  = unit.front_symbol().protects_against(enemy.front_symbol(), MovePhase::LEAP);
				bool enemy_can_shoot_unit = enemy.front_symbol().protects_against(unit.front_symbol(), MovePhase::LEAP);

				if(enemy.status != UnitStatus::ALIVE || !m.pos.is_in_line_with(enemy.pos)) {
					continue;
				}
				if(enemy_can_shoot_unit && !(can_shoot_enemy && _current_army > int(enemy_army_id)) ) {
					move_score = -100000;
					break;
				}
				// otherwise a normal enemy that's a free kill/not a threat
				if(!is_bowman || can_shoot_enemy) {
					move_score++;
				}
			}

		}
		if(move_score > 0) {
			_heuristic_moves.push_back(m);
		}
	}
}


std::pair<Move, bool> BattleManagerFast::get_random_move(float heuristic_probability) {
	static thread_local std::random_device rand_dev;
	static thread_local std::minstd_rand rand_engine{rand_dev()};
	static thread_local std::uniform_real_distribution heur_dist(0.0f, 1.0f);

	auto heur_chosen = heur_dist(rand_engine) < heuristic_probability;
	auto moves_arr = heur_chosen ? get_heuristically_good_moves() : get_legal_moves();

	BM_ASSERT_V(moves_arr.size() != 0, std::make_pair(Move{}, false), "BMFast - get_random_move has 0 moves to choose");
	
	std::uniform_int_distribution dist{0, int(moves_arr.size() - 1)};
	auto move = dist(rand_engine);

	return std::make_pair(moves_arr[move], heur_chosen);
}

unsigned BattleManagerFast::get_move_count() {
	return get_legal_moves().size();
}

godot::Array BattleManagerFastCpp::get_legal_moves_gd() {
	auto& moves_arr = bm.get_legal_moves();
	godot::Array arr{};
	
	for(auto& i: moves_arr) {
		arr.push_back(i.as_libspear_tuple());
	}

	return arr;
}

void BattleManagerFast::_append_moves_unit(UnitID uid, int8_t spell_id, TeamRelation relation, bool include_self) {
	auto [_, army] = _get_unit(uid).value();
	for(auto& other_army : _armies) {
		if(skip_army(army, other_army, relation)) {
			continue;
		}

		for(unsigned i = 0; i < other_army.units.size(); i++) {
			auto& unit = other_army.units[i];
			if(unit.status != UnitStatus::ALIVE || (!include_self && int(i) == uid.unit)) {
				continue;
			}

			_moves.emplace_back(uid.unit, unit.pos, spell_id);
		}
	}
}

void BattleManagerFast::_append_moves_all_tiles(UnitID uid, int8_t spell_id, bool include_impassable) {
	auto dims = _tiles.get_dims();
	for(int y = 0; y < dims.y; y++) {
		for(int x = 0; x < dims.x; x++) {
			auto pos = Position(x,y);
			if(include_impassable || (_tiles.get_tile(pos).is_passable() && _unit_cache.get(pos) == NO_UNIT)) {
				_moves.emplace_back(uid.unit, pos, spell_id);
			}
		}
	}
}

void BattleManagerFast::_append_moves_lines(UnitID uid, int8_t spell_id, Position center, int range_min, int range_max) {
	int range_min_real = (range_min >= 1) ? range_min : 1;
	if(range_min == 0 && _tiles.get_tile(center).is_passable()) {
		_moves.emplace_back(uid.unit, center, spell_id);
	}

	for(int dir = 0; dir < 6; dir++) {
		_append_moves_line(uid, spell_id, center, dir, range_min_real, range_max);
	}
}

void BattleManagerFast::_append_moves_line(UnitID uid, int8_t spell_id, Position center, uint8_t dir, int range_min, int range_max) {
	for(int r = range_min; r <= range_max; r++) {
		Position pos = center + DIRECTIONS[dir] * r;
		
		if(_tiles.get_tile(pos).is_passable() && _unit_cache.get(pos) == NO_UNIT) {
			_moves.emplace_back(uid.unit, pos, spell_id);
		}
	}
}

bool BattleManagerFast::is_occupied(Position pos, const Army& army, TeamRelation relation) const {
	for(auto& other_army : _armies) {
		if(skip_army(army, other_army, relation)) {
			continue;
		}

		for(auto& unit : other_army.units) {
			if(unit.status == UnitStatus::ALIVE && unit.pos == pos) {
				return true;
			}
		}
	}
	return false;
}

void BattleManagerFast::_move_unit(UnitID id, Position pos) {
	auto unit_opt = _get_unit(id);
	BM_ASSERT(unit_opt.has_value(), "Trying to move a dead unit");
	auto [unit, army] = unit_opt.value();
	BM_ASSERT(unit.status != UnitStatus::DEAD, "Trying to move a non-existent unit");
	BM_ASSERT(_unit_cache.get(pos) == NO_UNIT, "Unexpected unit during moving - units should be killed manually");

	if(unit.status == UnitStatus::ALIVE) {
		_unit_cache[unit.pos] = NO_UNIT;
	}

	unit.pos = pos;
	_unit_cache[pos] = id;
	auto tile = _tiles.get_tile(pos);

	if(tile.is_swamp()) {
		unit.flags |= Unit::FLAG_ON_SWAMP;
	}
	else {
		unit.flags &= ~Unit::FLAG_ON_SWAMP;
	}

	if(tile.is_mana_well()) {
		auto old_army = tile.get_controlling_army();
		if(old_army == army.id) {
			return;
		}

		if(size_t(old_army) < _armies.size()) {
			_armies[old_army].mana_points -= _mana_well_power;
		}

		tile.set_controlling_army(id.army);
		army.mana_points += _mana_well_power;
		_update_mana();
	}
}

void BattleManagerFast::_kill_unit(UnitID id, UnitID killer_id) {
	auto unit_opt = _get_unit(id);
	BM_ASSERT(unit_opt.has_value(), "Trying to move a dead unit");
	auto [unit, army] = unit_opt.value();
	BM_ASSERT(unit.status != UnitStatus::DEAD, "Trying to move a non-existent unit");

	auto victim_team = army.team;

	if(unit.get_martyr_id() != NO_UNIT) {
		auto martyr_opt = _get_unit(unit.get_martyr_id());
		BM_ASSERT(martyr_opt.has_value(), "Invalid martyr id");
		auto martyr = martyr_opt.value();

		auto pos = martyr.unit.pos;
		auto martyr_id = unit.get_martyr_id();

		unit.remove_martyr();
		martyr.unit.remove_martyr();
		_kill_unit(martyr_id, killer_id);
		_move_unit(id, pos);
		return;
	}

	_unit_cache[unit.pos] = NO_UNIT;
	unit.status = UnitStatus::DEAD;

	for(unsigned i = 0; i < MAX_ARMIES; i++) {
		if(_armies[i].team == victim_team) {
			_result.score_lost[i] -= unit.score;
			_result.total_scores[i] -= unit.score;

			BM_ASSERT(_result.total_scores[i] >= 0, "Total score for army {} = {} < 0", i, _result.total_scores[i]);
		}
		else {
			_result.score_gained[i] += unit.score;
		}
	}

	if(unit.mana > 0) {
		army.mana_points -= unit.mana;
		_update_mana();
	}

	if(unit.is_effect_active(Unit::FLAG_EFFECT_VENGEANCE) && killer_id != NO_UNIT && get_winner_team() == -1) {
		auto killer_opt = _get_unit(killer_id);
		BM_ASSERT(killer_opt.has_value(), "Unknown killer {}.{}", killer_id.unit, killer_id.army);

		unit.remove_effect(Unit::FLAG_EFFECT_VENGEANCE);
		killer_opt.value().unit.try_apply_effect(Unit::FLAG_EFFECT_DEATH_MARK);
	}
}


void BattleManagerFastCpp::insert_unit(int army, int idx, Vector2i pos, int rotation, bool is_summoning) {
	CHECK_UNIT(idx,);
	CHECK_ARMY(army,);
	bm._armies[army].units[idx].pos = pos;
	bm._armies[army].units[idx].rotation = rotation;
	bm._armies[army].units[idx].status = is_summoning ? UnitStatus::SUMMONING : UnitStatus::ALIVE;
	if(bm._tiles.get_tile(pos).is_swamp()) {
		bm._armies[army].units[idx].flags |= Unit::FLAG_ON_SWAMP;
	}
}

void BattleManagerFastCpp::set_unit_symbol(
		int army, int unit, int side, 
		int attack_strength, int defense_strength, int ranged_reach,
		bool is_counter, int push_force, bool parries, bool breaks_parry
) {
	CHECK_UNIT(unit,);
	CHECK_ARMY(army,);

	uint8_t flags = (parries	  ? Symbol::FLAG_PARRY : 0) 
				  | (breaks_parry ? Symbol::FLAG_PARRY_BREAK : 0) 
				  | (is_counter   ? Symbol::FLAG_COUNTER_ATTACK : 0);

	bm._armies[army].units[unit].sides[side] = Symbol(attack_strength, defense_strength, push_force, ranged_reach, flags);
}

void BattleManagerFastCpp::set_army_team(int army, int team) {
	CHECK_ARMY(army,);
	bm._armies[army].team = team;
}

void BattleManagerFastCpp::set_army_cyclone_timer(int army, int timer) {
	CHECK_ARMY(army,);
	bm._armies[army].cyclone_timer = timer;
}

void BattleManagerFastCpp::set_unit_score(int army, int unit, int score) {
	CHECK_UNIT(unit,);
	CHECK_ARMY(army,);

	bm._armies[army].units[unit].score = score;
}

void BattleManagerFastCpp::set_unit_mana(int army, int unit, int mana) {
	CHECK_UNIT(unit,);
	CHECK_ARMY(army,);

	bm._armies[army].units[unit].mana = mana;
}

void BattleManagerFastCpp::set_unit_effect(int army, int idx, godot::String effect, int duration) {
	CHECK_UNIT(idx,);
	CHECK_ARMY(army,);

	BM_ASSERT(effect != godot::String("Martyr"), "Martyr should be set with set_unit_martyr");
	
	bm._armies[army].units[idx].set_effect_gd(effect, duration);
}

void BattleManagerFastCpp::set_unit_martyr(int army, int idx, int martyr_idx, int duration) {
	CHECK_UNIT(idx,);
	CHECK_ARMY(army,);
	
	bm._armies[army].units[idx].try_apply_martyr(UnitID(army, martyr_idx), duration);
	bm._armies[army].units[martyr_idx].try_apply_martyr(UnitID(army, idx), duration);
}

void BattleManagerFastCpp::set_current_participant(int army) {
	CHECK_ARMY(army,);
	bm._current_army = army;
}

void BattleManagerFastCpp::set_tile_grid(TileGridFastCpp* tg) {
	BM_ASSERT(tg != nullptr, "TileGridFastCpp cannot be null");
	bm._tiles = tg->get_grid_copy();
	bm._unit_cache = CacheGrid(*tg);
}

void BattleManagerFastCpp::force_battle_ongoing() {
	BM_ASSERT(bm._state != BattleState::INITIALIZING, "Must finish_initialization() before calling force_battle_ongoing()");
	bm._state = BattleState::ONGOING;
}

void BattleManagerFastCpp::force_battle_sacrifice() {
	BM_ASSERT(bm._state != BattleState::INITIALIZING, "Must finish_initialization() before calling force_battle_sacrifice()");
	bm._state = BattleState::SACRIFICE;
}


godot::Array BattleManagerFastCpp::get_unit_id_on_position(Vector2i pos) const {
	godot::Array ret{};
	auto [army_id, unit_id] = bm._unit_cache.get(pos);
	ret.push_back(army_id);
	ret.push_back(unit_id);
	return ret;
}

int BattleManagerFastCpp::count_spell(int army, int idx, godot::String name) {
	CHECK_ARMY(army, 0);
	CHECK_UNIT(idx, 0);

	int i = 0;
	for(auto& spell : bm._spells) {
		if(spell.state == BattleSpell(name, NO_UNIT).state && spell.unit == UnitID(army, idx)) {
			i++;
		}
	}
	return i;
}

int BattleManagerFastCpp::get_unit_spell_count(int army, int idx) {
	CHECK_ARMY(army, 0);
	CHECK_UNIT(idx, 0);

	int i = 0;
	for(auto& spell : bm._spells) {
		if(spell.state != BattleSpell::State::NONE 
		   && spell.state != BattleSpell::State::SENTINEL
		   && spell.unit == UnitID(army, idx)
		) {
				i++;
		}
	}
	return i;
}

inline int BattleManagerFastCpp::get_unit_effect_count(int army, int idx) {
	CHECK_ARMY(army, 0);
	CHECK_UNIT(idx, 0);

	int i = 0;
	auto& unit = bm._armies[army].units[idx];
	for(auto& eff : unit.effects) {
		if(eff.mask != 0) {
			i++;
		}
	}
	return i;
}
	

void BattleManagerFastCpp::insert_spell(int army, int unit, int spell_id, godot::String str) {
	CHECK_UNIT(unit,);
	CHECK_ARMY(army,);
	BM_ASSERT(unsigned(spell_id) < MAX_SPELLS, "Invalid spell id when inserting spell");

	bm._spells[spell_id] = BattleSpell(str, UnitID(army, unit));
}

void BattleManagerFastCpp::set_cyclone_constants(int big, int small, int threshold, int mana_well_power) {
	bm._big_cyclone_counter_value = big;
	bm._small_cyclone_counter_value = small;
	bm._cyclone_mana_threshold = threshold;
	bm._mana_well_power = mana_well_power;
}

void BattleManagerFastCpp::_bind_methods() {
	ClassDB::bind_method(D_METHOD("insert_unit", "army", "index", "position", "rotation", "is_summoning"), &BattleManagerFastCpp::insert_unit);
	ClassDB::bind_method(D_METHOD(
		"set_unit_symbol_cpp", "army", "unit", "side", 
		"attack_strength", "defense_strength", "ranged_reach",
		"is_counter", "push_force", "parries", "breaks_parry"
 ), &BattleManagerFastCpp::set_unit_symbol);
	ClassDB::bind_method(D_METHOD("set_army_team", "army", "team"), &BattleManagerFastCpp::set_army_team);
	ClassDB::bind_method(D_METHOD("set_unit_score", "army", "unit", "score"), &BattleManagerFastCpp::set_unit_score);
	ClassDB::bind_method(D_METHOD("set_unit_mana", "army", "unit", "mana"), &BattleManagerFastCpp::set_unit_mana);
	ClassDB::bind_method(D_METHOD("set_unit_effect", "army", "unit", "effect", "duration"), &BattleManagerFastCpp::set_unit_effect);
	ClassDB::bind_method(D_METHOD("set_unit_martyr", "army", "unit", "martyr_id", "duration"), &BattleManagerFastCpp::set_unit_martyr);
	ClassDB::bind_method(D_METHOD("set_army_cyclone_timer", "army", "timer"), &BattleManagerFastCpp::set_army_cyclone_timer);
	ClassDB::bind_method(D_METHOD("set_tile_grid", "tilegrid"), &BattleManagerFastCpp::set_tile_grid);
	ClassDB::bind_method(D_METHOD("set_current_participant", "army"), &BattleManagerFastCpp::set_current_participant);
	ClassDB::bind_method(D_METHOD("set_cyclone_constants", "big", "small", "threshold", "mana_well_power"), &BattleManagerFastCpp::set_cyclone_constants);
	ClassDB::bind_method(D_METHOD("insert_spell", "army", "index", "spell"), &BattleManagerFastCpp::insert_spell);
	ClassDB::bind_method(D_METHOD("force_battle_ongoing"), &BattleManagerFastCpp::force_battle_ongoing);
	ClassDB::bind_method(D_METHOD("force_battle_sacrifice"), &BattleManagerFastCpp::force_battle_sacrifice);
	ClassDB::bind_method(D_METHOD("finish_initialization"), &BattleManagerFastCpp::finish_initialization);
	ClassDB::bind_method(D_METHOD("play_move", "libspear_tuple"), &BattleManagerFastCpp::play_move);
	ClassDB::bind_method(D_METHOD("play_moves", "libspear_tuples"), &BattleManagerFastCpp::play_moves);

	ClassDB::bind_method(D_METHOD("get_unit_position", "army", "unit"), &BattleManagerFastCpp::get_unit_position);
	ClassDB::bind_method(D_METHOD("get_unit_rotation", "army", "unit"), &BattleManagerFastCpp::get_unit_rotation);
	ClassDB::bind_method(D_METHOD("is_unit_alive", "army", "unit"), &BattleManagerFastCpp::is_unit_alive);
	ClassDB::bind_method(D_METHOD("is_unit_being_summoned", "army", "unit"), &BattleManagerFastCpp::is_unit_being_summoned);
	ClassDB::bind_method(D_METHOD("get_army_cyclone_timer", "army"), &BattleManagerFastCpp::get_army_cyclone_timer);
	ClassDB::bind_method(D_METHOD("get_army_mana_points", "army"), &BattleManagerFastCpp::get_army_mana_points);
	ClassDB::bind_method(D_METHOD("get_cyclone_target"), &BattleManagerFastCpp::get_cyclone_target);
	ClassDB::bind_method(D_METHOD("get_current_participant"), &BattleManagerFastCpp::get_current_participant);
	ClassDB::bind_method(D_METHOD("get_legal_moves"), &BattleManagerFastCpp::get_legal_moves_gd);
	ClassDB::bind_method(D_METHOD("get_unit_id_on_position", "position"), &BattleManagerFastCpp::get_unit_id_on_position);
	ClassDB::bind_method(D_METHOD("is_in_sacrifice_phase"), &BattleManagerFastCpp::is_in_sacrifice_phase);
	ClassDB::bind_method(D_METHOD("is_in_summoning_phase"), &BattleManagerFastCpp::is_in_summoning_phase);
	ClassDB::bind_method(D_METHOD("get_unit_effect", "army", "unit", "effect"), &BattleManagerFastCpp::get_unit_effect);
	ClassDB::bind_method(D_METHOD("get_unit_effect_duration_counter", "army", "unit", "effect"), 
			&BattleManagerFastCpp::get_unit_effect_duration_counter
	);
	ClassDB::bind_method(D_METHOD("get_unit_martyr_id", "army", "unit"), &BattleManagerFastCpp::get_unit_martyr_id);
	ClassDB::bind_method(D_METHOD("get_unit_martyr_team", "army", "unit"), &BattleManagerFastCpp::get_unit_martyr_team);
	ClassDB::bind_method(D_METHOD("count_spell", "name"), &BattleManagerFastCpp::count_spell);
	ClassDB::bind_method(D_METHOD("get_unit_effect_count", "army", "unit"), &BattleManagerFastCpp::get_unit_effect_count);
	ClassDB::bind_method(D_METHOD("get_unit_spell_count", "army", "unit"), &BattleManagerFastCpp::get_unit_spell_count);
	ClassDB::bind_method(D_METHOD("get_max_units_in_army"), &BattleManagerFastCpp::get_max_units_in_army);

	ClassDB::bind_method(D_METHOD("set_debug_internals", "name"), &BattleManagerFastCpp::set_debug_internals);
}
