extends Node2D

enum Phase { ENTRY, PLAYING, GAME_OVER }
var phase: Phase = Phase.ENTRY
var game_active: bool = false
var score: int = 0
var distance: float = 0.0
var best_score: int = 0
var coin_collected_a: int = 0
var coin_collected_b: int = 0
var gem_collected_a: int = 0
var gem_collected_b: int = 0
var last_score: int = 0
var last_coins: int = 0
var last_gems: int = 0
var total_coins: int = 0
var total_gems: int = 0
var player_level: int = 1
var player_xp: int = 0
var player_xp_required: int = 100
var game_time_sec: float = 0.0
var total_tiles_passed: int = 0
var _tiles_passed_accum: float = 0.0
var _debug_time_accum: float = 0.0
var _score_offset: int = 0
var powerups_data: Dictionary = {}
var pending_level_rewards: Array = []
var max_heart_bonus: int = 0
var magnet_duration_multiplier: float = 1.0
var shield_duration_multiplier: float = 1.0
var pickup_range_bonus: float = 0.0
var double_coins_duration_multiplier: float = 1.0
var double_coins_gain_multiplier: float = 2.0
var speed_boost_duration_multiplier: float = 1.0
var speed_boost_multiplier_multiplier: float = 1.0
var shield_hit_charges_run: int = 0
var _base_powerup_magnet_duration_sec: float = -1.0
var _base_powerup_shield_duration_sec: float = -1.0
var _base_powerup_double_coins_duration_sec: float = -1.0
var _base_powerup_speed_boost_duration_sec: float = -1.0
var _base_powerup_speed_boost_multiplier: float = -1.0
var _base_player_max_health: int = -1

const _SPEED_BOOST_PRE_RUN_DURATION_SEC: float = 15.0
const _SPEED_BOOST_PRE_RUN_MULTIPLIER: float = 1.5

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
@onready var ground_a: Node2D = get_node_or_null("Ground")
@onready var parallax = $ParallaxBackground
@onready var canvas = $CanvasLayer
var debug_label: Label
var spawn_status_label: Label
var speed_info_label: Label
var _jump_button: TouchScreenButton
var _attack_button: TouchScreenButton
var _jump_button_tint: Panel
var _attack_button_tint: Panel
var _last_viewport_size: Vector2i = Vector2i(-1, -1)
var _last_safe_area: Rect2i = Rect2i()
var _ga_layer: Node = null
var _gb_layer: Node = null
var _scene_verify_running: bool = false
var _scene_verify_start_ms: int = 0
var bgm_muted: bool = false
var sfx_muted: bool = false
const _BUKIT_BGM_DIR := "res://assets/audio/bgm/bukit"
const _BUKIT_BGM_PREFIX := "bgm-bukit-"
const _GAMEOVER_BGM_DIR := "res://assets/audio/bgm/gameover"
const _GAMEOVER_BGM_PREFIX := "bgm-gameover-"
var _bukit_bgm_paths: Array[String] = []
var _bukit_bgm_index: int = 0
var _bukit_bgm_initialized: bool = false
var _gameover_bgm_paths: Array[String] = []
var _gameover_bgm_index: int = 0
var _gameover_bgm_initialized: bool = false
enum BgmMode { RUN, GAME_OVER }
var _bgm_mode: BgmMode = BgmMode.RUN
var _bgm_user_volume: float = 0.8
var _bgm_base_db: float = 0.0
var _bgm_duck_db: float = 0.0
var _sfx_user_volume: float = 0.8
const _RUN_BGM_OFFSET_DB: float = -2.0
var _bgm_duck_tween: Tween = null
var _bgm_fade_tween: Tween = null
var magnet_timer: float = 0.0
var shield_timer: float = 0.0
var _last_health_current: int = -1
var _last_health_max: int = -1
@export var powerup_magnet_duration_sec: float = 30.0
@export var powerup_shield_duration_sec: float = 10.0
@export var powerup_double_coins_duration_sec: float = 10.0
@export var powerup_speed_boost_duration_sec: float = 5.0
@export var powerup_speed_boost_multiplier: float = 2.5
@export var ads_enabled: bool = true
@export var ads_max_per_session: int = 2
@export var rewarded_continue_grace_sec: float = 5.0
var ads_shown_count: int = 0
var continue_grace_timer: float = 0.0
var _carry_over_stats: Dictionary = {}
@onready var coin_hud_label: Label = $CanvasLayer/CoinHUD/Label
@onready var gem_hud_label: Label = $CanvasLayer/GemHUD/Label
@onready var score_hud_label: Label = $CanvasLayer/ScoreHUD/ScoreLabel
@onready var health_bar: ProgressBar = $CanvasLayer/HealthBar
@onready var missions_toast: Control = $CanvasLayer/MissionsToast
@onready var missions_toast_text: Label = $CanvasLayer/MissionsToast/Text
@onready var bgm_toast: Control = $CanvasLayer/BGMToast
@onready var bgm_toast_text: Label = $CanvasLayer/BGMToast/Text
@onready var version_label: Label = $CanvasLayer/VersionLabel
@onready var settings_button: Control = $CanvasLayer/SettingsButton
@onready var health_icon: Node2D = $CanvasLayer/HealthIcon
@onready var heart_spawn_label: Label = $CanvasLayer/HeartSpawnLabel
@onready var coin_hud: Control = $CanvasLayer/CoinHUD
@onready var coin_icon_anim: Node2D = $CanvasLayer/CoinIconAnim
@onready var score_hud: Control = $CanvasLayer/ScoreHUD
@onready var gem_hud: Control = $CanvasLayer/GemHUD
@onready var magnet_icon: TextureRect = $CanvasLayer/MagnetIcon
@onready var magnet_timer_label: Label = $CanvasLayer/MagnetTimerLabel
@onready var shield_icon: TextureRect = $CanvasLayer/ShieldIcon
@onready var shield_timer_label: Label = $CanvasLayer/ShieldTimerLabel
@onready var double_coins_icon: TextureRect = $CanvasLayer/DoubleCoinsIcon
@onready var double_coins_timer_label: Label = $CanvasLayer/DoubleCoinsTimerLabel
@onready var speed_boost_icon: TextureRect = $CanvasLayer/SpeedBoostIcon
@onready var speed_boost_timer_label: Label = $CanvasLayer/SpeedBoostTimerLabel
@export var enemy_ramp_start_distance: float = 400.0
@export var enemy_ramp_enabled: bool = true
@export var countdown_duration_sec: float = 3.0

var countdown_active: bool = false
var countdown_timer: float = 0.0
var entry_finished: bool = false

var _missions_toast_shown: bool = false
var _missions_toast_queue: Array[String] = []
var _suppress_ready_to_claim_toast: bool = false
var _missions_completed_type_toasted: Dictionary = {}
var _missions_toast_tween: Tween = null
var _bgm_toast_tween: Tween = null
var _missions_menu_opened_from_playing: bool = false
var _missions_menu_was_paused: bool = false
var _settings_menu_opened_from_playing: bool = false
var _settings_menu_was_paused: bool = false

func _ready() -> void:
    AdManager.move_banner(true) # Banner di atas untuk ingame
    if missions_manager and missions_manager.has_signal("ready_to_claim_changed"):
        var cb := Callable(self, "_on_missions_ready_to_claim_changed")
        if not missions_manager.is_connected("ready_to_claim_changed", cb):
            missions_manager.connect("ready_to_claim_changed", cb)
    if missions_manager and missions_manager.has_signal("mission_became_ready"):
        var cb2 := Callable(self, "_on_mission_became_ready")
        if not missions_manager.is_connected("mission_became_ready", cb2):
            missions_manager.connect("mission_became_ready", cb2)
    process_mode = Node.PROCESS_MODE_ALWAYS
    if _base_powerup_magnet_duration_sec < 0.0:
        _base_powerup_magnet_duration_sec = powerup_magnet_duration_sec
    if _base_powerup_shield_duration_sec < 0.0:
        _base_powerup_shield_duration_sec = powerup_shield_duration_sec
    if _base_powerup_double_coins_duration_sec < 0.0:
        _base_powerup_double_coins_duration_sec = powerup_double_coins_duration_sec
    if _base_powerup_speed_boost_duration_sec < 0.0:
        _base_powerup_speed_boost_duration_sec = powerup_speed_boost_duration_sec
    if _base_powerup_speed_boost_multiplier < 0.0:
        _base_powerup_speed_boost_multiplier = powerup_speed_boost_multiplier
    if _base_player_max_health < 0 and player:
        _base_player_max_health = int(player.max_health)
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

    var ui_font := load("res://assets/font/Fredoka Nunito/Nunito/static/Nunito-Regular.ttf") as Font
    var title_font := load("res://assets/font/Fredoka Nunito/Fredoka/static/Fredoka-Bold.ttf") as Font
    if ui_font and canvas:
        _apply_ui_font(canvas, ui_font)
    if title_font:
        _apply_shop_number_font(coin_hud_label, title_font)
        _apply_shop_number_font(gem_hud_label, title_font)
        _apply_shop_number_font(score_hud_label, title_font)
        _apply_shop_number_font(magnet_timer_label, title_font)
        _apply_shop_number_font(shield_timer_label, title_font)
        _apply_shop_number_font(double_coins_timer_label, title_font)
        _apply_shop_number_font(speed_boost_timer_label, title_font)

    _init_bukit_bgm()
    _init_gameover_bgm()
    _start_bukit_bgm_rotation()
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
        var gom := canvas.get_node_or_null("GameOverMenu")
        if gom:
            gom.visible = false
    if ground_a != null:
        _ga_layer = ground_a.get_node_or_null("TileMapLayerA")
        if _gb_layer == null:
            _gb_layer = ground_a.get_node_or_null("TileMapLayerB")

    _connect_mobile_buttons()
    _connect_viewport_resize()

    if canvas:
        var settings_btn := canvas.get_node_or_null("SettingsButton") as BaseButton
        if settings_btn and settings_btn.has_signal("pressed"):
            settings_btn.pressed.connect(_on_settings_button_pressed)
        if missions_toast:
            missions_toast.mouse_filter = Control.MOUSE_FILTER_STOP
            var cb3 := Callable(self, "_on_missions_toast_gui_input")
            if not missions_toast.gui_input.is_connected(cb3):
                missions_toast.gui_input.connect(cb3)

    if missions_manager and missions_manager.has_signal("ready_to_claim_changed"):
        var cb := Callable(self, "_on_ready_to_claim_changed")
        if not missions_manager.is_connected("ready_to_claim_changed", cb):
            missions_manager.connect("ready_to_claim_changed", cb)

    if missions_manager and missions_manager.has_signal("mission_became_ready"):
        var cb2 := Callable(self, "_on_mission_became_ready")
        if not missions_manager.is_connected("mission_became_ready", cb2):
            missions_manager.connect("mission_became_ready", cb2)


func _apply_ui_font(node: Node, font: Font) -> void:
    if node is Label:
        (node as Label).add_theme_font_override("font", font)
    elif node is BaseButton:
        (node as BaseButton).add_theme_font_override("font", font)
    for child in node.get_children():
        if child is Node:
            _apply_ui_font(child, font)


func _apply_shop_number_font(lbl: Label, title_font: Font) -> void:
    if lbl == null:
        return
    if title_font:
        lbl.add_theme_font_override("font", title_font)
    lbl.add_theme_constant_override("outline_size", 3)
    lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))


func _on_ready_to_claim_changed(can_claim: bool) -> void:
    if not can_claim:
        return
    if _suppress_ready_to_claim_toast:
        _suppress_ready_to_claim_toast = false
        return
    _enqueue_missions_toast(tr("Mission reward ready! Click toast / press M."))


func _on_mission_became_ready(_mission_id: String, mission_name: String) -> void:
    _suppress_ready_to_claim_toast = true
    var mission_title := mission_name.strip_edges()

    # Persingkat teks: Langsung nama misi jika tersedia, jika tidak pakai generic message
    if mission_title.is_empty():
        _enqueue_missions_toast(tr("Reward Ready!"))
        return

    # Lokalisasi nama misi (menggunakan sistem template {n} yang baru saja diperbaiki)
    # Pastikan mission_title adalah key yang valid di TransitionManager
    var localized_title := tr(mission_title)

    # Jika tr() mengembalikan string yang sama dan bukan bahasa Indonesia,
    # mungkin ini adalah string dinamis yang sudah diformat (misal "Kumpulkan 10 koin").
    # Kita coba deteksi dan bersihkan agar bisa diterjemahkan.
    var locale := TranslationServer.get_locale()
    if localized_title == mission_title and (locale.begins_with("en") or locale.begins_with("zh")):
        if mission_title.begins_with("Kumpulkan") and mission_title.ends_with("koin"):
            var n = mission_title.split(" ")[1]
            localized_title = tr("Collect {n} coins").replace("{n}", n)
        elif mission_title.begins_with("Kalahkan") and mission_title.ends_with("musuh"):
            var n = mission_title.split(" ")[1]
            localized_title = tr("Defeat {n} enemies").replace("{n}", n)
        elif mission_title.begins_with("Lompat") and mission_title.ends_with("kali"):
            var n = mission_title.split(" ")[1]
            localized_title = tr("Jump {n} times").replace("{n}", n)
        elif mission_title.begins_with("Dapatkan") and mission_title.ends_with("skill"):
            var n = mission_title.split(" ")[1]
            localized_title = tr("Get {n} skills").replace("{n}", n)
        elif mission_title.begins_with("Capai jarak") and mission_title.ends_with("m"):
            var n = mission_title.split(" ")[2]
            localized_title = tr("Reach {n}m distance").replace("{n}", n)

    # Namun untuk toast, kita cukup tampilkan "Selesai: [Nama Misi]"
    _enqueue_missions_toast(tr("Done: %s") % localized_title)
    var mt: String = ""
    if missions_manager and missions_manager.has_method("get_mission_type"):
        mt = String(missions_manager.call("get_mission_type", _mission_id))
    if mt.is_empty():
        return
    if _missions_completed_type_toasted.has(mt) and bool(_missions_completed_type_toasted[mt]):
        return
    if missions_manager and missions_manager.has_method("is_type_fully_completed"):
        var all_done: bool = bool(missions_manager.call("is_type_fully_completed", mt))
        if all_done:
            _missions_completed_type_toasted[mt] = true
            var title: String = mt
            if missions_manager.has_method("get_type_title"):
                title = String(missions_manager.call("get_type_title", mt))
            _enqueue_missions_toast(tr("%s completed!") % tr(title))


func _enqueue_missions_toast(msg: String) -> void:
    if _missions_toast_shown:
        _missions_toast_queue.append(msg)
        return
    _show_missions_toast(msg)


func _show_missions_toast(msg: String) -> void:
    if _missions_toast_shown:
        return
    _missions_toast_shown = true
    if missions_toast == null:
        return

    # Atur teks dan sesuaikan ukuran label
    if missions_toast_text:
        missions_toast_text.text = msg
        missions_toast_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        missions_toast_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        # Pastikan label mengisi panel dengan margin
        missions_toast_text.anchor_left = 0.0
        missions_toast_text.anchor_right = 1.0
        missions_toast_text.anchor_top = 0.0
        missions_toast_text.anchor_bottom = 1.0
        missions_toast_text.offset_left = 12 # Space for gold border
        missions_toast_text.offset_right = -8
        missions_toast_text.offset_top = 4
        missions_toast_text.offset_bottom = -4

    # Styling mobile-friendly (Compact & Clean)
    if missions_toast is Panel:
        var sb := StyleBoxFlat.new()
        sb.bg_color = Color(0, 0, 0, 0.8) # Slightly darker for premium feel
        sb.set_corner_radius_all(8) # Smaller radius for compact look
        sb.border_width_left = 4 # Thicker gold border
        sb.border_color = Color(1, 0.84, 0, 1)
        missions_toast.add_theme_stylebox_override("panel", sb)

    # Dynamic Width Calculation (Optional but helpful)
    # Kita asumsikan font size sekitar 16-18px. Kita batasi lebar agar tidak meluap.
    var text_size = 0
    if missions_toast_text and missions_toast_text.get_theme_font("font"):
        text_size = missions_toast_text.get_theme_font("font").get_string_size(msg, HORIZONTAL_ALIGNMENT_CENTER, -1, missions_toast_text.get_theme_font_size("font_size")).x

    var final_width = clampf(text_size + 40.0, 180.0, 320.0)
    missions_toast.offset_left = -final_width - 10.0 # Posisi dari kanan

    missions_toast.visible = true
    missions_toast.modulate = Color(1, 1, 1, 0)
    missions_toast.scale = Vector2(0.9, 0.9)
    missions_toast.pivot_offset = Vector2(final_width, 22) # Center right pivot

    if _missions_toast_tween != null:
        _missions_toast_tween.kill()
        _missions_toast_tween = null

    var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    _missions_toast_tween = tween
    tween.tween_property(missions_toast, "modulate:a", 1.0, 0.3)
    tween.tween_property(missions_toast, "scale", Vector2.ONE, 0.3)

    # Wait and then hide
    var hide_tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
    hide_tween.tween_interval(3.0) # Longer display time
    hide_tween.tween_property(missions_toast, "modulate:a", 0.0, 0.3)
    hide_tween.finished.connect(func():
        if missions_toast:
            missions_toast.visible = false
        _missions_toast_tween = null
        _missions_toast_shown = false
        if _missions_toast_queue.size() > 0:
            var next_msg: String = _missions_toast_queue.pop_front()
            call_deferred("_show_missions_toast", next_msg)
    )

func _on_missions_toast_gui_input(event: InputEvent) -> void:
    if missions_toast == null or not missions_toast.visible:
        return
    var pressed := false
    if event is InputEventMouseButton:
        var mb := event as InputEventMouseButton
        pressed = mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT
    elif event is InputEventScreenTouch:
        var st := event as InputEventScreenTouch
        pressed = st.pressed
    if not pressed:
        return
    if _missions_toast_tween != null:
        _missions_toast_tween.kill()
        _missions_toast_tween = null
    missions_toast.visible = false
    _missions_toast_shown = false
    if _missions_toast_queue.size() > 0:
        var next_msg: String = _missions_toast_queue.pop_front()
        call_deferred("_show_missions_toast", next_msg)
    open_missions_menu()


func _init_bukit_bgm() -> void:
    if _bukit_bgm_initialized:
        return
    var bgm := get_node_or_null("BGM") as AudioStreamPlayer
    if bgm == null:
        bgm = AudioStreamPlayer.new()
        bgm.name = "BGM"
        add_child(bgm)
    _bukit_bgm_paths = _load_bukit_bgm_paths()
    if _bukit_bgm_paths.is_empty():
        push_warning("[GameManager] No Bukit BGM files found in " + _BUKIT_BGM_DIR)
        return
    var cb := Callable(self, "_on_bukit_bgm_finished")
    if not bgm.finished.is_connected(cb):
        bgm.finished.connect(cb)
    _bukit_bgm_initialized = true


func _init_gameover_bgm() -> void:
    if _gameover_bgm_initialized:
        return
    var bgm := get_node_or_null("BGM") as AudioStreamPlayer
    if bgm == null:
        bgm = AudioStreamPlayer.new()
        bgm.name = "BGM"
        add_child(bgm)
    _gameover_bgm_paths = _load_gameover_bgm_paths()
    if _gameover_bgm_paths.is_empty():
        push_warning("[GameManager] No GameOver BGM files found in " + _GAMEOVER_BGM_DIR)
        return
    var cb := Callable(self, "_on_gameover_bgm_finished")
    if not bgm.finished.is_connected(cb):
        bgm.finished.connect(cb)
    _gameover_bgm_initialized = true


func _load_gameover_bgm_paths() -> Array[String]:
    var out: Array[String] = []
    var dir := DirAccess.open(_GAMEOVER_BGM_DIR)
    if dir == null:
        return out
    var files := dir.get_files()
    for f in files:
        var fs := String(f)
        var lower := fs.to_lower()
        var actual_file := lower
        if actual_file.ends_with(".remap"):
            actual_file = actual_file.trim_suffix(".remap")
        elif actual_file.ends_with(".import"):
            actual_file = actual_file.trim_suffix(".import")

        if not actual_file.ends_with(".mp3"):
            continue

        var clean_fs := fs
        if fs.to_lower().ends_with(".remap"):
            clean_fs = fs.left(-6)
        elif fs.to_lower().ends_with(".import"):
            clean_fs = fs.left(-7)

        if not clean_fs.begins_with(_GAMEOVER_BGM_PREFIX):
            continue

        var full_path := _GAMEOVER_BGM_DIR + "/" + clean_fs
        if not out.has(full_path):
            out.append(full_path)
    out.sort()
    return out


func _consume_next_gameover_bgm_index(size: int) -> int:
    if size <= 0:
        return 0
    var cfg := ConfigFile.new()
    var err := cfg.load("user://save.cfg")
    if err != OK:
        cfg = ConfigFile.new()
    var last := int(cfg.get_value("settings", "gameover_bgm_index", -1))
    var next := (last + 1) % size
    cfg.set_value("settings", "gameover_bgm_index", next)
    cfg.save("user://save.cfg")
    return next


func _save_gameover_bgm_index(i: int) -> void:
    var cfg := ConfigFile.new()
    var err := cfg.load("user://save.cfg")
    if err != OK:
        cfg = ConfigFile.new()
    cfg.set_value("settings", "gameover_bgm_index", i)
    cfg.save("user://save.cfg")


func _pick_gameover_bgm_path() -> String:
    _init_gameover_bgm()
    if _gameover_bgm_paths.is_empty():
        return ""
    if _gameover_bgm_index < 0 or _gameover_bgm_index >= _gameover_bgm_paths.size():
        _gameover_bgm_index = _consume_next_gameover_bgm_index(_gameover_bgm_paths.size())
    return _gameover_bgm_paths[_gameover_bgm_index]


func _on_gameover_bgm_finished() -> void:
    if phase != Phase.GAME_OVER:
        return
    if bgm_muted:
        return
    if _gameover_bgm_paths.is_empty():
        return
    _gameover_bgm_index = (_gameover_bgm_index + 1) % _gameover_bgm_paths.size()
    _save_gameover_bgm_index(_gameover_bgm_index)
    _play_game_over_bgm()


func _load_bukit_bgm_paths() -> Array[String]:
    var out: Array[String] = []
    var dir := DirAccess.open(_BUKIT_BGM_DIR)
    if dir == null:
        return out
    var files := dir.get_files()
    for f in files:
        var fs := String(f)
        var lower := fs.to_lower()
        var actual_file := lower
        if actual_file.ends_with(".remap"):
            actual_file = actual_file.trim_suffix(".remap")
        elif actual_file.ends_with(".import"):
            actual_file = actual_file.trim_suffix(".import")

        if not actual_file.ends_with(".mp3"):
            continue

        var clean_fs := fs
        if fs.to_lower().ends_with(".remap"):
            clean_fs = fs.left(-6)
        elif fs.to_lower().ends_with(".import"):
            clean_fs = fs.left(-7)

        if not clean_fs.begins_with(_BUKIT_BGM_PREFIX):
            continue

        var full_path := _BUKIT_BGM_DIR + "/" + clean_fs
        if not out.has(full_path):
            out.append(full_path)
    out.sort()
    return out


func _consume_next_bukit_bgm_index(size: int) -> int:
    if size <= 0:
        return 0
    var cfg := ConfigFile.new()
    var err := cfg.load("user://save.cfg")
    if err != OK:
        cfg = ConfigFile.new()
    var last := int(cfg.get_value("settings", "bukit_bgm_index", -1))
    var next := (last + 1) % size
    cfg.set_value("settings", "bukit_bgm_index", next)
    cfg.save("user://save.cfg")
    return next


func _save_bukit_bgm_index(i: int) -> void:
    var cfg := ConfigFile.new()
    var err := cfg.load("user://save.cfg")
    if err != OK:
        cfg = ConfigFile.new()
    cfg.set_value("settings", "bukit_bgm_index", i)
    cfg.save("user://save.cfg")


func _play_bukit_bgm_index(i: int) -> void:
    var bgm := get_node_or_null("BGM") as AudioStreamPlayer
    if bgm == null:
        return
    if _bukit_bgm_paths.is_empty():
        return
    _bukit_bgm_index = clampi(i, 0, _bukit_bgm_paths.size() - 1)
    var path := _bukit_bgm_paths[_bukit_bgm_index]
    var stream := load(path) as AudioStream
    if stream == null:
        return
    bgm.stream = stream
    _apply_bgm_mix()
    if not bgm_muted:
        bgm.play()
        _show_bgm_toast(_format_track_name(path))


func _start_bukit_bgm_rotation() -> void:
    _init_bukit_bgm()
    if _bukit_bgm_paths.is_empty():
        return
    _bukit_bgm_index = _consume_next_bukit_bgm_index(_bukit_bgm_paths.size())
    _play_bukit_bgm_index(_bukit_bgm_index)


func _on_bukit_bgm_finished() -> void:
    if phase != Phase.PLAYING:
        return
    if bgm_muted:
        return
    if _bukit_bgm_paths.is_empty():
        return
    _bukit_bgm_index = (_bukit_bgm_index + 1) % _bukit_bgm_paths.size()
    _save_bukit_bgm_index(_bukit_bgm_index)
    _play_bukit_bgm_index(_bukit_bgm_index)


func _show_bgm_toast(title: String) -> void:
    if bgm_toast == null:
        return
    if bgm_toast_text:
        bgm_toast_text.text = "BGM: " + title
    bgm_toast.visible = true
    bgm_toast.modulate = Color(1, 1, 1, 0)
    if _bgm_toast_tween != null:
        _bgm_toast_tween.kill()
        _bgm_toast_tween = null
    var tween := create_tween()
    _bgm_toast_tween = tween
    tween.tween_property(bgm_toast, "modulate:a", 1.0, 0.18)
    tween.tween_interval(2.2)
    tween.tween_property(bgm_toast, "modulate:a", 0.0, 0.22)
    tween.finished.connect(func():
        if bgm_toast:
            bgm_toast.visible = false
        _bgm_toast_tween = null
    )


func _format_track_name(path: String) -> String:
    var base := path.get_file().get_basename()
    base = base.replace("_", " ")
    base = base.replace("-", " ")
    base = base.strip_edges()
    return base


func _connect_mobile_buttons() -> void:
    if not canvas:
        return

    var mc = canvas.get_node_or_null("MobileControls")
    if not mc:
        return

    _jump_button = mc.get_node_or_null("JumpButton") as TouchScreenButton
    if _jump_button:
        if not _jump_button.pressed.is_connected(_on_jump_button_pressed):
            _jump_button.pressed.connect(_on_jump_button_pressed)

    _attack_button = mc.get_node_or_null("AttackButton") as TouchScreenButton
    if _attack_button:
        if not _attack_button.pressed.is_connected(_on_attack_button_pressed):
            _attack_button.pressed.connect(_on_attack_button_pressed)

    # _ensure_mobile_button_tints() # Removed tints as per user request
    _update_mobile_controls_layout(true)


func _ensure_mobile_button_tints() -> void:
    return # Disable button tints
    if canvas == null:
        return
    var mc := canvas.get_node_or_null("MobileControls") as Control
    if mc == null:
        return
    if _jump_button_tint == null:
        _jump_button_tint = Panel.new()
        _jump_button_tint.name = "JumpButtonTint"
        _jump_button_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _jump_button_tint.z_index = 0
        mc.add_child(_jump_button_tint)
    if _attack_button_tint == null:
        _attack_button_tint = Panel.new()
        _attack_button_tint.name = "AttackButtonTint"
        _attack_button_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _attack_button_tint.z_index = 0
        mc.add_child(_attack_button_tint)
    _update_mobile_button_tints()


func _update_mobile_button_tints() -> void:
    if _jump_button == null or _attack_button == null:
        return
    if _jump_button_tint == null or _attack_button_tint == null:
        return
    var jt := _jump_button.texture_normal
    var at := _attack_button.texture_normal
    if jt == null or at == null:
        return
    var js: Vector2 = jt.get_size()
    var asz: Vector2 = at.get_size()

    _jump_button_tint.size = js
    _jump_button_tint.position = _jump_button.position
    _jump_button_tint.visible = _jump_button.visible
    var sj := StyleBoxFlat.new()
    sj.bg_color = Color(0.2, 0.8, 1.0, 0.14)
    sj.border_width_left = 2
    sj.border_width_top = 2
    sj.border_width_right = 2
    sj.border_width_bottom = 2
    sj.border_color = Color(0.2, 0.8, 1.0, 0.35)
    var rj: int = int(round(minf(js.x, js.y) * 0.5))
    sj.corner_radius_top_left = rj
    sj.corner_radius_top_right = rj
    sj.corner_radius_bottom_left = rj
    sj.corner_radius_bottom_right = rj
    _jump_button_tint.add_theme_stylebox_override("panel", sj)

    _attack_button_tint.size = asz
    _attack_button_tint.position = _attack_button.position
    _attack_button_tint.visible = _attack_button.visible
    var sa := StyleBoxFlat.new()
    sa.bg_color = Color(1.0, 0.72, 0.25, 0.14)
    sa.border_width_left = 2
    sa.border_width_top = 2
    sa.border_width_right = 2
    sa.border_width_bottom = 2
    sa.border_color = Color(1.0, 0.72, 0.25, 0.35)
    var ra: int = int(round(minf(asz.x, asz.y) * 0.5))
    sa.corner_radius_top_left = ra
    sa.corner_radius_top_right = ra
    sa.corner_radius_bottom_left = ra
    sa.corner_radius_bottom_right = ra
    _attack_button_tint.add_theme_stylebox_override("panel", sa)


func _connect_viewport_resize() -> void:
    var vp := get_viewport()
    if vp == null:
        return
    var cb := Callable(self, "_on_viewport_size_changed")
    if not vp.size_changed.is_connected(cb):
        vp.size_changed.connect(cb)
    call_deferred("_on_viewport_size_changed")


func _on_viewport_size_changed() -> void:
    _update_mobile_controls_layout(false)


func _compute_safe_area_rect() -> Rect2:
    var vp_rect := get_viewport().get_visible_rect()
    var out := vp_rect

    if OS.has_feature("android") or OS.has_feature("ios"):
        var sa := DisplayServer.get_display_safe_area()
        var window_size := DisplayServer.window_get_size()

        if sa.size.x > 0 and sa.size.y > 0 and window_size.x > 0 and window_size.y > 0:
            # Hitung rasio antara screen pixels dan viewport units
            var scale_factor := Vector2(
                vp_rect.size.x / float(window_size.x),
                vp_rect.size.y / float(window_size.y)
            )

            # Skala Safe Area ke koordinat viewport
            out.position = Vector2(sa.position) * scale_factor
            out.size = Vector2(sa.size) * scale_factor

            print("[GameManager] Safe Area Scaled: ", out, " Scale Factor: ", scale_factor)

    return out


func _update_mobile_controls_layout(force: bool) -> void:
    var vp := get_viewport().get_visible_rect().size

    # Abaikan jika ukuran viewport tidak valid (biasanya frame pertama di mobile)
    if vp.x < 100 or vp.y < 100:
        return

    var vp_i := Vector2i(int(vp.x), int(vp.y))
    var sa_i := Rect2i()
    if OS.has_feature("android") or OS.has_feature("ios"):
        sa_i = DisplayServer.get_display_safe_area()
    if not force and vp_i == _last_viewport_size and sa_i == _last_safe_area:
        return
    _last_viewport_size = vp_i
    _last_safe_area = sa_i

    var safe := _compute_safe_area_rect()
    _update_safe_ui_layout(safe, vp)

    if _jump_button != null and _attack_button != null:
        # Config Layout Baru (Lebih naik & ke tengah)
        var margin_right: float = 80.0
        var margin_bottom: float = 60.0
        var spacing: float = 32.0

        var jt := _jump_button.texture_normal
        var at := _attack_button.texture_normal

        # Fallback size jika tekstur belum dimuat
        var js := jt.get_size() if jt != null else Vector2(96, 96)
        var asz := at.get_size() if at != null else Vector2(96, 96)

        # Perbesar tombol (Scale Up)
        var button_scale: float = 1.3
        _jump_button.scale = Vector2(button_scale, button_scale)
        _attack_button.scale = Vector2(button_scale, button_scale)

        # Transparansi agar tidak menghalangi pandangan (50% Opacity)
        _jump_button.modulate.a = 0.5
        _attack_button.modulate.a = 0.5

        # Hitung ukuran efektif setelah di-scale
        var js_scaled := js * button_scale
        var asz_scaled := asz * button_scale

        # Log posisi untuk debugging
        # Jump Button: Posisi acuan (Kanan Atas dari cluster tombol)
        var jump_pos := Vector2(
            safe.position.x + safe.size.x - margin_right - js_scaled.x,
            safe.position.y + safe.size.y - margin_bottom - js_scaled.y
        )

        # Attack Button: Sebelah kiri Jump, sedikit turun (formasi arc natural jempol)
        var attack_y_offset: float = 40.0
        var attack_pos := Vector2(
            jump_pos.x - spacing - asz_scaled.x,
            jump_pos.y + attack_y_offset
        )

        print("[GameManager] Setting button positions - Jump: ", jump_pos, " Attack: ", attack_pos, " Viewport: ", vp)

        _jump_button.position = jump_pos
        _attack_button.position = attack_pos

        # Pastikan tombol terlihat di mobile dan z-index tinggi HANYA saat bermain
        _jump_button.visible = (phase != Phase.GAME_OVER)
        _attack_button.visible = (phase != Phase.GAME_OVER)
        _jump_button.z_index = 100
        _attack_button.z_index = 100

        # _update_mobile_button_tints() # Removed tints as per user request


func _update_safe_ui_layout(safe: Rect2, viewport_size: Vector2) -> void:
    # Banner height offset (estimasi 70px + margin 10px) - Hanya untuk notifikasi tengah
    var banner_height: float = 80.0
    var inset_top_center: float = safe.position.y + banner_height
    var inset_top_hud: float = safe.position.y
    var inset_right: float = maxf(viewport_size.x - (safe.position.x + safe.size.x), 0.0)
    var inset_bottom: float = maxf(viewport_size.y - (safe.position.y + safe.size.y), 0.0)

    # Hapus pengaturan settings_button di sini karena dipindah ke bawah (RIGHT GROUP) agar logic-nya menyatu

    if version_label:
        version_label.offset_top = -32.0 - inset_bottom
        version_label.offset_bottom = -8.0 - inset_bottom

    if bgm_toast:
        bgm_toast.offset_top = 10.0 + inset_top_center
        bgm_toast.offset_bottom = 50.0 + inset_top_center

    if missions_toast:
        # Pindahkan ke kanan atas, lebih compact
        missions_toast.anchor_left = 1.0
        missions_toast.anchor_right = 1.0
        missions_toast.anchor_top = 0.0
        missions_toast.anchor_bottom = 0.0
        missions_toast.offset_left = -280.0 - inset_right
        missions_toast.offset_right = -10.0 - inset_right
        missions_toast.offset_top = 10.0 + inset_top_center
        missions_toast.offset_bottom = 54.0 + inset_top_center

    var sx := safe.position.x
    var sy := safe.position.y
    var rx := safe.position.x + safe.size.x

    # HUD Scaling (Kembalikan ke ukuran yang lebih wajar tapi tetap compact)
    var hud_scale := Vector2(0.85, 0.85)

    # LEFT GROUP (Health & Coin)
    if health_icon:
        health_icon.position = Vector2(sx + 20.0, sy + 24.0)
    if health_bar:
        health_bar.position = Vector2(sx + 40.0, sy + 12.0)
    if heart_spawn_label:
        heart_spawn_label.position = Vector2(sx + 248.0, sy + 12.0)

    if coin_hud:
        coin_hud.scale = hud_scale
        # Geser text lebih ke kanan agar tidak menumpuk dengan icon
        coin_hud.position = Vector2(sx + 60.0, sy + 64.0)
    if coin_icon_anim:
        # Perbesar sedikit icon dan geser agar tidak terlalu mepet kiri
        coin_icon_anim.scale = Vector2(0.25, 0.25)
        coin_icon_anim.position = Vector2(sx + 25.0, sy + 76.0)

    # RIGHT GROUP (Score, Gem, Settings)
    # Settings Button di pojok kanan paling ujung
    if settings_button:
        # Reset offset karena kita pakai position manual atau anchor yang sudah benar
        # Tapi karena ini Control node dengan anchor, kita mainkan offset dari kanan
        settings_button.anchor_left = 1.0
        settings_button.anchor_right = 1.0
        settings_button.offset_left = -72.0 - inset_right
        settings_button.offset_right = -16.0 - inset_right
        settings_button.offset_top = 16.0 + inset_top_hud
        settings_button.offset_bottom = 72.0 + inset_top_hud

    # Score & Gem di sebelah kiri Settings Button
    var right_hud_margin := 90.0 # Space untuk settings button

    if score_hud:
        score_hud.scale = hud_scale
        # Posisi X: Kanan layar - Margin Settings - Lebar estimasi Score
        score_hud.position = Vector2(rx - right_hud_margin - 140.0, sy + 20.0)

    if gem_hud:
        gem_hud.scale = hud_scale
        gem_hud.position = Vector2(rx - right_hud_margin - 140.0, sy + 55.0)

    var icon_x := sx + 16.0
    var label_x := sx + 56.0

    if magnet_icon:
        magnet_icon.position = Vector2(icon_x, sy + 96.0)
    if magnet_timer_label:
        magnet_timer_label.position = Vector2(label_x, sy + 96.0)
    if shield_icon:
        shield_icon.position = Vector2(icon_x, sy + 128.0)
    if shield_timer_label:
        shield_timer_label.position = Vector2(label_x, sy + 128.0)
    if double_coins_icon:
        double_coins_icon.position = Vector2(icon_x, sy + 160.0)
    if double_coins_timer_label:
        double_coins_timer_label.position = Vector2(label_x, sy + 160.0)
    if speed_boost_icon:
        speed_boost_icon.position = Vector2(icon_x, sy + 192.0)
    if speed_boost_timer_label:
        speed_boost_timer_label.position = Vector2(label_x, sy + 192.0)

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
    open_settings_menu()


func _wire_settings_menu_signals(settings_menu: Node) -> void:
    if settings_menu == null:
        return
    var c_bgm_vol := Callable(self, "set_bgm_volume")
    if settings_menu.has_signal("bgm_volume_changed") and not settings_menu.is_connected("bgm_volume_changed", c_bgm_vol):
        settings_menu.connect("bgm_volume_changed", c_bgm_vol)
    var c_sfx_vol := Callable(self, "set_sfx_volume")
    if settings_menu.has_signal("sfx_volume_changed") and not settings_menu.is_connected("sfx_volume_changed", c_sfx_vol):
        settings_menu.connect("sfx_volume_changed", c_sfx_vol)
    var c_bgm_mute := Callable(self, "set_bgm_muted")
    if settings_menu.has_signal("bgm_mute_changed") and not settings_menu.is_connected("bgm_mute_changed", c_bgm_mute):
        settings_menu.connect("bgm_mute_changed", c_bgm_mute)
    var c_sfx_mute := Callable(self, "set_sfx_muted")
    if settings_menu.has_signal("sfx_mute_changed") and not settings_menu.is_connected("sfx_mute_changed", c_sfx_mute):
        settings_menu.connect("sfx_mute_changed", c_sfx_mute)

    var c_resume := Callable(self, "resume_game")
    if settings_menu.has_signal("resume_pressed") and not settings_menu.is_connected("resume_pressed", c_resume):
        settings_menu.connect("resume_pressed", c_resume)

    var c_restart := Callable(self, "restart_game")
    if settings_menu.has_signal("restart_pressed") and not settings_menu.is_connected("restart_pressed", c_restart):
        settings_menu.connect("restart_pressed", c_restart)

    var c_menu := Callable(self, "return_to_main_menu")
    if settings_menu.has_signal("menu_pressed") and not settings_menu.is_connected("menu_pressed", c_menu):
        settings_menu.connect("menu_pressed", c_menu)

func _process(delta: float) -> void:
    if not is_inside_tree():
        return
    if countdown_active and game_active:
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

    if phase == Phase.PLAYING and game_active:
        var env_speed: float = base_speed
        if is_instance_valid(ground_a) and ground_a.has_method("get_speed"):
            env_speed = float(ground_a.call("get_speed"))

        # Update distance and background scrolling
        distance += env_speed * delta

        # Update tiles passed based on fixed tile width if env_speed is active
        var tile_w_px: float = 128.0 # Default tile width
        _tiles_passed_accum += env_speed * delta / tile_w_px
        total_tiles_passed = int(_tiles_passed_accum)

        game_time_sec += delta
        score = _score_offset + int(total_tiles_passed * score_per_tile)
        if is_instance_valid(coin_hud_label):
            coin_hud_label.text = str(coin_collected_a + coin_collected_b)
        if is_instance_valid(gem_hud_label):
            gem_hud_label.text = str(gem_collected_a + gem_collected_b)
        if is_instance_valid(score_hud_label):
            score_hud_label.text = str(score)
        if is_instance_valid(missions_manager) and missions_manager.has_method("update_distance"):
            missions_manager.update_distance(distance)
        var target_speed: float = clamp(base_speed + distance * speed_gain_per_meter, base_speed, max_speed)
        var boost_active: bool = speed_boost_timer > 0.0 and speed_boost_multiplier > 1.0
        if boost_active:
            target_speed *= speed_boost_multiplier
        if is_instance_valid(ground_a):
            if ground_a.has_method("set_speed"):
                ground_a.set_speed(target_speed)
            if ground_a.has_method("set_instant_speed_mode"):
                ground_a.set_instant_speed_mode(boost_active)
        if is_instance_valid(player):
            player.run_speed = target_speed
            if player.has_method("set_run_anim_factor"):
                var anim_factor: float = max(0.1, target_speed / max(base_speed, 0.1))
                player.call("set_run_anim_factor", anim_factor)
        _update_speed_info_label(env_speed, target_speed)
    if game_active:
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
        _apply_enemy_ramp_if_needed()
    if canvas:
        if magnet_icon:
            magnet_icon.visible = magnet_enabled
        if magnet_timer_label:
            magnet_timer_label.visible = magnet_enabled
            if magnet_enabled:
                var sec_left: int = int(ceil(magnet_timer))
                magnet_timer_label.text = str(max(sec_left, 0))
            else:
                magnet_timer_label.text = ""
        var shield_protection_active: bool = shield_enabled or shield_hit_charges_run > 0
        if shield_icon:
            shield_icon.visible = shield_protection_active
        if shield_timer_label:
            shield_timer_label.visible = shield_protection_active
            if shield_enabled:
                var shield_sec_left: int = int(ceil(shield_timer))
                shield_timer_label.text = str(max(shield_sec_left, 0))
            elif shield_hit_charges_run > 0:
                shield_timer_label.text = "x" + str(shield_hit_charges_run)
            else:
                shield_timer_label.text = ""
        if double_coins_icon:
            double_coins_icon.visible = double_coins_run_active
        if double_coins_timer_label:
            double_coins_timer_label.visible = double_coins_run_active
            if double_coins_run_active:
                var dsec_left: int = int(ceil(double_coins_timer))
                double_coins_timer_label.text = str(max(dsec_left, 0))
            else:
                double_coins_timer_label.text = ""
        var speed_active: bool = speed_boost_timer > 0.0 and speed_boost_multiplier > 1.0
        if speed_boost_icon:
            speed_boost_icon.visible = speed_active
        if speed_boost_timer_label:
            speed_boost_timer_label.visible = speed_active
            if speed_active:
                var speed_sec_left: int = int(ceil(speed_boost_timer))
                speed_boost_timer_label.text = str(max(speed_sec_left, 0))
            else:
                speed_boost_timer_label.text = ""
        if heart_spawn_label:
            heart_spawn_label.visible = false

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
    if is_instance_valid(ground_a) and ground_a.has_method("get_speed"):
        ground_speed = float(ground_a.call("get_speed"))
    var parallax_speed: float = 0.0
    if is_instance_valid(parallax) and parallax.has_method("get_layer_speed"):
        parallax_speed = float(parallax.call("get_layer_speed", 0))
    var player_speed: float = 0.0
    if is_instance_valid(player):
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
    if is_instance_valid(player) and player.is_inside_tree():
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
    if is_instance_valid(_jump_button) and _jump_button.is_inside_tree():
        jump_pos = _jump_button.global_position
    if is_instance_valid(_attack_button) and _attack_button.is_inside_tree():
        attack_pos = _attack_button.global_position
    var cam_center: Vector2 = Vector2.ZERO
    var cam := get_viewport().get_camera_2d()
    if cam != null and cam.is_inside_tree():
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
    if is_instance_valid(player) and player.is_inside_tree() and ground_a.has_method("get_powerup_distances"):
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
    get_tree().paused = true
    if terrain and terrain.has_method("set_movement_enabled"):
        terrain.set_movement_enabled(false)
    if ground_a and ground_a.has_method("set_movement_enabled"):
        ground_a.set_movement_enabled(false)

func resume_game() -> void:
    if phase == Phase.GAME_OVER:
        return
    game_active = true
    get_tree().paused = false
    if terrain and terrain.has_method("set_movement_enabled"):
        terrain.set_movement_enabled(true)
    if ground_a and ground_a.has_method("set_movement_enabled"):
        ground_a.set_movement_enabled(true)
    var tgt: float = clamp(base_speed + distance * speed_gain_per_meter, base_speed, max_speed)
    if ground_a and ground_a.has_method("set_speed"):
        ground_a.set_speed(tgt)

func return_to_main_menu() -> void:
    get_tree().paused = false
    if Preloader and Preloader.has_method("set_next_scene"):
        Preloader.set_next_scene("res://scenes/MainMenu.tscn")
    TransitionManager.play_transition_to_scene("res://scenes/LoadingScreen.tscn")


func open_missions_menu() -> void:
    _missions_menu_opened_from_playing = false
    _missions_menu_was_paused = get_tree().paused

    var is_ingame = (phase != Phase.GAME_OVER)
    if is_ingame:
        _missions_menu_opened_from_playing = true
        pause_game()

    var missions_menu := get_node_or_null("DailyMissionsMenu")
    if missions_menu == null:
        var packed := load("res://scenes/DailyMissionsMenu.tscn") as PackedScene
        if packed:
            missions_menu = packed.instantiate()
            (missions_menu as Node).name = "DailyMissionsMenu"
            add_child(missions_menu)
    if missions_menu:
        var cb := Callable(self, "_on_missions_overlay_closed")
        if missions_menu.has_signal("overlay_closed") and not missions_menu.is_connected("overlay_closed", cb):
            missions_menu.connect("overlay_closed", cb)
        if missions_menu.has_method("show_overlay"):
            missions_menu.call("show_overlay")
        elif missions_menu is CanvasItem:
            (missions_menu as CanvasItem).visible = true


func open_settings_menu() -> void:
    # Cek apakah menu sudah ada dan sedang ditampilkan
    var existing := get_node_or_null("SettingsMenu")
    if existing and (existing.visible or (existing.has_node("UI") and existing.get_node("UI").visible)):
        # Jika menu ada tapi tidak terlihat, panggil show_overlay lagi
        if existing.has_method("show_overlay"):
            existing.call("show_overlay")
        elif existing is CanvasItem:
            (existing as CanvasItem).visible = true
        return

    _settings_menu_opened_from_playing = false
    _settings_menu_was_paused = get_tree().paused

    var is_ingame = (phase != Phase.GAME_OVER)
    if is_ingame:
        _settings_menu_opened_from_playing = true
        pause_game()

    var settings_menu := existing
    if settings_menu == null:
        var packed := load("res://scenes/SettingsMenu.tscn") as PackedScene
        if packed:
            settings_menu = packed.instantiate()
            (settings_menu as Node).name = "SettingsMenu"
            add_child(settings_menu)

    if settings_menu:
        var cb := Callable(self, "_on_settings_overlay_closed")
        if settings_menu.has_signal("overlay_closed") and not settings_menu.is_connected("overlay_closed", cb):
            settings_menu.connect("overlay_closed", cb)
        _wire_settings_menu_signals(settings_menu as Node)
        if settings_menu.has_method("show_overlay"):
            settings_menu.call("show_overlay", is_ingame)
        elif settings_menu is CanvasItem:
            (settings_menu as CanvasItem).visible = true


func _on_missions_overlay_closed() -> void:
    if _missions_menu_opened_from_playing:
        _missions_menu_opened_from_playing = false
        if not _missions_menu_was_paused:
            resume_game()

func _on_settings_overlay_closed() -> void:
    if _settings_menu_opened_from_playing:
        _settings_menu_opened_from_playing = false
        if not _settings_menu_was_paused:
            resume_game()

func try_rewarded_continue() -> void:
    if ads_shown_count >= ads_max_per_session:
        print("[GameManager] Max ads reached, cannot continue.")
        return
    var adm = AdManager
    if adm and adm.has_method("show_rewarded"):
        if adm.has_method("is_rewarded_available") and not adm.is_rewarded_available():
            print("[GameManager] Rewarded ad not available.")
            return
        if adm.has_signal("reward_granted"):
            var cb := Callable(self, "_on_reward_granted")
            if not adm.reward_granted.is_connected(cb):
                adm.reward_granted.connect(cb)
                print("[GameManager] Connected to reward_granted signal.")
        print("[GameManager] Requesting rewarded ad...")
        adm.show_rewarded("continue")
    else:
        print("[GameManager] AdManager not found or missing method.")

func _on_reward_granted(reason: String) -> void:
    print("[GameManager] _on_reward_granted called with reason: ", reason)
    if reason == "continue":
        ads_shown_count += 1
        # Call deferred to ensure we are on main thread and UI is ready
        call_deferred("grant_continue")

func grant_continue() -> void:
    print("[GameManager] grant_continue execution started.")
    # Force hide Game Over menu immediately
    if canvas:
        var gom := canvas.get_node_or_null("GameOverMenu")
        if gom:
            gom.visible = false
            print("[GameManager] GameOverMenu hidden forcibly.")

    # Rollback total stats from previous game over (undo finalization)
    total_coins -= last_coins
    total_gems -= last_gems
    if total_coins < 0: total_coins = 0
    if total_gems < 0: total_gems = 0

    # Capture stats for new run (Carry Over)
    _carry_over_stats = {
        "score": last_score,
        "coin_collected": last_coins,
        "gem_collected": last_gems
    }

    # Save progress with rolled back totals (to prevent double counting if they die again)
    _save_progress()

    # Restart game from beginning
    restart_game()

func set_bgm_volume(v: float) -> void:
    _bgm_user_volume = clampf(v, 0.0, 1.0)
    _bgm_base_db = (-60.0 if _bgm_user_volume <= 0.0 else 20.0 * log(_bgm_user_volume) / log(10.0))
    _apply_bgm_mix()

func duck_bgm(reduction_db: float = 6.0, duration_sec: float = 0.22) -> void:
    if bgm_muted:
        return
    if _bgm_mode != BgmMode.RUN:
        return
    var d := -absf(reduction_db)
    _bgm_duck_db = minf(_bgm_duck_db, d)
    _apply_bgm_mix()
    if _bgm_duck_tween and _bgm_duck_tween.is_running():
        _bgm_duck_tween.kill()
    var dur: float = maxf(duration_sec, 0.02)
    _bgm_duck_tween = create_tween()
    _bgm_duck_tween.tween_method(func(v2: float) -> void:
        _bgm_duck_db = v2
        _apply_bgm_mix()
    , _bgm_duck_db, 0.0, dur)

func _apply_bgm_mix() -> void:
    var bgm := get_node_or_null("BGM") as AudioStreamPlayer
    if bgm == null:
        return
    var mode_offset := (_RUN_BGM_OFFSET_DB if _bgm_mode == BgmMode.RUN else 0.0)
    bgm.volume_db = (-60.0 if bgm_muted else (_bgm_base_db + mode_offset + _bgm_duck_db))

func set_sfx_volume(v: float) -> void:
    _sfx_user_volume = clampf(v, 0.0, 1.0)
    if TransitionManager and TransitionManager.has_method("set_sfx_volume"):
        TransitionManager.set_sfx_volume(_sfx_user_volume)
    var sfx := get_node_or_null("SFXJump")
    if sfx and sfx is AudioStreamPlayer:
        var db: float = (-60.0 if _sfx_user_volume <= 0.0 else 20.0 * log(_sfx_user_volume) / log(10.0))
        (sfx as AudioStreamPlayer).volume_db = (-60.0 if sfx_muted else db)

func set_bgm_muted(m: bool) -> void:
    bgm_muted = m
    var bgm := get_node_or_null("BGM")
    if bgm and bgm is AudioStreamPlayer:
        if m:
            (bgm as AudioStreamPlayer).stop()
        else:
            if (bgm as AudioStreamPlayer).stream != null:
                (bgm as AudioStreamPlayer).play()
    _apply_bgm_mix()
    _save_progress()

func set_sfx_muted(m: bool) -> void:
    sfx_muted = m
    if TransitionManager and TransitionManager.has_method("set_sfx_muted"):
        TransitionManager.set_sfx_muted(m)
    var sfx := get_node_or_null("SFXJump")
    if sfx and sfx is AudioStreamPlayer:
        var db: float = (-60.0 if _sfx_user_volume <= 0.0 else 20.0 * log(_sfx_user_volume) / log(10.0))
        (sfx as AudioStreamPlayer).volume_db = (-60.0 if m else db)
    _save_progress()

func activate_magnet(d: float) -> void:
    var dur: float = d
    if dur <= 0.0:
        dur = powerup_magnet_duration_sec
    else:
        dur *= max(magnet_duration_multiplier, 0.1)
    magnet_timer = max(dur, 0.0)
    magnet_enabled = magnet_timer > 0.0
    shield_timer = 0.0
    shield_enabled = false
    speed_boost_timer = 0.0
    speed_boost_multiplier = 1.0
    double_coins_timer = 0.0
    double_coins_run_active = false
    if missions_manager and missions_manager.has_method("add_skill"):
        missions_manager.add_skill()

func activate_shield(d: float) -> void:
    var dur: float = d
    if dur <= 0.0:
        dur = powerup_shield_duration_sec
    else:
        dur *= max(shield_duration_multiplier, 0.1)
    shield_timer = max(dur, 0.0)
    shield_enabled = shield_timer > 0.0
    magnet_timer = 0.0
    magnet_enabled = false
    speed_boost_timer = 0.0
    speed_boost_multiplier = 1.0
    double_coins_timer = 0.0
    double_coins_run_active = false
    if missions_manager and missions_manager.has_method("add_skill"):
        missions_manager.add_skill()
    if missions_manager and missions_manager.has_method("add_shield_skill"):
        missions_manager.add_shield_skill()

func is_magnet_active() -> bool:
    return magnet_enabled

func is_shield_active() -> bool:
    return shield_enabled

func try_consume_shield_hit() -> bool:
    if shield_enabled:
        return true
    if shield_hit_charges_run <= 0:
        return false
    shield_hit_charges_run = max(shield_hit_charges_run - 1, 0)
    powerups_data["shield_1hit_charges"] = shield_hit_charges_run
    _save_progress()
    return true

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
    if not is_instance_valid(player) or not player.is_inside_tree():
        return -1.0
    var p_pos: Vector2 = player.global_position
    var best: float = -1.0
    var grounds: Array = []
    if is_instance_valid(ground_a) and ground_a.is_inside_tree():
        grounds.append(ground_a)
    for g in grounds:
        if g == null:
            continue
        # Check all potential containers for hearts
        var container_names = ["HeartsA", "HeartsB", "CoinsA", "CoinsB"]
        for c_name in container_names:
            var root: Node = g.get_node_or_null(c_name)
            if root == null:
                continue
            for c in root.get_children():
                if (c is HeartPickup) or c.is_in_group("heart_pickup"):
                    if not (c is Node2D):
                        continue
                    var n2 := c as Node2D
                    if not n2.is_inside_tree():
                        continue
                    if n2.global_position.x < p_pos.x:
                        continue
                    var d: float = p_pos.distance_to(n2.global_position)
                    if best < 0.0 or d < best:
                        best = d
    return best

func activate_speed_boost(d: float = 0.0, m: float = 0.0) -> void:
    var was_active := speed_boost_timer > 0.0 and speed_boost_multiplier > 1.0
    var dur: float = d
    if dur <= 0.0:
        dur = powerup_speed_boost_duration_sec
    else:
        dur *= max(speed_boost_duration_multiplier, 0.1)
    var mul: float = m
    if mul <= 0.0:
        mul = powerup_speed_boost_multiplier
    else:
        mul *= max(speed_boost_multiplier_multiplier, 0.1)
    speed_boost_timer = max(dur, 0.0)
    speed_boost_multiplier = max(mul, 1.0)
    if (not was_active) and (speed_boost_timer > 0.0 and speed_boost_multiplier > 1.0):
        TransitionManager.play_sfx(&"speed_boost_start")
    magnet_timer = 0.0
    magnet_enabled = false
    shield_timer = 0.0
    shield_enabled = false
    double_coins_timer = 0.0
    double_coins_run_active = false
    if missions_manager and missions_manager.has_method("add_skill"):
        missions_manager.add_skill()

func is_speed_boost_active() -> bool:
    return speed_boost_timer > 0.0 and speed_boost_multiplier > 1.0

func _clear_existing_magnets_and_shields() -> void:
    var grounds: Array = []
    if ground_a != null:
        grounds.append(ground_a)
    for g in grounds:
        if g == null:
            continue
        var container_names = ["MagnetsA", "ShieldsA", "CoinsA"]
        for c_name in container_names:
            var root: Node = g.get_node_or_null(c_name)
            if root == null:
                continue
            for c in root.get_children():
                if (c is MagnetPowerup) or (c is ShieldPowerup) or c.is_in_group("shield_powerup"):
                    c.queue_free()

func _clear_existing_speed_boosts() -> void:
    var grounds: Array = []
    if ground_a != null:
        grounds.append(ground_a)
    for g in grounds:
        if g == null:
            continue
        var container_names = ["SpeedBoostsA", "CoinsA"]
        for c_name in container_names:
            var root: Node = g.get_node_or_null(c_name)
            if root == null:
                continue
            for c in root.get_children():
                if c is SpeedBoostPowerup:
                    c.queue_free()

func _clear_existing_hearts() -> void:
    var grounds: Array = []
    if ground_a != null:
        grounds.append(ground_a)
    for g in grounds:
        if g == null:
            continue
        for coins_root_name in ["CoinsA"]:
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
    if cam != null and cam.is_inside_tree():
        left_limit = cam.global_position.x - float(view_rect.size.x) * 0.5 - 64.0
    elif player != null and player.is_inside_tree():
        left_limit = player.global_position.x - float(view_rect.size.x) * 0.6
    else:
        return
    var grounds: Array = []
    if ground_a != null:
        grounds.append(ground_a)
    for g in grounds:
        if g == null:
            continue
        for coins_root_name in ["CoinsA"]:
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
                if not n2.is_inside_tree():
                    continue
                if n2.global_position.x < left_limit:
                    n2.queue_free()

func _ensure_skills_ahead_of_player() -> void:
    if phase != Phase.PLAYING:
        return
    if not is_instance_valid(player) or not player.is_inside_tree():
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

var _last_heart_spawn_check_time: float = 0.0

func _ensure_hearts_for_low_health() -> void:
    if phase != Phase.PLAYING:
        return
    var now: float = Time.get_ticks_msec() / 1000.0
    if now - _last_heart_spawn_check_time < 2.0:
        return
    _last_heart_spawn_check_time = now

    if player == null:
        return
    if ground_a == null:
        return
    if _last_health_max <= 0:
        return
    if _last_health_current >= _last_health_max:
        return

    if OS.is_debug_build():
        print("[GameManager] Low health detected: %d/%d. Checking for hearts..." % [_last_health_current, _last_health_max])

    if _has_any_heart_on_ground():
        if OS.is_debug_build():
            var d: float = _get_nearest_heart_distance_px()
            print("[GameManager] Heart found ahead at distance: %.2f px. Skipping spawn." % d)
        return

    if OS.is_debug_build():
        print("[GameManager] No heart found ahead. Requesting emergency spawn...")

    if not ground_a.has_method("request_emergency_heart"):
        return
    if not is_instance_valid(player) or not player.is_inside_tree():
        return
    var px: float = player.global_position.x
    var cam := get_viewport().get_camera_2d()
    var view_rect := get_viewport().get_visible_rect()
    if cam != null and cam.is_inside_tree():
        px = cam.global_position.x + float(view_rect.size.x) * 0.5
    var min_heart_dist_px: float = 500.0
    var max_heart_dist_px: float = 700.0
    if ground_a.has_method("request_emergency_heart"):
        ground_a.call("request_emergency_heart", px, min_heart_dist_px, max_heart_dist_px)

func _ensure_skill_after_power_end(_kind: String) -> void:
    if phase != Phase.PLAYING:
        return
    if not is_instance_valid(player) or not player.is_inside_tree():
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
            if ground_a.has_method("request_emergency_magnet"):
                ground_a.call("request_emergency_magnet", px, min_skill_dist_px, max_skill_dist_px)
        "shield":
            if ground_a.has_method("request_emergency_shield"):
                ground_a.call("request_emergency_shield", px, min_skill_dist_px, max_skill_dist_px)
        "double_coins":
            if ground_a.has_method("request_emergency_double_coins"):
                ground_a.call("request_emergency_double_coins", px, min_skill_dist_px, max_skill_dist_px)
        "speed_boost":
            if ground_a.has_method("request_emergency_speed_boost"):
                ground_a.call("request_emergency_speed_boost", px, min_skill_dist_px, max_skill_dist_px)

func _on_player_health_decreased(_current: int, _maximum: int) -> void:
    call_deferred("_ensure_hearts_for_low_health")

func _apply_enemy_ramp_if_needed() -> void:
    return


func set_playing_phase() -> void:
    phase = Phase.PLAYING
    game_active = true
    _bgm_mode = BgmMode.RUN
    _bgm_duck_db = 0.0
    _apply_spawn_safety_limits()
    _update_mobile_controls_layout(true)
    if ground_a and ground_a.has_method("set_speed_limits"):
        var max_with_boost: float = max_speed
        if powerup_speed_boost_multiplier > 1.0:
            max_with_boost = max_speed * powerup_speed_boost_multiplier
        ground_a.set_speed_limits(0.0, max_with_boost)
    if terrain and terrain.has_method("set_movement_enabled"):
        terrain.set_movement_enabled(true)
    if ground_a and ground_a.has_method("set_movement_enabled"):
        ground_a.set_movement_enabled(true)
        if ground_a.has_method("set_speed"):
            ground_a.set_speed(base_speed)
    if player:
        if player.has_method("prepare_for_playing_phase"):
            player.prepare_for_playing_phase()
        if player.has_method("enable_environment_movement"):
            player.enable_environment_movement(true)

    if parallax and parallax.has_method("set_speed"):
        var p_speed: float = 300.0
        if parallax.has_method("get"):
            var s = parallax.get("speed")
            if s != null:
                p_speed = float(s)
        parallax.set_speed(p_speed)

    _start_bukit_bgm_rotation()
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


func _apply_powerups_for_new_run() -> void:
    if powerups_data.is_empty():
        shield_hit_charges_run = 0
    else:
        shield_hit_charges_run = int(powerups_data.get("shield_1hit_charges", 0))

    var changed := false
    var double_tokens: int = int(powerups_data.get("double_coins_run_tokens", 0))
    if double_tokens > 0:
        activate_double_coins_run()
        powerups_data["double_coins_run_tokens"] = max(double_tokens - 1, 0)
        changed = true

    # 4. Magnet Run (Pre-active)
    var magnet_run_tokens: int = int(powerups_data.get("magnet_30s_tokens", 0))
    if magnet_run_tokens > 0:
        powerup_magnet_duration_sec = _base_powerup_magnet_duration_sec * max(magnet_duration_multiplier, 0.1)
        magnet_timer = powerup_magnet_duration_sec
        magnet_enabled = true
        powerups_data["magnet_30s_tokens"] = max(magnet_run_tokens - 1, 0)
        changed = true

    # 5. Speed Boost Run (Pre-active)
    var speed_boost_tokens: int = int(powerups_data.get("speed_boost_tokens", 0))
    if speed_boost_tokens > 0:
        var dur_mul: float = max(speed_boost_duration_multiplier, 0.1)
        var mul_mul: float = max(speed_boost_multiplier_multiplier, 0.1)
        speed_boost_timer = _SPEED_BOOST_PRE_RUN_DURATION_SEC * dur_mul
        speed_boost_multiplier = max(_SPEED_BOOST_PRE_RUN_MULTIPLIER * mul_mul, 1.0)
        powerups_data["speed_boost_tokens"] = max(speed_boost_tokens - 1, 0)
        changed = true

    if player and player is Player:
        var p := player as Player
        var base_max: int = (_base_player_max_health if _base_player_max_health > 0 else int(p.max_health))
        var effective_max: int = base_max + max_heart_bonus
        p.max_health = effective_max
        p.starting_health = effective_max
        p.current_health = effective_max

        set_player_health(effective_max, effective_max)

    powerup_magnet_duration_sec = _base_powerup_magnet_duration_sec * max(magnet_duration_multiplier, 0.1)
    powerup_shield_duration_sec = _base_powerup_shield_duration_sec * max(shield_duration_multiplier, 0.1)
    if _base_powerup_double_coins_duration_sec < 0.0:
        _base_powerup_double_coins_duration_sec = powerup_double_coins_duration_sec
    if _base_powerup_speed_boost_duration_sec < 0.0:
        _base_powerup_speed_boost_duration_sec = powerup_speed_boost_duration_sec
    if _base_powerup_speed_boost_multiplier < 0.0:
        _base_powerup_speed_boost_multiplier = powerup_speed_boost_multiplier
    powerup_double_coins_duration_sec = _base_powerup_double_coins_duration_sec * max(double_coins_duration_multiplier, 0.1)
    powerup_speed_boost_duration_sec = _base_powerup_speed_boost_duration_sec * max(speed_boost_duration_multiplier, 0.1)
    powerup_speed_boost_multiplier = _base_powerup_speed_boost_multiplier * max(speed_boost_multiplier_multiplier, 0.1)
    if changed:
        _save_progress()


func on_player_entry_finished() -> void:
    if phase != Phase.ENTRY:
        return
    entry_finished = true
    if not countdown_active:
        set_playing_phase()

func on_player_game_over(_cause: String) -> void:
    if phase == Phase.GAME_OVER:
        return
    phase = Phase.GAME_OVER
    game_active = false
    if _jump_button: _jump_button.visible = false
    if _attack_button: _attack_button.visible = false
    TransitionManager.play_sfx(&"game_over")
    if terrain and terrain.has_method("set_movement_enabled"):
        terrain.set_movement_enabled(false)
    if ground_a and ground_a.has_method("set_movement_enabled"):
        ground_a.set_movement_enabled(false)
    if ground_a and ground_a.has_method("set_speed"):
        ground_a.set_speed(0.0)

    last_score = score
    last_coins = coin_collected_a + coin_collected_b
    last_gems = gem_collected_a + gem_collected_b
    total_coins += last_coins
    total_gems += last_gems
    var xp_gain_from_distance: int = int(distance * xp_per_meter)
    var xp_gain_from_coins: int = int(float(last_coins) * xp_per_coin)
    var xp_gain: int = xp_gain_from_distance + xp_gain_from_coins
    if xp_gain > 0:
        _apply_xp_gain(xp_gain)
    if missions_manager and missions_manager.has_method("update_distance"):
        missions_manager.update_distance(distance)
    if missions_manager and missions_manager.has_method("add_run_played"):
        missions_manager.add_run_played()
    if score > best_score:
        best_score = score
    _save_progress()
    _play_game_over_bgm()
    if anomaly:
        anomaly.hide()

    if parallax and parallax.has_method("set_speed"):
        parallax.set_speed(0.0)
    if debug_label != null:
        debug_label.visible = false
    if canvas:
        var gom := canvas.get_node_or_null("GameOverMenu")
        if gom and gom.has_method("show_game_over"):
            gom.show_game_over(score, distance)

func _play_game_over_bgm() -> void:
    _bgm_mode = BgmMode.GAME_OVER
    _bgm_duck_db = 0.0
    if _bgm_duck_tween and _bgm_duck_tween.is_running():
        _bgm_duck_tween.kill()
    if bgm_muted:
        return
    var bgm := get_node_or_null("BGM") as AudioStreamPlayer
    if bgm == null:
        return
    var path := _pick_gameover_bgm_path()
    if path.is_empty():
        return
    var stream := load(path) as AudioStream
    if stream == null:
        return
    if stream is AudioStreamMP3:
        (stream as AudioStreamMP3).loop = false
    if _bgm_fade_tween and _bgm_fade_tween.is_running():
        _bgm_fade_tween.kill()
    _bgm_fade_tween = create_tween()
    _bgm_fade_tween.tween_property(bgm, "volume_db", -60.0, 0.18)
    _bgm_fade_tween.tween_callback(func() -> void:
        if bgm:
            bgm.stop()
            bgm.stream = stream
            bgm.play()
            _apply_bgm_mix()
            bgm.volume_db = -60.0
    )
    _bgm_fade_tween.tween_property(bgm, "volume_db", (_bgm_base_db if not bgm_muted else -60.0), 0.22)

func restart_game() -> void:
    get_tree().paused = false
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
        if not is_inside_tree():
            return
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
                        if not is_inside_tree():
                            return
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
    if err != OK:
        bgm_muted = false
        sfx_muted = false
        set_bgm_volume(0.8)
        set_sfx_volume(0.8)
        return
    best_score = int(cfg.get_value("progress", "best_score", 0))
    last_score = int(cfg.get_value("progress", "last_score", 0))
    last_coins = int(cfg.get_value("progress", "last_coins", 0))
    last_gems = int(cfg.get_value("progress", "last_gems", 0))
    total_coins = int(cfg.get_value("progress", "total_coins", 0))
    total_gems = int(cfg.get_value("progress", "total_gems", 0))
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
    if TransitionManager and TransitionManager.has_method("set_sfx_muted"):
        TransitionManager.set_sfx_muted(sfx_muted)
    if bgm_muted:
        var bgm := get_node_or_null("BGM") as AudioStreamPlayer
        if bgm:
            bgm.stop()
    var pd: Variant = cfg.get_value("powerups", "data", {})
    if pd is Dictionary:
        powerups_data = pd
    else:
        powerups_data = {}
    max_heart_bonus = int(powerups_data.get("max_heart_bonus", 0))
    magnet_duration_multiplier = float(powerups_data.get("magnet_duration_multiplier", 1.0))
    shield_duration_multiplier = float(powerups_data.get("shield_duration_multiplier", 1.0))
    pickup_range_bonus = float(powerups_data.get("pickup_range_bonus", 0.0))
    double_coins_duration_multiplier = float(powerups_data.get("double_coins_duration_multiplier", 1.0))
    double_coins_gain_multiplier = float(powerups_data.get("double_coins_gain_multiplier", 2.0))
    speed_boost_duration_multiplier = float(powerups_data.get("speed_boost_duration_multiplier", 1.0))
    speed_boost_multiplier_multiplier = float(powerups_data.get("speed_boost_multiplier_multiplier", 1.0))
    var plr_value: Variant = cfg.get_value("rewards", "pending_level_rewards", [])
    if plr_value is Array:
        pending_level_rewards = plr_value
    else:
        pending_level_rewards = []

func _save_progress() -> void:
    var cfg := ConfigFile.new()
    var err := cfg.load("user://save.cfg")
    if err != OK:
        cfg = ConfigFile.new()
    cfg.set_value("progress", "best_score", best_score)
    cfg.set_value("progress", "last_score", last_score)
    cfg.set_value("progress", "last_coins", last_coins)
    cfg.set_value("progress", "last_gems", last_gems)
    cfg.set_value("progress", "total_coins", total_coins)
    cfg.set_value("progress", "total_gems", total_gems)
    cfg.set_value("progress", "player_level", player_level)
    cfg.set_value("progress", "player_xp", player_xp)
    cfg.set_value("progress", "player_xp_required", player_xp_required)
    cfg.set_value("settings", "bgm_muted", bgm_muted)
    cfg.set_value("settings", "sfx_muted", sfx_muted)
    cfg.set_value("powerups", "data", powerups_data)
    cfg.set_value("rewards", "pending_level_rewards", pending_level_rewards)
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
    var old_level: int = player_level
    player_xp += amount
    if player_level <= 0:
        player_level = 1
    if player_xp_required <= 0:
        player_xp_required = _calculate_xp_required(player_level)
    while player_xp >= player_xp_required:
        player_xp -= player_xp_required
        player_level += 1
        player_xp_required = _calculate_xp_required(player_level)
    if player_level > old_level:
        var new_rewards: Array = _get_pending_level_rewards_for_range(old_level, player_level)
        if new_rewards.size() > 0:
            var merged: Array = []
            for r in pending_level_rewards:
                merged.append(r)
            for r2 in new_rewards:
                if not merged.has(r2):
                    merged.append(r2)
            pending_level_rewards = merged


func _get_pending_level_rewards_for_range(old_level: int, new_level: int) -> Array:
    var result: Array = []
    if new_level <= old_level:
        return result
    for lvl in range(old_level + 1, new_level + 1):
        var reward_type: String = ""
        match lvl:
            2:
                reward_type = "coins_50"
            3:
                reward_type = "coins_100"
            4:
                reward_type = "coins_150"
            5:
                reward_type = "coins_200"
            6:
                reward_type = "gems_5"
            7:
                reward_type = "coins_250"
            8:
                reward_type = "gems_10"
            _:
                reward_type = ""
        if reward_type != "":
            var entry := {"level": lvl, "type": reward_type}
            result.append(entry)
    return result




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
    if event is InputEventKey and event.pressed and not event.echo:
        if Input.is_action_just_pressed("open_missions_menu"):
            open_missions_menu()
            return
        if OS.is_debug_build() and (Input.is_action_just_pressed("toggle_debug") or event.keycode == KEY_F3):
            debug_info_enabled = not debug_info_enabled
            if debug_label != null:
                debug_label.visible = debug_info_enabled
            return
        if OS.is_debug_build() and (Input.is_action_just_pressed("verify_scenes") or event.keycode == KEY_F6):
            call_deferred("_verify_player_scenes")
        elif Input.is_action_pressed("ui_cancel"):
            open_settings_menu()

func on_coin_collected(segment: String, currency: String = "coins", amount: int = 1) -> void:
    var a := amount
    if a <= 0:
        a = 1
    var c := currency
    if c.is_empty():
        c = "coins"

    if c == "gems":
        if segment == "A":
            gem_collected_a += a
        else:
            gem_collected_b += a
        if gem_hud_label != null:
            gem_hud_label.text = str(gem_collected_a + gem_collected_b)
        return

    var gain: int = a
    if double_coins_run_active:
        gain = int(round(float(a) * max(double_coins_gain_multiplier, 1.0)))
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
    if missions_manager and missions_manager.has_method("add_skill"):
        missions_manager.add_skill()
    if missions_manager and missions_manager.has_method("add_double_coins_skill"):
        missions_manager.add_double_coins_skill()

func is_double_coins_active() -> bool:
    return double_coins_run_active

func _clear_existing_double_coins() -> void:
    var grounds: Array = []
    if ground_a != null:
        grounds.append(ground_a)
    for g in grounds:
        if g == null:
            continue
        for coins_root_name in ["CoinsA"]:
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
    if OS.is_debug_build():
        print("[GameManager] set_player_health: %d/%d (Clamped: %.1f)" % [new_current, maximum, clamped])
    if prev_current >= 0 and new_current != prev_current:
        _on_player_health_decreased(new_current, maximum)
func _start_play_phase() -> void:
    if not is_inside_tree():
        return
    get_tree().paused = false
    phase = Phase.ENTRY
    game_active = true
    _bgm_mode = BgmMode.RUN
    _bgm_duck_db = 0.0
    distance = 0.0

    score = 0
    _score_offset = 0
    coin_collected_a = 0
    coin_collected_b = 0
    gem_collected_a = 0
    gem_collected_b = 0

    # Apply carry-over stats if available (Continue feature)
    if not _carry_over_stats.is_empty():
        _score_offset = int(_carry_over_stats.get("score", 0))
        score = _score_offset
        coin_collected_a = int(_carry_over_stats.get("coin_collected", 0))
        gem_collected_a = int(_carry_over_stats.get("gem_collected", 0))
        _carry_over_stats.clear()

    var total_run_coins: int = coin_collected_a + coin_collected_b
    var total_run_gems: int = gem_collected_a + gem_collected_b
    if coin_hud_label != null:
        coin_hud_label.text = str(total_run_coins)
    if gem_hud_label != null:
        gem_hud_label.text = str(total_run_gems)
    if score_hud_label != null:
        score_hud_label.text = str(score)
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
    _missions_completed_type_toasted.clear()
    _apply_powerups_for_new_run()
    if ground_a:
        if ground_a.has_method("restart_from_flat_start"):
            ground_a.restart_from_flat_start()
        elif ground_a.has_method("_run_generate_now"):
            ground_a.call("_run_generate_now", true, true)
    if player and player.has_method("reset_player"):
        player.reset_player()
    _clear_existing_hearts()
    _next_coin_burst_distance = 300
    _apply_spawn_safety_limits()
    if terrain and terrain.has_method("set_movement_enabled"):
        terrain.set_movement_enabled(false)
    if ground_a and ground_a.has_method("set_movement_enabled"):
        ground_a.set_movement_enabled(false)
    var bgm2 := get_node_or_null("BGM")
    if bgm2 and bgm2 is AudioStreamPlayer:
        (bgm2 as AudioStreamPlayer).stop()
    if anomaly:
        anomaly.hide()

    # Hide menus
    if canvas:
        var pm := canvas.get_node_or_null("PauseMenu")
        if pm: pm.visible = false
        var gom := canvas.get_node_or_null("GameOverMenu")
        if gom: gom.visible = false

    if player:
        if player.has_method("enable_environment_movement"):
            player.enable_environment_movement(false)
        if player.has_method("start_entry_sequence"):
            player.start_entry_sequence()

func _append_perf_log(_line: String) -> void:
    pass


@onready var missions_manager: Node = MissionsManager
var _next_coin_burst_distance: int = 300
func _apply_spawn_safety_limits() -> void:
    var layers: Array = []
    if _ga_layer != null:
        layers.append(_ga_layer)
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
    if label and missions_manager:
        var txt: String = ""
        if missions_manager.has_method("get_ingame_missions_text"):
            txt = String(missions_manager.call("get_ingame_missions_text"))
        elif missions_manager.has_method("get_missions_text"):
            txt = String(missions_manager.call("get_missions_text"))
        (label as Label).text = "Misi:\n" + txt

func _trigger_coin_burst() -> void:
    var layers: Array = []
    if _ga_layer != null:
        layers.append(_ga_layer)
    for tl in layers:
        if tl != null and tl.has_method("spawn_bonus_coins"):
            tl.spawn_bonus_coins(2)


func on_enemy_killed_by_player() -> void:
    if missions_manager and missions_manager.has_method("add_enemy_kill"):
        missions_manager.add_enemy_kill()


func on_player_jump() -> void:
    if missions_manager and missions_manager.has_method("add_jump"):
        missions_manager.add_jump()
