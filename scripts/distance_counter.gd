extends Control

@export var meters_per_tile: float = 1.0
@export var tiles_per_update: int = 5
@export var distance: float = 0.0:
    set(value):
        distance = value
        update_display()

@onready var distance_label = $Label

func _ready() -> void:
    update_display()

func update_display() -> void:
    if distance_label:
        distance_label.text = str(int(distance)) + " M"

func add_distance(tiles_traveled: int) -> void:
    distance += float(tiles_traveled) * meters_per_tile

func set_distance(value: float) -> void:
    distance = value

func reset() -> void:
    distance = 0.0