extends Label

@export var prefix: String = "v"

func _ready() -> void:
    add_theme_color_override("font_color", Color(0, 0, 0, 1))
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
