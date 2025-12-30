@tool
extends Node2D

## Aktif/nonaktif gerakan scroll ground.
@export var movement_enabled: bool = true
@export var regenerate_on_start: bool = true
## Kecepatan scroll ground (px/detik).
@export var scroll_speed: float = 250.0
## Percepatan menuju kecepatan target.
@export var acceleration: float = 24.0
## Jika true, perubahan kecepatan halus memakai acceleration.
@export var use_acceleration: bool = true
## Batas bawah kecepatan scroll.
@export var min_scroll_speed: float = 0.0
## Batas atas kecepatan scroll.
@export var max_scroll_speed: float = 600.0
## Jika true, segmen ground di-wrap tak hingga.
@export var wrap_infinite: bool = true
## Jika true, segmen yang di-wrap digenerate ulang polanya.
@export var regenerate_on_wrap: bool = true
## Jumlah tile awal yang dipaksa rata (tanpa gap/step).
@export var flat_start_tiles: int = 24
## Panjang satu segmen ground (A dan B) dalam jumlah tile.
@export var segment_tile_count: int = 612
@export var segment_tile_count_min: int = 612
@export var segment_tile_count_max: int = 612
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
## Seed tetap untuk RNG; 0 berarti acak setiap init.
@export var fixed_seed: int = 0
@export_group("Coins")
@export var coin_scene: PackedScene
@export var coin_spawn_chance: float = 1.0
@export var coin_max_children: int = 40
@export var coin_scale: float = 1.0
@export var coin_group_min_len: int = 3
@export var coin_group_max_len: int = 6
@export var coin_group_gap_min: int = 2
@export var coin_group_gap_max: int = 5
@export var coin_height_offset_tiles: float = 1.5
@export_subgroup("Pola / Zigzag")
@export var coin_zigzag_enabled: bool = true
@export var coin_zigzag_amplitude_tiles: float = 0.5
@export var coin_zigzag_levels: int = 3
@export var coin_flat_top_min_len: int = 2
@export var coin_flat_top_max_len: int = 4
@export_enum("RandomCampur", "LengkungNaikTurun", "NaikTanggaFlatAtas", "GarisDatar") var coin_pattern_mode: int = 0
@export_group("Hearts")
@export var heart_scene: PackedScene
@export var heart_spawn_chance: float = 0.02
@export var heart_max_children: int = 3
@export var heart_height_offset_tiles: float = 2.0
@export var heart_scale: float = 1.0
@export var heart_osc_amplitude_tiles: float = 0.5
@export var heart_osc_frequency: float = 1.0
@export var heart_min_distance_tiles: float = 6.0
@export_group("Magnet")
@export var magnet_scene: PackedScene
@export var magnet_spawn_chance: float = 0.05
@export var magnet_max_children: int = 1
@export var magnet_height_offset_tiles: float = 2.0
@export var magnet_min_distance_tiles: float = 12.0
@export var magnet_gap_tiles: int = 40
@export_group("Shield")
@export var shield_scene: PackedScene
@export var shield_spawn_chance: float = 0.05
@export var shield_max_children: int = 1
@export var shield_height_offset_tiles: float = 2.0
@export var shield_min_distance_tiles: float = 12.0
@export var shield_gap_tiles: int = 40
@export_group("DoubleCoins")
@export var double_coins_scene: PackedScene
@export var double_coins_spawn_chance: float = 0.02
@export var double_coins_max_children: int = 1
@export var double_coins_height_offset_tiles: float = 2.0
@export var double_coins_min_distance_tiles: float = 24.0
@export var double_coins_gap_tiles: int = 80
@export var powerup_min_distance_tiles: float = 24.0
@export var powerup_coin_avoid_radius_tiles: int = 0
@export_group("Enemies")
@export var enemy_block_scene: PackedScene
@export var enemy_cone_scene: PackedScene
@export var enemy_spawn_chance: float = 0.25
@export var enemy_max_children: int = 20
@export var enemy_min_platform_len: int = 4
@export var enemy_min_gap_between: int = 6
@export var enemy_y_offset_tiles: float = 0.0
@export var enemy_gap_safe_buffer_block: int = 2
@export var enemy_gap_safe_buffer_cone: int = 2
@export var enemy_block_weight: float = 1.0
@export var enemy_cone_weight: float = 1.0
@export var enemy_allow_block: bool = true
@export var enemy_allow_cone: bool = true

var _generate_now_internal: bool = false

@export var generate_now: bool:
    set(value):
        _generate_now_internal = value
        if value:
            _run_generate_now(true, true)
            _generate_now_internal = false
    get:
        return _generate_now_internal

var _tile_a: TileMapLayer = null
var _tile_b: TileMapLayer = null
var _coins_a: Node2D = null
var _coins_b: Node2D = null
var _enemies_a: Node2D = null
var _enemies_b: Node2D = null
var _seg_width_px: float = 0.0
var _seg_overlap_px: float = 1.0
var _tile_w_px: float = 0.0
var _tile_h_px: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _flat_tiles_remaining: int = 0
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
var _last_heart_x: float = -1.0e20
var _last_magnet_x: float = -1.0e20
var _last_shield_x: float = -1.0e20
var _last_double_coins_x: float = -1.0e20
var _last_powerup_x: float = -1.0e20

const _BASE_SEGMENT_TILES: int = 64

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
    if fixed_seed != 0:
        _rng.seed = fixed_seed
    else:
        _rng.randomize()

func _ready() -> void:
    _initialized = false
    _ensure_initialized()
    if Engine.is_editor_hint():
        if _tile_a:
            _height_a = 0
            _generate_segment(_tile_a, _height_a)
            _tile_a.position.x = 0.0
        if _tile_b:
            _height_b = 0
            _generate_segment(_tile_b, _height_b)
            _tile_b.position.x = _seg_width_px - _seg_overlap_px
        _apply_debug_tint()
        return
    if regenerate_on_start:
        if _tile_a:
            _height_a = 0
            _generate_segment(_tile_a, _height_a)
            _tile_a.position.x = 0.0
        if _tile_b:
            _height_b = 0
            _generate_segment(_tile_b, _height_b)
            _tile_b.position.x = _seg_width_px - _seg_overlap_px
    _apply_debug_tint()

func _ensure_initialized() -> void:
    if _initialized:
        return
    _setup_rng()
    if _tile_a == null:
        _tile_a = get_node_or_null("TileMapLayerA") as TileMapLayer
    if _tile_b == null:
        _tile_b = get_node_or_null("TileMapLayerB") as TileMapLayer
    if _coins_a == null:
        _coins_a = get_node_or_null("CoinsA") as Node2D
    if _coins_b == null:
        _coins_b = get_node_or_null("CoinsB") as Node2D
    if _enemies_a == null:
        _enemies_a = get_node_or_null("EnemiesA") as Node2D
    if _enemies_b == null:
        _enemies_b = get_node_or_null("EnemiesB") as Node2D
    if coin_scene == null:
        coin_scene = load("res://scenes/Coin.tscn")
    if heart_scene == null:
        heart_scene = load("res://scenes/HeartPickup.tscn")
    if magnet_scene == null:
        magnet_scene = load("res://scenes/MagnetPowerup.tscn")
    if shield_scene == null:
        shield_scene = load("res://scenes/ShieldPowerup.tscn")
    if double_coins_scene == null:
        double_coins_scene = load("res://scenes/DoubleCoinsPowerup.tscn")
    if enemy_block_scene == null:
        enemy_block_scene = load("res://scenes/EnemyBlock.tscn")
    if enemy_cone_scene == null:
        enemy_cone_scene = load("res://scenes/EnemyCone.tscn")
    if _tile_a and _tile_a.tile_set and (_tile_w_px <= 0.0 or _tile_h_px <= 0.0):
        var cell := _tile_a.tile_set.tile_size
        _tile_w_px = float(cell.x) * _tile_a.scale.x
        _tile_h_px = float(cell.y) * _tile_a.scale.y
    if _tile_w_px <= 0.0:
        _tile_w_px = 128.0
    if _tile_h_px <= 0.0:
        _tile_h_px = 128.0
    if segment_tile_count_min <= 0:
        segment_tile_count_min = max(segment_tile_count, 1)
    if segment_tile_count_max < segment_tile_count_min:
        segment_tile_count_max = segment_tile_count_min
    segment_tile_count = _rng.randi_range(segment_tile_count_min, segment_tile_count_max)
    if min_step_run_len < 1:
        min_step_run_len = 1
    if max_step_run_len < min_step_run_len:
        max_step_run_len = min_step_run_len
    _seg_width_px = _tile_w_px * float(segment_tile_count)
    _flat_tiles_remaining = max(flat_start_tiles, 0)
    _target_speed = scroll_speed
    _initialized = true

func _physics_process(delta: float) -> void:
    if Engine.is_editor_hint():
        return
    if not movement_enabled:
        return
    if use_acceleration:
        if scroll_speed < _target_speed:
            scroll_speed = min(scroll_speed + acceleration * delta, _target_speed)
        elif scroll_speed > _target_speed:
            scroll_speed = max(scroll_speed - acceleration * delta, _target_speed)
    if scroll_speed == 0.0:
        return
    var dx: float = scroll_speed * delta
    if _tile_a:
        _tile_a.position.x -= dx
    if _tile_b:
        _tile_b.position.x -= dx
    if _coins_a:
        _coins_a.position.x -= dx
    if _coins_b:
        _coins_b.position.x -= dx
    if _enemies_a:
        _enemies_a.position.x -= dx
    if _enemies_b:
        _enemies_b.position.x -= dx
    if wrap_infinite:
        _handle_wrap()

func _handle_wrap() -> void:
    if _tile_a == null or _tile_b == null:
        return
    var left := _tile_a
    var right := _tile_b
    if left.position.x > right.position.x:
        left = _tile_b
        right = _tile_a
    var left_end: float = left.position.x + _seg_width_px
    if left_end < -_seg_width_px * 0.25:
        var old_x: float = left.position.x
        left.position.x = right.position.x + _seg_width_px - _seg_overlap_px
        var dx_wrap: float = left.position.x - old_x
        if left == _tile_a and _coins_a:
            _coins_a.position.x += dx_wrap
        elif left == _tile_b and _coins_b:
            _coins_b.position.x += dx_wrap
        if left == _tile_a and _enemies_a:
            _enemies_a.position.x += dx_wrap
        elif left == _tile_b and _enemies_b:
            _enemies_b.position.x += dx_wrap
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
    _clear_enemies_for_tile(tile)
    tile.clear()
    var current_height: int = clamp(start_height, min_height_tiles, max_height_tiles)
    var gap_edges: Array = []
    var gap_remaining: int = 0
    var last_was_gap: bool = false
    var ground_run_len: int = 0
    var height_run_len: int = 0
    var coin_group_remaining: int = 0
    var coin_gap_remaining: int = 0
    var coin_pending_gap_len: int = 0
    var enemy_gap_remaining: int = 0
    var heart_gap_remaining: int = 0
    var magnet_gap_remaining: int = 0
    var shield_gap_remaining: int = 0
    var double_coins_gap_remaining: int = 0
    var powerup_gap_remaining: int = 0
    var enemy_columns: Array = []
    var i: int = 0
    while i < segment_tile_count:
        var flat_override: bool = _flat_tiles_remaining > 0
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
        var coins_allowed: bool = not flat_override
        if coins_allowed:
            var group_enabled: bool = coin_group_max_len >= coin_group_min_len and coin_group_max_len > 0 and coin_spawn_chance > 0.0
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
                    var rc: float = _rng.randf()
                    if rc <= coin_spawn_chance:
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
                if coin_spawn_chance > 0.0 and _rng.randf() <= coin_spawn_chance:
                    do_spawn_coin = true
        if do_spawn_coin:
            _spawn_coin_for_column(tile, i, current_height)
        var do_spawn_enemy: bool = false
        var enemies_allowed: bool = not flat_override and not do_spawn_coin
        if enemies_allowed and enemy_spawn_chance > 0.0:
            if enemy_gap_remaining > 0:
                enemy_gap_remaining -= 1
            else:
                var run_len_after: int = ground_run_len + 1
                if run_len_after >= enemy_min_platform_len:
                    if _rng.randf() <= enemy_spawn_chance:
                        do_spawn_enemy = true
                        enemy_gap_remaining = max(enemy_min_gap_between, 0)
        if do_spawn_enemy:
            _spawn_enemy_for_column(tile, i, current_height)
            enemy_columns.append(i)
        var do_spawn_heart: bool = false
        var hearts_allowed: bool = not flat_override and not do_spawn_coin and not do_spawn_enemy and not _is_near_enemy(i, enemy_columns, 1) and not _is_player_health_full()
        if hearts_allowed and heart_scene != null and heart_spawn_chance > 0.0:
            if heart_gap_remaining > 0:
                heart_gap_remaining -= 1
            else:
                if _rng.randf() <= heart_spawn_chance:
                    do_spawn_heart = true
                    heart_gap_remaining = 40
        var do_spawn_shield: bool = false
        var shields_allowed: bool = not flat_override and not do_spawn_coin and not do_spawn_enemy and shield_scene != null and shield_spawn_chance > 0.0 and not _is_near_enemy(i, enemy_columns, 1) and not _has_coin_near_x(tile, i, powerup_coin_avoid_radius_tiles)
        if shields_allowed:
            if shield_gap_remaining > 0:
                shield_gap_remaining -= 1
            else:
                if _rng.randf() <= shield_spawn_chance:
                    do_spawn_shield = true
                    shield_gap_remaining = max(shield_gap_tiles, 0)
        var do_spawn_magnet: bool = false
        var magnets_allowed: bool = not flat_override and not do_spawn_coin and not do_spawn_enemy and not do_spawn_heart and not do_spawn_shield and magnet_scene != null and magnet_spawn_chance > 0.0 and not _is_near_enemy(i, enemy_columns, 1) and not _has_coin_near_x(tile, i, powerup_coin_avoid_radius_tiles)
        if magnets_allowed:
            if magnet_gap_remaining > 0:
                magnet_gap_remaining -= 1
            else:
                if _rng.randf() <= magnet_spawn_chance:
                    do_spawn_magnet = true
                    magnet_gap_remaining = max(magnet_gap_tiles, 0)
        var do_spawn_double_coins: bool = false
        var double_coins_allowed: bool = not flat_override and not do_spawn_coin and not do_spawn_enemy and not do_spawn_heart and not do_spawn_magnet and not do_spawn_shield and double_coins_scene != null and double_coins_spawn_chance > 0.0 and not _is_near_enemy(i, enemy_columns, 1) and not _is_double_coins_active() and not _has_coin_near_x(tile, i, powerup_coin_avoid_radius_tiles)
        if double_coins_allowed:
            if double_coins_gap_remaining > 0:
                double_coins_gap_remaining -= 1
            else:
                if _rng.randf() <= double_coins_spawn_chance:
                    do_spawn_double_coins = true
                    double_coins_gap_remaining = max(double_coins_gap_tiles, 0)
        var any_powerup_spawned: bool = false
        if powerup_gap_remaining > 0:
            if do_spawn_heart or do_spawn_shield or do_spawn_magnet or do_spawn_double_coins:
                do_spawn_heart = false
                do_spawn_shield = false
                do_spawn_magnet = false
                do_spawn_double_coins = false
            powerup_gap_remaining -= 1
        if do_spawn_heart:
            _spawn_heart_for_column(tile, i, current_height)
            any_powerup_spawned = true
        if do_spawn_shield:
            _spawn_shield_for_column(tile, i, current_height)
            any_powerup_spawned = true
        if do_spawn_magnet:
            _spawn_magnet_for_column(tile, i, current_height)
            any_powerup_spawned = true
        if do_spawn_double_coins:
            _spawn_double_coins_for_column(tile, i, current_height)
            any_powerup_spawned = true
        if any_powerup_spawned:
            powerup_gap_remaining = max(int(powerup_min_distance_tiles), 0)
        if flat_override and _flat_tiles_remaining > 0:
            _flat_tiles_remaining -= 1
        last_was_gap = false
        ground_run_len += 1
        height_run_len += 1
        i += 1
    if not gap_edges.is_empty():
        _clear_coins_near_gaps(tile, gap_edges)
        _clear_enemies_near_gaps(tile, gap_edges)
    _clear_lonely_peak_coins(tile)
    _clear_short_coin_groups(tile)
    if Engine.is_editor_hint():
        _ensure_editor_preview_for_tile(tile)
    return current_height

func _is_near_enemy(tile_x: int, enemy_columns: Array, buffer: int) -> bool:
    var b: int = max(buffer, 0)
    if enemy_columns.is_empty() or b <= 0:
        return false
    for ex in enemy_columns:
        var e: int = int(ex)
        if abs(tile_x - e) <= b:
            return true
    return false

func _is_player_health_full() -> bool:
    var gm := _get_main_node()
    if gm == null:
        return false
    var p := gm.get_node_or_null("Player")
    if p == null:
        return false
    var max_h: int = 0
    var cur_h: int = 0
    if p.has_method("get"):
        max_h = int(p.get("max_health"))
        cur_h = int(p.get("current_health"))
    if max_h <= 0:
        return false
    return cur_h >= max_h

func _is_double_coins_active() -> bool:
    var gm := _get_main_node()
    if gm == null:
        return false
    if gm.has_method("is_double_coins_active"):
        return gm.is_double_coins_active()
    return false

func _too_close_to_last_powerup(world_x: float) -> bool:
    if powerup_min_distance_tiles <= 0.0:
        return false
    var min_px: float = powerup_min_distance_tiles * _tile_w_px
    if min_px <= 0.0:
        return false
    if _last_powerup_x <= -1.0e19:
        return false
    return abs(world_x - _last_powerup_x) < min_px

func _get_main_node() -> Node:
    return get_tree().get_root().get_node_or_null("Main")

func _get_coins_root_for_tile(tile: TileMapLayer) -> Node2D:
    if tile == _tile_a:
        return _coins_a
    elif tile == _tile_b:
        return _coins_b
    return null

func _has_coin_near_x(tile: TileMapLayer, x: int, radius: int) -> bool:
    var root := _get_coins_root_for_tile(tile)
    if root == null:
        return false
    var r: int = max(radius, 0)
    for c in root.get_children():
        if c is HeartPickup:
            continue
        if c is MagnetPowerup:
            continue
        if c.is_in_group("shield_powerup"):
            continue
        if c is DoubleCoinsPowerup:
            continue
        if not (c is Node2D):
            continue
        var coin_node := c as Node2D
        var local_pos: Vector2 = tile.to_local(coin_node.global_position)
        var cell: Vector2i = tile.local_to_map(local_pos)
        if r <= 0:
            if cell.x == x:
                return true
        else:
            if abs(cell.x - x) <= r:
                return true
    return false

func _clear_coins_for_tile(tile: TileMapLayer) -> void:
    var root := _get_coins_root_for_tile(tile)
    if root == null:
        return
    for c in root.get_children():
        c.queue_free()

func _get_enemies_root_for_tile(tile: TileMapLayer) -> Node2D:
    if tile == _tile_a:
        return _enemies_a
    elif tile == _tile_b:
        return _enemies_b
    return null

func _clear_enemies_for_tile(tile: TileMapLayer) -> void:
    var root := _get_enemies_root_for_tile(tile)
    if root == null:
        return
    for c in root.get_children():
        c.queue_free()

func _clear_coins_near_gaps(tile: TileMapLayer, gap_edges: Array) -> void:
    var root := _get_coins_root_for_tile(tile)
    if root == null:
        return
    if gap_edges.is_empty():
        return
    var buffer: int = 2
    var nodes_by_x: Dictionary = {}
    for c in root.get_children():
        if c is HeartPickup:
            continue
        if c is MagnetPowerup:
            continue
        if c.is_in_group("shield_powerup"):
            continue
        if c is DoubleCoinsPowerup:
            continue
        if not (c is Node2D):
            continue
        var coin_node := c as Node2D
        var local_pos: Vector2 = tile.to_local(coin_node.global_position)
        var cell: Vector2i = tile.local_to_map(local_pos)
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
    var groups: Array = []
    var start_x: int = xs[0]
    var end_x: int = xs[0]
    for i in range(1, xs.size()):
        var x: int = xs[i]
        if x <= end_x + 1:
            end_x = x
        else:
            groups.append(Vector2i(start_x, end_x))
            start_x = x
            end_x = x
    groups.append(Vector2i(start_x, end_x))
    var ranges_to_remove: Array = []
    for gr in groups:
        var gs_group: int = gr.x
        var ge_group: int = gr.y
        var remove_group: bool = false
        for gap in gap_edges:
            var gs: int = gap.x
            var ge: int = gap.y
            var x_min: int = gs - buffer
            var x_max: int = ge + buffer
            if ge_group >= x_min and gs_group <= x_max:
                remove_group = true
                break
        if remove_group:
            ranges_to_remove.append(gr)
    for gr2 in ranges_to_remove:
        var rs: int = gr2.x
        var re: int = gr2.y
        for x2 in range(rs, re + 1):
            if nodes_by_x.has(x2):
                var arr2: Array = nodes_by_x[x2]
                for n in arr2:
                    if n is Node2D:
                        (n as Node2D).queue_free()

func _clear_lonely_peak_coins(tile: TileMapLayer) -> void:
    var root := _get_coins_root_for_tile(tile)
    if root == null:
        return
    var nodes_by_x: Dictionary = {}
    for c in root.get_children():
        if c is HeartPickup:
            continue
        if c is MagnetPowerup:
            continue
        if c.is_in_group("shield_powerup"):
            continue
        if c is DoubleCoinsPowerup:
            continue
        if not (c is Node2D):
            continue
        var coin_node := c as Node2D
        var local_pos: Vector2 = tile.to_local(coin_node.global_position)
        var cell: Vector2i = tile.local_to_map(local_pos)
        nodes_by_x[cell.x] = {
            "node": coin_node,
            "y": cell.y,
        }
    if nodes_by_x.is_empty():
        return
    var xs: Array = nodes_by_x.keys()
    xs.sort()
    var to_remove: Array = []
    for x in xs:
        var entry: Dictionary = nodes_by_x[x]
        var y: int = entry["y"]
        var has_left: bool = nodes_by_x.has(x - 1)
        var has_right: bool = nodes_by_x.has(x + 1)
        if not has_left and not has_right:
            continue
        var higher_left: bool = false
        var higher_right: bool = false
        if has_left:
            var left_entry: Dictionary = nodes_by_x[x - 1]
            var left_y: int = left_entry["y"]
            if y < left_y:
                higher_left = true
        if has_right:
            var right_entry: Dictionary = nodes_by_x[x + 1]
            var right_y: int = right_entry["y"]
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
    for n in to_remove:
        if n is Node2D:
            (n as Node2D).queue_free()

func _clear_enemies_near_gaps(tile: TileMapLayer, gap_edges: Array) -> void:
    var root := _get_enemies_root_for_tile(tile)
    if root == null:
        return
    if gap_edges.is_empty():
        return
    for c in root.get_children():
        if c is HeartPickup:
            continue
        if not (c is Node2D):
            continue
        var enemy_node := c as Node2D
        var name_str: String = enemy_node.name
        var buffer: int = 0
        if name_str.begins_with("EnemyBlock"):
            buffer = max(enemy_gap_safe_buffer_block, 0)
        elif name_str.begins_with("EnemyCone"):
            buffer = max(enemy_gap_safe_buffer_cone, 0)
        if buffer <= 0:
            continue
        var local_pos: Vector2 = tile.to_local(enemy_node.global_position)
        var cell: Vector2i = tile.local_to_map(local_pos)
        var x_cell: int = cell.x
        var remove_enemy: bool = false
        for gap in gap_edges:
            var gs: int = gap.x
            var ge: int = gap.y
            var x_min: int = gs - buffer
            var x_max: int = ge + buffer
            if x_cell >= x_min and x_cell <= x_max:
                remove_enemy = true
                break
        if remove_enemy:
            enemy_node.queue_free()

func _clear_short_coin_groups(tile: TileMapLayer) -> void:
    var root := _get_coins_root_for_tile(tile)
    if root == null:
        return
    var min_len: int = max(coin_group_min_len, 1)
    if min_len <= 1:
        return
    var nodes_by_x: Dictionary = {}
    for c in root.get_children():
        if c is HeartPickup:
            continue
        if c is MagnetPowerup:
            continue
        if c.is_in_group("shield_powerup"):
            continue
        if c is DoubleCoinsPowerup:
            continue
        if not (c is Node2D):
            continue
        var coin_node := c as Node2D
        var local_pos: Vector2 = tile.to_local(coin_node.global_position)
        var cell: Vector2i = tile.local_to_map(local_pos)
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
    var groups: Array = []
    var start_x: int = xs[0]
    var end_x: int = xs[0]
    for i in range(1, xs.size()):
        var x: int = xs[i]
        if x <= end_x + 1:
            end_x = x
        else:
            groups.append(Vector2i(start_x, end_x))
            start_x = x
            end_x = x
    groups.append(Vector2i(start_x, end_x))
    for gr in groups:
        var gs: int = gr.x
        var ge: int = gr.y
        var length: int = ge - gs + 1
        if length < min_len:
            for x2 in range(gs, ge + 1):
                if nodes_by_x.has(x2):
                    var arr2: Array = nodes_by_x[x2]
                    for n in arr2:
                        if n is Node2D:
                            (n as Node2D).queue_free()

func _ensure_editor_preview_for_tile(tile: TileMapLayer) -> void:
    var coins_root := _get_coins_root_for_tile(tile)
    var enemies_root := _get_enemies_root_for_tile(tile)
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
    var x_heart: int = clamp(mid - 4, 0, max(segment_tile_count - 1, 0))
    var x_magnet: int = clamp(mid + 8, 0, max(segment_tile_count - 1, 0))
    var x_shield: int = clamp(mid - 8, 0, max(segment_tile_count - 1, 0))
    var x_double: int = clamp(mid, 0, max(segment_tile_count - 1, 0))
    _spawn_coin_for_column(tile, x_coin, h_base)
    _spawn_enemy_for_column(tile, x_enemy, h_base)
    _spawn_heart_for_column(tile, x_heart, h_base)
    _spawn_magnet_for_column(tile, x_magnet, h_base)
    _spawn_shield_for_column(tile, x_shield, h_base)
    _spawn_double_coins_for_column(tile, x_double, h_base)

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

func _spawn_coin_for_column(tile: TileMapLayer, x: int, height: int) -> void:
    if coin_scene == null:
        return
    var root := _get_coins_root_for_tile(tile)
    if root == null:
        return
    var max_coins: int = _scale_max_children(coin_max_children)
    if max_coins > 0 and root.get_child_count() >= max_coins:
        return
    var seg_id := "A"
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
    var cell := Vector2i(x, coin_y)
    var local_pos: Vector2 = tile.map_to_local(cell)
    var world_pos: Vector2 = tile.to_global(local_pos)
    if frac_tiles != 0.0:
        world_pos.y -= frac_tiles * _tile_h_px
    var coin := coin_scene.instantiate()
    if coin == null:
        return
    coin.scale = Vector2.ONE * coin_scale
    if coin.has_method("set"):
        coin.set("source_segment", seg_id)
    root.add_child(coin)
    coin.global_position = world_pos
    if coin_zigzag_enabled and coin_zigzag_amplitude_tiles > 0.0:
        _coin_pattern_index += 1
    var main := get_tree().get_root().get_node_or_null("Main")
    if main and main.has_method("on_coin_collected") and coin.has_signal("collected"):
        coin.collected.connect(Callable(main, "on_coin_collected"))

func _spawn_heart_for_column(tile: TileMapLayer, x: int, height: int) -> void:
    if heart_scene == null:
        return
    var root := _get_coins_root_for_tile(tile)
    if root == null:
        return
    var max_hearts: int = _scale_max_children(heart_max_children)
    if max_hearts > 0:
        var heart_count: int = 0
        for c in root.get_children():
            if c is HeartPickup:
                heart_count += 1
        if heart_count >= max_hearts:
            return
    var top_y: int = -height
    var offset_tiles: float = heart_height_offset_tiles
    var whole_tiles: int = int(floor(offset_tiles))
    var frac_tiles: float = offset_tiles - float(whole_tiles)
    var heart_y: int = top_y - whole_tiles
    var cell := Vector2i(x, heart_y)
    var local_pos: Vector2 = tile.map_to_local(cell)
    var world_pos: Vector2 = tile.to_global(local_pos)
    if frac_tiles != 0.0:
        world_pos.y -= frac_tiles * _tile_h_px
    var min_dist_px: float = max(heart_min_distance_tiles * _tile_w_px, 0.0)
    if min_dist_px > 0.0 and _last_heart_x > -1.0e19:
        if abs(world_pos.x - _last_heart_x) < min_dist_px:
            return
    var heart := heart_scene.instantiate()
    if heart == null:
        return
    if heart_scale != 1.0:
        if heart is Node2D:
            (heart as Node2D).scale = Vector2.ONE * heart_scale
    if heart is HeartPickup:
        var hp := heart as HeartPickup
        hp.osc_amplitude = heart_osc_amplitude_tiles * _tile_h_px
        hp.osc_frequency = heart_osc_frequency
    root.add_child(heart)
    heart.global_position = world_pos
    _last_heart_x = world_pos.x
    _last_powerup_x = world_pos.x

func _spawn_shield_for_column(tile: TileMapLayer, x: int, height: int) -> void:
    var gm := _get_main_node()
    if gm != null:
        var magnet_active: bool = false
        var shield_active: bool = false
        if gm.has_method("is_magnet_active"):
            magnet_active = gm.is_magnet_active()
        if gm.has_method("is_shield_active"):
            shield_active = gm.is_shield_active()
        if magnet_active or shield_active:
            return
    if shield_scene == null:
        return
    var root := _get_coins_root_for_tile(tile)
    if root == null:
        return
    var max_shields: int = _scale_max_children(shield_max_children)
    if max_shields > 0:
        var shield_count: int = 0
        for c in root.get_children():
            if c.is_in_group("shield_powerup"):
                shield_count += 1
        if shield_count >= max_shields:
            return
    var top_y: int = -height
    var offset_tiles: float = shield_height_offset_tiles
    var whole_tiles: int = int(floor(offset_tiles))
    var frac_tiles: float = offset_tiles - float(whole_tiles)
    var shield_y: int = top_y - whole_tiles
    var cell := Vector2i(x, shield_y)
    var local_pos: Vector2 = tile.map_to_local(cell)
    var world_pos: Vector2 = tile.to_global(local_pos)
    if frac_tiles != 0.0:
        world_pos.y -= frac_tiles * _tile_h_px
    var min_dist_px: float = max(shield_min_distance_tiles * _tile_w_px, 0.0)
    if min_dist_px > 0.0 and _last_shield_x > -1.0e19:
        if abs(world_pos.x - _last_shield_x) < min_dist_px:
            return
    var shield := shield_scene.instantiate()
    if shield == null:
        return
    if not (shield is Node2D):
        return
    root.add_child(shield)
    (shield as Node2D).global_position = world_pos
    _last_shield_x = world_pos.x
    _last_powerup_x = world_pos.x

func _spawn_magnet_for_column(tile: TileMapLayer, x: int, height: int) -> void:
    var gm := _get_main_node()
    if gm != null:
        var magnet_active: bool = false
        var shield_active: bool = false
        if gm.has_method("is_magnet_active"):
            magnet_active = gm.is_magnet_active()
        if gm.has_method("is_shield_active"):
            shield_active = gm.is_shield_active()
        if magnet_active or shield_active:
            return
    if magnet_scene == null:
        return
    var root := _get_coins_root_for_tile(tile)
    if root == null:
        return
    var max_magnets: int = _scale_max_children(magnet_max_children)
    if max_magnets > 0:
        var magnet_count: int = 0
        for c in root.get_children():
            if c is MagnetPowerup:
                magnet_count += 1
        if magnet_count >= max_magnets:
            return
    var top_y: int = -height
    var offset_tiles: float = magnet_height_offset_tiles
    var whole_tiles: int = int(floor(offset_tiles))
    var frac_tiles: float = offset_tiles - float(whole_tiles)
    var magnet_y: int = top_y - whole_tiles
    var cell := Vector2i(x, magnet_y)
    var local_pos: Vector2 = tile.map_to_local(cell)
    var world_pos: Vector2 = tile.to_global(local_pos)
    if frac_tiles != 0.0:
        world_pos.y -= frac_tiles * _tile_h_px
    var min_dist_px: float = max(magnet_min_distance_tiles * _tile_w_px, 0.0)
    if min_dist_px > 0.0 and _last_magnet_x > -1.0e19:
        if abs(world_pos.x - _last_magnet_x) < min_dist_px:
            return
    var magnet := magnet_scene.instantiate()
    if magnet == null:
        return
    if not (magnet is Node2D):
        return
    root.add_child(magnet)
    (magnet as Node2D).global_position = world_pos
    _last_magnet_x = world_pos.x
    _last_powerup_x = world_pos.x

func _spawn_double_coins_for_column(tile: TileMapLayer, x: int, height: int) -> void:
    if double_coins_scene == null:
        return
    var root := _get_coins_root_for_tile(tile)
    if root == null:
        return
    var max_double: int = _scale_max_children(double_coins_max_children)
    if max_double > 0:
        var count: int = 0
        for c in root.get_children():
            if c is DoubleCoinsPowerup:
                count += 1
        if count >= max_double:
            return
    var top_y: int = -height
    var offset_tiles: float = double_coins_height_offset_tiles
    var whole_tiles: int = int(floor(offset_tiles))
    var frac_tiles: float = offset_tiles - float(whole_tiles)
    var dc_y: int = top_y - whole_tiles
    var cell := Vector2i(x, dc_y)
    var local_pos: Vector2 = tile.map_to_local(cell)
    var world_pos: Vector2 = tile.to_global(local_pos)
    if frac_tiles != 0.0:
        world_pos.y -= frac_tiles * _tile_h_px
    var min_dist_px: float = max(double_coins_min_distance_tiles * _tile_w_px, 0.0)
    if min_dist_px > 0.0 and _last_double_coins_x > -1.0e19:
        if abs(world_pos.x - _last_double_coins_x) < min_dist_px:
            return
    var node := double_coins_scene.instantiate()
    if node == null:
        return
    if not (node is Node2D):
        return
    root.add_child(node)
    (node as Node2D).global_position = world_pos
    _last_double_coins_x = world_pos.x
    _last_powerup_x = world_pos.x

func _spawn_enemy_for_column(tile: TileMapLayer, x: int, height: int) -> void:
    var root := _get_enemies_root_for_tile(tile)
    if root == null:
        return
    var max_enemies: int = _scale_max_children(enemy_max_children)
    if max_enemies > 0 and root.get_child_count() >= max_enemies:
        return
    var entries: Array = []
    if enemy_allow_block and enemy_block_scene != null and enemy_block_weight > 0.0:
        entries.append({"scene": enemy_block_scene, "weight": enemy_block_weight})
    if enemy_allow_cone and enemy_cone_scene != null and enemy_cone_weight > 0.0:
        entries.append({"scene": enemy_cone_scene, "weight": enemy_cone_weight})
    if entries.is_empty():
        return
    var enemy_scene: PackedScene = null
    if entries.size() == 1:
        enemy_scene = entries[0]["scene"]
    else:
        var total_w: float = 0.0
        for e in entries:
            total_w += float(e["weight"])
        if total_w <= 0.0:
            return
        var r: float = _rng.randf() * total_w
        var acc: float = 0.0
        for e2 in entries:
            acc += float(e2["weight"])
            if r <= acc:
                enemy_scene = e2["scene"]
                break
    if enemy_scene == null:
        return
    var top_y: int = -height
    var cell := Vector2i(x, top_y)
    var local_pos: Vector2 = tile.map_to_local(cell)
    var world_pos: Vector2 = tile.to_global(local_pos)
    var enemy := enemy_scene.instantiate()
    if enemy == null:
        return
    root.add_child(enemy)
    var ground_top_y: float = world_pos.y - (_tile_h_px * 0.5)
    var final_pos: Vector2 = Vector2(world_pos.x, ground_top_y)
    var hitbox_cs: CollisionShape2D = enemy.get_node_or_null("Hitbox/CollisionShape2D") as CollisionShape2D
    if hitbox_cs != null and hitbox_cs.shape is RectangleShape2D:
        var rect := hitbox_cs.shape as RectangleShape2D
        var bottom_local: float = hitbox_cs.position.y + rect.size.y * 0.5
        var scale_y: float = enemy.global_scale.y
        final_pos.y -= bottom_local * scale_y
    if enemy_y_offset_tiles != 0.0:
        final_pos.y -= enemy_y_offset_tiles * _tile_h_px
    enemy.global_position = final_pos

func _clear_collision_for_tile(tile: TileMapLayer) -> void:
    if Engine.is_editor_hint():
        return
    var root := tile.get_node_or_null("CollisionBodies") as Node2D
    if root == null:
        return
    for child in root.get_children():
        child.queue_free()

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
    var root := _ensure_collision_root(tile)
    var body := StaticBody2D.new()
    body.collision_layer = 1
    body.collision_mask = 2
    root.add_child(body)
    var shape_node := CollisionShape2D.new()
    body.add_child(shape_node)
    var rect := RectangleShape2D.new()
    var cell_size := Vector2(tile.tile_set.tile_size)
    rect.size = cell_size
    shape_node.shape = rect
    body.position = (Vector2(cell.x, cell.y) + Vector2(0.5, 0.5)) * cell_size

func _place_ground_column(tile: TileMapLayer, x: int, height: int) -> void:
    if tile == null:
        return
    var top_y: int = -height
    var source_top: int = 2
    var source_fill: int = 1
    var top_cell := Vector2i(x, top_y)
    tile.set_cell(top_cell, source_top, Vector2i(0, 0))
    _add_collision_for_cell(tile, top_cell)
    var fill_depth: int = 3
    var d: int = 1
    while d <= fill_depth:
        var y: int = top_y + d
        var fill_cell := Vector2i(x, y)
        tile.set_cell(fill_cell, source_fill, Vector2i(0, 0))
        _add_collision_for_cell(tile, fill_cell)
        d += 1

func _run_generate_now(reset_flat: bool = false, reset_height: bool = false) -> void:
    _initialized = false
    _ensure_initialized()
    if reset_flat:
        _flat_tiles_remaining = max(flat_start_tiles, 0)
    if reset_height:
        _height_a = 0
        _height_b = 0
    if _tile_a:
        _height_a = _generate_segment(_tile_a, _height_a)
        _tile_a.position.x = 0.0
    if _tile_b:
        _height_b = _generate_segment(_tile_b, _height_b)
        _tile_b.position.x = _seg_width_px
    _apply_debug_tint()

func set_speed(new_speed: float) -> void:
    var v: float = clamp(new_speed, min_scroll_speed, max_scroll_speed)
    _target_speed = v
    if not use_acceleration:
        scroll_speed = v

func get_speed() -> float:
    return scroll_speed

func set_speed_limits(min_s: float, max_s: float) -> void:
    min_scroll_speed = min_s
    max_scroll_speed = max_s
    _target_speed = clamp(_target_speed, min_scroll_speed, max_scroll_speed)
    scroll_speed = clamp(scroll_speed, min_scroll_speed, max_scroll_speed)

func set_movement_enabled(enabled: bool) -> void:
    movement_enabled = enabled

func get_active_segment_name() -> String:
    var cam := get_viewport().get_camera_2d()
    var px: float = 0.0
    if cam != null:
        px = cam.global_position.x
    else:
        px = 0.0
    var seg: Node = null
    if _tile_a:
        var ax: float = global_position.x + _tile_a.position.x
        var ax2: float = ax + _seg_width_px
        if px >= ax and px <= ax2:
            seg = _tile_a
    if seg == null and _tile_b:
        var bx: float = global_position.x + _tile_b.position.x
        var bx2: float = bx + _seg_width_px
        if px >= bx and px <= bx2:
            seg = _tile_b
    if seg == null:
        return ""
    return seg.name

func _apply_debug_tint() -> void:
    if not debug_tint_enabled:
        if _tile_a:
            _tile_a.modulate = Color(1, 1, 1, 1)
        if _tile_b:
            _tile_b.modulate = Color(1, 1, 1, 1)
        return
    if _tile_a:
        _tile_a.modulate = debug_color_a
    if _tile_b:
        _tile_b.modulate = debug_color_b
