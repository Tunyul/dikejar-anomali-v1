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
@export var max_platform_len: int = 12
@export var min_gap_len: int = 2
@export var max_gap_len: int = 4
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
@export var coin_y_tiles_min: int = -1
@export var coin_y_tiles_max: int = -1
@export var coin_spawn_margin_tiles: int = 1
@export var coin_groups_min: int = 0
@export var coin_groups_max: int = 0
@export var coins_per_group_min: int = 5
@export var coins_per_group_max: int = 7
@export var coin_spacing_tiles_min: int = 1
@export var coin_spacing_tiles_max: int = 1
@export var coin_group_spacing_tiles_min: int = 15
@export var coin_group_spacing_tiles_max: int = 16
@export var coin_scale: float = 0.7
@export var coin_anim_fps: float = 12.0
@export var coin_osc_amplitude: float = 12.0
@export var coin_osc_frequency: float = 0.2
@export var coin_spawn_x_additional_px: float = 0.0
@export var coin_spawn_follow_player: bool = false
@export var coin_spawn_player_offset_min_px: float = 150.0
@export var coin_spawn_player_offset_max_px: float = 450.0
@export var coin_min_clearance_px: float = 10.0
@export var coin_infinite_spawn_enabled: bool = true
@export var coin_stack_enabled: bool = true
@export var coin_stack_prob: float = 0.5
@export var coin_stack_max_per_column: int = 1
@export var coin_stack_vertical_offset_px: float = 20.0
@export var coin_stack_horizontal_jitter_px: float = 0.0
@export var coin_stack_use_tile_height: bool = false
@export var coin_stack_min_separation_px: float = 16.0
@export var coin_min_h_spacing_px: float = 24.0
@export var coin_min_v_spacing_px: float = 24.0
@export var coin_base_tint: Color = Color(1, 0.3297266, 0.5161776, 1)
@export var coin_stack_tint: Color = Color(0.27943614, 0.49578863, 1, 1)
@export var coin_tint_enabled: bool = true
@export var coin_allow_over_empty: bool = false

@export var enemy_spawn_enabled: bool = true
@export var enemy_spawn_margin_tiles: int = 2
@export var enemy_groups_min: int = 1
@export var enemy_groups_max: int = 2
@export var enemies_per_group_min: int = 1
@export var enemies_per_group_max: int = 2
@export var enemy_spacing_tiles_min: int = 8
@export var enemy_spacing_tiles_max: int = 16
@export var enemy_vertical_offset_px: float = 12.0
@export var enemy_scale: float = 0.6
@export var enemy_min_clearance_px: float = 6.0
@export var enemy_coin_min_h_spacing_px: float = 32.0
@export var enemy_coin_min_v_spacing_px: float = 32.0
@export var enemy_coin_min_dist_px: float = 56.0
@export var enemy_edge_clear_tiles: int = 5
@export var enemy_player_min_dx_px: float = 140.0
@export var enemy_slope_max_delta_tiles: int = 1
@export var enemy_allow_over_empty: bool = false
@export var enemy_min_platform_tiles: int = 9
@export var enemy_min_right_run_tiles: int = 5
@export var enemy_min_left_run_tiles: int = 5
@export var coin_max_children: int = 200
@export var enemy_max_children: int = 60

var _noise := FastNoiseLite.new()
var _rng := RandomNumberGenerator.new()
var _generate_now: bool = false
var _coin_scene := preload("res://scenes/Coin.tscn")
var _next_spawn_x: int = -1
var _last_tint_enabled: bool = true
var _last_base_tint: Color = Color(1, 1, 1, 1)
var _last_stack_tint: Color = Color(1, 1, 1, 1)
var _enemy_scene: PackedScene = null
var _next_enemy_spawn_x: int = -1
@export var spawn_update_interval_sec: float = 0.25
var _spawn_t_accum_coins: float = 0.0
var _spawn_t_accum_enemies: float = 0.0


func _ready():
    _configure_noise()
    if _enemy_scene == null:
        var r = load("res://scenes/EnemyCone.tscn")
        if r is PackedScene:
            _enemy_scene = r
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
    _spawn_enemy_groups_append_right(container)
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
            if enemy_edge_clear_tiles > 0:
                var left_ok := true
                var right_ok := true
                var lx_start := mx - enemy_edge_clear_tiles
                var rx_end := mx + enemy_edge_clear_tiles
                var ix := lx_start
                while ix < mx and left_ok:
                    if ix >= min_x and _column_top_y(ix) == -1:
                        left_ok = false
                        break
                    ix += 1
                ix = mx + 1
                while ix <= rx_end and right_ok:
                    if ix < max_x and _column_top_y(ix) == -1:
                        right_ok = false
                        break
                    ix += 1
                if not (left_ok and right_ok):
                    continue
            if enemy_min_platform_tiles > 0:
                var run_len := _platform_run_len_tiles(mx, min_x, max_x)
                if run_len < enemy_min_platform_tiles:
                    continue
            if enemy_min_right_run_tiles > 0:
                var rr := _platform_run_len_right(mx, max_x)
                if rr < enemy_min_right_run_tiles:
                    continue
            if enemy_min_left_run_tiles > 0:
                var rl := _platform_run_len_left(mx, min_x)
                if rl < enemy_min_left_run_tiles:
                    continue
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
            if coin_stack_vertical_offset_px != 0.0:
                coin_world.y += coin_stack_vertical_offset_px
            var base_sep: float = coin_stack_min_separation_px
            if coin_stack_use_tile_height:
                base_sep = max(world_cell_h, coin_stack_min_separation_px)
            var vstep: float = base_sep + coin_min_clearance_px + coin_osc_amplitude * 2.0
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
                if not too_close:
                    var enemies_cont: Node2D = null
                    var parent_node := get_parent()
                    if parent_node != null:
                        enemies_cont = parent_node.get_node_or_null("EnemiesA") if name == "TileMapLayer" else parent_node.get_node_or_null("EnemiesB")
                    if enemies_cont != null:
                        for e in enemies_cont.get_children():
                            if e is Node2D:
                                var ew: Vector2 = enemies_cont.to_global((e as Node2D).position)
                                var dxw: float = abs(ew.x - stacked_world.x)
                                var dyw: float = abs(ew.y - stacked_world.y)
                                if (enemy_coin_min_h_spacing_px > 0.0 and enemy_coin_min_v_spacing_px > 0.0 and dxw < enemy_coin_min_h_spacing_px and dyw < enemy_coin_min_v_spacing_px) or (enemy_coin_min_dist_px > 0.0 and sqrt(dxw * dxw + dyw * dyw) < enemy_coin_min_dist_px):
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
                var gm := get_tree().get_current_scene()
                if gm != null and gm.has_method("on_coin_collected"):
                    ncoin.collected.connect(gm.on_coin_collected)
                container.add_child(ncoin)
                occupied[key] = true
        var group_gap: int = _rng.randi_range(max(1, coin_group_spacing_tiles_min), max(coin_group_spacing_tiles_min, coin_group_spacing_tiles_max))
        x = min(max_x, x + max(1, count) * spacing_tiles + group_gap)

func _spawn_enemy_groups_in_view_right(container: Node) -> void:
    if tile_set == null or container == null or not enemy_spawn_enabled:
        return
    if _enemy_scene == null:
        return
    if container is Node2D:
        (container as Node2D).position.x = position.x
    for c in container.get_children():
        c.queue_free()
    var occupied: Dictionary = {}
    for e in container.get_children():
        if e is Node2D:
            var eg: Vector2 = (container as Node2D).to_global((e as Node2D).position)
            var el: Vector2 = to_local(eg)
            var em: Vector2i = local_to_map(el)
            var emx: int = em.x - origin.x
            occupied[str(emx)] = true
    var parent_occ: Dictionary = {}
    var gp := get_parent()
    if gp != null:
        if gp.has_meta("enemy_occ"):
            parent_occ = gp.get_meta("enemy_occ")
    var coins_cont: Node2D = null
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
            if enemy_edge_clear_tiles > 0:
                var left_ok2 := true
                var right_ok2 := true
                var lx_start2 := mx - enemy_edge_clear_tiles
                var rx_end2 := mx + enemy_edge_clear_tiles
                var jx := lx_start2
                while jx < mx and left_ok2:
                    if jx >= min_x and _column_top_y(jx) == -1:
                        left_ok2 = false
                        break
                    jx += 1
                jx = mx + 1
                while jx <= rx_end2 and right_ok2:
                    if jx < max_x and _column_top_y(jx) == -1:
                        right_ok2 = false
                        break
                    jx += 1
                if not (left_ok2 and right_ok2):
                    continue
            if enemy_min_platform_tiles > 0:
                var run_len2 := _platform_run_len_tiles(mx, min_x, max_x)
                if run_len2 < enemy_min_platform_tiles:
                    continue
            if enemy_min_right_run_tiles > 0:
                var rr2 := _platform_run_len_right(mx, max_x)
                if rr2 < enemy_min_right_run_tiles:
                    continue
            if enemy_min_left_run_tiles > 0:
                var rl2 := _platform_run_len_left(mx, min_x)
                if rl2 < enemy_min_left_run_tiles:
                    continue
            var lc: Vector2
            var wc: Vector2
            var required_margins_len: int = max(enemy_min_left_run_tiles, enemy_edge_clear_tiles) + max(enemy_min_right_run_tiles, enemy_edge_clear_tiles) + 1
            var needed_min: int = max(enemy_min_platform_tiles, max(min_platform_len, required_margins_len))
            if enemy_min_platform_tiles > 0 or min_platform_len > 0:
                var run_len_chk: int = _platform_run_len_tiles(mx, min_x, max_x)
                if run_len_chk < needed_min:
                    continue
                var bounds: Vector2i = _platform_bounds(mx, min_x, max_x)
                var req_left: int = max(enemy_min_left_run_tiles, enemy_edge_clear_tiles)
                var req_right: int = max(enemy_min_right_run_tiles, enemy_edge_clear_tiles)
                var safe_start: int = bounds.x + req_left
                var safe_end: int = bounds.y - req_right
                if safe_end < safe_start:
                    continue
                var center_idx: int = int(round((safe_start + safe_end) * 0.5))
                var center_top: int = _column_top_y(center_idx)
                if center_top == -1 and not enemy_allow_over_empty:
                    continue
                var parent_node: Node = get_parent()
                if parent_node != null:
                    coins_cont = parent_node.get_node_or_null("CoinsA") if name == "TileMapLayer" else parent_node.get_node_or_null("CoinsB")
                if coins_cont != null:
                    var has_coin_in_safe: bool = false
                    for c in coins_cont.get_children():
                        if c is Node2D:
                            var cg: Vector2 = (c as Node2D).global_position
                            var cl: Vector2 = to_local(cg)
                            var cm: Vector2i = local_to_map(cl)
                            var cix: int = cm.x - origin.x
                            if cix >= safe_start and cix <= safe_end:
                                has_coin_in_safe = true
                                break
                    if has_coin_in_safe:
                        continue
                var use_y: int = center_top if center_top != -1 else int(clamp(ground_y, 0, height - 1))
                lc = map_to_local(Vector2i(origin.x + center_idx, origin.y + use_y))
                wc = to_global(lc)
            else:
                if top_y == -1:
                    if not enemy_allow_over_empty:
                        continue
                    var pseudo_y: int = int(clamp(ground_y, 0, height - 1))
                    lc = map_to_local(Vector2i(origin.x + mx, origin.y + pseudo_y))
                    wc = to_global(lc)
                else:
                    lc = map_to_local(Vector2i(origin.x + mx, origin.y + top_y))
                    wc = to_global(lc)
            if enemy_slope_max_delta_tiles >= 0:
                var lt := _column_top_y(mx - 1)
                var rt := _column_top_y(mx + 1)
                if lt != -1 and rt != -1:
                    if abs(lt - rt) > enemy_slope_max_delta_tiles:
                        continue
            var world_cell_h: float = float(cell.y) * scale.y
            var top_surface_y: float = wc.y - world_cell_h * 0.5
            var enemy_world: Vector2 = Vector2(wc.x, top_surface_y)
            var nenemy: Node2D = _enemy_scene.instantiate() as Node2D
            if enemy_scale > 0.0:
                nenemy.scale = Vector2(enemy_scale, enemy_scale)
            var lp: Vector2 = (container as Node2D).to_local(enemy_world)
            var p := get_parent()
            if p != null:
                coins_cont = p.get_node_or_null("CoinsA") if name == "TileMapLayer" else p.get_node_or_null("CoinsB")
                var pl := p.get_node_or_null("Player")
                if pl != null and pl is Node2D:
                    var dxp: float = abs((pl as Node2D).global_position.x - enemy_world.x)
                    if dxp < enemy_player_min_dx_px:
                        continue
            if coins_cont != null:
                var too_close_to_coin := false
                for c in coins_cont.get_children():
                    if c is Node2D:
                        var cg: Vector2 = coins_cont.to_global((c as Node2D).position)
                        var dxw: float = abs(cg.x - enemy_world.x)
                        var dyw: float = abs(cg.y - enemy_world.y)
                        if enemy_coin_min_h_spacing_px > 0.0 and enemy_coin_min_v_spacing_px > 0.0:
                            if dxw < enemy_coin_min_h_spacing_px and dyw < enemy_coin_min_v_spacing_px:
                                too_close_to_coin = true
                        if not too_close_to_coin and enemy_coin_min_dist_px > 0.0:
                            var dist: float = sqrt(dxw * dxw + dyw * dyw)
                            if dist < enemy_coin_min_dist_px:
                                too_close_to_coin = true
                        if too_close_to_coin:
                            break
                if too_close_to_coin:
                    continue
            var cs := nenemy.get_node_or_null("Hitbox/CollisionShape2D")
            if cs != null and cs is CollisionShape2D and cs.shape is RectangleShape2D:
                var rs := cs.shape as RectangleShape2D
                var hh: float = rs.size.y * 0.5
                var hoff: float = cs.position.y
                lp.y -= (enemy_vertical_offset_px + enemy_min_clearance_px + hoff + hh)
            var world_col_w: int = int(round(enemy_world.x / (float(cell.x) * scale.x)))
            if occupied.has(str(mx)):
                continue
            if parent_occ.has(str(world_col_w)):
                continue
            nenemy.position = lp
            nenemy.z_index = 95
            container.add_child(nenemy)
            occupied[str(mx)] = true
            parent_occ[str(world_col_w)] = true
            if gp != null:
                gp.set_meta("enemy_occ", parent_occ)
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
    if container is Node2D:
        (container as Node2D).position.x = position.x
    if coin_max_children > 0 and container.get_child_count() >= coin_max_children:
        return
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
            if coin_stack_vertical_offset_px != 0.0:
                coin_world.y += coin_stack_vertical_offset_px
            var base_sep2: float = coin_stack_min_separation_px
            if coin_stack_use_tile_height:
                base_sep2 = max(world_cell_h, coin_stack_min_separation_px)
            var vstep2: float = base_sep2 + coin_min_clearance_px + coin_osc_amplitude * 2.0
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
                if not too_close2:
                    var enemies_cont2: Node2D = null
                    var parent_node2 := get_parent()
                    if parent_node2 != null:
                        enemies_cont2 = parent_node2.get_node_or_null("EnemiesA") if name == "TileMapLayer" else parent_node2.get_node_or_null("EnemiesB")
                    if enemies_cont2 != null:
                        for e2 in enemies_cont2.get_children():
                            if e2 is Node2D:
                                var ew2: Vector2 = enemies_cont2.to_global((e2 as Node2D).position)
                                var dxw2: float = abs(ew2.x - stacked_world2.x)
                                var dyw2: float = abs(ew2.y - stacked_world2.y)
                                if (enemy_coin_min_h_spacing_px > 0.0 and enemy_coin_min_v_spacing_px > 0.0 and dxw2 < enemy_coin_min_h_spacing_px and dyw2 < enemy_coin_min_v_spacing_px) or (enemy_coin_min_dist_px > 0.0 and sqrt(dxw2 * dxw2 + dyw2 * dyw2) < enemy_coin_min_dist_px):
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
                var gm2 := get_tree().get_current_scene()
                if gm2 != null and gm2.has_method("on_coin_collected"):
                    ncoin2.collected.connect(gm2.on_coin_collected)
                if coin_max_children <= 0 or container.get_child_count() < coin_max_children:
                    container.add_child(ncoin2)
                occupied2[key2] = true
        var group_gap: int = _rng.randi_range(max(1, coin_group_spacing_tiles_min), max(coin_group_spacing_tiles_min, coin_group_spacing_tiles_max))
        _next_spawn_x = min(max_x, _next_spawn_x + max(1, count) * spacing_tiles + group_gap)
        local_center = map_to_local(Vector2i(origin.x + _next_spawn_x, origin.y))
        world_center = to_global(local_center)

func _spawn_enemy_groups_append_right(container: Node) -> void:
    if not enemy_spawn_enabled or tile_set == null or container == null:
        return
    if _enemy_scene == null:
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
    if container is Node2D:
        (container as Node2D).position.x = position.x
    if enemy_max_children > 0 and container.get_child_count() >= enemy_max_children:
        return
    var occupied2: Dictionary = {}
    for e2 in container.get_children():
        if e2 is Node2D:
            var eg2: Vector2 = (container as Node2D).to_global((e2 as Node2D).position)
            var el2: Vector2 = to_local(eg2)
            var em2: Vector2i = local_to_map(el2)
            var emx2: int = em2.x - origin.x
            occupied2[str(emx2)] = true
    var parent_occ2: Dictionary = {}
    var gp2 := get_parent()
    if gp2 != null:
        if gp2.has_meta("enemy_occ"):
            parent_occ2 = gp2.get_meta("enemy_occ")
    if _next_enemy_spawn_x < 0:
        var start_world_x := right_x - float(step_px) * 2.0
        var local := to_local(Vector2(start_world_x, 0.0))
        var map := local_to_map(local)
        _next_enemy_spawn_x = clamp(map.x - origin.x, min_x, max_x - 1)
    var local_center: Vector2 = map_to_local(Vector2i(origin.x + _next_enemy_spawn_x, origin.y))
    var world_center: Vector2 = to_global(local_center)
    var coins_cont2: Node2D = null
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
            var required_margins_len2: int = max(enemy_min_left_run_tiles, enemy_edge_clear_tiles) + max(enemy_min_right_run_tiles, enemy_edge_clear_tiles) + 1
            var needed_min2: int = max(enemy_min_platform_tiles, max(min_platform_len, required_margins_len2))
            if enemy_min_platform_tiles > 0 or min_platform_len > 0:
                var run_len_chk2: int = _platform_run_len_tiles(mx, min_x, max_x)
                if run_len_chk2 < needed_min2:
                    continue
                var bounds2: Vector2i = _platform_bounds(mx, min_x, max_x)
                var req_left2: int = max(enemy_min_left_run_tiles, enemy_edge_clear_tiles)
                var req_right2: int = max(enemy_min_right_run_tiles, enemy_edge_clear_tiles)
                var safe_start2: int = bounds2.x + req_left2
                var safe_end2: int = bounds2.y - req_right2
                if safe_end2 < safe_start2:
                    continue
                var center_idx2: int = int(round((safe_start2 + safe_end2) * 0.5))
                var center_top2: int = _column_top_y(center_idx2)
                if center_top2 == -1 and not enemy_allow_over_empty:
                    continue
                var parent_node2: Node = get_parent()
                if parent_node2 != null:
                    coins_cont2 = parent_node2.get_node_or_null("CoinsA") if name == "TileMapLayer" else parent_node2.get_node_or_null("CoinsB")
                if coins_cont2 != null:
                    var has_coin_in_safe2: bool = false
                    for c2 in coins_cont2.get_children():
                        if c2 is Node2D:
                            var cg2: Vector2 = (c2 as Node2D).global_position
                            var cl2: Vector2 = to_local(cg2)
                            var cm2: Vector2i = local_to_map(cl2)
                            var cx2: int = cm2.x - origin.x
                            if cx2 >= safe_start2 and cx2 <= safe_end2:
                                has_coin_in_safe2 = true
                                break
                    if has_coin_in_safe2:
                        continue
                var use_y2: int = center_top2 if center_top2 != -1 else int(clamp(ground_y, 0, height - 1))
                lc = map_to_local(Vector2i(origin.x + center_idx2, origin.y + use_y2))
                wc = to_global(lc)
            else:
                if top_y == -1:
                    if not enemy_allow_over_empty:
                        continue
                    var pseudo_y2: int = int(clamp(ground_y, 0, height - 1))
                    lc = map_to_local(Vector2i(origin.x + mx, origin.y + pseudo_y2))
                    wc = to_global(lc)
                else:
                    lc = map_to_local(Vector2i(origin.x + mx, origin.y + top_y))
                    wc = to_global(lc)
            if enemy_slope_max_delta_tiles >= 0:
                var lt2 := _column_top_y(mx - 1)
                var rt2 := _column_top_y(mx + 1)
                if lt2 != -1 and rt2 != -1:
                    if abs(lt2 - rt2) > enemy_slope_max_delta_tiles:
                        continue
            var world_cell_h: float = float(cell.y) * scale.y
            var top_surface_y: float = wc.y - world_cell_h * 0.5
            var enemy_world: Vector2 = Vector2(wc.x, top_surface_y)
            var nenemy2: Node2D = _enemy_scene.instantiate() as Node2D
            if enemy_scale > 0.0:
                nenemy2.scale = Vector2(enemy_scale, enemy_scale)
            var lp2: Vector2 = (container as Node2D).to_local(enemy_world)
            var p2 := get_parent()
            if p2 != null:
                coins_cont2 = p2.get_node_or_null("CoinsA") if name == "TileMapLayer" else p2.get_node_or_null("CoinsB")
                var pl2 := p2.get_node_or_null("Player")
                if pl2 != null and pl2 is Node2D:
                    var dxp2: float = abs((pl2 as Node2D).global_position.x - enemy_world.x)
                    if dxp2 < enemy_player_min_dx_px:
                        continue
            if coins_cont2 != null:
                var too_close_to_coin2 := false
                for c2 in coins_cont2.get_children():
                    if c2 is Node2D:
                        var cg2: Vector2 = coins_cont2.to_global((c2 as Node2D).position)
                        var dxw2: float = abs(cg2.x - enemy_world.x)
                        var dyw2: float = abs(cg2.y - enemy_world.y)
                        if enemy_coin_min_h_spacing_px > 0.0 and enemy_coin_min_v_spacing_px > 0.0:
                            if dxw2 < enemy_coin_min_h_spacing_px and dyw2 < enemy_coin_min_v_spacing_px:
                                too_close_to_coin2 = true
                        if not too_close_to_coin2 and enemy_coin_min_dist_px > 0.0:
                            var dist2: float = sqrt(dxw2 * dxw2 + dyw2 * dyw2)
                            if dist2 < enemy_coin_min_dist_px:
                                too_close_to_coin2 = true
                        if too_close_to_coin2:
                            break
                if too_close_to_coin2:
                    continue
            var cs2 := nenemy2.get_node_or_null("Hitbox/CollisionShape2D")
            if cs2 != null and cs2 is CollisionShape2D and cs2.shape is RectangleShape2D:
                var rs2 := cs2.shape as RectangleShape2D
                var hh2: float = rs2.size.y * 0.5
                var hoff2: float = cs2.position.y
                lp2.y -= (enemy_vertical_offset_px + enemy_min_clearance_px + hoff2 + hh2)
            var world_col_w2: int = int(round(enemy_world.x / (float(cell.x) * scale.x)))
            if occupied2.has(str(mx)):
                continue
            if parent_occ2.has(str(world_col_w2)):
                continue
            nenemy2.position = lp2
            nenemy2.z_index = 95
            if enemy_max_children <= 0 or container.get_child_count() < enemy_max_children:
                container.add_child(nenemy2)
                occupied2[str(mx)] = true
                parent_occ2[str(world_col_w2)] = true
                if gp2 != null:
                    gp2.set_meta("enemy_occ", parent_occ2)
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

func _column_top_y(mx: int) -> int:
    for y in range(height - 1, -1, -1):
        var mp := Vector2i(origin.x + mx, origin.y + y)
        var sid := get_cell_source_id(mp)
        if sid != -1:
            var above_sid := -1
            if y - 1 >= 0:
                above_sid = get_cell_source_id(Vector2i(origin.x + mx, origin.y + y - 1))
            if above_sid == -1:
                return y
    return -1

func _platform_run_len_tiles(mx: int, min_x: int, max_x: int) -> int:
    var center_top := _column_top_y(mx)
    if center_top == -1:
        return 0
    var count := 1
    var i := mx - 1
    while i >= min_x:
        if _column_top_y(i) == -1:
            break
        count += 1
        i -= 1
    i = mx + 1
    while i < max_x:
        if _column_top_y(i) == -1:
            break
        count += 1
        i += 1
    return count

func _platform_center_tile(mx: int, min_x: int, max_x: int) -> int:
    var left := mx
    var right := mx
    var i := mx - 1
    while i >= min_x:
        if _column_top_y(i) == -1:
            break
        left = i
        i -= 1
    i = mx + 1
    while i < max_x:
        if _column_top_y(i) == -1:
            break
        right = i
        i += 1
    return int(round((left + right) * 0.5))

func _platform_bounds(mx: int, min_x: int, max_x: int) -> Vector2i:
    var left := mx
    var right := mx
    var i := mx - 1
    while i >= min_x:
        if _column_top_y(i) == -1:
            break
        left = i
        i -= 1
    i = mx + 1
    while i < max_x:
        if _column_top_y(i) == -1:
            break
        right = i
        i += 1
    return Vector2i(left, right)

func get_platform_run_len_at_world_x(world_x: float) -> int:
    if tile_set == null:
        return 0
    var local := to_local(Vector2(world_x, 0.0))
    var map := local_to_map(local)
    var mx: int = clamp(map.x - origin.x, 0, max(0, width - 1))
    return _platform_run_len_tiles(mx, 0, width)

func get_platform_runs_lr_at_world_x(world_x: float) -> Vector2i:
    if tile_set == null:
        return Vector2i(0, 0)
    var local := to_local(Vector2(world_x, 0.0))
    var map := local_to_map(local)
    var mx: int = clamp(map.x - origin.x, 0, max(0, width - 1))
    var b := _platform_bounds(mx, 0, width)
    if b.x == mx and b.y == mx and _column_top_y(mx) == -1:
        return Vector2i(0, 0)
    var left_run: int = mx - b.x
    var right_run: int = b.y - mx
    return Vector2i(left_run, right_run)

func _platform_run_len_right(mx: int, max_x: int) -> int:
    var i := mx + 1
    var count := 0
    while i < max_x:
        if _column_top_y(i) == -1:
            break
        count += 1
        i += 1
    return count

func _platform_run_len_left(mx: int, min_x: int) -> int:
    var i := mx - 1
    var count := 0
    while i >= min_x:
        if _column_top_y(i) == -1:
            break
        count += 1
        i -= 1
    return count
