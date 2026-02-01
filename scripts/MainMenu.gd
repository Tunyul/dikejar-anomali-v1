extends Control

const MissionsManagerScript := preload("res://scripts/MissionsManager.gd")


var _pending_level_rewards: Array = []
var _reward_panel: Control = null
var _coin_label: Label = null
var _total_coins: int = 0
var _gem_label: Label = null
var _total_gems: int = 0
var _reward_icon: TextureRect = null
var _missions_badge: Control = null
var _daily_button_animator: AnimationPlayer = null

@export var debug_dummy_stats: bool = false

static var _diamond_icon_tex: Texture2D = null

static func _get_diamond_icon_texture() -> Texture2D:
    if _diamond_icon_tex != null:
        return _diamond_icon_tex
    var tex := load("res://assets/diamond animation/diamond-1024x1024.png") as Texture2D
    if tex == null:
        _diamond_icon_tex = null
        return null
    _diamond_icon_tex = tex
    return tex

const _MENU_BGM_DIR := "res://assets/audio/backsound"
const _MENU_BGM_PREFIX := "backsound-mainmenu"
var _menu_bgm: AudioStreamPlayer = null
var _menu_bgm_paths: Array[String] = []
var _menu_bgm_index: int = 0
var _menu_bgm_volume: float = 0.8
var _menu_bgm_muted: bool = false
var _music_toast_panel: Control = null
var _music_toast: Label = null
var _music_toast_tween: Tween = null
var _title_sprite: Sprite2D = null
var _last_viewport_size: Vector2i = Vector2i(-1, -1)


func _ready() -> void:
    var play := get_node_or_null("UI/CenterContainer/VBox/ButtonsRow/PlayButton")
    if play == null:
        play = get_node_or_null("UI/CenterContainer/VBox/PlayButton")
    var shop := get_node_or_null("UI/CenterContainer/VBox/ButtonsRow/ShopButton")
    var settings := get_node_or_null("UI/CenterContainer/VBox/ButtonsRow/SettingsButton")
    var player_hud := get_node_or_null("UI/PlayerHUD")
    var coin_hud := get_node_or_null("UI/CoinHUD")
    var gem_hud := get_node_or_null("UI/GemHUD")
    var score_hud := get_node_or_null("UI/ScoreHUD")
    var daily_button := get_node_or_null("UI/DailyButton")
    _missions_badge = get_node_or_null("UI/DailyButton/MissionsBadge") as Control
    if daily_button:
        _daily_button_animator = daily_button.get_node_or_null("AnimationPlayer")
    _reward_panel = get_node_or_null("UI/RewardPanel") as Control
    var ver := get_node_or_null("UI/VersionLabel")

    if coin_hud:
        _coin_label = coin_hud.get_node_or_null("CoinLabel") as Label
    if gem_hud:
        _gem_label = gem_hud.get_node_or_null("GemLabel") as Label
        var gem_icon := gem_hud.get_node_or_null("GemIcon") as TextureRect
        if gem_icon:
            var icon_tex := _get_diamond_icon_texture()
            if icon_tex:
                gem_icon.texture = icon_tex
                gem_icon.modulate = Color(1, 1, 1, 1)
    if play:
        play.pressed.connect(_on_play_pressed)
    if shop:
        shop.pressed.connect(_on_shop_pressed)
    if settings:
        settings.pressed.connect(_on_settings_pressed)
    if daily_button:
        (daily_button as BaseButton).pressed.connect(_on_daily_pressed)
    if coin_hud or gem_hud or score_hud or player_hud:
        var cfg := ConfigFile.new()
        var err := cfg.load("user://save.cfg")
        if err == OK:
            if coin_hud:
                    _total_coins = int(cfg.get_value("progress", "total_coins", 0))
                    if _coin_label:
                        _coin_label.text = str(_total_coins)
            if gem_hud:
                    _total_gems = int(cfg.get_value("progress", "total_gems", 0))
                    if _gem_label:
                        _gem_label.text = str(_total_gems)
            if score_hud:
                var best := int(cfg.get_value("progress", "best_score", 0))
                var score_label := score_hud.get_node_or_null("ScoreLabel") as Label
                if score_label:
                    score_label.text = str(best)
            if player_hud:
                var level := int(cfg.get_value("progress", "player_level", 1))
                var xp := int(cfg.get_value("progress", "player_xp", 0))
                var xp_required := int(cfg.get_value("progress", "player_xp_required", 100))
                var level_label := player_hud.get_node_or_null("LevelLabel") as Label
                var xp_bar := player_hud.get_node_or_null("XPBar") as ProgressBar
                var xp_label := player_hud.get_node_or_null("XPLabel") as Label
                _reward_icon = player_hud.get_node_or_null("RewardIcon") as TextureRect
                if level_label:
                    level_label.text = "Lv " + str(level)
                if xp_bar:
                    if xp_required <= 0:
                        xp_required = 1
                    xp_bar.max_value = float(xp_required)
                    xp_bar.value = clampf(float(xp), 0.0, float(xp_required))
                if xp_label:
                    xp_label.text = str(xp) + "/" + str(xp_required) + " XP"
                var plr_value = cfg.get_value("rewards", "pending_level_rewards", [])
                if plr_value is Array:
                    _pending_level_rewards = plr_value
                else:
                    _pending_level_rewards = []
                if _reward_icon:
                    _update_reward_icon()
                    _reward_icon.gui_input.connect(_on_reward_icon_gui_input)
        else:
            _reset_main_menu_stats_to_default(coin_hud, gem_hud, score_hud, player_hud)

    if debug_dummy_stats and Engine.is_editor_hint():
        _apply_dummy_stats()
    if daily_button and daily_button is BaseButton:
        _refresh_daily_button_style(daily_button as BaseButton)
    refresh_missions_badge_from_save()

    if ver and ver is Label:
        (ver as Label).text = ProjectSettings.get_setting("application/config/version", "v0.1.0")
    var ground := get_node_or_null("Ground")
    if ground:
        if ground.has_method("set_title_mode"):
            ground.set_title_mode(true)
        if ground.has_method("generate_random"):
            ground.generate_random()
        if ground.has_method("set_movement_enabled"):
            ground.set_movement_enabled(true)
        if ground.has_method("set_speed_limits"):
            ground.set_speed_limits(0.0, 300.0)
        if ground.has_method("set_speed"):
            ground.set_speed(34.0)
    var parallax := get_node_or_null("ParallaxBackground")
    if parallax:
        if parallax.has_method("set_movement_enabled"):
            parallax.set_movement_enabled(true)
        if parallax.has_method("set_speed"):
            parallax.set_speed(200.0)
    var ui_font := load("res://assets/font/Fredoka Nunito/Nunito/static/Nunito-Regular.ttf") as Font
    var title_font := load("res://assets/font/Fredoka Nunito/Fredoka/static/Fredoka-Bold.ttf") as Font
    if ui_font:
        _apply_ui_font(self, ui_font)
    if title_font:
        if _coin_label:
            _apply_shop_number_font(_coin_label, title_font)
        if _gem_label:
            _apply_shop_number_font(_gem_label, title_font)
        if score_hud:
            var score_label := score_hud.get_node_or_null("ScoreLabel") as Label
            if score_label:
                _apply_shop_number_font(score_label, title_font)
        if player_hud:
            var level_label := player_hud.get_node_or_null("LevelLabel") as Label
            if level_label:
                _apply_shop_number_font(level_label, title_font)
            var xp_label := player_hud.get_node_or_null("XPLabel") as Label
            if xp_label:
                _apply_shop_number_font(xp_label, title_font)
        if _reward_panel:
            var reward_title := _reward_panel.get_node_or_null("Title") as Label
            if reward_title:
                _apply_shop_title_font(reward_title, title_font)

    _title_sprite = get_node_or_null("UI/TitleSprite") as Sprite2D
    _connect_viewport_resize()

    _init_menu_bgm()


func _reset_main_menu_stats_to_default(coin_hud: Node, gem_hud: Node, score_hud: Node, player_hud: Node) -> void:
    _total_coins = 0
    _total_gems = 0
    _pending_level_rewards = []

    if coin_hud and _coin_label == null:
        _coin_label = coin_hud.get_node_or_null("CoinLabel") as Label
    if _coin_label:
        _coin_label.text = "0"

    if gem_hud and _gem_label == null:
        _gem_label = gem_hud.get_node_or_null("GemLabel") as Label
    if _gem_label:
        _gem_label.text = "0"

    if score_hud:
        var score_label := score_hud.get_node_or_null("ScoreLabel") as Label
        if score_label:
            score_label.text = "0"

    if player_hud:
        var level_label := player_hud.get_node_or_null("LevelLabel") as Label
        var xp_bar := player_hud.get_node_or_null("XPBar") as ProgressBar
        var xp_label := player_hud.get_node_or_null("XPLabel") as Label
        _reward_icon = player_hud.get_node_or_null("RewardIcon") as TextureRect

        if level_label:
            level_label.text = "Lv 1"
        if xp_bar:
            xp_bar.max_value = 100.0
            xp_bar.value = 0.0
        if xp_label:
            xp_label.text = "0/100 XP"

        if _reward_icon:
            _update_reward_icon()
            var cb := Callable(self, "_on_reward_icon_gui_input")
            if not _reward_icon.gui_input.is_connected(cb):
                _reward_icon.gui_input.connect(cb)


func _apply_dummy_stats() -> void:
    var dummy_big: int = 1234567890
    _total_coins = dummy_big
    _total_gems = dummy_big
    if _coin_label:
        _coin_label.text = str(dummy_big)
    if _gem_label:
        _gem_label.text = str(dummy_big)

    var score_hud := get_node_or_null("UI/ScoreHUD")
    if score_hud:
        var score_label := score_hud.get_node_or_null("ScoreLabel") as Label
        if score_label:
            score_label.text = str(dummy_big)

    var player_hud := get_node_or_null("UI/PlayerHUD")
    if player_hud:
        var level_label := player_hud.get_node_or_null("LevelLabel") as Label
        if level_label:
            level_label.text = "Lv 99"

        var xp_bar := player_hud.get_node_or_null("XPBar") as ProgressBar
        if xp_bar:
            xp_bar.max_value = 1234567.0
            xp_bar.value = xp_bar.max_value * 0.5

        var xp_label := player_hud.get_node_or_null("XPLabel") as Label
        if xp_label:
            xp_label.text = "123456/1234567 XP"


func _on_reward_icon_gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        TransitionManager.play_sfx(&"click")
        _show_reward_panel()
    elif event is InputEventScreenTouch and event.pressed:
        TransitionManager.play_sfx(&"click")
        _show_reward_panel()

func _on_play_pressed() -> void:
    TransitionManager.play_sfx(&"click")
    print("PlayButton ditekan")
    if _menu_bgm:
        _menu_bgm.stop()
    var ui := get_node_or_null("UI")
    if ui:
        ui.visible = false
    visible = false
    process_mode = Node.PROCESS_MODE_DISABLED
    if Preloader and Preloader.has_method("set_next_scene"):
        Preloader.set_next_scene("res://scenes/Main.tscn")
    await TransitionManager.play_transition_to_scene("res://scenes/LoadingScreen.tscn")

func _on_shop_pressed() -> void:
    TransitionManager.play_sfx(&"click")
    if _menu_bgm:
        _menu_bgm.stop()
    get_tree().change_scene_to_file("res://scenes/ShopMenu.tscn")

func _on_settings_pressed() -> void:
    TransitionManager.play_sfx(&"click")
    var settings_menu := get_node_or_null("SettingsMenu")
    if settings_menu == null:
        var packed := load("res://scenes/SettingsMenu.tscn") as PackedScene
        if packed:
            settings_menu = packed.instantiate()
            (settings_menu as Node).name = "SettingsMenu"
            add_child(settings_menu)
    if settings_menu:
        _wire_settings_menu_signals(settings_menu as Node)
    if settings_menu:
        if settings_menu.has_method("show_overlay"):
            settings_menu.show_overlay()
        else:
            (settings_menu as CanvasItem).visible = true

func _on_daily_pressed() -> void:
    TransitionManager.play_sfx(&"click")
    var missions_menu := get_node_or_null("DailyMissionsMenu")
    if missions_menu == null:
        var packed := load("res://scenes/DailyMissionsMenu.tscn") as PackedScene
        if packed:
            missions_menu = packed.instantiate()
            (missions_menu as Node).name = "DailyMissionsMenu"
            add_child(missions_menu)
    if missions_menu:
        if missions_menu.has_method("show_overlay"):
            missions_menu.call("show_overlay")
        else:
            (missions_menu as CanvasItem).visible = true
    call_deferred("refresh_missions_badge_from_save")

    if _reward_panel:
        var claim_btn := _reward_panel.get_node_or_null("ClaimButton") as BaseButton
        var close_btn := _reward_panel.get_node_or_null("CloseButton") as BaseButton
        if claim_btn and not claim_btn.pressed.is_connected(_on_reward_claim_pressed):
            claim_btn.pressed.connect(_on_reward_claim_pressed)
        if close_btn and not close_btn.pressed.is_connected(_on_reward_close_pressed):
            close_btn.pressed.connect(_on_reward_close_pressed)


func _show_reward_panel() -> void:
    if _reward_panel == null:
        _reward_panel = get_node_or_null("UI/RewardPanel") as Control
    if _reward_panel == null:
        return
    _refresh_reward_panel()
    _reward_panel.visible = true


func _hide_reward_panel() -> void:
    if _reward_panel:
        _reward_panel.visible = false


func _refresh_reward_panel() -> void:
    if _reward_panel == null:
        return
    var info_label := _reward_panel.get_node_or_null("InfoLabel") as Label
    if info_label == null:
        return
    if _pending_level_rewards.is_empty():
        info_label.text = "Tidak ada reward level yang pending."
        return
    var lines: Array = []
    var total_coins := 0
    var total_gems := 0
    for r in _pending_level_rewards:
        if not (r is Dictionary):
            continue
        var lvl := int(r.get("level", 0))
        var t := String(r.get("type", ""))
        var coins := _coins_for_reward_type(t)
        var gems := _gems_for_reward_type(t)
        if coins <= 0 and gems <= 0:
            continue
        if coins > 0:
            total_coins += coins
            lines.append("Level " + str(lvl) + ": +" + str(coins) + " coins")
        if gems > 0:
            total_gems += gems
            lines.append("Level " + str(lvl) + ": +" + str(gems) + " gems")
    if lines.is_empty():
        info_label.text = "Reward pending siap di-claim."
    else:
        lines.append("")
        var totals: Array[String] = []
        if total_coins > 0:
            totals.append("+" + str(total_coins) + " coins")
        if total_gems > 0:
            totals.append("+" + str(total_gems) + " gems")
        lines.append("Total: " + ", ".join(totals))
        info_label.text = "\n".join(lines)


func _on_reward_claim_pressed() -> void:
    TransitionManager.play_sfx(&"click")
    if _pending_level_rewards.is_empty():
        _hide_reward_panel()
        return
    var bonus_coins := 0
    var bonus_gems := 0
    for r in _pending_level_rewards:
        if not (r is Dictionary):
            continue
        var t := String(r.get("type", ""))
        bonus_coins += _coins_for_reward_type(t)
        bonus_gems += _gems_for_reward_type(t)
    if bonus_coins > 0:
        _total_coins += bonus_coins
        if _coin_label:
            _coin_label.text = str(_total_coins)
    if bonus_gems > 0:
        _total_gems += bonus_gems
        if _gem_label:
            _gem_label.text = str(_total_gems)
    _pending_level_rewards.clear()
    _save_rewards_and_coins()
    _update_reward_icon()
    _hide_reward_panel()


func _on_reward_close_pressed() -> void:
    TransitionManager.play_sfx(&"click")
    _hide_reward_panel()


func _update_reward_icon() -> void:
    if _reward_icon == null:
        return
    var has_pending := not _pending_level_rewards.is_empty()
    if has_pending:
        _reward_icon.modulate = Color(1, 1, 1, 1)
    else:
        _reward_icon.modulate = Color(0.5, 0.5, 0.5, 1)


func _save_rewards_and_coins() -> void:
    var cfg := ConfigFile.new()
    var err := cfg.load("user://save.cfg")
    if err != OK:
        cfg = ConfigFile.new()
    cfg.set_value("progress", "total_coins", _total_coins)
    cfg.set_value("progress", "total_gems", _total_gems)
    cfg.set_value("rewards", "pending_level_rewards", _pending_level_rewards)
    cfg.save("user://save.cfg")


func refresh_coin_from_save() -> void:
    var coin_hud := get_node_or_null("UI/CoinHUD")
    if coin_hud:
        _coin_label = coin_hud.get_node_or_null("CoinLabel") as Label
    var cfg := ConfigFile.new()
    var err := cfg.load("user://save.cfg")
    if err != OK:
        return
    _total_coins = int(cfg.get_value("progress", "total_coins", 0))
    if _coin_label:
        _coin_label.text = str(_total_coins)


func refresh_gems_from_save() -> void:
    var gem_hud := get_node_or_null("UI/GemHUD")
    if gem_hud:
        _gem_label = gem_hud.get_node_or_null("GemLabel") as Label
    var cfg := ConfigFile.new()
    var err := cfg.load("user://save.cfg")
    if err != OK:
        return
    _total_gems = int(cfg.get_value("progress", "total_gems", 0))
    if _gem_label:
        _gem_label.text = str(_total_gems)


func refresh_missions_badge_from_save() -> void:
    var can_claim: bool = MissionsManagerScript.has_ready_to_claim_missions_in_save()
    if _missions_badge:
        _missions_badge.visible = can_claim
    var daily_button := get_node_or_null("UI/DailyButton") as BaseButton
    if daily_button:
        _refresh_daily_button_style(daily_button)





func _coins_for_reward_type(t: String) -> int:
    match t:
        "coins_50":
            return 50
        "coins_100":
            return 100
        "coins_150":
            return 150
        "coins_200":
            return 200
        "coins_250":
            return 250
        _:
            return 0


func _gems_for_reward_type(t: String) -> int:
    match t:
        "gems_5":
            return 5
        "gems_10":
            return 10
        _:
            return 0


func _refresh_daily_button_style(button: BaseButton) -> void:
    var can_claim: bool = MissionsManagerScript.has_ready_to_claim_missions_in_save()
    var path := "res://assets/tombol/tombol_mission_202x168.png"
    if can_claim:
        path = "res://assets/tombol/tombol_mission_ceklis_202x168.png"
    var tex := load(path) as Texture2D
    if tex == null:
        return
    var sb := StyleBoxTexture.new()
    sb.texture = tex
    button.add_theme_stylebox_override("normal", sb)
    button.add_theme_stylebox_override("hover", sb)
    button.add_theme_stylebox_override("pressed", sb)
    button.add_theme_stylebox_override("focus", sb)
    if _daily_button_animator:
        if can_claim:
            if not _daily_button_animator.is_playing() or _daily_button_animator.current_animation != "wiggle_and_idle":
                _daily_button_animator.play("wiggle_and_idle")
        else:
            if _daily_button_animator.is_playing():
                _daily_button_animator.stop()
            _daily_button_animator.play("RESET")

func _apply_ui_font(node: Node, font: Font) -> void:
    if node is Label:
        (node as Label).add_theme_font_override("font", font)
    elif node is BaseButton:
        (node as BaseButton).add_theme_font_override("font", font)
    for child in node.get_children():
        if child is Node:
            _apply_ui_font(child, font)


func _apply_shop_title_font(lbl: Label, title_font: Font) -> void:
    if lbl == null:
        return
    if title_font:
        lbl.add_theme_font_override("font", title_font)
    lbl.add_theme_color_override("font_color", Color(1, 1, 0, 1))
    lbl.add_theme_constant_override("outline_size", 3)
    lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
    lbl.add_theme_font_size_override("font_size", 36)


func _apply_shop_number_font(lbl: Label, title_font: Font) -> void:
    if lbl == null:
        return
    if title_font:
        lbl.add_theme_font_override("font", title_font)
    lbl.add_theme_constant_override("outline_size", 3)
    lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))


func _init_menu_bgm() -> void:
    _music_toast_panel = get_node_or_null("UI/MusicToastPanel") as Control
    if _music_toast_panel:
        _music_toast = _music_toast_panel.get_node_or_null("MusicToast") as Label
    else:
        _music_toast = get_node_or_null("UI/MusicToast") as Label
    _menu_bgm = get_node_or_null("MenuBGM") as AudioStreamPlayer
    if _menu_bgm == null:
        _menu_bgm = AudioStreamPlayer.new()
        _menu_bgm.name = "MenuBGM"
        add_child(_menu_bgm)
    if not _menu_bgm.finished.is_connected(_on_menu_bgm_finished):
        _menu_bgm.finished.connect(_on_menu_bgm_finished)

    _load_menu_audio_settings()
    _apply_menu_bgm_mix()

    _menu_bgm_paths = _load_menu_bgm_paths()
    if _menu_bgm_paths.is_empty():
        return
    _menu_bgm_index = _consume_next_menu_bgm_index(_menu_bgm_paths.size())
    _play_menu_bgm_index(_menu_bgm_index)


func _load_menu_bgm_paths() -> Array[String]:
    var out: Array[String] = []
    var dir := DirAccess.open(_MENU_BGM_DIR)
    if dir == null:
        return out
    var files := dir.get_files()
    for f in files:
        var fs := String(f)
        var lower := fs.to_lower()
        if not lower.ends_with(".mp3"):
            continue
        if not fs.begins_with(_MENU_BGM_PREFIX):
            continue
        out.append(_MENU_BGM_DIR + "/" + fs)
    out.sort()
    return out


func _load_menu_audio_settings() -> void:
    var cfg := ConfigFile.new()
    var err := cfg.load("user://save.cfg")
    if err != OK:
        _menu_bgm_volume = 0.8
        _menu_bgm_muted = false
        return
    _menu_bgm_volume = float(cfg.get_value("settings", "bgm_volume", 0.8))
    _menu_bgm_muted = bool(cfg.get_value("settings", "bgm_muted", false))


func _apply_menu_bgm_mix() -> void:
    if _menu_bgm == null:
        return
    _menu_bgm.volume_db = (-60.0 if _menu_bgm_muted else _lin_to_db(_menu_bgm_volume))


func _consume_next_menu_bgm_index(list_size: int) -> int:
    if list_size <= 0:
        return 0
    var cfg := ConfigFile.new()
    var err := cfg.load("user://save.cfg")
    if err != OK:
        cfg = ConfigFile.new()
    var last := int(cfg.get_value("settings", "menu_bgm_index", -1))
    var next := (last + 1) % list_size
    cfg.set_value("settings", "menu_bgm_index", next)
    cfg.save("user://save.cfg")
    return next


func _save_menu_bgm_index(i: int) -> void:
    var cfg := ConfigFile.new()
    var err := cfg.load("user://save.cfg")
    if err != OK:
        cfg = ConfigFile.new()
    cfg.set_value("settings", "menu_bgm_index", i)
    cfg.save("user://save.cfg")


func _play_menu_bgm_index(i: int) -> void:
    if _menu_bgm == null:
        return
    if _menu_bgm_paths.is_empty():
        return
    _menu_bgm_index = clampi(i, 0, _menu_bgm_paths.size() - 1)
    var path := _menu_bgm_paths[_menu_bgm_index]
    var stream := load(path) as AudioStream
    if stream == null:
        return
    _menu_bgm.stream = stream
    if not _menu_bgm_muted:
        _menu_bgm.play()
    _show_music_toast(_format_track_name(path))


func _on_menu_bgm_finished() -> void:
    if _menu_bgm_paths.is_empty():
        return
    _menu_bgm_index = (_menu_bgm_index + 1) % _menu_bgm_paths.size()
    _save_menu_bgm_index(_menu_bgm_index)
    _play_menu_bgm_index(_menu_bgm_index)


func _show_music_toast(title: String) -> void:
    if _music_toast == null:
        return
    _music_toast.text = "Backsound: " + title

    var target: CanvasItem = _music_toast
    if _music_toast_panel and _music_toast_panel is CanvasItem:
        target = _music_toast_panel as CanvasItem
        (target as CanvasItem).visible = true
        (target as CanvasItem).modulate = Color(1, 1, 1, 0)
    else:
        _music_toast.visible = true
        _music_toast.modulate = Color(1, 1, 1, 0)

    if _music_toast_tween and _music_toast_tween.is_running():
        _music_toast_tween.kill()
    _music_toast_tween = create_tween()
    _music_toast_tween.tween_property(target, "modulate", Color(1, 1, 1, 1), 0.18)
    _music_toast_tween.tween_interval(2.2)
    _music_toast_tween.tween_property(target, "modulate", Color(1, 1, 1, 0), 0.22)
    _music_toast_tween.tween_callback(func() -> void:
        if _music_toast_panel:
            _music_toast_panel.visible = false
        else:
            _music_toast.visible = false
    )


func _format_track_name(path: String) -> String:
    var base := path.get_file().get_basename()
    base = base.replace("_", " ")
    base = base.replace("-", " ")
    base = base.strip_edges()
    return base


func _lin_to_db(lin: float) -> float:
    var v := clampf(lin, 0.0, 1.0)
    return (-60.0 if v <= 0.0 else 20.0 * log(v) / log(10.0))


func _wire_settings_menu_signals(settings_menu: Node) -> void:
    if settings_menu == null:
        return
    var c_bgm_vol := Callable(self, "_on_settings_bgm_volume_changed")
    if settings_menu.has_signal("bgm_volume_changed") and not settings_menu.is_connected("bgm_volume_changed", c_bgm_vol):
        settings_menu.connect("bgm_volume_changed", c_bgm_vol)
    var c_bgm_mute := Callable(self, "_on_settings_bgm_mute_changed")
    if settings_menu.has_signal("bgm_mute_changed") and not settings_menu.is_connected("bgm_mute_changed", c_bgm_mute):
        settings_menu.connect("bgm_mute_changed", c_bgm_mute)


func _on_settings_bgm_volume_changed(v: float) -> void:
    _menu_bgm_volume = clampf(v, 0.0, 1.0)
    _apply_menu_bgm_mix()


func _on_settings_bgm_mute_changed(muted: bool) -> void:
    _menu_bgm_muted = muted
    if _menu_bgm:
        if muted:
            _menu_bgm.stop()
        else:
            if _menu_bgm.stream != null:
                _menu_bgm.play()
    _apply_menu_bgm_mix()


func _connect_viewport_resize() -> void:
    var vp := get_viewport()
    if vp == null:
        return
    var cb := Callable(self, "_on_viewport_size_changed")
    if not vp.size_changed.is_connected(cb):
        vp.size_changed.connect(cb)
    call_deferred("_on_viewport_size_changed")


func _on_viewport_size_changed() -> void:
    var vp := get_viewport().get_visible_rect().size
    var vp_i := Vector2i(int(vp.x), int(vp.y))
    if vp_i == _last_viewport_size:
        return
    _last_viewport_size = vp_i
    _apply_responsive_layout(vp)


func _apply_responsive_layout(vp: Vector2) -> void:
    if _title_sprite == null:
        return
    _title_sprite.position = Vector2(vp.x * 0.5, vp.y * 0.2777778)
    var scale_factor: float = minf(vp.x / 1024.0, vp.y / 576.0)
    scale_factor = clampf(scale_factor, 0.75, 1.35)
    var s: float = 0.34 * scale_factor
    _title_sprite.scale = Vector2(s, s)
