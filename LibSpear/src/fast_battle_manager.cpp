#include "fast_battle_manager.hpp"
#include "godot_cpp/core/class_db.hpp"
 
#include <algorithm>
#include <stdlib.h>

#define CHECK_UNIT(idx, val) \
    if(idx >= 5) { \
        printf("Unknown unit id %d", idx);\
        return val;\
    }

#define CHECK_ARMY(idx, val) \
    if(idx >= 2) { \
        printf("Unknown army id %d", idx); \
        return val; \
    }

int BattleManagerFast::play_move(unsigned unit_id, Vector2i pos) {
    CHECK_UNIT(unit_id, -1);
    auto unit = armies[current_participant].units[unit_id];

    if(state == BattleState::SUMMONING) {
        if(unit.status != UnitStatus::SUMMONING) {
            printf("WARNING - unit is not in summoning state, did not expect that\n");
        }

        // TODO spawner tiles
        if(false) {
            return -1;
        }

        unit.pos = pos;
        unit.status = UnitStatus::ALIVE;
    }
    else if(state == BattleState::ONGOING) {
        auto rot_new = get_rotation(unit.pos, pos);

        if(rot_new == 6) {
            printf("WARNING - target position is not a neighbor, did not expect that\n");
            return -1;
        }

        unit.rotation = rot_new;
        process_unit(unit);
        
        unit.pos = pos;
        process_unit(unit);
    }
    else {
        printf("WARNING - battle already ended, did not expect that\n");
    }
    
    current_participant = (current_participant+1) % 2;
    
    for(int i = 0; i < 2; i++) {
        auto& army = armies[i];
        bool defeat = true;

        for(auto& unit: army.units) {
            if(unit.status == UnitStatus::ALIVE) {
                defeat = false;
                break;
            }
        }

        if(defeat) {
            // TODO more teams
            return !i;
        }
    }

    return -1;
}


int BattleManagerFast::process_unit(Unit& unit, bool process_kills) {

    //                  TODO - more than two participants?
    for(auto neighbor : armies[!current_participant].units) {
        
        if(unit.status != UnitStatus::ALIVE) {
            continue;
        }

        auto rot_unit_to_neighbor = get_rotation(unit.pos, neighbor.pos);
        auto rot_neighbor_to_unit = flip(rot_unit_to_neighbor);

        // Skip non-neighbors
        if( rot_unit_to_neighbor == 6 ) {
            continue;
        }
        
        auto unit_symbol = unit.symbol_at_side(rot_unit_to_neighbor);
        auto neighbor_symbol = unit.symbol_at_side(rot_neighbor_to_unit);

        // counter
        if(neighbor_symbol.get_counter_force() > 0 && unit_symbol.get_defense_force() < neighbor_symbol.get_counter_force()) {
            unit.status = UnitStatus::DEAD;
            return 0;
        }

        if(process_kills) {
            if(unit_symbol.get_attack_force() > 0 && neighbor_symbol.get_defense_force() < unit_symbol.get_attack_force()) {
                neighbor.status = UnitStatus::DEAD;
            }

            if(unit_symbol.pushes()) {
                auto new_pos = neighbor.pos + neighbor.pos - unit.pos;
                if(tiles->get_tile(new_pos).is_wall() || get_unit(new_pos) != nullptr) {
                    neighbor.status = UnitStatus::DEAD;
                }
                neighbor.pos = new_pos;
                process_unit(neighbor, false);
            }
        }
    }
    
    if(process_kills) {
        process_bow(unit, armies[!current_participant]);
    }

    // TODO scores
    return 0;
}

// TODO Army -> Unit variant? maybe
int BattleManagerFast::process_bow(Unit& unit, Army& enemy_army) {
    for(int i = 0; i < 6; i++) {
        auto force = unit.sides[i].get_bow_force();
        if(force == 0) {
            continue;
        }

        auto iter = DIRECTIONS[i];

        for(auto pos = unit.pos + iter; tiles->get_tile(pos).is_passable(); pos = pos + iter) {
            auto other = armies[!current_participant].get_unit(pos);
            if(other != nullptr && other->symbol_at_side(flip(i)).get_defense_force() < force) {
                other->status = UnitStatus::DEAD;
            }
        }
    }
    // TODO scores
    return -1;
}

MoveIterator BattleManagerFast::get_legal_moves() const {
    return MoveIterator(this);
}

Move* MoveIterator::operator++() {
    // TODO
    return nullptr;
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

Unit* BattleManagerFast::get_unit(Position coord) {
    for(auto army : armies) {
        auto unit = army.get_unit(coord);
        if(unit != nullptr && unit->pos == coord) {
            return unit;
        }
    }
    return nullptr;
}

void BattleManagerFast::_bind_methods() {
    ClassDB::bind_method(D_METHOD("insert_unit"), &BattleManagerFast::insert_unit);
    ClassDB::bind_method(D_METHOD("set_unit_symbol"), &BattleManagerFast::set_unit_symbol);
    ClassDB::bind_method(D_METHOD("set_army_team"), &BattleManagerFast::set_army_team);
    ClassDB::bind_method(D_METHOD("set_tile_grid"), &BattleManagerFast::set_tile_grid);
    ClassDB::bind_method(D_METHOD("play_move"), &BattleManagerFast::play_move);

    ClassDB::bind_method(D_METHOD("get_unit_position"), &BattleManagerFast::get_unit_position);
    ClassDB::bind_method(D_METHOD("get_unit_rotation"), &BattleManagerFast::get_unit_rotation);
    ClassDB::bind_method(D_METHOD("get_current_participant"), &BattleManagerFast::get_current_participant);

}

Unit* Army::get_unit(Position coord) {
    for(auto& unit : units) {
        if(unit.pos == coord && unit.status == UnitStatus::ALIVE) {
            return &unit;
        }
    }
    return nullptr;
}
