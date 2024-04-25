# Code Structure

## Singletons

Global singletons provide key facades over core systems.

see: "Project Settings >> Autoload" for full list

- `IM` (Input Manager)
	- `WM` (World Manager)
		- `W_GRID` (World Grid Manager)
	- `BM` (Battle Manager)
		- `B_GRID` (Battle Grid Manager)

`IM` is notified when tiles are clicked. Then sends calls `WM` or `BM` depending on the game state (is battle or world map active). `WM`/`BM` control the game using maps loaded to `W_GRID`/`B_GRID` respectively. Grids handle positional queries etc.

`IM` contains a list of `Players` and knows if there is an active battle that needs to be resolved.

## Core user journeys

### 1. Starting the game

a) Normal Player

Uses Main Menu UI buttons to setup:
- pick scenario (pick a World or Battle map)
- configure list of players (AI or hot seat)
- [battle map only]\
configure armies that will fight

b) Tester

Speeds up common setups using *preset* resources.

- configured mostly in godot editor

### Behind the scenes

`UI` code interacts with `IM` (Input manager).

It sets up Players based on the intended map, then starts the map.

(see 1a for list of required config)

When the map is started `WM`/`BM` (World/Battle Manager) set up their own state and init corresponding grids.

Grid Managers (`W_GRID`/`B_GRID`) spawn `HexGrid` Nodes creating a clickable map that is based on `DataXyzMap` resource

### 2. Gameplay start - World map

Note: For battle map scenarios skip to "3."

Player opens theirs starting city where they can:
- recruit a hero
- build a building
- recruit units

After player acquires a hero, they will be able to:
- move around the map 
- interact with a city or another hero (swap/buy units)
- collect goods on the map
- fight enemy controlled armies (neutral or other players)


[More world info](../Documentation/World%20map/design.md)

[More economy info](../Documentation/World%20map/economy.md)

### 3. Battle

Battle has 2 phases:

1. Unit placement / summoning
2. Combat

During Unit placement players deploy units one by one. Units can only be deployed on "starting tiles" specific for the given player. Once a unit is placed it can't be relocated until combat starts. 

After all units are placed, Battle proceeds into the Combat phase.

In combat, players take turns giving an order to one of the units. Unit moves and attacks enemies.

Battle ends when all enemies are eliminated.

[More battle info](../Documentation/Battle%20System/Battle_Description.md)


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



