extends Node

var Attacker_wins = 0
var Defender_wins = 0

var BotSpeed = 30


signal collect_save_data(save: Save)
signal load_game(save: Save)

signal Tile_Selected(Cord : Vector2i)

#var player_reference : CharacterBody2D