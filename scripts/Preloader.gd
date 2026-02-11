extends Node

var _cache: Dictionary = {}
var _next_scene_path: String = ""

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
    if Engine.has_singleton("RemoteContent"):
        RemoteContent.start()
        if RemoteContent.is_ready():
            _maybe_preload_main()
        else:
            RemoteContent.content_ready.connect(_on_remote_ready)
    _maybe_preload_main()

func _on_remote_ready() -> void:
    _maybe_preload_main()

func _maybe_preload_main() -> void:
    var path := "res://scenes/Main.tscn"
    if ResourceLoader.exists(path):
        _preload_scene(path)

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
