var List_of_Steps
"""
In this tutorial we are going to make movement for the player character.

1 Open player.gd script, it's the place where
all of your work should be contained within for now

2 Create seperate function for the movement system.

3 Add a call for this function inside a process function so that
it will be called on every frame.

Now there are SEVERAL approaches:
I Node2d - basic movement
II CharacterBody2D - advanced system

I
1 Make a series of "if" statements related to each movement UP/LEFT..
2 depending on direction add to the current "postition" values to it's x or y
3 rotate the sprite based on the player input direction


II
1 Gather player input into a Vector 2d 

2 modify player's object default "velocity" variable by
multiplication of direction and speed

3 modify speed value based on player shift input

4 rotate the sprite based on the player input direction
"""

var BONUS
"""
Bonus challenge Add abbility for player to change clothes


1 Create seperate function which get's called from process after pressing
"Change_Clothes" button

Different levels of complexity

I 
1 Pick a random body from "crowd" list and call "change_clothes" with
random body clothes variable

II
1 Search in the list of bodies from the "crowd" array for bodies
that have different clothing than players

2 Pick a random one

III
Like in the II but instead of adding them to an array create a dictionary so
that different clothes types won't repeat making it equal chance for
type of clothing to be chosen regardless of the popularity

IV
Remember a list of previous clothes and chose a clothing
which hasn't been worn before.

In case there isn't one reset the list


"""


