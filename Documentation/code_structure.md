# Code Structure

# main game logic

Logic uses global singletons (see: "Project Settings >> Autoload")

- IM (Input Manager)
	- WM (World Manager)
		- W_GRID (World Grid Manager)
	- BM (Battle Manager)
		- B_GRID (Battle Grid Manager)

IM is notified when tiles are clicked. Then sends signal to WM or BM depending on the state. WM/BM control the game using W_GRID/B_GRID respectively, for positional queries etc.

IM contains list of players and knows if there is an active battle that needs to be resolved.

# Description of how game works:

## Game Setup

### a) Tester:
Selects using Main Menu interface desired play test scenario, previously created in Resources and attached to MainMenu variables in Main_Scene

### b) Normal Player:
Selects using Main Menu interface buttons calls Input_Manager functions that determine:
- list of players that is stored inside Input_Manager
- World/Battle map
- in case of battle map, armies that will fight during the battle

## Start of the game
Input Manager calls depending on chosen game mode either:

- a - World Manager with 
  - 1 World_Map variable
- b - Battle Manager with 
  - list of armies 
  - chosen Battle_Map variable

World/Battle Manager start functions now setup their own proper variables and launch:

World/Battle Grid Manager generate_grid function passing to it World/Battle Map variable

Grid Managers now draw a map creating clickable hex_tile nodes

## Gameplay start
first player can now provide his first gameplay input:

### World

in World Map he can at the start only select his starting city where he can:
- recruit a hero
- build a building
- recruit units
After he acquires a hero, he will be able to perform actions with him too:
- swap/pass units between himself and another heroe/city with which he collides/stands on top of
- move around the map (where upon contact with enemy controlled army a Battle starts)

### Battle
Battle section is split into 2 parts:
- 1 Unit placement
- 2 Combat

During Unit placement player can choose any unit from his army and place it on one of the available "starting tiles".
Unit once placed can't be relocated again. After all units are placed Battle proceeds into Combat phase where units can move and attack each other.


# Ideas for drawing the map:

class Map_Draw
would be responisble for drawing specific map (visually)
while gameplay classes like Battle_Grid and World_Grid would care about gameplay only and simply use Map_Draw

# World Manager

parameters:
	List of players (Host-Seat/AI/Connected_User)
	World Map ID
	From lobby game parameters (Races, starting locations, alliances)


Data:
	Every tile has 


# Important Grid functions:

reset_data - remove array data (memory)

hide_X - deletes childs, but doesn't remove the memory



