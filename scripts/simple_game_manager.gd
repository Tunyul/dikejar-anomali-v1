extends Node2D

enum Phase { TITLE, LOADING, ENTRY, PLAYING, GAME_OVER }
var phase: Phase = Phase.TITLE
var game_active: bool = false
var score: int = 0
var distance: float = 0.0
var loading_start_ms: int = 0
var min_loading_ms: int = 500
var loading_pct: float = 0.0
var load_progress_a: float = 0.0
var load_progress_b: float = 0.0
var done_a: bool = false
var done_b: bool = false
var countdown_remaining: int = 0
var countdown_running: bool = false

@onready var player = $Player
@onready var terrain = $Terrain
@onready var terrain_b = $TerrainB
@onready var ground_a: Node2D = $Terrain/Ground
@onready var ground_b: Node2D = $TerrainB/Ground
@onready var parallax = $ParallaxBackground
@onready var canvas = $CanvasLayer
@onready var title = canvas.get_node_or_null("TitleScreen")
@onready var loading = canvas.get_node_or_null("LoadingScreen")
@onready var game_over = canvas.get_node_or_null("GameOverScreen")
@onready var countdown_label: Label = canvas.get_node_or_null("CountdownLabel")

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
	set_title_phase()

func _process(delta: float) -> void:
	if phase == Phase.PLAYING:
		var terrain_speed = 150.0
		distance += terrain_speed * delta
		score = int(distance / 10.0)
	elif phase == Phase.LOADING:
		var elapsed = Time.get_ticks_msec() - loading_start_ms
		var loading_ready := (done_a and done_b) or loading_pct >= 0.999
		var loading_timeout := elapsed > 2000 and loading_pct >= 0.9
		if (loading_ready or loading_timeout) and elapsed >= min_loading_ms:
			set_entry_phase()

func set_title_phase() -> void:
	phase = Phase.TITLE
	game_active = false
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
	if ground_b and ground_b.has_method("set_title_mode"):
		ground_b.set_title_mode(true)
	if player:
		player.visible = false
	if title:
		title.show()
	if loading:
		loading.hide()
	if game_over:
		game_over.hide()

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
		if ground_a and ground_a.has_signal("generation_progress"):
			ground_a.connect("generation_progress", Callable(self, "on_generation_progress").bind("A"))
		if ground_b and ground_b.has_signal("generation_progress"):
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
		game_over.connect("restart_requested", Callable(self, "restart_game"))

func restart_game() -> void:
	set_title_phase()

func get_game_state() -> Dictionary:
	return {
		"phase": phase,
		"game_active": game_active,
		"score": score,
		"distance": distance
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
		set_playing_phase()
		return
	if countdown_label:
		countdown_label.text = str(countdown_remaining)
	countdown_remaining -= 1
	var t := get_tree().create_timer(1.0)
	t.timeout.connect(Callable(self, "_run_countdown_step"))
