extends Button

func _ready() -> void:
    text = ""
    tooltip_text = "Pause/Resume"
    pressed.connect(_on_pressed)
    set_process(true)

func _process(_delta: float) -> void:
    var gm := get_tree().get_root().get_node_or_null("GameManager")
    if gm and gm.has_method("get_game_state"):
        var st: Dictionary = gm.get_game_state()
        var phase := int(st.get("phase", 0))
        var active := bool(st.get("game_active", false))
        visible = (phase == 0)
        if active:
            self.disabled = false
        else:
            self.disabled = false

func _on_pressed() -> void:
    var gm := get_tree().get_root().get_node_or_null("GameManager")
    if gm and gm.has_method("get_game_state"):
        var st: Dictionary = gm.get_game_state()
        var phase := int(st.get("phase", 0))
        var active := bool(st.get("game_active", false))
        if phase == 0:
            if active and gm.has_method("pause_game"):
                gm.pause_game()
            elif (not active) and gm.has_method("resume_game"):
                gm.resume_game()
