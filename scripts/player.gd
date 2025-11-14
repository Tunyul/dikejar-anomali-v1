extends Node2D

@export var ground_path: NodePath
@export var y_offset_px: float = 64.0
@export var gravity_px: float = 2000.0
@export var jump_impulse_px: float = 600.0
@export var keep_x_px: float = 320.0

var _ground: TerrainGenerator
var _tile_px: float = 0.0
var _vel_y: float = 0.0
var _grounded: bool = false
var _request_jump: bool = false
var _anim: AnimatedSprite2D
var _visual_h_px: float = 0.0
var _last_target_y: float = 0.0
var _start_snapped: bool = false

func _ready() -> void:
	if ground_path:
		_ground = get_node_or_null(ground_path)
	else:
		_ground = get_parent().get_node_or_null("Ground")
	if _ground:
		_tile_px = float(_ground.tile_size) * _ground.tile_scale
		if _tile_px <= 0.0 and _ground.tile_set:
			_tile_px = float(_ground.tile_set.tile_size.x) * _ground.tile_scale
	_anim = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if _anim and _anim.sprite_frames:
		var anim_name: StringName = _anim.animation
		var tex: Texture2D = _anim.sprite_frames.get_frame_texture(anim_name, 0)
		if tex:
			_visual_h_px = float(tex.get_size().y) * _anim.scale.y
			y_offset_px = _visual_h_px * 0.5
		_anim.play(anim_name)

func _process(_delta: float) -> void:
	if not _ground:
		return
	if _tile_px <= 0.0:
		_tile_px = float(_ground.tile_size) * _ground.tile_scale
		if _tile_px <= 0.0 and _ground.tile_set:
			_tile_px = float(_ground.tile_set.tile_size.x) * _ground.tile_scale
	var local_to_ground: Vector2 = _ground.to_local(global_position)
	var tile_x := int(floor(local_to_ground.x / _tile_px))
	tile_x = clamp(tile_x, 0, _ground.world_width_tiles - 1)
	if _ground.surface_y_by_x.size() == 0:
		return
	var tile_y := _ground.surface_y_by_x[tile_x]
	if tile_y < 0:
		var found: bool = false
		for r in [0, 1, 2, 3]:
			var tx1: int = clamp(tile_x - r, 0, _ground.world_width_tiles - 1)
			var ty1: int = _ground.surface_y_by_x[tx1]
			if ty1 >= 0:
				tile_y = ty1
				found = true
				break
			var tx2: int = clamp(tile_x + r, 0, _ground.world_width_tiles - 1)
			var ty2: int = _ground.surface_y_by_x[tx2]
			if ty2 >= 0:
				tile_y = ty2
				found = true
				break
		if not found:
			if _last_target_y != 0.0:
				var target_hold := _last_target_y
				_vel_y += gravity_px * _delta
				position.y += _vel_y * _delta
				if position.y >= target_hold:
					position.y = target_hold
					_vel_y = 0.0
					_grounded = true
				else:
					_grounded = false
				global_position.x = keep_x_px
				return
	var target_y := _ground.position.y + float(tile_y) * _tile_px - y_offset_px
	_last_target_y = target_y

	if not _start_snapped:
		position.y = target_y
		_vel_y = 0.0
		_grounded = true
		_start_snapped = true

	if Input.is_action_just_pressed("ui_accept") or _request_jump:
		if _grounded:
			_vel_y = -jump_impulse_px
			_request_jump = false

	_vel_y += gravity_px * _delta
	position.y += _vel_y * _delta
	if position.y >= target_y:
		position.y = target_y
		_vel_y = 0.0
		_grounded = true
	else:
		_grounded = false

	global_position.x = keep_x_px

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_request_jump = true
	elif event is InputEventScreenTouch and event.pressed:
		_request_jump = true
	elif event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		_request_jump = true
