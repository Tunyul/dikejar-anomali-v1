extends Label

@export var prefix: String = "v"

func _ready() -> void:
    var ver: String = ""
    var v = ProjectSettings.get_setting("application/config/version")
    if v != null:
        ver = String(v).strip_edges()
    if ver == "":
        var f: FileAccess = FileAccess.open("res://VERSION", FileAccess.READ)
        if f:
            ver = f.get_as_text().strip_edges()
    if ver == "":
        ver = "dev"
    text = "%s%s" % [prefix, ver]
