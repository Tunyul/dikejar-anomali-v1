extends Button

func _ready() -> void:
    text = ""
    tooltip_text = "Pause/Resume"
    pressed.connect(_on_pressed)
    set_process(true)

func _process(_delta: float) -> void:
    var main := get_tree().get_root().get_node_or_null("Main")
    if main and main.has_method("get_game_state"):
        var st: Dictionary = main.get_game_state()
        var phase := int(st.get("phase", 0))
        var active := bool(st.get("game_active", false))
        visible = (phase == 0)
        if active:
            self.disabled = false
        else:
            self.disabled = false

func _on_pressed() -> void:
    var main := get_tree().get_root().get_node_or_null("Main")
    if main and main.has_method("get_game_state"):
        var st: Dictionary = main.get_game_state()
        var phase := int(st.get("phase", 0))
        var active := bool(st.get("game_active", false))
        if phase == 0:
            if active and main.has_method("pause_game"):
                main.pause_game()
            elif (not active) and main.has_method("resume_game"):
                main.resume_game()
