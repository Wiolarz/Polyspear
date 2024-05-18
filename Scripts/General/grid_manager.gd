class_name GridManager
extends Node2D

# Hex Sprite draw gaps
const VISUAL_EMPTY_BORDER = 11.0
const TILE_OFFSET_HORIZONTAL_PER_X : float = 529.0 + VISUAL_EMPTY_BORDER # current sprite size 529
const TILE_OFFSET_HORIZONTAL_PER_Y : float = TILE_OFFSET_HORIZONTAL_PER_X / 2
const TILE_OFFSET_VERTICAL_PER_Y : float = (608 + VISUAL_EMPTY_BORDER) * 0.75

## Thickness of a Sentinel perimeter around the gameplay area.
const SENTINEL_BORDER_SIZE : int = 1

func to_position(coord : Vector2i) -> Vector2:
	var horizontal = coord.x * TILE_OFFSET_HORIZONTAL_PER_X
	horizontal += coord.y * TILE_OFFSET_HORIZONTAL_PER_Y
	var vertical = coord.y * TILE_OFFSET_VERTICAL_PER_Y
	return Vector2(horizontal, vertical)
