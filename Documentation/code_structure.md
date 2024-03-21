# Code Structure




# main game logic

Everything centers around singletons:

Input Manager IM

	World Manager WM
		World Grid Manager W_GRID

		Battle Manager BM
			Battle Grid Manager B_GRID




# Needs in this project:

Main Menu

Lobby Manager - holds all player objects
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








