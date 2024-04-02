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