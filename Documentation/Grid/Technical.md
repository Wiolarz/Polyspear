# Techical Grid documentation


Grid system uses Axial coordinate system. Reference:
[redblobgames blog about coding hexagonal grids](https://www.redblobgames.com/grids/hexagons/)



we store tiles in array of arrays -> as array of columns to allow "grid[x][y]"


As a way to fail save function that could have looked outside of the array size, we use Sentinel tiles
[Wikipedia page about Sentinel values](https://en.wikipedia.org/wiki/Sentinel_value)










## Hex tiles
Each tile has specified:

WM and BM:
texture
flip_h
type (string for game logic)



## Directions
We start looking toward the left then we move clockwise
0-5
0 - LEFT
1-2 - TOP
3 - RIGHT
4-5 BOT

0 - Vector2i(-1, 0),
1 - Vector2i(0, -1),
2 - Vector2i(1, -1),
3 - Vector2i(1, 0),
4 - Vector2i(0, 1),
5 - Vector2i(-1, 1),
