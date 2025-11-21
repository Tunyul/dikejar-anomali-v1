extends Node2D

enum Phase { TITLE, LOADING, ENTRY, PLAYING, GAME_OVER }
var phase: Phase = Phase.TITLE
var game_active: bool = false
var score: int = 0
var distance: float = 0.0
var best_score: int = 0
var loading_start_ms: int = 0
var min_loading_ms: int = 500
var loading_pct: float = 0.0
var load_progress_a: float = 0.0
var load_progress_b: float = 0.0
var done_a: bool = false
var done_b: bool = false
var countdown_remaining: int = 0
var countdown_running: bool = false
@export var debug_info_enabled: bool = true

@onready var player = $Player
@onready var terrain = get_node_or_null("Terrain")
@onready var terrain_b = get_node_or_null("TerrainB")
@onready var ground_a: Node2D = get_node_or_null("Ground")
@onready var ground_b: Node2D = get_node_or_null("TerrainB/Ground")
@onready var parallax = $ParallaxBackground
@onready var canvas = $CanvasLayer
@onready var title = canvas.get_node_or_null("TitleScreen")
@onready var loading = canvas.get_node_or_null("LoadingScreen")
@onready var game_over = canvas.get_node_or_null("GameOverScreen")
@onready var countdown_label: Label = canvas.get_node_or_null("CountdownLabel")
@onready var ui_manager: Control = canvas.get_node_or_null("UIManager")
@onready var ui_distance: Node = ui_manager.get_node_or_null("DistanceCounter") if ui_manager != null else null
@onready var ui_timer: Node = ui_manager.get_node_or_null("GameTimer") if ui_manager != null else null
@onready var debug_label: Label = canvas.get_node_or_null("DebugInfoLabel")

func _ready() -> void:
	if player:
		player.connect("game_over_signal", Callable(self, "on_player_game_over"))
		player.connect("state_changed", Callable(self, "on_player_state_changed"))
	if title:
		title.connect("start_game_requested", Callable(self, "on_start_game"))
		title.connect("quit_game_requested", Callable(self, "on_quit_game"))
	if canvas and countdown_label == null:
		var lbl := Label.new()
		lbl.name = "CountdownLabel"
		lbl.visible = false
		lbl.z_index = 1000
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 200)
		lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		lbl.offset_left = 0
		lbl.offset_top = 0
		lbl.offset_right = 0
		lbl.offset_bottom = 0
		canvas.add_child(lbl)
		countdown_label = lbl
	if canvas and debug_label == null:
		var dl := Label.new()
		dl.name = "DebugInfoLabel"
		dl.visible = debug_info_enabled
		dl.z_index = 999
		dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		dl.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		dl.add_theme_font_size_override("font_size", 22)
		dl.add_theme_color_override("font_color", Color(0, 0, 0, 1))
		dl.set_anchors_preset(Control.PRESET_TOP_LEFT)
		# Tempatkan di bawah DistanceCounter (yang ber-offset 90,40)
		dl.offset_left = 90
		dl.offset_top = 80
		if ui_manager != null:
			ui_manager.add_child(dl)
		else:
			canvas.add_child(dl)
		debug_label = dl
	_load_best_score()
	set_title_phase()

func _process(delta: float) -> void:
	if debug_info_enabled and debug_label != null:
		var sa := "-"
		var sb := "-"
		if ground_a and ground_a.has_method("get_speed"):
			sa = str(int(round(ground_a.get_speed())))
		if ground_b and ground_b.has_method("get_speed"):
			sb = str(int(round(ground_b.get_speed())))
		var phase_name := "TITLE"
		if phase == Phase.LOADING:
			phase_name = "LOADING"
		elif phase == Phase.ENTRY:
			phase_name = "ENTRY"
		elif phase == Phase.PLAYING:
			phase_name = "PLAYING"
		elif phase == Phase.GAME_OVER:
			phase_name = "GAME_OVER"
		var tint_enabled := false
		if ground_a:
			tint_enabled = bool(ground_a.get("debug_tint_enabled"))
		var gen := "-"
		if not done_a and load_progress_a > 0.0 and load_progress_a < 0.999:
			gen = "A"
		elif not done_b and load_progress_b > 0.0 and load_progress_b < 0.999:
			gen = "B"
		var active_a := "-"
		var active_b := "-"
		if ground_a and ground_a.has_method("get_active_segment_name"):
			active_a = ground_a.get_active_segment_name()
		if ground_b and ground_b.has_method("get_active_segment_name"):
			active_b = ground_b.get_active_segment_name()
		var px := "-"
		var py := "-"
		if player:
			var ppos: Vector2 = player.global_position
			px = str(int(round(ppos.x)))
			py = str(int(round(ppos.y)))
		debug_label.visible = true
		debug_label.text = "Phase: %s\nGround A speed: %s\nGround B speed: %s\nGenerating: %s\nActive: A=%s B=%s\nPlayer pos: x=%s y=%s\nDebug tint: %s" % [phase_name, sa, sb, gen, active_a, active_b, px, py, str(tint_enabled)]
	elif debug_label != null:
		debug_label.visible = false
	if phase == Phase.PLAYING:
		var terrain_speed = 150.0
		distance += terrain_speed * delta
		score = int(distance / 10.0)
		if ui_distance and ui_distance.has_method("set_distance"):
			ui_distance.set_distance(distance)
	elif phase == Phase.LOADING:
		var elapsed = Time.get_ticks_msec() - loading_start_ms
		var loading_ready := (done_a and done_b) or loading_pct >= 0.999
		var loading_timeout := elapsed > 2000 and loading_pct >= 0.9
		if (loading_ready or loading_timeout) and elapsed >= min_loading_ms:
			set_entry_phase()

func set_title_phase() -> void:
	phase = Phase.TITLE
	game_active = false
	score = 0
	distance = 0.0
	countdown_running = false
	countdown_remaining = 0
	if parallax and parallax.has_method("set_movement_enabled"):
		parallax.set_movement_enabled(true)
	if terrain and terrain.has_method("set_movement_enabled"):
		terrain.set_movement_enabled(true)
		if terrain.has_method("set_speed"):
			terrain.set_speed(100.0)
	if terrain_b and terrain_b.has_method("set_movement_enabled"):
		terrain_b.set_movement_enabled(true)
		if terrain_b.has_method("set_speed"):
			terrain_b.set_speed(150.0)
	if ground_a and ground_a.has_method("set_title_mode"):
		ground_a.set_title_mode(true)
	if ground_a and ground_a.has_method("set_movement_enabled"):
		ground_a.set_movement_enabled(false)
	if ground_b and ground_b.has_method("set_title_mode"):
		ground_b.set_title_mode(true)
	if ground_b and ground_b.has_method("set_movement_enabled"):
		ground_b.set_movement_enabled(false)
	if player:
		player.visible = false
		if player.has_method("reset_player"):
			player.reset_player()
	if title:
		title.show()
	if loading:
		loading.hide()
	if game_over:
		game_over.hide()
	if ui_manager:
		ui_manager.hide()
	if ui_timer and ui_timer.has_method("reset"):
		ui_timer.reset()
	var bgm := get_node_or_null("BGM")
	if bgm and bgm is AudioStreamPlayer:
		(bgm as AudioStreamPlayer).stop()

func on_start_game() -> void:
	set_loading_phase()

func on_quit_game() -> void:
	get_tree().quit()

func set_loading_phase() -> void:
	phase = Phase.LOADING
	if title:
		title.hide()
	if loading and loading.has_method("show_screen"):
		loading.show_screen()
		if loading.has_method("start_transition"):
			loading.start_transition()
		loading_start_ms = Time.get_ticks_msec()
		loading_pct = 0.0
		load_progress_a = 0.0
		load_progress_b = 0.0
		done_a = false
		done_b = false
		if not ground_b:
			load_progress_b = 1.0
			done_b = true
		if not ground_a and not ground_b:
			loading_pct = 1.0
			done_a = true
			done_b = true
		if ground_a and ground_a.has_signal("generation_progress") and not ground_a.is_connected("generation_progress", Callable(self, "on_generation_progress")):
			ground_a.connect("generation_progress", Callable(self, "on_generation_progress").bind("A"))
		if ground_b and ground_b.has_signal("generation_progress") and not ground_b.is_connected("generation_progress", Callable(self, "on_generation_progress")):
			ground_b.connect("generation_progress", Callable(self, "on_generation_progress").bind("B"))
	if ground_a and ground_a.has_method("generate_random"):
		ground_a.generate_random()
	if ground_b and ground_b.has_method("generate_random"):
		ground_b.generate_random()

func on_generation_progress(pct: float, src: String) -> void:
	if src == "A":
		load_progress_a = pct
		if pct >= 0.999:
			done_a = true
	elif src == "B":
		load_progress_b = pct
		if pct >= 0.999:
			done_b = true
	var avg_pct = (load_progress_a + load_progress_b) * 0.5
	loading_pct = avg_pct
	if loading and loading.has_method("set_progress"):
		loading.set_progress(avg_pct)
	var elapsed = Time.get_ticks_msec() - loading_start_ms
	var loading_ready := (done_a and done_b) or avg_pct >= 0.999
	var loading_timeout := elapsed > 2000 and avg_pct >= 0.9
	if phase == Phase.LOADING and (loading_ready or loading_timeout) and elapsed >= min_loading_ms:
		set_entry_phase()

func set_entry_phase() -> void:
	phase = Phase.ENTRY
	if loading and loading.has_method("hide_screen"):
		if loading.has_method("finish_transition"):
			loading.finish_transition()
		loading.hide_screen()
	if parallax and parallax.has_method("set_movement_enabled"):
		parallax.set_movement_enabled(false)
	if terrain and terrain.has_method("set_movement_enabled"):
		terrain.set_movement_enabled(false)
	if terrain_b and terrain_b.has_method("set_movement_enabled"):
		terrain_b.set_movement_enabled(false)
	if ground_a and ground_a.has_method("set_title_mode"):
		ground_a.set_title_mode(false)
	if ground_b and ground_b.has_method("set_title_mode"):
		ground_b.set_title_mode(false)
	if ground_a and ground_a.has_method("set_movement_enabled"):
		ground_a.set_movement_enabled(false)
	if ground_b and ground_b.has_method("set_movement_enabled"):
		ground_b.set_movement_enabled(false)
	if player and player.has_method("start_appearance_from_left"):
		call_deferred("trigger_player_entry")

func trigger_player_entry() -> void:
	if player and player.has_method("start_appearance_from_left"):
		player.visible = true
		player.start_appearance_from_left(Vector2(280, 444))

func set_playing_phase() -> void:
	phase = Phase.PLAYING
	game_active = true
	if parallax and parallax.has_method("set_movement_enabled"):
		parallax.set_movement_enabled(true)
	if terrain and terrain.has_method("set_movement_enabled"):
		terrain.set_movement_enabled(true)
	if terrain_b and terrain_b.has_method("set_movement_enabled"):
		terrain_b.set_movement_enabled(true)
	if ground_a and ground_a.has_method("set_movement_enabled"):
		ground_a.set_movement_enabled(true)
		if ground_a.has_method("set_speed"):
			ground_a.set_speed(150.0)
		if ground_a.has_method("ensure_second_segment_ready"):
			ground_a.ensure_second_segment_ready()
	if ground_b and ground_b.has_method("set_movement_enabled"):
		ground_b.set_movement_enabled(true)
		if ground_b.has_method("set_speed"):
			ground_b.set_speed(150.0)
	if ui_manager:
		ui_manager.show()
	if ui_timer and ui_timer.has_method("start"):
		ui_timer.start()
	var bgm2 := get_node_or_null("BGM")
	if bgm2 and bgm2 is AudioStreamPlayer and (bgm2 as AudioStreamPlayer).stream != null:
		(bgm2 as AudioStreamPlayer).play()

func on_player_game_over(_cause: String) -> void:
	phase = Phase.GAME_OVER
	game_active = false
	if parallax and parallax.has_method("set_movement_enabled"):
		parallax.set_movement_enabled(false)
	if terrain and terrain.has_method("set_movement_enabled"):
		terrain.set_movement_enabled(false)
	if terrain_b and terrain_b.has_method("set_movement_enabled"):
		terrain_b.set_movement_enabled(false)
	if game_over and game_over.has_method("show_screen"):
		game_over.show_screen()
		if not game_over.is_connected("restart_requested", Callable(self, "restart_game")):
			game_over.connect("restart_requested", Callable(self, "restart_game"))
	if ui_timer and ui_timer.has_method("stop"):
		ui_timer.stop()
	if score > best_score:
		best_score = score
		_save_best_score()
	var bgm3 := get_node_or_null("BGM")
	if bgm3 and bgm3 is AudioStreamPlayer:
		(bgm3 as AudioStreamPlayer).stop()

func restart_game() -> void:
	set_title_phase()

func get_game_state() -> Dictionary:
	return {
		"phase": phase,
		"game_active": game_active,
		"score": score,
		"distance": distance,
		"best_score": best_score
	}
func on_player_state_changed(new_state, _old_state) -> void:
	if new_state == player.PlayerState.FULL_MOVEMENT:
		start_countdown()

func start_countdown() -> void:
	if countdown_running:
		return
	countdown_running = true
	countdown_remaining = 3
	if parallax and parallax.has_method("set_movement_enabled"):
		parallax.set_movement_enabled(false)
	if terrain and terrain.has_method("set_movement_enabled"):
		terrain.set_movement_enabled(false)
	if terrain_b and terrain_b.has_method("set_movement_enabled"):
		terrain_b.set_movement_enabled(false)
	if countdown_label:
		countdown_label.visible = true
		countdown_label.text = str(countdown_remaining)
		_run_countdown_step()

func _run_countdown_step() -> void:
	if countdown_remaining <= 0:
		if countdown_label:
			countdown_label.visible = false
		countdown_running = false
		await regenerate_gameplay_ground()
		set_playing_phase()
		return
	if countdown_label:
		countdown_label.text = str(countdown_remaining)
	countdown_remaining -= 1
	var t := get_tree().create_timer(1.0)
	t.timeout.connect(Callable(self, "_run_countdown_step"))

func regenerate_gameplay_ground() -> void:
	if ground_a and ground_a.has_method("set_title_mode"):
		ground_a.set_title_mode(false)
	if ground_b and ground_b.has_method("set_title_mode"):
		ground_b.set_title_mode(false)
	# Hubungkan progres untuk pemantauan ringan
	if ground_a and ground_a.has_signal("generation_progress") and not ground_a.is_connected("generation_progress", Callable(self, "on_gameplay_generation_progress")):
		ground_a.connect("generation_progress", Callable(self, "on_gameplay_generation_progress").bind("A"))
	if ground_b and ground_b.has_signal("generation_progress") and not ground_b.is_connected("generation_progress", Callable(self, "on_gameplay_generation_progress")):
		ground_b.connect("generation_progress", Callable(self, "on_gameplay_generation_progress").bind("B"))
	load_progress_a = 0.0
	load_progress_b = 0.0
	done_a = false
	done_b = false
	if ground_a and ground_a.has_method("prepare_gameplay_preserve_flat_start"):
		ground_a.prepare_gameplay_preserve_flat_start()
	elif ground_a and ground_a.has_method("generate_random"):
		ground_a.generate_random()
	var started_ms := Time.get_ticks_msec()
	while true:
		var avg := (load_progress_a + load_progress_b) * 0.5
		var elapsed := Time.get_ticks_msec() - started_ms
		if (done_a and done_b) or avg >= 0.99 or elapsed > 1000:
			break
		await get_tree().process_frame
	# Putuskan koneksi pemantauan untuk kebersihan
	if ground_a and ground_a.is_connected("generation_progress", Callable(self, "on_gameplay_generation_progress")):
		ground_a.disconnect("generation_progress", Callable(self, "on_gameplay_generation_progress"))
	if ground_b and ground_b.is_connected("generation_progress", Callable(self, "on_gameplay_generation_progress")):
		ground_b.disconnect("generation_progress", Callable(self, "on_gameplay_generation_progress"))

func on_gameplay_generation_progress(pct: float, src: String) -> void:
	if src == "A":
		load_progress_a = pct
		if pct >= 0.999:
			done_a = true
	elif src == "B":
		load_progress_b = pct
		if pct >= 0.999:
			done_b = true

func _load_best_score() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load("user://save.cfg")
	if err == OK:
		best_score = int(cfg.get_value("progress", "best_score", 0))

func _save_best_score() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "best_score", best_score)
	cfg.save("user://save.cfg")
func _unhandled_input(event) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		debug_info_enabled = not debug_info_enabled
		if debug_label != null:
			debug_label.visible = debug_info_enabled
