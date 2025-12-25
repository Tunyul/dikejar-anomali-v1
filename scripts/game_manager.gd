extends Node2D

enum Phase { ENTRY, PLAYING, GAME_OVER }
var phase: Phase = Phase.ENTRY
var game_active: bool = false
var score: int = 0
var distance: float = 0.0
var best_score: int = 0
var coin_collected_a: int = 0
var coin_collected_b: int = 0
var last_score: int = 0
var last_coins: int = 0
var total_coins: int = 0
var game_time_sec: float = 0.0
var total_tiles_passed: int = 0
var _tiles_passed_accum: float = 0.0
var _debug_time_accum: float = 0.0

@export var debug_info_enabled: bool = false
@export var base_speed: float = 150.0
@export var max_speed: float = 300.0
@export var speed_gain_per_meter: float = 0.02
@export var score_per_meter: float = 0.1
@export var debug_update_interval_sec: float = 0.25
@export var scene_verify_on_start: bool = false
@export var watchdog_fps_threshold: int = 15
@export var watchdog_hang_seconds: float = 1.5
@export var watchdog_print_interval_sec: float = 2.0
@export var perf_log_to_file: bool = false
var magnet_enabled: bool = false

@onready var player: Player = $Player
@onready var anomaly: Node2D = get_node_or_null("AnomalyChaser")
@onready var terrain = get_node_or_null("Terrain")
@onready var terrain_b = get_node_or_null("TerrainB")
@onready var ground_a: Node2D = get_node_or_null("Ground")
@onready var ground_b: Node2D = get_node_or_null("TerrainB/Ground")
@onready var parallax = $ParallaxBackground
@onready var canvas = $CanvasLayer
var debug_label: Label
var _jump_button: TouchScreenButton
var _attack_button: TouchScreenButton
var _ga_layer: Node = null
var _gb_layer: Node = null
var _scene_verify_running: bool = false
var _scene_verify_start_ms: int = 0
var bgm_muted: bool = false
var sfx_muted: bool = false
var magnet_timer: float = 0.0
@export var ads_enabled: bool = true
@export var ads_max_per_session: int = 2
@export var rewarded_continue_grace_sec: float = 5.0
var ads_shown_count: int = 0
var continue_grace_timer: float = 0.0
@onready var coin_hud_label: Label = $CanvasLayer/CoinHUD/Label
@onready var health_bar: ProgressBar = $CanvasLayer/HealthBar
@export var enemy_ramp_start_distance: float = 400.0
@export var enemy_ramp_enabled: bool = true
@export var countdown_duration_sec: float = 3.0

var countdown_active: bool = false
var countdown_timer: float = 0.0
var entry_finished: bool = false

func _ready() -> void:
    if player:
        player.connect("game_over_signal", Callable(self, "on_player_game_over"))
    if OS.is_debug_build():
        if not InputMap.has_action("verify_scenes"):
            InputMap.add_action("verify_scenes")
            var ev2 := InputEventKey.new()
            ev2.physical_keycode = KEY_F6
            InputMap.action_add_event("verify_scenes", ev2)
        if not InputMap.has_action("toggle_debug"):
            InputMap.add_action("toggle_debug")
            var ev3 := InputEventKey.new()
            ev3.physical_keycode = KEY_F3
            InputMap.action_add_event("toggle_debug", ev3)
    _load_progress()
    call_deferred("_start_play_phase")
    if scene_verify_on_start and OS.is_debug_build():
        call_deferred("_verify_player_scenes")
    if OS.is_debug_build() and canvas and debug_label == null:
        var dl := Label.new()
        dl.name = "DebugInfoLabel"
        dl.visible = debug_info_enabled
        dl.z_index = 999
        dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
        dl.vertical_alignment = VERTICAL_ALIGNMENT_TOP
        dl.add_theme_font_size_override("font_size", 18)
        dl.add_theme_color_override("font_color", Color(1, 1, 1, 1))
        dl.add_theme_constant_override("outline_size", 2)
        dl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
        var sb := StyleBoxFlat.new()
        sb.bg_color = Color(0, 0, 0, 0.35)
        sb.corner_radius_top_left = 4
        sb.corner_radius_top_right = 4
        sb.corner_radius_bottom_left = 4
        sb.corner_radius_bottom_right = 4
        dl.add_theme_stylebox_override("normal", sb)
        dl.set_anchors_preset(Control.PRESET_TOP_LEFT)
        dl.offset_left = 8
        dl.offset_top = 8
        dl.mouse_filter = Control.MOUSE_FILTER_IGNORE
        canvas.add_child(dl)
        debug_label = dl
    if canvas:
        var pm := canvas.get_node_or_null("PauseMenu")
        if pm:
            pm.visible = false
        var gom := canvas.get_node_or_null("GameOverMenu")
        if gom:
            gom.visible = false
    if ground_a != null:
        _ga_layer = ground_a.get_node_or_null("TileMapLayerA")
        if _gb_layer == null:
            _gb_layer = ground_a.get_node_or_null("TileMapLayerB")
    if ground_b != null and _gb_layer == null:
        _gb_layer = ground_b.get_node_or_null("TileMapLayerB")

    _connect_mobile_buttons()

func _connect_mobile_buttons() -> void:
    if not canvas or not player:
        return
    _jump_button = canvas.get_node_or_null("MobileControls/JumpButton") as TouchScreenButton
    if _jump_button and _jump_button.has_signal("pressed"):
        _jump_button.pressed.connect(_on_jump_button_pressed)
    _attack_button = canvas.get_node_or_null("MobileControls/AttackButton") as TouchScreenButton
    if _attack_button and _attack_button.has_signal("pressed"):
        _attack_button.pressed.connect(_on_attack_button_pressed)

func _debug_input(msg: String) -> void:
    if OS.is_debug_build():
        print(msg)
    if OS.is_debug_build() and debug_label != null and debug_info_enabled:
        debug_label.visible = true
        debug_label.text = msg

func _on_jump_button_pressed() -> void:
    _debug_input("INPUT: jump_button")
    if player and player.has_method("request_jump"):
        player.request_jump()

func _on_attack_button_pressed() -> void:
    _debug_input("INPUT: attack_button")
    if player and player.has_method("request_attack"):
        player.request_attack()

func _process(delta: float) -> void:
    if countdown_active:
        var lbl := canvas.get_node_or_null("CountdownLabel") if canvas else null
        countdown_timer = max(countdown_timer - delta, 0.0)
        if lbl and lbl is Label:
            var t := int(ceil(countdown_timer))
            if countdown_timer <= 0.0:
                (lbl as Label).visible = false
            elif t > 0:
                (lbl as Label).visible = true
                (lbl as Label).text = str(t)
        if countdown_timer <= 0.0:
            countdown_active = false
            if phase == Phase.ENTRY and entry_finished:
                set_playing_phase()

    if phase == Phase.PLAYING:
        var env_speed: float = base_speed
        if ground_a and ground_a.has_method("get_speed"):
            env_speed = float(ground_a.call("get_speed"))
        var tile_w_px: float = 128.0
        if _ga_layer != null and (_ga_layer as Node).has_method("get"):
            var ts: TileSet = _ga_layer.get("tile_set") if _ga_layer.has_method("get") else null
            if ts != null:
                var cell_a: Vector2i = ts.tile_size
                tile_w_px = float(cell_a.x) * (_ga_layer.get("scale").x if _ga_layer.has_method("get") else 1.0)
        distance += env_speed * delta
        if tile_w_px > 0.0:
            _tiles_passed_accum += env_speed * delta / tile_w_px
            total_tiles_passed = int(_tiles_passed_accum)
        game_time_sec += delta
        score = int(distance * score_per_meter)
        if coin_hud_label != null:
            coin_hud_label.text = str(coin_collected_a + coin_collected_b)
        if missions_manager and missions_manager.has_method("update_distance"):
            missions_manager.update_distance(distance)
        var target_speed: float = clamp(base_speed + distance * speed_gain_per_meter, base_speed, max_speed)
        if ground_a and ground_a.has_method("set_speed"):
            ground_a.set_speed(target_speed)
        if ground_b and ground_b.has_method("set_speed"):
            ground_b.set_speed(target_speed)
        if player and player.has_method("set_run_anim_factor"):
            var anim_factor: float = max(0.1, target_speed / max(base_speed, 0.1))
            player.call("set_run_anim_factor", anim_factor)
        if magnet_timer > 0.0:
            magnet_timer = max(magnet_timer - delta, 0.0)
            if magnet_timer <= 0.0:
                magnet_enabled = false
        _apply_enemy_ramp_if_needed()
    if OS.is_debug_build() and debug_info_enabled:
        _debug_time_accum += delta
        if _debug_time_accum >= debug_update_interval_sec:
            _debug_time_accum = 0.0
            _update_debug_label()
    if continue_grace_timer > 0.0:
        continue_grace_timer = max(continue_grace_timer - delta, 0.0)
        if player:
            player.enable_fall_death = false
    else:
        if player:
            player.enable_fall_death = true

func _update_debug_label() -> void:
    if debug_label == null or not debug_info_enabled:
        return
    var fps: int = int(Engine.get_frames_per_second())
    var env_speed: float = base_speed
    if ground_a and ground_a.has_method("get_speed"):
        env_speed = float(ground_a.call("get_speed"))
    var target_speed: float = clamp(base_speed + distance * speed_gain_per_meter, base_speed, max_speed)
    var layer_name: String = ""
    if ground_a and ground_a.has_method("get_active_segment_name"):
        layer_name = str(ground_a.call("get_active_segment_name"))
    var layer_short: String = ""
    if layer_name.ends_with("A"):
        layer_short = "A"
    elif layer_name.ends_with("B"):
        layer_short = "B"
    var time_s: int = int(game_time_sec)
    var coins_a: int = coin_collected_a
    var coins_b: int = coin_collected_b
    var coins_cnt_a: int = 0
    var coins_cnt_b: int = 0
    var enemies_cnt_a: int = 0
    var enemies_cnt_b: int = 0
    if ground_a:
        var coins_a_node := ground_a.get_node_or_null("CoinsA")
        if coins_a_node:
            coins_cnt_a = coins_a_node.get_child_count()
        var coins_b_node := ground_a.get_node_or_null("CoinsB")
        if coins_b_node:
            coins_cnt_b = coins_b_node.get_child_count()
        var enemies_a_node := ground_a.get_node_or_null("EnemiesA")
        if enemies_a_node:
            enemies_cnt_a = enemies_a_node.get_child_count()
        var enemies_b_node := ground_a.get_node_or_null("EnemiesB")
        if enemies_b_node:
            enemies_cnt_b = enemies_b_node.get_child_count()
    var player_pos: Vector2 = Vector2.ZERO
    var player_vel: Vector2 = Vector2.ZERO
    var player_grounded: bool = false
    var player_state_text: String = ""
    var env_move: bool = false
    if player:
        if player.has_method("get_player_state"):
            var ps: Dictionary = player.get_player_state()
            if ps.has("position"):
                player_pos = ps["position"]
            if ps.has("velocity"):
                player_vel = ps["velocity"]
            if ps.has("is_grounded"):
                player_grounded = bool(ps["is_grounded"])
            if ps.has("current_state"):
                var st_val: int = int(ps["current_state"])
                if st_val == 0:
                    player_state_text = "FULL_MOVEMENT"
                elif st_val == 1:
                    player_state_text = "GAME_OVER"
                else:
                    player_state_text = str(st_val)
        if player.has_method("_is_environment_moving"):
            env_move = bool(player._is_environment_moving())
    var jump_pos: Vector2 = Vector2.ZERO
    var attack_pos: Vector2 = Vector2.ZERO
    if _jump_button:
        jump_pos = _jump_button.global_position
    if _attack_button:
        attack_pos = _attack_button.global_position
    var cam_center: Vector2 = Vector2.ZERO
    var cam := get_viewport().get_camera_2d()
    if cam != null:
        cam_center = cam.global_position
    var phase_text: String = ("PLAYING" if phase == Phase.PLAYING else "GAME_OVER")
    var txt: String = ""
    txt += "Phase: " + phase_text + " | GameActive: " + str(game_active)
    txt += "\nEnvSpeed: " + str(int(env_speed)) + " / Target: " + str(int(target_speed)) + " | Base/Max: " + str(int(base_speed)) + "/" + str(int(max_speed))
    var layer_display: String = (layer_short if layer_short != "" else layer_name)
    txt += "\nLayer: " + layer_display + " | TilesPassed: " + str(total_tiles_passed) + " | Time: " + str(time_s) + "s"
    txt += "\nDistance: " + str(int(distance)) + " | Score: " + str(score)
    txt += "\nCoins A/B: " + str(coins_a) + "/" + str(coins_b) + " | Last: " + str(last_coins) + " | Best: " + str(best_score)
    txt += "\nCoinsCnt A/B: " + str(coins_cnt_a) + "/" + str(coins_cnt_b) + " | EnemiesCnt A/B: " + str(enemies_cnt_a) + "/" + str(enemies_cnt_b)
    txt += "\nPlayer XY: " + str(int(player_pos.x)) + "/" + str(int(player_pos.y)) + " | Vel X/Y: " + str(int(player_vel.x)) + "/" + str(int(player_vel.y))
    txt += "\nGrounded: " + str(player_grounded) + " | State: " + (player_state_text if player_state_text != "" else "-") + " | EnvMove: " + str(env_move)
    txt += "\nGround Tiles Run: " + str(total_tiles_passed) + " | L/R: 0/0"
    txt += "\nJumpBtn X/Y: " + str(int(jump_pos.x)) + "/" + str(int(jump_pos.y)) + " | AtkBtn X/Y: " + str(int(attack_pos.x)) + "/" + str(int(attack_pos.y))
    txt += "\nCamCenter X/Y: " + str(int(cam_center.x)) + "/" + str(int(cam_center.y)) + " | FPS: " + str(fps)
    debug_label.visible = true
    debug_label.text = txt

func on_quit_game() -> void:
    get_tree().quit()

func pause_game() -> void:
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
    var bgm := get_node_or_null("BGM")
    if bgm and bgm is AudioStreamPlayer:
        (bgm as AudioStreamPlayer).stop()
    _set_pause_menu_visible(true)
    _refresh_missions_label()

func resume_game() -> void:
    if phase == Phase.GAME_OVER:
        return
    game_active = true
    if parallax and parallax.has_method("set_movement_enabled"):
        parallax.set_movement_enabled(true)
    if terrain and terrain.has_method("set_movement_enabled"):
        terrain.set_movement_enabled(true)
    if terrain_b and terrain_b.has_method("set_movement_enabled"):
        terrain_b.set_movement_enabled(true)
    if ground_a and ground_a.has_method("set_movement_enabled"):
        ground_a.set_movement_enabled(true)
    if ground_b and ground_b.has_method("set_movement_enabled"):
        ground_b.set_movement_enabled(true)
    var tgt: float = clamp(base_speed + distance * speed_gain_per_meter, base_speed, max_speed)
    if ground_a and ground_a.has_method("set_speed"):
        ground_a.set_speed(tgt)
    if ground_b and ground_b.has_method("set_speed"):
        ground_b.set_speed(tgt)
    var bgm := get_node_or_null("BGM")
    if bgm and bgm is AudioStreamPlayer and (bgm as AudioStreamPlayer).stream != null:
        if not bgm_muted:
            (bgm as AudioStreamPlayer).play()
    _set_pause_menu_visible(false)

func return_to_main_menu() -> void:
    if Preloader and Preloader.has_method("set_next_scene"):
        Preloader.set_next_scene("res://scenes/MainMenu.tscn")
    await TransitionManager.play_transition_to_scene("res://scenes/LoadingScreen.tscn")

func try_rewarded_continue() -> void:
    if ads_shown_count >= ads_max_per_session:
        return
    var adm := get_node_or_null("AdManager")
    if adm and adm.has_method("show_rewarded"):
        if adm.has_method("is_rewarded_available") and not adm.is_rewarded_available():
            return
        if adm.has_signal("reward_granted"):
            adm.reward_granted.connect(_on_reward_granted)
        adm.show_rewarded("continue")

func _on_reward_granted(reason: String) -> void:
    if reason == "continue":
        ads_shown_count += 1
        grant_continue()

func grant_continue() -> void:
    phase = Phase.PLAYING
    game_active = true
    continue_grace_timer = rewarded_continue_grace_sec
    if parallax and parallax.has_method("set_movement_enabled"):
        parallax.set_movement_enabled(true)
    if terrain and terrain.has_method("set_movement_enabled"):
        terrain.set_movement_enabled(true)
    if terrain_b and terrain_b.has_method("set_movement_enabled"):
        terrain_b.set_movement_enabled(true)
    if ground_a and ground_a.has_method("set_movement_enabled"):
        ground_a.set_movement_enabled(true)
    if ground_b and ground_b.has_method("set_movement_enabled"):
        ground_b.set_movement_enabled(true)
    var tgt: float = clamp(base_speed + distance * speed_gain_per_meter, base_speed, max_speed)
    if ground_a and ground_a.has_method("set_speed"):
        ground_a.set_speed(tgt)
    if ground_b and ground_b.has_method("set_speed"):
        ground_b.set_speed(tgt)
    var bgm := get_node_or_null("BGM")
    if bgm and bgm is AudioStreamPlayer and (bgm as AudioStreamPlayer).stream != null and not bgm_muted:
        (bgm as AudioStreamPlayer).play()
    if canvas:
        var gom := canvas.get_node_or_null("GameOverMenu")
        if gom:
            gom.visible = false

func set_bgm_volume(v: float) -> void:
    var bgm := get_node_or_null("BGM")
    if bgm and bgm is AudioStreamPlayer:
        var lin: float = clampf(v, 0.0, 1.0)
        var db: float = (-60.0 if lin <= 0.0 else 20.0 * log(lin) / log(10.0))
        (bgm as AudioStreamPlayer).volume_db = db

func set_sfx_volume(v: float) -> void:
    var sfx := get_node_or_null("SFXJump")
    if sfx and sfx is AudioStreamPlayer:
        var lin: float = clampf(v, 0.0, 1.0)
        var db: float = (-60.0 if lin <= 0.0 else 20.0 * log(lin) / log(10.0))
        (sfx as AudioStreamPlayer).volume_db = db

func set_bgm_muted(m: bool) -> void:
    bgm_muted = m
    var bgm := get_node_or_null("BGM")
    if bgm and bgm is AudioStreamPlayer:
        if m:
            (bgm as AudioStreamPlayer).stop()
        else:
            if (bgm as AudioStreamPlayer).stream != null:
                (bgm as AudioStreamPlayer).play()
    _save_progress()

func set_sfx_muted(m: bool) -> void:
    sfx_muted = m
    var sfx := get_node_or_null("SFXJump")
    if sfx and sfx is AudioStreamPlayer:
        (sfx as AudioStreamPlayer).volume_db = (-60.0 if m else (sfx as AudioStreamPlayer).volume_db)
    _save_progress()

func _set_pause_menu_visible(v: bool) -> void:
    if canvas:
        var pm := canvas.get_node_or_null("PauseMenu")
        if pm:
            pm.visible = v
            if v:
                _refresh_missions_label()

func activate_magnet(d: float) -> void:
    magnet_timer = max(magnet_timer, max(d, 0.0))
    magnet_enabled = true

func _apply_enemy_ramp_if_needed() -> void:
    return


func set_playing_phase() -> void:
    phase = Phase.PLAYING
    game_active = true
    _apply_spawn_safety_limits()
    if ground_a and ground_a.has_method("set_speed_limits"):
        ground_a.set_speed_limits(0.0, max_speed)
    if ground_b and ground_b.has_method("set_speed_limits"):
        ground_b.set_speed_limits(0.0, max_speed)
    if parallax and parallax.has_method("set_movement_enabled"):
        parallax.set_movement_enabled(true)
    if terrain and terrain.has_method("set_movement_enabled"):
        terrain.set_movement_enabled(true)
    if terrain_b and terrain_b.has_method("set_movement_enabled"):
        terrain_b.set_movement_enabled(true)
    if ground_a and ground_a.has_method("set_movement_enabled"):
        ground_a.set_movement_enabled(true)
        if ground_a.has_method("set_speed"):
            ground_a.set_speed(base_speed)
    if ground_b and ground_b.has_method("set_movement_enabled"):
        ground_b.set_movement_enabled(true)
        if ground_b.has_method("set_speed"):
            ground_b.set_speed(base_speed)
    if player:
        if player.has_method("prepare_for_playing_phase"):
            player.prepare_for_playing_phase()
        if player.has_method("enable_environment_movement"):
            player.enable_environment_movement(true)

    var bgm2 := get_node_or_null("BGM")
    if bgm2 and bgm2 is AudioStreamPlayer and (bgm2 as AudioStreamPlayer).stream != null:
        (bgm2 as AudioStreamPlayer).play()
    if anomaly:
        if anomaly.has_method("start_appear"):
            anomaly.start_appear()
        anomaly.show()
    if canvas:
        var pm2 := canvas.get_node_or_null("PauseMenu")
        if pm2:
            pm2.visible = false
        var gom2 := canvas.get_node_or_null("GameOverMenu")
        if gom2:
            gom2.visible = false


func on_player_entry_finished() -> void:
    if phase != Phase.ENTRY:
        return
    entry_finished = true
    if not countdown_active:
        set_playing_phase()

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
    if ground_a and ground_a.has_method("set_speed"):
        ground_a.set_speed(0.0)
    if ground_b and ground_b.has_method("set_speed"):
        ground_b.set_speed(0.0)
    if parallax and parallax.has_method("set_speed"):
        parallax.call("set_speed", 0.0)

    last_score = score
    last_coins = coin_collected_a + coin_collected_b
    total_coins += last_coins
    if missions_manager and missions_manager.has_method("update_distance"):
        missions_manager.update_distance(distance)
    if missions_manager and missions_manager.has_method("add_coins") and last_coins > 0:
        missions_manager.add_coins(last_coins)
    if score > best_score:
        best_score = score
    _save_progress()
    var bgm3 := get_node_or_null("BGM")
    if bgm3 and bgm3 is AudioStreamPlayer:
        (bgm3 as AudioStreamPlayer).stop()
    if anomaly:
        anomaly.hide()
    if debug_label != null:
        debug_label.visible = true
        debug_label.text = "GAME OVER\nScore: " + str(score) + "\nDistance: " + str(int(round(distance)))
    if canvas:
        var gom := canvas.get_node_or_null("GameOverMenu")
        if gom:
            gom.visible = true

func restart_game() -> void:
    _start_play_phase()

func get_game_state() -> Dictionary:
    return {
        "phase": phase,
        "game_active": game_active,
        "score": score,
        "distance": distance,
        "best_score": best_score
    }

func _verify_player_scenes() -> void:
    if _scene_verify_running:
        return
    _scene_verify_running = true
    if not OS.is_debug_build():
        _scene_verify_running = false
        return
    _scene_verify_start_ms = Time.get_ticks_msec()
    print("SceneVerify: START")
    if perf_log_to_file:
        _append_perf_log("SceneVerify: START")
    var dir: DirAccess = DirAccess.open("res://scenes")
    if dir == null:
        return
    dir.list_dir_begin()
    var file: String = dir.get_next()
    var report: Array[String] = []
    while file != "":
        await get_tree().process_frame
        var found: Array = []
        var status: String = "-"
        if not dir.current_is_dir() and file.ends_with(".tscn"):
            var p: String = "res://scenes/" + file
            var sc: Resource = ResourceLoader.load(p)
            if sc and sc is PackedScene:
                var inst: Node = (sc as PackedScene).instantiate()
                var q: Array = []
                q.append(inst)
                var steps: int = 0
                while q.size() > 0:
                    var n: Node = q.pop_back() as Node
                    if n:
                        for c in n.get_children():
                            q.append(c)
                        if n.name == "Player" or (player and n.get_class() == player.get_class()):
                            found.append(n)
                    steps += 1
                    if steps % 100 == 0:
                        await get_tree().process_frame
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
                inst.free()
            else:
                status = "LOAD_FAIL"
        var line: String = file + " Players:" + str(found.size()) + " " + status
        report.append(line)
        file = dir.get_next()
    dir.list_dir_end()
    if report.size() > 0:
        print("SceneCheck:\n" + "\n".join(report))
    _scene_verify_running = false
    var dur := Time.get_ticks_msec() - _scene_verify_start_ms
    print("SceneVerify: END duration_ms=" + str(dur))
    if perf_log_to_file:
        _append_perf_log("SceneVerify: END duration_ms=" + str(dur))

func _load_progress() -> void:
    var cfg := ConfigFile.new()
    var err := cfg.load("user://save.cfg")
    if err == OK:
        best_score = int(cfg.get_value("progress", "best_score", 0))
        last_score = int(cfg.get_value("progress", "last_score", 0))
        last_coins = int(cfg.get_value("progress", "last_coins", 0))
        total_coins = int(cfg.get_value("progress", "total_coins", 0))

        bgm_muted = bool(cfg.get_value("settings", "bgm_muted", false))
        sfx_muted = bool(cfg.get_value("settings", "sfx_muted", false))

func _save_progress() -> void:
    var cfg := ConfigFile.new()
    var err := cfg.load("user://save.cfg")
    if err != OK:
        cfg = ConfigFile.new()
    cfg.set_value("progress", "best_score", best_score)
    cfg.set_value("progress", "last_score", last_score)
    cfg.set_value("progress", "last_coins", last_coins)
    cfg.set_value("progress", "total_coins", total_coins)
    cfg.set_value("settings", "bgm_muted", bgm_muted)
    cfg.set_value("settings", "sfx_muted", sfx_muted)
    cfg.save("user://save.cfg")



func _is_touch_over_button(btn: TouchScreenButton, pos: Vector2) -> bool:
    if not btn:
        return false
    var local: Vector2 = btn.to_local(pos)
    var tex := btn.texture_normal
    if tex == null:
        return false
    var size: Vector2 = tex.get_size()
    var rect := Rect2(Vector2.ZERO, size)
    return rect.has_point(local)

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventAction:
        var ia := event as InputEventAction
        if ia.pressed:
            if ia.action == "jump":
                if player and player.has_method("request_jump"):
                    player.request_jump()
                return
            if ia.action == "attack":
                if player and player.has_method("request_attack"):
                    player.request_attack()
                return
    if event is InputEventMouseButton and event.pressed:
        var mb := event as InputEventMouseButton
        if _is_touch_over_button(_jump_button, mb.position):
            if player and player.has_method("request_jump"):
                player.request_jump()
            return
        if _is_touch_over_button(_attack_button, mb.position):
            if player and player.has_method("request_attack"):
                player.request_attack()
            return
    if event is InputEventScreenTouch:
        var st := event as InputEventScreenTouch
        if st.pressed:
            if _is_touch_over_button(_jump_button, st.position):
                if player and player.has_method("request_jump"):
                    player.request_jump()
                return
            if _is_touch_over_button(_attack_button, st.position):
                if player and player.has_method("request_attack"):
                    player.request_attack()
                return
    if event is InputEventKey and event.pressed and not event.echo:
        if OS.is_debug_build() and (Input.is_action_just_pressed("toggle_debug") or event.keycode == KEY_F3):
            debug_info_enabled = not debug_info_enabled
            if debug_label != null:
                debug_label.visible = debug_info_enabled
            return
        if OS.is_debug_build() and (Input.is_action_just_pressed("verify_scenes") or event.keycode == KEY_F6):
            call_deferred("_verify_player_scenes")
        elif Input.is_action_pressed("ui_cancel"):
            if game_active:
                pause_game()
            else:
                resume_game()

func on_coin_collected(segment: String) -> void:
    if segment == "A":
        coin_collected_a += 1
    else:
        coin_collected_b += 1
    if missions_manager and missions_manager.has_method("add_coins"):
        missions_manager.add_coins(1)

func set_player_health(current: int, maximum: int) -> void:
    if health_bar == null:
        return
    health_bar.max_value = float(maximum)
    var clamped: float = clamp(float(current), 0.0, float(maximum))
    health_bar.value = clamped
func _start_play_phase() -> void:
    if not is_inside_tree():
        return
    phase = Phase.ENTRY
    game_active = false
    distance = 0.0
    score = 0
    coin_collected_a = 0
    coin_collected_b = 0
    game_time_sec = 0.0
    _tiles_passed_accum = 0.0
    total_tiles_passed = 0
    countdown_active = true
    countdown_timer = countdown_duration_sec
    entry_finished = false
    if player and player.has_method("reset_player"):
        player.reset_player()
    _next_coin_burst_distance = 300
    _apply_spawn_safety_limits()
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
    var bgm2 := get_node_or_null("BGM")
    if bgm2 and bgm2 is AudioStreamPlayer:
        (bgm2 as AudioStreamPlayer).stop()
    if anomaly:
        anomaly.hide()
    if player:
        if player.has_method("enable_environment_movement"):
            player.enable_environment_movement(false)
        if player.has_method("start_entry_sequence"):
            player.start_entry_sequence()

func _append_perf_log(_line: String) -> void:
    pass


@onready var missions_manager: Node = get_node_or_null("MissionsManager")
var _next_coin_burst_distance: int = 300
func _apply_spawn_safety_limits() -> void:
    var layers: Array = []
    if _ga_layer != null:
        layers.append(_ga_layer)
    if _gb_layer != null:
        layers.append(_gb_layer)
    for tl in layers:
        if tl != null:
            tl.set("coin_max_children", 40)
            tl.set("coin_spawn_batch_limit", 4)
            tl.set("enemy_max_children", 24)
            tl.set("enemy_spawn_batch_limit", 4)
            tl.set("spawn_update_interval_sec", 0.7)
            tl.set("spawn_min_fps", 45)
func _refresh_missions_label() -> void:
    if not canvas:
        return
    var label := canvas.get_node_or_null("PauseMenu/VBox/MissionsLabel")
    if label and missions_manager and missions_manager.has_method("get_missions_text"):
        var txt: String = missions_manager.get_missions_text()
        (label as Label).text = "Misi:\n" + txt

func _trigger_coin_burst() -> void:
    var layers: Array = []
    if _ga_layer != null:
        layers.append(_ga_layer)
    if _gb_layer != null:
        layers.append(_gb_layer)
    for tl in layers:
        if tl != null and tl.has_method("spawn_bonus_coins"):
            tl.spawn_bonus_coins(2)
