extends ParallaxBackground

@export var speed: float = 300.0 # pixels per second
@export var snap_px: float = 0.0
@export var use_smooth_scrolling: bool = true
@export var wrap_width: float = 0.0

var movement_enabled: bool = false
var target_speed: float = 0.0

func _ready() -> void:
	movement_enabled = true
	target_speed = speed

	# Configure cloud layers for smooth movement
	for i in range(get_child_count()):
		var parallax_layer = get_child(i)
		if parallax_layer is ParallaxLayer and parallax_layer.name.begins_with("Clouds"):
			# Ensure cloud layers use smooth movement
			parallax_layer.motion_offset = Vector2.ZERO
			# Set cloud-specific mirroring for seamless looping
			if parallax_layer.motion_mirroring.x == 0:
				parallax_layer.motion_mirroring.x = 1024

func _process(delta: float) -> void:
	if not movement_enabled:
		return

	# Use _process for smoother visual scrolling, especially on mobile
	# Update base offset - ParallaxLayers will handle their own movement
	# based on their motion_scale automatically.
	var move_amount = speed * delta

	if snap_px > 0.0:
		move_amount = round(move_amount / snap_px) * snap_px

	scroll_base_offset.x -= move_amount

	if wrap_width > 0.0:
		# Use fmod for wrapping if wrap_width is set
		scroll_base_offset.x = fmod(scroll_base_offset.x, wrap_width)

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
