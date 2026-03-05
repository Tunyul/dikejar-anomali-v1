extends Node

var _cache: Dictionary = {}
var _next_scene_path: String = ""
var _total_to_load: int = 0
var _loaded_count: int = 0
var _deferred_total_to_load: int = 0
var _deferred_loaded_count: int = 0

var _boot_ready: bool = false
var _deferred_ready: bool = false
var _deferred_requested: bool = false
var _deferred_started: bool = false
var _warmup_started: bool = false
var _warmup_ready: bool = false

var _active_stage: String = ""
var _active_assets: Array[String] = []
var _active_total: int = 0
var _active_loaded: int = 0
var _active_index: int = -1
var _active_path: String = ""
var _last_boot_progress_emit: float = -1.0
var _last_deferred_progress_emit: float = -1.0

const _BOOT_ASSETS := [
    "res://scenes/LoadingScreen.tscn",
    "res://scenes/MainMenu.tscn",
    "res://scenes/Main.tscn",
    "res://scenes/ShopMenu.tscn",
    "res://scenes/DailyMissionsMenu.tscn",
    "res://scenes/SettingsMenu.tscn",
    "res://scenes/GameOver.tscn",
    "res://scenes/SeasonRewardsMenu.tscn",
    "res://scenes/SkillProgressPanel.tscn"
]

const _DEFERRED_ASSETS := [
    "res://scenes/player.tscn",
    "res://scenes/Coin.tscn",
    "res://scenes/Diamond.tscn",
    "res://scenes/CollectibleHeart.tscn",
    "res://scenes/EnemyBlock.tscn",
    "res://scenes/EnemyCone.tscn",
    "res://scenes/MagnetPowerup.tscn",
    "res://scenes/ShieldPowerup.tscn",
    "res://scenes/DoubleCoinsPowerup.tscn",
    "res://scenes/SpeedBoostPowerup.tscn"
]

const _WARMUP_SCENES := [
    "res://scenes/Coin.tscn",
    "res://scenes/Diamond.tscn",
    "res://scenes/CollectibleHeart.tscn",
    "res://scenes/EnemyBlock.tscn",
    "res://scenes/EnemyCone.tscn",
    "res://scenes/MagnetPowerup.tscn",
    "res://scenes/ShieldPowerup.tscn",
    "res://scenes/DoubleCoinsPowerup.tscn",
    "res://scenes/SpeedBoostPowerup.tscn"
]

signal progress_changed(p: float)
signal all_ready
signal deferred_progress_changed(p: float)
signal deferred_ready
signal warmup_ready

func _ready() -> void:
    if _has_cmd_arg("--smoke-check"):
        call_deferred("_run_smoke_check")
        return
    if _has_cmd_arg("--check-only"):
        call_deferred("_run_smoke_check")
        return
    if _has_cmd_arg("--sfx-test"):
        call_deferred("_run_sfx_test")
        return
    if _is_headless_or_check_only():
        return
    set_process(false)

func start_preloading() -> void:
    if _boot_ready:
        _emit_boot_progress(1.0)
        all_ready.emit()
        start_deferred_preloading()
        return
    if _active_stage == "boot":
        return
    _begin_stage("boot", _BOOT_ASSETS)

func start_deferred_preloading() -> void:
    _deferred_requested = true
    if _deferred_ready:
        _emit_deferred_progress(1.0)
        deferred_ready.emit()
        return
    if _active_stage == "deferred":
        return
    if not _boot_ready:
        if _active_stage == "boot":
            return
        start_preloading()
        return
    if _deferred_started:
        return
    _deferred_started = true
    _begin_stage("deferred", _DEFERRED_ASSETS)

func _process(_delta: float) -> void:
    if _active_stage == "":
        set_process(false)
        return
    _poll_active_request()

func _begin_stage(stage: String, assets: Array) -> void:
    var normalized := _normalize_assets(assets)
    _active_stage = stage
    _active_assets = normalized
    _active_total = normalized.size()
    _active_loaded = 0
    _active_index = -1
    _active_path = ""

    if stage == "boot":
        _boot_ready = false
        _total_to_load = _active_total
        _loaded_count = 0
        _last_boot_progress_emit = -1.0
        _emit_boot_progress(1.0 if _active_total <= 0 else 0.0)
    elif stage == "deferred":
        _deferred_ready = false
        _deferred_total_to_load = _active_total
        _deferred_loaded_count = 0
        _last_deferred_progress_emit = -1.0
        _emit_deferred_progress(1.0 if _active_total <= 0 else 0.0)

    set_process(true)
    if _active_total <= 0:
        _finish_active_stage()
        return
    _request_next_active_asset()

func _normalize_assets(assets: Array) -> Array[String]:
    var out: Array[String] = []
    var seen: Dictionary = {}
    for a in assets:
        var path := String(a).strip_edges()
        if path.is_empty():
            continue
        if seen.has(path):
            continue
        seen[path] = true
        if not ResourceLoader.exists(path):
            push_warning("Preloader missing optional asset: " + path)
            continue
        out.append(path)
    return out

func _request_next_active_asset() -> void:
    while _active_index + 1 < _active_total:
        _active_index += 1
        var path := _active_assets[_active_index]

        if _cache.has(path):
            _mark_active_asset_loaded()
            continue

        var err := ResourceLoader.load_threaded_request(path, "PackedScene", true, ResourceLoader.CACHE_MODE_REUSE)
        if err != OK:
            _preload_scene(path)
            _mark_active_asset_loaded()
            continue

        _active_path = path
        return

    _finish_active_stage()

func _poll_active_request() -> void:
    if _active_path.is_empty():
        _request_next_active_asset()
        return

    var item_progress: Array = []
    var status := ResourceLoader.load_threaded_get_status(_active_path, item_progress)
    var item_ratio := 0.0
    if item_progress.size() > 0:
        item_ratio = clampf(float(item_progress[0]), 0.0, 1.0)
    _emit_active_progress(item_ratio)

    if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
        return

    if status == ResourceLoader.THREAD_LOAD_LOADED:
        var res := ResourceLoader.load_threaded_get(_active_path)
        if res is PackedScene:
            _cache[_active_path] = res
        else:
            _preload_scene(_active_path)
        _mark_active_asset_loaded()
        _active_path = ""
        _request_next_active_asset()
        return

    _preload_scene(_active_path)
    _mark_active_asset_loaded()
    _active_path = ""
    _request_next_active_asset()

func _emit_active_progress(item_ratio: float) -> void:
    if _active_total <= 0:
        return
    var p := (float(_active_loaded) + clampf(item_ratio, 0.0, 1.0)) / float(_active_total)
    if _active_stage == "boot":
        _emit_boot_progress(p)
    elif _active_stage == "deferred":
        _emit_deferred_progress(p)

func _mark_active_asset_loaded() -> void:
    _active_loaded += 1
    if _active_stage == "boot":
        _loaded_count = _active_loaded
        _emit_boot_progress(get_progress())
    elif _active_stage == "deferred":
        _deferred_loaded_count = _active_loaded
        _emit_deferred_progress(get_deferred_progress())

func _finish_active_stage() -> void:
    var stage := _active_stage
    _active_stage = ""
    _active_assets.clear()
    _active_total = 0
    _active_loaded = 0
    _active_index = -1
    _active_path = ""

    if stage == "boot":
        _boot_ready = true
        _loaded_count = _total_to_load
        _emit_boot_progress(1.0)
        all_ready.emit()
        _deferred_requested = true
        start_deferred_preloading()
    elif stage == "deferred":
        _deferred_ready = true
        _deferred_loaded_count = _deferred_total_to_load
        _emit_deferred_progress(1.0)
        deferred_ready.emit()

    if _active_stage == "":
        set_process(false)

func _emit_boot_progress(p: float) -> void:
    var clamped := clampf(p, 0.0, 1.0)
    if absf(clamped - _last_boot_progress_emit) < 0.001:
        return
    _last_boot_progress_emit = clamped
    progress_changed.emit(clamped)

func _emit_deferred_progress(p: float) -> void:
    var clamped := clampf(p, 0.0, 1.0)
    if absf(clamped - _last_deferred_progress_emit) < 0.001:
        return
    _last_deferred_progress_emit = clamped
    deferred_progress_changed.emit(clamped)

func get_progress() -> float:
    if _total_to_load <= 0:
        return 1.0
    return float(_loaded_count) / float(_total_to_load)

func is_ready() -> bool:
    return _boot_ready

func get_deferred_progress() -> float:
    if _deferred_total_to_load <= 0:
        return 1.0
    return float(_deferred_loaded_count) / float(_deferred_total_to_load)

func is_deferred_ready() -> bool:
    return _deferred_ready

func start_warmup() -> void:
    if _warmup_ready:
        warmup_ready.emit()
        return
    if _warmup_started:
        return
    _warmup_started = true
    call_deferred("_run_warmup")

func is_warmup_ready() -> bool:
    return _warmup_ready

func _run_warmup() -> void:
    if _is_headless_or_check_only():
        _warmup_ready = true
        warmup_ready.emit()
        return
    var holder := Node.new()
    holder.name = "WarmupHolder"
    add_child(holder)

    for path in _WARMUP_SCENES:
        var packed := get_packed(path)
        if packed == null:
            continue
        var inst := packed.instantiate()
        if inst == null:
            continue
        holder.add_child(inst)
        _touch_warmup_node(inst)
        await get_tree().process_frame
        if is_instance_valid(inst):
            inst.queue_free()
        await get_tree().process_frame

    if is_instance_valid(holder):
        holder.queue_free()
    _warmup_ready = true
    warmup_ready.emit()

func _touch_warmup_node(node: Node) -> void:
    if node is AnimatedSprite2D:
        var anim := node as AnimatedSprite2D
        if anim.sprite_frames:
            if anim.animation.is_empty():
                var names := anim.sprite_frames.get_animation_names()
                if names.size() > 0:
                    anim.animation = names[0]
            anim.play()
            anim.advance(1.0 / 60.0)
            anim.stop()
    for child in node.get_children():
        if child is Node:
            _touch_warmup_node(child)

func _has_cmd_arg(arg: String) -> bool:
    for a in OS.get_cmdline_args():
        if a == arg:
            return true
    return false

func _is_headless_or_check_only() -> bool:
    if DisplayServer.get_name() == "headless":
        return true
    return false

func _run_smoke_check() -> void:
    print("SMOKE_CHECK_START")
    var paths: Array[String] = [
        "res://scenes/LoadingScreen.tscn",
        "res://scenes/MainMenu.tscn",
        "res://scenes/ShopMenu.tscn",
        "res://scenes/Main.tscn",
        "res://scenes/DailyMissionsMenu.tscn"
    ]
    for p in paths:
        var res := load(p)
        if not (res is PackedScene):
            push_error("Smoke check failed to load: %s" % p)
    print("SMOKE_CHECK_OK")
    get_tree().quit()

func _run_sfx_test() -> void:
    await get_tree().process_frame
    if Engine.has_singleton("TransitionManager"):
        TransitionManager.set_sfx_muted(false)
        TransitionManager.set_sfx_volume(1.0)
        TransitionManager.play_sfx(&"coin")
        await get_tree().create_timer(0.11).timeout
        TransitionManager.play_sfx(&"coin")
        await get_tree().create_timer(0.11).timeout
        TransitionManager.play_sfx(&"coin")
        await get_tree().create_timer(0.2).timeout
    get_tree().quit()

func _preload_scene(path: String) -> void:
    if not _cache.has(path):
        var r := load(path)
        if r is PackedScene:
            _cache[path] = r

func get_packed(path: String) -> PackedScene:
    if _cache.has(path):
        return _cache[path]
    if not _active_path.is_empty() and _active_path == path:
        var status := ResourceLoader.load_threaded_get_status(path)
        if status == ResourceLoader.THREAD_LOAD_LOADED:
            var threaded := ResourceLoader.load_threaded_get(path)
            if threaded is PackedScene:
                _cache[path] = threaded
                return threaded
    var r := load(path)
    if r is PackedScene:
        _cache[path] = r
        return r
    return null

func set_next_scene(path: String) -> void:
    _next_scene_path = path

func peek_next_scene() -> String:
    return _next_scene_path

func consume_next_scene() -> String:
    var p := _next_scene_path
    _next_scene_path = ""
    return p
