extends Node2D

signal generation_progress(pct: float)

@onready var tile_layer: TileMapLayer = $TileMapLayer

var _title_mode: bool = true
@export var movement_enabled: bool = false
@export var scroll_speed: float = 150.0

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
    scroll_speed = s

func _process(delta: float) -> void:
    if movement_enabled and tile_layer != null:
        tile_layer.position.x -= scroll_speed * delta

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
    var local := tile_layer.to_local(pos)
    var map := tile_layer.local_to_map(local)
    for i in range(cells):
        var check := Vector2i(map.x, map.y + i)
        var sid := tile_layer.get_cell_source_id(check)
        if sid != -1:
            return false
    return true