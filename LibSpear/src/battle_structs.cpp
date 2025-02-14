
#include "battle_structs.hpp"

int Army::find_unit_id_to_summon(int i) const {
	for(; i < 5; i++) {
		if(units[i].status == UnitStatus::SUMMONING) {
			return i;
		}
	}
	return -1;
}

bool Army::is_defeated() const {
	for(auto& unit: units) {
		if(unit.status != UnitStatus::DEAD) {
			return false;
		}
	}
	return true;
}
