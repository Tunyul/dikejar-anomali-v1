extends Node

var coins_collected: int = 0
var max_distance: int = 0
var missions: Array = []

func _ready() -> void:
    _load()
    if missions.is_empty():
        _init_default()

func _init_default() -> void:
    missions = [
        {"id": "m1", "name": "Kumpulkan 20 koin", "target": 20, "progress": 0},
        {"id": "m2", "name": "Capai jarak 500m", "target": 500, "progress": 0},
        {"id": "m3", "name": "Kumpulkan 50 koin", "target": 50, "progress": 0}
    ]
    coins_collected = 0
    max_distance = 0
    _save()

func add_coins(n: int) -> void:
    coins_collected += n
    for m in missions:
        if String(m.name).begins_with("Kumpulkan"):
            m.progress = coins_collected


func update_distance(d: float) -> void:
    var di := int(round(d))
    if di > max_distance:
        max_distance = di
        for m in missions:
            if String(m.name).begins_with("Capai jarak"):
                m.progress = max_distance


func get_missions_text() -> String:
    var lines := []
    for m in missions:
        var prog := int(m.progress)
        var tgt := int(m.target)
        var mname: String = String(m.name)
        lines.append(mname + " (" + str(min(prog, tgt)) + "/" + str(tgt) + ")")
    return "\n".join(lines)

func _load() -> void:
    var cfg := ConfigFile.new()
    var err := cfg.load("user://save.cfg")
    if err == OK:
        coins_collected = int(cfg.get_value("missions", "coins_collected", 0))
        max_distance = int(cfg.get_value("missions", "max_distance", 0))
        var ms: Array = cfg.get_value("missions", "list", [])
        if ms is Array:
            missions = ms

func _save() -> void:
    var cfg := ConfigFile.new()
    var err := cfg.load("user://save.cfg")
    if err != OK:
        cfg = ConfigFile.new()
    cfg.set_value("missions", "coins_collected", coins_collected)
    cfg.set_value("missions", "max_distance", max_distance)
    cfg.set_value("missions", "list", missions)
    cfg.save("user://save.cfg")
