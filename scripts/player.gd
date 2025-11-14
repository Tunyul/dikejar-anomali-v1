extends CharacterBody2D

# Movement parameters
@export var run_speed: float = 200.0
@export var jump_velocity: float = -400.0
@export var gravity: float = 1200.0
@export var fall_death_y: float = 1000.0

# Animation phases
enum AnimationPhase {
	HIDDEN,
	APPEARING,
	RUNNING_IN_PLACE,
	FULL_MOVEMENT
}
var current_phase: AnimationPhase = AnimationPhase.HIDDEN
var appear_speed: float = 400.0
var appear_target_x: float = 150.0
var animation_timer: float = 0.0

# Game state
var game_over: bool = false
var is_grounded: bool = false
var start_delay: float = 0.5
var can_move: bool = false

# Signals
signal game_over_signal(cause: String)

# References
var game_manager: Node
var parallax_background: Node
var terrain_nodes: Array = []
var main_camera: Camera2D

func _ready() -> void:
	# Player enabled by default for gameplay
	visible = true
	set_process(true)
	set_physics_process(true)
	
	# Set up collision layers - Player on layer 2, collides with terrain on layer 1
	collision_layer = 2
	collision_mask = 1
	
	# Find references
	find_references()
	
	# Start animation sequence
	start_appearance_animation()
	
	# Find game manager
	var main_node = get_tree().get_root().get_node_or_null("Main")
	if main_node:
		game_manager = main_node

func position_player_on_screen() -> void:
	# Position player at consistent screen position using external camera
	if main_camera:
		# Use fixed camera position (360, 360) from Main scene
		var camera_pos = Vector2(360, 360)
		var viewport_size = get_viewport().get_visible_rect().size
		
		# Player should appear 30% from left edge, 25% from bottom of screen
		var target_screen_x = viewport_size.x * 0.3  # 30% from left edge
		var target_screen_y = viewport_size.y * 0.75  # 25% from bottom
		
		# Calculate world position based on fixed camera position
		var world_pos = camera_pos + Vector2(target_screen_x - viewport_size.x * 0.5, target_screen_y - viewport_size.y * 0.5)
		position = Vector2(world_pos.x, position.y)  # Keep Y position, set X

func configure_camera() -> void:
	# Configure external camera from Main scene
	var main_node = get_tree().get_root().get_node_or_null("Main")
	if main_node:
		main_camera = main_node.get_node_or_null("Camera2D")
		if main_camera:
			var viewport_size = get_viewport().get_visible_rect().size
			
			# Set camera limits based on viewport
			main_camera.limit_left = -1000
			main_camera.limit_top = 0
			main_camera.limit_right = 10000
			main_camera.limit_bottom = viewport_size.y
			
			# Enable smoothing for smooth following
			main_camera.position_smoothing_enabled = true
			main_camera.position_smoothing_speed = 8.0
			return
	
	# Fallback: try to find camera in current scene
	main_camera = get_node_or_null("Camera2D")
	if main_camera:
		var viewport_size = get_viewport().get_visible_rect().size
		main_camera.limit_left = -1000
		main_camera.limit_top = 0
		main_camera.limit_right = 10000
		main_camera.limit_bottom = viewport_size.y
		main_camera.position_smoothing_enabled = true
		main_camera.position_smoothing_speed = 8.0

func find_references() -> void:
	# Find parallax background and terrain nodes
	var main_node = get_tree().get_root().get_node_or_null("Main")
	if main_node:
		parallax_background = main_node.get_node_or_null("ParallaxBackground")
		
		# Find terrain nodes
		terrain_nodes.clear()
		for child in main_node.get_children():
			if child.name.begins_with("Terrain"):
				terrain_nodes.append(child)

func find_ground_position(target_x: float) -> float:
	# Find the ground Y position at the target X coordinate
	var ground_y = 400.0  # Default fallback position
	
	for terrain in terrain_nodes:
		if terrain and terrain.has_node("Ground"):
			var ground = terrain.get_node("Ground")
			if ground and ground is TileMapLayer:
				# Get tile at position - convert world position to tile position
				var tile_pos = ground.local_to_map(Vector2(target_x - terrain.position.x, 0))
				# Check for ground tiles at this position (assuming ground tiles are at lower Y values)
				for y in range(-10, 10):  # Check vertical range
					var offset = Vector2i(0, y)
					var check_pos = Vector2i(tile_pos.x + offset.x, tile_pos.y + offset.y)
					var cell_data = ground.get_cell_tile_data(check_pos)
					if cell_data:
						# Found a tile, calculate ground surface position
						var tile_world_pos = ground.map_to_local(check_pos)
						ground_y = terrain.position.y + tile_world_pos.y - 96  # Adjust for player height (96px)
						break
				break
	
	return ground_y

func find_optimal_spawn_position() -> Vector2:
	# Use manual Y position if set in editor, otherwise find terrain ground
	var spawn_x = -200.0  # Further left off-screen
	var spawn_y = 500.0  # Use your manually set Y position
	return Vector2(spawn_x, spawn_y)

func start_appearance_animation() -> void:
	# Phase 1: Hidden - player starts off-screen to the left, aligned with terrain
	current_phase = AnimationPhase.HIDDEN
	
	# Find optimal spawn position aligned with terrain
	var optimal_spawn = find_optimal_spawn_position()
	position = optimal_spawn
	
	# Start appearing after a short delay
	await get_tree().create_timer(0.8).timeout
	current_phase = AnimationPhase.APPEARING

func start_running_in_place() -> void:
	# Phase 3: Running in place while environment starts moving
	current_phase = AnimationPhase.RUNNING_IN_PLACE
	can_move = true  # Enable running animation
	
	# Position player at consistent screen position
	position_player_on_screen()
	
	# Start environment movement after running in place
	await get_tree().create_timer(1.2).timeout
	start_full_movement()

func start_full_movement() -> void:
	# Phase 4: Full movement - environment moves, player runs in place
	current_phase = AnimationPhase.FULL_MOVEMENT
	enable_environment_movement(true)

func _physics_process(delta: float) -> void:
	if game_over:
		return
	
	# Handle different animation phases
	match current_phase:
		AnimationPhase.HIDDEN:
			# Player is hidden off-screen
			velocity = Vector2.ZERO
			return
			
		AnimationPhase.APPEARING:
			# Player runs in from left side
			handle_appearing_phase(delta)
			return
			
		AnimationPhase.RUNNING_IN_PLACE:
			# Player runs in place while environment prepares to move
			handle_running_in_place_phase(delta)
			
		AnimationPhase.FULL_MOVEMENT:
			# Normal gameplay - player runs in place, environment moves
			handle_full_movement_phase(delta)
	
	# Apply gravity and collision detection for phases that need it
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# Move and slide with collision detection
	move_and_slide()
	
	# Check if grounded by analyzing collision normal
	is_grounded = false
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if collision.get_normal().y < -0.7:  # Floor collision (normal pointing up)
			is_grounded = true
			break
	
	# Also check if we're on floor using built-in method as backup
	if not is_grounded:
		is_grounded = is_on_floor()
	
	# Check for fall death
	if position.y > fall_death_y:
		trigger_game_over("fell")
	
	# Check if player fell off screen
	var viewport_rect = get_viewport().get_visible_rect()
	if position.y > viewport_rect.size.y + 200:
		trigger_game_over("fell_off_screen")

func handle_appearing_phase(delta: float) -> void:
	# Move player from left side into view
	if position.x < appear_target_x:
		position.x += appear_speed * delta
		velocity.x = appear_speed * 0.7  # Running animation speed
		velocity.y = 0
	else:
		# Player has appeared, transition to running in place
		position.x = appear_target_x
		start_running_in_place()

func handle_running_in_place_phase(_delta: float) -> void:
	# Player runs in place at target position
	velocity.x = run_speed  # Running animation
	velocity.y = 0  # Stay on ground
	
	# Keep player at fixed position while running
	position.x = appear_target_x
	
	# Ensure player stays at screen position using camera reference
	if main_camera:
		var viewport_size = get_viewport().get_visible_rect().size
		var target_screen_x = viewport_size.x * 0.3  # 30% from left edge
		var camera_pos = Vector2(360, 360)
		var world_pos = camera_pos + Vector2(target_screen_x - viewport_size.x * 0.5, 0)
		position.x = world_pos.x

func handle_full_movement_phase(_delta: float) -> void:
	# Normal gameplay - running in place, world moves around player
	velocity.x = run_speed  # Running animation
	
	# Keep player at fixed screen position while world moves
	position.x = appear_target_x
	
	# Ensure player stays at screen position using camera reference
	if main_camera:
		var viewport_size = get_viewport().get_visible_rect().size
		var target_screen_x = viewport_size.x * 0.3  # 30% from left edge
		var camera_pos = Vector2(360, 360)
		var world_pos = camera_pos + Vector2(target_screen_x - viewport_size.x * 0.5, 0)
		position.x = world_pos.x
	
	# Handle jump input (screen tap/click)
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

func enable_environment_movement(enable: bool) -> void:
	# Enable/disable parallax background movement
	if parallax_background and parallax_background.has_method("set_movement_enabled"):
		parallax_background.set_movement_enabled(enable)
		if parallax_background.has_method("set_speed"):
			parallax_background.set_speed(run_speed if enable else 0.0)
	
	# Enable/disable terrain movement
	for terrain in terrain_nodes:
		if terrain and terrain.has_method("set_movement_enabled"):
			terrain.set_movement_enabled(enable)
		elif terrain and terrain.has_method("set_speed"):
			terrain.set_speed(run_speed if enable else 0.0)

func _input(event: InputEvent) -> void:
	if game_over:
		return
	
	# Handle screen tap/click for jump
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event.is_pressed() and is_on_floor():
			velocity.y = jump_velocity

func trigger_game_over(cause: String) -> void:
	if game_over:
		return
	
	game_over = true
	velocity = Vector2.ZERO
	
	# Notify game manager
	if game_manager and game_manager.has_method("on_player_game_over"):
		game_manager.on_player_game_over(cause)
	
	# Emit signal for other listeners
	game_over_signal.emit(cause)

func reset_player() -> void:
	game_over = false
	velocity = Vector2.ZERO
	position = Vector2(100, 300)  # Starting position

func get_player_state() -> Dictionary:
	return {
		"position": position,
		"velocity": velocity,
		"is_grounded": is_grounded,
		"game_over": game_over
	}
