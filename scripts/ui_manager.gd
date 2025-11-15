extends Control

@onready var healthbar = $Healthbar
@onready var distance_counter = $DistanceCounter
@onready var game_timer = $GameTimer

func _ready() -> void:
    # Connect signals
    if healthbar:
        healthbar.health_depleted.connect(_on_health_depleted)

func _on_health_depleted() -> void:
    # Handle health depletion - could emit signal to main game
    pass

func get_healthbar() -> Control:
    return healthbar

func get_distance_counter() -> Control:
    return distance_counter

func get_game_timer() -> Control:
    return game_timer