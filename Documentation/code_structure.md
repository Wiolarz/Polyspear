# Code Structure




# main game logic

Everything centers around singletons:

Input Manager IM

	World Manager WM
		World Grid Manager W_GRID

		Battle Manager BM
			Battle Grid Manager B_GRID


# Description of how game works:


## Game Setup
### -a Tester:
Selects using Main Menu interface desired play test scenario, previously created in Resources and attached to MainMenu variables in Main_Scene

### -b Normal Player:
Selects using Main Menu interface buttons calls Input_Manager functions that determine:
- list of players that is stored inside Input_Manager
- World/Battle map
- in case of battle map, armies that will fight during the battle

## Start of the game
Input Manager calls depending on chosen game mode either:
- a - World Manager with 1 World_Map variable
- b - Battle Manager with 1 list of armies and 2 chosen Battle_Map variable

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

1 During Unit placement player can choose any unit from his army and place it on one of the available "starting tiles".
Unit once placed can't be relocated again. After all units are placed Battle proceeds into



# Singletons:

Main Menu

Input Manager - holds all player objects
	*Multiplayer Manager 

Gameplay Manager

	World Manager
		World Grid Manager

	Battle Manager
		Battle Grid Manager




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



