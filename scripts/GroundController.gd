extends Node2D

signal generation_progress(pct: float)

@onready var tile_layer: TileMapLayer = $TileMapLayer

var _title_mode: bool = true
@export var movement_enabled: bool = false
@export var scroll_speed: float = 150.0
@export var speed_multiplier: float = 1.0
@export var acceleration: float = 0.0
@export var use_acceleration: bool = false
@export var max_scroll_speed: float = 300.0
@export var min_scroll_speed: float = 0.0

func set_title_mode(enable: bool) -> void:
	_title_mode = enable

func generate_random() -> void:
	if tile_layer == null:
		return
	# Set generator seed to 0 for randomization per generate
	tile_layer.noise_seed = 0
	emit_signal("generation_progress", 0.0)
	if tile_layer.has_method("generate"):
		tile_layer.generate()
	emit_signal("generation_progress", 1.0)

func set_movement_enabled(enable: bool) -> void:
	movement_enabled = enable

func set_speed(s: float) -> void:
	scroll_speed = clamp(s, min_scroll_speed, max_scroll_speed)

func add_speed(ds: float) -> void:
	scroll_speed = clamp(scroll_speed + ds, min_scroll_speed, max_scroll_speed)

func set_multiplier(m: float) -> void:
	speed_multiplier = m

func set_acceleration(a: float) -> void:
	acceleration = a

func set_acceleration_enabled(enable: bool) -> void:
	use_acceleration = enable

func set_speed_limits(min_s: float, max_s: float) -> void:
	min_scroll_speed = min_s
	max_scroll_speed = max_s
	scroll_speed = clamp(scroll_speed, min_scroll_speed, max_scroll_speed)

func get_speed() -> float:
	return clamp(scroll_speed, min_scroll_speed, max_scroll_speed) * speed_multiplier

func _process(delta: float) -> void:
	if movement_enabled and tile_layer != null:
		if use_acceleration:
			scroll_speed = clamp(scroll_speed + acceleration * delta, min_scroll_speed, max_scroll_speed)
		var s: float = clamp(scroll_speed, min_scroll_speed, max_scroll_speed) * speed_multiplier
		tile_layer.position.x -= s * delta

func is_solid_at_world_pos(pos: Vector2) -> bool:
	if tile_layer == null:
		return false
	var local := tile_layer.to_local(pos)
	var map := tile_layer.local_to_map(local)
	var sid := tile_layer.get_cell_source_id(map)
	return sid != -1

func is_gap_below_world_pos(pos: Vector2, cells: int = 2) -> bool:
	if tile_layer == null:
		return false
	var cell := tile_layer.tile_set.tile_size if tile_layer.tile_set != null else Vector2i(128, 128)
	var ray_len := float(cells) * float(cell.y) * tile_layer.scale.y
	var space := get_world_2d().direct_space_state
	var res := space.intersect_ray(PhysicsRayQueryParameters2D.create(pos, pos + Vector2(0, ray_len), 1, []))
	return res.is_empty()
