extends ParallaxBackground

@export var speed: float = 300.0 # pixels per second
@export var snap_px: float = 0.0
@export var use_smooth_scrolling: bool = true
@export var wrap_width: float = 0.0

var movement_enabled: bool = false
var target_speed: float = 0.0

func _ready() -> void:
	# Movement enabled by default for proper scrolling
	movement_enabled = true
	target_speed = speed
	
	# Configure cloud layers for smooth movement
	for i in range(get_child_count()):
		var layer = get_child(i)
		if layer is ParallaxLayer and layer.name.begins_with("Clouds"):
			# Ensure cloud layers use smooth movement
			layer.motion_offset = Vector2.ZERO
			# Set cloud-specific mirroring for seamless looping
			if layer.motion_mirroring.x == 0:
				layer.motion_mirroring.x = 1024

func _physics_process(delta: float) -> void:
	if not movement_enabled:
		return
	
	# Use physics process for consistent frame rate
	var adjusted_speed := speed
	if get_child_count() > 0:
		var first_layer = get_child(0)
		if first_layer is ParallaxLayer:
			adjusted_speed = speed * first_layer.motion_scale.x
			
	var nx := scroll_base_offset.x - adjusted_speed * delta
	# Apply smooth scrolling or legacy snapping
	if use_smooth_scrolling:
		scroll_base_offset.x = nx  # Smooth movement
	else:
		if snap_px > 0.0:
			nx = floor(nx / snap_px) * snap_px
		scroll_base_offset.x = nx  # Legacy snapping behavior
	
	# Apply cloud-specific smoothing
	for i in range(get_child_count()):
		var layer = get_child(i)
		if layer is ParallaxLayer and layer.name.begins_with("Clouds"):
			# Use direct assignment for cloud layers to prevent stuttering
			layer.motion_offset.x = scroll_base_offset.x * layer.motion_scale.x
			layer.motion_offset.y = 0  # Ensure no vertical drift
			# Handle cloud wrapping for seamless looping
			if layer.motion_mirroring.x > 0:
				var wrapped_offset = fposmod(layer.motion_offset.x, layer.motion_mirroring.x)
				if wrapped_offset != layer.motion_offset.x:
					layer.motion_offset.x = wrapped_offset
	if wrap_width > 0.0 and abs(scroll_base_offset.x) >= wrap_width:
		scroll_base_offset.x = -fposmod(-scroll_base_offset.x, wrap_width)

func set_movement_enabled(enabled: bool) -> void:
	movement_enabled = enabled

func set_speed(new_speed: float) -> void:
	speed = new_speed
	target_speed = new_speed

func get_layer_speed(layer_index: int = 0) -> float:
	if get_child_count() > layer_index:
		var parallax_layer = get_child(layer_index)
		if parallax_layer is ParallaxLayer:
			return speed * parallax_layer.motion_scale.x
	return speed
