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

@export var debug_info_enabled: bool = true
@export var base_speed: float = 150.0
@export var max_speed: float = 300.0
@export var speed_gain_per_meter: float = 0.02
@export var score_per_meter: float = 0.1

@onready var player: Player = $Player
@onready var anomaly: Node2D = get_node_or_null("AnomalyChaser")
@onready var terrain = get_node_or_null("Terrain")
@onready var terrain_b = get_node_or_null("TerrainB")
@onready var ground_a: Node2D = get_node_or_null("Ground")
@onready var ground_b: Node2D = get_node_or_null("TerrainB/Ground")
@onready var parallax = $ParallaxBackground
@onready var canvas = $CanvasLayer
var debug_label: Label

func _ready() -> void:
    if player:
        player.connect("game_over_signal", Callable(self, "on_player_game_over"))
    if not InputMap.has_action("toggle_debug"):
        InputMap.add_action("toggle_debug")
        var ev := InputEventKey.new()
        ev.physical_keycode = KEY_F3
        InputMap.action_add_event("toggle_debug", ev)
    _load_progress()
    set_playing_phase()
    _verify_player_scenes()
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

func _process(delta: float) -> void:
    if phase == Phase.PLAYING:
        var env_speed: float = base_speed
        if ground_a and ground_a.has_method("get_speed"):
            env_speed = float(ground_a.call("get_speed"))
        distance += env_speed * delta
        score = int(distance * score_per_meter)
        var target_speed: float = clamp(base_speed + distance * speed_gain_per_meter, base_speed, max_speed)
        if ground_a and ground_a.has_method("set_speed"):
            ground_a.set_speed(target_speed)
        if ground_b and ground_b.has_method("set_speed"):
            ground_b.set_speed(target_speed)
        if player and player.has_method("set_run_anim_factor"):
            var anim_factor: float = max(0.1, target_speed / max(base_speed, 0.1))
            player.call("set_run_anim_factor", anim_factor)
    if debug_label != null:
        debug_label.visible = debug_info_enabled
        if debug_info_enabled:
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
            lines.append("CamCenter X/Y: " + str(cam_x) + "/" + str(cam_y) + " | FPS: " + str(fps))
            debug_label.text = "\n".join(lines)

func on_quit_game() -> void:
    get_tree().quit()

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
    if event is InputEventKey and event.pressed and not event.echo:
        if Input.is_action_just_pressed("toggle_debug") or event.keycode == KEY_F3:
            debug_info_enabled = not debug_info_enabled
        elif Input.is_action_pressed("ui_cancel"):
            if game_active:
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
            else:
                set_playing_phase()

func on_coin_collected(segment: String) -> void:
    if segment == "A":
        coin_collected_a += 1
    else:
        coin_collected_b += 1
func _input(event) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if Input.is_action_just_pressed("toggle_debug") or event.keycode == KEY_F3:
            debug_info_enabled = not debug_info_enabled
