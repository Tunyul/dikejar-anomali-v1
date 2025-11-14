extends ParallaxBackground

@export var speed: float = 600.0 # pixels per second
@export var snap_px: float = 1.0
@export var wrap_width: float = 0.0

func _process(delta: float) -> void:
	var nx := scroll_base_offset.x - speed * delta
	if snap_px > 0.0:
		nx = floor(nx / snap_px) * snap_px
	scroll_base_offset.x = nx
	if wrap_width > 0.0 and abs(scroll_base_offset.x) >= wrap_width:
		scroll_base_offset.x = -fposmod(-scroll_base_offset.x, wrap_width)
