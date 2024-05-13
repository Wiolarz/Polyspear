#include "fast_battle_manager.hpp"
#include "godot_cpp/core/class_db.hpp"
 

Unit* Army::get_unit(Position coord) {
    for(auto& unit : units) {
        if(unit.pos == coord && unit.status == UnitStatus::ALIVE) {
            return &unit;
        }
    }
    return nullptr;
}

MoveResult BattleManagerFast::play_move(unsigned unit, Position pos) {

    // TODO everything

    return {-1};
}


void BattleManagerFast::_bind_methods() {
    //ClassDB::bind_method(D_METHOD("play_move"), &BattleManagerFast::play_move);
    ClassDB::bind_method(D_METHOD("get_current_participant"), &BattleManagerFast::get_current_participant);
}

