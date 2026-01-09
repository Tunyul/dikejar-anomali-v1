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
var player_level: int = 1
var player_xp: int = 0
var player_xp_required: int = 100
var game_time_sec: float = 0.0
var total_tiles_passed: int = 0
var _tiles_passed_accum: float = 0.0
var _debug_time_accum: float = 0.0
var powerups_data: Dictionary = {}

@export var debug_info_enabled: bool = false
@export var base_speed: float = 180.0
@export var max_speed: float = 360.0
@export var speed_gain_per_meter: float = 0.015
@export var score_per_meter: float = 0.1
@export var score_per_tile: int = 1
@export var xp_per_meter: float = 0.02
@export var xp_per_coin: float = 0.2
@export var debug_update_interval_sec: float = 0.25
@export var scene_verify_on_start: bool = false
@export var watchdog_fps_threshold: int = 15
@export var watchdog_hang_seconds: float = 1.5
@export var watchdog_print_interval_sec: float = 2.0
@export var perf_log_to_file: bool = false
var magnet_enabled: bool = false
var shield_enabled: bool = false
var double_coins_run_active: bool = false
var double_coins_timer: float = 0.0
var speed_boost_timer: float = 0.0
var speed_boost_multiplier: float = 1.0


@onready var player: Player = $Player
@onready var anomaly: Node2D = get_node_or_null("AnomalyChaser")
@onready var terrain = get_node_or_null("Terrain")
@onready var terrain_b = get_node_or_null("TerrainB")
@onready var ground_a: Node2D = get_node_or_null("Ground")
@onready var ground_b: Node2D = get_node_or_null("TerrainB/Ground")
@onready var parallax = $ParallaxBackground
@onready var canvas = $CanvasLayer
var debug_label: Label
var spawn_status_label: Label
var speed_info_label: Label
var _jump_button: TouchScreenButton
var _attack_button: TouchScreenButton
var _ga_layer: Node = null
var _gb_layer: Node = null
var _scene_verify_running: bool = false
var _scene_verify_start_ms: int = 0
var bgm_muted: bool = false
var sfx_muted: bool = false
var magnet_timer: float = 0.0
var shield_timer: float = 0.0
var _last_health_current: int = -1
var _last_health_max: int = -1
@export var powerup_magnet_duration_sec: float = 10.0
@export var powerup_shield_duration_sec: float = 10.0
@export var powerup_double_coins_duration_sec: float = 10.0
@export var powerup_speed_boost_duration_sec: float = 5.0
@export var powerup_speed_boost_multiplier: float = 2.5
@export var ads_enabled: bool = true
@export var ads_max_per_session: int = 2
@export var rewarded_continue_grace_sec: float = 5.0
var ads_shown_count: int = 0
var continue_grace_timer: float = 0.0
@onready var coin_hud_label: Label = $CanvasLayer/CoinHUD/Label
@onready var score_hud_label: Label = $CanvasLayer/ScoreHUD/ScoreLabel
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
        dl.visible = false
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
    if canvas and spawn_status_label == null:
        var sl := Label.new()
        sl.name = "SpawnStatusLabel"
        sl.visible = false
        sl.z_index = 998
        sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
        sl.vertical_alignment = VERTICAL_ALIGNMENT_TOP
        sl.add_theme_font_size_override("font_size", 16)
        sl.add_theme_color_override("font_color", Color(1, 1, 1, 1))
        var sb2 := StyleBoxFlat.new()
        sb2.bg_color = Color(0, 0, 0, 0.4)
        sb2.corner_radius_top_left = 4
        sb2.corner_radius_top_right = 4
        sb2.corner_radius_bottom_left = 4
        sb2.corner_radius_bottom_right = 4
        sl.add_theme_stylebox_override("normal", sb2)
        sl.set_anchors_preset(Control.PRESET_TOP_LEFT)
        sl.offset_left = 8
        sl.offset_top = 120
        sl.mouse_filter = Control.MOUSE_FILTER_IGNORE
        canvas.add_child(sl)
        spawn_status_label = sl
    if canvas and speed_info_label == null:
        var sil := Label.new()
        sil.name = "SpeedInfoLabel"
        sil.visible = false
        sil.z_index = 998
        sil.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
        sil.vertical_alignment = VERTICAL_ALIGNMENT_TOP
        sil.add_theme_font_size_override("font_size", 16)
        sil.add_theme_color_override("font_color", Color(1, 1, 0, 1))
        var sb3 := StyleBoxFlat.new()
        sb3.bg_color = Color(0, 0, 0, 0.5)
        sb3.corner_radius_top_left = 4
        sb3.corner_radius_top_right = 4
        sb3.corner_radius_bottom_left = 4
        sb3.corner_radius_bottom_right = 4
        sil.add_theme_stylebox_override("normal", sb3)
        sil.set_anchors_preset(Control.PRESET_TOP_LEFT)
        sil.offset_left = 8
        sil.offset_top = 160
        sil.mouse_filter = Control.MOUSE_FILTER_IGNORE
        canvas.add_child(sil)
        speed_info_label = sil
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

    if canvas:
        var settings_button := canvas.get_node_or_null("SettingsButton") as BaseButton
        if settings_button and settings_button.has_signal("pressed"):
            settings_button.pressed.connect(_on_settings_button_pressed)

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
    if OS.is_debug_build() and debug_info_enabled:
        print(msg)
        if debug_label != null:
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

func _on_settings_button_pressed() -> void:
    _debug_input("INPUT: settings_button")
    pause_game()

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

    var magnet_was_enabled: bool = magnet_enabled
    var shield_was_enabled: bool = shield_enabled
    var double_was_active: bool = double_coins_run_active
    var speed_was_active: bool = speed_boost_timer > 0.0 and speed_boost_multiplier > 1.0

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
        score = int(total_tiles_passed * score_per_tile)
        if coin_hud_label != null:
            coin_hud_label.text = str(coin_collected_a + coin_collected_b)
        if score_hud_label != null:
            score_hud_label.text = str(score)
        if missions_manager and missions_manager.has_method("update_distance"):
            missions_manager.update_distance(distance)
        var target_speed: float = clamp(base_speed + distance * speed_gain_per_meter, base_speed, max_speed)
        var boost_active: bool = speed_boost_timer > 0.0 and speed_boost_multiplier > 1.0
        if boost_active:
            target_speed *= speed_boost_multiplier
        if ground_a and ground_a.has_method("set_speed"):
            ground_a.set_speed(target_speed)
        if ground_b and ground_b.has_method("set_speed"):
            ground_b.set_speed(target_speed)
        if parallax and parallax.has_method("set_speed"):
            parallax.set_speed(target_speed)
        if ground_a and ground_a.has_method("set_instant_speed_mode"):
            ground_a.set_instant_speed_mode(boost_active)
        if ground_b and ground_b.has_method("set_instant_speed_mode"):
            ground_b.set_instant_speed_mode(boost_active)
        if player:
            player.run_speed = target_speed
        if player and player.has_method("set_run_anim_factor"):
            var anim_factor: float = max(0.1, target_speed / max(base_speed, 0.1))
            player.call("set_run_anim_factor", anim_factor)
        _update_speed_info_label(env_speed, target_speed)
    if magnet_timer > 0.0:
        magnet_timer = max(magnet_timer - delta, 0.0)
        if magnet_timer <= 0.0:
            magnet_enabled = false
            if magnet_was_enabled:
                _ensure_skill_after_power_end("magnet")
    if shield_timer > 0.0:
        shield_timer = max(shield_timer - delta, 0.0)
        if shield_timer <= 0.0:
            shield_enabled = false
            if shield_was_enabled:
                _ensure_skill_after_power_end("shield")
    if double_coins_timer > 0.0:
        double_coins_timer = max(double_coins_timer - delta, 0.0)
        if double_coins_timer <= 0.0:
            if double_was_active:
                _ensure_skill_after_power_end("double_coins")
            double_coins_run_active = false
    _recycle_powerups_behind_player()
    _ensure_skills_ahead_of_player()
    _ensure_hearts_for_low_health()
    if speed_boost_timer > 0.0:
        speed_boost_timer = max(speed_boost_timer - delta, 0.0)
        if speed_boost_timer <= 0.0:
            speed_boost_multiplier = 1.0
            if speed_was_active and not is_speed_boost_active():
                _ensure_skill_after_power_end("speed_boost")
    if canvas:
        var magnet_icon := canvas.get_node_or_null("MagnetIcon") as TextureRect
        var magnet_label := canvas.get_node_or_null("MagnetTimerLabel") as Label
        if magnet_icon:
            magnet_icon.visible = magnet_enabled
        if magnet_label:
            magnet_label.visible = magnet_enabled
            if magnet_enabled:
                var sec_left: int = int(ceil(magnet_timer))
                magnet_label.text = str(max(sec_left, 0))
            else:
                magnet_label.text = ""
        var shield_icon := canvas.get_node_or_null("ShieldIcon") as TextureRect
        var shield_label := canvas.get_node_or_null("ShieldTimerLabel") as Label
        if shield_icon:
            shield_icon.visible = shield_enabled
        if shield_label:
            shield_label.visible = shield_enabled
            if shield_enabled:
                var shield_sec_left: int = int(ceil(shield_timer))
                shield_label.text = str(max(shield_sec_left, 0))
            else:
                shield_label.text = ""
        var double_icon := canvas.get_node_or_null("DoubleCoinsIcon") as TextureRect
        var double_label := canvas.get_node_or_null("DoubleCoinsTimerLabel") as Label
        if double_icon:
            double_icon.visible = double_coins_run_active
        if double_label:
            double_label.visible = double_coins_run_active
            if double_coins_run_active:
                var dsec_left: int = int(ceil(double_coins_timer))
                double_label.text = str(max(dsec_left, 0))
            else:
                double_label.text = ""
        var speed_icon := canvas.get_node_or_null("SpeedBoostIcon") as TextureRect
        var speed_label := canvas.get_node_or_null("SpeedBoostTimerLabel") as Label
        var speed_active: bool = speed_boost_timer > 0.0 and speed_boost_multiplier > 1.0
        if speed_icon:
            speed_icon.visible = speed_active
        if speed_label:
            speed_label.visible = speed_active
            if speed_active:
                var speed_sec_left: int = int(ceil(speed_boost_timer))
                speed_label.text = str(max(speed_sec_left, 0))
            else:
                speed_label.text = ""
        var heart_spawn_label := canvas.get_node_or_null("HeartSpawnLabel") as Label
        if heart_spawn_label:
            heart_spawn_label.visible = false
    _apply_enemy_ramp_if_needed()
    if OS.is_debug_build() and debug_info_enabled:
        _debug_time_accum += delta
        if _debug_time_accum >= debug_update_interval_sec:
            _debug_time_accum = 0.0
            _update_debug_label()
    _update_spawn_status_label()

func _update_speed_info_label(env_speed: float, target_speed: float) -> void:
    if speed_info_label == null:
        return
    if not debug_info_enabled:
        speed_info_label.visible = false
        return
    var boost_active: bool = is_speed_boost_active()
    speed_info_label.visible = boost_active
    if not boost_active:
        return
    var ground_speed: float = env_speed
    if ground_a and ground_a.has_method("get_speed"):
        ground_speed = float(ground_a.call("get_speed"))
    var parallax_speed: float = 0.0
    if parallax and parallax.has_method("get_layer_speed"):
        parallax_speed = float(parallax.call("get_layer_speed", 0))
    var player_speed: float = 0.0
    if player:
        player_speed = player.run_speed
    var txt: String = "BOOST SPEED\n"
    txt += "Env: " + str(int(env_speed)) + " | Target: " + str(int(target_speed)) + "\n"
    txt += "Ground: " + str(int(ground_speed)) + " | Parallax: " + str(int(parallax_speed)) + "\n"
    txt += "Player: " + str(int(player_speed)) + " x" + str(powerup_speed_boost_multiplier)
    speed_info_label.text = txt

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
    var nearest_heart_dist_px: float = _get_nearest_heart_distance_px()
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
    if nearest_heart_dist_px >= 0.0:
        txt += "\nHeartDistPx: " + str(int(nearest_heart_dist_px))
    txt += "\nCamCenter X/Y: " + str(int(cam_center.x)) + "/" + str(int(cam_center.y)) + " | FPS: " + str(fps)
    debug_label.visible = true
    debug_label.text = txt

func _update_spawn_status_label() -> void:
    if spawn_status_label == null:
        return
    if not debug_info_enabled:
        spawn_status_label.visible = false
        return
    if not ground_a or not ground_a.has_method("get_spawn_status"):
        spawn_status_label.text = "Spawn: -"
        return
    var st: Dictionary = ground_a.call("get_spawn_status")
    var coin_on: bool = bool(st.get("coins", false))
    var heart_on: bool = bool(st.get("hearts", false))
    var enemy_on: bool = bool(st.get("enemies", false))
    var magnet_on: bool = bool(st.get("magnet", false)) or magnet_enabled
    var shield_on: bool = bool(st.get("shield", false)) or shield_enabled
    var double_on: bool = bool(st.get("double_coins", false)) or double_coins_run_active
    var speed_on: bool = bool(st.get("speed_boost", false)) or (speed_boost_timer > 0.0 and speed_boost_multiplier > 1.0)
    var t: String = "Spawn: Coin " + ("Aktif" if coin_on else "Non")
    t += " | Heart " + ("Aktif" if heart_on else "Non")
    t += " | Enemy " + ("Aktif" if enemy_on else "Non")
    t += " | Magnet " + ("Aktif" if magnet_on else "Non")
    t += " | Shield " + ("Aktif" if shield_on else "Non")
    t += " | Double " + ("Aktif" if double_on else "Non")
    t += " | Speed " + ("Aktif" if speed_on else "Non")
    var dist_text: String = ""
    if player != null and ground_a.has_method("get_powerup_distances"):
        var pd: Dictionary = ground_a.call("get_powerup_distances", player.global_position.x)
        var dh: float = float(pd.get("heart", -1.0))
        var dm: float = float(pd.get("magnet", -1.0))
        var ds: float = float(pd.get("shield", -1.0))
        var dd: float = float(pd.get("double_coins", -1.0))
        var dv: float = float(pd.get("speed_boost", -1.0))
        var sh: String = (str(int(round(dh))) if dh >= 0.0 else "-")
        var sm: String = (str(int(round(dm))) if dm >= 0.0 else "-")
        var ss: String = (str(int(round(ds))) if ds >= 0.0 else "-")
        var sd: String = (str(int(round(dd))) if dd >= 0.0 else "-")
        var sv: String = (str(int(round(dv))) if dv >= 0.0 else "-")
        dist_text = "\nDistTile: H " + sh + " | M " + sm + " | S " + ss + " | D " + sd + " | Sp " + sv
        var heart_px: float = _get_nearest_heart_distance_px()
        if heart_px >= 0.0:
            var tile_w_px: float = 64.0
            if ground_a.has_method("get_tile_width_px"):
                tile_w_px = float(ground_a.call("get_tile_width_px"))
                if tile_w_px <= 0.0:
                    tile_w_px = 64.0
            var heart_tiles: float = heart_px
            if tile_w_px > 0.0:
                heart_tiles = heart_px / tile_w_px
            dist_text += "\nHeartTile: " + str(int(round(heart_tiles)))
    spawn_status_label.text = t + dist_text

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
    var dur: float = d
    if dur <= 0.0:
        dur = powerup_magnet_duration_sec
    magnet_timer = max(dur, 0.0)
    magnet_enabled = magnet_timer > 0.0
    shield_timer = 0.0
    shield_enabled = false
    speed_boost_timer = 0.0
    speed_boost_multiplier = 1.0
    double_coins_timer = 0.0
    double_coins_run_active = false

func activate_shield(d: float) -> void:
    var dur: float = d
    if dur <= 0.0:
        dur = powerup_shield_duration_sec
    shield_timer = max(dur, 0.0)
    shield_enabled = shield_timer > 0.0
    magnet_timer = 0.0
    magnet_enabled = false
    speed_boost_timer = 0.0
    speed_boost_multiplier = 1.0
    double_coins_timer = 0.0
    double_coins_run_active = false

func is_magnet_active() -> bool:
    return magnet_enabled

func is_shield_active() -> bool:
    return shield_enabled

func _has_any_heart_on_ground() -> bool:
    var d: float = _get_nearest_heart_distance_px()
    return d >= 0.0

func can_spawn_hearts() -> bool:
    if phase != Phase.PLAYING:
        return false
    if _last_health_max <= 0:
        return false
    return _last_health_current < _last_health_max

func _get_nearest_heart_distance_px() -> float:
    if player == null:
        return -1.0
    var p_pos: Vector2 = player.global_position
    var best: float = -1.0
    var grounds: Array = []
    if ground_a != null:
        grounds.append(ground_a)
    if ground_b != null:
        grounds.append(ground_b)
    for g in grounds:
        if g == null:
            continue
        for coins_root_name in ["CoinsA", "CoinsB"]:
            var root: Node = g.get_node_or_null(coins_root_name)
            if root == null:
                continue
            for c in root.get_children():
                if c is HeartPickup and c is Node2D:
                    var n2 := c as Node2D
                    if n2.global_position.x < p_pos.x:
                        continue
                    var d: float = p_pos.distance_to(n2.global_position)
                    if best < 0.0 or d < best:
                        best = d
    return best

func activate_speed_boost(d: float = 0.0, m: float = 0.0) -> void:
    var dur: float = d
    if dur <= 0.0:
        dur = powerup_speed_boost_duration_sec
    var mul: float = m
    if mul <= 0.0:
        mul = powerup_speed_boost_multiplier
    speed_boost_timer = max(dur, 0.0)
    speed_boost_multiplier = max(mul, 1.0)
    magnet_timer = 0.0
    magnet_enabled = false
    shield_timer = 0.0
    shield_enabled = false
    double_coins_timer = 0.0
    double_coins_run_active = false

func is_speed_boost_active() -> bool:
    return speed_boost_timer > 0.0 and speed_boost_multiplier > 1.0

func _clear_existing_magnets_and_shields() -> void:
    var grounds: Array = []
    if ground_a != null:
        grounds.append(ground_a)
    if ground_b != null:
        grounds.append(ground_b)
    for g in grounds:
        if g == null:
            continue
        for coins_root_name in ["CoinsA", "CoinsB"]:
            var root: Node = g.get_node_or_null(coins_root_name)
            if root == null:
                continue
            for c in root.get_children():
                if (c is MagnetPowerup) or (c is ShieldPowerup) or c.is_in_group("shield_powerup"):
                    c.queue_free()

func _clear_existing_speed_boosts() -> void:
    var grounds: Array = []
    if ground_a != null:
        grounds.append(ground_a)
    if ground_b != null:
        grounds.append(ground_b)
    for g in grounds:
        if g == null:
            continue
        for coins_root_name in ["CoinsA", "CoinsB"]:
            var root: Node = g.get_node_or_null(coins_root_name)
            if root == null:
                continue
            for c in root.get_children():
                if c is SpeedBoostPowerup:
                    c.queue_free()

func _clear_existing_hearts() -> void:
    var grounds: Array = []
    if ground_a != null:
        grounds.append(ground_a)
    if ground_b != null:
        grounds.append(ground_b)
    for g in grounds:
        if g == null:
            continue
        for coins_root_name in ["CoinsA", "CoinsB"]:
            var root: Node = g.get_node_or_null(coins_root_name)
            if root == null:
                continue
            for c in root.get_children():
                if c is HeartPickup:
                    c.queue_free()

func _recycle_powerups_behind_player() -> void:
    if phase != Phase.PLAYING:
        return
    if player == null:
        return
    var cam := get_viewport().get_camera_2d()
    var view_rect := get_viewport().get_visible_rect()
    var left_limit: float
    if cam != null:
        left_limit = cam.global_position.x - float(view_rect.size.x) * 0.5 - 64.0
    else:
        left_limit = player.global_position.x - float(view_rect.size.x) * 0.6
    var grounds: Array = []
    if ground_a != null:
        grounds.append(ground_a)
    if ground_b != null:
        grounds.append(ground_b)
    for g in grounds:
        if g == null:
            continue
        for coins_root_name in ["CoinsA", "CoinsB"]:
            var root: Node = g.get_node_or_null(coins_root_name)
            if root == null:
                continue
            for c in root.get_children():
                if c == null:
                    continue
                var is_powerup: bool = false
                if c is HeartPickup:
                    is_powerup = true
                elif c is MagnetPowerup:
                    is_powerup = true
                elif (c is ShieldPowerup) or c.is_in_group("shield_powerup"):
                    is_powerup = true
                elif c is DoubleCoinsPowerup:
                    is_powerup = true
                elif c is SpeedBoostPowerup:
                    is_powerup = true
                if not is_powerup:
                    continue
                if not (c is Node2D):
                    continue
                var n2 := c as Node2D
                if n2.global_position.x < left_limit:
                    n2.queue_free()

func _ensure_skills_ahead_of_player() -> void:
    if phase != Phase.PLAYING:
        return
    if player == null:
        return
    if ground_a == null:
        return
    var px: float = player.global_position.x
    var min_skill_dist_tiles: float = 70.0
    var max_skill_dist_tiles: float = 100.0
    var tile_w_px: float = 64.0
    if ground_a.has_method("get_tile_width_px"):
        tile_w_px = float(ground_a.call("get_tile_width_px"))
        if tile_w_px <= 0.0:
            tile_w_px = 64.0
    var min_skill_dist_px: float = min_skill_dist_tiles * tile_w_px
    var max_skill_dist_px: float = max_skill_dist_tiles * tile_w_px
    var any_skill_ahead: bool = false
    if ground_a.has_method("get_powerup_distances"):
        var pd: Dictionary = ground_a.call("get_powerup_distances", px)
        for key in ["magnet", "shield", "double_coins", "speed_boost"]:
            var d: float = float(pd.get(key, -1.0))
            if d >= 0.0:
                any_skill_ahead = true
                break
    if any_skill_ahead:
        return
    _spawn_random_skill_ahead(px, min_skill_dist_px, max_skill_dist_px)

func _ensure_hearts_for_low_health() -> void:
    if phase != Phase.PLAYING:
        return
    if player == null:
        return
    if ground_a == null:
        return
    if _last_health_max <= 0:
        return
    if _last_health_current >= _last_health_max:
        return
    if _has_any_heart_on_ground():
        return
    if not ground_a.has_method("request_emergency_heart"):
        return
    var px: float = player.global_position.x
    var cam := get_viewport().get_camera_2d()
    var view_rect := get_viewport().get_visible_rect()
    if cam != null:
        px = cam.global_position.x + float(view_rect.size.x) * 0.5
    var min_heart_dist_px: float = 500.0
    var max_heart_dist_px: float = 700.0
    ground_a.call("request_emergency_heart", px, min_heart_dist_px, max_heart_dist_px)

func _ensure_skill_after_power_end(_kind: String) -> void:
    if phase != Phase.PLAYING:
        return
    if player == null:
        return
    if ground_a == null:
        return
    var px: float = player.global_position.x
    var min_skill_dist_tiles: float = 70.0
    var max_skill_dist_tiles: float = 100.0
    var tile_w_px: float = 64.0
    if ground_a.has_method("get_tile_width_px"):
        tile_w_px = float(ground_a.call("get_tile_width_px"))
        if tile_w_px <= 0.0:
            tile_w_px = 64.0
    var min_skill_dist_px: float = min_skill_dist_tiles * tile_w_px
    var max_skill_dist_px: float = max_skill_dist_tiles * tile_w_px
    _spawn_random_skill_ahead(px, min_skill_dist_px, max_skill_dist_px)

func _spawn_random_skill_ahead(px: float, min_skill_dist_px: float, max_skill_dist_px: float) -> void:
    if ground_a == null:
        return
    var candidates: Array[String] = []
    if ground_a.has_method("request_emergency_magnet"):
        candidates.append("magnet")
    if ground_a.has_method("request_emergency_shield"):
        candidates.append("shield")
    if ground_a.has_method("request_emergency_double_coins"):
        candidates.append("double_coins")
    if ground_a.has_method("request_emergency_speed_boost"):
        candidates.append("speed_boost")
    if candidates.is_empty():
        return
    var rng := RandomNumberGenerator.new()
    rng.randomize()
    var idx: int = rng.randi_range(0, candidates.size() - 1)
    var kind: String = candidates[idx]
    match kind:
        "magnet":
            ground_a.call("request_emergency_magnet", px, min_skill_dist_px, max_skill_dist_px)
        "shield":
            ground_a.call("request_emergency_shield", px, min_skill_dist_px, max_skill_dist_px)
        "double_coins":
            ground_a.call("request_emergency_double_coins", px, min_skill_dist_px, max_skill_dist_px)
        "speed_boost":
            ground_a.call("request_emergency_speed_boost", px, min_skill_dist_px, max_skill_dist_px)

func _on_player_health_decreased(_current: int, _maximum: int) -> void:
    call_deferred("_ensure_hearts_for_low_health")

func _apply_enemy_ramp_if_needed() -> void:
    return


func set_playing_phase() -> void:
    phase = Phase.PLAYING
    game_active = true
    _apply_spawn_safety_limits()
    if ground_a and ground_a.has_method("set_speed_limits"):
        var max_with_boost: float = max_speed
        if powerup_speed_boost_multiplier > 1.0:
            max_with_boost = max_speed * powerup_speed_boost_multiplier
        ground_a.set_speed_limits(0.0, max_with_boost)
    if ground_b and ground_b.has_method("set_speed_limits"):
        var max_with_boost_b: float = max_speed
        if powerup_speed_boost_multiplier > 1.0:
            max_with_boost_b = max_speed * powerup_speed_boost_multiplier
        ground_b.set_speed_limits(0.0, max_with_boost_b)
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
    var xp_gain_from_distance: int = int(distance * xp_per_meter)
    var xp_gain_from_coins: int = int(float(last_coins) * xp_per_coin)
    var xp_gain: int = xp_gain_from_distance + xp_gain_from_coins
    if xp_gain > 0:
        _apply_xp_gain(xp_gain)
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
        debug_label.visible = false
    if canvas:
        var gom := canvas.get_node_or_null("GameOverMenu")
        if gom and gom.has_method("show_game_over"):
            gom.show_game_over(score, distance)

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
        player_level = int(cfg.get_value("progress", "player_level", 1))
        player_xp = int(cfg.get_value("progress", "player_xp", 0))
        player_xp_required = int(cfg.get_value("progress", "player_xp_required", 100))
        if player_xp_required <= 0:
            player_xp_required = _calculate_xp_required(player_level)
        bgm_muted = bool(cfg.get_value("settings", "bgm_muted", false))
        sfx_muted = bool(cfg.get_value("settings", "sfx_muted", false))
        var bgm_volume: float = float(cfg.get_value("settings", "bgm_volume", 0.8))
        var sfx_volume: float = float(cfg.get_value("settings", "sfx_volume", 0.8))
        set_bgm_volume(bgm_volume)
        set_sfx_volume(sfx_volume)
        if bgm_muted:
            set_bgm_muted(true)
        if sfx_muted:
            set_sfx_muted(true)
        var pd = cfg.get_value("powerups", "data", {})
        if pd is Dictionary:
            powerups_data = pd
        else:
            powerups_data = {}

func _save_progress() -> void:
    var cfg := ConfigFile.new()
    var err := cfg.load("user://save.cfg")
    if err != OK:
        cfg = ConfigFile.new()
    cfg.set_value("progress", "best_score", best_score)
    cfg.set_value("progress", "last_score", last_score)
    cfg.set_value("progress", "last_coins", last_coins)
    cfg.set_value("progress", "total_coins", total_coins)
    cfg.set_value("progress", "player_level", player_level)
    cfg.set_value("progress", "player_xp", player_xp)
    cfg.set_value("progress", "player_xp_required", player_xp_required)
    cfg.set_value("settings", "bgm_muted", bgm_muted)
    cfg.set_value("settings", "sfx_muted", sfx_muted)
    cfg.set_value("powerups", "data", powerups_data)
    var ver = ProjectSettings.get_setting("application/config/version")
    if ver != null:
        cfg.set_value("meta", "version", String(ver))
    cfg.save("user://save.cfg")


func _calculate_xp_required(level: int) -> int:
    var base_xp := 100
    var step := 25
    if level <= 1:
        return base_xp
    return base_xp + (level - 1) * step


func _apply_xp_gain(amount: int) -> void:
    if amount <= 0:
        return
    player_xp += amount
    if player_level <= 0:
        player_level = 1
    if player_xp_required <= 0:
        player_xp_required = _calculate_xp_required(player_level)
    while player_xp >= player_xp_required:
        player_xp -= player_xp_required
        player_level += 1
        player_xp_required = _calculate_xp_required(player_level)



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
    var gain: int = 1
    if double_coins_run_active:
        gain = 2
    if segment == "A":
        coin_collected_a += gain
    else:
        coin_collected_b += gain
    if missions_manager and missions_manager.has_method("add_coins"):
        missions_manager.add_coins(gain)

func activate_double_coins_run(d: float = 0.0) -> void:
    var dur: float = d
    if dur <= 0.0:
        dur = powerup_double_coins_duration_sec
    double_coins_timer = max(dur, 0.0)
    double_coins_run_active = double_coins_timer > 0.0
    magnet_timer = 0.0
    magnet_enabled = false
    shield_timer = 0.0
    shield_enabled = false
    speed_boost_timer = 0.0
    speed_boost_multiplier = 1.0

func is_double_coins_active() -> bool:
    return double_coins_run_active

func _clear_existing_double_coins() -> void:
    var grounds: Array = []
    if ground_a != null:
        grounds.append(ground_a)
    if ground_b != null:
        grounds.append(ground_b)
    for g in grounds:
        if g == null:
            continue
        for coins_root_name in ["CoinsA", "CoinsB"]:
            var root: Node = g.get_node_or_null(coins_root_name)
            if root == null:
                continue
            for c in root.get_children():
                if c is DoubleCoinsPowerup:
                    c.queue_free()

func set_player_health(current: int, maximum: int) -> void:
    var prev_current: int = _last_health_current
    if health_bar == null:
        return
    health_bar.max_value = float(maximum)
    var clamped: float = clamp(float(current), 0.0, float(maximum))
    var new_current: int = int(clamped)
    health_bar.value = clamped
    _last_health_current = new_current
    _last_health_max = maximum
    if prev_current >= 0 and new_current != prev_current:
        _on_player_health_decreased(new_current, maximum)
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
    magnet_enabled = false
    magnet_timer = 0.0
    shield_enabled = false
    shield_timer = 0.0
    double_coins_run_active = false
    double_coins_timer = 0.0
    double_coins_run_active = false
    _last_health_current = -1
    _last_health_max = -1
    countdown_active = true
    countdown_timer = countdown_duration_sec
    entry_finished = false
    if player and player.has_method("reset_player"):
        player.reset_player()
    _clear_existing_hearts()
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
