# Techical Grid documentation

## Coordinates

```
      /\   /\ 
     /  \ /  \
    |0,0 |1,0 | ...
    |    |    |
     \  / \  / \
      \/   \/   \
      |0,1 |1,1 | ...
      |    |    |
       \  / \  /
        \/   \/
         \ ...
```

Grid uses Axial coordinate system.

Reference:
[redblobgames blog about coding hexagonal grids](https://www.redblobgames.com/grids/hexagons/)

- X represents direction right
- Y represents direction bottom right

Note: 3td axis is expressed as a combination of those 2

## Directions

We start looking toward the left (0) then we move clockwise up to 5

```

    1 /\ 2
     /  \
  0 |    | 3
     \  /
    5 \/ 4

0 - LEFT
1-2 - TOP LEFT - RIGHT
3 - RIGHT
4-5 BOT RIGHT - LEFT
```

## Technical details

### Grid

We store tiles in array of arrays. With first index representing X. 
Allowing lookuips like `grid[x][y]`

Sentinel tiles are used to mitigate out of bands lookups.
See [Sentinel values - Wikipedia](https://en.wikipedia.org/wiki/Sentinel_value)

### Tiles

Each tile has specified:

- WM and BM:
- texture
- flip_h
- type (string for game logic)

### Directions as vectors

```
0 - Vector2i(-1, 0), # LEFT
1 - Vector2i(0, -1), # TOP-LEFT
2 - Vector2i(1, -1), # TOP-RIGHT
3 - Vector2i(1, 0), # RIGHT
4 - Vector2i(0, 1), # BOTTOM-RIGHT
5 - Vector2i(-1, 1), # BOTTOM-LEFT
```
