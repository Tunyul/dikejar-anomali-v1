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
@export var gap_chance: float = 0.15
@export var min_gap_tiles: int = 2
@export var max_gap_tiles: int = 3
@export var edge_guard_tiles: int = 2
@export var rng_seed: int = 0
@export var flat_prefix_tiles: int = 32
@export var gap_spacing_tiles: int = 1
@export var use_caps: bool = true
@export var grass_left_texture_path: String = "res://assets/Tiles/png/128x128/GrassLeft.png"
@export var grass_right_texture_path: String = "res://assets/Tiles/png/128x128/GrassRight.png"

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

	var grass_left_id: int = -1
	var grass_right_id: int = -1
	if use_caps:
		var left_src := TileSetAtlasSource.new()
		left_src.texture = load(grass_left_texture_path)
		left_src.texture_region_size = Vector2i(tile_size, tile_size)
		left_src.create_tile(Vector2i(0, 0))
		grass_left_id = ts.add_source(left_src)
		var right_src := TileSetAtlasSource.new()
		right_src.texture = load(grass_right_texture_path)
		right_src.texture_region_size = Vector2i(tile_size, tile_size)
		right_src.create_tile(Vector2i(0, 0))
		grass_right_id = ts.add_source(right_src)

	tile_set = ts

	var rng := RandomNumberGenerator.new()
	if rng_seed != 0:
		rng.seed = rng_seed
	else:
		rng.randomize()

	var x: int = 0
	var right_guard: int = world_width_tiles - edge_guard_tiles
	var safe_until: int = flat_prefix_tiles
	if safe_until > world_width_tiles:
		safe_until = world_width_tiles
	var gap_spacing_left: int = 0
	var force_left_cap: bool = false
	while x < world_width_tiles:
		if x < safe_until:
			var top_id: int = grass_id
			if force_left_cap and use_caps and grass_left_id != -1:
				top_id = grass_left_id
				force_left_cap = false
			set_cell(Vector2i(x, ground_y_tiles), top_id, Vector2i(0, 0))
			for d in range(1, fill_depth_tiles + 1):
				set_cell(Vector2i(x, ground_y_tiles + d), dirt_id, Vector2i(0, 0))
		else:
			if gap_spacing_left > 0:
				gap_spacing_left -= 1
			else:
				var can_gap: bool = x >= edge_guard_tiles and x <= right_guard - min_gap_tiles
				if can_gap and rng.randf() < gap_chance:
					var max_w: int = right_guard - x
					if max_w > max_gap_tiles:
						max_w = max_gap_tiles
					var w: int = rng.randi_range(min_gap_tiles, max_w)
					if use_caps and grass_right_id != -1 and x > 0:
						set_cell(Vector2i(x - 1, ground_y_tiles), grass_right_id, Vector2i(0, 0))
					x += w
					force_left_cap = use_caps and grass_left_id != -1
					gap_spacing_left = gap_spacing_tiles
					continue
			var top_id2: int = grass_id
			if force_left_cap and use_caps and grass_left_id != -1:
				top_id2 = grass_left_id
				force_left_cap = false
			set_cell(Vector2i(x, ground_y_tiles), top_id2, Vector2i(0, 0))
			for d in range(1, fill_depth_tiles + 1):
				set_cell(Vector2i(x, ground_y_tiles + d), dirt_id, Vector2i(0, 0))
		x += 1
