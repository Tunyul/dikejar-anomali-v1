extends Node2D

enum Phase { TITLE, LOADING, ENTRY, PLAYING, GAME_OVER }
var phase: Phase = Phase.TITLE
var game_active: bool = false
var score: int = 0
var distance: float = 0.0
var best_score: int = 0
var coin_collected_a: int = 0
var coin_collected_b: int = 0
var last_score: int = 0
var last_coins: int = 0
var total_coins: int = 0
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

@onready var player: Player = $Player
@onready var anomaly: Node2D = get_node_or_null("AnomalyChaser")
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
@onready var cloud_transition: Control = canvas.get_node_or_null("CloudTransition")

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
		dl.add_theme_font_size_override("font_size", 14)
		dl.add_theme_color_override("font_color", Color(0, 0, 0, 1))
		dl.set_anchors_preset(Control.PRESET_TOP_LEFT)
		dl.offset_left = 8
		dl.offset_top = 8
		if ui_manager != null:
			ui_manager.add_child(dl)
		else:
			canvas.add_child(dl)
		debug_label = dl
		if ui_manager != null and ui_timer != null and ui_timer is Control:
			var gt := ui_timer as Control
			debug_label.offset_left = gt.position.x + 60
			debug_label.offset_top = gt.position.y + 20
		_load_progress()
		set_title_phase()
		_verify_player_scenes()
		if cloud_transition == null:
			var ps := ResourceLoader.load("res://scenes/CloudTransition.tscn")
			if ps and ps is PackedScene:
				var inst := (ps as PackedScene).instantiate()
				inst.name = "CloudTransition"
				canvas.add_child(inst)
				cloud_transition = inst

func _process(delta: float) -> void:
	var sa := "-"
	var sb := "-"
	if debug_info_enabled and debug_label != null:
		if ui_manager != null and ui_timer != null and ui_timer is Control and debug_label.get_parent() == ui_manager:
			var gt := ui_timer as Control
			debug_label.offset_left = gt.position.x + 60
			debug_label.offset_top = gt.position.y + 20
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
	var pstate_name := "-"
	var entry_x := "-"
	var entry_y := "-"
	var countdown_flag := false
	var pos_delta_x := "-"
	if player:
		match player.current_state:
			player.PlayerState.FULL_MOVEMENT:
				pstate_name = "FULL_MOVEMENT"
			player.PlayerState.GAME_OVER:
				pstate_name = "GAME_OVER"
		entry_x = str(int(round(player.entry_stop_x)))
		entry_y = str(int(round(player.entry_stop_y)))
		countdown_flag = player.countdown_active
		pos_delta_x = str(int(round(abs(player.global_position.x - player.entry_stop_x))))
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
		var plx := "-"
		var ply := "-"
		if player and ground_a:
			var lpos: Vector2 = ground_a.to_local(player.global_position)
			plx = str(int(round(lpos.x)))
			ply = str(int(round(lpos.y)))
		var fps := int(round(Engine.get_frames_per_second()))
		var cam_x := 0
		var cam := get_viewport().get_camera_2d()
		if cam != null:
			cam_x = int(round(cam.get_screen_center_position().x))
		var seg_w := 0
		if ground_a and ground_a.has_method("_segment_width_px"):
			seg_w = int(round(float(ground_a.call("_segment_width_px"))))
		var tla_x := "-"
		var tlb_x := "-"
		var coins_a := 0
		var coins_b := 0
		var coin_follow := false
		var cymin := 0
		var cymax := 0
		var cgmin := 0
		var cgmax := 0
		var ccmin := 0
		var ccmax := 0
		var csmin := 0
		var csmax := 0
		var cgsmin := 0
		var cgsmax := 0
		var cscale := 1.0
		var cfps := 12.0
		var coamp := 0.0
		var cofreq := 0.0
		if ground_a:
			var tla := ground_a.get_node_or_null("TileMapLayer")
			var tlb := ground_a.get_node_or_null("TileMapLayerB")
			if tla and tla is Node2D:
				tla_x = str(int(round((tla as Node2D).position.x)))
			if tlb and tlb is Node2D:
				tlb_x = str(int(round((tlb as Node2D).position.x)))
			var ca := ground_a.get_node_or_null("CoinsA")
			var cb := ground_a.get_node_or_null("CoinsB")
			if ca:
				coins_a = ca.get_child_count()
				for c in ca.get_children():
					if c.has_signal("collected") and not c.is_connected("collected", Callable(self, "on_coin_collected")):
						c.connect("collected", Callable(self, "on_coin_collected"))
			if cb:
				coins_b = cb.get_child_count()
				for c2 in cb.get_children():
					if c2.has_signal("collected") and not c2.is_connected("collected", Callable(self, "on_coin_collected")):
						c2.connect("collected", Callable(self, "on_coin_collected"))
			if tla:
				coin_follow = bool(tla.get("coin_spawn_follow_player"))
				cymin = int(tla.get("coin_y_tiles_min"))
				cymax = int(tla.get("coin_y_tiles_max"))
				cgmin = int(tla.get("coin_groups_min"))
				cgmax = int(tla.get("coin_groups_max"))
				ccmin = int(tla.get("coins_per_group_min"))
				ccmax = int(tla.get("coins_per_group_max"))
				csmin = int(tla.get("coin_spacing_tiles_min"))
				csmax = int(tla.get("coin_spacing_tiles_max"))
				cgsmin = int(tla.get("coin_group_spacing_tiles_min"))
				cgsmax = int(tla.get("coin_group_spacing_tiles_max"))
				cscale = float(tla.get("coin_scale"))
				cfps = float(tla.get("coin_anim_fps"))
				coamp = float(tla.get("coin_osc_amplitude"))
				cofreq = float(tla.get("coin_osc_frequency"))
		debug_label.visible = true
		debug_label.text = "Player: x=%s y=%s\nPlayerLocal: x=%s y=%s\nFPS: %d\nPhase: %s | PState: %s | Ex/Ey: %s/%s | DX:%s | CDown: %s\nCoin A : %d / Coin B : %d\nSpeed A/B: %s/%s\nGen: %s Active: %s|%s\nCamX: %d SegW: %d\nTA/TB X: %s/%s\nCoins A/B: %d/%d | F:%s Y:%d-%d G:%d-%d C:%d-%d S:%d-%d GS:%d-%d Sc:%.1f CFPS:%.1f Osc:%.1f/%.1f\nTint: %s" % [px, py, plx, ply, fps, phase_name, pstate_name, entry_x, entry_y, pos_delta_x, str(countdown_flag), coin_collected_a, coin_collected_b, sa, sb, gen, active_a, active_b, cam_x, seg_w, tla_x, tlb_x, coins_a, coins_b, str(coin_follow), cymin, cymax, cgmin, cgmax, ccmin, ccmax, csmin, csmax, cgsmin, cgsmax, cscale, cfps, coamp, cofreq, str(tint_enabled)]
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
	coin_collected_a = 0
	coin_collected_b = 0
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
		var pa := ground_a.get_parent()
		if pa != null:
			var ca := pa.get_node_or_null("CoinsA")
			var cb := pa.get_node_or_null("CoinsB")
			if ca:
				for c in ca.get_children():
					c.queue_free()
			if cb:
				for c in cb.get_children():
					c.queue_free()
	if ground_a and ground_a.has_method("set_movement_enabled"):
		ground_a.set_movement_enabled(false)
	if ground_b and ground_b.has_method("set_title_mode"):
		ground_b.set_title_mode(true)
		var pb := ground_b.get_parent()
		if pb != null:
			var ca2 := pb.get_node_or_null("CoinsA")
			var cb2 := pb.get_node_or_null("CoinsB")
			if ca2:
				for c2 in ca2.get_children():
					c2.queue_free()
			if cb2:
				for c2 in cb2.get_children():
					c2.queue_free()
	if ground_b and ground_b.has_method("set_movement_enabled"):
		ground_b.set_movement_enabled(false)
	if player:
		player.visible = false
		if player.has_method("reset_player"):
			player.reset_player()
		if title:
			if title.has_method("set_stats"):
				title.set_stats(best_score, last_score, last_coins, total_coins)
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
	if anomaly:
		anomaly.hide()

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
	if anomaly:
		anomaly.hide()

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
	if cloud_transition and cloud_transition.has_method("play"):
		cloud_transition.call("play")
		await cloud_transition.finished
	if player:
		player.visible = true
		if player.entry_stop_x <= 0.0:
			player.entry_stop_x = 280.0
		player.global_position = Vector2(player.entry_stop_x, player.entry_stop_y)
		player.position = Vector2(player.entry_stop_x, player.entry_stop_y)
	await get_tree().create_timer(0.3).timeout
	start_countdown()
	if anomaly:
		anomaly.hide()

func trigger_player_entry() -> void:
	if player:
		player.visible = true
		if player.entry_stop_x <= 0.0:
			player.entry_stop_x = 280.0
		player.global_position = Vector2(player.entry_stop_x, player.entry_stop_y)
		player.position = Vector2(player.entry_stop_x, player.entry_stop_y)

func set_playing_phase() -> void:
	phase = Phase.PLAYING
	game_active = true
	if ground_a and ground_a.has_method("set_speed_limits"):
		ground_a.set_speed_limits(0.0, 300.0)
	if ground_b and ground_b.has_method("set_speed_limits"):
		ground_b.set_speed_limits(0.0, 300.0)
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
	if ground_b and ground_b.has_method("set_movement_enabled"):
		ground_b.set_movement_enabled(true)
		if ground_b.has_method("set_speed"):
			ground_b.set_speed(150.0)
	if player:
		if player.has_method("prepare_for_playing_phase"):
			player.prepare_for_playing_phase()
		if player.has_method("enable_environment_movement"):
			player.enable_environment_movement(true)
		if player.entry_stop_x <= 0.0:
			player.entry_stop_x = 280.0
		player.global_position = Vector2(player.entry_stop_x, player.global_position.y)
		player.position = Vector2(player.entry_stop_x, player.position.y)
	if ui_manager:
		ui_manager.show()
	if ui_timer and ui_timer.has_method("start"):
		ui_timer.start()
	var bgm2 := get_node_or_null("BGM")
	if bgm2 and bgm2 is AudioStreamPlayer and (bgm2 as AudioStreamPlayer).stream != null:
		(bgm2 as AudioStreamPlayer).play()
	if anomaly:
		if anomaly.has_method("start_appear"):
			anomaly.start_appear()
		anomaly.show()


func on_player_game_over(_cause: String) -> void:
	phase = Phase.GAME_OVER
	game_active = false
	if parallax and parallax.has_method("set_movement_enabled"):
		parallax.set_movement_enabled(false)
	if terrain and terrain.has_method("set_movement_enabled"):
		terrain.set_movement_enabled(false)
	if terrain_b and terrain_b.has_method("set_movement_enabled"):
		terrain_b.set_movement_enabled(false)
	if ground_a and ground_a.has_method("set_movement_enabled"):
		ground_a.set_movement_enabled(false)
	if ground_b and ground_b.has_method("set_movement_enabled"):
		ground_b.set_movement_enabled(false)
	if game_over and game_over.has_method("show_screen"):
		game_over.show_screen()
		if not game_over.is_connected("restart_requested", Callable(self, "restart_game")):
			game_over.connect("restart_requested", Callable(self, "restart_game"))
	if ui_timer and ui_timer.has_method("stop"):
		ui_timer.stop()
	if ui_manager:
		ui_manager.hide()
	last_score = score
	last_coins = coin_collected_a + coin_collected_b
	total_coins += last_coins
	if score > best_score:
		best_score = score
		_save_progress()
	_save_progress()
	var bgm3 := get_node_or_null("BGM")
	if bgm3 and bgm3 is AudioStreamPlayer:
		(bgm3 as AudioStreamPlayer).stop()
	if anomaly:
		anomaly.hide()

func restart_game() -> void:
	set_title_phase()
	if ground_a and ground_a.has_method("set_movement_enabled"):
		ground_a.set_movement_enabled(false)
	if ground_b and ground_b.has_method("set_movement_enabled"):
		ground_b.set_movement_enabled(false)

func get_game_state() -> Dictionary:
	return {
		"phase": phase,
		"game_active": game_active,
		"score": score,
		"distance": distance,
		"best_score": best_score
	}
func on_player_state_changed(new_state, _old_state) -> void:
	if new_state == player.PlayerState.FULL_MOVEMENT and phase == Phase.ENTRY:
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
	if player and player.has_method("begin_countdown"):
		player.begin_countdown()
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
		if ground_a and ground_a.has_method("spawn_initial_coins"):
			ground_a.spawn_initial_coins()
		if player and player.has_method("end_countdown"):
			player.end_countdown()
		if player:
			if player.entry_stop_x <= 0.0:
				player.entry_stop_x = 280.0
			player.global_position = Vector2(player.entry_stop_x, player.global_position.y)
			player.position = Vector2(player.entry_stop_x, player.position.y)
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

func _verify_player_scenes() -> void:
	if not OS.is_debug_build():
		return
	var dir: DirAccess = DirAccess.open("res://scenes")
	if dir == null:
		return
	dir.list_dir_begin()
	var file: String = dir.get_next()
	var report: Array[String] = []
	while file != "":
		var found: Array = []
		var status: String = "-"
		if not dir.current_is_dir() and file.ends_with(".tscn"):
			var p: String = "res://scenes/" + file
			var sc: Resource = ResourceLoader.load(p)
			if sc and sc is PackedScene:
				var inst: Node = (sc as PackedScene).instantiate()
				var q: Array = []
				q.append(inst)
				while q.size() > 0:
					var n: Node = q.pop_back() as Node
					if n:
						for c in n.get_children():
							q.append(c)
						if n.name == "Player" or (player and n.get_class() == player.get_class()):
							found.append(n)
				status = "OK"
				var issues: Array = []
				for pn in found:
					var aspr: AnimatedSprite2D = pn.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
					var col: CollisionShape2D = pn.get_node_or_null("CollisionShape2D") as CollisionShape2D
					var ray: RayCast2D = pn.get_node_or_null("GroundRay") as RayCast2D
					if aspr == null:
						issues.append("Missing AnimatedSprite2D")
					if col == null:
						issues.append("Missing CollisionShape2D")
					if ray == null:
						issues.append("Missing GroundRay")
					var ex_exists: bool = false
					var ex_val: float = 0.0
					var plist: Array = pn.get_property_list()
					for pr in plist:
						var pname = pr.get("name")
						if String(pname) == "entry_stop_x":
							ex_exists = true
							ex_val = float(pn.get("entry_stop_x"))
							break
					if ex_exists and ex_val <= 0.0:
						issues.append("entry_stop_x<=0")
				if issues.size() > 0:
					status = "ISSUES: " + ",".join(issues)
			else:
				status = "LOAD_FAIL"
		var line: String = file + " Players:" + str(found.size()) + " " + status
		report.append(line)
		file = dir.get_next()
	dir.list_dir_end()
	if report.size() > 0:
		if debug_label != null:
			debug_label.visible = true
			debug_label.text = "SceneCheck:\n" + "\n".join(report)
		else:
			print("SceneCheck:\n" + "\n".join(report))

func _load_progress() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load("user://save.cfg")
	if err == OK:
		best_score = int(cfg.get_value("progress", "best_score", 0))
		last_score = int(cfg.get_value("progress", "last_score", 0))
		last_coins = int(cfg.get_value("progress", "last_coins", 0))
		total_coins = int(cfg.get_value("progress", "total_coins", 0))

func _save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "best_score", best_score)
	cfg.set_value("progress", "last_score", last_score)
	cfg.set_value("progress", "last_coins", last_coins)
	cfg.set_value("progress", "total_coins", total_coins)
	cfg.save("user://save.cfg")
func _unhandled_input(event) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		debug_info_enabled = not debug_info_enabled
		if debug_label != null:
			debug_label.visible = debug_info_enabled
func on_coin_collected(segment: String) -> void:
	if segment == "A":
		coin_collected_a += 1
	else:
		coin_collected_b += 1
