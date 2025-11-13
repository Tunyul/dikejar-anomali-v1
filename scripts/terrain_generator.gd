@tool
class_name TerrainGenerator
extends TileMapLayer

@export var tile_size: int = 128
@export var world_width_tiles: int = 64
@export var ground_y_tiles: int = 5
@export var fill_depth_tiles: int = 3
@export var grass_texture_path: String = "res://assets/Tiles/png/128x128/GrassMid.png"
@export var dirt_texture_path: String = "res://assets/Tiles/png/128x128/Dirt.png"
@export var tile_scale: float = 0.5
@export var auto_generate: bool = true
@export var regenerate: bool = false: set = _set_regenerate
@export var target_baseline_px: int = 420

func _ready() -> void:
	if auto_generate and not Engine.is_editor_hint():
		generate()

func _set_regenerate(value: bool) -> void:
	if value:
		generate()

func generate() -> void:
	clear()
	scale = Vector2(tile_scale, tile_scale)
	var viewport_h := int(get_viewport().get_visible_rect().size.y)
	var tile_px := int(tile_size * tile_scale)
	var baseline := (target_baseline_px if target_baseline_px > 0 else viewport_h - tile_px)
	position.y = baseline - ground_y_tiles * tile_px
	var ts := TileSet.new()
	ts.tile_size = Vector2i(tile_size, tile_size)

	var grass_source := TileSetAtlasSource.new()
	grass_source.texture = load(grass_texture_path)
	grass_source.texture_region_size = Vector2i(tile_size, tile_size)
	grass_source.create_tile(Vector2i(0, 0))
	var grass_id := ts.add_source(grass_source)

	var dirt_source := TileSetAtlasSource.new()
	dirt_source.texture = load(dirt_texture_path)
	dirt_source.texture_region_size = Vector2i(tile_size, tile_size)
	dirt_source.create_tile(Vector2i(0, 0))
	var dirt_id := ts.add_source(dirt_source)

	tile_set = ts

	for x in range(world_width_tiles):
		set_cell(Vector2i(x, ground_y_tiles), grass_id, Vector2i(0, 0))
		for d in range(1, fill_depth_tiles + 1):
			set_cell(Vector2i(x, ground_y_tiles + d), dirt_id, Vector2i(0, 0))
