extends Control

@onready var bar = $CenterContainer/VBoxContainer/ProgressBar
@onready var overlay = $ColorRect
@onready var label = $CenterContainer/VBoxContainer/Label

func show_screen() -> void:
	set_visible(true)

func hide_screen() -> void:
	set_visible(false)

func set_progress(pct: float) -> void:
	if bar:
		bar.value = clamp(int(pct * 100.0), 0, 100)
	if label:
		label.text = "Loading " + str(clamp(int(pct * 100.0), 0, 100)) + "%"

func start_transition() -> void:
	set_visible(true)
	if overlay:
		overlay.modulate = Color(0, 0, 0, 0)
		var t = create_tween()
		t.tween_property(overlay, "modulate:a", 0.5, 0.25)

func finish_transition() -> void:
	if overlay:
		var t = create_tween()
		t.tween_property(overlay, "modulate:a", 0.0, 0.2)
		t.finished.connect(func(): hide_screen())
