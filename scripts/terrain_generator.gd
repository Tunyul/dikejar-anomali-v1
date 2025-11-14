@tool
class_name TerrainGenerator
extends TileMapLayer

@export var tile_size: int = 128
@export var world_width_tiles: int = 64
@export var ground_y_tiles: int = 5
@export var fill_depth_tiles: int = 3
@export var grass_texture_path: String = "res://assets/Tiles/png/128x128/GrassMid.png"
@export var dirt_texture_path: String = "res://assets/Tiles/png/128x128/Dirt.png" 
@export var tile_scale: float = 0.5
@export var auto_generate: bool = true
@export var regenerate: bool = false: set = _set_regenerate
@export var target_baseline_px: int = 420
@export var gap_chance: float = 0.15
@export var min_gap_tiles: int = 2
@export var max_gap_tiles: int = 3
@export var edge_guard_tiles: int = 2
@export var rng_seed: int = 0
@export var flat_prefix_tiles: int = 32
@export var gap_spacing_tiles: int = 1
@export var use_caps: bool = true
@export var grass_left_texture_path: String = "res://assets/Tiles/png/128x128/GrassLeft.png"
@export var grass_right_texture_path: String = "res://assets/Tiles/png/128x128/GrassRight.png"
@export var enable_hills: bool = true
@export var hill_chance: float = 0.2
@export var hill_run_min_tiles: int = 2
@export var hill_run_max_tiles: int = 6
@export var hill_y_min: int = 2
@export var hill_y_max: int = 6
@export var hill_up_texture_path: String = "res://assets/Tiles/png/128x128/GrassHillLeft.png"
@export var hill_down_texture_path: String = "res://assets/Tiles/png/128x128/GrassHillRight.png"
@export var hill_up2_texture_path: String = "res://assets/Tiles/png/128x128/GrassHillLeft2.png"
@export var hill_down2_texture_path: String = "res://assets/Tiles/png/128x128/GrassHillRight2.png"

@export var test_colorize_hills: bool = false
@export var draw_border: bool = true
@export var border_color: Color = Color(1, 0, 0, 0.9)
@export var border_width_px: float = 2.0

@export var enable_spikes: bool = true
@export var spike_texture_path: String = "res://assets/Enemies/png/128x128/Spike_Up.png"
@export var spike_chance: float = 0.15
@export var spike_spacing_tiles: int = 3
@export var spike_z_index: int = 6

var _last_hill_up: bool = false
var surface_y_by_x: PackedInt32Array = PackedInt32Array()

# Tile ID variables for sharing between functions
var _grass_id: int = 0
var _dirt_id: int = 1
var _grass_left_id: int = -1
var _grass_right_id: int = -1
var _hill_up_id: int = -1
var _hill_down_id: int = -1
var _hill_up2_id: int = -1
var _hill_down2_id: int = -1

func _tinted_texture(src: Texture2D, col: Color) -> Texture2D:
	var img := src.get_image()
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	var w := img.get_width()
	var h := img.get_height()
	for yy in range(h):
		for xx in range(w):
			var p := img.get_pixel(xx, yy)
			img.set_pixel(xx, yy, Color(p.r * col.r, p.g * col.g, p.b * col.b, p.a))
	return ImageTexture.create_from_image(img)

func _ready() -> void:
	if auto_generate and not Engine.is_editor_hint():
		# Reset seed untuk setiap game baru
		reset_random_seed()
		# Gunakan call_deferred untuk menghindari lag di awal game
		call_deferred("generate")

func reset_random_seed() -> void:
	# Generate seed yang benar-benar random
	var time_seed = int(Time.get_ticks_msec())
	var process_seed = int(Time.get_ticks_usec() % 1000000)
	var random_combined = time_seed + process_seed + randi()
	rng_seed = random_combined % 2147483647  # Maksimum 32-bit integer

func generate_random() -> void:
	# Generate terrain dengan seed random baru
	reset_random_seed() 
	generate()

func _set_regenerate(value: bool) -> void:
	if value:
		generate()

func generate() -> void:
	clear()
	scale = Vector2(tile_scale, tile_scale)
	var viewport_h := int(get_viewport().get_visible_rect().size.y)
	var tile_px := int(tile_size * tile_scale)
	var baseline := (target_baseline_px if target_baseline_px > 0 else viewport_h - tile_px)
	position.y = baseline - ground_y_tiles * tile_px
	
	# Use deferred call to avoid lag during initialization
	call_deferred("_setup_tileset")

func _setup_tileset() -> void:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(tile_size, tile_size)
	
	# Setup physics layer untuk collision - PERTAMA SEKALI
	ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(0, 1)  # Layer 1 untuk terrain
	ts.set_physics_layer_collision_mask(0, 2)   # Layer 2 untuk player collision
	
	# Set TileSet to TileMapLayer first before setup tiles
	tile_set = ts
	if rng_seed == 0:
		# Gunakan waktu untuk membuat seed yang benar-benar random
		var time_seed = int(Time.get_ticks_msec())
		var process_seed = int(Time.get_ticks_usec() % 1000000)
		rng_seed = time_seed + process_seed

	# Setup semua TileSetAtlasSource DULU tanpa collision
	var grass_source := TileSetAtlasSource.new()
	grass_source.texture = load(grass_texture_path)
	grass_source.texture_region_size = Vector2i(tile_size, tile_size)
	grass_source.create_tile(Vector2i(0, 0))
	_grass_id = ts.add_source(grass_source)
	
	# Setup collision setelah TileSetAtlasSource ditambahkan ke TileSet
	var grass_tile_data = ts.get_source(_grass_id).get_tile_data(Vector2i(0, 0), 0)
	if grass_tile_data and ts.get_physics_layers_count() > 0:
		grass_tile_data.set_collision_polygons_count(0, 1)
		grass_tile_data.set_collision_polygon_points(0, 0, PackedVector2Array([Vector2(0, 0), Vector2(tile_size, 0), Vector2(tile_size, tile_size), Vector2(0, tile_size)]))

	var dirt_source := TileSetAtlasSource.new()
	dirt_source.texture = load(dirt_texture_path)
	dirt_source.texture_region_size = Vector2i(tile_size, tile_size)
	dirt_source.create_tile(Vector2i(0, 0))
	_dirt_id = ts.add_source(dirt_source)
	
	# Setup collision setelah TileSetAtlasSource ditambahkan ke TileSet
	var dirt_tile_data = ts.get_source(_dirt_id).get_tile_data(Vector2i(0, 0), 0)
	if dirt_tile_data and ts.get_physics_layers_count() > 0:
		dirt_tile_data.set_collision_polygons_count(0, 1)
		dirt_tile_data.set_collision_polygon_points(0, 0, PackedVector2Array([Vector2(0, 0), Vector2(tile_size, 0), Vector2(tile_size, tile_size), Vector2(0, tile_size)]))

	# Reset tile IDs
	_grass_left_id = -1
	_grass_right_id = -1
	_hill_up_id = -1
	_hill_down_id = -1
	_hill_up2_id = -1
	_hill_down2_id = -1
	if use_caps:
		var left_src := TileSetAtlasSource.new()
		left_src.texture = load(grass_left_texture_path)
		left_src.texture_region_size = Vector2i(tile_size, tile_size)
		left_src.create_tile(Vector2i(0, 0))
		_grass_left_id = ts.add_source(left_src)
		
		# Setup collision setelah TileSetAtlasSource ditambahkan ke TileSet
		var grass_left_tile_data = ts.get_source(_grass_left_id).get_tile_data(Vector2i(0, 0), 0)
		if grass_left_tile_data and ts.get_physics_layers_count() > 0:
			grass_left_tile_data.set_collision_polygons_count(0, 1)
			grass_left_tile_data.set_collision_polygon_points(0, 0, PackedVector2Array([Vector2(0, 0), Vector2(tile_size, 0), Vector2(tile_size, tile_size), Vector2(0, tile_size)]))
		
		var right_src := TileSetAtlasSource.new()
		right_src.texture = load(grass_right_texture_path)
		right_src.texture_region_size = Vector2i(tile_size, tile_size)
		right_src.create_tile(Vector2i(0, 0))
		_grass_right_id = ts.add_source(right_src)
		
		# Setup collision setelah TileSetAtlasSource ditambahkan ke TileSet
		var grass_right_tile_data = ts.get_source(_grass_right_id).get_tile_data(Vector2i(0, 0), 0)
		if grass_right_tile_data and ts.get_physics_layers_count() > 0:
			grass_right_tile_data.set_collision_polygons_count(0, 1)
			grass_right_tile_data.set_collision_polygon_points(0, 0, PackedVector2Array([Vector2(0, 0), Vector2(tile_size, 0), Vector2(tile_size, tile_size), Vector2(0, tile_size)]))
	if enable_hills:
		var up_src := TileSetAtlasSource.new()
		var _up_tex: Texture2D = load(hill_up_texture_path)
		up_src.texture = (_tinted_texture(_up_tex, Color(0, 1, 0)) if test_colorize_hills else _up_tex)
		up_src.texture_region_size = Vector2i(tile_size, tile_size)
		up_src.create_tile(Vector2i(0, 0))
		_hill_up_id = ts.add_source(up_src)
		
		# Setup collision setelah TileSetAtlasSource ditambahkan ke TileSet
		var hill_up_tile_data = ts.get_source(_hill_up_id).get_tile_data(Vector2i(0, 0), 0)
		if hill_up_tile_data and ts.get_physics_layers_count() > 0:
			hill_up_tile_data.set_collision_polygons_count(0, 1)
			hill_up_tile_data.set_collision_polygon_points(0, 0, PackedVector2Array([Vector2(0, 0), Vector2(tile_size, 0), Vector2(tile_size, tile_size), Vector2(0, tile_size)]))
		
		var down_src := TileSetAtlasSource.new()
		var _down_tex: Texture2D = load(hill_down_texture_path)
		down_src.texture = (_tinted_texture(_down_tex, Color(0, 0, 1)) if test_colorize_hills else _down_tex)
		down_src.texture_region_size = Vector2i(tile_size, tile_size)
		down_src.create_tile(Vector2i(0, 0))
		_hill_down_id = ts.add_source(down_src)
		
		# Setup collision setelah TileSetAtlasSource ditambahkan ke TileSet
		var hill_down_tile_data = ts.get_source(_hill_down_id).get_tile_data(Vector2i(0, 0), 0)
		if hill_down_tile_data and ts.get_physics_layers_count() > 0:
			hill_down_tile_data.set_collision_polygons_count(0, 1)
			hill_down_tile_data.set_collision_polygon_points(0, 0, PackedVector2Array([Vector2(0, 0), Vector2(tile_size, 0), Vector2(tile_size, tile_size), Vector2(0, tile_size)]))
		
		var up2_src := TileSetAtlasSource.new()
		var _up2_tex: Texture2D = load(hill_up2_texture_path)
		up2_src.texture = (_tinted_texture(_up2_tex, Color(1, 0, 0)) if test_colorize_hills else _up2_tex)
		up2_src.texture_region_size = Vector2i(tile_size, tile_size)
		up2_src.create_tile(Vector2i(0, 0))
		_hill_up2_id = ts.add_source(up2_src)
		
		# Setup collision setelah TileSetAtlasSource ditambahkan ke TileSet
		var hill_up2_tile_data = ts.get_source(_hill_up2_id).get_tile_data(Vector2i(0, 0), 0)
		if hill_up2_tile_data and ts.get_physics_layers_count() > 0:
			hill_up2_tile_data.set_collision_polygons_count(0, 1)
			hill_up2_tile_data.set_collision_polygon_points(0, 0, PackedVector2Array([Vector2(0, 0), Vector2(tile_size, 0), Vector2(tile_size, tile_size), Vector2(0, tile_size)]))
		
		var down2_src := TileSetAtlasSource.new()
		var _down2_tex: Texture2D = load(hill_down2_texture_path)
		down2_src.texture = (_tinted_texture(_down2_tex, Color(1, 1, 0)) if test_colorize_hills else _down2_tex)
		down2_src.texture_region_size = Vector2i(tile_size, tile_size)
		down2_src.create_tile(Vector2i(0, 0))
		_hill_down2_id = ts.add_source(down2_src)
		
		# Setup collision setelah TileSetAtlasSource ditambahkan ke TileSet
		var hill_down2_tile_data = ts.get_source(_hill_down2_id).get_tile_data(Vector2i(0, 0), 0)
		if hill_down2_tile_data and ts.get_physics_layers_count() > 0:
			hill_down2_tile_data.set_collision_polygons_count(0, 1)
			hill_down2_tile_data.set_collision_polygon_points(0, 0, PackedVector2Array([Vector2(0, 0), Vector2(tile_size, 0), Vector2(tile_size, tile_size), Vector2(0, tile_size)]))

	surface_y_by_x.resize(world_width_tiles)
	for i in range(world_width_tiles):
		surface_y_by_x[i] = -1

	# Use chunked generation to avoid lag
	call_deferred("_generate_chunked")

func _generate_chunked() -> void:
	var rng := RandomNumberGenerator.new()
	if rng_seed == 0:
		# Jika rng_seed 0, generate seed random berdasarkan waktu
		rng.randomize()
	else:
		# Jika rng_seed diset, gunakan seed yang sudah ditentukan
		rng.seed = rng_seed

	var x: int = 0
	var right_guard: int = world_width_tiles - edge_guard_tiles
	var safe_until: int = flat_prefix_tiles
	if safe_until > world_width_tiles:
		safe_until = world_width_tiles
	var gap_spacing_left: int = 0
	var force_left_cap: bool = false
	var y: int = ground_y_tiles
	_last_hill_up = false
	
	# Use tile IDs from instance variables that were set in _setup_tileset
	
	# Generate terrain dalam chunk kecil per frame
	while x < world_width_tiles:
		var chunk_size: int = min(10, world_width_tiles - x)  # Process 10 tiles per frame
		var chunk_end: int = x + chunk_size
		
		while x < chunk_end and x < world_width_tiles:
			if x < safe_until:
				var top_id: int = _grass_id
				if force_left_cap and use_caps and _grass_left_id != -1:
					top_id = _grass_left_id
					force_left_cap = false
				set_cell(Vector2i(x, y), top_id, Vector2i(0, 0))
				surface_y_by_x[x] = y
				for d in range(1, max(1, fill_depth_tiles) + 1):
					set_cell(Vector2i(x, y + d), _dirt_id, Vector2i(0, 0))
			else:
				if gap_spacing_left > 0:
					gap_spacing_left -= 1
				else:
					var can_gap: bool = x >= edge_guard_tiles and x <= right_guard - min_gap_tiles
					if can_gap and rng.randf() < gap_chance:
						var max_w: int = right_guard - x
						if max_w > max_gap_tiles:
							max_w = max_gap_tiles
						var w: int = rng.randi_range(min_gap_tiles, max_w)
						if use_caps and _grass_right_id != -1 and x > 0:
							set_cell(Vector2i(x - 1, y), _grass_right_id, Vector2i(0, 0))
						x += w
						force_left_cap = use_caps and _grass_left_id != -1
						gap_spacing_left = gap_spacing_tiles
						continue
					
					var do_hill: bool = enable_hills and _hill_up_id != -1 and _hill_down_id != -1 and _hill_up2_id != -1 and _hill_down2_id != -1 and rng.randf() < hill_chance
					if do_hill:
						var dir_up: bool = not _last_hill_up
						if dir_up and y <= hill_y_min:
							dir_up = false
						elif (not dir_up) and y >= hill_y_max:
							dir_up = false
						var run_len: int = hill_run_min_tiles
						var max_len: int = hill_run_max_tiles
						if run_len < 1:
							run_len = 1
						if max_len < run_len:
							max_len = run_len
						var remaining: int = world_width_tiles - x
						if max_len > remaining:
							max_len = remaining
						run_len = rng.randi_range(run_len, max_len)
						if run_len >= 2:
							var dy: int = (-1 if dir_up else 1)
							var start_tid: int = (_hill_up2_id if dir_up else _hill_down_id)
							set_cell(Vector2i(x, y), start_tid, Vector2i(0, 0))
							if dir_up:
								for d in range(1, max(1, fill_depth_tiles) + 1):
									set_cell(Vector2i(x, y + d), _dirt_id, Vector2i(0, 0))
							else:
								for d in range(1, max(1, fill_depth_tiles) + 1):
									set_cell(Vector2i(x, y + d), _dirt_id, Vector2i(0, 0))
							var end_tid: int = (_hill_up_id if dir_up else _hill_down2_id)
							set_cell(Vector2i(x, y + dy), end_tid, Vector2i(0, 0))
							surface_y_by_x[x] = y + dy
							if dir_up:
								for d in range(2, max(1, fill_depth_tiles) + 1):
									set_cell(Vector2i(x, y + dy + d), _dirt_id, Vector2i(0, 0))
							else:
								for d in range(1, max(1, fill_depth_tiles) + 1):
									set_cell(Vector2i(x, y + dy + d), _dirt_id, Vector2i(0, 0))
							y += dy
							x += 1
							gap_spacing_left = gap_spacing_tiles
							_last_hill_up = dir_up
							continue
						force_left_cap = false
						gap_spacing_left = gap_spacing_tiles
						_last_hill_up = dir_up
						continue
			
			var top_id2: int = _grass_id
			if force_left_cap and use_caps and _grass_left_id != -1:
				top_id2 = _grass_left_id
				force_left_cap = false
			set_cell(Vector2i(x, y), top_id2, Vector2i(0, 0))
			surface_y_by_x[x] = y
			for d in range(1, max(1, fill_depth_tiles) + 1):
				set_cell(Vector2i(x, y + d), _dirt_id, Vector2i(0, 0))
			x += 1
		
		# Yield frame untuk menghindari lag
		if x < world_width_tiles:
			await get_tree().process_frame
	
	# Complete border and spikes after terrain is done
	if draw_border:
		call_deferred("_rebuild_border_lines", tile_size)
	call_deferred("_rebuild_spikes", tile_size)

func _clear_border_lines() -> void:
	for c in get_children():
		if c is Line2D:
			c.queue_free()

func _add_border_line(points: PackedVector2Array) -> void:
	var ln := Line2D.new()
	ln.default_color = border_color
	ln.width = border_width_px / max(tile_scale, 0.0001)
	ln.z_index = 6
	ln.points = points
	add_child(ln)

func _rebuild_border_lines(tile_sz: int) -> void:
	_clear_border_lines()
	var in_seg := false
	var current_y := 0
	var points := PackedVector2Array()
	for x in range(world_width_tiles):
		var y := surface_y_by_x[x]
		if y >= 0:
			if not in_seg:
				in_seg = true
				current_y = y
				points.append(Vector2(float(x * tile_sz), float(y * tile_sz)))
			else:
				if y != current_y:
					points.append(Vector2(float(x * tile_sz), float(current_y * tile_sz)))
					points.append(Vector2(float(x * tile_sz), float(y * tile_sz)))
					current_y = y
		else:
			if in_seg:
				points.append(Vector2(float(x * tile_sz), float(current_y * tile_sz)))
				_add_border_line(points)
				points = PackedVector2Array()
				in_seg = false
	if in_seg:
		points.append(Vector2(float(world_width_tiles * tile_sz), float(current_y * tile_sz)))
		_add_border_line(points)

func _ensure_obstacles_container() -> Node2D:
	var cont := get_node_or_null("Obstacles") as Node2D
	if not cont:
		cont = Node2D.new()
		cont.name = "Obstacles"
		add_child(cont)
	return cont

func _clear_obstacles() -> void:
	var cont := _ensure_obstacles_container()
	for c in cont.get_children():
		c.queue_free()

func _rebuild_spikes(tile_sz: int) -> void:
	if not enable_spikes:
		return
	_clear_obstacles()
	var cont := _ensure_obstacles_container()
	var tex := load(spike_texture_path) as Texture2D
	if not tex:
		return
	var rng := RandomNumberGenerator.new()
	if rng_seed == 0:
		# Jika rng_seed 0, generate seed random berdasarkan waktu
		rng.randomize()
	else:
		# Jika rng_seed diset, gunakan seed yang sudah ditentukan
		rng.seed = rng_seed
	var right_guard := world_width_tiles - edge_guard_tiles
	var start_x: int = max(flat_prefix_tiles, edge_guard_tiles)
	var spacing_left: int = 0
	for x in range(start_x, right_guard):
		if spacing_left > 0:
			spacing_left -= 1
			continue
		var y: int = surface_y_by_x[x]
		if y < 0:
			continue
		if x <= edge_guard_tiles or x >= right_guard - 1:
			continue
		var y_prev: int = surface_y_by_x[x - 1]
		var y_next: int = surface_y_by_x[x + 1]
		if y_prev < 0 or y_next < 0:
			continue
		if rng.randf() >= spike_chance:
			continue
		var spr := Sprite2D.new()
		spr.texture = tex
		spr.centered = false
		spr.z_index = spike_z_index
		spr.position = Vector2(float(x * tile_sz), float(y * tile_sz) - float(tile_sz))
		cont.add_child(spr)
		spacing_left = spike_spacing_tiles
