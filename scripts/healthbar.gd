extends Control

@export var max_health: int = 100
@export var current_health: int = 100:
    set(value):
        current_health = clamp(value, 0, max_health)
        update_healthbar()

@onready var progress_bar = $ProgressBar
@onready var health_label = $Label

func _ready() -> void:
    update_healthbar()

func update_healthbar() -> void:
    if progress_bar:
        progress_bar.value = float(current_health) / float(max_health) * 100
    
    if health_label:
        health_label.text = str(current_health) + "%"

func set_health(value: int) -> void:
    current_health = clamp(value, 0, max_health)

func take_damage(amount: int) -> void:
    current_health -= amount
    if current_health <= 0:
        current_health = 0
        emit_signal("health_depleted")

func heal(amount: int) -> void:
    current_health += amount

signal health_depleted