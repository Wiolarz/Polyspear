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
    if(state == BattleState::INITIALIZING) {
        state = BattleState::SUMMONING;
        for(int i = 0; i < armies.size(); i++) {
            armies[i].id = i;
            for(auto& unit: armies[i].units) {
                if(unit.status != UnitStatus::DEAD) {
                    result.total_scores[i] += unit.score;
                }
            }
        }

        unit_cache.update_armies(armies);
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
    moves_dirty = true;
    heuristic_moves_dirty = true;

    result.winner_team = -1;
    result.score_gained.fill(0);
    result.score_lost.fill(0);

    previous_participant = current_participant;

    ERR_FAIL_COND_V_MSG(state == BattleState::INITIALIZING ,result, "BMFast - Please call finish_initialization() before playing a move");
    CHECK_UNIT(unit_id, result);
    
    UnitID uid = std::make_pair(current_participant, unit_id);
    auto& unit = armies[current_participant].units[unit_id];

    if(state == BattleState::SUMMONING) {
        if(unit.status != UnitStatus::SUMMONING) {
            WARN_PRINT("BMFast - unit is not in summoning state\n");
            return result;
        }

        if(tiles->get_tile(pos).get_spawning_army() != current_participant) {
            WARN_PRINT("BMFast - target spawn does not belong to current army, aborting\n");
            return result;
        }

        _move_unit(uid, pos);
        unit.rotation = tiles->get_tile(pos).get_spawn_rotation();
        unit.status = UnitStatus::ALIVE;

        bool end_summon = true;
        for(int i = (current_participant+1) % armies.size(); i != current_participant; i = (i+1)%armies.size()) {
            if(armies[i].find_summon_id() != -1) {
                current_participant = i;
                end_summon = false;
                break;
            }
        }

        if(end_summon) {
            state = BattleState::ONGOING;
        }
    }
    else if(state == BattleState::ONGOING) {
        auto rot_new = get_rotation(unit.pos, pos);

        if(rot_new == 6) {
            WARN_PRINT("BMFast - target position is not a neighbor\n");
            return result;
        }

        unit.rotation = rot_new;
        _process_unit(uid, true);
        
        if(unit.status == UnitStatus::ALIVE) {
            _move_unit(uid, pos);
            _process_unit(uid, true);
        }
        
        int limit = current_participant;
        do {
            current_participant = (current_participant+1) % armies.size();
        } while(armies[current_participant].is_defeated() && current_participant != limit);
    }
    else {
        WARN_PRINT("BMFast - battle already ended, did not expect that\n");
        return result;
    }

    result.winner_team = get_winner_team();

    // Test whether all cache updates are correct
    unit_cache.self_test(armies);

    return result;
}


void BattleManagerFastCpp::_process_unit(UnitID unit_id, bool process_kills) {
    auto [unit, army] = _get_unit(unit_id);

    for(int i = 0; i < 6; i++) {
        auto pos = unit->pos + DIRECTIONS[i];
        auto neighbor_id = unit_cache.get(pos);
        auto [neighbor, enemy_army] = _get_unit(neighbor_id);

        if(!neighbor || !enemy_army || neighbor->status != UnitStatus::ALIVE || enemy_army->team == army->team) {
            continue;
        }

        auto rot_unit_to_neighbor = get_rotation(unit->pos, neighbor->pos);
        auto rot_neighbor_to_unit = flip(rot_unit_to_neighbor);

        // Skip non-neighbors
        if( rot_unit_to_neighbor == 6 ) {
            raise(SIGINT);
            continue;
        }
        
        auto unit_symbol = unit->symbol_at_side(rot_unit_to_neighbor);
        auto neighbor_symbol = neighbor->symbol_at_side(rot_neighbor_to_unit);

        // counter/spear
        if(neighbor_symbol.get_counter_force() > 0 && unit_symbol.get_defense_force() < neighbor_symbol.get_counter_force()) {
            //unit.kill(enemy_army.id, army.id, out_result);
            _kill_unit(unit_id, enemy_army->team);
            return;
        }

        if(process_kills) {
            if(unit_symbol.get_attack_force() > 0 && neighbor_symbol.get_defense_force() < unit_symbol.get_attack_force()) {
                //neighbor->kill(army.id, enemy_army.id, out_result);
                _kill_unit(neighbor_id, army->team);
            }

            if(unit_symbol.pushes()) {
                auto new_pos = neighbor->pos + neighbor->pos - unit->pos;
                if(!(tiles->get_tile(new_pos).is_passable()) || _get_unit(new_pos).first != nullptr) {
                    //neighbor->kill(army->id, enemy_army.id, out_result);
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
        auto force = unit->symbol_at_side(i).get_bow_force();
        if(force == 0) {
            continue;
        }

        auto iter = DIRECTIONS[i];

        for(auto pos = unit->pos + iter; !(tiles->get_tile(pos).is_wall()); pos = pos + iter) {
            //if(is_occupied(pos, army->team, TeamRelation::ALLY)) {
            //    break;
            //}

            auto other_id = unit_cache.get(pos);
            auto [other, other_army] = _get_unit(other_id);

            if(!other && !other_army) {
                continue;
            }

            if(other_army->team == army->team) {
                break;
            }

            if(other != nullptr && other->symbol_at_side(flip(i)).get_defense_force() < force) {
                //other->kill(army->id, enemy_army.id, out_result);
                _kill_unit(other_id, army->team);
                break;
            }
        }
    }
}

int BattleManagerFastCpp::get_winner_team() {

    if(state == BattleState::SUMMONING) {
        return -1;
    }

    int last_team_alive = -2;
    int teams_alive = 4;
    std::array<int, 4> armies_in_teams_alive = {0,0,0,0};

    for(int i = 0; i < armies.size(); i++) {
        if(!armies[i].is_defeated()) {
            armies_in_teams_alive[armies[i].team] += 1;
        }
    }
    
    for(int i = 0; i < 4; i++) {
        if(armies_in_teams_alive[i] == 0) {
            teams_alive--;
        }
        else {
            last_team_alive = i;
        }
    }

    if(teams_alive == 0) {
        ERR_PRINT("C++ Assertion failed: no teams alive after battle, should not be possible");
        state = BattleState::FINISHED;
        return -2;
    }

    if(teams_alive == 1) {
        state = BattleState::FINISHED;
        return last_team_alive;
    }

    return -1;
}


const std::vector<Move>& BattleManagerFastCpp::get_legal_moves() {
    if(moves_dirty) {
        _refresh_legal_moves();
        moves_dirty = false;
    }
    return moves;
}

const std::vector<Move>& BattleManagerFastCpp::get_heuristically_good_moves() {
    if(heuristic_moves_dirty) {
        _refresh_heuristically_good_moves();
        heuristic_moves_dirty = false;
    }
    if(heuristic_moves.empty()) {
        return get_legal_moves();
    }
    return heuristic_moves;
}

void BattleManagerFastCpp::_refresh_legal_moves() {
    moves.clear();
    moves.reserve(64);

    auto& army = armies[current_participant];
    auto& spawns = tiles->get_spawns(current_participant);

    Move move;

    if(state == BattleState::SUMMONING) {
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
                moves.push_back(move);
            }
        }
    }
    else if(state == BattleState::ONGOING) {

        for(int unit_id = 0; unit_id < army.units.size(); unit_id++) {
            auto& unit = army.units[unit_id];
            if(unit.status != UnitStatus::ALIVE) {
                continue;
            }

            for(int side = 0; side < 6; side++) {
                move.unit = unit_id;
                move.pos = unit.pos + DIRECTIONS[side];

                if(!tiles->get_tile(move.pos).is_passable()) {
                    continue;
                }
                
                auto [other_unit, other_army] = _get_unit(move.pos);
                if(other_unit && other_army) {
                    if(other_army->team == army.team) {
                        continue;
                    }

                    auto rot_neighbor_to_unit = get_rotation(other_unit->pos, unit.pos);
                    auto neighbor_symbol = other_unit->symbol_at_side(rot_neighbor_to_unit);

                    if(neighbor_symbol.get_defense_force() >= MIN_SHIELD_DEFENSE) {
                        continue;
                    }
                }
                /*for(auto& other_army : armies) {
                    for(auto& other_unit : other_army.units) {
                        if( !(other_unit.status == UnitStatus::ALIVE && other_unit.pos == move.pos) ) {
                            continue;
                        }

                        if(other_army.team == army.team) {
                            discard = true;
                        }

                        auto rot_neighbor_to_unit = get_rotation(other_unit.pos, unit.pos);
                        auto neighbor_symbol = other_unit.symbol_at_side(rot_neighbor_to_unit);

                        if(neighbor_symbol.get_defense_force() >= MIN_SHIELD_DEFENSE) {
                            discard = true;
                        }
                    }
                }*/

                moves.push_back(move);
            }
        }
    }
}

void BattleManagerFastCpp::_refresh_heuristically_good_moves() {
    heuristic_moves.clear();
    heuristic_moves.reserve(64);

    if(state == BattleState::SUMMONING) {
        _refresh_heuristically_good_summon_moves();
        return;
    }

    auto& army = armies[current_participant];

    std::vector<BattleResult> move_results;
    bool killing_move_found = false;


    for(auto& m : get_legal_moves()) {
        auto bm = *this;
        auto result = bm.play_move(m);
        
        // Always win the game if possible and avoid defeats
        if(result.winner_team == army.team) {
            heuristic_moves.clear();
            heuristic_moves.push_back(m);
            return;
        }
        else if(result.winner_team != -1) {
            continue;
        }

        // If a move kills an enemy unit, prioritize killing move
        if(result.score_gained[current_participant] > 0) {
            if(!killing_move_found) {
                killing_move_found = true;
                heuristic_moves.clear();
            }
            heuristic_moves.push_back(m);
        }

        // If no killing move found, prioritize moves that don't result in a loss
        if(result.score_lost[current_participant] == 0 && !killing_move_found) {
            heuristic_moves.push_back(m);
        }
    }
}

void BattleManagerFastCpp::_refresh_heuristically_good_summon_moves() {
    auto& army = armies[current_participant];

    bool enemy_has_unsummoned_bowman = false;
    for(auto& enemy_army : armies) {
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

    for(auto& m : get_legal_moves()) {
        auto& unit = army.units[m.unit];
        // At this moment assumes every spawn is not safe from bowman - good for now, but TODO?

        // Summon bowman preferrably only on tiles where an enemy can be shot
        if(unit.sides[0].get_bow_force() > 0) {
            for(auto& enemy_army : armies) {
                if(enemy_army.team == army.team) {
                    continue;
                }
                    
                for(auto& enemy : enemy_army.units) {
                    if(enemy.status == UnitStatus::ALIVE && m.pos.is_in_line_with(enemy.pos) && enemy.sides[0].get_defense_force() < unit.sides[0].get_bow_force()) {
                        heuristic_moves.push_back(m);
                    }
                }
            }
        }

        // Avoid yet-unsummoned bowman - only spawn when there's a non-bowman unit on the other side
        if(enemy_has_unsummoned_bowman) {
            for(auto& enemy_army : armies) {
                if(enemy_army.team == army.team) {
                    continue;
                }

                for(auto& enemy : enemy_army.units) {
                    if(enemy.status == UnitStatus::ALIVE && m.pos.is_in_line_with(enemy.pos) && enemy.sides[0].get_bow_force() <= unit.sides[0].get_defense_force()) {
                        heuristic_moves.push_back(m);
                    }
                }
            }
        }
    }
}


std::pair<Move, bool> BattleManagerFastCpp::get_random_move(float heuristic_probability) {
    static thread_local std::mt19937 rand_engine;
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
    for(auto& army : armies) {
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
        unit_cache[unit->pos] = NO_UNIT;
    }

    unit->pos = pos;
    if(unit_cache.get(pos) != NO_UNIT) {
        ERR_FAIL_MSG("Unexpected unit during moving - units should be killed manually");
    }
    unit_cache[pos] = id;
}

void BattleManagerFastCpp::_kill_unit(UnitID id, int killer_team) {
    auto [unit, army] = _get_unit(id);
    auto victim_team = army->team;

    unit_cache[unit->pos] = NO_UNIT;
    unit->status = UnitStatus::DEAD;
    result.score_gained[killer_team] += unit->score;
    result.score_lost[victim_team] -= unit->score;
    result.total_scores[victim_team] -= unit->score;
}


void BattleManagerFastCpp::insert_unit(int army, int idx, Vector2i pos, int rotation, bool is_summoning) {
    CHECK_UNIT(idx,);
    CHECK_ARMY(army,);
    armies[army].units[idx].pos = pos;
    armies[army].units[idx].rotation = rotation;
    armies[army].units[idx].status = is_summoning ? UnitStatus::SUMMONING : UnitStatus::ALIVE;
}

void BattleManagerFastCpp::set_unit_symbol(int army, int unit, int side, int symbol) {
    CHECK_UNIT(unit,);
    CHECK_ARMY(army,);
    armies[army].units[unit].sides[side] = Symbol(symbol);
}

void BattleManagerFastCpp::set_army_team(int army, int team) {
    CHECK_ARMY(army,);
    armies[army].team = team;
}

void BattleManagerFastCpp::set_current_participant(int army) {
    CHECK_ARMY(army,);
    current_participant = army;
}

void BattleManagerFastCpp::set_tile_grid(TileGridFastCpp* tg) {
    tiles = tg;
    unit_cache = CacheGrid(*tg);
}

void BattleManagerFastCpp::force_battle_ongoing() {
    if(state == BattleState::INITIALIZING) {
        ERR_FAIL_MSG("Must finish_initialization() before calling force_battle_ongoing()");
    }
    state = BattleState::ONGOING;
}

std::pair<Unit*, Army*> BattleManagerFastCpp::_get_unit(UnitID id) {
    if(id == NO_UNIT) {
        return std::make_pair(nullptr, nullptr);
    }
    return std::make_pair(&armies[id.first].units[id.second], &armies[id.first]);
}

std::pair<Unit*, Army*> BattleManagerFastCpp::_get_unit(Position coord) {
    return _get_unit(unit_cache.get(coord));
}

void BattleManagerFastCpp::_bind_methods() {
    ClassDB::bind_method(D_METHOD("insert_unit"), &BattleManagerFastCpp::insert_unit, "army", "index", "position", "rotation", "is_summoning");
    ClassDB::bind_method(D_METHOD("set_unit_symbol"), &BattleManagerFastCpp::set_unit_symbol, "army", "index", "symbol_slot", "symbol_type");
    ClassDB::bind_method(D_METHOD("set_army_team"), &BattleManagerFastCpp::set_army_team, "army", "team");
    ClassDB::bind_method(D_METHOD("set_tile_grid"), &BattleManagerFastCpp::set_tile_grid, "tilegrid");
    ClassDB::bind_method(D_METHOD("set_current_participant"), &BattleManagerFastCpp::set_current_participant, "army");
    ClassDB::bind_method(D_METHOD("force_battle_ongoing"), &BattleManagerFastCpp::force_battle_ongoing);
    ClassDB::bind_method(D_METHOD("finish_initialization"), &BattleManagerFastCpp::finish_initialization);
    ClassDB::bind_method(D_METHOD("play_move"), &BattleManagerFastCpp::play_move_gd, "unit", "position");

    ClassDB::bind_method(D_METHOD("get_unit_position"), &BattleManagerFastCpp::get_unit_position, "army", "unit");
    ClassDB::bind_method(D_METHOD("get_unit_rotation"), &BattleManagerFastCpp::get_unit_rotation, "army", "unit");
    ClassDB::bind_method(D_METHOD("is_unit_alive"), &BattleManagerFastCpp::is_unit_alive, "army", "unit");
    ClassDB::bind_method(D_METHOD("is_unit_being_summoned"), &BattleManagerFastCpp::is_unit_being_summoned, "army", "unit");
    ClassDB::bind_method(D_METHOD("get_current_participant"), &BattleManagerFastCpp::get_current_participant);
    ClassDB::bind_method(D_METHOD("get_legal_moves"), &BattleManagerFastCpp::get_legal_moves_gd);

}
