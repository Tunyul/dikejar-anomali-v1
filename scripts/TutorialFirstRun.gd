extends Control

const _MAIN_SCENE := "res://scenes/MainTutorial.tscn"

var _transitioning: bool = false

func _ready() -> void:
    call_deferred("_go_to_main")


func _go_to_main() -> void:
    if _transitioning == false:
        _transitioning = true
    if TransitionManager and TransitionManager.has_method("play_transition_to_scene"):
        await TransitionManager.play_transition_to_scene(_MAIN_SCENE)
        return
    get_tree().change_scene_to_file(_MAIN_SCENE)
