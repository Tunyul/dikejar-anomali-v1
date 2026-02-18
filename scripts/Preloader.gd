extends Node

var _cache: Dictionary = {}
var _next_scene_path: String = ""
var _total_to_load: int = 0
var _loaded_count: int = 0

signal progress_changed(p: float)
signal all_ready

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

func start_preloading() -> void:
    if _loaded_count > 0 and _loaded_count >= _total_to_load and _total_to_load > 0:
        all_ready.emit()
        return

    var assets := [
        "res://scenes/Main.tscn",
        "res://scenes/MainMenu.tscn",
        "res://scenes/ShopMenu.tscn",
        "res://scenes/DailyMissionsMenu.tscn",
        "res://scenes/SettingsMenu.tscn",
        "res://scenes/GameOver.tscn",
        "res://scenes/player.tscn",
        "res://scenes/Coin.tscn",
        "res://scenes/Diamond.tscn",
        "res://scenes/HeartPickup.tscn",
        "res://scenes/EnemyBlock.tscn",
        "res://scenes/EnemyCone.tscn",
        "res://scenes/MagnetPowerup.tscn",
        "res://scenes/ShieldPowerup.tscn",
        "res://scenes/DoubleCoinsPowerup.tscn",
        "res://scenes/SpeedBoostPowerup.tscn"
    ]

    _total_to_load = assets.size()
    _loaded_count = 0

    for path in assets:
        if ResourceLoader.exists(path):
            _preload_scene(path)
        _loaded_count += 1
        progress_changed.emit(get_progress())
        # Berikan kesempatan engine untuk memproses frame jika banyak asset
        if _loaded_count % 3 == 0:
            await get_tree().process_frame

    all_ready.emit()

func get_progress() -> float:
    if _total_to_load <= 0: return 1.0
    return float(_loaded_count) / float(_total_to_load)

func is_ready() -> bool:
    return _loaded_count >= _total_to_load

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
    var r := load(path)
    if r is PackedScene:
        _cache[path] = r
        return r
    return null

func set_next_scene(path: String) -> void:
    _next_scene_path = path

func consume_next_scene() -> String:
    var p := _next_scene_path
    _next_scene_path = ""
    return p
