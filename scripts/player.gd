extends CharacterBody2D

@export var ground_path: NodePath
@export var y_offset_px: float = 64.0
@export var gravity_px: float = 2000.0
@export var jump_impulse_px: float = 600.0
@export var keep_x_px: float = 250.0
@export var enabled: bool = true
@export var follow_ground: bool = true
@export var smooth_y: bool = true
@export var smooth_speed_px: float = 600.0
@export var manual_control: bool = false
@export var manual_position: Vector2 = Vector2(250, 450)
@export var lock_position: bool = true

var _ground: TerrainGenerator
var _tile_px: float = 0.0
var _grounded: bool = false
var _request_jump: bool = false
var _anim: AnimatedSprite2D
var _visual_h_px: float = 0.0
var _last_target_y: float = 0.0
var _start_snapped: bool = false
var _lock_x: bool = true
var _input_block: bool = false
var _intro_mode: bool = false
var _intro_tween: Tween
var _raycast: RayCast2D

func _ready() -> void:
	# Setup player collision - player on layer 2, collides with layer 1 (terrain)
	collision_layer = 2   # Player on layer 2
	collision_mask = 1   # Player collides with layer 1 (terrain)
	
	# Setup RayCast2D untuk collision detection
	_raycast = RayCast2D.new()
	_raycast.position = Vector2(0, 0)
	_raycast.target_position = Vector2(0, 100)  # Ray ke bawah
	_raycast.collision_mask = 1  # Collision layer 1 (terrain)
	_raycast.enabled = true
	add_child(_raycast)
	
	if ground_path:
		_ground = get_node_or_null(ground_path)
	else:
		# Cari Ground di sibling nodes dulu, kalau nggak ada cek parent
		_ground = get_parent().get_node_or_null("Ground")
		if not _ground:
			_ground = get_parent().get_node_or_null("Terrain/Ground")
	if _ground:
		_tile_px = float(_ground.tile_size) * _ground.tile_scale
		if _tile_px <= 0.0 and _ground.tile_set:
			_tile_px = float(_ground.tile_set.tile_size.x) * _ground.tile_scale
	_anim = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if _anim and _anim.sprite_frames:
		var anim_name: StringName = _anim.animation
		var tex: Texture2D = _anim.sprite_frames.get_frame_texture(anim_name, 0)
		if tex:
			_visual_h_px = float(tex.get_size().y) * _anim.scale.y
			y_offset_px = _visual_h_px * 0.5
		_anim.play(anim_name)

func set_manual_position(x: float, y: float) -> void:
	manual_position.x = x
	manual_position.y = y
	if manual_control and lock_position:
		position = manual_position
	elif manual_control:
		position.x = x

func set_manual_x(x: float) -> void:
	manual_position.x = x
	if manual_control:
		position.x = x

func set_manual_y(y: float) -> void:
	manual_position.y = y
	if manual_control and lock_position:
		position.y = y

func _physics_process(delta: float) -> void:
	if not enabled:
		return
	
	# Dapatkan kecepatan terrain untuk prediksi collision
	var terrain_speed := 0.0
	if _ground and _ground.get_parent():
		var terrain_scroll = _ground.get_parent()
		if terrain_scroll.has_method("get"):
			terrain_speed = terrain_scroll.get("speed")
	
	# Manual control mode
	if manual_control:
		if lock_position:
			position = manual_position
		else:
			position.x = manual_position.x
		velocity = Vector2.ZERO
		return
	
	if not _ground:
		return
		
	if _tile_px <= 0.0:
		_tile_px = float(_ground.tile_size) * _ground.tile_scale
		if _tile_px <= 0.0 and _ground.tile_set:
			_tile_px = float(_ground.tile_set.tile_size.x) * _ground.tile_scale
	
	# Hitung target Y dari terrain data
	var local_to_ground: Vector2 = _ground.to_local(global_position)
	var tile_x := int(floor(local_to_ground.x / _tile_px))
	tile_x = clamp(tile_x, 0, _ground.world_width_tiles - 1)
	if _ground.surface_y_by_x.size() == 0:
		return
		
	var tile_y := _ground.surface_y_by_x[tile_x]
	var gap_detected: bool = false
	
	# Cek apakah ini adalah gap (tile kosong)
	if tile_y < 0:
		gap_detected = true
		var found: bool = false
		for r in [0, 1, 2, 3]:
			var tx1: int = clamp(tile_x - r, 0, _ground.world_width_tiles - 1)
			var ty1: int = _ground.surface_y_by_x[tx1]
			if ty1 >= 0:
				tile_y = ty1
				found = true
				gap_detected = false
				break
			var tx2: int = clamp(tile_x + r, 0, _ground.world_width_tiles - 1)
			var ty2: int = _ground.surface_y_by_x[tx2]
			if ty2 >= 0:
				tile_y = ty2
				found = true
				gap_detected = false
				break
		if not found:
			if _last_target_y != 0.0:
				var target_hold := _last_target_y
				position.y = target_hold
				velocity.y = 0.0
				_grounded = true
				global_position.x = keep_x_px
				return
	
	var target_y := _ground.position.y + float(tile_y) * _tile_px - y_offset_px
	_last_target_y = target_y

	if not _start_snapped:
		position.y = target_y
		velocity.y = 0.0
		_grounded = true
		_start_snapped = true

	# Gunakan raycast untuk collision detection yang lebih akurat
	# Prediksi posisi berdasarkan kecepatan terrain
	var predicted_position = global_position
	if terrain_speed > 0:
		predicted_position.y += terrain_speed * delta * 0.5  # Prediksi terrain naik
	
	# Cek gap di depan untuk prediksi jatuh
	var tiles_ahead_check := 3
	var gap_ahead_detected := false
	for i in range(1, tiles_ahead_check + 1):
		var future_tile_x: int = clamp(tile_x + i, 0, _ground.world_width_tiles - 1)
		if _ground.surface_y_by_x[future_tile_x] < 0:
			gap_ahead_detected = true
			break
	
	# Setup raycast dengan posisi yang lebih akurat
	_raycast.global_position = global_position
	_raycast.target_position = Vector2(0, 120)  # Ray lebih panjang untuk terrain naik
	
	# Cek collision dengan raycast
	var collision_detected = false
	var collision_point = Vector2.ZERO
	var collision_normal = Vector2.ZERO
	
	if _raycast.is_colliding():
		collision_detected = true
		collision_point = _raycast.get_collision_point()
		collision_normal = _raycast.get_collision_normal()
	
	# Jika tidak ada collision dari atas, cek collision dari bawah (saat terrain naik)
	if not collision_detected:
		_raycast.target_position = Vector2(0, -50)  # Ray ke atas untuk cek terrain naik
		if _raycast.is_colliding():
			collision_detected = true
			collision_point = _raycast.get_collision_point()
			collision_normal = _raycast.get_collision_normal()
		# Kembalikan ray ke bawah untuk next frame
		_raycast.target_position = Vector2(0, 100)
	
	if collision_detected:
		# Ada collision, snap ke posisi collision
		if collision_normal.y < -0.5:  # Normal ke atas (ground)
			# Snap ke posisi ground dengan offset yang tepat
			var target_pos_y = collision_point.y - y_offset_px
			if position.y > target_pos_y or velocity.y > 0:  # Hanya snap jika di bawah ground atau sedang jatuh
				position.y = target_pos_y
				velocity.y = 0.0
				_grounded = true
		elif collision_normal.y > 0.5:  # Normal ke bawah (ceiling)
			velocity.y = 0.0  # Hentikan velocity ke atas
			_grounded = false
		
		# Handle jumping
		if _request_jump and collision_normal.y < -0.5:
			velocity.y = -jump_impulse_px
			_grounded = false
			_request_jump = false
		
		# Tambahan: Dorong player ke atas jika terrain naik dan player sedang di bawah
		elif collision_normal.y < -0.5 and position.y > collision_point.y - y_offset_px:
			velocity.y = max(velocity.y, 0)  # Hentikan velocity ke bawah
			position.y = collision_point.y - y_offset_px
	else:
		# Tidak ada collision, cek apakah ada gap atau terrain data
		if gap_detected or gap_ahead_detected:
			# Ada gap, jatuh dengan gravity
			velocity.y += gravity_px * delta
			_grounded = false
		elif follow_ground:
			# Ikuti terrain data
			if smooth_y:
				position.y = move_toward(position.y, target_y, smooth_speed_px * delta)
			else:
				position.y = target_y
		_grounded = true
	
	_request_jump = false

	if _lock_x:
		global_position.x = keep_x_px	
	
	# Keep animation running
	if _anim and _anim.sprite_frames:
		if not _anim.is_playing():
			_anim.play(_anim.animation)
	
	# Manual control mode
	if manual_control:
		if lock_position:
			position = manual_position
		else:
			position.x = manual_position.x
		velocity = Vector2.ZERO
		return
		
	# Batasi velocity ke bawah untuk mencegah tembus terrain
	if velocity.y > 1000:  # Maksimum kecepatan jatuh
		velocity.y = 1000
	
	# Apply movement dengan collision response yang lebih baik
	var _collision_info = move_and_slide()
	
	# Cek collision dari bawah setelah movement dengan ray yang lebih panjang
	if velocity.y > 0:  # Jika sedang jatuh
		_raycast.global_position = global_position
		_raycast.target_position = Vector2(0, 20)  # Ray pendek tapi cukup untuk ground check
		if _raycast.is_colliding():
			var _hit_point = _raycast.get_collision_point()
			var hit_normal = _raycast.get_collision_normal()
			if hit_normal.y < -0.5 and global_position.y > _hit_point.y - y_offset_px:
				position.y = _hit_point.y - y_offset_px
				velocity.y = 0.0
				_grounded = true
	
	# Tambahan: Cek collision dari samping untuk mencegah tembus
	if velocity.x != 0:
		_raycast.global_position = global_position
		_raycast.target_position = Vector2(10 * sign(velocity.x), 0)  # Ray ke samping
		if _raycast.is_colliding():
			var _hit_point = _raycast.get_collision_point()
			var hit_normal = _raycast.get_collision_normal()
			if abs(hit_normal.x) > 0.5:  # Normal horizontal
				velocity.x = 0  # Hentikan movement horizontal

func set_intro_mode(intro_enabled: bool) -> void:
	_intro_mode = intro_enabled
	if intro_enabled:
		manual_control = false
		_input_block = true
		_lock_x = false
	else:
		manual_control = true
		_input_block = false
		_lock_x = true

func set_intro_tween(tween: Tween) -> void:
	if _intro_tween:
		_intro_tween.kill()
	_intro_tween = tween

func kill_intro_tween() -> void:
	if _intro_tween:
		_intro_tween.kill()
		_intro_tween = null

func _input(event: InputEvent) -> void:
	if _input_block:
		return
	if event is InputEventMouseButton and event.pressed:
		_request_jump = true
	elif event is InputEventScreenTouch and event.pressed:
		_request_jump = true
	elif event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		_request_jump = true
