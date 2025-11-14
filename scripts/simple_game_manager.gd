extends Node2D

# Quick game manager - essential features only
var game_active: bool = true
var score: int = 0
var distance: float = 0.0

@onready var player = $Player
@onready var terrain = $Terrain
@onready var parallax = $ParallaxBackground

func _ready() -> void:
	# Auto-connect player game over signal
	if player:
		player.connect("game_over_signal", Callable(self, "on_player_game_over"))

func _process(delta: float) -> void:
	if not game_active:
		return
	
	# Update score based on distance - match terrain speed
	var terrain_speed = 150.0
	distance += terrain_speed * delta
	score = int(distance / 10.0)

func on_player_game_over(_cause: String) -> void:
	game_active = false
	show_game_over()

func show_game_over() -> void:
	# Simple game over - restart with R key
	if Input.is_action_just_pressed("ui_accept"):
		restart_game()

func restart_game() -> void:
	game_active = true
	score = 0
	distance = 0.0
	
	# Reset player position if exists
	if player:
		player.position = Vector2(200, 600)
		if player.has_method("reset_player"):
			player.reset_player()
	
	# Notify terrain to reset
	if terrain and terrain.has_method("reset_terrain"):
		terrain.reset_terrain()

func get_game_state() -> Dictionary:
	return {
		"game_active": game_active,
		"score": score,
		"distance": distance
	}
