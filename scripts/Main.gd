extends Node2D

@export var base_speed: float = 250.0
@export var speed_gain_per_meter: float = 0.6

@onready var player = $Player
@onready var anomaly = $AnomalyChaser
@onready var terrain = $Ground
@onready var parallax = $ParallaxBackground
@onready var canvas = $CanvasLayer

func _ready() -> void:
    # Register this scene's nodes with the GameManager Autoload
    var nodes = {
        "player": player,
        "anomaly": anomaly,
        "terrain": terrain,
        "ground_a": terrain, # Assuming terrain is ground_a for now
        "parallax": parallax,
        "canvas": canvas
    }
    GameManager.register_game_nodes(nodes)

    # Initialize game speed in GameManager if needed
    GameManager.base_speed = base_speed
    GameManager.speed_gain_per_meter = speed_gain_per_meter

    # Start the game loop via GameManager
    # (Optional: GameManager might have its own start logic)
