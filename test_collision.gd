extends Node

@onready var player = $"Main/Player"
@onready var terrain = $"Main/Terrain"

func _ready():
	print("=== COLLISION TEST ===")
	print("Player type: ", player.get_class())
	print("Player collision layer: ", player.collision_layer)
	print("Player collision mask: ", player.collision_mask)
	
	var ground = terrain.get_node("Ground")
	print("Ground collision layer: ", ground.collision_layer)
	print("Ground collision mask: ", ground.collision_mask)
	
	# Test raycast
	if player.has_method("_raycast"):
		print("Raycast exists: ", player._raycast != null)
		if player._raycast:
			print("Raycast collision mask: ", player._raycast.collision_mask)
	
	print("=== TEST COMPLETE ===")