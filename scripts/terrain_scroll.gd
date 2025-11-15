extends Node2D

@export var speed: float = 300.0
@export var speed_tiles_per_s: float = 0.0
@export var use_smooth_movement: bool = true
@export var peer: NodePath
@export var is_primary: bool = true
@export var join_overlap_px: int = 1

var _width_px: int = 0
var _peer_node: Node2D
var _snap_units: float = 1.0
var _tile_px: int = 0
var _ground: TerrainGenerator
var _regen_block: bool = false
var movement_enabled: bool = false
var is_active: bool = false

func _ready() -> void:
	# Start with movement enabled for proper scrolling
	movement_enabled = true
	
	_peer_node = get_node_or_null(peer)
	_ground = $Ground
	
	if _ground:
		_tile_px = int(float(_ground.tile_size) * _ground.tile_scale)
		if _tile_px <= 0 and _ground.tile_set:
			_tile_px = int(float(_ground.tile_set.tile_size.x) * _ground.tile_scale)
		_width_px = int(_ground.world_width_tiles * _tile_px)
		_snap_units = 1.0 / max(_ground.tile_scale, 0.0001)
	
	if is_primary and _peer_node:
		_peer_node.position.x = position.x + float(_width_px - join_overlap_px)

func _physics_process(delta: float) -> void:
	if not movement_enabled:
		return
		
	var speed_px := (speed_tiles_per_s * float(_tile_px) if speed_tiles_per_s > 0.0 else speed)
	var new_x_a := position.x - speed_px * delta
	if use_smooth_movement:
		position.x = new_x_a  # Smooth movement without snapping
	else:
		position.x = floor(new_x_a / _snap_units) * _snap_units  # Legacy snapping behavior
	
	# Update ground reference if available
	if _ground and _ground.tile_set:
		_tile_px = int(float(_ground.tile_set.tile_size.x) * _ground.tile_scale)
		_width_px = int(_ground.world_width_tiles * _tile_px)
	
	# Handle peer node movement
	if _peer_node:
		var new_x_b := _peer_node.position.x - speed_px * delta
		if use_smooth_movement:
			_peer_node.position.x = new_x_b  # Smooth movement without snapping
		else:
			_peer_node.position.x = floor(new_x_b / _snap_units) * _snap_units  # Legacy snapping behavior
		var seg := float(_width_px - join_overlap_px)
		if position.x <= -seg:
			if use_smooth_movement:
				position.x = _peer_node.position.x + seg  # Smooth wrapping
			else:
				position.x = floor((_peer_node.position.x + seg) / _snap_units) * _snap_units  # Legacy snapping
		elif _peer_node.position.x <= -seg:
			if use_smooth_movement:
				_peer_node.position.x = position.x + seg  # Smooth wrapping
			else:
				_peer_node.position.x = floor((position.x + seg) / _snap_units) * _snap_units  # Legacy snapping

func set_movement_enabled(enabled: bool) -> void:
	movement_enabled = enabled

func set_speed(new_speed: float) -> void:
	speed = new_speed
	speed_tiles_per_s = 0.0

func reset_terrain() -> void:
	# Reset position to starting position
	if is_primary:
		position.x = 0.0
		if _peer_node:
			_peer_node.position.x = float(_width_px - join_overlap_px)
	else:
		if _peer_node:
			position.x = float(_peer_node.position.x + _width_px - join_overlap_px)
	
	# Reset ground reference
	if _ground:
		_tile_px = int(float(_ground.tile_size) * _ground.tile_scale)
		if _tile_px <= 0 and _ground.tile_set:
			_tile_px = int(float(_ground.tile_set.tile_size.x) * _ground.tile_scale)
		_width_px = int(_ground.world_width_tiles * _tile_px)
