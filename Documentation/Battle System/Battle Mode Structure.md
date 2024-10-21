All of battles are managed by: `battle_manager.gd` -> main singleton  
To calculate gameplay logic it uses `battle_grid_state.gd`.

# Battle Manager

## Battle Setup
Two main functions:

`start_battle()` - main method which uses `_load_map()` and initiates its `_battle_grid_state`.  
Function ends by calling `_on_turn_started()` for the first player.
## Battle End
Only one public function: `close_when_quitting_game()` as it's safe to use, it gets called everywhere.  
Second way to end a battle is by having a `battle_grid_state` in a state == STATE_BATTLE_FINISHED during the `end_move()` function call. Which then calls `_on_battle_ended()`.
## Additional mechanics

### Map editor

List of public functions that simply call private functions that:

- Loads a map
- Unloads a map,
- based on the given coord call specific tile function “paint”
- returns a deep copy of the grid.

### Cheats

List of simple wrappers that call `battle_grid_state` functions.

For cheats which end the battle wrapper concludes the current player move.

### Chess clock

Operates on milliseconds represented by integers.  
Chess clock is updated on `_process` and constantly accessed by a `_process` on `BattleUi`

  

# Battle Grid State

# Units