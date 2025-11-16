@tool
extends TileMapLayer

@export var width: int = 128
@export var height: int = 128
@export var seed: int = 12345
@export var noise_frequency: float = 0.02
@export var grass_threshold: float = 0.6
@export var dirt_threshold: float = 0.4
@export var auto_generate_on_ready: bool = true
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

var _noise := FastNoiseLite.new()
var _rng := RandomNumberGenerator.new()
var _generate_now: bool = false

func _ready():
    _configure_noise()
    if auto_generate_on_ready:
        generate()

func _configure_noise():
    _rng.randomize()
    _noise.seed = int(_rng.randi()) if seed == 0 else seed
    _noise.frequency = noise_frequency

func clear_map():
    clear()

func generate():
    if tile_set == null:
        return
    if clear_before_generate:
        clear()
    _configure_noise()
    if runner_mode:
        _generate_flat_runner()
    else:
        var has_top: bool = tile_set.has_source(grass_source_id) or (use_grass_mid and tile_set.has_source(grass_mid_source_id))
        var has_dirt := tile_set.has_source(dirt_source_id)
        for x in range(width):
            for y in range(height):
                var n := _noise.get_noise_2d(float(x), float(y))
                var v := (n + 1.0) * 0.5
                var pos: Vector2i = Vector2i(origin.x + x, origin.y + y)
                if v >= grass_threshold and has_top:
                    var use_mid: bool = use_grass_mid and tile_set.has_source(grass_mid_source_id)
                    var sid: int = grass_mid_source_id if use_mid else grass_source_id
                    var coords: Vector2i = atlas_coords_grass_mid if use_mid else atlas_coords_grass
                    var alt: int = alternative_grass_mid if use_mid else alternative_grass
                    set_cell(pos, sid, coords, alt)
                elif v >= dirt_threshold and has_dirt:
                    set_cell(pos, dirt_source_id, atlas_coords_dirt, alternative_dirt)
    if add_dirt_band:
        _draw_dirt_band()
    queue_redraw()

func _generate_flat_runner():
    var gy: int = int(clamp(ground_y, 0, int(max(0, height - 1))))
    var thick: int = int(clamp(ground_thickness, 1, height - gy))
    var has_top: bool = tile_set.has_source(grass_source_id) or (use_grass_mid and tile_set.has_source(grass_mid_source_id))
    var has_dirt: bool = tile_set.has_source(dirt_source_id)
    var x: int = 0
    while x < width:
        var plat_len: int = _rng.randi_range(min_platform_len, max_platform_len)
        var plat_end: int = int(min(x + plat_len, width))
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
        x = plat_end
        var gap_len: int = _rng.randi_range(min_gap_len, max_gap_len)
        x = int(min(x + gap_len, width))
    if add_dirt_band:
        _draw_dirt_band()

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

func _set_generate_now(value: bool) -> void:
    _generate_now = value
    if value:
        generate()
        _generate_now = false

func _get_generate_now() -> bool:
    return _generate_now