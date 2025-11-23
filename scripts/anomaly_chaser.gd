extends CharacterBody2D

@export var offset_x: float = 24.0
@export var follow_speed_y: float = 400.0
@export var entry_duration_sec: float = 0.8
@export var entry_offset_extra: float = -64.0
@export var hover_height_px: float = 20.0
@export var collision_size: Vector2 = Vector2(64, 64)

var _player: Node2D
var _camera: Camera2D
var _entry_timer: float = -1.0
@onready var sprite: Sprite2D = $Sprite2D
@onready var collider: CollisionShape2D = $CollisionShape2D
@onready var ground_ray: RayCast2D = $GroundRay

func _ready() -> void:
	var main := get_tree().get_root().get_node_or_null("Main")
	if main:
		_player = main.get_node_or_null("Player")
		_camera = main.get_node_or_null("Camera2D")
	collision_layer = 4
	collision_mask = 1
	if collider:
		var rect := RectangleShape2D.new()
		rect.size = collision_size
		collider.shape = rect
	if ground_ray:
		ground_ray.enabled = true
		ground_ray.collision_mask = 1
		ground_ray.target_position = Vector2(0, 200)
	if _player:
		global_position.y = _player.global_position.y

func _process(delta: float) -> void:
	if _camera == null:
		return
	var vp := get_viewport().get_visible_rect().size
	var left_world := _camera.position.x - vp.x * 0.5
	var extra := 0.0
	if _entry_timer >= 0.0:
		var denom: float = entry_duration_sec
		if denom < 0.0001:
			denom = 0.0001
		var p: float = clamp(_entry_timer / denom, 0.0, 1.0)
		extra = lerp(entry_offset_extra, 0.0, p)
		_entry_timer += delta
	global_position.x = left_world + offset_x + extra
	if _player != null:
		var ty := _player.global_position.y
		var gy := ty
		if ground_ray and ground_ray.is_enabled():
			ground_ray.global_position = Vector2(global_position.x, global_position.y)
			if ground_ray.is_colliding():
				var cp := ground_ray.get_collision_point()
				gy = min(ty, cp.y - hover_height_px)
		var dy := gy - global_position.y
		var ms := follow_speed_y * delta
		if abs(dy) <= ms:
			global_position.y = gy
		else:
			global_position.y += sign(dy) * ms

func start_appear() -> void:
	_entry_timer = 0.0
	if _player != null:
		global_position.y = _player.global_position.y
	var vp := get_viewport().get_visible_rect().size
	var left_world := 0.0
	if _camera != null:
		left_world = _camera.position.x - vp.x * 0.5
	global_position.x = left_world + offset_x + entry_offset_extra
