#include "fast_battle_manager.hpp"
#include "godot_cpp/core/class_db.hpp"
#include "battle_mcts.hpp"
 
#include <algorithm>
#include <stdlib.h>
#include <random>
#include <csignal>
#include <format>


#define CHECK_UNIT(idx, ret) ERR_FAIL_COND_V_MSG(idx >= MAX_UNITS_IN_ARMY, ret, std::format("BMFast - invalid unit id {}", idx).c_str())
#define CHECK_ARMY(idx, ret) ERR_FAIL_COND_V_MSG(idx >= MAX_ARMIES, ret, std::format("BMFast - invalid army id {}", idx).c_str())

void BattleManagerFastCpp::finish_initialization() {
    if(_state == BattleState::INITIALIZING) {
        _state = BattleState::SUMMONING;
        for(int i = 0; i < _armies.size(); i++) {
            _armies[i].id = i;
            for(auto& unit: _armies[i].units) {
                if(unit.status != UnitStatus::DEAD) {
                    _result.total_scores[i] += unit.score;
                    _result.max_scores[i]   += unit.score;
                }
            }
        }

        _unit_cache.update_armies(_armies);
    }
    else {
        WARN_PRINT("BMFast already initialized");
    }
}

BattleResult BattleManagerFastCpp::play_move(Move move) {
    auto ret = _play_move(move.unit, Vector2i(move.pos.x, move.pos.y));
    return ret;
}

int BattleManagerFastCpp::play_move_gd(unsigned unit_id, Vector2i pos) {
    auto ret = _play_move(unit_id, pos);
    return ret.winner_team;
}

BattleResult BattleManagerFastCpp::_play_move(unsigned unit_id, Vector2i pos) {
    _moves_dirty = true;
    _heuristic_moves_dirty = true;

    _result.winner_team = -1;
    _result.score_gained.fill(0);
    _result.score_lost.fill(0);

    _previous_army = _current_army;

    ERR_FAIL_COND_V_MSG(_state == BattleState::INITIALIZING, _result, "BMFast - Please call finish_initialization() before playing a move");
    CHECK_UNIT(unit_id, _result);
    
    UnitID uid = std::make_pair(_current_army, unit_id);
    auto& unit = _armies[_current_army].units[unit_id];

    if(_state == BattleState::SUMMONING) {
        if(unit.status != UnitStatus::SUMMONING) {
            WARN_PRINT("BMFast - unit is not in summoning state\n");
            return _result;
        }

        if(_tiles->get_tile(pos).get_spawning_army() != _current_army) {
            WARN_PRINT("BMFast - target spawn does not belong to current army, aborting\n");
            return _result;
        }

        _move_unit(uid, pos);
        unit.rotation = _tiles->get_tile(pos).get_spawn_rotation();
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
            _state = BattleState::ONGOING;
        }
    }
    else if(_state == BattleState::ONGOING) {
        auto rot_new = get_rotation(unit.pos, pos);

        if(rot_new == 6) {
            WARN_PRINT("BMFast - target position is not a neighbor\n");
            return _result;
        }

        unit.rotation = rot_new;
        _process_unit(uid, true);
        
        if(unit.status == UnitStatus::ALIVE) {
            _move_unit(uid, pos);
            _process_unit(uid, true);
        }
        
        int limit = _current_army;
        do {
            _current_army = (_current_army+1) % _armies.size();
        } while(_armies[_current_army].is_defeated() && _current_army != limit);
    }
    else {
        WARN_PRINT("BMFast - battle already ended, did not expect that\n");
        return _result;
    }

    _result.winner_team = get_winner_team();

    // Test whether all cache updates are correct
    //unit_cache.self_test(armies);

    return _result;
}


void BattleManagerFastCpp::_process_unit(UnitID unit_id, bool process_kills) {
    auto [unit, army] = _get_unit(unit_id);

    for(int side = 0; side < 6; side++) {
        auto pos = unit->pos + DIRECTIONS[side];
        auto neighbor_id = _unit_cache.get(pos);
        auto [neighbor, enemy_army] = _get_unit(neighbor_id);

        if(!neighbor || !enemy_army || neighbor->status != UnitStatus::ALIVE || enemy_army->team == army->team) {
            continue;
        }

        auto unit_symbol = unit->symbol_at_abs_side(side);
        auto neighbor_symbol = neighbor->symbol_at_abs_side(flip(side));

        // counter/spear
        if(neighbor_symbol.get_counter_force() > 0 && unit_symbol.get_defense_force() < neighbor_symbol.get_counter_force()) {
            _kill_unit(unit_id, enemy_army->team);
            return;
        }

        if(process_kills) {
            if(unit_symbol.get_attack_force() > 0 && neighbor_symbol.get_defense_force() < unit_symbol.get_attack_force()) {
                _kill_unit(neighbor_id, army->team);
            }

            if(unit_symbol.pushes()) {
                auto new_pos = neighbor->pos + neighbor->pos - unit->pos;
                if(!(_tiles->get_tile(new_pos).is_passable()) || _get_unit(new_pos).first != nullptr) {
                    _kill_unit(neighbor_id, army->team);
                }
                else {
                    _move_unit(neighbor_id, new_pos);
                    _process_unit(neighbor_id, false);
                }
            }
        }
    }

    if(process_kills) {
        _process_bow(unit_id);
    }
}

void BattleManagerFastCpp::_process_bow(UnitID unit_id) {
    auto [unit, army] = _get_unit(unit_id);

    for(int i = 0; i < 6; i++) {
        auto force = unit->symbol_at_abs_side(i).get_bow_force();
        if(force == 0) {
            continue;
        }

        auto iter = DIRECTIONS[i];

        for(auto pos = unit->pos + iter; !(_tiles->get_tile(pos).is_wall()); pos = pos + iter) {
            auto other_id = _unit_cache.get(pos);
            auto [other, other_army] = _get_unit(other_id);

            if(!other && !other_army) {
                continue;
            }

            if(other_army->team == army->team) {
                break;
            }

            if(other != nullptr && other->symbol_at_abs_side(flip(i)).get_defense_force() < force) {
                _kill_unit(other_id, army->team);
                break;
            }
        }
    }
}

int BattleManagerFastCpp::get_winner_team() {

    if(_state == BattleState::SUMMONING) {
        return -1;
    }

    int last_team_alive = -2;
    int teams_alive = MAX_ARMIES;
    std::array<int, MAX_ARMIES> armies_in_teams_alive = {0,0,0,0};

    for(int i = 0; i < _armies.size(); i++) {
        if(!_armies[i].is_defeated()) {
            armies_in_teams_alive[_armies[i].team] += 1;
        }
    }
    
    for(int i = 0; i < MAX_ARMIES; i++) {
        if(armies_in_teams_alive[i] == 0) {
            teams_alive--;
        }
        else {
            last_team_alive = i;
        }
    }

    if(teams_alive == 0) {
        ERR_PRINT("C++ Assertion failed: no teams alive after battle, should not be possible");
        _state = BattleState::FINISHED;
        return -2;
    }

    if(teams_alive == 1) {
        _state = BattleState::FINISHED;
        return last_team_alive;
    }

    return -1;
}


const std::vector<Move>& BattleManagerFastCpp::get_legal_moves() {
    if(_moves_dirty) {
        _refresh_legal_moves();
        _moves_dirty = false;
    }
    return _moves;
}

const std::vector<Move>& BattleManagerFastCpp::get_heuristically_good_moves() {
    if(_heuristic_moves_dirty) {
        _refresh_heuristically_good_moves();
        _heuristic_moves_dirty = false;
    }
    if(_heuristic_moves.empty()) {
        return get_legal_moves();
    }
    return _heuristic_moves;
}

void BattleManagerFastCpp::_refresh_legal_moves() {
    _moves.clear();
    _moves.reserve(64);

    auto& army = _armies[_current_army];
    auto& spawns = _tiles->get_spawns(_current_army);

    Move move;

    if(_state == BattleState::SUMMONING) {
        for(auto& spawn : spawns) {
            if(is_occupied(spawn, army.team, TeamRelation::ALLY)) {
                continue;
            }

            for(int i = 0; i < army.units.size(); i++) {
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

        for(int unit_id = 0; unit_id < army.units.size(); unit_id++) {
            auto& unit = army.units[unit_id];
            if(unit.status != UnitStatus::ALIVE) {
                continue;
            }

            for(int side = 0; side < 6; side++) {
                move.unit = unit_id;
                move.pos = unit.pos + DIRECTIONS[side];

                if(!_tiles->get_tile(move.pos).is_passable()) {
                    continue;
                }
                
                auto [other_unit, other_army] = _get_unit(move.pos);
                if(other_unit && other_army) {
                    if(other_army->team == army.team) {
                        continue;
                    }

                    auto neighbor_symbol = other_unit->symbol_at_abs_side(flip(side));

                    if(neighbor_symbol.get_defense_force() >= MIN_SHIELD_DEFENSE) {
                        continue;
                    }
                }

                _moves.push_back(move);
            }
        }
    }
}

void BattleManagerFastCpp::_refresh_heuristically_good_moves() {
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
        auto result = bm.play_move(m);
        
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

void BattleManagerFastCpp::_refresh_heuristically_good_summon_moves() {
    auto& army = _armies[_current_army];

    bool enemy_has_unsummoned_bowman = false;
    for(auto& enemy_army : _armies) {
        if(enemy_army.team == army.team) {
            continue;
        }

        for(auto& enemy : enemy_army.units) {
            if(enemy.status == UnitStatus::SUMMONING && enemy.sides[0].get_bow_force() > 0) {
                enemy_has_unsummoned_bowman = true;
                break;
            }
        }
    }

    // Avoid enemy bowman/find free bowman kills
    for(auto& m : get_legal_moves()) {
        auto& unit = army.units[m.unit];

        bool is_bowman = unit.sides[0].get_bow_force() > 0;
        // Behavior when the spawn position is empty
        // At this moment assumes every spawn is not safe from bowman - good for now, but TODO?
        
        // Default - empty tile
        int move_score = (enemy_has_unsummoned_bowman || is_bowman) ? 0 : 1;

        for(int enemy_army_id = 0; enemy_army_id < _armies.size(); enemy_army_id++) {
            auto& enemy_army = _armies[enemy_army_id];

            if(enemy_army.team == army.team) {
                continue;
            }

            for(auto& enemy : enemy_army.units) {
                bool can_shoot_enemy      = unit.sides[0].get_bow_force() > enemy.sides[0].get_defense_force();
                bool enemy_can_shoot_unit = enemy.sides[0].get_bow_force() > unit.sides[0].get_defense_force();

                if(enemy.status != UnitStatus::ALIVE || !m.pos.is_in_line_with(enemy.pos)) {
                    continue;
                }
                if(enemy_can_shoot_unit && !(can_shoot_enemy && _current_army > enemy_army_id) ) {
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


std::pair<Move, bool> BattleManagerFastCpp::get_random_move(float heuristic_probability) {
    static thread_local std::minstd_rand rand_engine;
    static thread_local std::uniform_real_distribution heur_dist(0.0f, 1.0f);

    auto heur_chosen = heur_dist(rand_engine) < heuristic_probability;
    auto moves_arr = heur_chosen ? get_heuristically_good_moves() : get_legal_moves();

    ERR_FAIL_COND_V_MSG(moves_arr.size() == 0, std::make_pair(Move{}, false), "BMFast - get_random_move has 0 moves to choose");
    
    std::uniform_int_distribution dist{0, int(moves_arr.size() - 1)};
    auto move = dist(rand_engine);

    return std::make_pair(moves_arr[move], heur_chosen);
}

int BattleManagerFastCpp::get_move_count() {
    return get_legal_moves().size();
}

godot::Array BattleManagerFastCpp::get_legal_moves_gd() {
    auto& moves_arr = get_legal_moves();
    godot::Array arr{};
    
    for(auto& i: moves_arr) {
        godot::Array val{};
        val.push_back(i.unit);
        val.push_back(Vector2i(i.pos.x, i.pos.y));
        arr.push_back(val);
    }

    return arr;
}

bool BattleManagerFastCpp::is_occupied(Position pos, int team, TeamRelation relation) const {
    for(auto& army : _armies) {
        if( (army.team == team) != (relation == TeamRelation::ALLY) ) {
            continue;
        }

        for(auto& unit : army.units) {
            if(unit.status == UnitStatus::ALIVE && unit.pos == pos) {
                return true;
            }
        }
    }
    return false;
}

void BattleManagerFastCpp::_move_unit(UnitID id, Position pos) {
    auto [unit, army] = _get_unit(id);

    if(unit->status == UnitStatus::ALIVE) {
        _unit_cache[unit->pos] = NO_UNIT;
    }

    unit->pos = pos;
    if(_unit_cache.get(pos) != NO_UNIT) {
        ERR_FAIL_MSG("Unexpected unit during moving - units should be killed manually");
    }
    _unit_cache[pos] = id;
}

void BattleManagerFastCpp::_kill_unit(UnitID id, int killer_team) {
    auto [unit, army] = _get_unit(id);
    auto victim_team = army->team;

    _unit_cache[unit->pos] = NO_UNIT;
    unit->status = UnitStatus::DEAD;
    _result.score_gained[killer_team] += unit->score;
    _result.score_lost[victim_team] -= unit->score;
    _result.total_scores[victim_team] -= unit->score;
}


void BattleManagerFastCpp::insert_unit(int army, int idx, Vector2i pos, int rotation, bool is_summoning) {
    CHECK_UNIT(idx,);
    CHECK_ARMY(army,);
    _armies[army].units[idx].pos = pos;
    _armies[army].units[idx].rotation = rotation;
    _armies[army].units[idx].status = is_summoning ? UnitStatus::SUMMONING : UnitStatus::ALIVE;
}

void BattleManagerFastCpp::set_unit_symbol(int army, int unit, int side, int symbol) {
    CHECK_UNIT(unit,);
    CHECK_ARMY(army,);
    _armies[army].units[unit].sides[side] = Symbol(symbol);
}

void BattleManagerFastCpp::set_army_team(int army, int team) {
    CHECK_ARMY(army,);
    _armies[army].team = team;
}

void BattleManagerFastCpp::set_current_participant(int army) {
    CHECK_ARMY(army,);
    _current_army = army;
}

void BattleManagerFastCpp::set_tile_grid(TileGridFastCpp* tg) {
    _tiles = tg;
    _unit_cache = CacheGrid(*tg);
}

void BattleManagerFastCpp::force_battle_ongoing() {
    if(_state == BattleState::INITIALIZING) {
        ERR_FAIL_MSG("Must finish_initialization() before calling force_battle_ongoing()");
    }
    _state = BattleState::ONGOING;
}


godot::Array BattleManagerFastCpp::get_unit_id_on_position(Vector2i pos) const {
    godot::Array ret{};
    auto [army_id, unit_id] = _unit_cache.get(pos);
    ret.push_back(army_id);
    ret.push_back(unit_id);
    return ret;
}

void BattleManagerFastCpp::_bind_methods() {
    ClassDB::bind_method(D_METHOD("insert_unit", "army", "index", "position", "rotation", "is_summoning"), &BattleManagerFastCpp::insert_unit);
    ClassDB::bind_method(D_METHOD("set_unit_symbol", "army", "index", "symbol_slot", "symbol_type"), &BattleManagerFastCpp::set_unit_symbol);
    ClassDB::bind_method(D_METHOD("set_army_team", "army", "team"), &BattleManagerFastCpp::set_army_team);
    ClassDB::bind_method(D_METHOD("set_tile_grid", "tilegrid"), &BattleManagerFastCpp::set_tile_grid);
    ClassDB::bind_method(D_METHOD("set_current_participant", "army"), &BattleManagerFastCpp::set_current_participant);
    ClassDB::bind_method(D_METHOD("force_battle_ongoing"), &BattleManagerFastCpp::force_battle_ongoing);
    ClassDB::bind_method(D_METHOD("finish_initialization"), &BattleManagerFastCpp::finish_initialization);
    ClassDB::bind_method(D_METHOD("play_move", "unit", "position"), &BattleManagerFastCpp::play_move_gd);

    ClassDB::bind_method(D_METHOD("get_unit_position", "army", "unit"), &BattleManagerFastCpp::get_unit_position);
    ClassDB::bind_method(D_METHOD("get_unit_rotation", "army", "unit"), &BattleManagerFastCpp::get_unit_rotation);
    ClassDB::bind_method(D_METHOD("is_unit_alive", "army", "unit"), &BattleManagerFastCpp::is_unit_alive);
    ClassDB::bind_method(D_METHOD("is_unit_being_summoned", "army", "unit"), &BattleManagerFastCpp::is_unit_being_summoned);
    ClassDB::bind_method(D_METHOD("get_current_participant"), &BattleManagerFastCpp::get_current_participant);
    ClassDB::bind_method(D_METHOD("get_legal_moves"), &BattleManagerFastCpp::get_legal_moves_gd);
    ClassDB::bind_method(D_METHOD("get_unit_id_on_position", "position"), &BattleManagerFastCpp::get_unit_id_on_position);

}
