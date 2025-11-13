extends ParallaxBackground

@export var speed: float = 600.0 # pixels per second

func _process(delta: float) -> void:
	# Move background base offset to the left for right-to-left motion
	scroll_base_offset.x -= speed * delta
