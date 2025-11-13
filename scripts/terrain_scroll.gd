extends Node2D

@export var speed: float = 300.0
@export var peer: NodePath
@export var is_primary: bool = true

var _width_px: float = 0.0
var _peer_node: Node2D

func _ready() -> void:
	_peer_node = get_node_or_null(peer)
	var ground: TerrainGenerator = $Ground
	var tile_px: float = float(ground.tile_size) * ground.tile_scale
	_width_px = ground.world_width_tiles * tile_px
	if is_primary and _peer_node:
		_peer_node.position.x = position.x + _width_px

func _process(delta: float) -> void:
	position.x -= speed * delta
	if _peer_node and position.x <= -_width_px:
		position.x = _peer_node.position.x + _width_px
