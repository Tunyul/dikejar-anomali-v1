extends Control



var _pending_level_rewards: Array = []
@onready var _reward_panel: Control = %RewardPanel
@onready var _profile_panel: Control = %ProfilePanel
@onready var _coin_label: Label = %CoinLabel
var _total_coins: int = 0
@onready var _gem_label: Label = %GemLabel
var _total_gems: int = 0
@onready var _reward_icon: TextureRect = %RewardIcon
@onready var _daily_badge: Control = %MissionsBadge
@onready var _avatar_icon: TextureRect = %AvatarIcon

const SKIN_MAP: Dictionary = {
    "skin_basic": "res://assets/profile/profile_basic.png",
    "skin_premium": "res://assets/profile/profile_premium.png",
    "skin_chef": "res://assets/profile/profile_chef.png",
    "skin_firefighter": "res://assets/profile/profile_firefighter.png",
    "skin_caveman": "res://assets/profile/profile_caveman.png",
    "skin_cat_explorer": "res://assets/profile/profile_cat_explorer.png",
    "skin_doctor": "res://assets/profile/profile_doctor.png",
    "skin_robot": "res://assets/profile/profile_robot.png",
    "skin_knight": "res://assets/profile/profile_knight.png",
    "skin_neon": "res://assets/profile/profile_neon.png",
    "skin_shadow": "res://assets/profile/profile_ninja.png",
    "skin_astro_white": "res://assets/profile/profile_astro_white.png",
    "skin_astro_blue": "res://assets/profile/profile_astro_blue.png",
    "skin_pirate": "res://assets/profile/profile_pirate.png",
    "skin_wizard": "res://assets/profile/profile_wizard.png",
    "skin_dragon": "res://assets/profile/profile_dragon.png",
    "skin_superhero": "res://assets/profile/profile_superhero.png",
    "skin_green_dragon": "res://assets/profile/profile_green_dragon.png",
    "skin_superhero_male": "res://assets/profile/profile_superhero_male.png",
    "skin_superhero_female": "res://assets/profile/profile_superhero_female.png",
    "skin_witch": "res://assets/profile/profile_witch.png",
    "skin_pirate_v2": "res://assets/profile/profile_pirate_v2.png",
    "skin_orc": "res://assets/profile/profile_orc.png"
}
const _BANNER_LOCK_PROFILE := "mainmenu_profile_overlay"
const _BANNER_LOCK_REWARD := "mainmenu_reward_overlay"

@export var debug_dummy_stats: bool = false

static var _diamond_icon_tex: Texture2D = null

static func _get_diamond_icon_texture() -> Texture2D:
    if _diamond_icon_tex != null:
        return _diamond_icon_tex
    var tex := load("res://assets/diamond_animation/diamond-1024x1024.png") as Texture2D
    if tex == null:
        _diamond_icon_tex = null
        return null
    _diamond_icon_tex = tex
    return tex

@onready var _title_sprite: Sprite2D = %TitleSprite
@onready var _parallax_bg: ParallaxBackground = %ParallaxBackground
var _flag_id: Texture2D = null
var _flag_en: Texture2D = null
var _flag_zh: Texture2D = null
var _lang_confirm_popup: Node = null
var _lang_popup: PopupMenu = null
var _settings_menu: Node = null

@onready var _play_button: Button = %PlayButton
@onready var _shop_button: Button = %ShopButton
@onready var _settings_button: Button = %SettingsButton
@onready var _player_hud: Control = %PlayerHUD
@onready var _coin_hud: Control = %CoinHUD
@onready var _gem_hud: Control = %GemHUD
@onready var _score_hud: Control = %ScoreHUD
@onready var _coin_hud_bg: Control = get_node_or_null("UI/CoinHUDBackground") as Control
@onready var _gem_hud_bg: Control = get_node_or_null("UI/GemHUDBackground") as Control
@onready var _score_hud_bg: Control = get_node_or_null("UI/ScoreHUDBackground") as Control
@onready var _center_container: Control = get_node_or_null("UI/CenterContainer") as Control
@onready var _buttons_row: Control = %ButtonsRow if has_node("%ButtonsRow") else null
@onready var _daily_button: Button = %DailyButton
@onready var _lang_button: TextureButton = %LanguageButton
@onready var _version_label: Label = %VersionLabel
@onready var _score_label: Label = %ScoreLabel
@onready var _level_label: Label = %LevelLabel
@onready var _xp_bar: ProgressBar = %XPBar
@onready var _xp_label: Label = %XPLabel
@onready var _reward_icon_animator: AnimationPlayer = %RewardIconAnimator if has_node("%RewardIconAnimator") else null
@onready var _season_menu_button: Button = %SeasonMenuButton if has_node("%SeasonMenuButton") else null

var _season_rewards_menu: Node = null
@onready var _inner_avatar_icon: TextureRect = %InnerIcon
@onready var _reward_title: Label = %RewardTitle
@onready var _reward_info_label: Label = %RewardInfoLabel
@onready var _large_inner_avatar_icon: TextureRect = %LargeInnerAvatarIcon
@onready var _gem_icon: TextureRect = %GemIcon
@onready var _profile_panel_inner: Panel = %Panel
@onready var _profile_overlay: ColorRect = %Overlay
@onready var _ground: Node = %Ground if has_node("%Ground") else null
@onready var _ui_layer: CanvasLayer = %UI
@onready var _missions_menu: Node = %DailyMissionsMenu if has_node("%DailyMissionsMenu") else null
@onready var _settings_menu_node: Node = %SettingsMenu if has_node("%SettingsMenu") else null
@onready var _close_profile_button: Button = %CloseProfileButton
@onready var _change_avatar_button: Button = %ChangeAvatarButton
@onready var _change_border_button: Button = %ChangeBorderButton
var _profile_banner_lock_active: bool = false
var _reward_banner_lock_active: bool = false
var _profile_panel_target_scale: Vector2 = Vector2.ONE

func _ready() -> void:
    AdManager.load_banner()
    AdManager.show_banner()
    AdManager.move_banner(false) # Banner di bawah untuk menu
    if Preloader and Preloader.has_method("start_deferred_preloading"):
        Preloader.start_deferred_preloading()

    if _gem_icon:
        var icon_tex := _get_diamond_icon_texture()
        if icon_tex:
            _gem_icon.texture = icon_tex
            _gem_icon.modulate = Color(1, 1, 1, 1)

    if _play_button:
        _play_button.pressed.connect(_on_play_pressed)
    if _shop_button:
        _shop_button.pressed.connect(_on_shop_pressed)
    if _settings_button:
        _settings_button.pressed.connect(_on_settings_pressed)
    if _daily_button:
        _daily_button.pressed.connect(_on_daily_pressed)
    if _xp_bar:
        _xp_bar.gui_input.connect(_on_xp_bar_gui_input)
    if _xp_label:
        _xp_label.gui_input.connect(_on_xp_bar_gui_input)
    if _reward_icon:
        _reward_icon.gui_input.connect(_on_reward_icon_gui_input)
    if _season_menu_button:
        _season_menu_button.pressed.connect(_on_season_menu_pressed)

    _settings_menu = _settings_menu_node
    if _settings_menu == null:
        var packed_settings := load("res://scenes/SettingsMenu.tscn") as PackedScene
        if packed_settings:
            _settings_menu = packed_settings.instantiate()
            (_settings_menu as Node).name = "SettingsMenu"
            add_child(_settings_menu)

    if _settings_menu:
        _wire_settings_menu_signals(_settings_menu as Node)

    if _lang_button:
        _init_language_icons()
        _refresh_language_button()
        _ensure_language_popup()
        _refresh_language_popup_items()
        _lang_button.pressed.connect(_on_language_button_pressed)
        if TransitionManager and TransitionManager.has_signal("language_changed"):
            var cb := Callable(self, "_on_language_changed")
            if not TransitionManager.language_changed.is_connected(cb):
                TransitionManager.language_changed.connect(cb)

    if _coin_hud or _gem_hud or _score_hud or _player_hud:
        var best: int = 0
        var level: int = 1
        var xp: int = 0
        var xp_required: int = 100

        if GameManager:
            _total_coins = int(GameManager.total_coins)
            _total_gems = int(GameManager.total_gems)
            best = int(GameManager.best_score)
            level = int(GameManager.player_level)
            xp = int(GameManager.player_xp)
            xp_required = int(GameManager.player_xp_required)
            _pending_level_rewards = GameManager.pending_level_rewards
        else:
            var cfg := ConfigFile.new()
            var err := cfg.load("user://save.cfg")
            if err == OK:
                _total_coins = int(cfg.get_value("progress", "total_coins", 0))
                _total_gems = int(cfg.get_value("progress", "total_gems", 0))
                best = int(cfg.get_value("progress", "best_score", 0))
                level = int(cfg.get_value("progress", "player_level", 1))
                xp = int(cfg.get_value("progress", "player_xp", 0))
                xp_required = int(cfg.get_value("progress", "player_xp_required", 100))
                var plr_value = cfg.get_value("rewards", "pending_level_rewards", [])
                if plr_value is Array:
                    _pending_level_rewards = plr_value
                else:
                    _pending_level_rewards = []

        if _coin_label:
            _coin_label.text = str(_total_coins)
        if _gem_label:
            _gem_label.text = str(_total_gems)
        if _score_label:
            _score_label.text = str(best)

        if _player_hud:
            # Load equipped cosmetics
            var cosmetics: Dictionary = _get_cosmetics_snapshot()
            var equipped_border := String(cosmetics.get("equipped_border", "border_gold"))
            var equipped_skin := String(cosmetics.get("equipped_skin", "skin_basic"))

            _update_avatar_border(equipped_border)
            _update_avatar_icon(equipped_skin)

            if _level_label:
                _level_label.text = tr("Lv. %d") % level
            if _xp_bar:
                if xp_required <= 0:
                    xp_required = 1
                _xp_bar.max_value = float(xp_required)
                _xp_bar.value = clampf(float(xp), 0.0, float(xp_required))
                # Aktifkan interaksi klik pada XP Bar
                _xp_bar.mouse_filter = Control.MOUSE_FILTER_STOP
                if not _xp_bar.gui_input.is_connected(_on_xp_bar_gui_input):
                    _xp_bar.gui_input.connect(_on_xp_bar_gui_input)
            if _xp_label:
                _xp_label.text = tr("%d/%d XP") % [xp, xp_required]
                # Aktifkan interaksi klik pada XP Label juga agar lebih user-friendly
                _xp_label.mouse_filter = Control.MOUSE_FILTER_STOP
                if not _xp_label.gui_input.is_connected(_on_xp_bar_gui_input):
                    _xp_label.gui_input.connect(_on_xp_bar_gui_input)

            if _reward_icon:
                _update_reward_icon()
                var reward_cb := Callable(self, "_on_reward_icon_gui_input")
                if not _reward_icon.gui_input.is_connected(reward_cb):
                    _reward_icon.gui_input.connect(reward_cb)
            if _avatar_icon:
                _avatar_icon.mouse_filter = Control.MOUSE_FILTER_STOP
                var avatar_cb := Callable(self, "_on_avatar_icon_gui_input")
                if not _avatar_icon.gui_input.is_connected(avatar_cb):
                    _avatar_icon.gui_input.connect(avatar_cb)
        else:
            _reset_main_menu_stats_to_default()

    if debug_dummy_stats and Engine.is_editor_hint():
        _apply_dummy_stats()

    if _daily_button:
        _refresh_daily_button_style(_daily_button)

    if GameManager and GameManager.has_signal("currencies_changed"):
        var cb_curr := Callable(self, "_on_game_currencies_changed")
        if not GameManager.currencies_changed.is_connected(cb_curr):
            GameManager.currencies_changed.connect(cb_curr)
    if GameManager and GameManager.has_signal("season_rewards_changed"):
        var cb_rewards := Callable(self, "_on_season_rewards_changed")
        if not GameManager.season_rewards_changed.is_connected(cb_rewards):
            GameManager.season_rewards_changed.connect(cb_rewards)
    if MissionsManager and MissionsManager.has_signal("ready_to_claim_changed"):
        var cb_ready := Callable(self, "_on_missions_ready_changed")
        if not MissionsManager.ready_to_claim_changed.is_connected(cb_ready):
            MissionsManager.ready_to_claim_changed.connect(cb_ready)

    refresh_missions_badge_from_save()

    if _version_label:
        _version_label.text = ProjectSettings.get_setting("application/config/version", "v0.1.0")

    if _ground:
        if _ground.has_method("set_title_mode"):
            _ground.set_title_mode(true)
        if _ground.has_method("generate_random"):
            _ground.generate_random()
        if _ground.has_method("set_movement_enabled"):
            _ground.set_movement_enabled(true)
        if _ground.has_method("set_speed_limits"):
            _ground.set_speed_limits(0.0, 300.0)
        if _ground.has_method("set_speed"):
            _ground.set_speed(34.0)

    if _parallax_bg:
        if _parallax_bg.has_method("set_movement_enabled"):
            _parallax_bg.set_movement_enabled(true)
        if _parallax_bg.has_method("set_speed"):
            _parallax_bg.set_speed(200.0)

    var ui_font := load("res://assets/font/Fredoka Nunito/Nunito/static/Nunito-Regular.ttf") as Font
    var title_font := load("res://assets/font/Fredoka Nunito/Fredoka/static/Fredoka-Bold.ttf") as Font
    if ui_font:
        if _ui_layer:
            _apply_ui_font(_ui_layer, ui_font)
        else:
            _apply_ui_font(self, ui_font)
    if title_font:
        if _coin_label:
            _apply_shop_number_font(_coin_label, title_font)
        if _gem_label:
            _apply_shop_number_font(_gem_label, title_font)
        if _score_label:
            _apply_shop_number_font(_score_label, title_font)
        if _level_label:
            _apply_shop_number_font(_level_label, title_font)
        if _xp_label:
            _apply_shop_number_font(_xp_label, title_font)
        if _reward_title:
            _apply_shop_title_font(_reward_title, title_font)
        if _reward_info_label:
            _apply_ui_font(_reward_info_label, ui_font)

    _connect_viewport_resize()
    _init_menu_bgm()

func _exit_tree() -> void:
    _release_profile_banner_lock()
    _release_reward_banner_lock()


func _init_language_icons() -> void:
    if DisplayServer.get_name() == "headless":
        return
    if _flag_id == null:
        _flag_id = _load_flag_texture("res://assets/icon/icon_flag_INA.png")
    if _flag_en == null:
        _flag_en = _load_flag_texture("res://assets/icon/icon_flag_US.png")
    if _flag_zh == null:
        _flag_zh = _load_flag_texture("res://assets/icon/icon_flag_CN.png")


func _load_flag_texture(path: String) -> Texture2D:
    if not ResourceLoader.exists(path):
        return null
    return load(path) as Texture2D


func _normalize_locale(locale: String) -> String:
    var lc := locale.strip_edges().to_lower()
    if lc.begins_with("en"):
        return "en"
    if lc.begins_with("id"):
        return "id"
    if lc.begins_with("zh"):
        return "zh"
    return "en"


func _get_current_language() -> String:
    if TransitionManager and TransitionManager.has_method("get_language"):
        return _normalize_locale(str(TransitionManager.get_language()))
    return _normalize_locale(str(TranslationServer.get_locale()))


func _refresh_language_button(_locale: String = "") -> void:
    if _lang_button == null:
        return
    var lc := (_normalize_locale(_locale) if _locale != "" else _get_current_language())
    var tex: Texture2D = null
    if lc == "id":
        tex = _flag_id
    elif lc == "zh":
        tex = _flag_zh
    else:
        tex = _flag_en
    if tex:
        _lang_button.texture_normal = tex
        _lang_button.texture_pressed = tex
        _lang_button.texture_hover = tex
        _lang_button.texture_disabled = tex


func _on_language_changed(locale: String) -> void:
    _refresh_language_button(locale)
    _refresh_language_popup_items(locale)
    _refresh_player_hud_locale_texts()
    _refresh_profile_panel() # Update teks Profile Panel jika sedang terbuka


func _on_language_button_pressed() -> void:
    TransitionManager.play_sfx(&"click")
    _show_language_popup()


func _ensure_language_popup() -> void:
    if _lang_popup != null and is_instance_valid(_lang_popup):
        return

    _lang_popup = PopupMenu.new()
    _lang_popup.name = "LanguagePopup"
    _lang_popup.hide_on_item_selection = true
    _lang_popup.hide_on_checkable_item_selection = true
    _lang_popup.transparent = true
    _lang_popup.id_pressed.connect(_on_language_popup_id_pressed)

    if _ui_layer:
        _ui_layer.add_child(_lang_popup)
    else:
        add_child(_lang_popup)


func _refresh_language_popup_items(_locale: String = "") -> void:
    if _lang_popup == null or not is_instance_valid(_lang_popup):
        return

    var lc := (_normalize_locale(_locale) if _locale != "" else _get_current_language())

    _lang_popup.clear()

    if _flag_id:
        _lang_popup.add_icon_item(_flag_id, _locale_to_display_name("id"), 0)
    else:
        _lang_popup.add_item(_locale_to_display_name("id"), 0)
    if _flag_en:
        _lang_popup.add_icon_item(_flag_en, _locale_to_display_name("en"), 1)
    else:
        _lang_popup.add_item(_locale_to_display_name("en"), 1)
    if _flag_zh:
        _lang_popup.add_icon_item(_flag_zh, _locale_to_display_name("zh"), 2)
    else:
        _lang_popup.add_item(_locale_to_display_name("zh"), 2)

    for i in range(_lang_popup.item_count):
        _lang_popup.set_item_as_radio_checkable(i, true)
        _lang_popup.set_item_checked(i, false)

    var checked_index := 1
    if lc == "id":
        checked_index = 0
    elif lc == "zh":
        checked_index = 2
    _lang_popup.set_item_checked(checked_index, true)


func _show_language_popup() -> void:
    _ensure_language_popup()
    _refresh_language_popup_items()
    if _lang_popup == null or not is_instance_valid(_lang_popup):
        return
    if _lang_button == null or not is_instance_valid(_lang_button):
        return

    if _lang_popup.visible:
        _lang_popup.hide()
        return

    var rect := _lang_button.get_global_rect()
    var pos := rect.position + Vector2(0.0, rect.size.y)

    var vp := get_viewport()
    var vp_rect := (vp.get_visible_rect() if vp else Rect2(Vector2.ZERO, Vector2(1920, 1080)))
    var popup_min_size: Vector2 = Vector2(220.0, 160.0)
    pos.x = clampf(pos.x, 8.0, vp_rect.size.x - popup_min_size.x - 8.0)
    pos.y = clampf(pos.y, 8.0, vp_rect.size.y - popup_min_size.y - 8.0)

    _lang_popup.popup(Rect2i(Vector2i(int(pos.x), int(pos.y)), Vector2i(1, 1)))


func _on_language_popup_id_pressed(id: int) -> void:
    var locale := "en"
    match id:
        0:
            locale = "id"
        1:
            locale = "en"
        2:
            locale = "zh"
        _:
            locale = "en"
    if TransitionManager and TransitionManager.has_method("set_language"):
        TransitionManager.set_language(locale)
    _refresh_language_button(locale)
    _refresh_language_popup_items(locale)


func _locale_to_display_name(locale: String) -> String:
    var lc := _normalize_locale(locale)
    if lc == "id":
        return tr("Indonesian")
    if lc == "zh":
        return tr("Chinese")
    return tr("English")


func _show_language_confirm(target_locale: String) -> void:
    if _ui_layer == null:
        if TransitionManager and TransitionManager.has_method("set_language"):
            TransitionManager.set_language(target_locale)
        _refresh_language_button(target_locale)
        return

    if _lang_confirm_popup and is_instance_valid(_lang_confirm_popup):
        _lang_confirm_popup.queue_free()
        _lang_confirm_popup = null

    var confirm_scene := load("res://scenes/ConfirmPanel.tscn") as PackedScene
    if confirm_scene == null:
        if TransitionManager and TransitionManager.has_method("set_language"):
            TransitionManager.set_language(target_locale)
        _refresh_language_button(target_locale)
        return

    var popup := confirm_scene.instantiate()
    _lang_confirm_popup = popup
    _ui_layer.add_child(popup)

    if popup is Control:
        call_deferred("_position_language_confirm_popup", popup as Control)

    var msg := popup.get_node("%Message") as Label
    if msg:
        msg.text = tr("Change language to %s?") % [_locale_to_display_name(target_locale)]

    var yes := popup.get_node("%YesButton") as BaseButton
    var no := popup.get_node("%NoButton") as BaseButton

    if yes:
        yes.pressed.connect(func():
            if is_instance_valid(popup):
                popup.queue_free()
            if TransitionManager and TransitionManager.has_method("set_language"):
                TransitionManager.set_language(target_locale)
            _refresh_language_button(target_locale)
        )
    if no:
        no.pressed.connect(func():
            if is_instance_valid(popup):
                popup.queue_free()
        )


func _position_language_confirm_popup(c: Control) -> void:
    if c == null or not is_instance_valid(c):
        return
    await get_tree().process_frame
    if c == null or not is_instance_valid(c):
        return

    var vp: Viewport = get_viewport()
    var vp_rect: Rect2 = vp.get_visible_rect()
    var vp_size: Vector2 = vp_rect.size

    var title_bottom := vp_size.y * 0.22
    if _title_sprite and _title_sprite.texture:
        var sz := _title_sprite.texture.get_size() * _title_sprite.scale
        title_bottom = _title_sprite.global_position.y + sz.y * 0.5

    var popup_size := c.size
    if popup_size == Vector2.ZERO:
        popup_size = c.get_combined_minimum_size()

    var margin := 24.0
    var desired_center_y: float = maxf(vp_size.y * 0.5, title_bottom + margin + popup_size.y * 0.5)
    var desired_top_left := Vector2(vp_size.x * 0.5 - popup_size.x * 0.5, desired_center_y - popup_size.y * 0.5)

    var clamp_margin := 16.0
    desired_top_left.x = clampf(desired_top_left.x, clamp_margin, vp_size.x - popup_size.x - clamp_margin)
    desired_top_left.y = clampf(desired_top_left.y, clamp_margin, vp_size.y - popup_size.y - clamp_margin)

    c.global_position = desired_top_left


func _reset_main_menu_stats_to_default() -> void:
    _total_coins = 0
    _total_gems = 0
    _pending_level_rewards = []

    if _coin_label:
        _coin_label.text = "0"

    if _gem_label:
        _gem_label.text = "0"

    if _score_label:
        _score_label.text = "0"

    if _level_label:
        _level_label.text = "Lv 1"
    if _xp_bar:
        _xp_bar.max_value = 100.0
        _xp_bar.value = 0.0
    if _xp_label:
        _xp_label.text = "0/100 XP"

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

    if _score_label:
        _score_label.text = str(dummy_big)

    if _level_label:
        _level_label.text = "Lv 99"

    if _xp_bar:
        _xp_bar.max_value = 1234567.0
        _xp_bar.value = _xp_bar.max_value * 0.5

    if _xp_label:
        _xp_label.text = "123456/1234567 XP"


func _refresh_player_hud_locale_texts() -> void:
    var level: int = 1
    var xp: int = 0
    var xp_required: int = 100

    if GameManager:
        level = int(GameManager.player_level)
        xp = int(GameManager.player_xp)
        xp_required = int(GameManager.player_xp_required)
    else:
        var cfg := ConfigFile.new()
        if cfg.load("user://save.cfg") == OK:
            level = int(cfg.get_value("progress", "player_level", 1))
            xp = int(cfg.get_value("progress", "player_xp", 0))
            xp_required = int(cfg.get_value("progress", "player_xp_required", 100))

    if xp_required <= 0:
        xp_required = 1

    if _level_label:
        _level_label.text = tr("Lv. %d") % level
    if _xp_bar:
        _xp_bar.max_value = float(xp_required)
        _xp_bar.value = clampf(float(xp), 0.0, float(xp_required))
    if _xp_label:
        _xp_label.text = tr("%d/%d XP") % [xp, xp_required]


func _on_season_menu_pressed() -> void:
    TransitionManager.play_sfx(&"click")
    _show_season_rewards_menu()

func _on_reward_icon_gui_input(event: InputEvent) -> void:
    if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch and event.pressed):
        get_viewport().set_input_as_handled()
        TransitionManager.play_sfx(&"click")
        _show_season_rewards_menu()

func _on_xp_bar_gui_input(event: InputEvent) -> void:
    if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch and event.pressed):
        get_viewport().set_input_as_handled()
        TransitionManager.play_sfx(&"click")
        _show_season_rewards_menu()

func _show_season_rewards_menu() -> void:
    print("Mencoba menampilkan season rewards menu...")
    if _season_rewards_menu == null or not is_instance_valid(_season_rewards_menu):
        var packed_scene = load("res://scenes/SeasonRewardsMenu.tscn")
        if packed_scene:
            _season_rewards_menu = packed_scene.instantiate()
            _season_rewards_menu.name = "SeasonRewardsMenu"

            # Tambahkan ke root pohon scene agar selalu berada di atas menu utama
            get_tree().root.add_child(_season_rewards_menu)
            print("SeasonRewardsMenu diinstansiasi dan ditambahkan ke root.")
        else:
            push_error("Gagal memuat SeasonRewardsMenu.tscn!")

    if _season_rewards_menu and _season_rewards_menu.has_method("show_menu"):
        # Pastikan menu terlihat dan memproses input
        _season_rewards_menu.visible = true
        _season_rewards_menu.show_menu()
        print("Panggil show_menu() pada SeasonRewardsMenu.")

func _on_avatar_icon_gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        get_viewport().set_input_as_handled()
        TransitionManager.play_sfx(&"click")
        _show_profile_panel()
    elif event is InputEventScreenTouch and event.pressed:
        get_viewport().set_input_as_handled()
        TransitionManager.play_sfx(&"click")
        _show_profile_panel()

func _show_profile_panel() -> void:
    if _profile_panel == null:
        return
    _acquire_profile_banner_lock()

    var inner_panel := _profile_panel_inner
    if inner_panel == null:
        _release_profile_banner_lock()
        return

    var close_btn := _close_profile_button
    if close_btn and not close_btn.pressed.is_connected(_hide_profile_panel):
        close_btn.pressed.connect(_hide_profile_panel)

    var change_avatar_btn := _change_avatar_button
    if change_avatar_btn and not change_avatar_btn.pressed.is_connected(_on_change_avatar_pressed):
        change_avatar_btn.pressed.connect(_on_change_avatar_pressed)

    var change_border_btn := _change_border_button
    if change_border_btn and not change_border_btn.pressed.is_connected(_on_change_border_pressed):
        change_border_btn.pressed.connect(_on_change_border_pressed)

    _refresh_profile_panel()

    # Animasi buka panel
    _profile_panel.visible = true
    var overlay := _profile_overlay
    if overlay:
        overlay.modulate.a = 0.0

    inner_panel.modulate.a = 0.0
    inner_panel.scale = _profile_panel_target_scale * 0.8
    inner_panel.pivot_offset = inner_panel.size / 2

    var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    if overlay:
        tw.tween_property(overlay, "modulate:a", 1.0, 0.3)
    tw.tween_property(inner_panel, "modulate:a", 1.0, 0.3)
    tw.tween_property(inner_panel, "scale", _profile_panel_target_scale, 0.3)

func _on_change_avatar_pressed() -> void:
    TransitionManager.play_sfx(&"click")
    var cosmetics: Dictionary = _get_cosmetics_snapshot()
    var owned_skins: Array = cosmetics.get("owned_skins", ["skin_basic"])
    var current_skin := String(cosmetics.get("equipped_skin", "skin_basic"))

    if owned_skins.size() <= 1:
        _on_shop_pressed()
        return

    # Cycle to next owned skin
    var idx := owned_skins.find(current_skin)
    var next_idx := (idx + 1) % owned_skins.size()
    var next_skin := String(owned_skins[next_idx])

    cosmetics["equipped_skin"] = next_skin
    _set_cosmetics_snapshot(cosmetics)

    _update_avatar_icon(next_skin)
    _refresh_profile_panel()

    # Feedback visual tombol
    var btn := _change_avatar_button
    if btn:
        var btn_tw := create_tween()
        btn_tw.tween_property(btn, "scale", Vector2(1.1, 1.1), 0.05)
        btn_tw.tween_property(btn, "scale", Vector2.ONE, 0.1)

func _on_change_border_pressed() -> void:
    TransitionManager.play_sfx(&"click")
    var cosmetics: Dictionary = _get_cosmetics_snapshot()
    var owned_borders: Array = cosmetics.get("owned_borders", [])
    var current_border := String(cosmetics.get("equipped_border", ""))

    # Buat list pilihan unik
    var selection_list: Array = [""] # Opsi tanpa border (Basic)

    # Tambahkan border premium yang sudah dibeli
    for b in owned_borders:
        var b_str = String(b)
        if b_str != "" and not selection_list.has(b_str):
            selection_list.append(b_str)

    # Cycle ke border berikutnya
    var idx := selection_list.find(current_border)
    if idx == -1: idx = 0

    var next_idx := (idx + 1) % selection_list.size()
    var next_border := String(selection_list[next_idx])

    cosmetics["equipped_border"] = next_border
    _set_cosmetics_snapshot(cosmetics)

    # Update visual
    _update_avatar_border(next_border)
    _refresh_profile_panel()

    # Feedback visual tombol
    var btn := %ChangeBorderButton
    if btn:
        var btn_tw := create_tween()
        btn_tw.tween_property(btn, "scale", Vector2(1.1, 1.1), 0.05)
        btn_tw.tween_property(btn, "scale", Vector2.ONE, 0.1)

func _hide_profile_panel() -> void:
    TransitionManager.play_sfx(&"click")
    if _profile_panel:
        var inner_panel := _profile_panel_inner
        var overlay := _profile_overlay

        var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
        if overlay:
            tw.tween_property(overlay, "modulate:a", 0.0, 0.2)
        if inner_panel:
            tw.tween_property(inner_panel, "modulate:a", 0.0, 0.2)
            tw.tween_property(inner_panel, "scale", _profile_panel_target_scale * 0.8, 0.2)
        tw.chain().tween_callback(func():
            _profile_panel.visible = false
            _release_profile_banner_lock()
        )
    else:
        _release_profile_banner_lock()

func _refresh_profile_panel() -> void:
    if _profile_panel == null: return

    var inner_panel := _profile_panel_inner
    if inner_panel == null: return

    var name_label := %NameLabel
    var lv_label := %LevelValue
    var xp_label := %XPValue
    var score_label := %ScoreValue
    var large_avatar := %LargeAvatarIcon
    var title_label := %ProfileTitle
    var change_avatar_btn := %ChangeAvatarButton
    var change_border_btn := %ChangeBorderButton
    var close_btn := %CloseProfileButton

    if title_label:
        title_label.text = tr("PROFIL PEMAIN")
    if change_avatar_btn:
        change_avatar_btn.text = tr("GANTI AVATAR")
    if change_border_btn:
        change_border_btn.text = tr("GANTI BORDER")
    if close_btn:
        close_btn.text = tr("TUTUP")

    var player_name := "Player"
    var level := 1
    var xp := 0
    var xp_req := 100
    var best_score := 0

    if GameManager:
        level = int(GameManager.player_level)
        xp = int(GameManager.player_xp)
        xp_req = int(GameManager.player_xp_required)
        best_score = int(GameManager.best_score)
    else:
        var cfg := ConfigFile.new()
        var err := cfg.load("user://save.cfg")
        if err == OK:
            player_name = String(cfg.get_value("profile", "name", "Player"))
            level = int(cfg.get_value("progress", "player_level", 1))
            xp = int(cfg.get_value("progress", "player_xp", 0))
            xp_req = int(cfg.get_value("progress", "player_xp_required", 100))
            best_score = int(cfg.get_value("progress", "best_score", 0))

    if name_label:
        name_label.text = player_name
    if lv_label:
        lv_label.text = tr("Lv. %d") % level
    if xp_label:
        xp_label.text = tr("%d/%d XP") % [xp, xp_req]
    if score_label:
        score_label.text = str(best_score)

    if large_avatar:
        var cosmetics: Dictionary = _get_cosmetics_snapshot()
        var equipped_skin := String(cosmetics.get("equipped_skin", "skin_basic"))
        var equipped_border := String(cosmetics.get("equipped_border", ""))

        var icon_path: String = SKIN_MAP.get(equipped_skin, "res://assets/profile/profile_basic.png")

        var inner := _large_inner_avatar_icon
        if inner:
            inner.texture = load(icon_path) as Texture2D

        _apply_border_to_icon(large_avatar, equipped_border, _large_inner_avatar_icon)

func _on_play_pressed() -> void:
    TransitionManager.play_sfx(&"click")
    print("PlayButton ditekan")
    # Stop BGM before transition to prevent double BGM in LoadingScreen and Main gameplay
    if TransitionManager and TransitionManager.has_method("stop_bgm"):
        TransitionManager.stop_bgm()

    if _ui_layer:
        _ui_layer.visible = false
    visible = false
    process_mode = Node.PROCESS_MODE_DISABLED
    if Preloader and Preloader.has_method("set_next_scene"):
        Preloader.set_next_scene("res://scenes/Main.tscn")
    await TransitionManager.play_transition_to_scene("res://scenes/LoadingScreen.tscn")

func _on_shop_pressed() -> void:
    TransitionManager.play_sfx(&"click")
    if TransitionManager.has_method("fade_to_scene"):
        TransitionManager.fade_to_scene("res://scenes/ShopMenu.tscn")
    else:
        process_mode = Node.PROCESS_MODE_DISABLED
        get_tree().change_scene_to_file("res://scenes/ShopMenu.tscn")

func _on_settings_pressed() -> void:
    TransitionManager.play_sfx(&"click")
    var settings_menu := _settings_menu
    if settings_menu == null or not is_instance_valid(settings_menu):
        settings_menu = _settings_menu_node

    if settings_menu == null:
        var packed := load("res://scenes/SettingsMenu.tscn") as PackedScene
        if packed:
            settings_menu = packed.instantiate()
            (settings_menu as Node).name = "SettingsMenu"
            if _ui_layer:
                _ui_layer.add_child(settings_menu)
            else:
                add_child(settings_menu)

    _settings_menu = settings_menu
    if settings_menu:
        _wire_settings_menu_signals(settings_menu as Node)
        if settings_menu.has_method("show_overlay"):
            settings_menu.call_deferred("show_overlay")
        else:
            (settings_menu as CanvasItem).visible = true

func _on_daily_pressed() -> void:
    TransitionManager.play_sfx(&"click")
    var missions_menu := _missions_menu
    if missions_menu == null or not is_instance_valid(missions_menu):
        # Check if old instance exists in UI layer or self
        var old_menu: Node = null
        if _ui_layer and _ui_layer.has_node("DailyMissionsMenu"):
            old_menu = _ui_layer.get_node("DailyMissionsMenu")
        elif has_node("DailyMissionsMenu"):
            old_menu = get_node("DailyMissionsMenu")

        if old_menu:
            old_menu.queue_free()

        var packed := load("res://scenes/DailyMissionsMenu.tscn") as PackedScene
        if packed:
            missions_menu = packed.instantiate()
            (missions_menu as Node).name = "DailyMissionsMenu"
            if _ui_layer:
                _ui_layer.add_child(missions_menu)
            else:
                add_child(missions_menu)

    _missions_menu = missions_menu
    if missions_menu:
        if missions_menu.has_method("show_overlay"):
            missions_menu.call_deferred("show_overlay")
        elif missions_menu is CanvasItem:
            missions_menu.visible = true
    call_deferred("refresh_missions_badge_from_save")

func _show_reward_panel() -> void:
    if _reward_panel == null:
        return
    _acquire_reward_banner_lock()

    var claim_btn := %RewardClaimButton
    var close_btn := %RewardCloseButton
    if claim_btn and not claim_btn.pressed.is_connected(_on_reward_claim_pressed):
        claim_btn.pressed.connect(_on_reward_claim_pressed)
    if close_btn and not close_btn.pressed.is_connected(_on_reward_close_pressed):
        close_btn.pressed.connect(_on_reward_close_pressed)

    _refresh_reward_panel()
    _reward_panel.visible = true


func _hide_reward_panel() -> void:
    if _reward_panel:
        _reward_panel.visible = false
    _release_reward_banner_lock()

func _acquire_profile_banner_lock() -> void:
    if _profile_banner_lock_active:
        return
    if AdManager and AdManager.has_method("acquire_banner_lock"):
        AdManager.acquire_banner_lock(_BANNER_LOCK_PROFILE)
    _profile_banner_lock_active = true

func _release_profile_banner_lock() -> void:
    if not _profile_banner_lock_active:
        return
    if AdManager and AdManager.has_method("release_banner_lock"):
        AdManager.release_banner_lock(_BANNER_LOCK_PROFILE)
    _profile_banner_lock_active = false

func _acquire_reward_banner_lock() -> void:
    if _reward_banner_lock_active:
        return
    if AdManager and AdManager.has_method("acquire_banner_lock"):
        AdManager.acquire_banner_lock(_BANNER_LOCK_REWARD)
    _reward_banner_lock_active = true

func _release_reward_banner_lock() -> void:
    if not _reward_banner_lock_active:
        return
    if AdManager and AdManager.has_method("release_banner_lock"):
        AdManager.release_banner_lock(_BANNER_LOCK_REWARD)
    _reward_banner_lock_active = false


func _refresh_reward_panel() -> void:
    if _reward_panel == null:
        return
    var info_label := _reward_info_label
    if info_label == null:
        return
    if _pending_level_rewards.is_empty():
        info_label.text = tr("No pending level rewards.")
        return
    var lines: Array = []
    var total_coins := 0
    var total_gems := 0
    for r in _pending_level_rewards:
        if not (r is Dictionary):
            continue
        var lvl := int(r.get("level", 0))
        var t := String(r.get("type", ""))
        var amt := int(r.get("amount", 0))

        if amt <= 0:
            # Fallback for old save data
            var coins := _coins_for_reward_type(t)
            var gems := _gems_for_reward_type(t)
            if coins > 0:
                total_coins += coins
                lines.append(tr("Level %d: +%d coins") % [lvl, coins])
            elif gems > 0:
                total_gems += gems
                lines.append(tr("Level %d: +%d gems") % [lvl, gems])
            continue

        if t == "coins":
            total_coins += amt
            lines.append(tr("Level %d: +%d coins") % [lvl, amt])
        elif t == "gems":
            total_gems += amt
            lines.append(tr("Level %d: +%d gems") % [lvl, amt])
    if lines.is_empty():
        info_label.text = tr("Pending rewards ready to claim.")
    else:
        lines.append("")
        var totals: Array[String] = []
        if total_coins > 0:
            totals.append("+%d coins" % total_coins)
        if total_gems > 0:
            totals.append("+%d gems" % total_gems)
        lines.append(tr("Total: %s") % [", ".join(totals)])
        info_label.text = "\n".join(lines)


func _on_reward_claim_pressed() -> void:
    TransitionManager.play_sfx(&"click")
    var did_claim := false
    if GameManager and GameManager.has_method("claim_all_pending_rewards"):
        var result: Dictionary = GameManager.claim_all_pending_rewards()
        if bool(result.get("ok", false)):
            var currencies: Dictionary = result.get("currencies", {})
            _total_coins = int(currencies.get("coins", _total_coins))
            _total_gems = int(currencies.get("gems", _total_gems))
            did_claim = true
            if _coin_label:
                _coin_label.text = str(_total_coins)
            if _gem_label:
                _gem_label.text = str(_total_gems)
            _refresh_currency_display()
    if did_claim:
        _refresh_currency_display()
        _hide_reward_panel()


func _refresh_currency_display() -> void:
    if GameManager:
        _total_coins = int(GameManager.total_coins)
        _total_gems = int(GameManager.total_gems)
        _pending_level_rewards = GameManager.pending_level_rewards
    else:
        var cfg := ConfigFile.new()
        var err := cfg.load("user://save.cfg")
        if err == OK:
            _total_coins = int(cfg.get_value("progress", "total_coins", 0))
            _total_gems = int(cfg.get_value("progress", "total_gems", 0))
            var plr_value = cfg.get_value("rewards", "pending_level_rewards", [])
            if plr_value is Array:
                _pending_level_rewards = plr_value
            else:
                _pending_level_rewards = []
    if _coin_label:
        _coin_label.text = str(_total_coins)
    if _gem_label:
        _gem_label.text = str(_total_gems)
    _update_reward_icon()


func _on_reward_close_pressed() -> void:
    TransitionManager.play_sfx(&"click")
    _hide_reward_panel()


func _update_reward_icon() -> void:
    if _reward_icon == null:
        return

    var has_rewards := not _pending_level_rewards.is_empty()
    _reward_icon.visible = has_rewards

    if _reward_icon_animator:
        if has_rewards:
            if _reward_icon_animator.has_animation("wiggle"):
                if not _reward_icon_animator.is_playing() or _reward_icon_animator.current_animation != "wiggle":
                    _reward_icon_animator.play("wiggle")
        else:
            _reward_icon_animator.stop()

func _update_avatar_border(border_id: String) -> void:
    _apply_border_to_icon(_avatar_icon, border_id, _inner_avatar_icon)

func _apply_border_to_icon(icon_node: TextureRect, border_id: String, inner_icon: TextureRect = null) -> void:
    if icon_node == null:
        return

    # If inner_icon not provided, try to find it
    if inner_icon == null:
        inner_icon = icon_node.get_node_or_null("InnerIcon") as TextureRect

    if inner_icon == null:
        # Ensure we are modifying the icon_node correctly
        inner_icon = TextureRect.new()
        inner_icon.name = "InnerIcon"
        inner_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        inner_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        inner_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 0)
        inner_icon.show_behind_parent = true
        icon_node.add_child(inner_icon)

    var border_tex_path := ""
    var padding := 5 # Default padding

    match border_id:
        "border_gold_premium":
            border_tex_path = "res://assets/border/border_gold_premium.png"
            padding = 5
        "border_silver_premium":
            border_tex_path = "res://assets/border/border_silver_premium.png"
            padding = 5
        "border_neon_v2":
            border_tex_path = "res://assets/border/border_neon_v2.png"
            padding = 5
        "border_shadow_v2":
            border_tex_path = "res://assets/border/border_shadow_v2.png"
            padding = 5
        "border_fire":
            border_tex_path = "res://assets/border/border_fire.png"
            padding = 5
        "border_kraken":
            border_tex_path = "res://assets/border/border_kraken.png"
            padding = 5
        "border_nature":
            border_tex_path = "res://assets/border/border_nature.png"
            padding = 5
        "border_cyber":
            border_tex_path = "res://assets/border/border_cyber.png"
            padding = 5
        "border_gold":
            border_tex_path = "res://assets/border/border_gold_premium.png"
            padding = 5
        "border_silver":
            border_tex_path = "res://assets/border/border_silver_premium.png"
            padding = 5
        "border_bronze":
            border_tex_path = "res://assets/border/border_fire.png"
            padding = 5
        "border_white":
            border_tex_path = "res://assets/border/border_shadow_v2.png"
            padding = 5
        _:
            border_tex_path = ""

    if border_tex_path != "" and not ResourceLoader.exists(border_tex_path):
        border_tex_path = ""

    if border_tex_path == "":
        icon_node.texture = null
        if inner_icon:
            inner_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 0)
    else:
        var tex = load(border_tex_path) as Texture2D
        if tex:
            icon_node.texture = tex
            if inner_icon:
                inner_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, padding)
        else:
            icon_node.texture = null
            if inner_icon:
                inner_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 0)

func _update_avatar_icon(skin_id: String) -> void:
    if _avatar_icon == null:
        return
    var inner_icon := _inner_avatar_icon
    if inner_icon == null: return

    var icon_path: String = SKIN_MAP.get(skin_id, "res://assets/profile/profile_basic.png")
    var tex := load(icon_path) as Texture2D
    if tex:
        inner_icon.texture = tex


func _wire_settings_menu_signals(settings_menu: Node) -> void:
    if settings_menu == null:
        return

    # Connect overlay_closed
    var close_cb := Callable(self, "_on_settings_close")
    if settings_menu.has_signal("overlay_closed"):
        if not settings_menu.is_connected("overlay_closed", close_cb):
            settings_menu.connect("overlay_closed", close_cb)

    # Connect bgm_volume_changed
    if settings_menu.has_signal("bgm_volume_changed"):
        var vol_cb := func(v: float):
            if typeof(GameManager) != TYPE_NIL:
                GameManager.set_bgm_volume(v)
            elif TransitionManager and TransitionManager.has_method("set_bgm_volume"):
                TransitionManager.set_bgm_volume(v)
        if not settings_menu.is_connected("bgm_volume_changed", vol_cb):
            settings_menu.connect("bgm_volume_changed", vol_cb)

    # Connect bgm_mute_changed
    if settings_menu.has_signal("bgm_mute_changed"):
        var mute_cb := func(m: bool):
            if typeof(GameManager) != TYPE_NIL:
                GameManager.set_bgm_muted(m)
            elif TransitionManager and TransitionManager.has_method("set_bgm_muted"):
                TransitionManager.set_bgm_muted(m)
        if not settings_menu.is_connected("bgm_mute_changed", mute_cb):
            settings_menu.connect("bgm_mute_changed", mute_cb)


func _on_settings_close() -> void:
    _refresh_currency_display()
    _init_language_icons()
    _refresh_language_button()


func _apply_ui_font(node: Node, font: Font) -> void:
    if node is Label:
        (node as Label).add_theme_font_override("font", font)
    elif node is BaseButton:
        (node as BaseButton).add_theme_font_override("font", font)

    # Jangan rekursif ke dalam menu lain yang merupakan scene terpisah
    for child in node.get_children():
        if child is Node:
            if child.scene_file_path != "":
                continue
            _apply_ui_font(child, font)


func _apply_shop_number_font(lbl: Label, title_font: Font) -> void:
    if lbl == null: return
    lbl.add_theme_font_override("font", title_font)


func _apply_shop_title_font(lbl: Label, title_font: Font) -> void:
    if lbl == null: return
    lbl.add_theme_font_override("font", title_font)


func _connect_viewport_resize() -> void:
    var vp := get_viewport()
    if vp == null:
        return
    var cb := Callable(self, "_on_viewport_size_changed")
    if not vp.size_changed.is_connected(cb):
        vp.size_changed.connect(cb)
    call_deferred("_on_viewport_size_changed")


func _on_viewport_size_changed() -> void:
    var vp := get_viewport()
    if vp == null:
        return
    var vp_size := vp.get_visible_rect().size
    _apply_mainmenu_responsive_layout(vp_size)


func _apply_mainmenu_responsive_layout(vp_size: Vector2) -> void:
    var safe := Rect2(Vector2.ZERO, vp_size)
    if OS.has_feature("android") or OS.has_feature("ios"):
        var sa := DisplayServer.get_display_safe_area()
        if sa.size.x > 0 and sa.size.y > 0:
            safe = Rect2(Vector2(sa.position), Vector2(sa.size))

    var inset_left := safe.position.x
    var inset_top := safe.position.y
    var inset_right := maxf(vp_size.x - (safe.position.x + safe.size.x), 0.0)
    var inset_bottom := maxf(vp_size.y - (safe.position.y + safe.size.y), 0.0)
    var use_horizontal_safe_inset := not OS.has_feature("android")
    var horizontal_left := inset_left if use_horizontal_safe_inset else 0.0
    var horizontal_right := inset_right if use_horizontal_safe_inset else 0.0

    if _center_container:
        _center_container.offset_top = inset_top
        _center_container.offset_bottom = -inset_bottom

    if _buttons_row:
        var btn_scale := clampf(vp_size.x / 1400.0, 0.84, 1.0)
        _buttons_row.scale = Vector2.ONE * btn_scale
        _buttons_row.pivot_offset = _buttons_row.size * 0.5

    var hud_scale := clampf(vp_size.x / 1024.0, 0.86, 1.0)
    _set_hud_row_layout(_coin_hud_bg, _coin_hud, horizontal_left + 20.0, inset_top + 74.0, hud_scale)
    _set_hud_row_layout(_gem_hud_bg, _gem_hud, horizontal_left + 20.0, inset_top + 138.0, hud_scale)
    _set_hud_row_layout(_score_hud_bg, _score_hud, horizontal_left + 20.0, inset_top + 202.0, hud_scale)

    if _player_hud:
        _player_hud.offset_left = horizontal_left + 10.0
        _player_hud.offset_top = inset_top + 10.0
        _player_hud.offset_right = horizontal_left + 400.0
        _player_hud.offset_bottom = inset_top + 66.0

    if _daily_button:
        _daily_button.offset_left = -95.0 - horizontal_right
        _daily_button.offset_right = -20.0 - horizontal_right
        _daily_button.offset_top = 20.0 + inset_top
        _daily_button.offset_bottom = 75.0 + inset_top

    if _lang_button:
        _lang_button.offset_left = -115.0 - horizontal_right
        _lang_button.offset_right = -40.0 - horizontal_right
        _lang_button.offset_top = 85.0 + inset_top
        _lang_button.offset_bottom = 140.0 + inset_top

    if _version_label:
        _version_label.offset_top = -32.0 - inset_bottom
        _version_label.offset_bottom = -8.0 - inset_bottom

    _apply_reward_panel_layout(safe.size)
    _apply_profile_panel_layout(safe.size)


func _set_hud_row_layout(bg: Control, row: Control, left: float, top: float, scale_factor: float) -> void:
    var width := 296.0 * scale_factor
    var height := 48.0 * scale_factor
    if bg:
        bg.offset_left = left
        bg.offset_top = top
        bg.offset_right = left + width
        bg.offset_bottom = top + height
    if row:
        row.offset_left = left
        row.offset_top = top
        row.offset_right = left + width
        row.offset_bottom = top + height


func _apply_reward_panel_layout(safe_size: Vector2) -> void:
    if _reward_panel == null:
        return
    var base := Vector2(400.0, 260.0)
    var fit := minf(safe_size.x / (base.x + 48.0), safe_size.y / (base.y + 48.0))
    fit = clampf(fit, 0.75, 1.0)
    _reward_panel.pivot_offset = base * 0.5
    _reward_panel.scale = Vector2.ONE * fit


func _apply_profile_panel_layout(safe_size: Vector2) -> void:
    if _profile_panel_inner == null:
        return
    var base := Vector2(700.0, 460.0)
    var fit := minf(safe_size.x / (base.x + 48.0), safe_size.y / (base.y + 48.0))
    fit = clampf(fit, 0.62, 1.0)
    _profile_panel_target_scale = Vector2.ONE * fit
    _profile_panel_inner.pivot_offset = base * 0.5
    if _profile_panel and _profile_panel.visible:
        _profile_panel_inner.scale = _profile_panel_target_scale


func _init_menu_bgm() -> void:
    if TransitionManager and TransitionManager.has_method("play_bgm"):
        TransitionManager.play_bgm("res://assets/audio/backsound/backsound-mainmenu-1.mp3")


func _refresh_daily_button_style(btn: Button) -> void:
    if btn == null: return
    # If missions are ready to claim, make it glow or something
    pass


func refresh_missions_badge_from_save() -> void:
    if _daily_badge == null: return

    var count := 0
    if MissionsManager and MissionsManager.has_method("get_claimable_count"):
        count = int(MissionsManager.call("get_claimable_count", ""))
    elif MissionsManager and MissionsManager.has_method("has_ready_to_claim_missions_in_save"):
        count = 1 if bool(MissionsManager.call("has_ready_to_claim_missions_in_save")) else 0

    _daily_badge.visible = (count > 0)
    var lbl := _daily_badge.get_node_or_null("Label") as Label
    if lbl:
        lbl.text = str(count) if count > 0 else ""

func _on_game_currencies_changed(coins: int, gems: int) -> void:
    _total_coins = coins
    _total_gems = gems
    if _coin_label:
        _coin_label.text = str(_total_coins)
    if _gem_label:
        _gem_label.text = str(_total_gems)

func _on_season_rewards_changed(_pending_count: int) -> void:
    _refresh_currency_display()

func _on_missions_ready_changed(_can_claim: bool) -> void:
    refresh_missions_badge_from_save()


func _coins_for_reward_type(type: String) -> int:
    match type:
        "coins": return 100
        "premium_coins": return 500
        "skin_reward": return 200
    return 0


func _gems_for_reward_type(type: String) -> int:
    match type:
        "gems": return 5
        "premium_gems": return 20
    return 0


func _save_rewards_and_coins() -> void:
    if GameManager:
        GameManager.total_coins = _total_coins
        GameManager.total_gems = _total_gems
        GameManager.pending_level_rewards = _pending_level_rewards
        if GameManager.has_method("_save_progress"):
            GameManager.call("_save_progress")


func _get_cosmetics_snapshot() -> Dictionary:
    if GameManager and GameManager.has_method("get_cosmetics_snapshot"):
        var snapshot: Variant = GameManager.get_cosmetics_snapshot()
        if snapshot is Dictionary:
            return snapshot
    var cfg := ConfigFile.new()
    var err := cfg.load("user://save.cfg")
    if err != OK:
        return {}
    var cosmetics_value: Variant = cfg.get_value("cosmetics", "data", {})
    if cosmetics_value is Dictionary:
        return cosmetics_value
    return {}


func _set_cosmetics_snapshot(cosmetics: Dictionary) -> void:
    if GameManager and GameManager.has_method("update_cosmetics"):
        GameManager.update_cosmetics(cosmetics, true)
        if GameManager.has_method("update_player_cosmetics"):
            GameManager.update_player_cosmetics()
    return
