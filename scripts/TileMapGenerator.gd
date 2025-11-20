@tool
extends TileMapLayer

@export var width: int = 128
@export var height: int = 128
@export var noise_seed: int = 12345
@export var noise_frequency: float = 0.02
@export var grass_threshold: float = 0.6
@export var dirt_threshold: float = 0.4
@export var auto_generate_on_ready: bool = false
@export var clear_before_generate: bool = true
@export var grass_source_id: int = 0
@export var dirt_source_id: int = 1
@export var atlas_coords_grass: Vector2i = Vector2i(0, 0)
@export var atlas_coords_dirt: Vector2i = Vector2i(0, 0)
@export var alternative_grass: int = 0
@export var alternative_dirt: int = 0
@export var generate_now: bool = false: set = _set_generate_now, get = _get_generate_now
@export var runner_mode: bool = true
@export var ground_y: int = 8
@export var ground_thickness: int = 3
@export var min_platform_len: int = 6
@export var max_platform_len: int = 14
@export var min_gap_len: int = 2
@export var max_gap_len: int = 5
@export var use_grass_mid: bool = true
@export var grass_mid_source_id: int = 0
@export var atlas_coords_grass_mid: Vector2i = Vector2i(0, 0)
@export var alternative_grass_mid: int = 0
@export var origin: Vector2i = Vector2i(0, 0)
@export var add_dirt_band: bool = false
@export var dirt_y: int = 12
@export var dirt_band_thickness: int = 1
@export var show_y_labels: bool = false
@export var labels_x_tiles_offset: int = -1
@export var labels_color: Color = Color(1, 1, 1, 0.8)
@export var labels_font_size: int = 18
@export var show_x_labels: bool = false
@export var labels_y_tiles_offset: int = -1
@export var show_collision_overlay: bool = false
@export var collision_overlay_color: Color = Color(0, 1, 0, 0.25)
@export var show_gap_overlay: bool = false
@export var collision_overlay_outline: bool = false
@export var overlay_only_ground: bool = true
@export var overlay_include_grass: bool = true
@export var overlay_include_dirt: bool = true
@export var flat_start_enabled: bool = true
@export var flat_start_len: int = 8

var _noise := FastNoiseLite.new()
var _rng := RandomNumberGenerator.new()
var _generate_now: bool = false

func _ready():
	_configure_noise()
	if auto_generate_on_ready:
		generate()
	_build_colliders()

func _configure_noise():
	_rng.randomize()
	_noise.seed = int(_rng.randi()) if noise_seed == 0 else noise_seed
	_noise.frequency = noise_frequency

func clear_map():
	clear()
	var cc := get_node_or_null("TileColliders")
	if cc:
		cc.queue_free()

func generate():
	if tile_set == null:
		return
	if clear_before_generate:
		clear()
		var cc := get_node_or_null("TileColliders")
		if cc:
			cc.queue_free()
	_configure_noise()
	if runner_mode:
		_generate_flat_runner()
		_build_colliders()
	else:
		var has_top: bool = tile_set.has_source(grass_source_id) or (use_grass_mid and tile_set.has_source(grass_mid_source_id))
		var has_dirt := tile_set.has_source(dirt_source_id)
		for x in range(width):
			for y in range(height):
				var n := _noise.get_noise_2d(float(x), float(y))
				var v := (n + 1.0) * 0.5
				var pos: Vector2i = Vector2i(origin.x + x, origin.y + y)
				if flat_start_enabled and x < flat_start_len and y == ground_y and has_top:
					var use_mid: bool = use_grass_mid and tile_set.has_source(grass_mid_source_id)
					var sid: int = grass_mid_source_id if use_mid else grass_source_id
					var coords: Vector2i = atlas_coords_grass_mid if use_mid else atlas_coords_grass
					var alt: int = alternative_grass_mid if use_mid else alternative_grass
					set_cell(pos, sid, coords, alt)
					if has_dirt:
						if y + 1 < height:
							var below1: Vector2i = Vector2i(origin.x + x, origin.y + y + 1)
							set_cell(below1, dirt_source_id, atlas_coords_dirt, alternative_dirt)
						if y + 2 < height:
							var below2: Vector2i = Vector2i(origin.x + x, origin.y + y + 2)
							set_cell(below2, dirt_source_id, atlas_coords_dirt, alternative_dirt)
					continue
				if flat_start_enabled and x < flat_start_len and has_dirt:
					var max_flat_y: int = ground_y + max(1, ground_thickness) - 1
					if y > ground_y and y <= max_flat_y and y < height:
						set_cell(pos, dirt_source_id, atlas_coords_dirt, alternative_dirt)
						continue
				if v >= grass_threshold and has_top:
					var use_mid: bool = use_grass_mid and tile_set.has_source(grass_mid_source_id)
					var sid: int = grass_mid_source_id if use_mid else grass_source_id
					var coords: Vector2i = atlas_coords_grass_mid if use_mid else atlas_coords_grass
					var alt: int = alternative_grass_mid if use_mid else alternative_grass
					set_cell(pos, sid, coords, alt)
					if has_dirt:
						if y + 1 < height:
							var below1: Vector2i = Vector2i(origin.x + x, origin.y + y + 1)
							set_cell(below1, dirt_source_id, atlas_coords_dirt, alternative_dirt)
						if y + 2 < height:
							var below2: Vector2i = Vector2i(origin.x + x, origin.y + y + 2)
							set_cell(below2, dirt_source_id, atlas_coords_dirt, alternative_dirt)
				elif v >= dirt_threshold and has_dirt:
					set_cell(pos, dirt_source_id, atlas_coords_dirt, alternative_dirt)
		if add_dirt_band:
			_draw_dirt_band()
		_build_colliders()
		queue_redraw()

func _generate_flat_runner():
	var gy: int = int(clamp(ground_y, 0, int(max(0, height - 1))))
	var thick: int = int(clamp(ground_thickness, 1, height - gy))
	var has_top: bool = tile_set.has_source(grass_source_id) or (use_grass_mid and tile_set.has_source(grass_mid_source_id))
	var has_dirt: bool = tile_set.has_source(dirt_source_id)
	var x: int = 0
	if flat_start_enabled:
		var start_len: int = int(min(flat_start_len, width))
		for px in range(0, start_len):
			var top: Vector2i = Vector2i(origin.x + px, origin.y + gy)
			if has_top:
				var use_mid: bool = use_grass_mid and tile_set.has_source(grass_mid_source_id)
				var sid: int = grass_mid_source_id if use_mid else grass_source_id
				var coords: Vector2i = atlas_coords_grass_mid if use_mid else atlas_coords_grass
				var alt: int = alternative_grass_mid if use_mid else alternative_grass
				set_cell(top, sid, coords, alt)
			for ty in range(1, thick):
				var pos: Vector2i = Vector2i(origin.x + px, origin.y + gy + ty)
				if has_dirt:
					set_cell(pos, dirt_source_id, atlas_coords_dirt, alternative_dirt)
		x = start_len
	while x < width:
		var plat_len: int = _rng.randi_range(min_platform_len, max_platform_len)
		var plat_end: int = int(min(x + plat_len, width))
		for px in range(x, plat_end):
			var top: Vector2i = Vector2i(origin.x + px, origin.y + gy)
			if has_top:
				var use_mid: bool = use_grass_mid and tile_set.has_source(grass_mid_source_id)
				var sid: int = grass_mid_source_id if use_mid else grass_source_id
				var coords: Vector2i = atlas_coords_grass_mid if use_mid else atlas_coords_grass
				var alt: int = alternative_grass_mid if use_mid else alternative_grass
				set_cell(top, sid, coords, alt)
			for ty in range(1, thick):
				var pos: Vector2i = Vector2i(origin.x + px, origin.y + gy + ty)
				if has_dirt:
					set_cell(pos, dirt_source_id, atlas_coords_dirt, alternative_dirt)
		x = plat_end
		var gap_len: int = _rng.randi_range(min_gap_len, max_gap_len)
		x = int(min(x + gap_len, width))
		if add_dirt_band:
			_draw_dirt_band()

func _build_colliders():
	if tile_set == null:
		return
	var cell := tile_set.tile_size if tile_set != null else Vector2i(128, 128)
	var root := StaticBody2D.new()
	root.name = "TileColliders"
	root.collision_layer = 1
	add_child(root)
	for x in range(width):
		for y in range(height):
			var mp := Vector2i(origin.x + x, origin.y + y)
			var sid := get_cell_source_id(mp)
			var is_grass := sid == grass_source_id or sid == grass_mid_source_id
			var is_dirt := sid == dirt_source_id
			if not is_grass and not is_dirt:
				continue
			var rect := RectangleShape2D.new()
			rect.size = Vector2(cell.x, cell.y)
			var col := CollisionShape2D.new()
			col.shape = rect
			var center: Vector2 = map_to_local(mp)
			col.position = center
			root.add_child(col)

func _draw_dirt_band():
	if tile_set == null:
		return
	var has_dirt: bool = tile_set.has_source(dirt_source_id)
	if not has_dirt:
		return
	var dy: int = int(clamp(dirt_y, 0, int(max(0, height - 1))))
	var thick: int = int(clamp(dirt_band_thickness, 1, height - dy))
	for px in range(0, width):
		for ty in range(0, thick):
			var pos: Vector2i = Vector2i(origin.x + px, origin.y + dy + ty)
			set_cell(pos, dirt_source_id, atlas_coords_dirt, alternative_dirt)

func _draw() -> void:
	var font := ThemeDB.fallback_font
	var size := labels_font_size if labels_font_size > 0 else ThemeDB.fallback_font_size
	var cell := tile_set.tile_size if tile_set != null else Vector2i(128, 128)

	if show_y_labels:
		var base_x := (origin.x + labels_x_tiles_offset) * cell.x + float(cell.x) * 0.5
		for y in range(height):
			var yy := (origin.y + y) * cell.y + float(cell.y) * 0.5
			draw_string(font, Vector2(base_x, yy), str(y), HORIZONTAL_ALIGNMENT_LEFT, -1.0, size)

	if show_x_labels:
		var y_base := (origin.y + labels_y_tiles_offset) * cell.y + float(cell.y) * 0.5
		for x in range(width):
			var xx := (origin.x + x) * cell.x + float(cell.x) * 0.5
			draw_string(font, Vector2(xx, y_base), str(x), HORIZONTAL_ALIGNMENT_LEFT, -1.0, size)

	if show_collision_overlay:
		for x in range(width):
			for y in range(height):
				var mp := Vector2i(origin.x + x, origin.y + y)
				var td := get_cell_tile_data(mp)
				var has_col := false
				var has_phys_layers := tile_set != null and tile_set.get_physics_layers_count() > 0
				if td != null and has_phys_layers:
					has_col = td.get_collision_polygons_count(0) > 0
				elif td != null and not has_phys_layers:
					has_col = get_cell_source_id(mp) != -1
				var sid := get_cell_source_id(mp)
				var is_grass := overlay_include_grass and (sid == grass_source_id or sid == grass_mid_source_id)
				var is_dirt := overlay_include_dirt and sid == dirt_source_id
				if overlay_only_ground and not (is_grass or is_dirt):
					continue
				var tl := Vector2(float(origin.x + x) * cell.x, float(origin.y + y) * cell.y)
				var rect := Rect2(tl, Vector2(cell.x, cell.y))
				if show_gap_overlay:
					if not has_col:
						draw_rect(rect, collision_overlay_color, not collision_overlay_outline)
				else:
					if has_col:
						draw_rect(rect, collision_overlay_color, not collision_overlay_outline)

func _set_generate_now(value: bool) -> void:
	_generate_now = value
	if value:
		generate()
		_generate_now = false

func _get_generate_now() -> bool:
	return _generate_now
