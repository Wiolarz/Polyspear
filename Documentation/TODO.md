# TODO

## now
fix battle map render, dont spawn units yet, prepare unit buttons the way you made map creator

add clear data, map / map reset for battle grid/manager same like in world


### documentation
document why keeping Sentinel protection reserved to loading data code not saving maps is better as it makes sure that no matter how bad we break map creator game still works
move map sizes from board data to simply getting info from code as array dimension carry those values anyway

Document how players have to be set in Input manager before other managers can start working

document why factory functions for battle_setup and world_setup shouldnt be made

Refactor project file names or something

### code


Camera movement between battle area and world map area. Destroy childs on clear data function

remove old unused scenes


Add alliances somewhere to determine teams for players


serialization and deserialization for HexTile put code in the same place

move manpipulation of hextile sprite2D  to hextile script


input manager restricts movement on turns


creat basic battle map, add it to tests

after summoning phase during battle ends, replace summon tiles with basic grass tiles


## MONSTER BUGS -> game breaking stuff


## FIX 
	Stuff that needs to be fixed, for the game to work properly

change unit scenes into resources

Make camera center on the map
-on grid manager, remember playable map cornes, and based on them generate border for the camera, + set starting camera in the middle of those corners
- or on larger map (set camera on player starter units)


In gameplay manager setting up units if one player has already placed all of their units

Add tests in place of those place holders

AI is once again broken completely needs a full rewrite

in BM name unit scenes for debugger

## THINK_About
creating enum for displaying directions as words (create addon to allow displaying enum values as strings)

rename basic_map to polyspear_main_project

how to properly reset Singeleton objects

How to approach spliting code into abstract and visual part

model MVC model - view - controller -> add gameplay manager to input manager



## Core goals

Create MM (Multiplayer Manager)
Create WM (World Manager)

How to load premade maps into Grid Manager
Make a map generator (battle maps + global maps)

add colors for players

### More Armies in a single battle:
un-summoned units have to be placed in UI
kill_unit() has to account for more sides:
	modify Input Manager



## Nice to have goals
implement functionality to flip hex tile sprites (map creator, and data_tile func)


moving the camera on larger map + zoom option
#google camera tutorials + addons



add rotation animation (copy code from Brawler branch)
particles on death animation (+hit shields)
add highlight last move (made by the other player)



add save system for battles + overworld map




## CHANGE
	 Stuff currently implemented which needs to be changed

Replace some of the enum variables with a proper class


## REFACTOR

consider removing E.WorldMapTiles

Change variable names in resources to match coding style




# FEATURE: Bigger Units

## Foreword

The addition of bigger sized units will be hard to implement, while in the end in may be a bad feature.

Its still worthwile to document stuff needed to be changed once the work on this feature would start.




Graphics/Technical -> Spacing_of_the_Grid


# FEATURE: Alliances
Team - determines units and heroes within a single player
Alliance - group of teams

# FEATURE Better Map creator

## Nice to have

make it so that spawn positions are modifier instead of a different tile type, so that once summoning phase ends something else may be there isntead of simple basic grass tile


create 2 functions: extend/reduce map_size
User will be able to press a button change canvas size -> at the map borders a line? (or just last edge hex rows/columns will highlight)
it will be then dragable by the player:
- Reducing map size will simply grey out existing tiles, 
- Extending map size will show new empty sentinel tiles forming
and once mouse button is released map will be resized
(previous map would be saved and loaded into new canvas)

create ctrl_z and ctrl_r? function that will revert changes or recover reverted state



# FEATURE: Different maps

## TODO
special type tiles like spawn points/cities:
have a basic "spawn" sprite (or specific faction city sprite) (for choice based cities (start of the game) create a different question mark city tile)
All specific player tiles will have assigned color in player order (when players later on decide to change their color, it simply gets swapped in manager)

For color based tiles to work, opacity of special regions has to be 0 in sprite, and receive a full tile sprite underneath to swap color in



## Think_about

How to handle different art assets for different regions in the game?
- They could be an additional resource (map_art) for WorldSetup alongside gameplay map_data


# FEATURE: Saving data files

Player Data (nick, ETA, match history, statistics) - resource
Game Settings (resolution, audio settings, etc.) - txt
---------
This data should be stored in either:
    1 - AppData folder -> Game will need uninstaller
    2 - To be in the same folder as the game -> not sure how to make it yet
