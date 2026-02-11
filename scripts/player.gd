extends CharacterBody2D
class_name Player

# ===== MOVEMENT PARAMETERS =====
@export var run_speed: float = 200.0
@export var jump_velocity: float = -400.0
@export var jump_enabled: bool = true
@export var coyote_time: float = 0.1
@export var jump_buffer_time: float = 0.15
@export var gravity: float = 1200.0
@export var fall_multiplier: float = 1.5
@export var max_fall_speed: float = 2000.0
@export var low_jump_multiplier: float = 1.0
@export var jump_hold_gravity_scale: float = 1.0
@export var fall_death_y: float = 800.0
@export var enable_fall_death: bool = true
@export var gap_fall_threshold: float = 300.0
@export var gap_fall_grace_time: float = 0.25
@export var speed_boost_fly_height: float = 120.0
@export var speed_boost_ceiling_y: float = 50.0
@export var lock_environment_speed_to_player: bool = true
@export var terrain_paths: Array[NodePath] = []
@export var attack_duration: float = 0.3
@export var max_health: int = 100
@export var starting_health: int = 100
@export var damage_knockback_horizontal: float = 260.0
@export var damage_knockback_vertical: float = -420.0
@export var hit_invincibility_sec: float = 1.0
@export var hit_blink_interval_sec: float = 0.1
@export var anomaly_instant_game_over: bool = true
@export var anomaly_damage: int = 20

# ===== PERFORMANCE SETTINGS =====
@export var position_adjustment_speed: float = 3.0
@export var max_physics_iterations: int = 10
@export var enable_debug_logging: bool = false
@export var auto_recenter_x: bool = true
@export var recenter_speed_x: float = 150.0
@export var recenter_use_linear: bool = true

# ===== VISUAL SETTINGS =====
@export var sprite_scale: Vector2 = Vector2(1.0, 1.0)  # Default 1:1 scale
@export var match_sprite_to_collision: bool = true
@export var preserve_editor_transform: bool = true
@export var collision_size: Vector2 = Vector2(48, 72)  # Optimized collision size (smaller = better gameplay feel)
@export var preserve_editor_sprite_scale: bool = true
@export var run_scale_override: float = 0.0
@export var jump_scale_override: float = 0.0

# ===== POSITION SETTINGS (BISA DIUBAH DI INSPECTOR) =====
@export var freeze_x_on_jump: bool = true  # Player tidak maju saat loncat
@export var jump_horizontal_damping: float = 0.1  # Redupsi kecepatan horizontal saat loncat (0.0-1.0)
@export var entry_stop_x: float = 280.0
@export var entry_stop_y: float = 444.0
@export var entry_duration_sec: float = 1.5
@export var entry_start_offset_x: float = -800.0
@export var enable_entry_sequence: bool = true
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
@export var head_block_grace_time: float = 0.08
@export var play_start_grace_sec: float = 1.5
@export var lock_x_during_full_movement: bool = true
@export var enable_entry_stop: bool = true

# ===== STATE MANAGEMENT =====
enum PlayerState {
    ENTRY,
    FULL_MOVEMENT,
    GAME_OVER
}

var current_state: PlayerState = PlayerState.FULL_MOVEMENT
var state_timer: float = 0.0
var state_data: Dictionary = {}

# ===== MOVEMENT STATE =====
var is_grounded: bool = false
var can_jump: bool = true
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var jump_requested: bool = false
var attack_active: bool = false
var attack_timer: float = 0.0
var attack_held: bool = false
var current_health: int = 0
var is_invincible: bool = false
var invincible_timer: float = 0.0
var _blink_timer: float = 0.0

# ===== POSITION MANAGEMENT =====
var _entry_start_position: Vector2 = Vector2.ZERO

# ===== REFERENCES =====
var game_manager: Node
var parallax_background: Node
var terrain_nodes: Array = []
var main_camera: Camera2D
var animated_sprite: AnimatedSprite2D
var ground_ray: RayCast2D
var attack_hitbox: Area2D

# ===== SIGNALS =====
signal game_over_signal(cause: String)
signal state_changed(new_state: PlayerState, old_state: PlayerState)

var _last_env_speed: float = -1.0

var _env_move_enabled: bool = false
var _jumping_this_frame: bool = false
var _jump_grace_timer: float = 0.0
var _head_clear_timer: float = 0.0
var _play_start_grace_timer: float = 0.0
var countdown_active: bool = false
var _anim_scales: Dictionary = {}
var _anim_offsets: Dictionary = {}
var _run_anim_factor: float = 1.0
var _boost_safe_fall_pending: bool = false

func request_jump() -> void:
    jump_buffer_timer = jump_buffer_time
    jump_requested = true

func request_attack() -> void:
    if is_on_floor() and not attack_active:
        attack_active = true
        attack_timer = attack_duration

func _left_bound_world() -> float:
    var lb: float = 0.0
    var viewport_rect = get_viewport().get_visible_rect()
    if main_camera:
        lb = main_camera.position.x - float(viewport_rect.size.x) * 0.5
    return lb + left_game_over_margin

func match_sprite_to_collision_size() -> void:
    var collision_shape = $CollisionShape2D
    if not collision_shape or not collision_shape.shape:
        return
    var shape_size = collision_shape.shape.size
    var sprite_frames = animated_sprite.sprite_frames
    if not sprite_frames:
        return
    var run_tex := sprite_frames.get_frame_texture("run", 0) if sprite_frames.has_animation("run") and sprite_frames.get_frame_count("run") > 0 else null
    var jump_tex := sprite_frames.get_frame_texture("jump", 0) if sprite_frames.has_animation("jump") and sprite_frames.get_frame_count("jump") > 0 else null
    if run_tex == null and jump_tex == null:
        return
    var run_size := Vector2(run_tex.get_width(), run_tex.get_height()) if run_tex != null else Vector2.ZERO
    var jump_size := Vector2(jump_tex.get_width(), jump_tex.get_height()) if jump_tex != null else Vector2.ZERO
    var original_sprite_size := run_size
    if jump_size.x > original_sprite_size.x or jump_size.y > original_sprite_size.y:
        original_sprite_size = jump_size
    var target_scale_x = (shape_size.x * 0.9) / max(original_sprite_size.x, 1.0)
    var target_scale_y = (shape_size.y * 0.9) / max(original_sprite_size.y, 1.0)
    var uniform_scale = min(target_scale_x, target_scale_y)
    var final_scale = Vector2(uniform_scale, uniform_scale)
    animated_sprite.scale = final_scale
    if enable_debug_logging and OS.is_debug_build():
        print("Sprite resized: orig_run=", run_size, " orig_jump=", jump_size, " collision=", shape_size, " scale=", final_scale)

func _ready() -> void:
    # Set process mode agar bisa dipause oleh SceneTree.paused
    process_mode = Node.PROCESS_MODE_PAUSABLE

    if OS.is_debug_build():
        if not InputMap.has_action("jump"):
            InputMap.add_action("jump")
            var ev := InputEventKey.new()
            ev.physical_keycode = KEY_SPACE
            InputMap.action_add_event("jump", ev)
        if not InputMap.has_action("attack"):
            InputMap.add_action("attack")
            var ev_att := InputEventKey.new()
            ev_att.physical_keycode = KEY_K
            InputMap.action_add_event("attack", ev_att)
    if not InputMap.has_action("toggle_lock_x"):
        InputMap.add_action("toggle_lock_x")
        var ev2 := InputEventKey.new()
        ev2.physical_keycode = KEY_F4
        InputMap.action_add_event("toggle_lock_x", ev2)
    if not InputMap.has_action("toggle_fall_death"):
        InputMap.add_action("toggle_fall_death")
        var ev3 := InputEventKey.new()
        ev3.physical_keycode = KEY_F5
        InputMap.action_add_event("toggle_fall_death", ev3)
    initialize_player()
    setup_collision_layers()
    find_and_cache_references()
    if entry_stop_x <= 0.0:
        entry_stop_x = 280.0
    if enable_entry_stop and not enable_entry_sequence:
        _set_to_entry_stop()
    start_initial_state_sequence()

func initialize_player() -> void:
    visible = true
    set_process(true)
    set_physics_process(true)
    set_process_input(true)

    # Initialize collision shape size and position
    var collision_shape = get_node_or_null("CollisionShape2D")
    if collision_shape and collision_shape.shape is RectangleShape2D:
        var rect_shape = collision_shape.shape as RectangleShape2D
        if not preserve_editor_transform:
            rect_shape.size = collision_size
            collision_shape.position = Vector2(0, 0)
        else:
            collision_size = rect_shape.size
        if enable_debug_logging and OS.is_debug_build():
            print("Player collision initialized: size=", rect_shape.size, " position=", collision_shape.position)

    # Initialize sprite - AnimatedSprite2D sudah di-set manual di editor
    animated_sprite = get_node_or_null("AnimatedSprite2D")
    if animated_sprite:
        animated_sprite.play("run")
        animated_sprite.speed_scale = 1.0
        if not animated_sprite.is_playing():
            animated_sprite.play("run")
        slice_jump_spritesheet_if_needed()
        slice_run_spritesheet_if_needed()
        if enable_debug_logging and OS.is_debug_build():
            print("AnimatedSprite2D initialized: position=", animated_sprite.position, " scale=", animated_sprite.scale, " playing=", animated_sprite.is_playing())
        _prepare_animation_scales()
        _apply_scale_for_anim("run")
        animated_sprite.centered = true
        _prepare_animation_offsets()
        _apply_offset_for_anim("run")
    if enable_entry_stop:
        _set_to_entry_stop()


    ground_ray = get_node_or_null("GroundRay")
    if ground_ray:
        ground_ray.collision_mask = 1
        ground_ray.enabled = true
    attack_hitbox = get_node_or_null("AttackHitbox") as Area2D
    if attack_hitbox:
        attack_hitbox.monitoring = false
        attack_hitbox.monitorable = false
        if not attack_hitbox.is_connected("area_entered", Callable(self, "_on_attack_hitbox_area_entered")):
            attack_hitbox.area_entered.connect(Callable(self, "_on_attack_hitbox_area_entered"))
    if animated_sprite:
        log_animation_scales()

    current_health = starting_health

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



func start_initial_state_sequence() -> void:
    if enable_entry_sequence:
        start_entry_sequence()
    else:
        set_state(PlayerState.FULL_MOVEMENT)


func start_entry_sequence() -> void:
    set_state(PlayerState.ENTRY)



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
        PlayerState.ENTRY:
            handle_entry_state(delta)
        PlayerState.FULL_MOVEMENT:
            handle_full_movement_state(delta)
        PlayerState.GAME_OVER:
             handle_game_over_state(delta)
    if attack_active:
        attack_timer = max(attack_timer - delta, 0.0)
        if attack_timer <= 0.0:
            if attack_held and current_state == PlayerState.FULL_MOVEMENT and is_on_floor():
                attack_timer = attack_duration
            else:
                attack_active = false

    _update_attack_hitbox()
    apply_physics(delta)
    check_game_over_conditions()
    sync_environment_speed_if_needed()
    _update_invincibility(delta)



func handle_full_movement_state(_delta: float) -> void:
    state_timer += _delta
    # Player tetap di posisi X=200, terrain yang bergerak
    velocity.x = 0  # Player tidak bergerak horizontal
    # Stabilkan posisi Y tepat setelah transisi agar tidak terjadi penyesuaian mendadak
    if state_timer < 0.2:
        position.y = entry_stop_y
        velocity.y = 0

    # Handle horizontal movement - freeze saat loncat jika diaktifkan
    if freeze_x_on_jump and not is_on_floor():
        velocity.x = velocity.x * (1.0 - jump_horizontal_damping)

    # Control animation based on state
    update_animation_state()
    # SKIP maintain_screen_position - player harus tetap di X=200


func handle_entry_state(_delta: float) -> void:
    state_timer += _delta
    if _entry_start_position == Vector2.ZERO:
        var start_x: float = entry_stop_x + entry_start_offset_x
        _entry_start_position = Vector2(start_x, entry_stop_y)
        global_position = _entry_start_position
        position = _entry_start_position
        velocity = Vector2.ZERO
    var t: float = 1.0
    if entry_duration_sec > 0.0:
        t = clamp(state_timer / entry_duration_sec, 0.0, 1.0)
    var new_x: float = lerpf(_entry_start_position.x, entry_stop_x, t)
    global_position.x = new_x
    position.x = new_x
    velocity = Vector2.ZERO
    update_animation_state()
    if t >= 1.0:
        _entry_start_position = Vector2.ZERO
        set_state(PlayerState.FULL_MOVEMENT)
        if game_manager and game_manager.has_method("on_player_entry_finished"):
            game_manager.on_player_entry_finished()


func handle_game_over_state(_delta: float) -> void:
    velocity = Vector2.ZERO
    if animated_sprite and animated_sprite.is_playing():
        animated_sprite.stop()

func apply_physics(delta: float) -> void:
    if current_state == PlayerState.GAME_OVER:
        velocity = Vector2.ZERO
        return
    var speed_fly: bool = false
    if game_manager == null or not is_instance_valid(game_manager):
        var main_node = get_tree().get_root().get_node_or_null("Main")
        if main_node != null:
            game_manager = main_node
    if game_manager != null and game_manager.has_method("is_speed_boost_active"):
        speed_fly = game_manager.is_speed_boost_active()
    if speed_fly:
        _boost_safe_fall_pending = true
        var target_y: float = min(entry_stop_y - speed_boost_fly_height, speed_boost_ceiling_y)
        var t_adj: float = clampf(position_adjustment_speed * delta, 0.0, 1.0)
        position.y = lerpf(position.y, target_y, t_adj)
        global_position.y = position.y
        velocity.y = 0.0
    else:
        var apply_gravity: bool = true
        if _boost_safe_fall_pending:
            var gap_below := _has_gap_below_long(gap_fall_threshold * 2.0)
            if gap_below:
                apply_gravity = false
                velocity.y = 0.0
            else:
                _boost_safe_fall_pending = false
        if apply_gravity:
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
    if position.y < speed_boost_ceiling_y:
        position.y = speed_boost_ceiling_y
        velocity.y = max(velocity.y, 0)

    # Move with collision - use proper floor detection
    var was_on_floor = is_on_floor()
    # Use move_and_slide with floor detection parameters
    # Set up_floor_snap_length to prevent tiny movements
    set_up_direction(Vector2.UP)
    var ray_ok := ground_ray != null and ground_ray.is_enabled() and ground_ray.is_colliding()
    _jump_grace_timer = max(_jump_grace_timer - delta, 0.0)
    _head_clear_timer = max(_head_clear_timer - delta, 0.0)
    var blocked_front := is_on_floor() and _blocked_ahead(front_check_distance) and _jump_grace_timer <= 0.0
    var head_blocked := (not is_on_floor()) and velocity.y < 0.0 and _blocked_above(collision_size.y * 0.6)
    var should_snap := is_on_floor() and ray_ok and not _has_gap_below(gap_fall_threshold) and not blocked_front and not head_blocked and _head_clear_timer <= 0.0
    var snap_len := 6.0 if should_snap else 0.0
    set_floor_snap_length(snap_len)
    if was_on_floor:
        coyote_timer = coyote_time
    else:
        coyote_timer = max(coyote_timer - delta, 0.0)
    if jump_buffer_timer > 0.0:
        jump_buffer_timer = max(jump_buffer_timer - delta, 0.0)
    if jump_enabled and jump_requested and jump_buffer_timer > 0.0:
        var can_perform := is_on_floor() or coyote_timer > 0.0
        if can_perform:
            velocity.y = jump_velocity
            coyote_timer = 0.0
            _jumping_this_frame = true
            _jump_grace_timer = jump_block_grace_time
            TransitionManager.play_sfx(&"jump")
            if game_manager and game_manager.has_method("on_player_jump"):
                game_manager.on_player_jump()
            jump_requested = false
            jump_buffer_timer = 0.0
    if head_blocked:
        velocity.y = max(velocity.y, 0.0)
        _head_clear_timer = head_block_grace_time
    move_and_slide()
    if current_state == PlayerState.FULL_MOVEMENT:
        var lbound2 := _left_bound_world()
        if lock_x_during_full_movement:
            global_position.x = clamp(global_position.x, lbound2, entry_stop_x)
        else:
            global_position.x = max(global_position.x, lbound2)
        position.x = global_position.x
        if enable_entry_stop and auto_recenter_x:
            var recenter_ready := is_on_floor() and not _blocked_ahead(front_check_distance)
            if recenter_ready and abs(global_position.x - entry_stop_x) > 1.0:
                if recenter_use_linear:
                    var dx: float = entry_stop_x - global_position.x
                    var step: float = recenter_speed_x * delta
                    if step >= absf(dx):
                        global_position.x = entry_stop_x
                    else:
                        global_position.x += signf(dx) * step
                    position.x = global_position.x
                else:
                    var t: float = clampf(position_adjustment_speed * delta, 0.0, 1.0)
                    global_position.x = lerpf(global_position.x, entry_stop_x, t)
                    position.x = global_position.x
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

func _has_gap_below_long(ray_len: float) -> bool:
    var space := get_world_2d().direct_space_state
    var half_w := collision_size.x * 0.5
    var foot_y := global_position.y + collision_size.y * 0.5 - 1.0
    var ray_len_clamped: float = max(ray_len, collision_size.y * 1.2)
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

func _blocked_above(ray_len: float) -> bool:
    var space := get_world_2d().direct_space_state
    var half_w := collision_size.x * 0.5
    var head_y := global_position.y - collision_size.y * 0.5 + 1.0
    var ray_len_clamped: float = max(1.0, ray_len)
    var start_left := Vector2(global_position.x - half_w + 2.0, head_y)
    var start_mid := Vector2(global_position.x, head_y)
    var start_right := Vector2(global_position.x + half_w - 2.0, head_y)
    var end_left := start_left + Vector2(0, -ray_len_clamped)
    var end_mid := start_mid + Vector2(0, -ray_len_clamped)
    var end_right := start_right + Vector2(0, -ray_len_clamped)
    var pleft := PhysicsRayQueryParameters2D.create(start_left, end_left, 1, [self])
    var pmid := PhysicsRayQueryParameters2D.create(start_mid, end_mid, 1, [self])
    var pright := PhysicsRayQueryParameters2D.create(start_right, end_right, 1, [self])
    var r1 := space.intersect_ray(pleft)
    var r2 := space.intersect_ray(pmid)
    var r3 := space.intersect_ray(pright)
    return not (r1.is_empty() and r2.is_empty() and r3.is_empty())

func check_game_over_conditions() -> void:
    var viewport_rect = get_viewport().get_visible_rect()
    if current_state == PlayerState.FULL_MOVEMENT and _is_environment_moving() and enable_fall_death:
        var off_screen_threshold: float = float(viewport_rect.size.y) + 200.0
        var threshold: float = fall_death_y
        if threshold > 0.0:
            if position.y >= threshold or position.y > off_screen_threshold:
                velocity.y = 0.0
                trigger_game_over("fell_off_screen")
        else:
            if position.y > off_screen_threshold:
                trigger_game_over("fell_off_screen")

func _update_invincibility(delta: float) -> void:
    if not is_invincible:
        if animated_sprite:
            animated_sprite.visible = true
        return
    invincible_timer = max(invincible_timer - delta, 0.0)
    _blink_timer += delta
    if _blink_timer >= hit_blink_interval_sec:
        _blink_timer = 0.0
        if animated_sprite:
            animated_sprite.visible = not animated_sprite.visible
    if invincible_timer <= 0.0:
        is_invincible = false
        if animated_sprite:
            animated_sprite.visible = true

func update_health_bar() -> void:
    if game_manager and game_manager.has_method("set_player_health"):
        game_manager.set_player_health(current_health, max_health)


func update_animation_state() -> void:
    if not animated_sprite:
        return

    if attack_active and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("attack"):
        if animated_sprite.animation != "attack":
            animated_sprite.play("attack")
            _apply_scale_for_anim("attack")
            _apply_offset_for_anim("attack")
        animated_sprite.speed_scale = ((0.6 if countdown_active else 1.0) * _run_anim_factor)
        return

    if is_on_floor():
        if animated_sprite.animation != "run" and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("run"):
            animated_sprite.play("run")
        _apply_scale_for_anim("run")
        _apply_offset_for_anim("run")
        animated_sprite.speed_scale = ((0.6 if countdown_active else 1.0) * _run_anim_factor)
    else:
        if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("jump"):
            if animated_sprite.animation != "jump" or velocity.y < 0.0:
                animated_sprite.play("jump")
                _apply_scale_for_anim("jump")
                _apply_offset_for_anim("jump")
            animated_sprite.speed_scale = ((0.6 if countdown_active else 0.9) * _run_anim_factor)
        else:
            if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("run") and animated_sprite.animation != "run":
                animated_sprite.play("run")
                _apply_scale_for_anim("run")
                _apply_offset_for_anim("run")
            animated_sprite.speed_scale = ((0.6 if countdown_active else 0.8) * _run_anim_factor)



func set_state(new_state: PlayerState) -> void:
    var old_state = current_state
    current_state = new_state
    state_timer = 0.0

    if enable_debug_logging and OS.is_debug_build():
        print("State transition: ", old_state, " -> ", new_state, " position: ", position, " is_on_floor: ", is_on_floor())

    match new_state:
        PlayerState.ENTRY:
            visible = true
            _entry_start_position = Vector2.ZERO
            velocity = Vector2.ZERO
        PlayerState.FULL_MOVEMENT:
            visible = true
            if is_on_floor():
                velocity.y = 0
                if enable_entry_stop:
                    position.y = entry_stop_y
            if entry_stop_x <= 0.0:
                entry_stop_x = 280.0
            if lock_x_during_full_movement and enable_entry_stop:
                global_position = Vector2(entry_stop_x, global_position.y)
                position = Vector2(entry_stop_x, position.y)
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

    var boost_active: bool = false
    if game_manager == null or not is_instance_valid(game_manager):
        var main_node = get_tree().get_root().get_node_or_null("Main")
        if main_node != null:
            game_manager = main_node
    if game_manager != null and game_manager.has_method("is_speed_boost_active"):
        boost_active = game_manager.is_speed_boost_active()

    if boost_active:
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
        var me := false
        if n and n.has_method("get"):
            me = n.get("movement_enabled")
        if me:
            return true
    if parallax_background and parallax_background.has_method("get"):
        var pm: bool = parallax_background.get("movement_enabled")
        if pm:
            return true
    return _env_move_enabled

func prepare_for_playing_phase() -> void:
    _play_start_grace_timer = play_start_grace_sec
    if lock_environment_speed_to_player:
        set_environment_speed(run_speed)

func _input(event: InputEvent) -> void:
    if current_state == PlayerState.GAME_OVER:
        return
    if not event or not is_instance_valid(self):
        return

    # Handle screen touch for jump and attack (if not on buttons)
    if event is InputEventScreenTouch and event.pressed:
        var viewport_rect = get_viewport().get_visible_rect()
        # If touch is on the left half of the screen, jump
        if event.position.x < viewport_rect.size.x * 0.5:
            request_jump()
        # If touch is on the right half of the screen, attack (if not on a button)
        # Note: TouchScreenButton should handle its own events and stop propagation if set up correctly
        else:
            request_attack()
        return

    if event.is_action_pressed("jump"):
        request_jump()
        return
    if event.is_action_pressed("attack"):
        attack_held = true
        request_attack()
        return
    if event.is_action_released("attack"):
        attack_held = false
        return

func apply_damage(amount: int) -> void:
    if current_state == PlayerState.GAME_OVER:
        return
    if is_invincible:
        return
    if game_manager and game_manager.has_method("try_consume_shield_hit") and game_manager.try_consume_shield_hit():
        return
    var next_health := current_health - amount
    if next_health > 0:
        TransitionManager.play_sfx(&"player_hit")
    current_health = max(next_health, 0)

    update_health_bar()

    if current_health <= 0:
        trigger_game_over("health_depleted")

func heal(amount: int) -> void:
    if current_state == PlayerState.GAME_OVER:
        return
    if amount <= 0:
        return
    current_health += amount
    if current_health > max_health:
        current_health = max_health
    update_health_bar()

func apply_hit_reaction(from_position: Vector2) -> void:
    if current_state == PlayerState.GAME_OVER:
        return
    var dir: float = sign(global_position.x - from_position.x)
    if dir == 0.0:
        dir = 1.0
    velocity.x = damage_knockback_horizontal * dir
    velocity.y = damage_knockback_vertical
    is_invincible = true
    invincible_timer = hit_invincibility_sec
    _blink_timer = 0.0
func on_anomaly_contact() -> void:
    if current_state != PlayerState.FULL_MOVEMENT:
        return
    if anomaly_instant_game_over:
        trigger_game_over("caught_by_anomaly")
    else:
        apply_damage(anomaly_damage)
        if current_state != PlayerState.GAME_OVER:
            _set_to_entry_stop()
            velocity = Vector2.ZERO
func _update_attack_hitbox() -> void:
    if not attack_hitbox:
        return
    var active := attack_active and current_state == PlayerState.FULL_MOVEMENT
    attack_hitbox.monitoring = active
    attack_hitbox.monitorable = active

func _on_attack_hitbox_area_entered(area: Area2D) -> void:
    if not attack_active:
        return
    if area == null:
        return
    var enemy_node: Node = null
    var parent := area.get_parent()
    if parent and parent is Node2D:
        var n2d := parent as Node2D
        var nm: String = n2d.name
        if nm.begins_with("EnemyBlock") or nm.begins_with("EnemyCone"):
            enemy_node = n2d
    if enemy_node and enemy_node.has_method("on_player_attack_hit"):
        enemy_node.call("on_player_attack_hit", self)

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
    _entry_start_position = Vector2.ZERO
    current_health = starting_health
    update_health_bar()
    is_invincible = false
    invincible_timer = 0.0
    _blink_timer = 0.0
    if animated_sprite:
        animated_sprite.visible = true
    if enable_entry_sequence:
        set_state(PlayerState.ENTRY)
    else:
        _set_to_entry_stop()
        set_state(PlayerState.FULL_MOVEMENT)


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
                if child is Node2D and (child.name.begins_with("Terrain") or child.name.begins_with("Ground")):
                    nodes.append(child)
    return nodes

func _set_to_entry_stop() -> void:
    if entry_stop_x <= 0.0:
        entry_stop_x = 280.0
    global_position = Vector2(entry_stop_x, entry_stop_y)
    position = Vector2(entry_stop_x, entry_stop_y)

func _validate_initial_position() -> void:
    if position.x == 0.0 or global_position.x == 0.0:
        _set_to_entry_stop()

func _blocked_ahead(dist: float) -> bool:
    var half_w := collision_size.x * 0.5
    var foot_y := global_position.y + collision_size.y * 0.5 - 2.0
    var mid_y := global_position.y
    var d: float = max(dist - front_block_margin, 0.5)
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

# pushback dihapus: tidak ada dorongan memaksa ke kiri

func _get_anim_frame_size(anim: String) -> Vector2:
    if not animated_sprite or not animated_sprite.sprite_frames:
        return Vector2.ZERO
    if not animated_sprite.sprite_frames.has_animation(anim):
        return Vector2.ZERO
    var tex := animated_sprite.sprite_frames.get_frame_texture(anim, 0)
    if tex == null:
        return Vector2.ZERO
    return Vector2(tex.get_width(), tex.get_height())

func _get_scaled_size_for_anim(anim: String) -> Vector2:
    var s := _get_anim_frame_size(anim)
    return Vector2(s.x * animated_sprite.scale.x, s.y * animated_sprite.scale.y)

func log_animation_scales() -> void:
    var run_orig := _get_anim_frame_size("run")
    var jump_orig := _get_anim_frame_size("jump")
    var run_scaled := _get_scaled_size_for_anim("run")
    var jump_scaled := _get_scaled_size_for_anim("jump")
    print("Player scale=", animated_sprite.scale, " run orig=", run_orig, " run scaled=", run_scaled, " jump orig=", jump_orig, " jump scaled=", jump_scaled)

func _compute_scale_for_anim(anim: String) -> Vector2:
    var s: Vector2 = _get_anim_frame_size(anim)
    var collision_shape = $CollisionShape2D
    if s == Vector2.ZERO or not collision_shape or not collision_shape.shape:
        return animated_sprite.scale
    var shape_size: Vector2 = collision_shape.shape.size
    var target_w: float = shape_size.x * 0.9
    var target_h: float = shape_size.y * 0.9
    var uniform: float = min(target_w / max(s.x, 1.0), target_h / max(s.y, 1.0))
    return Vector2(uniform, uniform)

func _prepare_animation_scales() -> void:
    _anim_scales.clear()
    _anim_scales["run"] = Vector2(run_scale_override, run_scale_override) if run_scale_override > 0.0 else _compute_scale_for_anim("run")
    _anim_scales["jump"] = Vector2(jump_scale_override, jump_scale_override) if jump_scale_override > 0.0 else _compute_scale_for_anim("jump")
    _anim_scales["attack"] = _compute_scale_for_anim("attack")

func _apply_scale_for_anim(anim: String) -> void:
    if preserve_editor_sprite_scale:
        return
    var s: Vector2
    if anim == "run" and run_scale_override > 0.0:
        s = Vector2(run_scale_override, run_scale_override)
    elif anim == "jump" and jump_scale_override > 0.0:
        s = Vector2(jump_scale_override, jump_scale_override)
    elif _anim_scales.has(anim):
        s = _anim_scales[anim] as Vector2
    else:
        s = _compute_scale_for_anim(anim)
        _anim_scales[anim] = s
    animated_sprite.scale = s

func _compute_offset_for_anim(anim: String) -> Vector2:
    if not animated_sprite:
        return Vector2.ZERO
    var collision_shape = $CollisionShape2D
    if not collision_shape or not collision_shape.shape:
        return Vector2.ZERO
    var shape_size: Vector2 = collision_shape.shape.size
    var scaled := _get_scaled_size_for_anim(anim)
    var dx: float = 0.0
    var dy: float = (shape_size.y - scaled.y) * 0.5
    return Vector2(dx, dy)

func _prepare_animation_offsets() -> void:
    _anim_offsets.clear()
    _anim_offsets["run"] = _compute_offset_for_anim("run")
    _anim_offsets["jump"] = _compute_offset_for_anim("jump")
    _anim_offsets["attack"] = _compute_offset_for_anim("attack")

func _apply_offset_for_anim(anim: String) -> void:
    if _anim_offsets.has(anim):
        animated_sprite.offset = _anim_offsets[anim] as Vector2

func set_run_anim_factor(factor: float) -> void:
    _run_anim_factor = clamp(factor, 0.5, 3.0)

func slice_jump_spritesheet_if_needed() -> void:
    if not animated_sprite or not animated_sprite.sprite_frames:
        return
    var sf := animated_sprite.sprite_frames
    if not sf.has_animation("jump"):
        return
    var count := sf.get_frame_count("jump")
    if count > 1:
        return
    var sheet := sf.get_frame_texture("jump", 0)
    if sheet == null:
        return
    var w := sheet.get_width()
    var h := sheet.get_height()
    if int(w) == 956 and int(h) == 1668:
        var cols := 4
        var rows := 4
        var cw: int = int(round(float(w) / float(cols)))
        var ch: int = int(round(float(h) / float(rows)))
        sf.clear("jump")
        for r in range(rows):
            for c in range(cols):
                var at := AtlasTexture.new()
                at.atlas = sheet
                at.region = Rect2(c * cw, r * ch, cw, ch)
                sf.add_frame("jump", at)

func slice_run_spritesheet_if_needed() -> void:
    if not animated_sprite or not animated_sprite.sprite_frames:
        return
    var sf := animated_sprite.sprite_frames
    if not sf.has_animation("run"):
        return
    var count := sf.get_frame_count("run")
    if count > 1:
        return
    var sheet := sf.get_frame_texture("run", 0)
    if sheet == null:
        return
    var w := sheet.get_width()
    var h := sheet.get_height()
    var cols := 4
    var rows := 4
    var cw: int = int(round(float(w) / float(cols)))
    var ch: int = int(round(float(h) / float(rows)))
    sf.clear("run")
    for r in range(rows):
        for c in range(cols):
            var at := AtlasTexture.new()
            at.atlas = sheet
            at.region = Rect2(c * cw, r * ch, cw, ch)
            sf.add_frame("run", at)
