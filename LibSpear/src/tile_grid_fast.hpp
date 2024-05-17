#ifndef TILE_GRID_FAST_H
#define TILE_GRID_FAST_H

#ifdef WIN32
#include "windows.h"
#endif

#include "godot_cpp/classes/node.hpp"
#include "godot_cpp/core/class_db.hpp"
#include "godot_cpp/variant/vector2i.hpp"
#include "godot_cpp/variant/string.hpp"
#include <stdint.h>
#include <array>
#include <vector>

#include "data.hpp"

using namespace godot;

class TileGridFast : public Node {
    GDCLASS(TileGridFast, Node);

    Vector2i dims;
    std::vector<Tile> tiles;

protected:
    static void _bind_methods();

public:
    void set_map_size(Vector2i dimensions);
    
    Tile get_tile(Position pos);
    //inline int get_tile_gd(Vector2i pos);
    
    void set_tile(Position pos, Tile tile_type);
    inline void set_tile_gd(Vector2i pos, godot::String str) {
        set_tile(Position(pos.x, pos.y), Tile(str));
    }
};


#endif
