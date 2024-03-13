# Design

# Army

Player has a list of armies, but not all of them have to contain a hero.
Those armies are garrisons in towns and the cannot move on their own.
So not all armies are displayed in "heroes" tab at the bottom of the screen.

But when there is a battle we send an army class data instead of hero data
While to determine if the selected army can be moved we use -> does army contain a hero?



## Heroes



### CITY
When Hero army enters the city which has more units than the hero can command, the units go into "reserve" space
(they can be swapped back in, but in a case of an attack they don't appear)

### Another Ally Hero
when we selecet a hero then press on another one, instead of swapping we begin the trade





var UI
"""
show list of cities and heroes at the bottom for quick selection option


# Code 

## TODO

Add resources
add combat
add city interface


## think about


World Manager
next_player_turn()
Decide if the players array will store removed players or not.
In case we were to add "leaderboard" variable there will be a need to extend this function
