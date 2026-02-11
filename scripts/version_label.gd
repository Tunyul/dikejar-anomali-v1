extends Label

@export var prefix: String = "v"

func _ready() -> void:
    add_theme_font_size_override("font_size", 18)
    add_theme_color_override("font_color", Color(1, 1, 1, 1))
    var ver: String = ""
    var f: FileAccess = FileAccess.open("res://VERSION", FileAccess.READ)
    if f:
        ver = f.get_as_text().strip_edges()
    if ver == "":
        var v = ProjectSettings.get_setting("application/config/version")
        if v != null:
            ver = String(v).strip_edges()
    if ver == "":
        ver = "dev"
    text = "%s%s" % [prefix, ver]
