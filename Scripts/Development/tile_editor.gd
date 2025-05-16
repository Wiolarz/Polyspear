extends ArtEditor


## override
func _init_resource_type() -> void:
	dirty_changes = DataTile.new()
	resource_directory_path = CFG.BATTLE_MAP_TILES_PATH


##override
func apply_texture_to_preview() -> void:
	resource_preview_form.paint(dirty_changes)
