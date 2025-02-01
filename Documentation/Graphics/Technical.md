# Graphics - technical notes

Currently in AutoLoad we first load GridManager (parent of all tiles objects)
Then we load GameplayManager (parent of all units object)
which leads to Units rendering on top of tiles.

If for any reason this would need to change a simple solution would be to manually set
all tiles Z Index in their sprite assets from 0 to -1


## Spacing_of_the_Grid

Those values will updated with the release of HD update.
```
const TileHorizontalOffset : float = 700.0
const TileVerticalOffset : float = 606.2
const OddRowHorizontalOffset : float = 350.0
```
