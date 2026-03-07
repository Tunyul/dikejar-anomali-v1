@tool
extends Node2D

## Aktif/nonaktif gerakan scroll ground.
@export var movement_enabled: bool = true
@export var regenerate_on_start: bool = true
## Kecepatan scroll ground (px/detik).
@export var scroll_speed: float = 220.0
## Percepatan menuju kecepatan target.
@export var acceleration: float = 18.0
## Jika true, perubahan kecepatan halus memakai acceleration.
@export var use_acceleration: bool = true
## Batas bawah kecepatan scroll.
@export var min_scroll_speed: float = 0.0
## Batas atas kecepatan scroll.
@export var max_scroll_speed: float = 480.0
## Jika true, segmen ground di-wrap tak hingga.
@export var wrap_infinite: bool = true
## Jika true, segmen yang di-wrap digenerate ulang polanya.
@export var regenerate_on_wrap: bool = true
## Panjang satu segmen ground (A dan B) dalam jumlah tile.
@export var segment_tile_count: int = 320
@export var segment_tile_count_min: int = 320
@export var segment_tile_count_max: int = 320
## Langkah vertikal MAKSIMUM naik/turun per kolom (dalam tile).
@export var max_step_height: int = 2
## Langkah vertikal MINIMUM naik/turun per kolom (dalam tile).
## Contoh: min=2 max=3 → setiap step selalu 2–3 tile.
@export var min_step_height: int = 1
## Tinggi MINIMUM permukaan ground relatif terhadap dasar (dalam tile).
## Contoh: min=3 max=5 → ground selalu 3–5 tile di atas dasar.
@export var min_height_tiles: int = 0
## Tinggi MAKSIMUM permukaan ground relatif terhadap dasar (dalam tile).
## 0 = rata dasar, 1 = satu tile di atas, dst.
@export var max_height_tiles: int = 1
## Panjang MINIMUM platform tanah (dalam tile) di antara dua gap.
## Nilai 6 membuat setiap platform minimal sepanjang 6 tile.
@export var min_platform_len: int = 6
@export var min_step_run_len: int = 6
@export var max_step_run_len: int = 6
## Peluang mencoba memulai GAP pada kolom ini (0–1).
## Semakin besar → jurang lebih sering muncul.
@export var gap_chance: float = 0.15
## Panjang MINIMUM satu gap (jurang) dalam tile.
## Jurang akan selalu ≥ nilai ini.
@export var gap_min_len: int = 3
## Panjang MAKSIMUM satu gap (jurang) dalam tile.
## Jurang akan selalu ≤ nilai ini.
@export var gap_max_len: int = 3
## Peluang mencoba naik (step up) pada kolom ini.
@export var up_chance: float = 0.3
## Peluang mencoba turun (step down) pada kolom ini.
@export var down_chance: float = 0.2
## Jika true, segmen A/B diberi warna tint debug.
@export var debug_tint_enabled: bool = false
## Warna tint untuk TileMapLayerA saat debug tint aktif.
@export var debug_color_a: Color = Color(0.7, 0.0, 0.12, 1.0)
## Warna tint untuk TileMapLayerB saat debug tint aktif.
@export var debug_color_b: Color = Color(1.0, 0.95, 0.0, 1.0)
@export var debug_color_flat_start: Color = Color(0.7, 0.0, 0.12, 1.0)
## Jika true, akan print log saat wrap segmen.
@export var debug_info_enabled: bool = false
@export var flat_start_length_tiles: int = 24
## Seed tetap untuk RNG; 0 berarti acak setiap init.
@export var fixed_seed: int = 0

# Pool variables for performance optimization (Object Pooling)
var _coin_pool: Array[Node2D] = []
var _enemy_block_pool: Array[Node2D] = []
var _enemy_cone_pool: Array[Node2D] = []
var _heart_pool: Array[Node2D] = []
var _diamond_pool: Array[Node2D] = []
var _magnet_pool: Array[Node2D] = []
var _shield_pool: Array[Node2D] = []
var _double_pool: Array[Node2D] = []
var _speed_pool: Array[Node2D] = []

var _generate_now_internal: bool = false
var _runtime_use_acceleration: bool = true
var _base_use_acceleration: bool = true

@export var generate_now: bool:
    set(value):
        _generate_now_internal = value
        if value:
            _run_generate_now(true, true)
            _generate_now_internal = false
    get:
        return _generate_now_internal

@export_group("Coins")
@export var coin_scene: PackedScene
@export var coin_spawn_chance: float = 1.0
@export var coin_max_children: int = 30
@export var coin_scale: float = 1.0
@export var coin_group_min_len: int = 3
@export var coin_group_max_len: int = 6
@export var coin_group_gap_min: int = 2
@export var coin_group_gap_max: int = 5
@export var coin_height_offset_tiles: float = 1.5
@export var diamond_height_offset_tiles: float = 1.5
@export var heart_height_offset_tiles: float = 1.5
@export var magnet_height_offset_tiles: float = 1.5
@export var shield_height_offset_tiles: float = 1.5
@export var double_coins_height_offset_tiles: float = 1.5
@export var speed_boost_height_offset_tiles: float = 1.5

@export_group("Diamonds")
@export var diamond_scene: PackedScene
@export var diamond_spawn_chance: float = 0.05
@export var diamond_max_children: int = 3
@export var diamond_scale: float = 1.0
@export var diamond_amount: int = 1
@export var diamond_min_distance_tiles: int = 50
@export var diamond_avoid_radius_tiles: int = 5
@export var diamond_high_spawn_ratio: float = 0.1
@export var diamond_high_extra_offset_min_tiles: float = 0.5
@export var diamond_high_extra_offset_max_tiles: float = 1.0

@export_group("Hearts")
@export var heart_scene: PackedScene
@export var heart_spawn_chance: float = 0.03
@export var heart_max_children: int = 2
@export var heart_scale: float = 1.0
@export var heart_min_distance_tiles: int = 100

@export_group("Powerups")
@export var magnet_powerup_scene: PackedScene
@export var magnet_max_children: int = 1
@export var magnet_scale: float = 1.0
@export var shield_powerup_scene: PackedScene
@export var shield_max_children: int = 1
@export var shield_scale: float = 1.0
@export var double_coins_powerup_scene: PackedScene
@export var double_coins_max_children: int = 1
@export var double_coins_scale: float = 1.0
@export var speed_boost_powerup_scene: PackedScene
@export var speed_boost_max_children: int = 1
@export var speed_boost_scale: float = 1.0
@export var powerup_coin_avoid_radius_tiles: int = 3

@export_group("Coin Patterns")
@export var coin_pattern_mode: int = 0
@export var coin_flat_top_min_len: int = 3
@export var coin_flat_top_max_len: int = 8
@export var coin_zigzag_enabled: bool = true
@export var coin_zigzag_amplitude_tiles: float = 0.5
@export var coin_zigzag_levels: int = 2

@export_group("Enemies")
@export var enemy_block_scene: PackedScene
@export var enemy_cone_scene: PackedScene
@export var enemy_spawn_chance: float = 0.3
@export var enemy_max_children: int = 15
@export var enemy_scale: float = 1.0
@export var enemy_min_platform_len: int = 5
@export var enemy_min_gap_between: int = 8
@export var enemy_y_offset_tiles: float = 0.0
@export var enemy_gap_safe_buffer_block: int = 2
@export var enemy_gap_safe_buffer_cone: int = 2
@export var enemy_block_weight: float = 1.0
@export var enemy_cone_weight: float = 1.0
@export var enemy_allow_block: bool = true
@export var enemy_allow_cone: bool = true

var _tile_flat_start: TileMapLayer = null
var _tile_a: TileMapLayer = null
var _tile_b: TileMapLayer = null
var _coins_a: Node2D = null
var _coins_b: Node2D = null
var _diamonds_a: Node2D = null
var _diamonds_b: Node2D = null
var _enemies_a: Node2D = null
var _enemies_b: Node2D = null
var _hearts_a: Node2D = null
var _hearts_b: Node2D = null
var _magnets_a: Node2D = null
var _magnets_b: Node2D = null
var _shields_a: Node2D = null
var _shields_b: Node2D = null
var _double_coins_a: Node2D = null
var _double_coins_b: Node2D = null
var _speed_boosts_a: Node2D = null
var _speed_boosts_b: Node2D = null
var _seg_width_px: float = 0.0
var _seg_overlap_px: float = 4.0
var _tile_w_px: float = 0.0
var _tile_h_px: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _height_a: int = 0
var _height_b: int = 0
var _target_speed: float = 250.0
var _initialized: bool = false
var _height_lock_remaining: int = 0
var _coin_pattern_type: int = 0
var _coin_pattern_index: int = 0
var _coin_group_len_current: int = 0
var _flat_top_start_index: int = 0
var _flat_top_end_index: int = 0
var _runtime_seed: int = 0
var _flat_start_runtime_initialized: bool = false
var _tiles_since_last_heart: int = 100
var _debug_heart_spawn_session_count: int = 0
var _initial_flat_start_pos: Vector2 = Vector2.ZERO
var _initial_tile_a_pos: Vector2 = Vector2.ZERO
var _initial_tile_b_pos: Vector2 = Vector2.ZERO
var _initial_positions_captured: bool = false

const _BASE_SEGMENT_TILES: int = 64

# ===== POOL MANAGEMENT =====
func _get_from_pool(pool: Array[Node2D], scene: PackedScene) -> Node2D:
    var inst: Node2D = null
    while not pool.is_empty():
        var candidate: Node2D = pool.pop_back() as Node2D
        if candidate == null or not is_instance_valid(candidate):
            continue
        if candidate.is_queued_for_deletion():
            continue
        inst = candidate
        break
    if inst == null:
        inst = scene.instantiate() as Node2D

    if inst and inst.has_method("reset"):
        # Log spam reduced: only print every 100 resets in debug builds
        _debug_heart_spawn_session_count += 1
        if OS.is_debug_build() and _debug_heart_spawn_session_count % 100 == 0:
            print("[DEBUG] Resetting pooled objects (Session Count: %d)" % _debug_heart_spawn_session_count)
        inst.call("reset")

    return inst

const _POOL_RETURN_META := "_pool_return_queued"

func _append_node_to_pool(node: Node, pool: Array[Node2D]) -> void:
    if node == null or not is_instance_valid(node):
        return
    if node.is_queued_for_deletion():
        return
    if node.has_meta(_POOL_RETURN_META):
        node.remove_meta(_POOL_RETURN_META)
    if node is Node2D:
        pool.append(node as Node2D)
    else:
        node.free()

func _return_to_pool_deferred(node: Node, pool: Array[Node2D]) -> void:
    if node == null or not is_instance_valid(node):
        return
    if node.is_queued_for_deletion():
        return
    if node.get_parent():
        node.get_parent().remove_child(node)
    _append_node_to_pool(node, pool)

func _return_to_pool(node: Node, pool: Array[Node2D]) -> void:
    if node == null or not is_instance_valid(node):
        return
    if node.has_meta(_POOL_RETURN_META):
        return
    var defer_return := Engine.is_in_physics_frame() and node is CollisionObject2D
    if defer_return:
        node.set_meta(_POOL_RETURN_META, true)
        call_deferred("_return_to_pool_deferred", node, pool)
        return
    if node.get_parent():
        node.get_parent().remove_child(node)
    _append_node_to_pool(node, pool)

func _clear_root_to_pool(root: Node2D, pool: Array[Node2D]) -> void:
    if root == null:
        return
    var children: Array[Node] = root.get_children()
    for c: Node in children:
        _return_to_pool(c, pool)

func return_spawned_node_to_pool(node: Node) -> bool:
    if node == null:
        return false
    if node is HeartPickup or node.is_in_group("heart_pickup"):
        _return_to_pool(node, _heart_pool)
        return true
    if node is MagnetPowerup or node.is_in_group("magnet_powerup"):
        _return_to_pool(node, _magnet_pool)
        return true
    if node is ShieldPowerup or node.is_in_group("shield_powerup"):
        _return_to_pool(node, _shield_pool)
        return true
    if node is DoubleCoinsPowerup or node.is_in_group("double_coins_powerup"):
        _return_to_pool(node, _double_pool)
        return true
    if node is SpeedBoostPowerup or node.is_in_group("speed_boost_powerup"):
        _return_to_pool(node, _speed_pool)
        return true

    if not (node is Node2D):
        return false

    var node2d := node as Node2D
    var nname := String(node2d.name)
    if nname.begins_with("EnemyBlock"):
        _return_to_pool(node2d, _enemy_block_pool)
        return true
    if nname.begins_with("EnemyCone"):
        _return_to_pool(node2d, _enemy_cone_pool)
        return true

    var sc := node2d.get_script() as Script
    if sc != null:
        var script_path := String(sc.resource_path)
        if script_path.ends_with("/coin.gd"):
            var currency := String(node2d.get("currency")).to_lower()
            if currency == "gems":
                _return_to_pool(node2d, _diamond_pool)
            else:
                _return_to_pool(node2d, _coin_pool)
            return true

    return false

func _scale_max_children(base: int) -> int:
    if base <= 0:
        return base
    var seg_len: int = max(segment_tile_count, 1)
    var factor: float = float(seg_len) / float(_BASE_SEGMENT_TILES)
    if factor <= 1.0:
        return base
    return int(round(float(base) * factor))

func _setup_rng() -> void:
    if _rng == null:
        _rng = RandomNumberGenerator.new()
    if Engine.is_editor_hint():
        if fixed_seed != 0:
            _rng.seed = fixed_seed
        else:
            _rng.randomize()
        return
    if _runtime_seed == 0:
        var base: int = fixed_seed
        if base == 0:
            base = 1
        var t: int = int(Time.get_ticks_msec())
        var path_hash: int = 0
        var cs: Node = get_tree().current_scene
        if cs != null:
            var p: String = cs.scene_file_path
            path_hash = hash(p)
        _runtime_seed = base ^ t ^ path_hash
    _rng.seed = _runtime_seed

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_PAUSABLE
    _base_use_acceleration = use_acceleration
    _runtime_use_acceleration = use_acceleration
    _initialized = false
    _ensure_initialized()
    _ensure_flat_start_tiles()
    if Engine.is_editor_hint():
        if _tile_a:
            _height_a = _generate_segment(_tile_a, 0)
            _tile_a.position.x = 0.0
            _sync_containers_for_tile(_tile_a)
        if _tile_b:
            _height_b = _generate_segment(_tile_b, _height_a)
            _tile_b.position.x = _seg_width_px
            _sync_containers_for_tile(_tile_b)
        _align_segments_with_flat_start()
        _apply_debug_tint()
        return
    if regenerate_on_start:
        if _tile_a:
            _height_a = _generate_segment(_tile_a, 0)
            _tile_a.position.x = 0.0
            _sync_containers_for_tile(_tile_a)
        if _tile_b:
            _height_b = _generate_segment(_tile_b, _height_a)
            _tile_b.position.x = _seg_width_px
            _sync_containers_for_tile(_tile_b)
    _align_segments_with_flat_start()
    _apply_debug_tint()

func _sync_containers_for_tile(tile: TileMapLayer) -> void:
    if not is_instance_valid(tile):
        return
    var target_pos: Vector2 = tile.position
    var target_scale: Vector2 = tile.scale
    if tile == _tile_a:
        if _coins_a:
            _coins_a.position = target_pos
            _coins_a.scale = target_scale
        if _diamonds_a:
            _diamonds_a.position = target_pos
            _diamonds_a.scale = target_scale
        if _enemies_a:
            _enemies_a.position = target_pos
            _enemies_a.scale = target_scale
        if _hearts_a:
            _hearts_a.position = target_pos
            _hearts_a.scale = target_scale
        if _magnets_a:
            _magnets_a.position = target_pos
            _magnets_a.scale = target_scale
        if _shields_a:
            _shields_a.position = target_pos
            _shields_a.scale = target_scale
        if _double_coins_a:
            _double_coins_a.position = target_pos
            _double_coins_a.scale = target_scale
        if _speed_boosts_a:
            _speed_boosts_a.position = target_pos
            _speed_boosts_a.scale = target_scale
    elif tile == _tile_b:
        if _coins_b:
            _coins_b.position = target_pos
            _coins_b.scale = target_scale
        if _diamonds_b:
            _diamonds_b.position = target_pos
            _diamonds_b.scale = target_scale
        if _enemies_b:
            _enemies_b.position = target_pos
            _enemies_b.scale = target_scale
        if _hearts_b:
            _hearts_b.position = target_pos
            _hearts_b.scale = target_scale
        if _magnets_b:
            _magnets_b.position = target_pos
            _magnets_b.scale = target_scale
        if _shields_b:
            _shields_b.position = target_pos
            _shields_b.scale = target_scale
        if _double_coins_b:
            _double_coins_b.position = target_pos
            _double_coins_b.scale = target_scale
        if _speed_boosts_b:
            _speed_boosts_b.position = target_pos
            _speed_boosts_b.scale = target_scale

func _ensure_initialized() -> void:
    if _initialized:
        return
    _setup_rng()
    if not is_instance_valid(_tile_flat_start):
        _tile_flat_start = get_node_or_null("TileMapLayerFlatStart") as TileMapLayer
    if not is_instance_valid(_tile_a):
        _tile_a = get_node_or_null("TileMapLayerA") as TileMapLayer
    if not is_instance_valid(_tile_b):
        _tile_b = get_node_or_null("TileMapLayerB") as TileMapLayer

    if not _initial_positions_captured:
        if _tile_flat_start:
            _initial_flat_start_pos = _tile_flat_start.position
        if _tile_a:
            _initial_tile_a_pos = _tile_a.position
        if _tile_b:
            _initial_tile_b_pos = _tile_b.position
        _initial_positions_captured = true

    # Inisialisasi kontainer secara otomatis jika tidak ada
    var containers: Array[Array] = [
        ["_coins_a", "CoinsA"], ["_coins_b", "CoinsB"],
        ["_diamonds_a", "DiamondsA"], ["_diamonds_b", "DiamondsB"],
        ["_enemies_a", "EnemiesA"], ["_enemies_b", "EnemiesB"],
        ["_hearts_a", "HeartsA"], ["_hearts_b", "HeartsB"],
        ["_magnets_a", "MagnetsA"], ["_magnets_b", "MagnetsB"],
        ["_shields_a", "ShieldsA"], ["_shields_b", "ShieldsB"],
        ["_double_coins_a", "DoubleCoinsA"], ["_double_coins_b", "DoubleCoinsB"],
        ["_speed_boosts_a", "SpeedBoostsA"], ["_speed_boosts_b", "SpeedBoostsB"]
    ]

    for pair: Array in containers:
        var var_name: String = pair[0]
        var node_name: String = pair[1]
        var current_val: Node2D = get(var_name)

        if not is_instance_valid(current_val):
            var existing: Node2D = get_node_or_null(node_name) as Node2D
            if is_instance_valid(existing):
                set(var_name, existing)
            else:
                var new_node: Node2D = Node2D.new()
                new_node.name = node_name
                new_node.z_index = 100
                add_child(new_node)
                if Engine.is_editor_hint():
                    new_node.owner = owner if owner else self
                set(var_name, new_node)

    # Sinkronisasi scale dan position container dengan TileMapLayer agar posisi lokal konsisten
    _sync_containers_for_tile(_tile_a)
    _sync_containers_for_tile(_tile_b)
    if coin_scene == null:
        coin_scene = load("res://scenes/Coin.tscn")
    if heart_scene == null:
        heart_scene = load("res://scenes/CollectibleHeart.tscn")
    if enemy_block_scene == null:
        enemy_block_scene = load("res://scenes/EnemyBlock.tscn")
    if enemy_cone_scene == null:
        enemy_cone_scene = load("res://scenes/EnemyCone.tscn")
    if magnet_powerup_scene == null:
        magnet_powerup_scene = load("res://scenes/MagnetPowerup.tscn")
    if shield_powerup_scene == null:
        shield_powerup_scene = load("res://scenes/ShieldPowerup.tscn")
    if double_coins_powerup_scene == null:
        double_coins_powerup_scene = load("res://scenes/DoubleCoinsPowerup.tscn")
    if speed_boost_powerup_scene == null:
        speed_boost_powerup_scene = load("res://scenes/SpeedBoostPowerup.tscn")
    if _tile_a and _tile_a.tile_set and (_tile_w_px <= 0.0 or _tile_h_px <= 0.0):
        var cell: Vector2i = _tile_a.tile_set.tile_size
        _tile_w_px = float(cell.x) * _tile_a.scale.x
        _tile_h_px = float(cell.y) * _tile_a.scale.y
    if _tile_w_px <= 0.0:
        _tile_w_px = 128.0
    if _tile_h_px <= 0.0:
        _tile_h_px = 128.0
    if segment_tile_count <= 0:
        if _tile_a != null:
            var used_a: Rect2i = _tile_a.get_used_rect()
            if used_a.size.x > 0:
                segment_tile_count = used_a.size.x
        elif _tile_b != null:
            var used_b: Rect2i = _tile_b.get_used_rect()
            if used_b.size.x > 0:
                segment_tile_count = used_b.size.x
    if segment_tile_count_min <= 0:
        segment_tile_count_min = max(segment_tile_count, 1)
    if segment_tile_count_max < segment_tile_count_min:
        segment_tile_count_max = segment_tile_count_min
    if not Engine.is_editor_hint():
        segment_tile_count = _rng.randi_range(segment_tile_count_min, segment_tile_count_max)
    if min_step_run_len < 1:
        min_step_run_len = 1
    if max_step_run_len < min_step_run_len:
        max_step_run_len = min_step_run_len
    _seg_width_px = _tile_w_px * float(segment_tile_count)
    _target_speed = scroll_speed
    _initialized = true

func _ensure_flat_start_tiles() -> void:
    if _tile_flat_start == null:
        return
    if not Engine.is_editor_hint():
        if _flat_start_runtime_initialized:
            return
    var len_cells: int = flat_start_length_tiles
    if len_cells <= 0:
        _tile_flat_start.clear()
        _clear_collision_for_tile(_tile_flat_start)
        return
    var h_base: int = clamp(0, min_height_tiles, max_height_tiles)
    _tile_flat_start.clear()
    _clear_collision_for_tile(_tile_flat_start)
    var x: int = 0
    while x < len_cells:
        _place_ground_column(_tile_flat_start, x, h_base)
        x += 1
    if not Engine.is_editor_hint():
        _flat_start_runtime_initialized = true

func _align_segments_with_flat_start() -> void:
    if _tile_flat_start == null:
        return
    if _tile_a == null:
        return
    var rect: Rect2i = _tile_flat_start.get_used_rect()
    if rect.size.x <= 0 and flat_start_length_tiles <= 0:
        return
    var cell_size: Vector2 = Vector2.ZERO
    if _tile_flat_start.tile_set != null:
        cell_size = Vector2(_tile_flat_start.tile_set.tile_size)
    elif _tile_a.tile_set != null:
        cell_size = Vector2(_tile_a.tile_set.tile_size)
    else:
        cell_size = Vector2(_tile_w_px, _tile_h_px)
    var scale_x: float = _tile_flat_start.scale.x
    var start_cell_x: int = rect.position.x
    var len_cells: int = rect.size.x
    if flat_start_length_tiles > 0:
        if len_cells <= 0:
            len_cells = flat_start_length_tiles
            start_cell_x = 0
    if len_cells <= 0:
        return
    var end_cells: int = start_cell_x + len_cells
    var length_px: float = float(end_cells) * cell_size.x * scale_x
    var start_x: float = _tile_flat_start.position.x + length_px - _seg_overlap_px
    var pos_a: Vector2 = _tile_a.position
    _tile_a.position = Vector2(start_x, pos_a.y)
    _sync_containers_for_tile(_tile_a)

    if _tile_b != null:
        _tile_b.position.x = _tile_a.position.x + _seg_width_px - _seg_overlap_px
        _sync_containers_for_tile(_tile_b)

func _physics_process(delta: float) -> void:
    if Engine.is_editor_hint():
        return
    if not movement_enabled:
        return
    if _runtime_use_acceleration:
        if scroll_speed < _target_speed:
            scroll_speed = min(scroll_speed + acceleration * delta, _target_speed)
        elif scroll_speed > _target_speed:
            scroll_speed = max(scroll_speed - acceleration * delta, _target_speed)
    if scroll_speed == 0.0:
        return
    var dx: float = scroll_speed * delta

    # Gerakkan TileMapLayer saja
    if _tile_flat_start:
        _tile_flat_start.position.x -= dx

    if _tile_a:
        _tile_a.position.x -= dx
        _sync_containers_for_tile(_tile_a)

    if _tile_b:
        _tile_b.position.x -= dx
        _sync_containers_for_tile(_tile_b)

    if wrap_infinite:
        _handle_wrap()

func _handle_wrap() -> void:
    if _tile_a == null or _tile_b == null:
        return
    var left: TileMapLayer = _tile_a
    var right: TileMapLayer = _tile_b
    if left.position.x > right.position.x:
        left = _tile_b
        right = _tile_a
    var left_end: float = left.position.x + _seg_width_px
    if left_end < -_seg_width_px * 0.25:
        left.position.x = right.position.x + _seg_width_px - _seg_overlap_px
        if debug_info_enabled:
            print("[InfiniteGround] Wrapping segment: ", left.name, " to ", left.position.x)

        # Hard sync positions immediately after wrap
        _sync_containers_for_tile(left)
        if regenerate_on_wrap:
            var start_h: int = _height_a
            if left == _tile_a:
                start_h = _height_b
            else:
                start_h = _height_a
            var new_h: int = _generate_segment(left, start_h)
            if left == _tile_a:
                _height_a = new_h
            else:
                _height_b = new_h
        _apply_debug_tint()

func _generate_segment(tile: TileMapLayer, start_height: int) -> int:
    if tile == null:
        return start_height
    _clear_collision_for_tile(tile)
    _clear_coins_for_tile(tile)
    _clear_diamonds_for_tile(tile)
    _clear_enemies_for_tile(tile)
    _clear_hearts_for_tile(tile)
    _clear_powerups_for_tile(tile)
    tile.clear()
    var current_height: int = clamp(start_height, min_height_tiles, max_height_tiles)
    var gap_edges: Array[Vector2i] = []
    var gap_remaining: int = 0
    var last_was_gap: bool = false
    var ground_run_len: int = 0
    var height_run_len: int = 0
    var coin_group_remaining: int = 0
    var coin_gap_remaining: int = 0
    var coin_pending_gap_len: int = 0
    var enemy_gap_remaining: int = 0
    var enemy_columns: Array[int] = []

    var last_heart_x: int = -1024
    var last_diamond_x: int = -1024
    var i: int = 0
    var is_first_segment: bool = false
    if not Engine.is_editor_hint():
        if not _flat_start_runtime_initialized:
             is_first_segment = (tile == _tile_a)
    else:
        is_first_segment = false

    while i < segment_tile_count:
        _tiles_since_last_heart += 1
        var flat_override: bool = false
        if is_first_segment and i < max(min_platform_len, 12):
            flat_override = true

        if flat_override:
            gap_remaining = 0
        else:
            if gap_remaining > 0:
                gap_remaining -= 1
                i += 1
                last_was_gap = true
                ground_run_len = 0
                height_run_len = 0
                continue
            var rg: float = _rng.randf()
            if rg < gap_chance and not last_was_gap and ground_run_len >= min_platform_len and _height_lock_remaining <= 0:
                var remaining: int = segment_tile_count - i
                var max_len: int = min(gap_max_len, max(remaining - 1, 0))
                if max_len >= gap_min_len:
                    var glen: int = _rng.randi_range(gap_min_len, max_len)
                    gap_remaining = max(glen - 1, 0)
                    gap_edges.append(Vector2i(i, i + glen - 1))
                    i += 1
                    last_was_gap = true
                    ground_run_len = 0
                    continue

        var cols_remaining: int = segment_tile_count - i
        var rs: float = _rng.randf()
        var can_step: bool = not flat_override and cols_remaining >= max(min_step_run_len, 1) and height_run_len >= min_step_run_len
        if _height_lock_remaining > 0:
            _height_lock_remaining -= 1
            can_step = false
        if can_step:
            var step_min: int = max(min_step_height, 1)
            var step_max: int = max(max_step_height, step_min)
            if rs < up_chance and current_height < max_height_tiles:
                var step_up: int = _rng.randi_range(step_min, step_max)
                current_height = clamp(current_height + step_up, min_height_tiles, max_height_tiles)
                height_run_len = 0
                var lock_min: int = max(min_step_run_len - 1, 0)
                var lock_max: int = max(max_step_run_len - 1, lock_min)
                var max_lock_allowed: int = max(cols_remaining - 1, 0)
                lock_max = min(lock_max, max_lock_allowed)
                if lock_max > 0 and lock_max >= lock_min:
                    _height_lock_remaining = _rng.randi_range(lock_min, lock_max)
            elif rs < up_chance + down_chance and current_height > min_height_tiles:
                var step_down: int = _rng.randi_range(step_min, step_max)
                current_height = clamp(current_height - step_down, min_height_tiles, max_height_tiles)
                height_run_len = 0
                var lock_min_d: int = max(min_step_run_len - 1, 0)
                var lock_max_d: int = max(max_step_run_len - 1, lock_min_d)
                var max_lock_allowed_d: int = max(cols_remaining - 1, 0)
                lock_max_d = min(lock_max_d, max_lock_allowed_d)
                if lock_max_d > 0 and lock_max_d >= lock_min_d:
                    _height_lock_remaining = _rng.randi_range(lock_min_d, lock_max_d)

        _place_ground_column(tile, i, current_height)
        var do_spawn_coin: bool = false
        var coins_allowed: bool = true
        if coins_allowed:
            var group_enabled: bool = coin_group_max_len >= coin_group_min_len and coin_group_max_len > 0
            if group_enabled:
                if coin_group_remaining > 0:
                    do_spawn_coin = true
                    coin_group_remaining -= 1
                    if coin_group_remaining == 0 and coin_pending_gap_len > 0:
                        coin_gap_remaining = coin_pending_gap_len
                        coin_pending_gap_len = 0
                elif coin_gap_remaining > 0:
                    coin_gap_remaining -= 1
                else:
                    if coin_spawn_chance > 0.0:
                        var roll: float = _rng.randf()
                        if roll < coin_spawn_chance:
                            var gmin: int = max(coin_group_min_len, 1)
                            var gmax: int = max(coin_group_max_len, gmin)
                            var cols_for_group: int = cols_remaining
                            if cols_for_group >= gmin:
                                gmax = min(gmax, cols_for_group)
                                coin_group_remaining = _rng.randi_range(gmin, gmax)
                                _coin_group_len_current = coin_group_remaining
                            var gap_min_c: int = max(coin_group_gap_min, 0)
                            var gap_max_c: int = max(coin_group_gap_max, gap_min_c)
                            if gap_max_c > 0:
                                coin_pending_gap_len = _rng.randi_range(gap_min_c, gap_max_c)
                            _select_coin_pattern()
                            do_spawn_coin = true
                            coin_group_remaining -= 1
                            if coin_group_remaining == 0 and coin_pending_gap_len > 0:
                                coin_gap_remaining = coin_pending_gap_len
                                coin_pending_gap_len = 0
            else:
                do_spawn_coin = true

        if do_spawn_coin:
            _spawn_coin_for_column(tile, i, current_height)

        var do_spawn_enemy: bool = false
        var enemies_allowed: bool = not flat_override and not do_spawn_coin
        if enemies_allowed:
            if enemy_gap_remaining > 0:
                enemy_gap_remaining -= 1
            else:
                var run_len_after: int = ground_run_len + 1
                if run_len_after >= enemy_min_platform_len:
                    do_spawn_enemy = true
                    enemy_gap_remaining = max(enemy_min_gap_between, 0)
        if do_spawn_enemy:
            _spawn_enemy_for_column(tile, i, current_height)
            enemy_columns.append(i)

        var can_spawn_diamond: bool = true
        if diamond_scene == null:
            can_spawn_diamond = false
        elif diamond_spawn_chance <= 0.0:
            can_spawn_diamond = false
        if can_spawn_diamond:
            var min_d: float = max(diamond_min_distance_tiles, 0.0)
            if min_d > 0.0 and last_diamond_x >= 0 and float(i - last_diamond_x) < min_d:
                can_spawn_diamond = false
        if can_spawn_diamond:
            var r_avoid: int = max(diamond_avoid_radius_tiles, 0)
            if r_avoid > 0 and _has_coin_near_x(tile, i, r_avoid):
                can_spawn_diamond = false
        if can_spawn_diamond:
            if _has_enemy_near_x(tile, i, 0) or _has_heart_near_x(tile, i, 0):
                can_spawn_diamond = false
        if can_spawn_diamond:
            var rd: float = _rng.randf()
            if rd < diamond_spawn_chance:
                _spawn_diamond_for_column(tile, i, current_height)
                last_diamond_x = i

        var can_spawn_heart: bool = true
        if heart_scene == null:
            can_spawn_heart = false
        elif heart_spawn_chance <= 0.0:
            can_spawn_heart = false
        if can_spawn_heart:
            var main: Node = _get_main_node()
            if main != null and main.has_method("can_spawn_hearts"):
                var should_spawn: bool = main.call("can_spawn_hearts")
                if not should_spawn:
                    can_spawn_heart = false
                    # Log spam reduced: only print every 50 attempts in debug builds
                    _debug_heart_spawn_session_count += 1
                    if OS.is_debug_build() and _debug_heart_spawn_session_count % 50 == 0:
                         print("[InfiniteGround] Heart spawn blocked by GameManager. Player full health (Count: %d)" % _debug_heart_spawn_session_count)
            elif main == null:
                 print("[InfiniteGround] Warning: Main scene not found for heart spawn check.")

        if can_spawn_heart:
            var min_dist: float = max(heart_min_distance_tiles, 1.0)
            if min_dist > 0.0 and last_heart_x >= 0 and float(i - last_heart_x) < min_dist:
                can_spawn_heart = false
            if _tiles_since_last_heart < min_dist:
                can_spawn_heart = false
        if can_spawn_heart:
            var has_enemy_here: bool = _has_enemy_near_x(tile, i, 0)
            if has_enemy_here:
                can_spawn_heart = false
        if can_spawn_heart:
            var rh: float = _rng.randf()
            if rh < heart_spawn_chance:
                _spawn_heart_for_column(tile, i, current_height)
                last_heart_x = i
        last_was_gap = false
        ground_run_len += 1
        height_run_len += 1
        i += 1
        _tiles_since_last_heart += 1

    if not gap_edges.is_empty():
        _clear_coins_near_gaps(tile, gap_edges)
        _clear_enemies_near_gaps(tile, gap_edges)
    _clear_lonely_peak_coins(tile)
    _clear_short_coin_groups(tile)
    _ensure_trailing_coins(tile)
    _ensure_min_spawn_density(tile)

    return current_height

func _ensure_trailing_coins(tile: TileMapLayer) -> void:
    if tile == null:
        return
    var root: Node2D = _get_coins_root_for_tile(tile)
    if root == null:
        return
    var last_ground_x: int = -1
    var x: int = segment_tile_count - 1
    while x >= 0:
        var h: int = _get_ground_height_for_column(tile, x)
        if h >= 0:
            last_ground_x = x
            break
        x -= 1
    if last_ground_x < 0:
        return
    var has_coin: bool = false
    var radius_tiles: int = 3
    for c: Node in root.get_children():
        if not (c is Node2D):
            continue
        var coin_node: Node2D = c as Node2D
        var cell: Vector2i = tile.local_to_map(coin_node.position)
        if abs(cell.x - last_ground_x) <= radius_tiles:
            has_coin = true
            break
    if has_coin:
        return
    var start_x: int = max(last_ground_x - radius_tiles, 0)
    for sx: int in range(start_x, last_ground_x + 1):
        var h2: int = _get_ground_height_for_column(tile, sx)
        if h2 < 0:
            continue
        var has_enemy_trail: bool = _has_enemy_near_x(tile, sx, 1)
        if has_enemy_trail:
            continue
        _spawn_coin_for_column(tile, sx, h2)

func _has_enemy_near_x(tile: TileMapLayer, x: int, radius: int) -> bool:
    var root: Node2D = _get_enemies_root_for_tile(tile)
    if root == null:
        return false
    var r: int = max(radius, 0)
    for c: Node in root.get_children():
        if not (c is Node2D):
            continue
        var enemy_node: Node2D = c as Node2D
        var cell: Vector2i = tile.local_to_map(enemy_node.position)
        if abs(cell.x - x) <= r:
            return true
    return false

func _is_near_enemy(tile_x: int, enemy_columns: Array[int], buffer: int) -> bool:
    var b: int = max(buffer, 0)
    if enemy_columns.is_empty() or b <= 0:
        return false
    for ex: int in enemy_columns:
        if abs(tile_x - ex) <= b:
            return true
    return false

func _column_world_x(tile: TileMapLayer, x: int) -> float:
    if tile == null:
        return 0.0
    if not tile.is_inside_tree():
        return 0.0
    var cell: Vector2i = Vector2i(x, 0)
    var local_pos: Vector2 = tile.map_to_local(cell)
    var world_pos: Vector2 = tile.to_global(local_pos)
    return world_pos.x

func _get_main_node() -> Node:
    var root := get_tree().get_root()
    if root == null:
        return null
    var gm := root.get_node_or_null("GameManager")
    if gm != null:
        return gm
    return root.get_node_or_null("Main")

func _get_coins_root_for_tile(tile: TileMapLayer) -> Node2D:
    if tile == _tile_a:
        return _coins_a
    elif tile == _tile_b:
        return _coins_b
    return null

func _get_hearts_root_for_tile(tile: TileMapLayer) -> Node2D:
    if tile == _tile_a: return _hearts_a
    if tile == _tile_b: return _hearts_b
    return null

func _get_magnets_root_for_tile(tile: TileMapLayer) -> Node2D:
    if tile == _tile_a: return _magnets_a
    if tile == _tile_b: return _magnets_b
    return null

func _get_shields_root_for_tile(tile: TileMapLayer) -> Node2D:
    if tile == _tile_a: return _shields_a
    if tile == _tile_b: return _shields_b
    return null

func _get_double_coins_root_for_tile(tile: TileMapLayer) -> Node2D:
    if tile == _tile_a: return _double_coins_a
    if tile == _tile_b: return _double_coins_b
    return null

func _get_speed_boosts_root_for_tile(tile: TileMapLayer) -> Node2D:
    if tile == _tile_a: return _speed_boosts_a
    if tile == _tile_b: return _speed_boosts_b
    return null

func get_powerup_distances(from_world_x: float) -> Dictionary:
    _ensure_initialized()
    var result: Dictionary = {}
    result["magnet"] = -1.0
    result["shield"] = -1.0
    result["double_coins"] = -1.0
    result["speed_boost"] = -1.0
    var tiles: Array[TileMapLayer] = []
    if _tile_a != null:
        tiles.append(_tile_a)
    if _tile_b != null:
        tiles.append(_tile_b)
    for tile: TileMapLayer in tiles:
        if tile == null:
            continue
        var roots: Array[Node2D] = [
            _get_coins_root_for_tile(tile),
            _get_magnets_root_for_tile(tile),
            _get_shields_root_for_tile(tile),
            _get_double_coins_root_for_tile(tile),
            _get_speed_boosts_root_for_tile(tile)
        ]
        for root: Node2D in roots:
            if root == null:
                continue
            for c: Node in root.get_children():
                if not (c is Node2D):
                    continue
                var kind: String = ""
                if c is MagnetPowerup:
                    kind = "magnet"
                elif c is ShieldPowerup or c.is_in_group("shield_powerup"):
                    kind = "shield"
                elif c is DoubleCoinsPowerup:
                    kind = "double_coins"
                elif c is SpeedBoostPowerup:
                    kind = "speed_boost"
                if kind == "":
                    continue
                var n2d: Node2D = c as Node2D
                if n2d == null:
                    continue
                if not tile.is_inside_tree():
                    continue
                var dx: float = n2d.position.x - (from_world_x - tile.global_position.x)
                if dx < 0.0:
                    continue
                var dist_tiles: float = dx
                if _tile_w_px > 0.0:
                    dist_tiles = dx / _tile_w_px
                var prev: float = float(result.get(kind, -1.0))
                if prev < 0.0 or dist_tiles < prev:
                    result[kind] = dist_tiles
    return result

func get_tile_width_px() -> float:
    _ensure_initialized()
    return _tile_w_px

func _has_coin_near_x(tile: TileMapLayer, x: int, radius: int) -> bool:
    var root: Node2D = _get_coins_root_for_tile(tile)
    if root == null:
        return false
    var r: int = max(radius, 0)
    for c: Node in root.get_children():
        if not (c is Node2D):
            continue
        if not c.has_method("get"):
            continue
        if str(c.get("currency")) != "coins":
            continue
        var coin_node: Node2D = c as Node2D
        var cell: Vector2i = tile.local_to_map(coin_node.position)
        if abs(cell.x - x) <= r:
            return true
    return false

func _has_heart_near_x(tile: TileMapLayer, x: int, radius: int) -> bool:
    var roots: Array[Node2D] = [_get_hearts_root_for_tile(tile), _get_coins_root_for_tile(tile)]
    var r: int = max(radius, 0)
    for root: Node2D in roots:
        if root == null: continue
        for c: Node in root.get_children():
            if not (c is HeartPickup) and not c.is_in_group("heart_pickup"):
                continue
            if not (c is Node2D):
                continue
            var heart_node: Node2D = c as Node2D
            var cell: Vector2i = tile.local_to_map(heart_node.position)
            if abs(cell.x - x) <= r:
                return true
    return false

func _has_magnet_near_x(tile: TileMapLayer, x: int, radius: int) -> bool:
    var roots: Array[Node2D] = [_get_magnets_root_for_tile(tile), _get_coins_root_for_tile(tile)]
    var r: int = max(radius, 0)
    for root: Node2D in roots:
        if root == null: continue
        for c: Node in root.get_children():
            if not (c is MagnetPowerup):
                continue
            if not (c is Node2D):
                continue
            var magnet_node: Node2D = c as Node2D
            var cell: Vector2i = tile.local_to_map(magnet_node.position)
            if abs(cell.x - x) <= r:
                return true
    return false

func _has_shield_near_x(tile: TileMapLayer, x: int, radius: int) -> bool:
    var roots: Array[Node2D] = [_get_shields_root_for_tile(tile), _get_coins_root_for_tile(tile)]
    var r: int = max(radius, 0)
    for root: Node2D in roots:
        if root == null: continue
        for c: Node in root.get_children():
            if not (c is Node2D):
                continue
            var node2d: Node2D = c as Node2D
            if not (node2d is ShieldPowerup) and not node2d.is_in_group("shield_powerup"):
                continue
            var cell: Vector2i = tile.local_to_map(node2d.position)
            if abs(cell.x - x) <= r:
                return true
    return false

func _has_double_coins_near_x(tile: TileMapLayer, x: int, radius: int) -> bool:
    var roots: Array[Node2D] = [_get_double_coins_root_for_tile(tile), _get_coins_root_for_tile(tile)]
    var r: int = max(radius, 0)
    for root: Node2D in roots:
        if root == null: continue
        for c: Node in root.get_children():
            if not (c is Node2D):
                continue
            var node2d: Node2D = c as Node2D
            if not (node2d is DoubleCoinsPowerup):
                continue
            var cell: Vector2i = tile.local_to_map(node2d.position)
            if abs(cell.x - x) <= r:
                return true
    return false

func _has_speed_boost_near_x(tile: TileMapLayer, x: int, radius: int) -> bool:
    var roots: Array[Node2D] = [_get_speed_boosts_root_for_tile(tile), _get_coins_root_for_tile(tile)]
    var r: int = max(radius, 0)
    for root: Node2D in roots:
        if root == null: continue
        for c: Node in root.get_children():
            if not (c is Node2D):
                continue
            var node2d: Node2D = c as Node2D
            if not (node2d is SpeedBoostPowerup):
                continue
            var cell: Vector2i = tile.local_to_map(node2d.position)
            if abs(cell.x - x) <= r:
                return true
    return false

func _ensure_min_spawn_density(_tile: TileMapLayer) -> void:
    return

func _clear_coins_for_tile(tile: TileMapLayer) -> void:
    _clear_root_to_pool(_get_coins_root_for_tile(tile), _coin_pool)

func _get_diamonds_root_for_tile(tile: TileMapLayer) -> Node2D:
    if tile == _tile_a:
        return _diamonds_a
    elif tile == _tile_b:
        return _diamonds_b
    return null

func _clear_diamonds_for_tile(tile: TileMapLayer) -> void:
    _clear_root_to_pool(_get_diamonds_root_for_tile(tile), _diamond_pool)

func _get_enemies_root_for_tile(tile: TileMapLayer) -> Node2D:
    if tile == _tile_a:
        return _enemies_a
    elif tile == _tile_b:
        return _enemies_b
    return null

func _clear_enemies_for_tile(tile: TileMapLayer) -> void:
    var root: Node2D = _get_enemies_root_for_tile(tile)
    if root == null:
        return
    var children: Array[Node] = root.get_children()
    for c: Node in children:
        if c.name.begins_with("EnemyBlock"):
            _return_to_pool(c as Node2D, _enemy_block_pool)
        elif c.name.begins_with("EnemyCone"):
            _return_to_pool(c as Node2D, _enemy_cone_pool)
        else:
            c.free()

func _clear_hearts_for_tile(tile: TileMapLayer) -> void:
    _clear_root_to_pool(_get_hearts_root_for_tile(tile), _heart_pool)

func _clear_powerups_for_tile(tile: TileMapLayer) -> void:
    _clear_root_to_pool(_get_magnets_root_for_tile(tile), _magnet_pool)
    _clear_root_to_pool(_get_shields_root_for_tile(tile), _shield_pool)
    _clear_root_to_pool(_get_double_coins_root_for_tile(tile), _double_pool)
    _clear_root_to_pool(_get_speed_boosts_root_for_tile(tile), _speed_pool)

func request_emergency_heart(from_world_x: float, min_dist_px: float, max_dist_px: float) -> bool:
    if OS.is_debug_build():
        print("[InfiniteGround] request_emergency_heart called. Min: %.2f, Max: %.2f" % [min_dist_px, max_dist_px])
    _ensure_initialized()
    if heart_scene == null:
        return false
    var min_world: float = from_world_x + max(min_dist_px, 0.0)
    var max_world: float = from_world_x + max(max_dist_px, min_dist_px)
    if max_world <= min_world:
        max_world = min_world + _tile_w_px
    var tiles: Array[TileMapLayer] = []
    if _tile_a != null:
        tiles.append(_tile_a)
    if _tile_b != null:
        tiles.append(_tile_b)
    for tile: TileMapLayer in tiles:
        if tile == null:
            continue
        var best_x: int = -1
        var x: int = 0
        while x < segment_tile_count:
            var h: int = _get_ground_height_for_column(tile, x)
            if h >= 0:
                var wx: float = _column_world_x(tile, x)
                if wx >= min_world and wx <= max_world:
                    var has_enemy: bool = _has_enemy_near_x(tile, x, 0)
                    if has_enemy:
                        x += 1
                        continue
                    var has_heart: bool = _has_heart_near_x(tile, x, 1)
                    if has_heart:
                        x += 1
                        continue
                    best_x = x
                    break
            x += 1
        if best_x >= 0:
            var h_best: int = _get_ground_height_for_column(tile, best_x)
            if h_best >= 0:
                _spawn_heart_for_column(tile, best_x, h_best, true)
                if OS.is_debug_build():
                    print("[InfiniteGround] Emergency heart spawned at tile_x: %d" % best_x)
                return true
    if OS.is_debug_build():
        print("[InfiniteGround] Failed to spawn emergency heart (no valid spot found).")
    return false

func _count_powerups_of_type() -> Dictionary:
    var counts: Dictionary = {}
    counts["magnet"] = 0
    counts["shield"] = 0
    counts["double_coins"] = 0
    counts["speed_boost"] = 0
    var tiles: Array[TileMapLayer] = []
    if _tile_a != null:
        tiles.append(_tile_a)
    if _tile_b != null:
        tiles.append(_tile_b)
    for tile: TileMapLayer in tiles:
        if tile == null:
            continue

        var magnet_root: Node2D = _get_magnets_root_for_tile(tile)
        if magnet_root:
            counts["magnet"] += magnet_root.get_child_count()

        var shield_root: Node2D = _get_shields_root_for_tile(tile)
        if shield_root:
            counts["shield"] += shield_root.get_child_count()

        var double_root: Node2D = _get_double_coins_root_for_tile(tile)
        if double_root:
            counts["double_coins"] += double_root.get_child_count()

        var speed_root: Node2D = _get_speed_boosts_root_for_tile(tile)
        if speed_root:
            counts["speed_boost"] += speed_root.get_child_count()

        var coin_root: Node2D = _get_coins_root_for_tile(tile)
        if coin_root:
            for c: Node in coin_root.get_children():
                if not (c is Node2D):
                    continue
                var node2d: Node2D = c as Node2D
                if node2d is MagnetPowerup:
                    counts["magnet"] += 1
                elif (node2d is ShieldPowerup) or node2d.is_in_group("shield_powerup"):
                    counts["shield"] += 1
                elif node2d is DoubleCoinsPowerup:
                    counts["double_coins"] += 1
                elif node2d is SpeedBoostPowerup:
                    counts["speed_boost"] += 1
    return counts

func request_emergency_magnet(from_world_x: float, min_dist_px: float, max_dist_px: float) -> bool:
    _ensure_initialized()
    if magnet_powerup_scene == null:
        return false
    var main: Node = _get_main_node()
    if main != null and main.has_method("is_magnet_active"):
        if main.call("is_magnet_active"):
            return false
    var min_world: float = from_world_x + max(min_dist_px, 0.0)
    var max_world: float = from_world_x + max(max_dist_px, min_dist_px)
    if max_world <= min_world:
        max_world = min_world + _tile_w_px
    var tiles: Array[TileMapLayer] = []
    if _tile_a != null:
        tiles.append(_tile_a)
    if _tile_b != null:
        tiles.append(_tile_b)
    var counts: Dictionary = _count_powerups_of_type()
    var total_magnets: int = int(counts["magnet"])
    if magnet_max_children > 0 and total_magnets >= magnet_max_children:
        return false
    for tile: TileMapLayer in tiles:
        if tile == null:
            continue
        var root: Node2D = _get_coins_root_for_tile(tile)
        if root == null:
            continue
        var best_x: int = -1
        var x: int = 0
        while x < segment_tile_count:
            var h: int = _get_ground_height_for_column(tile, x)
            if h >= 0:
                var wx: float = _column_world_x(tile, x)
                if wx >= min_world and wx <= max_world:
                    var has_enemy: bool = _has_enemy_near_x(tile, x, 0)
                    if has_enemy:
                        x += 1
                        continue
                    var has_heart: bool = _has_heart_near_x(tile, x, 1)
                    if has_heart:
                        x += 1
                        continue
                    var has_magnet: bool = _has_magnet_near_x(tile, x, 1)
                    if has_magnet:
                        x += 1
                        continue
                    var has_coin: bool = _has_coin_near_x(tile, x, powerup_coin_avoid_radius_tiles)
                    if has_coin:
                        x += 1
                        continue
                    best_x = x
                    break
            x += 1
        if best_x >= 0:
            var h_best: int = _get_ground_height_for_column(tile, best_x)
            if h_best >= 0:
                var top_y: int = -h_best
                var offset_tiles: float = max(magnet_height_offset_tiles, 0.0)
                var whole_tiles: int = int(floor(offset_tiles))
                var frac_tiles: float = offset_tiles - float(whole_tiles)
                var magnet_y: int = top_y - whole_tiles
                var cell: Vector2i = Vector2i(best_x, magnet_y)
                var local_pos: Vector2 = tile.map_to_local(cell)
                if frac_tiles != 0.0:
                    if tile.tile_set != null:
                        local_pos.y -= frac_tiles * float(tile.tile_set.tile_size.y)
                var magnet: Node2D = _get_from_pool(_magnet_pool, magnet_powerup_scene)
                if magnet == null:
                    return false
                magnet.scale = _calc_scale(magnet_scale, tile)

                var target_root: Node2D = _get_magnets_root_for_tile(tile)
                if target_root == null:
                    target_root = root

                target_root.add_child(magnet)
                magnet.position = local_pos

                if magnet.has_method("reset"):
                    magnet.call("reset")
                return true
    return false

func _request_emergency_powerup(from_world_x: float, min_dist_px: float, max_dist_px: float, kind: String) -> bool:
    _ensure_initialized()
    var scene: PackedScene = null
    var max_children: int = 0
    var height_offset: float = 0.0
    var scale_value: float = 1.0
    var main: Node = _get_main_node()
    if kind == "shield":
        scene = shield_powerup_scene
        max_children = shield_max_children
        height_offset = shield_height_offset_tiles
        scale_value = shield_scale
        if main != null and main.has_method("is_shield_active"):
            if main.call("is_shield_active"):
                return false
    elif kind == "double_coins":
        scene = double_coins_powerup_scene
        max_children = double_coins_max_children
        height_offset = double_coins_height_offset_tiles
        scale_value = double_coins_scale
        if main != null and main.has_method("is_double_coins_active"):
            if main.call("is_double_coins_active"):
                return false
    elif kind == "speed_boost":
        scene = speed_boost_powerup_scene
        max_children = speed_boost_max_children
        height_offset = speed_boost_height_offset_tiles
        scale_value = speed_boost_scale
        if main != null and main.has_method("is_speed_boost_active"):
            if main.call("is_speed_boost_active"):
                return false
    if scene == null:
        return false
    var min_world: float = from_world_x + max(min_dist_px, 0.0)
    var max_world: float = from_world_x + max(max_dist_px, min_dist_px)
    if max_world <= min_world:
        max_world = min_world + _tile_w_px
    var tiles: Array[TileMapLayer] = []
    if _tile_a != null:
        tiles.append(_tile_a)
    if _tile_b != null:
        tiles.append(_tile_b)
    var counts: Dictionary = _count_powerups_of_type()
    var current: int = int(counts[kind])
    if max_children > 0 and current >= max_children:
        return false
    for tile: TileMapLayer in tiles:
        if tile == null:
            continue
        var root: Node2D = _get_coins_root_for_tile(tile)
        if root == null:
            continue
        var best_x: int = -1
        var x: int = 0
        while x < segment_tile_count:
            var h: int = _get_ground_height_for_column(tile, x)
            if h >= 0:
                var wx: float = _column_world_x(tile, x)
                if wx >= min_world and wx <= max_world:
                    var has_enemy: bool = _has_enemy_near_x(tile, x, 0)
                    if has_enemy:
                        x += 1
                        continue
                    var has_heart: bool = _has_heart_near_x(tile, x, 1)
                    if has_heart:
                        x += 1
                        continue
                    var has_magnet: bool = _has_magnet_near_x(tile, x, 1)
                    if has_magnet:
                        x += 1
                        continue
                    var has_shield: bool = _has_shield_near_x(tile, x, 1)
                    if has_shield:
                        x += 1
                        continue
                    var has_double: bool = _has_double_coins_near_x(tile, x, 1)
                    if has_double:
                        x += 1
                        continue
                    var has_speed: bool = _has_speed_boost_near_x(tile, x, 1)
                    if has_speed:
                        x += 1
                        continue
                    var has_coin: bool = _has_coin_near_x(tile, x, powerup_coin_avoid_radius_tiles)
                    if has_coin:
                        x += 1
                        continue
                    best_x = x
                    break
            x += 1
        if best_x >= 0:
            var h_best: int = _get_ground_height_for_column(tile, best_x)
            if h_best >= 0:
                var top_y: int = -h_best
                var offset_tiles: float = max(height_offset, 0.0)
                var whole_tiles: int = int(floor(offset_tiles))
                var frac_tiles: float = offset_tiles - float(whole_tiles)
                var py: int = top_y - whole_tiles
                var cell: Vector2i = Vector2i(best_x, py)
                var local_pos: Vector2 = tile.map_to_local(cell)
                if frac_tiles != 0.0:
                    if tile.tile_set != null:
                        local_pos.y -= frac_tiles * float(tile.tile_set.tile_size.y)
                var pool: Array[Node2D] = []
                match kind:
                    "shield": pool = _shield_pool
                    "double_coins": pool = _double_pool
                    "speed_boost": pool = _speed_pool
                    "magnet": pool = _magnet_pool

                var inst: Node2D = _get_from_pool(pool, scene)
                if inst == null:
                    return false
                inst.scale = _calc_scale(scale_value, tile)

                var target_root: Node2D = root
                match kind:
                    "magnet":
                        var mr: Node2D = _get_magnets_root_for_tile(tile)
                        if mr: target_root = mr
                    "shield":
                        var sr: Node2D = _get_shields_root_for_tile(tile)
                        if sr: target_root = sr
                    "double_coins":
                        var dr: Node2D = _get_double_coins_root_for_tile(tile)
                        if dr: target_root = dr
                    "speed_boost":
                        var sbr: Node2D = _get_speed_boosts_root_for_tile(tile)
                        if sbr: target_root = sbr

                target_root.add_child(inst)
                inst.position = local_pos

                if inst.has_method("reset"):
                    inst.call("reset")
                return true
    return false

func request_emergency_shield(from_world_x: float, min_dist_px: float, max_dist_px: float) -> bool:
    return _request_emergency_powerup(from_world_x, min_dist_px, max_dist_px, "shield")

func request_emergency_double_coins(from_world_x: float, min_dist_px: float, max_dist_px: float) -> bool:
    return _request_emergency_powerup(from_world_x, min_dist_px, max_dist_px, "double_coins")

func request_emergency_speed_boost(from_world_x: float, min_dist_px: float, max_dist_px: float) -> bool:
    return _request_emergency_powerup(from_world_x, min_dist_px, max_dist_px, "speed_boost")

func _clear_coins_near_gaps(tile: TileMapLayer, gap_edges: Array[Vector2i]) -> void:
    var root: Node2D = _get_coins_root_for_tile(tile)
    if root == null:
        return
    if gap_edges.is_empty():
        return
    var buffer: int = 2
    var nodes_by_x: Dictionary = {}
    for c: Node in root.get_children():
        if not (c is Node2D):
            continue
        var coin_node: Node2D = c as Node2D
        var cell: Vector2i = tile.local_to_map(coin_node.position)
        var x_key: int = cell.x
        if not nodes_by_x.has(x_key):
            nodes_by_x[x_key] = []
        var arr: Array = nodes_by_x[x_key]
        arr.append(coin_node)
        nodes_by_x[x_key] = arr
    if nodes_by_x.is_empty():
        return
    var xs: Array = nodes_by_x.keys()
    xs.sort()
    var groups: Array[Vector2i] = []
    var start_x: int = int(xs[0])
    var end_x: int = int(xs[0])
    for i: int in range(1, xs.size()):
        var x: int = int(xs[i])
        if x <= end_x + 1:
            end_x = x
        else:
            groups.append(Vector2i(start_x, end_x))
            start_x = x
            end_x = x
    groups.append(Vector2i(start_x, end_x))
    var ranges_to_remove: Array[Vector2i] = []
    for gr: Vector2i in groups:
        var gs_group: int = gr.x
        var ge_group: int = gr.y
        var remove_group: bool = false
        for gap: Vector2i in gap_edges:
            var gs: int = gap.x
            var ge: int = gap.y
            var x_min: int = gs - buffer
            var x_max: int = ge + buffer
            if ge_group >= x_min and gs_group <= x_max:
                remove_group = true
                break
        if remove_group:
            ranges_to_remove.append(gr)
    for gr2: Vector2i in ranges_to_remove:
        var rs: int = gr2.x
        var re: int = gr2.y
        for x2: int in range(rs, re + 1):
            if nodes_by_x.has(x2):
                var arr2: Array = nodes_by_x[x2]
                for n: Node2D in arr2:
                    _return_to_pool(n, _coin_pool)

func _clear_lonely_peak_coins(tile: TileMapLayer) -> void:
    var root: Node2D = _get_coins_root_for_tile(tile)
    if root == null:
        return
    var nodes_by_x: Dictionary = {}
    for c: Node in root.get_children():
        if not (c is Node2D):
            continue
        var coin_node: Node2D = c as Node2D
        var cell: Vector2i = tile.local_to_map(coin_node.position)
        nodes_by_x[cell.x] = {
            "node": coin_node,
            "y": cell.y,
        }
    if nodes_by_x.is_empty():
        return
    var xs: Array = nodes_by_x.keys()
    xs.sort()
    var to_remove: Array[Node2D] = []
    for x: int in xs:
        var entry: Dictionary = nodes_by_x[x]
        var y: int = int(entry["y"])
        var has_left: bool = nodes_by_x.has(x - 1)
        var has_right: bool = nodes_by_x.has(x + 1)
        if not has_left and not has_right:
            continue
        var higher_left: bool = false
        var higher_right: bool = false
        if has_left:
            var left_entry: Dictionary = nodes_by_x[x - 1]
            var left_y: int = int(left_entry["y"])
            if y < left_y:
                higher_left = true
        if has_right:
            var right_entry: Dictionary = nodes_by_x[x + 1]
            var right_y: int = int(right_entry["y"])
            if y < right_y:
                higher_right = true
        var is_peak: bool = false
        if has_left and has_right:
            is_peak = higher_left and higher_right
        elif has_left:
            is_peak = higher_left
        elif has_right:
            is_peak = higher_right

        if is_peak:
            to_remove.append(entry["node"])

    for n: Node2D in to_remove:
        _return_to_pool(n, _coin_pool)

func _clear_enemies_near_gaps(tile: TileMapLayer, gap_edges: Array[Vector2i]) -> void:
    var root: Node2D = _get_enemies_root_for_tile(tile)
    if root == null:
        return
    if gap_edges.is_empty():
        return
    for c: Node in root.get_children():
        if not (c is Node2D):
            continue
        var enemy_node: Node2D = c as Node2D
        var name_str: String = enemy_node.name
        var buffer: int = 0
        if name_str.begins_with("EnemyBlock"):
            buffer = max(enemy_gap_safe_buffer_block, 0)
        elif name_str.begins_with("EnemyCone"):
            buffer = max(enemy_gap_safe_buffer_cone, 0)
        if buffer <= 0:
            continue
        var cell: Vector2i = tile.local_to_map(enemy_node.position)
        var x_cell: int = cell.x
        var remove_enemy: bool = false
        for gap: Vector2i in gap_edges:
            var gs: int = gap.x
            var ge: int = gap.y
            var x_min: int = gs - buffer
            var x_max: int = ge + buffer
            if x_cell >= x_min and x_cell <= x_max:
                remove_enemy = true
                break
        if remove_enemy:
            var pool_to_use: Array[Node2D] = []
            if name_str.begins_with("EnemyBlock"):
                pool_to_use = _enemy_block_pool
            elif name_str.begins_with("EnemyCone"):
                pool_to_use = _enemy_cone_pool

            if not pool_to_use.is_empty() or name_str.begins_with("Enemy"):
                 _return_to_pool(enemy_node, pool_to_use)
            else:
                 enemy_node.queue_free()

func _clear_short_coin_groups(tile: TileMapLayer) -> void:
    var root: Node2D = _get_coins_root_for_tile(tile)
    if root == null:
        return
    var min_len: int = max(coin_group_min_len, 1)
    if min_len <= 1:
        return
    var nodes_by_x: Dictionary = {}
    for c: Node in root.get_children():
        if not (c is Node2D):
            continue
        var coin_node: Node2D = c as Node2D
        var cell: Vector2i = tile.local_to_map(coin_node.position)
        var x_key: int = cell.x
        if not nodes_by_x.has(x_key):
            nodes_by_x[x_key] = []
        var arr: Array = nodes_by_x[x_key]
        arr.append(coin_node)
        nodes_by_x[x_key] = arr
    if nodes_by_x.is_empty():
        return
    var xs: Array = nodes_by_x.keys()
    xs.sort()
    var groups: Array[Vector2i] = []
    var start_x: int = int(xs[0])
    var end_x: int = int(xs[0])
    for i: int in range(1, xs.size()):
        var x: int = int(xs[i])
        if x <= end_x + 1:
            end_x = x
        else:
            groups.append(Vector2i(start_x, end_x))
            start_x = x
            end_x = x
    groups.append(Vector2i(start_x, end_x))
    for gr: Vector2i in groups:
        var gs: int = gr.x
        var ge: int = gr.y
        var length: int = ge - gs + 1
        if length < min_len:
            for x2: int in range(gs, ge + 1):
                if nodes_by_x.has(x2):
                    var arr2: Array = nodes_by_x[x2]
                    for n: Node2D in arr2:
                        _return_to_pool(n, _coin_pool)

func _ensure_editor_preview_for_tile(tile: TileMapLayer) -> void:
    var coins_root: Node2D = _get_coins_root_for_tile(tile)
    var enemies_root: Node2D = _get_enemies_root_for_tile(tile)
    var has_any: bool = false
    if coins_root != null and coins_root.get_child_count() > 0:
        has_any = true
    if enemies_root != null and enemies_root.get_child_count() > 0:
        has_any = true
    if has_any:
        return
    var h_base: int = clamp(0, min_height_tiles, max_height_tiles)
    var mid: int = int(segment_tile_count / 2.0)
    var x_coin: int = clamp(mid, 0, max(segment_tile_count - 1, 0))
    var x_enemy: int = clamp(mid + 4, 0, max(segment_tile_count - 1, 0))
    _spawn_coin_for_column(tile, x_coin, h_base)
    _spawn_enemy_for_column(tile, x_enemy, h_base)

func _select_coin_pattern() -> void:
    _coin_pattern_index = 0
    if not coin_zigzag_enabled or coin_zigzag_amplitude_tiles <= 0.0:
        _coin_pattern_type = 0
        return
    match coin_pattern_mode:
        0:
            var r: float = _rng.randf()
            if r < 0.33:
                _coin_pattern_type = 1
            elif r < 0.66:
                _coin_pattern_type = 2
            else:
                _coin_pattern_type = 3
        1:
            _coin_pattern_type = 1
        2:
            _coin_pattern_type = 2
        3:
            _coin_pattern_type = 3
        _:
            _coin_pattern_type = 2
    if _coin_pattern_type == 2:
        var group_len: int = max(_coin_group_len_current, 1)
        _flat_top_start_index = 0
        _flat_top_end_index = max(group_len - 1, 0)
        if group_len >= 3:
            var flat_min: int = max(coin_flat_top_min_len, 1)
            var flat_max: int = max(coin_flat_top_max_len, flat_min)
            var max_allowed: int = max(group_len - 2, 1)
            flat_max = min(flat_max, max_allowed)
            if flat_min > flat_max:
                flat_min = flat_max
            var flat_len: int = flat_max
            if flat_max > flat_min:
                flat_len = _rng.randi_range(flat_min, flat_max)
            var remainder: int = group_len - flat_len
            var up_len: int = int(remainder / 2.0)
            var flat_start: int = up_len
            var flat_end: int = flat_start + flat_len - 1
            _flat_top_start_index = flat_start
            _flat_top_end_index = flat_end

func _spawn_coin_for_column(tile: TileMapLayer, x: int, height: int, ignore_max_limit: bool = false) -> void:
    if coin_scene == null:
        return
    var root: Node2D = _get_coins_root_for_tile(tile)
    if root == null:
        return
    var max_coins: int = _scale_max_children(coin_max_children)
    if not ignore_max_limit and max_coins > 0 and root.get_child_count() >= max_coins:
        return
    var seg_id: String = "A"
    if tile == _tile_b:
        seg_id = "B"
    var top_y: int = -height
    var offset_tiles: float = max(coin_height_offset_tiles, 0.0)
    if coin_zigzag_enabled and coin_zigzag_amplitude_tiles > 0.0:
        if _coin_pattern_type == 1:
            var levels_tri: int = max(coin_zigzag_levels, 2)
            var group_len_tri: int = max(_coin_group_len_current, 1)
            if group_len_tri >= 3:
                var idx_tri: int = clamp(_coin_pattern_index, 0, group_len_tri - 1)
                var denom_tri: float = float(max(group_len_tri - 1, 1))
                var t_tri: float = float(idx_tri) / denom_tri
                var h_tri: float = 4.0 * t_tri * (1.0 - t_tri)
                var level_tri: int = int(round(h_tri * float(levels_tri - 1)))
                level_tri = clamp(level_tri, 0, levels_tri - 1)
                offset_tiles += float(level_tri) * coin_zigzag_amplitude_tiles
        elif _coin_pattern_type == 2:
            var levels: int = max(coin_zigzag_levels, 2)
            var group_len: int = max(_coin_group_len_current, 1)
            var idx: int = clamp(_coin_pattern_index, 0, group_len - 1)
            var level: int = 0
            if group_len < 3:
                level = levels - 1
            else:
                var flat_start: int = max(_flat_top_start_index, 0)
                var flat_end: int = min(_flat_top_end_index, group_len - 1)
                if flat_end < flat_start:
                    flat_end = flat_start
                var up_len: int = flat_start
                var down_len: int = max(group_len - flat_end - 1, 0)
                if idx < flat_start and up_len > 0:
                    if up_len == 1:
                        level = levels - 2
                    else:
                        var denom_up: float = float(max(up_len - 1, 1))
                        var f_up: float = float(idx) / denom_up
                        level = int(floor(f_up * float(levels - 1)))
                elif idx >= flat_start and idx <= flat_end:
                    level = levels - 1
                elif idx > flat_end and down_len > 0:
                    var idx_fall: int = idx - (flat_end + 1)
                    if down_len == 1:
                        level = levels - 2
                    else:
                        var denom_down: float = float(max(down_len - 1, 1))
                        var f_down: float = float(idx_fall) / denom_down
                        level = int(floor((1.0 - f_down) * float(levels - 1)))
            level = clamp(level, 0, levels - 1)
            offset_tiles += float(level) * coin_zigzag_amplitude_tiles
        elif _coin_pattern_type == 3:
            pass
    var whole_tiles: int = int(floor(offset_tiles))
    var frac_tiles: float = offset_tiles - float(whole_tiles)
    var coin_y: int = top_y - whole_tiles
    var cell: Vector2i = Vector2i(x, coin_y)
    var local_pos: Vector2 = tile.map_to_local(cell)
    if frac_tiles != 0.0:
        if tile.tile_set != null:
            local_pos.y -= frac_tiles * float(tile.tile_set.tile_size.y)

    for c: Node in root.get_children():
        if not (c is Node2D):
            continue
        var existing: Node2D = c as Node2D
        if existing.position.distance_to(local_pos) < 1.0:
            return

    var coin: Node2D = _get_from_pool(_coin_pool, coin_scene)
    if coin == null:
        return
    coin.scale = _calc_scale(coin_scale, tile)
    if coin.has_method("set"):
        coin.set("source_segment", seg_id)
    coin.position = local_pos
    root.add_child(coin)

    if coin.has_method("reset"):
        coin.call("reset")
    if coin_zigzag_enabled and coin_zigzag_amplitude_tiles > 0.0:
        _coin_pattern_index += 1

    var main: Node = _get_main_node()
    if main and main.has_method("on_coin_collected") and coin.has_signal("collected"):
        if not coin.collected.is_connected(Callable(main, "on_coin_collected")):
            coin.collected.connect(Callable(main, "on_coin_collected"))

func _spawn_diamond_for_column(tile: TileMapLayer, x: int, height: int, ignore_limit: bool = false) -> void:
    if diamond_scene == null:
        return
    var root: Node2D = _get_diamonds_root_for_tile(tile)
    if root == null:
        return
    var max_d: int = diamond_max_children
    if max_d > 0 and not ignore_limit and root.get_child_count() >= max_d:
        return
    var seg_id: String = "A"
    if tile == _tile_b:
        seg_id = "B"
    var top_y: int = -height
    var offset_tiles: float = max(diamond_height_offset_tiles, 0.0)
    var high_ratio: float = clamp(diamond_high_spawn_ratio, 0.0, 1.0)
    if high_ratio > 0.0 and _rng.randf() < high_ratio:
        var extra_min: float = max(diamond_high_extra_offset_min_tiles, 0.0)
        var extra_max: float = max(diamond_high_extra_offset_max_tiles, extra_min)
        offset_tiles += _rng.randf_range(extra_min, extra_max)
    var whole_tiles: int = int(floor(offset_tiles))
    var frac_tiles: float = offset_tiles - float(whole_tiles)
    var dy: int = top_y - whole_tiles
    var cell: Vector2i = Vector2i(x, dy)
    var local_pos: Vector2 = tile.map_to_local(cell)
    if frac_tiles != 0.0:
        if tile.tile_set != null:
            local_pos.y -= frac_tiles * float(tile.tile_set.tile_size.y)

    for c2: Node in root.get_children():
        if not (c2 is Node2D):
            continue
        var existing: Node2D = c2 as Node2D
        if existing.position.distance_to(local_pos) < 1.0:
            return

    var diamond: Node2D = _get_from_pool(_diamond_pool, diamond_scene)
    if diamond == null:
        return
    diamond.scale = _calc_scale(diamond_scale, tile)
    if diamond.has_method("set"):
        diamond.set("source_segment", seg_id)
        var a: int = diamond_amount
        if a <= 0:
            a = 1
        diamond.set("amount", a)
        diamond.set("currency", "gems")
    diamond.position = local_pos
    root.add_child(diamond)

    if diamond.has_method("reset"):
        diamond.call("reset")
    var main: Node = _get_main_node()
    if main and main.has_method("on_coin_collected") and diamond.has_signal("collected"):
        if not diamond.collected.is_connected(Callable(main, "on_coin_collected")):
            diamond.collected.connect(Callable(main, "on_coin_collected"))

func _spawn_heart_for_column(tile: TileMapLayer, x: int, height: int, ignore_limit: bool = false) -> void:
    if heart_scene == null:
        return
    var root: Node2D = _get_hearts_root_for_tile(tile)
    if root == null:
        root = _get_coins_root_for_tile(tile)
    if root == null:
        return
    var max_hearts: int = _scale_max_children(heart_max_children)
    if max_hearts > 0 and not ignore_limit:
        var count: int = 0
        for c: Node in root.get_children():
            if c is HeartPickup or c.is_in_group("heart_pickup"):
                count += 1
        if count >= max_hearts:
            return

    if not ignore_limit:
        var main: Node = _get_main_node()
        if main != null and main.has_method("can_spawn_hearts"):
            if not main.call("can_spawn_hearts"):
                if OS.is_debug_build():
                    print("[InfiniteGround] Heart spawn blocked in _spawn_heart_for_column (Health Full)")
                return
    var top_y: int = -height
    var offset_tiles: float = max(heart_height_offset_tiles, 0.0)
    var whole_tiles: int = int(floor(offset_tiles))
    var frac_tiles: float = offset_tiles - float(whole_tiles)
    var heart_y: int = top_y - whole_tiles
    var cell: Vector2i = Vector2i(x, heart_y)
    var local_pos: Vector2 = tile.map_to_local(cell)
    if frac_tiles != 0.0:
        if tile.tile_set != null:
            local_pos.y -= frac_tiles * float(tile.tile_set.tile_size.y)

    for c2: Node in root.get_children():
        if not (c2 is Node2D):
            continue
        var existing: Node2D = c2 as Node2D
        if existing.position.distance_to(local_pos) < 1.0:
            return

    var heart: Node2D = _get_from_pool(_heart_pool, heart_scene)
    if heart == null:
        return
    heart.scale = _calc_scale(coin_scale * heart_scale, tile)
    heart.position = local_pos
    root.add_child(heart)

    if heart.has_method("reset"):
        heart.call("reset")
    var distance_tiles_check: int = _tiles_since_last_heart
    _tiles_since_last_heart = 0

    _debug_heart_spawn_session_count += 1

    var dist_px_est: float = float(distance_tiles_check) * _tile_w_px

    print("DEBUG_HEART_SPAWN: #%d | x=%d | Dist: %d tiles (approx %.2f px) | Scale: %.2f | Emergency: %s" % [_debug_heart_spawn_session_count, x, distance_tiles_check, dist_px_est, heart.scale.x, str(ignore_limit)])

    if OS.is_debug_build():
        print("[InfiniteGround] Heart spawned at column %d. Scale: %.2f" % [x, heart.scale.x])

func _spawn_enemy_for_column(tile: TileMapLayer, x: int, height: int) -> void:
    var root: Node2D = _get_enemies_root_for_tile(tile)
    if root == null:
        return
    var max_enemies: int = _scale_max_children(enemy_max_children)
    if max_enemies > 0 and root.get_child_count() >= max_enemies:
        return
    var entries: Array[Dictionary] = []
    if enemy_allow_block and enemy_block_scene != null and enemy_block_weight > 0.0:
        entries.append({"scene": enemy_block_scene, "weight": enemy_block_weight})
    if enemy_allow_cone and enemy_cone_scene != null and enemy_cone_weight > 0.0:
        entries.append({"scene": enemy_cone_scene, "weight": enemy_cone_weight})
    if entries.is_empty():
        return
    var enemy_scene: PackedScene = null
    if entries.size() == 1:
        enemy_scene = entries[0]["scene"] as PackedScene
    else:
        var total_w: float = 0.0
        for e: Dictionary in entries:
            total_w += float(e["weight"])
        if total_w <= 0.0:
            return
        var r: float = _rng.randf() * total_w
        var acc: float = 0.0
        for e2: Dictionary in entries:
            acc += float(e2["weight"])
            if r <= acc:
                enemy_scene = e2["scene"] as PackedScene
                break
    if enemy_scene == null:
        return
    var top_y: int = -height
    var cell: Vector2i = Vector2i(x, top_y)
    var local_pos: Vector2 = tile.map_to_local(cell)

    var enemy: Node2D = null
    if enemy_scene == enemy_block_scene:
        enemy = _get_from_pool(_enemy_block_pool, enemy_block_scene)
    elif enemy_scene == enemy_cone_scene:
        enemy = _get_from_pool(_enemy_cone_pool, enemy_cone_scene)

    if enemy == null:
        return

    enemy.scale = _calc_scale(enemy_scale, tile)
    root.add_child(enemy)

    if enemy.has_method("reset"):
        enemy.call("reset")

    var ground_top_y: float = local_pos.y
    if tile.tile_set != null:
        ground_top_y -= (float(tile.tile_set.tile_size.y) * 0.5)
    var final_pos_local: Vector2 = Vector2(local_pos.x, ground_top_y)

    var hitbox_cs: CollisionShape2D = enemy.get_node_or_null("Hitbox/CollisionShape2D") as CollisionShape2D
    if hitbox_cs != null and hitbox_cs.shape is RectangleShape2D:
        var rect: RectangleShape2D = hitbox_cs.shape as RectangleShape2D
        var bottom_local: float = hitbox_cs.position.y + rect.size.y * 0.5
        var scale_y: float = enemy.scale.y
        final_pos_local.y -= bottom_local * scale_y

    if enemy_y_offset_tiles != 0.0:
        if tile.tile_set != null:
            final_pos_local.y -= enemy_y_offset_tiles * float(tile.tile_set.tile_size.y)

    enemy.position = final_pos_local

func _calc_scale(base: float, tile: TileMapLayer) -> Vector2:
    var s: float = base
    if is_instance_valid(tile) and tile.scale.x != 0.0:
        s /= tile.scale.x
    return Vector2.ONE * s

func _clear_collision_for_tile(tile: TileMapLayer) -> void:
    if Engine.is_editor_hint():
        return
    var root := tile.get_node_or_null("CollisionBodies") as Node2D
    if root == null:
        return
    for child: Node in root.get_children():
        root.remove_child(child)
        child.free()

func _ensure_collision_root(tile: TileMapLayer) -> Node2D:
    var root := tile.get_node_or_null("CollisionBodies") as Node2D
    if root == null:
        root = Node2D.new()
        root.name = "CollisionBodies"
        tile.add_child(root)
    root.position = Vector2.ZERO
    root.scale = Vector2.ONE
    return root

func _add_collision_for_cell(tile: TileMapLayer, cell: Vector2i) -> void:
    if Engine.is_editor_hint():
        return
    if tile.tile_set == null:
        return
    var root: Node2D = _ensure_collision_root(tile)
    var body: StaticBody2D = StaticBody2D.new()
    body.collision_layer = 1
    body.collision_mask = 2
    root.add_child(body)
    var shape_node: CollisionShape2D = CollisionShape2D.new()
    body.add_child(shape_node)
    var rect: RectangleShape2D = RectangleShape2D.new()
    var cell_size: Vector2 = Vector2(tile.tile_set.tile_size)
    rect.size = cell_size
    shape_node.shape = rect
    body.position = (Vector2(cell.x, cell.y) + Vector2(0.5, 0.5)) * cell_size

func _place_ground_column(tile: TileMapLayer, x: int, height: int) -> void:
    if tile == null:
        return
    var top_y: int = -height
    var source_top: int = 2
    var source_fill: int = 1
    var top_cell: Vector2i = Vector2i(x, top_y)
    tile.set_cell(top_cell, source_top, Vector2i(0, 0))
    _add_collision_for_cell(tile, top_cell)
    var fill_depth: int = 3
    var d: int = 1
    while d <= fill_depth:
        var y: int = top_y + d
        var fill_cell: Vector2i = Vector2i(x, y)
        tile.set_cell(fill_cell, source_fill, Vector2i(0, 0))
        _add_collision_for_cell(tile, fill_cell)
        d += 1

func _get_ground_height_for_column(tile: TileMapLayer, x: int) -> int:
    if tile == null:
        return -1
    var max_h: int = int(max_height_tiles)
    var min_h: int = int(min_height_tiles)
    if max_h < min_h:
        var tmp: int = max_h
        max_h = min_h
        min_h = tmp
    var h: int = max_h
    while h >= min_h:
        var top_y: int = -h
        var cell: Vector2i = Vector2i(x, top_y)
        var src_id: int = tile.get_cell_source_id(cell)
        if src_id != -1:
            return h
        h -= 1
    return -1

func _run_generate_now(reset_flat: bool = false, reset_height: bool = false) -> void:
    _initialized = false
    _ensure_initialized()
    if reset_flat:
        _flat_start_runtime_initialized = false
        if _tile_flat_start != null and _initial_positions_captured:
            _tile_flat_start.position = _initial_flat_start_pos
    _ensure_flat_start_tiles()
    if reset_height:
        _height_a = 0
        _height_b = 0
    if _tile_a != null:
        _height_a = _generate_segment(_tile_a, 0)
        if _initial_positions_captured:
            _tile_a.position = _initial_tile_a_pos
        else:
            _tile_a.position.x = 0.0
        _sync_containers_for_tile(_tile_a)
    if _tile_b != null:
        _height_b = _generate_segment(_tile_b, _height_a)
        if _initial_positions_captured:
            _tile_b.position = _initial_tile_b_pos
        else:
            _tile_b.position.x = float(_seg_width_px - _seg_overlap_px)
        _sync_containers_for_tile(_tile_b)
    _align_segments_with_flat_start()
    _apply_debug_tint()

func restart_from_flat_start() -> void:
    _run_generate_now(true, true)

func set_speed(new_speed: float) -> void:
    var v: float = clamp(new_speed, min_scroll_speed, max_scroll_speed)
    _target_speed = v
    if not _runtime_use_acceleration:
        scroll_speed = v

func get_speed() -> float:
    return scroll_speed

func set_speed_limits(min_s: float, max_s: float) -> void:
    min_scroll_speed = min_s
    max_scroll_speed = max_s
    _target_speed = clamp(_target_speed, min_scroll_speed, max_scroll_speed)
    scroll_speed = clamp(scroll_speed, min_scroll_speed, max_scroll_speed)

func set_instant_speed_mode(enabled: bool) -> void:
    if enabled:
        _runtime_use_acceleration = false
    else:
        _runtime_use_acceleration = _base_use_acceleration

func set_movement_enabled(enabled: bool) -> void:
    movement_enabled = enabled

func get_active_segment_name() -> String:
    if not is_inside_tree():
        return ""
    var vp: Viewport = get_viewport()
    if vp == null:
        return ""
    var cam: Camera2D = vp.get_camera_2d()
    var px: float = 0.0
    if cam != null:
        px = cam.global_position.x
    else:
        px = 0.0
    var seg: Node2D = null
    if _tile_a != null:
        var ax: float = _tile_a.global_position.x
        var ax2: float = ax + float(_seg_width_px)
        if px >= ax and px <= ax2:
            seg = _tile_a
    if seg == null and _tile_b != null:
        var bx: float = _tile_b.global_position.x
        var bx2: float = bx + float(_seg_width_px)
        if px >= bx and px <= bx2:
            seg = _tile_b
    if seg == null:
        return ""
    return seg.name

func get_spawn_status() -> Dictionary:
    var s: Dictionary = {}
    var coins_root_a: Node2D = _coins_a
    var coins_root_b: Node2D = _coins_b
    var enemies_root_a: Node2D = _enemies_a
    var enemies_root_b: Node2D = _enemies_b
    var coins_spawned: bool = false
    var hearts_spawned: bool = false
    var enemies_spawned: bool = false
    var coin_roots: Array[Node2D] = []
    if coins_root_a != null:
        coin_roots.append(coins_root_a)
    if coins_root_b != null:
        coin_roots.append(coins_root_b)
    for r: Node2D in coin_roots:
        for c: Node in r.get_children():
            if c is Node2D:
                if c is HeartPickup:
                    hearts_spawned = true
                else:
                    coins_spawned = true
    var enemy_roots: Array[Node2D] = []
    if enemies_root_a != null:
        enemy_roots.append(enemies_root_a)
    if enemies_root_b != null:
        enemy_roots.append(enemies_root_b)
    for er: Node2D in enemy_roots:
        if er.get_child_count() > 0:
            enemies_spawned = true
            break
    s["coins"] = coins_spawned
    s["hearts"] = hearts_spawned
    s["enemies"] = enemies_spawned
    return s

func _apply_debug_tint() -> void:
    if not debug_tint_enabled:
        if _tile_a != null:
            _tile_a.modulate = Color(1, 1, 1, 1)
        if _tile_b != null:
            _tile_b.modulate = Color(1, 1, 1, 1)
        if _tile_flat_start != null:
            _tile_flat_start.modulate = Color(1, 1, 1, 1)
        return
    if _tile_a != null:
        _tile_a.modulate = debug_color_a
    if _tile_b != null:
        _tile_b.modulate = debug_color_b
    if _tile_flat_start != null:
        _tile_flat_start.modulate = debug_color_flat_start
