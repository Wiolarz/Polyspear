
#include "battle_structs.hpp"

int Army::find_unit_id_to_deploy(int i) const {
	for(; i < 5; i++) {
		if(units[i].status == UnitStatus::DEPLOYING) {
			return i;
		}
	}
	return -1;
}

int Army::find_empty_unit_slot() const {
	for(int i = 0; i < 5; i++) {
		if(units[i].status == UnitStatus::DEAD) {
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
