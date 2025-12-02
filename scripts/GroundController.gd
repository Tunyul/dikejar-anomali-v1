extends Node2D

signal generation_progress(pct: float)

@onready var tile_layer: TileMapLayer = $TileMapLayer
@onready var tile_layer_b: TileMapLayer = $TileMapLayerB


var _title_mode: bool = true
@export var movement_enabled: bool = false
@export var scroll_speed: float = 150.0
@export var speed_multiplier: float = 1.0
@export var acceleration: float = 0.0
@export var use_acceleration: bool = false
@export var max_scroll_speed: float = 300.0
@export var min_scroll_speed: float = 0.0
@export var wrap_infinite: bool = true
@export var regenerate_on_wrap: bool = false
@export var smooth_speed: bool = true
@export var speed_ramp_per_sec: float = 60.0
@export var start_with_b: bool = false
@export var debug_tint_enabled: bool = false
@export var debug_color_a: Color = Color(0.8, 1.0, 0.8, 1.0)
@export var debug_color_b: Color = Color(1.0, 0.8, 0.8, 1.0)

var _target_scroll_speed: float = 150.0
var _b_ready: bool = false
var _a_flat_removed: bool = false
var _rng := RandomNumberGenerator.new()

func set_title_mode(enable: bool) -> void:
	_title_mode = enable
	_apply_debug_tint()
	var p := get_parent()
	if enable and p != null:
		var ca := _find_container_by_prefix(p, "CoinsA")
		var cb := _find_container_by_prefix(p, "CoinsB")
		var ea := _find_container_by_prefix(p, "EnemiesA")
		var eb := _find_container_by_prefix(p, "EnemiesB")
		if ca:
			for c in ca.get_children():
				c.queue_free()
		if cb:
			for c in cb.get_children():
				c.queue_free()
		if ea:
			for e in ea.get_children():
				e.queue_free()
		if eb:
			for e2 in eb.get_children():
				e2.queue_free()
		if tile_layer != null and tile_layer.has_method("reset_coin_spawn_state"):
			tile_layer.reset_coin_spawn_state()
		if tile_layer_b != null and tile_layer_b.has_method("reset_coin_spawn_state"):
			tile_layer_b.reset_coin_spawn_state()
		if tile_layer != null and tile_layer.has_method("reset_enemy_spawn_state"):
			tile_layer.reset_enemy_spawn_state()
		if tile_layer_b != null and tile_layer_b.has_method("reset_enemy_spawn_state"):
			tile_layer_b.reset_enemy_spawn_state()
		if tile_layer != null:
			tile_layer.set("coin_infinite_spawn_enabled", false)
			tile_layer.set("enemy_spawn_enabled", false)
			tile_layer.set("random_ascend_enabled", false)
			tile_layer.set("step_flat_enabled", false)
			tile_layer.set("min_gap_len", 0)
			tile_layer.set("max_gap_len", 0)
			var w := int(tile_layer.get("width")) if tile_layer.has_method("get") else 128
			tile_layer.set("flat_start_enabled", true)
			tile_layer.set("flat_start_len", max(1, w))
		if tile_layer_b != null:
			tile_layer_b.set("coin_infinite_spawn_enabled", false)
			tile_layer_b.set("enemy_spawn_enabled", false)
			tile_layer_b.set("random_ascend_enabled", false)
			tile_layer_b.set("step_flat_enabled", false)
			tile_layer_b.set("min_gap_len", 0)
			tile_layer_b.set("max_gap_len", 0)
			var wb := int(tile_layer_b.get("width")) if tile_layer_b.has_method("get") else 128
			tile_layer_b.set("flat_start_enabled", true)
			tile_layer_b.set("flat_start_len", max(1, wb))

func generate_random() -> void:
	if tile_layer == null:
		return
	emit_signal("generation_progress", 0.0)
	if _title_mode:
		tile_layer.set("random_ascend_enabled", false)
		tile_layer.set("step_flat_enabled", false)
		tile_layer.set("min_gap_len", 0)
		tile_layer.set("max_gap_len", 0)
		tile_layer.set("coin_infinite_spawn_enabled", false)
		tile_layer.set("enemy_spawn_enabled", false)
		tile_layer.flat_start_enabled = true
		var w2 := int(tile_layer.get("width")) if tile_layer.has_method("get") else 128
		tile_layer.set("flat_start_len", max(1, w2))
		tile_layer.noise_seed = 0
		if tile_layer.has_method("generate"):
			tile_layer.generate()
		if tile_layer_b != null:
			if tile_layer_b.has_method("clear"):
				tile_layer_b.clear()
			var seg := _segment_width_px()
			if seg > 0.0:
				tile_layer_b.position.x = tile_layer.position.x + seg
			# Konfigurasi layer B agar flat dan generate segera
			tile_layer_b.set("random_ascend_enabled", false)
			tile_layer_b.set("step_flat_enabled", false)
			tile_layer_b.set("min_gap_len", 0)
			tile_layer_b.set("max_gap_len", 0)
			tile_layer_b.set("coin_infinite_spawn_enabled", false)
			tile_layer_b.set("enemy_spawn_enabled", false)
			tile_layer_b.flat_start_enabled = true
			var wb2 := int(tile_layer_b.get("width")) if tile_layer_b.has_method("get") else 128
			tile_layer_b.set("flat_start_len", max(1, wb2))
			tile_layer_b.noise_seed = 0
			if tile_layer_b.has_method("generate"):
				tile_layer_b.generate()
			tile_layer_b.flat_start_enabled = false
			_b_ready = true
	else:
		tile_layer.noise_seed = 0
		if tile_layer.has_method("generate"):
			tile_layer.generate()
		if tile_layer_b != null:
			if tile_layer_b.has_method("clear"):
				tile_layer_b.clear()
			tile_layer_b.flat_start_enabled = false
			var seg2 := _segment_width_px()
			if seg2 > 0.0:
				tile_layer_b.position.x = tile_layer.position.x + seg2
			_b_ready = false
	emit_signal("generation_progress", 1.0)
	_apply_debug_tint()

func prepare_gameplay_preserve_flat_start() -> void:
	if tile_layer == null:
		return
	emit_signal("generation_progress", 0.0)
	if tile_layer_b != null:
		if tile_layer_b.has_method("clear"):
			tile_layer_b.clear()
		tile_layer_b.flat_start_enabled = false
		var seg := _segment_width_px()
		if seg > 0.0:
			tile_layer_b.position.x = tile_layer.position.x + seg
		_b_ready = false
	emit_signal("generation_progress", 1.0)
	_apply_debug_tint()

func ensure_second_segment_ready() -> void:
	if tile_layer_b == null:
		return
	if not _b_ready:
		tile_layer_b.flat_start_enabled = false
		tile_layer_b.noise_seed = 0
		if tile_layer_b.has_method("generate"):
			tile_layer_b.generate()
		_b_ready = true

func set_movement_enabled(enable: bool) -> void:
	movement_enabled = enable

func set_speed(s: float) -> void:
	_target_scroll_speed = clamp(s, min_scroll_speed, max_scroll_speed)

func add_speed(ds: float) -> void:
	_target_scroll_speed = clamp(_target_scroll_speed + ds, min_scroll_speed, max_scroll_speed)

func set_multiplier(m: float) -> void:
	speed_multiplier = m

func set_acceleration(a: float) -> void:
	acceleration = a

func set_acceleration_enabled(enable: bool) -> void:
	use_acceleration = enable

func set_speed_limits(min_s: float, max_s: float) -> void:
	min_scroll_speed = min_s
	max_scroll_speed = max_s
	_target_scroll_speed = clamp(_target_scroll_speed, min_scroll_speed, max_scroll_speed)

func get_speed() -> float:
	return clamp(scroll_speed, min_scroll_speed, max_scroll_speed) * speed_multiplier

func _physics_process(delta: float) -> void:
	if movement_enabled and tile_layer != null:
		if use_acceleration:
			_target_scroll_speed = clamp(_target_scroll_speed + acceleration * delta, min_scroll_speed, max_scroll_speed)
		if smooth_speed:
			scroll_speed = move_toward(scroll_speed, _target_scroll_speed, speed_ramp_per_sec * delta)
		else:
			scroll_speed = _target_scroll_speed
		var s: float = clamp(scroll_speed, min_scroll_speed, max_scroll_speed) * speed_multiplier
		tile_layer.position.x -= s * delta
		if tile_layer_b != null:
			tile_layer_b.position.x -= s * delta
		if wrap_infinite:
			var seg := _segment_width_px()
			if seg > 0.0:
				if tile_layer_b != null:
					while tile_layer.position.x <= -seg:
						tile_layer.position.x = tile_layer_b.position.x + seg
						if not _a_flat_removed:
							tile_layer.flat_start_enabled = false
							tile_layer.noise_seed = 0
							if regenerate_on_wrap and tile_layer.has_method("generate"):
								tile_layer.call_deferred("generate")
							_a_flat_removed = true
						elif regenerate_on_wrap:
							tile_layer.noise_seed = 0
							if tile_layer.has_method("generate"):
								tile_layer.call_deferred("generate")
					while tile_layer_b.position.x <= -seg:
						tile_layer_b.position.x = tile_layer.position.x + seg
						if not _b_ready:
							tile_layer_b.flat_start_enabled = false
							tile_layer_b.noise_seed = 0
							if regenerate_on_wrap and tile_layer_b.has_method("generate"):
								tile_layer_b.call_deferred("generate")
							_b_ready = true
						if regenerate_on_wrap:
							tile_layer_b.noise_seed = 0
							if tile_layer_b.has_method("generate"):
								tile_layer_b.call_deferred("generate")
					while tile_layer.position.x >= seg:
						tile_layer.position.x = tile_layer_b.position.x - seg
						if not _a_flat_removed:
							tile_layer.flat_start_enabled = false
							tile_layer.noise_seed = 0
							if regenerate_on_wrap and tile_layer.has_method("generate"):
								tile_layer.call_deferred("generate")
							_a_flat_removed = true
						elif regenerate_on_wrap:
							tile_layer.noise_seed = 0
							if tile_layer.has_method("generate"):
								tile_layer.call_deferred("generate")
					while tile_layer_b.position.x >= seg:
						tile_layer_b.position.x = tile_layer.position.x - seg
						if not _b_ready:
							tile_layer_b.flat_start_enabled = false
							tile_layer_b.noise_seed = 0
							if regenerate_on_wrap and tile_layer_b.has_method("generate"):
								tile_layer_b.call_deferred("generate")
							if regenerate_on_wrap and tile_layer_b.has_method("clear_coins"):
								tile_layer_b.call_deferred("clear_coins")
							if regenerate_on_wrap and tile_layer_b.has_method("spawn_initial_coins"):
								tile_layer_b.call_deferred("spawn_initial_coins")
							if regenerate_on_wrap and tile_layer_b.has_method("clear_enemies"):
								tile_layer_b.call_deferred("clear_enemies")
							if regenerate_on_wrap and tile_layer_b.has_method("spawn_initial_enemies"):
								tile_layer_b.call_deferred("spawn_initial_enemies")
							_b_ready = true
						if regenerate_on_wrap:
							tile_layer_b.noise_seed = 0
							if tile_layer_b.has_method("generate"):
								tile_layer_b.call_deferred("generate")
							if tile_layer_b.has_method("clear_coins"):
								tile_layer_b.call_deferred("clear_coins")
							if tile_layer_b.has_method("spawn_initial_coins"):
								tile_layer_b.call_deferred("spawn_initial_coins")
							if tile_layer_b.has_method("clear_enemies"):
								tile_layer_b.call_deferred("clear_enemies")
							if tile_layer_b.has_method("spawn_initial_enemies"):
								tile_layer_b.call_deferred("spawn_initial_enemies")
				else:
					while tile_layer.position.x <= -seg:
						tile_layer.position.x = tile_layer.position.x + seg * 2.0
						if regenerate_on_wrap:
							tile_layer.noise_seed = 0
							if tile_layer.has_method("generate"):
								tile_layer.call_deferred("generate")
							if tile_layer.has_method("clear_coins"):
								tile_layer.call_deferred("clear_coins")
							if tile_layer.has_method("spawn_initial_coins"):
								tile_layer.call_deferred("spawn_initial_coins")
							if tile_layer.has_method("clear_enemies"):
								tile_layer.call_deferred("clear_enemies")
							if tile_layer.has_method("spawn_initial_enemies"):
								tile_layer.call_deferred("spawn_initial_enemies")
					while tile_layer.position.x >= seg:
						tile_layer.position.x = tile_layer.position.x - seg * 2.0
						if regenerate_on_wrap:
							tile_layer.noise_seed = 0
							if tile_layer.has_method("generate"):
								tile_layer.call_deferred("generate")
							if tile_layer.has_method("clear_coins"):
								tile_layer.call_deferred("clear_coins")
							if tile_layer.has_method("spawn_initial_coins"):
								tile_layer.call_deferred("spawn_initial_coins")
							if tile_layer.has_method("clear_enemies"):
								tile_layer.call_deferred("clear_enemies")
							if tile_layer.has_method("spawn_initial_enemies"):
								tile_layer.call_deferred("spawn_initial_enemies")

func is_solid_at_world_pos(pos: Vector2) -> bool:
	if tile_layer == null:
		return false
	var local := tile_layer.to_local(pos)
	var map := tile_layer.local_to_map(local)
	var sid := tile_layer.get_cell_source_id(map)
	if sid != -1:
		return true
	if tile_layer_b != null:
		var local_b := tile_layer_b.to_local(pos)
		var map_b := tile_layer_b.local_to_map(local_b)
		var sid_b := tile_layer_b.get_cell_source_id(map_b)
		return sid_b != -1
	return false

func is_gap_below_world_pos(pos: Vector2, cells: int = 2) -> bool:
	if tile_layer == null:
		return false
	var cell := tile_layer.tile_set.tile_size if tile_layer.tile_set != null else Vector2i(128, 128)
	var ray_len := float(cells) * float(cell.y) * tile_layer.scale.y
	var space := get_world_2d().direct_space_state
	var res := space.intersect_ray(PhysicsRayQueryParameters2D.create(pos, pos + Vector2(0, ray_len), 1, []))
	return res.is_empty()

func _ready() -> void:
	if tile_layer != null and tile_layer_b != null:
		var seg := _segment_width_px()
		if seg > 0.0:
			if start_with_b:
				tile_layer.position.x = tile_layer_b.position.x + seg
			else:
				tile_layer_b.position.x = tile_layer.position.x + seg
		tile_layer.flat_start_enabled = true
		tile_layer_b.flat_start_enabled = false
		tile_layer.noise_seed = 0
		if tile_layer.has_method("generate"):
			tile_layer.generate()
		tile_layer.flat_start_enabled = false
		_b_ready = false
		_a_flat_removed = false
		_apply_debug_tint()
	_target_scroll_speed = clamp(scroll_speed, min_scroll_speed, max_scroll_speed)
	_rng.randomize()

func _segment_width_px() -> float:
	if tile_layer == null:
		return 0.0
	var cell := tile_layer.tile_set.tile_size if tile_layer.tile_set != null else Vector2i(128, 128)
	return float(tile_layer.width) * float(cell.x) * tile_layer.scale.x

func get_active_segment_name() -> String:
	var seg := _segment_width_px()
	if seg <= 0.0:
		return "-"
	var ax := tile_layer.position.x if tile_layer != null else 1e9
	var bx := tile_layer_b.position.x if tile_layer_b != null else 1e9
	var in_a := tile_layer != null and ax <= 0.0 and (ax + seg) >= 0.0
	var in_b := tile_layer_b != null and bx <= 0.0 and (bx + seg) >= 0.0
	if in_a and in_b:
		return "A+B"
	if in_a:
		return "TileMapLayer"
	if in_b:
		return "TileMapLayerB"
	var ac := ax + seg * 0.5
	var bc := bx + seg * 0.5
	return "TileMapLayer" if ac < bc else "TileMapLayerB"

func _apply_debug_tint() -> void:
	if tile_layer != null:
		tile_layer.modulate = debug_color_a if debug_tint_enabled else Color(1, 1, 1, 1)
	if tile_layer_b != null:
		tile_layer_b.modulate = debug_color_b if debug_tint_enabled else Color(1, 1, 1, 1)

func spawn_initial_coins() -> void:
	ensure_second_segment_ready()
	# Bersihkan kontainer koin terlebih dahulu agar tidak ada sisa dari generate sebelumnya
	var p := get_parent()
	if p != null:
		var ca := _find_container_by_prefix(p, "CoinsA")
		var cb := _find_container_by_prefix(p, "CoinsB")
		var ea := _find_container_by_prefix(p, "EnemiesA")
		var eb := _find_container_by_prefix(p, "EnemiesB")
		if ca:
			for c in ca.get_children():
				c.queue_free()
		if cb:
			for c in cb.get_children():
				c.queue_free()
		if ea:
			for e in ea.get_children():
				e.queue_free()
		if eb:
			for e2 in eb.get_children():
				e2.queue_free()
	if tile_layer != null and tile_layer.has_method("spawn_initial_coins"):
		tile_layer.spawn_initial_coins()
	if tile_layer_b != null and tile_layer_b.has_method("spawn_initial_coins"):
		tile_layer_b.spawn_initial_coins()
	if tile_layer != null and tile_layer.has_method("spawn_initial_enemies"):
		tile_layer.spawn_initial_enemies()
	if tile_layer_b != null and tile_layer_b.has_method("spawn_initial_enemies"):
		tile_layer_b.spawn_initial_enemies()

func _get_active_layer() -> TileMapLayer:
	return tile_layer

func _find_container_by_prefix(p: Node, base: String) -> Node:
	if p == null:
		return null
	var n := p.get_node_or_null(base)
	if n != null:
		return n
	for c in p.get_children():
		var nm := String(c.name)
		if nm.begins_with(base):
			return c
	return null
