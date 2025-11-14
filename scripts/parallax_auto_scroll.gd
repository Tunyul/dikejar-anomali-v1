extends ParallaxBackground

@export var speed: float = 300.0 # pixels per second
@export var snap_px: float = 1.0
@export var wrap_width: float = 0.0

var movement_enabled: bool = false
var target_speed: float = 0.0

func _ready() -> void:
	# Movement enabled by default for proper scrolling
	movement_enabled = true
	target_speed = speed

func _process(delta: float) -> void:
	if not movement_enabled:
		return
	
	# Calculate speed based on layer motion scales for proper parallax effect
	var adjusted_speed := speed
	if get_child_count() > 0:
		var first_layer = get_child(0)
		if first_layer is ParallaxLayer:
			adjusted_speed = speed * first_layer.motion_scale.x
			
	var nx := scroll_base_offset.x - adjusted_speed * delta
	if snap_px > 0.0:
		nx = floor(nx / snap_px) * snap_px
	scroll_base_offset.x = nx
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
