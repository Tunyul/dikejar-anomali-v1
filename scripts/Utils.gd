class_name Utils
extends RefCounted

## Core utility functions for Anomaly Rush
## Optimized for Godot 4.6

const AUDIO_BUS_MASTER := "Master"
const AUDIO_BUS_SFX := "SFX"
const AUDIO_BUS_MUSIC := "Music"

# ------------------------------------------------------------------------------
# Time & Frame Management
# ------------------------------------------------------------------------------

static func frame_freeze(duration: float, time_scale: float = 0.1) -> void:
	Engine.time_scale = time_scale
	await Engine.get_main_loop().create_timer(duration * time_scale).timeout
	Engine.time_scale = 1.0

static func delay(duration: float, node: Node) -> void:
	await node.get_tree().create_timer(duration).timeout

# ------------------------------------------------------------------------------
# Node Hierarchy & Groups
# ------------------------------------------------------------------------------

static func get_all_children(node: Node, type_filter: Variant = null) -> Array[Node]:
	var nodes: Array[Node] = []
	for child in node.get_children():
		if type_filter == null or is_instance_of(child, type_filter):
			nodes.append(child)
		if child.get_child_count() > 0:
			nodes.append_array(get_all_children(child, type_filter))
	return nodes

static func free_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()

# ------------------------------------------------------------------------------
# Math & Randomness
# ------------------------------------------------------------------------------

static func chance(percentage: float) -> bool:
	return randf() <= (percentage / 100.0)

static func random_vector2(min_val: float, max_val: float) -> Vector2:
	return Vector2(randf_range(min_val, max_val), randf_range(min_val, max_val))

static func choose(array: Array) -> Variant:
	if array.is_empty(): return null
	return array.pick_random()

# ------------------------------------------------------------------------------
# File System & Data
# ------------------------------------------------------------------------------

static func load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_error("Utils: File not found " + path)
		return null

	var file = FileAccess.open(path, FileAccess.READ)
	var content = file.get_as_text()
	var json = JSON.new()
	var error = json.parse(content)

	if error != OK:
		push_error("Utils: JSON Parse Error " + json.get_error_message())
		return null

	return json.data

static func save_json(path: String, data: Variant) -> void:
	var file = FileAccess.open(path, FileAccess.WRITE)
	var json_string = JSON.stringify(data, "\t")
	file.store_string(json_string)
	file.close()

# ------------------------------------------------------------------------------
# UI & Formatting
# ------------------------------------------------------------------------------

static func format_currency(amount: int) -> String:
	var string_val = str(amount)
	var result = ""
	var count = 0

	for i in range(string_val.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "." + result
		result = string_val[i] + result
		count += 1

	return "Rp " + result

static func center_pivot(control: Control) -> void:
	control.pivot_offset = control.size / 2.0
