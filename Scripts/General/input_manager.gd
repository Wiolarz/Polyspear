extends Node


"""
when player selects a hex it inform input_manager

there input_manager check who the current play is:
    1 in single player its simple check if its the player turn
    2 in multi player we check if its the local machine turn, if it is then it sends the move to all users

if the AI plays the move:
    1 in single player AI gets called to act when its their turn so it goes straight to gameplay
    2 in multi GAME HOST only sends the call to AI for it to make a move 










where do we call AI?

there is an end turn function "switch player" it could call the input manager to let it now who the current player is


"""







