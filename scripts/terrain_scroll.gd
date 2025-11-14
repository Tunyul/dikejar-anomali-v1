extends Node2D

@export var speed: float = 300.0
@export var speed_tiles_per_s: float = 0.0
@export var peer: NodePath
@export var is_primary: bool = true
@export var join_overlap_px: int = 1

var _width_px: int = 0
var _peer_node: Node2D
var _snap_units: float = 1.0
var _tile_px: int = 0
var _ground: TerrainGenerator
var _regen_block: bool = false


func _ready() -> void:
	_peer_node = get_node_or_null(peer)
	_ground = $Ground
	_tile_px = int(float(_ground.tile_size) * _ground.tile_scale)
	if _tile_px <= 0 and _ground.tile_set:
		_tile_px = int(float(_ground.tile_set.tile_size.x) * _ground.tile_scale)
	_width_px = int(_ground.world_width_tiles * _tile_px)
	_snap_units = 1.0 / max(_ground.tile_scale, 0.0001)
	if is_primary and _peer_node:
		_peer_node.position.x = position.x + float(_width_px - join_overlap_px)

func _process(delta: float) -> void:
	var speed_px := (speed_tiles_per_s * float(_tile_px) if speed_tiles_per_s > 0.0 else speed)
	var new_x_a := position.x - speed_px * delta
	position.x = floor(new_x_a / _snap_units) * _snap_units
	if _ground and _ground.tile_set:
		_tile_px = int(float(_ground.tile_set.tile_size.x) * _ground.tile_scale)
		_width_px = int(_ground.world_width_tiles * _tile_px)
	if Input.is_key_pressed(KEY_R):
		if not _regen_block and _ground:
			_ground.regenerate = true
			_regen_block = true
	else:
		_regen_block = false
	if _peer_node:
		var new_x_b := _peer_node.position.x - speed_px * delta
		_peer_node.position.x = floor(new_x_b / _snap_units) * _snap_units
		var seg := float(_width_px - join_overlap_px)
		if position.x <= -seg:
			position.x = floor((_peer_node.position.x + seg) / _snap_units) * _snap_units
		elif _peer_node.position.x <= -seg:
			_peer_node.position.x = floor((position.x + seg) / _snap_units) * _snap_units
