extends Node2D

@export var start_speed_parallax: float = 1200.0
@export var target_speed_parallax: float = 600.0
@export var start_speed_terrain: float = 120.0
@export var target_speed_terrain: float = 50.0
@export var transition_duration: float = 2.0
@export var appear_delay: float = 1.2
@export var appear_duration: float = 0.8


func _ready() -> void:
	# Randomize terrain sebelum game dimulai
	var terrain_a := get_node_or_null("Terrain") as Node2D
	var terrain_b := get_node_or_null("TerrainB") as Node2D
	
	# Generate terrain baru dengan seed random (hanya jika belum digenerate)
	# Cek apakah terrain sudah punya tiles untuk menghindari double generation
	if terrain_a:
		var ground_a = terrain_a.get_node_or_null("Ground") as TileMapLayer
		if ground_a and ground_a.has_method("generate_random"):
			# Cek apakah sudah ada tiles (sudah digenerate)
			if ground_a.get_used_cells().size() == 0:
				ground_a.call("generate_random")
		elif terrain_a.has_method("generate_random"):
			if terrain_a.get_used_cells().size() == 0:
				terrain_a.call("generate_random")
	
	if terrain_b:
		var ground_b = terrain_b.get_node_or_null("Ground") as TileMapLayer
		if ground_b and ground_b.has_method("generate_random"):
			if ground_b.get_used_cells().size() == 0:
				ground_b.call("generate_random")
		elif terrain_b.has_method("generate_random"):
			if terrain_b.get_used_cells().size() == 0:
				terrain_b.call("generate_random")
	
	var parallax := get_node_or_null("ParallaxBackground") as ParallaxBackground
	if parallax:
		parallax.set("speed", 0.0)

	if terrain_a:
		terrain_a.set("speed", 0.0)
	if terrain_b:
		terrain_b.set("speed", 0.0)

	var player := get_node_or_null("Player") as Node2D
	if player:
		# Enable intro mode
		player.call("set_intro_mode", true)
		var cam := get_node_or_null("Camera2D") as Camera2D
		var vw := get_viewport().get_visible_rect().size.x
		var cam_x := (cam.global_position.x if cam else 0.0)
		var left_edge := cam_x - vw * 0.5
		player.global_position.x = left_edge - 120.0
		# Set Y position ke tinggi yang sama dengan manual position
		var target_y = player.get("manual_position").y
		player.global_position.y = target_y
		# Stop tween yang ada dulu
		player.call("kill_intro_tween")
		
		var twp := create_tween()
		player.call("set_intro_tween", twp)
		twp.tween_interval(appear_delay)
		twp.tween_property(player, "global_position:x", float(player.get("keep_x_px")), appear_duration)
		twp.tween_callback(Callable(self, "_on_player_appear_done"))

func _on_player_appear_done() -> void:
	var player := get_node_or_null("Player") as Node2D
	if player:
		# Kill intro tween dulu
		player.call("kill_intro_tween")
		# Disable intro mode, kembali ke manual control
		player.call("set_intro_mode", false)
	var parallax := get_node_or_null("ParallaxBackground") as ParallaxBackground
	if parallax:
		var tw := create_tween()
		tw.tween_property(parallax, "speed", target_speed_parallax, transition_duration)
	var terrain_a := get_node_or_null("Terrain") as Node2D
	var terrain_b := get_node_or_null("TerrainB") as Node2D
	if terrain_a:
		var tw2 := create_tween()
		tw2.tween_property(terrain_a, "speed", target_speed_terrain, transition_duration)
	if terrain_b:
		var tw3 := create_tween()
		tw3.tween_property(terrain_b, "speed", target_speed_terrain, transition_duration)
