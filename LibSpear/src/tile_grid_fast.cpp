#include "tile_grid_fast.hpp"

Tile TileGridFast::get_tile(Position pos) {
    int idx = pos.x + pos.y * dims.x;
    if(idx >= tiles.size()) {
        printf("ERROR - invalid tile position %d %d (idx - %d, dims - %dx%d)\n", pos.x, pos.y, idx, dims.x, dims.y);
        return Tile();
    }
    return tiles[idx];
}

void TileGridFast::set_tile(Position pos, Tile type) {
    unsigned idx = pos.x + pos.y * dims.x;
    if(idx >= tiles.size()) {
        printf("ERROR - invalid tile position %d %d (idx - %d, dims - %dx%d)\n", pos.x, pos.y, idx, dims.x, dims.y);
        return;
    }
    tiles[idx] = type;
}

void TileGridFast::set_map_size(Vector2i dimensions) {
    dims = dimensions;
    tiles.resize(dims.x * dims.y);
}

void TileGridFast::_bind_methods() {
    //ClassDB::bind_method(D_METHOD("get_tile"), &TileGridFast::get_tile_gd);
    ClassDB::bind_method(D_METHOD("set_tile"), &TileGridFast::set_tile_gd);
    ClassDB::bind_method(D_METHOD("set_map_size"), &TileGridFast::set_map_size);
}


