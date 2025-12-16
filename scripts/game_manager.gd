extends Node2D

enum Phase { PLAYING, GAME_OVER }
var phase: Phase = Phase.PLAYING
var game_active: bool = false
var score: int = 0
var distance: float = 0.0
var best_score: int = 0
var coin_collected_a: int = 0
var coin_collected_b: int = 0
var last_score: int = 0
var last_coins: int = 0
var total_coins: int = 0

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
@export var perf_log_to_file: bool = true
@export var tutorial_enabled: bool = true
@export var super_easy_mode: bool = false
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
var _debug_t_accum: float = 0.0
var _ga_layer: Node = null
var _gb_layer: Node = null
var _scene_verify_running: bool = false
var _watchdog_low_fps_accum: float = 0.0
var _watchdog_print_accum: float = 0.0
var _scene_verify_start_ms: int = 0
var tutorial_shown: bool = false
var bgm_muted: bool = false
var sfx_muted: bool = false
var magnet_timer: float = 0.0
@export var ads_enabled: bool = true
@export var ads_max_per_session: int = 2
@export var rewarded_continue_grace_sec: float = 5.0
var ads_shown_count: int = 0
var continue_grace_timer: float = 0.0
@onready var coin_hud_label: Label = $CanvasLayer/CoinHUD/Label
@export var enemy_ramp_start_distance: float = 400.0
var _enemy_ramp_applied: bool = false

func _ready() -> void:
    if player:
        player.connect("game_over_signal", Callable(self, "on_player_game_over"))
    if not InputMap.has_action("toggle_debug"):
        InputMap.add_action("toggle_debug")
        var ev := InputEventKey.new()
        ev.physical_keycode = KEY_F3
        InputMap.action_add_event("toggle_debug", ev)
    if not InputMap.has_action("verify_scenes"):
        InputMap.add_action("verify_scenes")
        var ev2 := InputEventKey.new()
        ev2.physical_keycode = KEY_F6
        InputMap.action_add_event("verify_scenes", ev2)
    _load_progress()
    call_deferred("_start_play_phase")
    if scene_verify_on_start and OS.is_debug_build():
        call_deferred("_verify_player_scenes")
    if canvas and debug_label == null:
        var dl := Label.new()
        dl.name = "DebugInfoLabel"
        dl.visible = debug_info_enabled
        dl.z_index = 999
        dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
        dl.vertical_alignment = VERTICAL_ALIGNMENT_TOP
        dl.add_theme_font_size_override("font_size", 14)
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
        _ga_layer = ground_a.get_node_or_null("TileMapLayer")
    if ground_b != null:
        _gb_layer = ground_b.get_node_or_null("TileMapLayerB")

    _setup_tutorial_overlay()

func _process(delta: float) -> void:
    if phase == Phase.PLAYING:
        var env_speed: float = base_speed
        if ground_a and ground_a.has_method("get_speed"):
            env_speed = float(ground_a.call("get_speed"))
        distance += env_speed * delta
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
            if magnet_timer <= 0.0 and not super_easy_mode:
                magnet_enabled = false
        _apply_enemy_ramp_if_needed()
        if int(round(distance)) >= _next_coin_burst_distance:
            _trigger_coin_burst()
            _next_coin_burst_distance += 300
    if continue_grace_timer > 0.0:
        continue_grace_timer = max(continue_grace_timer - delta, 0.0)
        if player:
            player.enable_fall_death = false
    else:
        if player:
            player.enable_fall_death = true
    if debug_label != null:
        debug_label.visible = debug_info_enabled
        if debug_info_enabled:
            _debug_t_accum += delta
            if _debug_t_accum < debug_update_interval_sec:
                return
            _debug_t_accum = 0.0
            var cur_speed: float = base_speed
            if ground_a and ground_a.has_method("get_speed"):
                cur_speed = float(ground_a.call("get_speed"))
            var tgt_speed: float = clamp(base_speed + distance * speed_gain_per_meter, base_speed, max_speed)
            var fps := int(round(Engine.get_frames_per_second()))
            var phase_name := ("PLAYING" if phase == Phase.PLAYING else "GAME_OVER")
            var ppos := Vector2.ZERO
            var pvel := Vector2.ZERO
            var grounded := false
            var pstate := "-"
            if player:
                ppos = player.global_position
                pvel = player.velocity
                grounded = player.is_on_floor()
                pstate = ("PLAYING" if player.current_state == player.PlayerState.FULL_MOVEMENT else "GAME_OVER")
            var ground_tiles_run: int = 0
            var ground_tiles_lr: String = "-"
            if player:
                var active := _ga_layer
                if _ga_layer != null and _gb_layer != null:
                    var cell_a: Vector2i = _ga_layer.tile_set.tile_size if _ga_layer.tile_set != null else Vector2i(128, 128)
                    var seg_a: float = float(_ga_layer.width) * float(cell_a.x) * _ga_layer.scale.x
                    var cell_b: Vector2i = _gb_layer.tile_set.tile_size if _gb_layer.tile_set != null else Vector2i(128, 128)
                    var seg_b: float = float(_gb_layer.width) * float(cell_b.x) * _gb_layer.scale.x
                    var px: float = player.global_position.x
                    var in_a: bool = (px >= _ga_layer.position.x) and (px <= _ga_layer.position.x + seg_a)
                    var in_b: bool = (px >= _gb_layer.position.x) and (px <= _gb_layer.position.x + seg_b)
                    if in_b and not in_a:
                        active = _gb_layer
                if active != null:
                    if active.has_method("get_platform_run_len_at_world_x"):
                        ground_tiles_run = int(active.call("get_platform_run_len_at_world_x", player.global_position.x))
                    if active.has_method("get_platform_runs_lr_at_world_x"):
                        var lr: Vector2i = active.call("get_platform_runs_lr_at_world_x", player.global_position.x)
                        ground_tiles_lr = str(lr.x) + "/" + str(lr.y)
            var env_move := false
            if ground_a and ground_a.has_method("get"):
                env_move = bool(ground_a.get("movement_enabled"))
            var cam := get_viewport().get_camera_2d()
            var cam_x := 0
            var cam_y := 0
            if cam != null:
                var cc := cam.get_screen_center_position()
                cam_x = int(round(cc.x))
                cam_y = int(round(cc.y))
            var lines := []
            lines.append("Phase: " + phase_name + " | GameActive: " + str(game_active))
            lines.append("EnvSpeed: " + str(int(round(cur_speed))) + " / Target: " + str(int(round(tgt_speed))) + " | Base/Max: " + str(int(base_speed)) + "/" + str(int(max_speed)))
            lines.append("Distance: " + str(int(round(distance))) + " | Score: " + str(score))
            lines.append("Coins A/B: " + str(coin_collected_a) + "/" + str(coin_collected_b) + " | Last: " + str(last_coins) + " | Best: " + str(best_score))
            lines.append("Player X/Y: " + str(int(round(ppos.x))) + "/" + str(int(round(ppos.y))) + " | Vel X/Y: " + str(int(round(pvel.x))) + "/" + str(int(round(pvel.y))))
            lines.append("Grounded: " + str(grounded) + " | State: " + pstate + " | EnvMove: " + str(env_move))
            lines.append("Ground Tiles Run: " + str(ground_tiles_run) + " | L/R: " + ground_tiles_lr)
            lines.append("CamCenter X/Y: " + str(cam_x) + "/" + str(cam_y) + " | FPS: " + str(fps))
            debug_label.text = "\n".join(lines)
            if OS.is_debug_build():
                if fps < watchdog_fps_threshold:
                    _watchdog_low_fps_accum += debug_update_interval_sec
                    _watchdog_print_accum += debug_update_interval_sec
                    if _watchdog_low_fps_accum >= watchdog_hang_seconds and _watchdog_print_accum >= watchdog_print_interval_sec:
                        _watchdog_print_accum = 0.0
                        var msg := "Watchdog: LowFPS " + str(fps) + " for " + ("%0.2f" % _watchdog_low_fps_accum) + "s | phase:" + phase_name + " | active:" + str(game_active) + " | scene_verify:" + str(_scene_verify_running) + " | dist:" + str(int(round(distance))) + " | speed:" + str(int(round(cur_speed)))
                        push_warning(msg)
                        print(msg)
                        if perf_log_to_file:
                            _append_perf_log(msg)
                else:
                    _watchdog_low_fps_accum = 0.0

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
    if Engine.has_singleton("TransitionManager"):
        await TransitionManager.fade_to_scene("res://scenes/MainMenu.tscn", 0.4)
    else:
        get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

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

func _set_tutorial_visible(v: bool) -> void:
    if not tutorial_enabled:
        return
    if canvas:
        var to := canvas.get_node_or_null("TutorialOverlay")
        if to:
            to.visible = v

func _setup_tutorial_overlay() -> void:
    if tutorial_enabled and not tutorial_shown:
        _set_tutorial_visible(true)

func on_tutorial_dismiss() -> void:
    tutorial_shown = true
    _set_tutorial_visible(false)
    _save_progress()

func activate_magnet(d: float) -> void:
    magnet_timer = max(magnet_timer, max(d, 0.0))
    magnet_enabled = true

func _apply_enemy_ramp_if_needed() -> void:
    if _enemy_ramp_applied:
        return
    if distance < enemy_ramp_start_distance:
        return
    var layers: Array = []
    if _ga_layer != null:
        layers.append(_ga_layer)
    if _gb_layer != null:
        layers.append(_gb_layer)
    for tl in layers:
        if tl != null:
            tl.set("enemy_spawn_enabled", true)
            tl.set("enemy_groups_min", 1)
            tl.set("enemy_groups_max", 1)
            tl.set("enemy_spacing_tiles_min", 14)
            tl.set("enemy_spacing_tiles_max", 18)
            tl.set("enemy_min_platform_tiles", 10)
            tl.set("enemy_min_right_run_tiles", 6)
            tl.set("enemy_min_left_run_tiles", 6)
    _enemy_ramp_applied = true

func set_playing_phase() -> void:
    phase = Phase.PLAYING
    game_active = true
    distance = 0.0
    score = 0
    coin_collected_a = 0
    coin_collected_b = 0
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
        if player.lock_x_during_full_movement and player.enable_entry_stop:
            player.global_position = Vector2(player.entry_stop_x, player.global_position.y)
            player.position = Vector2(player.entry_stop_x, player.position.y)

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
    set_playing_phase()

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

        tutorial_shown = bool(cfg.get_value("progress", "tutorial_shown", false))
        super_easy_mode = bool(cfg.get_value("progress", "super_easy_mode", false))
        bgm_muted = bool(cfg.get_value("settings", "bgm_muted", false))
        sfx_muted = bool(cfg.get_value("settings", "sfx_muted", false))

func _save_progress() -> void:
    var cfg := ConfigFile.new()
    cfg.set_value("progress", "best_score", best_score)
    cfg.set_value("progress", "last_score", last_score)
    cfg.set_value("progress", "last_coins", last_coins)
    cfg.set_value("progress", "total_coins", total_coins)
    cfg.set_value("progress", "tutorial_shown", tutorial_shown)
    cfg.set_value("progress", "super_easy_mode", super_easy_mode)
    cfg.set_value("settings", "bgm_muted", bgm_muted)
    cfg.set_value("settings", "sfx_muted", sfx_muted)
    cfg.save("user://save.cfg")

func _unhandled_input(event) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if Input.is_action_just_pressed("toggle_debug") or event.keycode == KEY_F3:
            debug_info_enabled = not debug_info_enabled
        elif Input.is_action_just_pressed("verify_scenes") or event.keycode == KEY_F6:
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
func _input(event) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if Input.is_action_just_pressed("toggle_debug") or event.keycode == KEY_F3:
            debug_info_enabled = not debug_info_enabled
func _start_play_phase() -> void:
    if not is_inside_tree():
        return
    set_playing_phase()

func _append_perf_log(line: String) -> void:
    var f := FileAccess.open("user://perf.log", FileAccess.READ_WRITE)
    if f:
        f.seek(f.get_length())
        f.store_string(line + "\n")


@onready var missions_manager: Node = get_node_or_null("MissionsManager")
var _next_coin_burst_distance: int = 300
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
