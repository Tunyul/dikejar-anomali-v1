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
@export var random_ascend_enabled: bool = true
@export var ascend_chance: float = 0.25
@export var max_ascend_tiles: int = 2
@export var step_flat_enabled: bool = true
@export var step_flat_chance: float = 0.3
@export var step_flat_len1: int = 4
@export var step_flat_up_len: int = 4
@export var step_flat_len2: int = 4
@export var step_flat_flat_dirt_thickness: int = 3
@export var step_flat_up_dirt_thickness: int = 4
@export var step_flat_use_random: bool = true
@export var step_flat_len1_min: int = 2
@export var step_flat_len1_max: int = 6
@export var step_flat_up_len_min: int = 3
@export var step_flat_up_len_max: int = 6
@export var step_flat_len2_min: int = 2
@export var step_flat_len2_max: int = 6

@export var coin_vertical_offset_px: float = 48.0
@export var coin_y_tiles_min: int = 0
@export var coin_y_tiles_max: int = 1
@export var coin_spawn_margin_tiles: int = 2
@export var coin_groups_min: int = 1
@export var coin_groups_max: int = 2
@export var coins_per_group_min: int = 5
@export var coins_per_group_max: int = 7
@export var coin_spacing_tiles_min: int = 2
@export var coin_spacing_tiles_max: int = 3
@export var coin_group_spacing_tiles_min: int = 12
@export var coin_group_spacing_tiles_max: int = 24
@export var coin_scale: float = 1.0
@export var coin_anim_fps: float = 12.0
@export var coin_osc_amplitude: float = 8.0
@export var coin_osc_frequency: float = 1.2
@export var coin_spawn_x_additional_px: float = 0.0
@export var coin_spawn_follow_player: bool = false
@export var coin_spawn_player_offset_min_px: float = 150.0
@export var coin_spawn_player_offset_max_px: float = 450.0
@export var coin_min_clearance_px: float = 24.0
@export var coin_infinite_spawn_enabled: bool = true
@export var coin_stack_enabled: bool = true
@export var coin_stack_prob: float = 0.5
@export var coin_stack_max_per_column: int = 3
@export var coin_stack_vertical_offset_px: float = 10.0
@export var coin_stack_horizontal_jitter_px: float = 0.0
@export var coin_stack_use_tile_height: bool = true
@export var coin_stack_min_separation_px: float = 48.0
@export var coin_min_h_spacing_px: float = 24.0
@export var coin_min_v_spacing_px: float = 24.0
@export var coin_base_tint: Color = Color(1, 1, 1, 1)
@export var coin_stack_tint: Color = Color(0.8, 1.0, 0.9, 1.0)
@export var coin_tint_enabled: bool = true
@export var coin_allow_over_empty: bool = true

@export var enemy_spawn_enabled: bool = true
@export var enemy_spawn_margin_tiles: int = 2
@export var enemy_groups_min: int = 1
@export var enemy_groups_max: int = 2
@export var enemies_per_group_min: int = 1
@export var enemies_per_group_max: int = 2
@export var enemy_spacing_tiles_min: int = 8
@export var enemy_spacing_tiles_max: int = 16
@export var enemy_vertical_offset_px: float = 8.0
@export var enemy_scale: float = 0.5

var _noise := FastNoiseLite.new()
var _rng := RandomNumberGenerator.new()
var _generate_now: bool = false
var _coin_scene := preload("res://scenes/Coin.tscn")
var _next_spawn_x: int = -1
var _last_tint_enabled: bool = true
var _last_base_tint: Color = Color(1, 1, 1, 1)
var _last_stack_tint: Color = Color(1, 1, 1, 1)
var _enemy_scene := preload("res://scenes/EnemyCone.tscn")
var _next_enemy_spawn_x: int = -1
@export var spawn_update_interval_sec: float = 0.25
var _spawn_t_accum_coins: float = 0.0
var _spawn_t_accum_enemies: float = 0.0


func _ready():
	_configure_noise()
	if auto_generate_on_ready:
		generate()

func _process(delta: float) -> void:
	var p := get_parent()
	if p == null:
		return
	var cont_a: Node2D = p.get_node_or_null("CoinsA")
	var cont_b: Node2D = p.get_node_or_null("CoinsB")
	var enem_a: Node2D = p.get_node_or_null("EnemiesA")
	var enem_b: Node2D = p.get_node_or_null("EnemiesB")
	if cont_a != null and name == "TileMapLayer":
		cont_a.position.x = position.x
		var parent_movement_enabled := bool(p.get("movement_enabled")) if p != null else false
		if coin_infinite_spawn_enabled and parent_movement_enabled:
			_spawn_t_accum_coins += delta
			if _spawn_t_accum_coins >= spawn_update_interval_sec:
				_spawn_groups_append_right(cont_a)
				_spawn_t_accum_coins = 0.0
		if coin_tint_enabled != _last_tint_enabled or coin_base_tint != _last_base_tint or coin_stack_tint != _last_stack_tint:
			_apply_tint(cont_a)
			_last_tint_enabled = coin_tint_enabled
			_last_base_tint = coin_base_tint
			_last_stack_tint = coin_stack_tint
	if cont_b != null and name == "TileMapLayerB":
		cont_b.position.x = position.x
		var parent_movement_enabled_b := bool(p.get("movement_enabled")) if p != null else false
		if coin_infinite_spawn_enabled and parent_movement_enabled_b:
			_spawn_t_accum_coins += delta
			if _spawn_t_accum_coins >= spawn_update_interval_sec:
				_spawn_groups_append_right(cont_b)
				_spawn_t_accum_coins = 0.0
		if coin_tint_enabled != _last_tint_enabled or coin_base_tint != _last_base_tint or coin_stack_tint != _last_stack_tint:
			_apply_tint(cont_b)
			_last_tint_enabled = coin_tint_enabled
			_last_base_tint = coin_base_tint
			_last_stack_tint = coin_stack_tint
	if enem_a != null and name == "TileMapLayer":
		enem_a.position.x = position.x
		var move_en_a := bool(p.get("movement_enabled")) if p != null else false
		if enemy_spawn_enabled and move_en_a:
			_spawn_t_accum_enemies += delta
			if _spawn_t_accum_enemies >= spawn_update_interval_sec:
				_spawn_enemy_groups_append_right(enem_a)
				_spawn_t_accum_enemies = 0.0
	if enem_b != null and name == "TileMapLayerB":
		enem_b.position.x = position.x
		var move_en_b := bool(p.get("movement_enabled")) if p != null else false
		if enemy_spawn_enabled and move_en_b:
			_spawn_t_accum_enemies += delta
			if _spawn_t_accum_enemies >= spawn_update_interval_sec:
				_spawn_enemy_groups_append_right(enem_b)
				_spawn_t_accum_enemies = 0.0

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
		queue_redraw()
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
	var ascend_offset: int = 0
	var first_change_done: bool = false
	var pending_step: int = 0
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
		gy = int(clamp(gy + pending_step, 0, int(max(0, height - 1))))
		thick = int(clamp(ground_thickness, 1, height - gy))
		var use_step: bool = step_flat_enabled and ascend_offset == 0 and pending_step == 0 and _rng.randf() < step_flat_chance
		var plat_end: int = 0
		if use_step:
			var l1: int = step_flat_len1
			var lup: int = step_flat_up_len
			var l2: int = step_flat_len2
			if step_flat_use_random:
				l1 = _rng.randi_range(max(1, step_flat_len1_min), max(step_flat_len1_min, step_flat_len1_max))
				lup = _rng.randi_range(max(1, step_flat_up_len_min), max(step_flat_up_len_min, step_flat_up_len_max))
				l2 = _rng.randi_range(max(1, step_flat_len2_min), max(step_flat_len2_min, step_flat_len2_max))
			l1 = max(1, l1)
			lup = max(1, lup)
			l2 = max(1, l2)
			var total: int = l1 + lup + l2
			plat_end = int(min(x + total, width))
			var up_y: int = int(max(0, gy - 1))
			var end_l1: int = x + l1
			var end_lup: int = end_l1 + lup
			for px in range(x, plat_end):
				var top_y: int = gy
				var in_raised: bool = px >= end_l1 and px < end_lup
				if in_raised:
					# Pastikan baris flat lama dihapus pada area naik
					erase_cell(Vector2i(origin.x + px, origin.y + gy))
					if has_dirt:
						set_cell(Vector2i(origin.x + px, origin.y + gy), dirt_source_id, atlas_coords_dirt, alternative_dirt)
						var max_thick := int(clamp(ground_thickness, 1, height - gy))
						for by in range(1, max_thick):
							var bpos := Vector2i(origin.x + px, origin.y + gy + by)
							set_cell(bpos, dirt_source_id, atlas_coords_dirt, alternative_dirt)
					top_y = up_y
				var top: Vector2i = Vector2i(origin.x + px, origin.y + top_y)
				if has_top:
					var use_mid: bool = use_grass_mid and tile_set.has_source(grass_mid_source_id)
					var sid: int = grass_mid_source_id if use_mid else grass_source_id
					var coords: Vector2i = atlas_coords_grass_mid if use_mid else atlas_coords_grass
					var alt: int = alternative_grass_mid if use_mid else alternative_grass
					set_cell(top, sid, coords, alt)
				var fill_thick: int = step_flat_flat_dirt_thickness
				if in_raised:
					fill_thick = step_flat_up_dirt_thickness
				fill_thick = int(clamp(fill_thick, 1, height - top_y))
				for ty in range(1, fill_thick + 1):
					var pos: Vector2i = Vector2i(origin.x + px, origin.y + top_y + ty)
					if has_dirt:
						set_cell(pos, dirt_source_id, atlas_coords_dirt, alternative_dirt)
		else:
			var plat_len: int = _rng.randi_range(min_platform_len, max_platform_len)
			plat_end = int(min(x + plat_len, width))
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
	# no base redraw here; raised segment handled above
		x = plat_end
		var gap_len: int = _rng.randi_range(min_gap_len, max_gap_len)
		x = int(min(x + gap_len, width))
		if use_step:
			pending_step = 0
			first_change_done = true
		else:
			if ascend_offset > 0:
				pending_step = 1
				ascend_offset = int(max(0, ascend_offset - 1))
			elif random_ascend_enabled and ((not first_change_done) or _rng.randf() < ascend_chance) and ascend_offset < max_ascend_tiles:
				pending_step = -1
				ascend_offset += 1
				first_change_done = true
			else:
				pending_step = 0
		if add_dirt_band:
			_draw_dirt_band()

func _build_colliders():
	if tile_set == null:
		return
	var cell := tile_set.tile_size if tile_set != null else Vector2i(128, 128)
	var prev := get_node_or_null("TileColliders")
	if prev:
		remove_child(prev)
		prev.queue_free()
	var root := StaticBody2D.new()
	root.name = "TileColliders"
	root.collision_layer = 1
	add_child(root)
	for x in range(width):
		var y := 0
		while y < height:
			var mp := Vector2i(origin.x + x, origin.y + y)
			var sid := get_cell_source_id(mp)
			var solid := sid == grass_source_id or sid == grass_mid_source_id or sid == dirt_source_id
			if not solid:
				y += 1
				continue
			var start_y := y
			var end_y := y
			while end_y + 1 < height:
				var mp2 := Vector2i(origin.x + x, origin.y + end_y + 1)
				var sid2 := get_cell_source_id(mp2)
				var solid2 := sid2 == grass_source_id or sid2 == grass_mid_source_id or sid2 == dirt_source_id
				if not solid2:
					break
				end_y += 1
			var top_center: Vector2 = map_to_local(Vector2i(origin.x + x, origin.y + start_y))
			var bottom_center: Vector2 = map_to_local(Vector2i(origin.x + x, origin.y + end_y))
			var rect := RectangleShape2D.new()
			rect.size = Vector2(cell.x, float(end_y - start_y + 1) * float(cell.y))
			var col := CollisionShape2D.new()
			col.shape = rect
			col.position = Vector2(top_center.x, (top_center.y + bottom_center.y) * 0.5)
			root.add_child(col)
			y = end_y + 1

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
		_generate_pair_if_exists()
		var gp := get_parent()
		if gp != null:
			if has_method("spawn_initial_coins"):
				call_deferred("spawn_initial_coins")
			if has_method("spawn_initial_enemies"):
				call_deferred("spawn_initial_enemies")

		_generate_now = false

func _get_generate_now() -> bool:
	return _generate_now

func _generate_pair_if_exists() -> void:
	var p := get_parent()
	if p == null:
		return
	var layer_a: TileMapLayer = p.get_node_or_null("TileMapLayer") as TileMapLayer
	var layer_b: TileMapLayer = p.get_node_or_null("TileMapLayerB") as TileMapLayer
	if layer_a == null or layer_b == null:
		return
	# Sinkronisasi konfigurasi koin antara kedua layer: ambil dari instance pemanggil (self)
	var src: TileMapLayer = self
	var dst: TileMapLayer = layer_b if self == layer_a else layer_a
	if dst != null:
		dst.set("coin_tint_enabled", src.get("coin_tint_enabled"))
		dst.set("coin_base_tint", src.get("coin_base_tint"))
		dst.set("coin_stack_tint", src.get("coin_stack_tint"))
		dst.set("coin_vertical_offset_px", src.get("coin_vertical_offset_px"))
		dst.set("coin_y_tiles_min", src.get("coin_y_tiles_min"))
		dst.set("coin_y_tiles_max", src.get("coin_y_tiles_max"))
		dst.set("coin_spawn_margin_tiles", src.get("coin_spawn_margin_tiles"))
		dst.set("coin_groups_min", src.get("coin_groups_min"))
		dst.set("coin_groups_max", src.get("coin_groups_max"))
		dst.set("coins_per_group_min", src.get("coins_per_group_min"))
		dst.set("coins_per_group_max", src.get("coins_per_group_max"))
		dst.set("coin_spacing_tiles_min", src.get("coin_spacing_tiles_min"))
		dst.set("coin_spacing_tiles_max", src.get("coin_spacing_tiles_max"))
		dst.set("coin_group_spacing_tiles_min", src.get("coin_group_spacing_tiles_min"))
		dst.set("coin_group_spacing_tiles_max", src.get("coin_group_spacing_tiles_max"))
		dst.set("coin_scale", src.get("coin_scale"))
		dst.set("coin_anim_fps", src.get("coin_anim_fps"))
		dst.set("coin_osc_amplitude", src.get("coin_osc_amplitude"))
		dst.set("coin_osc_frequency", src.get("coin_osc_frequency"))
		dst.set("coin_spawn_x_additional_px", src.get("coin_spawn_x_additional_px"))
		dst.set("coin_spawn_follow_player", src.get("coin_spawn_follow_player"))
		dst.set("coin_spawn_player_offset_min_px", src.get("coin_spawn_player_offset_min_px"))
		dst.set("coin_spawn_player_offset_max_px", src.get("coin_spawn_player_offset_max_px"))
		dst.set("coin_min_clearance_px", src.get("coin_min_clearance_px"))
		dst.set("coin_infinite_spawn_enabled", src.get("coin_infinite_spawn_enabled"))
		dst.set("coin_stack_enabled", src.get("coin_stack_enabled"))
		dst.set("coin_stack_prob", src.get("coin_stack_prob"))
		dst.set("coin_stack_max_per_column", src.get("coin_stack_max_per_column"))
		dst.set("coin_stack_vertical_offset_px", src.get("coin_stack_vertical_offset_px"))
		dst.set("coin_stack_horizontal_jitter_px", src.get("coin_stack_horizontal_jitter_px"))
		dst.set("coin_stack_use_tile_height", src.get("coin_stack_use_tile_height"))
		dst.set("coin_stack_min_separation_px", src.get("coin_stack_min_separation_px"))
		dst.set("coin_min_h_spacing_px", src.get("coin_min_h_spacing_px"))
		dst.set("coin_min_v_spacing_px", src.get("coin_min_v_spacing_px"))
		dst.set("coin_allow_over_empty", src.get("coin_allow_over_empty"))
		dst.set("enemy_spawn_enabled", src.get("enemy_spawn_enabled"))
		dst.set("enemy_spawn_margin_tiles", src.get("enemy_spawn_margin_tiles"))
		dst.set("enemy_groups_min", src.get("enemy_groups_min"))
		dst.set("enemy_groups_max", src.get("enemy_groups_max"))
		dst.set("enemies_per_group_min", src.get("enemies_per_group_min"))
		dst.set("enemies_per_group_max", src.get("enemies_per_group_max"))
		dst.set("enemy_spacing_tiles_min", src.get("enemy_spacing_tiles_min"))
		dst.set("enemy_spacing_tiles_max", src.get("enemy_spacing_tiles_max"))
		dst.set("enemy_vertical_offset_px", src.get("enemy_vertical_offset_px"))
		dst.set("enemy_scale", src.get("enemy_scale"))
	if layer_a.has_method("generate"):
		layer_a.generate()
	layer_b.flat_start_enabled = false
	if layer_b.has_method("generate"):
		layer_b.generate()
	var cell: Vector2i = layer_a.tile_set.tile_size if layer_a.tile_set != null else Vector2i(128, 128)
	var seg: float = float(layer_a.width) * float(cell.x) * layer_a.scale.x
	layer_b.position.x = layer_a.position.x + seg
	if layer_a.has_method("clear_coins"):
		layer_a.clear_coins()
	if layer_a.has_method("spawn_initial_coins"):
		layer_a.spawn_initial_coins()
	if layer_a.has_method("clear_enemies"):
		layer_a.clear_enemies()
	if layer_a.has_method("spawn_initial_enemies"):
		layer_a.spawn_initial_enemies()
	if layer_b.has_method("clear_coins"):
		layer_b.clear_coins()
	if layer_b.has_method("spawn_initial_coins"):
		layer_b.spawn_initial_coins()
	if layer_b.has_method("clear_enemies"):
		layer_b.clear_enemies()
	if layer_b.has_method("spawn_initial_enemies"):
		layer_b.spawn_initial_enemies()



func spawn_initial_coins() -> void:
	var p := get_parent()
	if p == null:
		return
	var container: Node2D = null
	if name == "TileMapLayer":
		container = p.get_node_or_null("CoinsA")
	elif name == "TileMapLayerB":
		container = p.get_node_or_null("CoinsB")
	if container == null:
		return
	_spawn_groups_in_view_right(container)
	_next_spawn_x = -1

func spawn_initial_enemies() -> void:
	var p := get_parent()
	if p == null:
		return
	var container: Node2D = null
	if name == "TileMapLayer":
		container = p.get_node_or_null("EnemiesA")
	elif name == "TileMapLayerB":
		container = p.get_node_or_null("EnemiesB")
	if container == null:
		return
	_spawn_enemy_groups_in_view_right(container)
	_next_enemy_spawn_x = -1

func reset_coin_spawn_state() -> void:
	_next_spawn_x = -1

func reset_enemy_spawn_state() -> void:
	_next_enemy_spawn_x = -1



func clear_coins() -> void:
	var p := get_parent()
	if p == null:
		return
	var container: Node = null
	if name == "TileMapLayer":
		container = p.get_node_or_null("CoinsA")
	elif name == "TileMapLayerB":
		container = p.get_node_or_null("CoinsB")
	if container == null:
		return
	for c in container.get_children():
		c.queue_free()

func clear_enemies() -> void:
	var p := get_parent()
	if p == null:
		return
	var container: Node = null
	if name == "TileMapLayer":
		container = p.get_node_or_null("EnemiesA")
	elif name == "TileMapLayerB":
		container = p.get_node_or_null("EnemiesB")
	if container == null:
		return
	for e in container.get_children():
		e.queue_free()

func _spawn_groups_in_view_right(container: Node) -> void:
	if tile_set == null or container == null:
		return
	if container is Node2D:
		(container as Node2D).position.x = position.x
	for c in container.get_children():
		c.queue_free()
	var occupied: Dictionary = {}
	var sep_h: float = max(1.0, coin_min_h_spacing_px)
	var sep_v: float = max(1.0, coin_min_v_spacing_px)
	var w: int = width
	var cell: Vector2i = tile_set.tile_size if tile_set != null else Vector2i(128, 128)
	var margin: int = int(max(0, coin_spawn_margin_tiles))
	var max_x: int = int(max(margin + 1, w - margin))
	var cam := get_viewport().get_camera_2d()
	var vw := int(get_viewport_rect().size.x)
	if vw <= 0:
		vw = 1024
	var step_px := int(float(cell.x) * scale.x)
	var cx := cam.get_screen_center_position().x if cam != null else 0.0
	var left_x := cx - float(vw) * 0.5
	var right_x := cx + float(vw) * 0.5
	var start_world_x := left_x
	if coin_spawn_follow_player:
		var p := get_parent()
		var pl := p.get_node_or_null("Player") if p != null else null
		if pl != null and pl is Node2D:
			var px: float = (pl as Node2D).global_position.x
			var min_off: float = max(0.0, coin_spawn_player_offset_min_px)
			var max_off: float = max(min_off, coin_spawn_player_offset_max_px)
			start_world_x = _rng.randf_range(px + min_off, px + max_off)
		else:
			start_world_x = _rng.randf_range(left_x, right_x - float(step_px))
	else:
		start_world_x = _rng.randf_range(left_x, right_x - float(step_px))
	var local := to_local(Vector2(start_world_x, 0.0))
	var map := local_to_map(local)
	var min_x: int = margin
	if flat_start_enabled:
		min_x = max(min_x, flat_start_len)
	if name == "TileMapLayer":
		min_x = max(min_x, flat_start_len)
	var x: int = clamp(map.x - origin.x, min_x, max_x - 1)
	var groups: int = _rng.randi_range(max(1, coin_groups_min), max(coin_groups_min, coin_groups_max))
	for g in range(groups):
		var count: int = _rng.randi_range(max(1, coins_per_group_min), max(coins_per_group_min, coins_per_group_max))
		var spacing_tiles: int = _rng.randi_range(max(1, coin_spacing_tiles_min), max(coin_spacing_tiles_min, coin_spacing_tiles_max))
		var vtiles_min: int = max(0, coin_y_tiles_min)
		var vtiles_max: int = max(vtiles_min, coin_y_tiles_max)
		var group_vtiles: int = _rng.randi_range(vtiles_min, vtiles_max)
		var offset_px: float = coin_vertical_offset_px if coin_vertical_offset_px > 0.0 else 32.0
		var clearance_px: float = max(0.0, float(coin_min_clearance_px)) + max(0.0, float(coin_osc_amplitude))
		for i in range(count):
			var mx := x + i * spacing_tiles
			if mx >= max_x:
				break
			var top_y := -1
			for y in range(height - 1, -1, -1):
				var mp := Vector2i(origin.x + mx, origin.y + y)
				var sid := get_cell_source_id(mp)
				if sid != -1:
					var above_sid := -1
					if y - 1 >= 0:
						above_sid = get_cell_source_id(Vector2i(origin.x + mx, origin.y + y - 1))
					if above_sid == -1:
						top_y = y
						break
			var local_center: Vector2
			if top_y == -1:
				if not coin_allow_over_empty:
					continue
				var pseudo_y: int = int(clamp(ground_y, 0, height - 1))
				local_center = map_to_local(Vector2i(origin.x + mx, origin.y + pseudo_y))
			else:
				local_center = map_to_local(Vector2i(origin.x + mx, origin.y + top_y))
			var world_center: Vector2 = to_global(local_center)
			var world_cell_h: float = float(cell.y) * scale.y
			var top_surface_y: float = world_center.y - world_cell_h * 0.5
			var coin_world: Vector2 = Vector2(world_center.x + coin_spawn_x_additional_px, top_surface_y - offset_px - float(group_vtiles) * world_cell_h - clearance_px)
			var vstep: float = max(world_cell_h, coin_stack_min_separation_px) + coin_min_clearance_px + coin_osc_amplitude * 2.0
			var stack_count: int = 1
			if coin_stack_enabled:
				var prob: float = clamp(coin_stack_prob, 0.0, 1.0)
				if _rng.randf() < prob:
					stack_count = _rng.randi_range(2, max(2, coin_stack_max_per_column))
			for s in range(stack_count):
				var jitter_x: float = _rng.randf_range(-coin_stack_horizontal_jitter_px, coin_stack_horizontal_jitter_px)
				var stacked_world: Vector2 = Vector2(coin_world.x + jitter_x, coin_world.y - float(s) * vstep)
				var ncoin: Area2D = _coin_scene.instantiate() as Area2D
				var segment: String = "A" if name == "TileMapLayer" else "B"
				ncoin.set("source_segment", segment)
				var tint_color: Color = coin_stack_tint if s > 0 else coin_base_tint
				ncoin.set("tint", tint_color if coin_tint_enabled else Color(1, 1, 1, 1))
				ncoin.set("is_stack", s > 0)
				var lp: Vector2 = container.to_local(stacked_world)
				var key := str(int(round(lp.x / sep_h))) + ":" + str(int(round(lp.y / sep_v)))
				if occupied.has(key):
					continue
				var too_close: bool = false
				for c in container.get_children():
					if c is Node2D:
						var cp: Vector2 = (c as Node2D).position
						var dx: float = abs(cp.x - lp.x)
						var dy: float = abs(cp.y - lp.y)
						if (coin_min_h_spacing_px > 0.0 or coin_min_v_spacing_px > 0.0):
							if dx < coin_min_h_spacing_px and dy < coin_min_v_spacing_px:
								too_close = true
								break
						else:
							if dx <= 0.001 and dy <= 0.001:
								too_close = true
								break
				if too_close:
					continue
				if coin_scale > 0.0:
					ncoin.scale = Vector2(coin_scale, coin_scale)
				if coin_anim_fps > 0.0:
					ncoin.set("anim_fps", coin_anim_fps)
				if coin_osc_amplitude > 0.0:
					ncoin.set("osc_amplitude", coin_osc_amplitude)
				if coin_osc_frequency > 0.0:
					ncoin.set("osc_frequency", coin_osc_frequency)
				ncoin.position = lp
				ncoin.z_index = 100
				container.add_child(ncoin)
				occupied[key] = true
		var group_gap: int = _rng.randi_range(max(1, coin_group_spacing_tiles_min), max(coin_group_spacing_tiles_min, coin_group_spacing_tiles_max))
		x = min(max_x, x + max(1, count) * spacing_tiles + group_gap)

func _spawn_enemy_groups_in_view_right(container: Node) -> void:
	if tile_set == null or container == null or not enemy_spawn_enabled:
		return
	if container is Node2D:
		(container as Node2D).position.x = position.x
	for c in container.get_children():
		c.queue_free()
	var w: int = width
	var cell: Vector2i = tile_set.tile_size if tile_set != null else Vector2i(128, 128)
	var margin: int = int(max(0, enemy_spawn_margin_tiles))
	var max_x: int = int(max(margin + 1, w - margin))
	var cam := get_viewport().get_camera_2d()
	var vw := int(get_viewport_rect().size.x)
	if vw <= 0:
		vw = 1024
	var step_px := int(float(cell.x) * scale.x)
	var cx := cam.get_screen_center_position().x if cam != null else 0.0
	var left_x := cx - float(vw) * 0.5
	var right_x := cx + float(vw) * 0.5
	var start_world_x := _rng.randf_range(left_x, right_x - float(step_px))
	var local := to_local(Vector2(start_world_x, 0.0))
	var map := local_to_map(local)
	var min_x: int = margin
	if flat_start_enabled:
		min_x = max(min_x, flat_start_len)
	if name == "TileMapLayer":
		min_x = max(min_x, flat_start_len)
	var x: int = clamp(map.x - origin.x, min_x, max_x - 1)
	var groups: int = _rng.randi_range(max(1, enemy_groups_min), max(enemy_groups_min, enemy_groups_max))
	for g in range(groups):
		var count: int = _rng.randi_range(max(1, enemies_per_group_min), max(enemies_per_group_min, enemies_per_group_max))
		var spacing_tiles: int = _rng.randi_range(max(1, enemy_spacing_tiles_min), max(enemy_spacing_tiles_min, enemy_spacing_tiles_max))
		for i in range(count):
			var mx := x + i * spacing_tiles
			if mx >= max_x:
				break
			var top_y := -1
			for y in range(height - 1, -1, -1):
				var mp := Vector2i(origin.x + mx, origin.y + y)
				var sid := get_cell_source_id(mp)
				if sid != -1:
					var above_sid := -1
					if y - 1 >= 0:
						above_sid = get_cell_source_id(Vector2i(origin.x + mx, origin.y + y - 1))
					if above_sid == -1:
						top_y = y
						break
			var lc: Vector2
			var wc: Vector2
			if top_y == -1:
				var pseudo_y: int = int(clamp(ground_y, 0, height - 1))
				lc = map_to_local(Vector2i(origin.x + mx, origin.y + pseudo_y))
				wc = to_global(lc)
			else:
				lc = map_to_local(Vector2i(origin.x + mx, origin.y + top_y))
				wc = to_global(lc)
			var world_cell_h: float = float(cell.y) * scale.y
			var top_surface_y: float = wc.y - world_cell_h * 0.5
			var enemy_world: Vector2 = Vector2(wc.x, top_surface_y - enemy_vertical_offset_px)
			var nenemy: Node2D = _enemy_scene.instantiate() as Node2D
			if enemy_scale > 0.0:
				nenemy.scale = Vector2(enemy_scale, enemy_scale)
			var lp: Vector2 = (container as Node2D).to_local(enemy_world)
			nenemy.position = lp
			nenemy.z_index = 95
			container.add_child(nenemy)
		var group_gap: int = _rng.randi_range(max(1, enemy_spacing_tiles_min), max(enemy_spacing_tiles_min, enemy_spacing_tiles_max))
		x = min(max_x, x + max(1, count) * spacing_tiles + group_gap)

func _spawn_groups_append_right(container: Node) -> void:
	if not coin_infinite_spawn_enabled or tile_set == null or container == null:
		return
	var cell: Vector2i = tile_set.tile_size if tile_set != null else Vector2i(128, 128)
	var margin: int = int(max(0, coin_spawn_margin_tiles))
	var max_x: int = int(max(margin + 1, width - margin))
	var cam := get_viewport().get_camera_2d()
	var vw := int(get_viewport_rect().size.x)
	if vw <= 0:
		vw = 1024
	var cx := cam.get_screen_center_position().x if cam != null else 0.0
	var right_x := cx + float(vw) * 0.5
	var step_px := int(float(cell.x) * scale.x)
	var min_x: int = margin
	if flat_start_enabled:
		min_x = max(min_x, flat_start_len)
	if name == "TileMapLayer":
		min_x = max(min_x, flat_start_len)
	if _next_spawn_x < 0:
		var start_world_x := right_x - float(step_px) * 2.0
		var local := to_local(Vector2(start_world_x, 0.0))
		var map := local_to_map(local)
		_next_spawn_x = clamp(map.x - origin.x, min_x, max_x - 1)
	var local_center: Vector2 = map_to_local(Vector2i(origin.x + _next_spawn_x, origin.y))
	var world_center: Vector2 = to_global(local_center)
	var occupied2: Dictionary = {}
	var sep_h2: float = max(1.0, coin_min_h_spacing_px)
	var sep_v2: float = max(1.0, coin_min_v_spacing_px)
	for ec in container.get_children():
		if ec is Node2D:
			var ep: Vector2 = (ec as Node2D).position
			var ekey := str(int(round(ep.x / sep_h2))) + ":" + str(int(round(ep.y / sep_v2)))
			occupied2[ekey] = true
	while world_center.x <= right_x + float(step_px) * 2.0:
		var count: int = _rng.randi_range(max(1, coins_per_group_min), max(coins_per_group_min, coins_per_group_max))
		var spacing_tiles: int = _rng.randi_range(max(1, coin_spacing_tiles_min), max(coin_spacing_tiles_min, coin_spacing_tiles_max))
		var vtiles_min: int = max(0, coin_y_tiles_min)
		var vtiles_max: int = max(vtiles_min, coin_y_tiles_max)
		var group_vtiles: int = _rng.randi_range(vtiles_min, vtiles_max)
		var offset_px: float = coin_vertical_offset_px if coin_vertical_offset_px > 0.0 else 32.0
		var clearance_px: float = max(0.0, float(coin_min_clearance_px)) + max(0.0, float(coin_osc_amplitude))
		for i in range(count):
			var mx := _next_spawn_x + i * spacing_tiles
			if mx >= max_x:
				break
			var top_y := -1
			for y in range(height - 1, -1, -1):
				var mp := Vector2i(origin.x + mx, origin.y + y)
				var sid := get_cell_source_id(mp)
				if sid != -1:
					var above_sid := -1
					if y - 1 >= 0:
						above_sid = get_cell_source_id(Vector2i(origin.x + mx, origin.y + y - 1))
					if above_sid == -1:
						top_y = y
						break
			var lc: Vector2
			var wc: Vector2
			if top_y == -1:
				if not coin_allow_over_empty:
					continue
				var pseudo_y2: int = int(clamp(ground_y, 0, height - 1))
				lc = map_to_local(Vector2i(origin.x + mx, origin.y + pseudo_y2))
				wc = to_global(lc)
			else:
				lc = map_to_local(Vector2i(origin.x + mx, origin.y + top_y))
				wc = to_global(lc)
			var world_cell_h: float = float(cell.y) * scale.y
			var top_surface_y: float = wc.y - world_cell_h * 0.5
			var coin_world: Vector2 = Vector2(wc.x + coin_spawn_x_additional_px, top_surface_y - offset_px - float(group_vtiles) * world_cell_h - clearance_px)
			var vstep2: float = max(world_cell_h, coin_stack_min_separation_px) + coin_min_clearance_px + coin_osc_amplitude * 2.0
			var stack_count: int = 1
			if coin_stack_enabled:
				var prob2: float = clamp(coin_stack_prob, 0.0, 1.0)
				if _rng.randf() < prob2:
					stack_count = _rng.randi_range(2, max(2, coin_stack_max_per_column))
			for s in range(stack_count):
				var jitter_x2: float = _rng.randf_range(-coin_stack_horizontal_jitter_px, coin_stack_horizontal_jitter_px)
				var stacked_world2: Vector2 = Vector2(coin_world.x + jitter_x2, coin_world.y - float(s) * vstep2)
				var ncoin2: Area2D = _coin_scene.instantiate() as Area2D
				var segment2: String = "A" if name == "TileMapLayer" else "B"
				ncoin2.set("source_segment", segment2)
				var tint_color2: Color = coin_stack_tint if s > 0 else coin_base_tint
				ncoin2.set("tint", tint_color2 if coin_tint_enabled else Color(1, 1, 1, 1))
				ncoin2.set("is_stack", s > 0)
				var lp2: Vector2 = (container as Node2D).to_local(stacked_world2)
				var key2 := str(int(round(lp2.x / sep_h2))) + ":" + str(int(round(lp2.y / sep_v2)))
				if occupied2.has(key2):
					continue
				var too_close2: bool = false
				for c2 in container.get_children():
					if c2 is Node2D:
						var cp2: Vector2 = (c2 as Node2D).position
						var dx2: float = abs(cp2.x - lp2.x)
						var dy2: float = abs(cp2.y - lp2.y)
						if (coin_min_h_spacing_px > 0.0 or coin_min_v_spacing_px > 0.0):
							if dx2 < coin_min_h_spacing_px and dy2 < coin_min_v_spacing_px:
								too_close2 = true
								break
						else:
							if dx2 <= 0.001 and dy2 <= 0.001:
								too_close2 = true
								break
				if too_close2:
					continue
				if coin_scale > 0.0:
					ncoin2.scale = Vector2(coin_scale, coin_scale)
				if coin_anim_fps > 0.0:
					ncoin2.set("anim_fps", coin_anim_fps)
				if coin_osc_amplitude > 0.0:
					ncoin2.set("osc_amplitude", coin_osc_amplitude)
				if coin_osc_frequency > 0.0:
					ncoin2.set("osc_frequency", coin_osc_frequency)
				ncoin2.position = lp2
				ncoin2.z_index = 100
				container.add_child(ncoin2)
				occupied2[key2] = true
		var group_gap: int = _rng.randi_range(max(1, coin_group_spacing_tiles_min), max(coin_group_spacing_tiles_min, coin_group_spacing_tiles_max))
		_next_spawn_x = min(max_x, _next_spawn_x + max(1, count) * spacing_tiles + group_gap)
		local_center = map_to_local(Vector2i(origin.x + _next_spawn_x, origin.y))
		world_center = to_global(local_center)

func _spawn_enemy_groups_append_right(container: Node) -> void:
	if not enemy_spawn_enabled or tile_set == null or container == null:
		return
	var cell: Vector2i = tile_set.tile_size if tile_set != null else Vector2i(128, 128)
	var margin: int = int(max(0, enemy_spawn_margin_tiles))
	var max_x: int = int(max(margin + 1, width - margin))
	var cam := get_viewport().get_camera_2d()
	var vw := int(get_viewport_rect().size.x)
	if vw <= 0:
		vw = 1024
	var cx := cam.get_screen_center_position().x if cam != null else 0.0
	var right_x := cx + float(vw) * 0.5
	var step_px := int(float(cell.x) * scale.x)
	var min_x: int = margin
	if flat_start_enabled:
		min_x = max(min_x, flat_start_len)
	if name == "TileMapLayer":
		min_x = max(min_x, flat_start_len)
	if _next_enemy_spawn_x < 0:
		var start_world_x := right_x - float(step_px) * 2.0
		var local := to_local(Vector2(start_world_x, 0.0))
		var map := local_to_map(local)
		_next_enemy_spawn_x = clamp(map.x - origin.x, min_x, max_x - 1)
	var local_center: Vector2 = map_to_local(Vector2i(origin.x + _next_enemy_spawn_x, origin.y))
	var world_center: Vector2 = to_global(local_center)
	while world_center.x <= right_x + float(step_px) * 2.0:
		var count: int = _rng.randi_range(max(1, enemies_per_group_min), max(enemies_per_group_min, enemies_per_group_max))
		var spacing_tiles: int = _rng.randi_range(max(1, enemy_spacing_tiles_min), max(enemy_spacing_tiles_min, enemy_spacing_tiles_max))
		for i in range(count):
			var mx := _next_enemy_spawn_x + i * spacing_tiles
			if mx >= max_x:
				break
			var top_y := -1
			for y in range(height - 1, -1, -1):
				var mp := Vector2i(origin.x + mx, origin.y + y)
				var sid := get_cell_source_id(mp)
				if sid != -1:
					var above_sid := -1
					if y - 1 >= 0:
						above_sid = get_cell_source_id(Vector2i(origin.x + mx, origin.y + y - 1))
					if above_sid == -1:
						top_y = y
						break
			var lc: Vector2
			var wc: Vector2
			if top_y == -1:
				var pseudo_y: int = int(clamp(ground_y, 0, height - 1))
				lc = map_to_local(Vector2i(origin.x + mx, origin.y + pseudo_y))
				wc = to_global(lc)
			else:
				lc = map_to_local(Vector2i(origin.x + mx, origin.y + top_y))
				wc = to_global(lc)
			var world_cell_h: float = float(cell.y) * scale.y
			var top_surface_y: float = wc.y - world_cell_h * 0.5
			var enemy_world: Vector2 = Vector2(wc.x, top_surface_y - enemy_vertical_offset_px)
			var nenemy2: Node2D = _enemy_scene.instantiate() as Node2D
			if enemy_scale > 0.0:
				nenemy2.scale = Vector2(enemy_scale, enemy_scale)
			var lp2: Vector2 = (container as Node2D).to_local(enemy_world)
			nenemy2.position = lp2
			nenemy2.z_index = 95
			container.add_child(nenemy2)
		var group_gap: int = _rng.randi_range(max(1, enemy_spacing_tiles_min), max(enemy_spacing_tiles_min, enemy_spacing_tiles_max))
		_next_enemy_spawn_x = min(max_x, _next_enemy_spawn_x + max(1, count) * spacing_tiles + group_gap)
		local_center = map_to_local(Vector2i(origin.x + _next_enemy_spawn_x, origin.y))
		world_center = to_global(local_center)
func _apply_tint(container: Node) -> void:
	if container == null:
		return
	for c in container.get_children():
		if c != null and c.has_method("set"):
			var is_stack := false
			if c.has_method("get"):
				is_stack = bool(c.get("is_stack"))
			var tint_color: Color = coin_stack_tint if is_stack else coin_base_tint
			c.set("tint", tint_color if coin_tint_enabled else Color(1, 1, 1, 1))
