extends CharacterBody2D
class_name Player

# ===== MOVEMENT PARAMETERS =====
@export var run_speed: float = 200.0
@export var jump_velocity: float = -400.0
@export var jump_enabled: bool = true
@export var air_jumps: int = 0
@export var coyote_time: float = 0.1
@export var jump_buffer_time: float = 0.15
@export var gravity: float = 1200.0
@export var fall_multiplier: float = 1.5
@export var max_fall_speed: float = 2000.0
@export var low_jump_multiplier: float = 1.0
@export var jump_hold_gravity_scale: float = 1.0
@export var fall_death_y: float = 1000.0
@export var gap_fall_threshold: float = 300.0
@export var gap_fall_grace_time: float = 0.25
@export var lock_environment_speed_to_player: bool = true
@export var terrain_paths: Array[NodePath] = []

# ===== PERFORMANCE SETTINGS =====
@export var position_adjustment_speed: float = 3.0
@export var max_physics_iterations: int = 10
@export var enable_debug_logging: bool = false

# ===== VISUAL SETTINGS =====
@export var sprite_scale: Vector2 = Vector2(1.0, 1.0)  # Default 1:1 scale
@export var match_sprite_to_collision: bool = true
@export var preserve_editor_transform: bool = true
@export var collision_size: Vector2 = Vector2(48, 72)  # Optimized collision size (smaller = better gameplay feel)

# ===== POSITION SETTINGS (BISA DIUBAH DI INSPECTOR) =====
@export var screen_position_x: float = 0.3  # 0.0-1.0 (0%=kiri, 100%=kanan)
@export var screen_position_y: float = 0.75  # 0.0-1.0 (0%=atas, 100%=bawah)
@export var freeze_x_on_jump: bool = true  # Player tidak maju saat loncat
@export var jump_horizontal_damping: float = 0.1  # Redupsi kecepatan horizontal saat loncat (0.0-1.0)
@export var entry_stop_x: float = 280.0
@export var entry_stop_y: float = 444.0
@export var entry_duration_sec: float = 1.5
@export var entry_start_offset_x: float = -800.0
@export var front_check_distance: float = 24.0
@export var front_block_margin: float = 2.0
@export var front_probe_width: float = 2.0
@export var pushback_rate: float = 180.0
@export var pushback_recovery_rate: float = 60.0
@export var left_game_over_margin: float = 16.0
@export var max_pushback_offset: float = 220.0
@export var pushback_lock_x: float = 190.0
@export var air_recovery_rate: float = 120.0
@export var jump_block_grace_time: float = 0.12

# ===== STATE MANAGEMENT =====
enum PlayerState {
	HIDDEN,
	APPEARING,
	RUNNING_IN_PLACE,
	FULL_MOVEMENT,
	GAME_OVER
}

var current_state: PlayerState = PlayerState.HIDDEN
var state_timer: float = 0.0
var state_data: Dictionary = {}

# ===== MOVEMENT STATE =====
var is_grounded: bool = false
var can_jump: bool = true
var remaining_air_jumps: int = 0
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var jump_requested: bool = false
var attack_requested: bool = false

# ===== POSITION MANAGEMENT =====
var target_screen_position: Vector2 = Vector2.ZERO
var appear_start_position: Vector2 = Vector2.ZERO
var appear_target_position: Vector2 = Vector2.ZERO

# ===== REFERENCES =====
var game_manager: Node
var parallax_background: Node
var terrain_nodes: Array = []
var main_camera: Camera2D
var animated_sprite: AnimatedSprite2D
var ground_ray: RayCast2D
var title_screen: Control

# ===== SIGNALS =====
signal game_over_signal(cause: String)
signal state_changed(new_state: PlayerState, old_state: PlayerState)

var _last_env_speed: float = -1.0
var _pushback_offset: float = 0.0
var _desired_x: float = 0.0
var _prev_x: float = 0.0
var _block_cooldown: float = 0.0
var _front_clear_timer: float = 0.0
var _stuck_on_block: bool = false
var _stuck_anchor_x: float = 0.0
var _env_move_enabled: bool = false
var _jumping_this_frame: bool = false
var _jump_grace_timer: float = 0.0

func match_sprite_to_collision_size() -> void:
	# Get collision shape size
	var collision_shape = $CollisionShape2D
	if not collision_shape or not collision_shape.shape:
		return
	
	var shape_size = collision_shape.shape.size  # Vector2(64, 96)
	
	# Get first frame texture to determine original sprite size
	var sprite_frames = animated_sprite.sprite_frames
	if not sprite_frames or sprite_frames.get_frame_count("run") == 0:
		return
	
	var first_frame_texture = sprite_frames.get_frame_texture("run", 0)
	if not first_frame_texture:
		return
	
	var original_sprite_size = Vector2(first_frame_texture.get_width(), first_frame_texture.get_height())
	
	# Calculate exact scale to match collision size
	# Use 90% of collision size for better visual proportions and gameplay feel
	var target_scale_x = (shape_size.x * 0.9) / original_sprite_size.x
	var target_scale_y = (shape_size.y * 0.9) / original_sprite_size.y
	
	# Apply calculated scale
	var uniform_scale = min(target_scale_x, target_scale_y)
	var final_scale = Vector2(uniform_scale, uniform_scale)
	animated_sprite.scale = final_scale
	
	if enable_debug_logging and OS.is_debug_build():
		print("Sprite resized: original=", original_sprite_size, " collision=", shape_size, " scale=", final_scale)

func _ready() -> void:
	if not InputMap.has_action("jump"):
		InputMap.add_action("jump")
		var ev := InputEventKey.new()
		ev.physical_keycode = KEY_SPACE
		InputMap.action_add_event("jump", ev)
		var mev := InputEventMouseButton.new()
		mev.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event("jump", mev)
	if not InputMap.has_action("attack"):
		InputMap.add_action("attack")
		var kev := InputEventKey.new()
		kev.physical_keycode = KEY_K
		InputMap.action_add_event("attack", kev)
		var rmev := InputEventMouseButton.new()
		rmev.button_index = MOUSE_BUTTON_RIGHT
		InputMap.action_add_event("attack", rmev)
	initialize_player()
	setup_collision_layers()
	find_and_cache_references()
	calculate_screen_positions()
	start_initial_state_sequence()
	remaining_air_jumps = air_jumps

func initialize_player() -> void:
	visible = true
	set_process(true)
	set_physics_process(true)
	
	# Initialize collision shape size and position
	var collision_shape = get_node_or_null("CollisionShape2D")
	if collision_shape and collision_shape.shape is RectangleShape2D:
		var rect_shape = collision_shape.shape as RectangleShape2D
		if not preserve_editor_transform:
			rect_shape.size = collision_size
			collision_shape.position = Vector2(0, 0)
		if enable_debug_logging and OS.is_debug_build():
			print("Player collision initialized: size=", rect_shape.size, " position=", collision_shape.position)
	
	# Initialize sprite - AnimatedSprite2D sudah di-set manual di editor
	animated_sprite = get_node_or_null("AnimatedSprite2D")
	if animated_sprite:
		animated_sprite.play("run")
		animated_sprite.speed_scale = 1.0
		# Pastikan animasi berjalan otomatis
		if not animated_sprite.is_playing():
			animated_sprite.play("run")
		# Tidak perlu auto-scale karena sudah di-set manual di editor
		if enable_debug_logging and OS.is_debug_build():
			print("AnimatedSprite2D initialized: position=", animated_sprite.position, " scale=", animated_sprite.scale, " playing=", animated_sprite.is_playing())
		if match_sprite_to_collision and not preserve_editor_transform:
			match_sprite_to_collision_size()

	ground_ray = get_node_or_null("GroundRay")
	if ground_ray:
		ground_ray.collision_mask = 1
		ground_ray.enabled = true

func setup_collision_layers() -> void:
	collision_layer = 2  # Player layer
	collision_mask = 1   # Terrain layer

func find_and_cache_references() -> void:
	var main_node = get_tree().get_root().get_node_or_null("Main")
	if not main_node:
		push_error("Main node not found! Player references cannot be initialized.")
		return
	
	game_manager = main_node
	main_camera = main_node.get_node_or_null("Camera2D")
	parallax_background = main_node.get_node_or_null("ParallaxBackground")
	title_screen = main_node.get_node_or_null("CanvasLayer/TitleScreen")
	
	# Configure camera if found
	if main_camera:
		_setup_camera_limits()
	
	# Cache terrain nodes efficiently
	terrain_nodes.clear()
	for child in main_node.get_children():
		if child is Node2D and child.name.begins_with("Terrain"):
			terrain_nodes.append(child)
	
	if enable_debug_logging and OS.is_debug_build():
		print("Player references cached:", {
			"camera": main_camera != null,
			"parallax": parallax_background != null,
			"title_screen": title_screen != null,
			"terrain_count": terrain_nodes.size()
		})

func _setup_camera_limits() -> void:
	if not main_camera or not is_instance_valid(main_camera):
		return
	
	var viewport_size = get_viewport().get_visible_rect().size
	main_camera.limit_left = -1000
	main_camera.limit_top = 0
	main_camera.limit_right = 10000
	main_camera.limit_bottom = viewport_size.y
	main_camera.position_smoothing_enabled = true
	main_camera.position_smoothing_speed = 8.0

func calculate_screen_positions() -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	# POSISI PLAYER DI LAYAR - BISA DIUBAH DI INSPECTOR
	target_screen_position = Vector2(viewport_size.x * screen_position_x, viewport_size.y * screen_position_y)
	
	# Calculate world positions based on camera
	if main_camera:
		var camera_pos = main_camera.position
		var world_offset = Vector2(
			target_screen_position.x - viewport_size.x * 0.5,
			target_screen_position.y - viewport_size.y * 0.5
		)
		appear_target_position = camera_pos + world_offset
	else:
		appear_target_position = Vector2(300, 480)  # Fallback
	
	appear_start_position = appear_target_position - Vector2(800, 0)  # Mulai dari lebih jauh kiri

func start_initial_state_sequence() -> void:
	if title_screen:
		set_state(PlayerState.HIDDEN)
		title_screen.show_title()
	else:
		set_state(PlayerState.HIDDEN)
		await get_tree().create_timer(1.0).timeout
		set_state(PlayerState.APPEARING)

func start_appearance_from_left(target: Vector2) -> void:
	appear_target_position = target
	appear_start_position = Vector2(target.x + entry_start_offset_x, target.y)
	position = appear_start_position
	set_state(PlayerState.APPEARING)

# ===== REMOVED REDUNDANT FUNCTIONS =====
# The following functions have been integrated into the new state management system:
# - position_player_on_screen() -> integrated into calculate_screen_positions()
# - configure_camera() -> integrated into find_and_cache_references()
# - find_references() -> renamed to find_and_cache_references()
# - find_ground_position() -> will be added when terrain collision needed
# - find_optimal_spawn_position() -> integrated into state system
# - start_appearance_animation() -> integrated into start_initial_state_sequence()
# - start_running_in_place() -> integrated into state transitions
# - start_full_movement() -> integrated into state transitions

func _physics_process(delta: float) -> void:
	match current_state:
		PlayerState.HIDDEN:
			handle_hidden_state(delta)
		PlayerState.APPEARING:
			handle_appearing_state(delta)
		PlayerState.RUNNING_IN_PLACE:
			handle_running_in_place_state(delta)
		PlayerState.FULL_MOVEMENT:
			handle_full_movement_state(delta)
		PlayerState.GAME_OVER:
			handle_game_over_state(delta)
	
	# Apply physics dan collision detection
	# Pastikan player tetap di tanah di state tertentu (kecuali FULL_MOVEMENT)
	if current_state == PlayerState.APPEARING or current_state == PlayerState.RUNNING_IN_PLACE:
		# Force player to stay on ground pada fase awal
		if is_on_floor() or current_state == PlayerState.APPEARING:
			velocity.y = 0
		elif enable_debug_logging and OS.is_debug_build() and state_timer < 0.5:
			print("WARNING: Player left ground in ", current_state, " state! position: ", position, " velocity: ", velocity)
		# Kunci posisi Y saat muncul/diam
		position.y = entry_stop_y
	
		apply_physics(delta)
		check_game_over_conditions()
	elif current_state == PlayerState.FULL_MOVEMENT:
		apply_physics(delta)
		check_game_over_conditions()
		sync_environment_speed_if_needed()

func handle_hidden_state(_delta: float) -> void:
	velocity = Vector2.ZERO
	visible = false
	if animated_sprite and animated_sprite.is_playing():
		animated_sprite.stop()
		if enable_debug_logging and OS.is_debug_build():
			print("Animation stopped in HIDDEN state")

func handle_appearing_state(delta: float) -> void:
	visible = true
	state_timer += delta
	
	if enable_debug_logging and OS.is_debug_build() and state_timer < 0.1:  # Log hanya sekali di awal
		print("APPEARING state started - position: ", position, " visible: ", visible)
	
	# Gerakkan player dari kiri ke posisi entry_stop_x (200px)
	var target_x = entry_stop_x
	var progress = clamp(state_timer / max(entry_duration_sec, 0.0001), 0.0, 1.0)
	position.x = lerp(appear_start_position.x, target_x, progress)
	
	# LOCK Y position to prevent upward movement during appearance
	position.y = entry_stop_y
	velocity.y = 0  # Prevent any vertical movement
	
	# Animation speed based on movement
	if animated_sprite:
		if animated_sprite.animation != "run":
			animated_sprite.play("run")
		animated_sprite.speed_scale = 1.2
		# Pastikan animasi tetap berjalan
		if not animated_sprite.is_playing():
			animated_sprite.play("run")
	
	# Transition to next state when done
	if progress >= 1.0:
		if enable_debug_logging and OS.is_debug_build():
			print("APPEARING completed - final position: ", position)
		set_state(PlayerState.RUNNING_IN_PLACE)

func handle_running_in_place_state(delta: float) -> void:
	state_timer += delta
	
	# Player diam di posisi entry_stop_x (200px) - PASTIKAN tidak bergerak
	velocity.x = 0  # Tidak bergerak horizontal
	velocity.y = 0  # Juga tidak jatuh
	
	# LOCK position exactly at entry_stop_x
	position.x = entry_stop_x
	position.y = entry_stop_y
	
	# Debug log position
	if enable_debug_logging and OS.is_debug_build() and state_timer < 0.5:  # Log first few frames
		print("RUNNING_IN_PLACE - position: ", position, " velocity: ", velocity)
	
	# Pastikan animasi run berjalan
	if animated_sprite:
		if animated_sprite.animation != "run":
			animated_sprite.play("run")
		animated_sprite.speed_scale = 1.0
		if not animated_sprite.is_playing():
			animated_sprite.play("run")
	
	# SKIP maintain_screen_position - ini menyebabkan gerakan!
	
	
	# JANGAN aktifkan parallax/terrain lagi - sudah diaktifkan di APPEARING state
	# Transition to next state when done
	if state_timer >= 1.2:
		if enable_debug_logging and OS.is_debug_build():
			print("Parallax and terrain movement activated!")
		
		set_state(PlayerState.FULL_MOVEMENT)

func handle_full_movement_state(_delta: float) -> void:
	state_timer += _delta
	# Player tetap di posisi X=200, terrain yang bergerak
	velocity.x = 0  # Player tidak bergerak horizontal

	var env_moving := _is_environment_moving()
	if not env_moving:
		position.x = entry_stop_x
		_prev_x = position.x
	else:
		_desired_x = entry_stop_x - _pushback_offset
		var front_block := _blocked_ahead(front_check_distance) or _block_cooldown > 0.0
		var allow_forward := (not _stuck_on_block) and (not front_block) and ((_front_clear_timer > 0.2) or not is_on_floor())
		if allow_forward:
			position.x = _desired_x
		else:
			var anchor_x: float = _stuck_anchor_x if _stuck_on_block else _prev_x
			position.x = min(anchor_x, _desired_x)
		position.x = min(entry_stop_x, position.x)
		if is_on_floor():
			if position.x < _prev_x:
				_prev_x = position.x
		else:
			_prev_x = max(_prev_x, position.x)
		_apply_pushback(_delta)
	# Stabilkan posisi Y tepat setelah transisi agar tidak terjadi penyesuaian mendadak
	if state_timer < 0.2:
		position.y = entry_stop_y
		velocity.y = 0
	
		# Debug log position and ground status
		if enable_debug_logging and OS.is_debug_build() and state_timer < 1.0:  # Log first few frames
			pass
	
	# Debug log if position changes unexpectedly
	if enable_debug_logging and OS.is_debug_build() and abs(position.x - entry_stop_x) > 1.0:
		print("WARNING: Player X position changed! Expected: ", entry_stop_x, " Actual: ", position.x)
	
	# Handle horizontal movement - freeze saat loncat jika diaktifkan
	if freeze_x_on_jump and not is_on_floor():
		# Saat di udara, kurangi/diamkan gerakan horizontal
		velocity.x = velocity.x * (1.0 - jump_horizontal_damping)
	
	# Handle jump input
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
		jump_requested = true
	if Input.is_action_just_pressed("attack"):
		attack_requested = true
		if enable_debug_logging and OS.is_debug_build():
			print("Attack triggered")
	
	# Control animation based on state
	update_animation_state()
	# SKIP maintain_screen_position - player harus tetap di X=200
	

func handle_game_over_state(_delta: float) -> void:
	velocity = Vector2.ZERO
	if animated_sprite and animated_sprite.is_playing():
		animated_sprite.stop()

func apply_physics(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		var g := gravity
		if velocity.y < 0.0:
			var hold := Input.is_action_pressed("jump")
			g = gravity * (jump_hold_gravity_scale if hold else low_jump_multiplier)
		else:
			g = gravity * fall_multiplier
		velocity.y += g * delta
		if max_fall_speed > 0.0 and velocity.y > max_fall_speed:
			velocity.y = max_fall_speed
	
	# Prevent ceiling collision
	if position.y < 50:
		position.y = 50
		velocity.y = max(velocity.y, 0)
	
	# Move with collision - use proper floor detection
	var was_on_floor = is_on_floor()
	# Use move_and_slide with floor detection parameters
	# Set up_floor_snap_length to prevent tiny movements
	set_up_direction(Vector2.UP)
	var ray_ok := ground_ray != null and ground_ray.is_enabled() and ground_ray.is_colliding()
	_jump_grace_timer = max(_jump_grace_timer - delta, 0.0)
	var blocked_front := is_on_floor() and _blocked_ahead(front_check_distance) and _jump_grace_timer <= 0.0
	var should_snap := is_on_floor() and ray_ok and not _has_gap_below(gap_fall_threshold) and not blocked_front
	var snap_len := 6.0 if should_snap else 0.0
	set_floor_snap_length(snap_len)
	if was_on_floor:
		coyote_timer = coyote_time
		remaining_air_jumps = air_jumps
	else:
		coyote_timer = max(coyote_timer - delta, 0.0)
	if jump_buffer_timer > 0.0:
		jump_buffer_timer = max(jump_buffer_timer - delta, 0.0)
	if jump_enabled and jump_requested and jump_buffer_timer > 0.0:
		var can_use_air := remaining_air_jumps > 0
		var can_perform := is_on_floor() or coyote_timer > 0.0 or can_use_air
		if can_perform:
			velocity.y = jump_velocity
			_jumping_this_frame = true
			_jump_grace_timer = jump_block_grace_time
			if not is_on_floor() and coyote_timer <= 0.0 and can_use_air:
				remaining_air_jumps -= 1
			var sfx2 := get_tree().get_root().get_node_or_null("Main/SFXJump")
			if sfx2 and sfx2 is AudioStreamPlayer and sfx2.stream != null:
				(sfx2 as AudioStreamPlayer).play()
			jump_requested = false
			jump_buffer_timer = 0.0
	move_and_slide()
	if current_state == PlayerState.FULL_MOVEMENT and _is_environment_moving() and blocked_front and is_on_floor():
		var target_x: float = min(entry_stop_x, min(_prev_x, _desired_x))
		if position.x > target_x:
			position.x = target_x
	if blocked_front and is_on_floor() and not _jumping_this_frame and velocity.y > 0.0:
		velocity.y = max(velocity.y, 0)
	
	
	# Debug log if floor status changes unexpectedly
	if enable_debug_logging and OS.is_debug_build() and was_on_floor and not is_on_floor() and state_timer < 1.0:
		print("WARNING: Player left floor unexpectedly! was_on_floor: ", was_on_floor, " now_on_floor: ", is_on_floor(), " position: ", position, " velocity: ", velocity)
	
	# Update grounded state - simplified
	is_grounded = is_on_floor()
	_jumping_this_frame = false

func _has_gap_below(ray_len: float) -> bool:
	var space := get_world_2d().direct_space_state
	var half_w := collision_size.x * 0.5
	var foot_y := global_position.y + collision_size.y * 0.5 - 1.0
	var ray_len_clamped: float = min(ray_len, collision_size.y * 1.2)
	var start_left := Vector2(global_position.x - half_w + 2.0, foot_y)
	var start_mid := Vector2(global_position.x, foot_y)
	var start_right := Vector2(global_position.x + half_w - 2.0, foot_y)
	var end_left := start_left + Vector2(0, max(ray_len_clamped, 1.0))
	var end_mid := start_mid + Vector2(0, max(ray_len_clamped, 1.0))
	var end_right := start_right + Vector2(0, max(ray_len_clamped, 1.0))
	var pleft := PhysicsRayQueryParameters2D.create(start_left, end_left, 1, [self])
	var pmid := PhysicsRayQueryParameters2D.create(start_mid, end_mid, 1, [self])
	var pright := PhysicsRayQueryParameters2D.create(start_right, end_right, 1, [self])
	var r1 := space.intersect_ray(pleft)
	var r2 := space.intersect_ray(pmid)
	var r3 := space.intersect_ray(pright)
	return r1.is_empty() and r2.is_empty() and r3.is_empty()

func check_game_over_conditions() -> void:
	var viewport_rect = get_viewport().get_visible_rect()
	if current_state == PlayerState.FULL_MOVEMENT and _is_environment_moving():
		var off_screen_threshold: float = float(viewport_rect.size.y) + 200.0
		var threshold: float = fall_death_y
		if threshold > 0.0:
			if position.y > threshold or position.y > off_screen_threshold:
				trigger_game_over("fell_off_screen")
		else:
			if position.y > off_screen_threshold:
				trigger_game_over("fell_off_screen")
		var left_bound_world: float = 0.0
		if main_camera:
			left_bound_world = main_camera.position.x - float(viewport_rect.size.x) * 0.5
		if _pushback_offset > 0.0 and state_timer > 0.5 and position.x < left_bound_world + left_game_over_margin:
			trigger_game_over("left_screen")

func update_animation_state() -> void:
	if not animated_sprite:
		return
	
	if is_on_floor():
		if animated_sprite.animation != "run" and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("run"):
			animated_sprite.play("run")
		animated_sprite.speed_scale = 1.0
	else:
		if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("run") and animated_sprite.animation != "run":
			animated_sprite.play("run")
		animated_sprite.speed_scale = 0.8

func maintain_screen_position() -> void:
	if not main_camera or not is_instance_valid(main_camera):
		return
	
	# Hanya maintain vertical position, horizontal tetap di X=200
	# Player tidak boleh bergerak horizontal - terrain yang bergerak
	pass

func set_state(new_state: PlayerState) -> void:
	var old_state = current_state
	current_state = new_state
	state_timer = 0.0
	
	if enable_debug_logging and OS.is_debug_build():
		print("State transition: ", old_state, " -> ", new_state, " position: ", position, " is_on_floor: ", is_on_floor())
	
	if state_data.has("fall_start_y"):
		state_data.erase("fall_start_y")
	
	match new_state:
		PlayerState.HIDDEN:
			position = appear_start_position
			velocity = Vector2.ZERO
			_pushback_offset = 0.0
		PlayerState.APPEARING:
			visible = true
			enable_environment_movement(false)
			_pushback_offset = 0.0
		PlayerState.RUNNING_IN_PLACE:
			position.x = entry_stop_x
			visible = true
			_pushback_offset = 0.0
			_prev_x = position.x
			_block_cooldown = 0.0
		PlayerState.FULL_MOVEMENT:
			visible = true
			if is_on_floor():
				velocity.y = 0
				position.y = entry_stop_y
			_prev_x = entry_stop_x
			_pushback_offset = 0.0
			_block_cooldown = 0.0
			_front_clear_timer = 0.0
			_stuck_on_block = false
			_stuck_anchor_x = entry_stop_x
			if lock_environment_speed_to_player:
				set_environment_speed(run_speed)
		PlayerState.GAME_OVER:
			velocity = Vector2.ZERO
			enable_environment_movement(false)
	
	state_changed.emit(new_state, old_state)

func set_environment_speed(speed: float) -> void:
	var nodes := _get_terrain_nodes()
	for n in nodes:
		if n and n.has_method("set_speed"):
			n.set_speed(speed)
	if parallax_background and parallax_background.has_method("set_speed"):
		parallax_background.set_speed(speed)

func sync_environment_speed_if_needed() -> void:
	if not lock_environment_speed_to_player:
		return
	if current_state == PlayerState.FULL_MOVEMENT:
		if _last_env_speed != run_speed:
			set_environment_speed(run_speed)
			_last_env_speed = run_speed

func enable_environment_movement(enable: bool) -> void:
	# Kontrol parallax background movement
	var parallax_bg = get_tree().get_root().get_node_or_null("Main/ParallaxBackground")
	if parallax_bg and parallax_bg.has_method("set_movement_enabled"):
		parallax_bg.set_movement_enabled(enable)
		if enable_debug_logging and OS.is_debug_build():
			print("Parallax movement ", "enabled" if enable else "disabled")
	
	# Kontrol terrain scrolling
	var nodes := _get_terrain_nodes()
	for n in nodes:
		if n and n.has_method("set_movement_enabled"):
			n.set_movement_enabled(enable)
			if enable_debug_logging and OS.is_debug_build():
				print(str(n.name), " movement ", "enabled" if enable else "disabled")
	
	if enable_debug_logging:
		print("Environment movement ", "enabled" if enable else "disabled")
	_env_move_enabled = enable

func _is_environment_moving() -> bool:
	var nodes := _get_terrain_nodes()
	for n in nodes:
		if n and n.has_method("get_speed"):
			var sp := float(n.get_speed())
			if sp > 0.0:
				return true
		var me := false
		if n and n.has_method("get"):
			me = bool(n.get("movement_enabled")) if n.has_method("get") else false
		if me:
			return true
	if parallax_background and parallax_background.has_method("get"):
		var pm := bool(parallax_background.get("movement_enabled"))
		if pm:
			return true
	return _env_move_enabled

func _input(event: InputEvent) -> void:
	if current_state != PlayerState.FULL_MOVEMENT:
		return
	
	# Validate event and player state
	if not event or not is_instance_valid(self):
		return
	
	# Handle screen tap/click for jump with proper validation
	var is_valid_jump_event = (event is InputEventScreenTouch or event is InputEventMouseButton)
	if is_valid_jump_event and event.is_pressed():
		jump_buffer_timer = jump_buffer_time
		jump_requested = true

func trigger_game_over(cause: String) -> void:
	if current_state == PlayerState.GAME_OVER:
		return
	
	set_state(PlayerState.GAME_OVER)
	
	# Notify game manager
	if game_manager and game_manager.has_method("on_player_game_over"):
		game_manager.on_player_game_over(cause)
	
	# Emit signal for other listeners
	game_over_signal.emit(cause)

func reset_player() -> void:
	velocity = Vector2.ZERO
	state_timer = 0.0
	
	# Reset to initial state sequence
	set_state(PlayerState.HIDDEN)
	start_initial_state_sequence()

func get_player_state() -> Dictionary:
	return {
		"position": position,
		"velocity": velocity,
		"is_grounded": is_grounded,
		"current_state": current_state,
		"state_timer": state_timer
	}

func _get_terrain_nodes() -> Array:
	var nodes: Array = []
	if terrain_paths.size() > 0:
		for p in terrain_paths:
			var n := get_tree().get_root().get_node_or_null(p)
			if n:
				nodes.append(n)
	elif terrain_nodes.size() > 0:
		nodes = terrain_nodes.duplicate()
	else:
		var main_node := get_tree().get_root().get_node_or_null("Main")
		if main_node:
			for child in main_node.get_children():
				if child is Node2D and child.name.begins_with("Terrain"):
					nodes.append(child)
	return nodes

func _blocked_ahead(dist: float) -> bool:
	var half_w := collision_size.x * 0.5
	var foot_y := global_position.y + collision_size.y * 0.5 - 2.0
	var mid_y := global_position.y
	var d: float = min(dist, front_block_margin)
	var from1 := Vector2(global_position.x + half_w, foot_y)
	var to1 := Vector2(from1.x + max(d, 0.5), foot_y)
	var from2 := Vector2(global_position.x + half_w, mid_y)
	var to2 := Vector2(from2.x + max(d, 0.5), mid_y)
	var space := get_world_2d().direct_space_state
	var r1 := space.intersect_ray(PhysicsRayQueryParameters2D.create(from1, to1, 1, [self]))
	if not r1.is_empty():
		return true
	var r2 := space.intersect_ray(PhysicsRayQueryParameters2D.create(from2, to2, 1, [self]))
	if not r2.is_empty():
		return true
	# Narrow front probe to avoid early blocking due to full body shape
	var probe := RectangleShape2D.new()
	probe.size = Vector2(max(front_probe_width, 0.5), max(collision_size.y - 2.0, 1.0))
	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = probe
	var xf := Transform2D.IDENTITY
	xf.origin = global_position + Vector2(half_w + probe.size.x * 0.5, 0)
	params.transform = xf
	params.collision_mask = 1
	params.exclude = [self]
	var res := space.intersect_shape(params, 1)
	if res.size() > 0:
		return true
	return false

func _apply_pushback(delta: float) -> void:
	var blocked := is_on_floor() and _blocked_ahead(front_check_distance)
	if blocked:
		_pushback_offset = min(max_pushback_offset, _pushback_offset + pushback_rate * delta)
		_block_cooldown = 0.15
		_front_clear_timer = 0.0
		if not _stuck_on_block:
			_stuck_on_block = true
			_stuck_anchor_x = position.x
		else:
			_stuck_anchor_x = min(_stuck_anchor_x, position.x)
	else:
		_block_cooldown = max(0.0, _block_cooldown - delta)
		_front_clear_timer += delta
		var can_recover := (not is_on_floor()) or _front_clear_timer > 0.25
		if can_recover:
			var recover_speed: float = air_recovery_rate if not is_on_floor() else pushback_recovery_rate
			_pushback_offset = max(0.0, _pushback_offset - recover_speed * delta)
			_stuck_on_block = false
