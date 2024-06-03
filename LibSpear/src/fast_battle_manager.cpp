#include "fast_battle_manager.hpp"
#include "godot_cpp/core/class_db.hpp"
#include "battle_mcts.hpp"
 
#include <algorithm>
#include <stdlib.h>
#include <random>

#define CHECK_UNIT(idx, val) \
    if(idx >= 5) { \
        printf("ERROR - Unknown unit id %d\n", idx);\
		::godot::_err_print_error(FUNCTION_STR, __FILE__, __LINE__, "ERROR - Unknown unit id - check stdout"); \
        return val;\
    }

#define CHECK_ARMY(idx, val) \
    if(idx >= 2) { \
        printf("ERROR - Unknown army id %d\n", idx); \
		::godot::_err_print_error(FUNCTION_STR, __FILE__, __LINE__, "ERROR - Unknown army id - check stdout"); \
        return val; \
    }

int BattleManagerFast::play_move(Move move) {
    auto ret = play_move_gd(move.unit, Vector2i(move.pos.x, move.pos.y));
    moves_dirty = true;
    return ret;
}

int BattleManagerFast::play_move_gd(unsigned unit_id, Vector2i pos) {
    auto ret = _play_move(unit_id, pos);
    moves_dirty = true;
    return ret;
}

int BattleManagerFast::_play_move(unsigned unit_id, Vector2i pos) {
    CHECK_UNIT(unit_id, -1);
    auto& unit = armies[current_participant].units[unit_id];

    if(state == BattleState::SUMMONING) {
        if(unit.status != UnitStatus::SUMMONING) {
            WARN_PRINT("BMFast - unit is not in summoning state\n");
            return -1;
        }

        if(tiles->get_tile(pos).get_spawning_team() != current_participant) {
            WARN_PRINT("BMFast - target spawn does not belong to current army, aborting\n");
            return -1;
        }

        unit.pos = pos;
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
            return -1;
        }

        unit.rotation = rot_new;
        _process_unit(unit, armies[current_participant]);
        
        if(unit.status == UnitStatus::ALIVE) {
            unit.pos = pos;
            _process_unit(unit, armies[current_participant]);
        }
        
        int limit = current_participant;
        do {
            current_participant = (current_participant+1) % armies.size();
        } while(armies[current_participant].is_defeated() && current_participant != limit);
    }
    else {
        WARN_PRINT("BMFast - battle already ended, did not expect that\n");
        return -1;
    }

    return get_winner();
}


int BattleManagerFast::_process_unit(Unit& unit, Army& army, bool process_kills) {

    for(auto& enemy_army : armies) {

        if(enemy_army.team == army.team) {
            continue;
        }

        for(auto& neighbor : enemy_army.units) {
            
            if(neighbor.status != UnitStatus::ALIVE) {
                continue;
            }

            auto rot_unit_to_neighbor = get_rotation(unit.pos, neighbor.pos);
            auto rot_neighbor_to_unit = flip(rot_unit_to_neighbor);

            // Skip non-neighbors
            if( rot_unit_to_neighbor == 6 ) {
                continue;
            }
            
            auto unit_symbol = unit.symbol_at_side(rot_unit_to_neighbor);
            auto neighbor_symbol = neighbor.symbol_at_side(rot_neighbor_to_unit);
            /*
            printf("pos: u %d,%d, n %d %d, rotations: u -%d+%d, n -%d+%d\n",
                   unit.pos.x, unit.pos.y, neighbor.pos.x, neighbor.pos.y, 
                   unit.rotation, rot_unit_to_neighbor, neighbor.rotation, rot_neighbor_to_unit
            );

            printf("unit symbols: ");
            for(int i = 0; i < 6; i++) {
                unit.sides[i].print();
                printf("->");
                unit.symbol_at_side(i).print();
                printf(" ");
            }
            
            printf("\nneighbor symbols: ");

            for(int i = 0; i < 6; i++) {
                neighbor.sides[i].print();
                printf("->");
                neighbor.symbol_at_side(i).print();
                printf(" ");
            }
            printf("\n");
*/
            // counter
            if(neighbor_symbol.get_counter_force() > 0 && unit_symbol.get_defense_force() < neighbor_symbol.get_counter_force()) {
                //printf("%d %d dead by counter (ud %d, nc %d)\n", unit.pos.x, unit.pos.y, unit_symbol.get_defense_force(), neighbor_symbol.get_counter_force());
                unit.status = UnitStatus::DEAD;
                return 0;
            }

            if(process_kills) {
                if(unit_symbol.get_attack_force() > 0 && neighbor_symbol.get_defense_force() < unit_symbol.get_attack_force()) {
                    //printf("%d %d dead by attack (ua %d, nd %d)\n", neighbor.pos.x, neighbor.pos.y, unit_symbol.get_attack_force(), neighbor_symbol.get_defense_force());
                    neighbor.status = UnitStatus::DEAD;
                }

                if(unit_symbol.pushes()) {
                    auto new_pos = neighbor.pos + neighbor.pos - unit.pos;
                    //printf("ffs%d %p\n", tiles->get_tile(new_pos).is_passable(), _get_unit(new_pos));
                    if(!(tiles->get_tile(new_pos).is_passable()) || _get_unit(new_pos) != nullptr) {
                        //printf("%d %d dead by smashing into the wall on %d %d\n", neighbor.pos.x, neighbor.pos.y, new_pos.x, new_pos.y);
                        neighbor.status = UnitStatus::DEAD;
                    }
                    neighbor.pos = new_pos;
                    _process_unit(neighbor, enemy_army, false);
                }
            }
        }

        if(process_kills) {
            _process_bow(unit, enemy_army);
        }
    }
    

    // TODO scores
    return 0;
}

// TODO Army -> Unit variant? maybe
int BattleManagerFast::_process_bow(Unit& unit, Army& enemy_army) {
    for(int i = 0; i < 6; i++) {
        auto force = unit.symbol_at_side(i).get_bow_force();
        if(force == 0) {
            continue;
        }

        auto iter = DIRECTIONS[i];

        //printf("-- actually checking the bow: pos %d %d, rot %d, %d\n", unit.pos.x, unit.pos.y, unit.rotation, i);

        auto pos = unit.pos;
        for(auto pos = unit.pos; !(tiles->get_tile(pos).is_wall()); pos = pos + iter) {
            pos = pos + iter;
            //printf("aaa checking %d %d\n", pos.x, pos.y);
            auto other = enemy_army.get_unit(pos);
            if(other != nullptr && other->symbol_at_side(flip(i)).get_defense_force() < force) {
                //printf("%d %d dead by bow\n", other->pos.x, other->pos.y);
                other->status = UnitStatus::DEAD;
            }
        }
    }
    // TODO scores
    return -1;
}

int BattleManagerFast::get_winner() {

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


const std::vector<Move>& BattleManagerFast::get_legal_moves() {
    if(moves_dirty) {
        _refresh_legal_moves();
        moves_dirty = false;
    }
    return moves;
}

void BattleManagerFast::_refresh_legal_moves() {
    moves.clear();
    moves.reserve(64);

    //printf("Refreshing legal moves\n");

    auto& army = armies[current_participant];
    auto& spawns = tiles->get_spawns(current_participant);

    Move move;

    if(state == BattleState::SUMMONING) {
        for(auto& spawn : spawns) {
            if(is_occupied(spawn, army.team)) {
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
                
                if(is_occupied(move.pos, army.team)) {
                    continue;
                }

                moves.push_back(move);
            }
        }
    }
}

Move BattleManagerFast::get_random_move() {
    static thread_local std::mt19937 rand_engine;

    auto moves_arr = get_legal_moves();

    if(moves_arr.size() == 0) {
		::godot::_err_print_error(FUNCTION_STR, __FILE__, __LINE__, "ERROR - a random move requested, but 0 moves are possible"); \
    }
    
    std::uniform_int_distribution dist{0, int(moves_arr.size() - 1)};

    auto move = dist(rand_engine);

    return moves_arr[move];
}

int BattleManagerFast::get_move_count() {
    return get_legal_moves().size();
}

bool BattleManagerFast::is_occupied(Position pos, int team) const {
    for(auto& army : armies) {
        if(army.team != team) {
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

void BattleManagerFast::insert_unit(int army, int idx, Vector2i pos, int rotation, bool is_summoning) {
    CHECK_UNIT(idx,)
    CHECK_ARMY(army,)
    armies[army].units[idx].pos = pos;
    armies[army].units[idx].rotation = rotation;
    armies[army].units[idx].status = is_summoning ? UnitStatus::SUMMONING : UnitStatus::ALIVE;
}

void BattleManagerFast::set_unit_symbol(int army, int unit, int side, int symbol) {
    CHECK_UNIT(unit,)
    CHECK_ARMY(army,)
    armies[army].units[unit].sides[side] = Symbol(symbol);
}

void BattleManagerFast::set_army_team(int army, int team) {
    CHECK_ARMY(army,)
    armies[army].team = team;
}

void BattleManagerFast::set_current_participant(int army) {
    CHECK_ARMY(army,)
    current_participant = army;
}

void BattleManagerFast::set_tile_grid(TileGridFast* tg) {
    tiles = tg;
}

void BattleManagerFast::force_battle_ongoing() {
    state = BattleState::ONGOING;
}

Unit* BattleManagerFast::_get_unit(Position coord) {
    for(auto army : armies) {
        auto unit = army.get_unit(coord);
        if(unit != nullptr && unit->pos == coord) {
            return unit;
        }
    }
    return nullptr;
}
/*
void BattleManagerFast::mcts_init() {
    if(mcts) {
        delete mcts;
    }
    mcts = new BattleMCTSManager();
    mcts->set_root(this);
}

void BattleManagerFast::mcts_iterate(int iterations) {
    mcts->iterate(iterations);
}

int BattleManagerFast::mcts_get_optimal_move_unit() {
    return mcts->get_optimal_move_unit();
}

Vector2i BattleManagerFast::mcts_get_optimal_move_position() {
    return mcts->get_optimal_move_position();
}

BattleManagerFast::~BattleManagerFast() {
    if(mcts) {
        delete mcts;
    }
}
*/


void BattleManagerFast::_bind_methods() {
    ClassDB::bind_method(D_METHOD("insert_unit"), &BattleManagerFast::insert_unit);
    ClassDB::bind_method(D_METHOD("set_unit_symbol"), &BattleManagerFast::set_unit_symbol);
    ClassDB::bind_method(D_METHOD("set_army_team"), &BattleManagerFast::set_army_team);
    ClassDB::bind_method(D_METHOD("set_tile_grid"), &BattleManagerFast::set_tile_grid);
    ClassDB::bind_method(D_METHOD("set_current_participant"), &BattleManagerFast::set_current_participant);
    ClassDB::bind_method(D_METHOD("force_battle_ongoing"), &BattleManagerFast::force_battle_ongoing);
    ClassDB::bind_method(D_METHOD("play_move"), &BattleManagerFast::play_move_gd);

    ClassDB::bind_method(D_METHOD("get_unit_position"), &BattleManagerFast::get_unit_position);
    ClassDB::bind_method(D_METHOD("get_unit_rotation"), &BattleManagerFast::get_unit_rotation);
    ClassDB::bind_method(D_METHOD("get_current_participant"), &BattleManagerFast::get_current_participant);
    ClassDB::bind_method(D_METHOD("is_unit_alive"), &BattleManagerFast::is_unit_alive);
    ClassDB::bind_method(D_METHOD("is_unit_being_summoned"), &BattleManagerFast::is_unit_being_summoned);

}

Unit* Army::get_unit(Position coord) {
    for(auto& unit : units) {
        if(unit.pos == coord && unit.status == UnitStatus::ALIVE) {
            return &unit;
        }
    }
    return nullptr;
}

int Army::find_summon_id(int i) {
    for(; i < 5; i++) {
        if(units[i].status == UnitStatus::SUMMONING) {
            return i;
        }
    }
    return -1;
}

bool Army::is_defeated() {
    for(auto& unit: units) {
        if(unit.status == UnitStatus::ALIVE) {
            return false;
        }
    }
    return true;
}
