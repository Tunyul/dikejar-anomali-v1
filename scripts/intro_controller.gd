extends Node2D

@export var start_speed_parallax: float = 1200.0
@export var target_speed_parallax: float = 600.0
@export var start_speed_terrain: float = 120.0
@export var target_speed_terrain: float = 50.0
@export var transition_duration: float = 2.0


func _ready() -> void:
	var parallax := get_node_or_null("ParallaxBackground") as ParallaxBackground
	if parallax:
		parallax.set("speed", start_speed_parallax)
		var tw := create_tween()
		tw.tween_property(parallax, "speed", target_speed_parallax, transition_duration)

	var terrain_a := get_node_or_null("Terrain") as Node2D
	var terrain_b := get_node_or_null("TerrainB") as Node2D
	if terrain_a:
		terrain_a.set("speed", start_speed_terrain)
		var tw2 := create_tween()
		tw2.tween_property(terrain_a, "speed", target_speed_terrain, transition_duration)
	if terrain_b:
		terrain_b.set("speed", start_speed_terrain)
		var tw3 := create_tween()
		tw3.tween_property(terrain_b, "speed", target_speed_terrain, transition_duration)

	var cam := get_node_or_null("Terrain/Player/Camera2D") as Camera2D
	if cam:
		var base_off := cam.offset
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		var tw5 := create_tween()
		for i in range(6):
			var j := Vector2(rng.randf_range(-8.0, 8.0), rng.randf_range(-5.0, 5.0))
			tw5.tween_property(cam, "offset", base_off + j, 0.06)
		tw5.tween_property(cam, "offset", base_off, 0.1)
