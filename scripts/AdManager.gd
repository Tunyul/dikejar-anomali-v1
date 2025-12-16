extends Node

@export var ads_enabled: bool = true
@export var auto_grant_rewarded: bool = true
signal reward_granted(reason: String)

func is_rewarded_available() -> bool:
    return ads_enabled

func show_rewarded(reason: String) -> void:
    if not ads_enabled:
        return
    if auto_grant_rewarded:
        call_deferred("_emit_reward", reason)

func _emit_reward(reason: String) -> void:
    reward_granted.emit(reason)
