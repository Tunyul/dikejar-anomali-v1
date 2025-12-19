extends Node

var _cache: Dictionary = {}
var _next_scene_path: String = ""

func _ready() -> void:
    _preload_scene("res://scenes/Main.tscn")

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
