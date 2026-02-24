@tool
extends Control

@export var refresh_editor: bool = false : set = _set_refresh_editor

@export var card_default_min_size: Vector2 = DEFAULT_CARD_MIN_SIZE
@export var card_icon_min_size: Vector2 = Vector2(96.0, 96.0)
@export var groups_scroll_height: float = 0.0

const SAVE_PATH := "user://save.cfg"

const DEFAULT_CARD_MIN_SIZE := Vector2(240.0, 280.0)

var shop_groups: Array = []
var buy_buttons: Array = []
var current_coins: int = 0
var current_gems: int = 0
var _parallax_bg: ParallaxBackground = null
var _ui_vbox: VBoxContainer = null
var _last_viewport_size: Vector2i = Vector2i(-1, -1)
var _closing: bool = false
var _coin_icon_tex: Texture2D = null
var _gem_icon_tex: Texture2D = null
var _groups_scroll: ScrollContainer = null
var _shop_title_font: Font = null
var _scroll_dragging: bool = false
var _scroll_drag_total: float = 0.0
var _last_scroll_gesture_msec: int = -1000000
var _scroll_pointer_id: int = -1
var _scroll_last_pos: Vector2 = Vector2.ZERO
var _edge_padding_nodes: Array = []
var _items_margin_nodes: Array = []
var _fx_rng := RandomNumberGenerator.new()
var _ad_manager: Node = null
var _awaiting_rewarded_reason: String = ""
var _daily_claim_day_bucket: int = -1
var _daily_claim_count: int = 0

const _DAILY_CLAIM_ITEM_ID := "daily_coins_claim"
const _DAILY_CLAIM_MIN_COINS := 100
const _DAILY_CLAIM_MAX_COINS := 500
const _DAILY_CLAIM_AD_REASON := "shop_daily_coins_claim"

func _set_refresh_editor(_val: bool) -> void:
    if Engine.is_editor_hint():
        _init_shop_data()
        _build_groups_ui()
        if _ui_vbox and _ui_vbox.get_parent():
             _apply_responsive_layout(get_viewport_rect().size)
    refresh_editor = false

func _enter_tree() -> void:
    if Engine.is_editor_hint():
        return
    # Matikan input dan process sementara saat transisi masuk untuk mencegah race condition
    set_process_input(false)
    set_process_unhandled_input(false)
    set_process(false)


func _ready() -> void:
    _fx_rng.randomize()
    _parallax_bg = get_node_or_null("ParallaxBG") as ParallaxBackground
    if _parallax_bg:
        var bg_layer := _parallax_bg.get_node_or_null("BG") as ParallaxLayer
        var bg_sprite := _parallax_bg.get_node_or_null("BG/Sprite") as Sprite2D
        if bg_layer and bg_sprite and bg_sprite.texture:
            bg_layer.motion_mirroring = bg_sprite.texture.get_size()

    _ui_vbox = get_node_or_null("UI/VBox") as VBoxContainer
    if _ui_vbox:
        _ui_vbox.show()
        _ui_vbox.modulate.a = 0.0
        _ui_vbox.scale = Vector2(0.9, 0.9)
        _ui_vbox.pivot_offset = get_viewport_rect().size * 0.5
        var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
        tween.tween_property(_ui_vbox, "modulate:a", 1.0, 0.3)
        tween.tween_property(_ui_vbox, "scale", Vector2.ONE, 0.3)

    # 1. Load resources first
    _load_currency_icons()
    var ui_font := load("res://assets/font/Fredoka Nunito/Nunito/static/Nunito-Regular.ttf") as Font
    var title_font := load("res://assets/font/Fredoka Nunito/Fredoka/static/Fredoka-Bold.ttf") as Font
    _shop_title_font = title_font

    # 2. Setup visual appearance (Fonts, Colors, Styles)
    if ui_font:
        _apply_ui_font(self, ui_font)

    if title_font:
        var title := get_node_or_null("UI/VBox/TitleLabel") as Label
        if title:
            title.add_theme_font_override("font", title_font)
            title.add_theme_color_override("font_color", Color(1, 1, 0, 1))
            title.add_theme_constant_override("outline_size", 3)
            title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
            title.add_theme_font_size_override("font_size", 36)
            title.text = tr("Shop")

    var groups_scroll := get_node_or_null("UI/VBox/GroupsScroll") as ScrollContainer
    _groups_scroll = groups_scroll
    if groups_scroll:
        if not Engine.is_editor_hint():
            groups_scroll.custom_minimum_size = Vector2.ZERO
        if groups_scroll_height > 0.0:
            groups_scroll.custom_minimum_size.y = groups_scroll_height
            groups_scroll.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
        var bg := StyleBoxFlat.new()
        bg.bg_color = Color(0.08, 0.08, 0.08, 0.0) # Transparan
        bg.corner_radius_top_left = 8
        bg.corner_radius_top_right = 8
        bg.corner_radius_bottom_left = 8
        bg.corner_radius_bottom_right = 8
        groups_scroll.add_theme_stylebox_override("panel", bg)
        groups_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
        groups_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
        if groups_scroll_height <= 0.0:
            groups_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
        if Engine.is_editor_hint():
            groups_scroll.clip_contents = false
        _setup_groups_scroll_input()

    if Engine.is_editor_hint():
        call_deferred("_editor_init_and_build")
    else:
        _init_shop_data()
        _build_groups_ui()

    if not Engine.is_editor_hint():
        var back := get_node_or_null("UI/VBox/BackButton") as BaseButton
        var close_btn := get_node_or_null("UI/CloseButton") as BaseButton
        var coins_label := get_node_or_null("UI/VBox/CurrencyRow/CoinsLabel")
        var gems_label := get_node_or_null("UI/VBox/CurrencyRow/GemsLabel")
        var status_label := get_node_or_null("UI/VBox/StatusLabel") as Label
        _ad_manager = AdManager
        if _ad_manager:
            _ad_manager.move_banner(false) # Banner di bawah untuk shop

        if back and not back.pressed.is_connected(_on_back_pressed):
            back.pressed.connect(_on_back_pressed)
        if close_btn and not close_btn.pressed.is_connected(_on_back_pressed):
            close_btn.pressed.connect(_on_back_pressed)

        if _ad_manager and _ad_manager.has_signal("reward_granted"):
            var cb_reward := Callable(self, "_on_reward_granted")
            if not _ad_manager.is_connected("reward_granted", cb_reward):
                _ad_manager.connect("reward_granted", cb_reward)

        current_coins = _load_coins()
        current_gems = _load_gems()
        _setup_currency_display(coins_label, gems_label)
        _load_daily_claim_progress()

        if status_label:
            status_label.text = ""

        _update_buy_buttons_state()

        if TransitionManager and TransitionManager.has_signal("language_changed"):
            var cb_lang := Callable(self, "_on_language_changed")
            if not TransitionManager.language_changed.is_connected(cb_lang):
                TransitionManager.language_changed.connect(cb_lang)

    _connect_viewport_resize()
    _init_status_timer()

    if not Engine.is_editor_hint():
        call_deferred("_enable_processing")

func _enable_processing() -> void:
    if is_inside_tree():
        set_process_input(true)
        set_process_unhandled_input(true)
        set_process(true)

func _input(event: InputEvent) -> void:
    if not is_inside_tree():
        return
    if _closing:
        return
    if _groups_scroll == null:
        return

    var rect := _groups_scroll.get_global_rect()
    if rect.size.x <= 0.0 or rect.size.y <= 0.0:
        rect = Rect2(_groups_scroll.global_position, _groups_scroll.size)

    var h_scroll_bar := _groups_scroll.get_h_scroll_bar()
    var max_scroll := 0
    if h_scroll_bar:
        max_scroll = int(h_scroll_bar.max_value)

    if event is InputEventScreenTouch:
        var e := event as InputEventScreenTouch
        if e.pressed:
            if rect.has_point(e.position):
                _scroll_pointer_id = e.index
                _scroll_last_pos = e.position
                _scroll_dragging = true
                _scroll_drag_total = 0.0
        else:
            if e.index == _scroll_pointer_id:
                if _scroll_drag_total >= 14.0:
                    _last_scroll_gesture_msec = Time.get_ticks_msec()
                _scroll_pointer_id = -1
                _scroll_dragging = false
        return

    if event is InputEventScreenDrag:
        var e := event as InputEventScreenDrag
        if _scroll_dragging and e.index == _scroll_pointer_id:
            var delta := e.position - _scroll_last_pos
            _scroll_last_pos = e.position
            _groups_scroll.scroll_horizontal = clampi(int(_groups_scroll.scroll_horizontal - delta.x), 0, max_scroll)
            _scroll_drag_total += absf(delta.x) + absf(delta.y)
            get_viewport().set_input_as_handled()
        return

    if event is InputEventMouseButton:
        var e := event as InputEventMouseButton
        if e.button_index == MOUSE_BUTTON_LEFT:
            if e.pressed:
                if rect.has_point(e.position):
                    _scroll_pointer_id = 0
                    _scroll_last_pos = e.position
                    _scroll_dragging = true
                    _scroll_drag_total = 0.0
            else:
                if _scroll_pointer_id == 0:
                    if _scroll_drag_total >= 14.0:
                        _last_scroll_gesture_msec = Time.get_ticks_msec()
                    _scroll_pointer_id = -1
                    _scroll_dragging = false
        return

    if event is InputEventMouseMotion:
        var e := event as InputEventMouseMotion
        if _scroll_dragging and _scroll_pointer_id == 0 and (e.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
            _groups_scroll.scroll_horizontal = clampi(int(_groups_scroll.scroll_horizontal - e.relative.x), 0, max_scroll)
            _scroll_drag_total += absf(e.relative.x) + absf(e.relative.y)
            get_viewport().set_input_as_handled()

    return

func _init_status_timer() -> void:
    var timer := get_node_or_null("StatusTimer") as Timer
    if not timer:
        timer = Timer.new()
        timer.name = "StatusTimer"
        timer.one_shot = true
        timer.wait_time = 3.0
        timer.timeout.connect(_on_status_timer_timeout)
        add_child(timer)

func _on_status_timer_timeout() -> void:
    if not is_inside_tree():
        return
    var status_label := get_node_or_null("UI/VBox/StatusLabel") as Label
    if status_label:
        status_label.text = ""

func _set_status_text(text: String) -> void:
    var status_label := get_node_or_null("UI/VBox/StatusLabel") as Label
    if status_label:
        status_label.text = text
        var timer := get_node_or_null("StatusTimer") as Timer
        if timer:
            timer.start()

func _exit_tree() -> void:
    set_process(false)

func _process(delta: float) -> void:
    if not is_inside_tree():
        return
    if _parallax_bg:
        # Move from Top-Right to Bottom-Left
        # X decreases (Left), Y increases (Bottom)
        _parallax_bg.scroll_base_offset.x -= 40.0 * delta
        _parallax_bg.scroll_base_offset.y += 40.0 * delta

        # Wrap around for Shop BG to prevent large offset values
        # Using 1664, 1109 as seen in ShopMenu.tscn motion_mirroring
        var mirror_x = 1664.0
        var mirror_y = 1109.0
        if abs(_parallax_bg.scroll_base_offset.x) >= mirror_x:
            _parallax_bg.scroll_base_offset.x = fmod(_parallax_bg.scroll_base_offset.x, mirror_x)
        if abs(_parallax_bg.scroll_base_offset.y) >= mirror_y:
            _parallax_bg.scroll_base_offset.y = fmod(_parallax_bg.scroll_base_offset.y, mirror_y)

func _unhandled_input(event: InputEvent) -> void:
    if not is_inside_tree():
        return
    if _closing:
        return
    if event.is_action_pressed(&"ui_cancel"):
        _on_back_pressed()
        get_viewport().set_input_as_handled()

func _setup_groups_scroll_input() -> void:
    if _groups_scroll == null:
        return
    _groups_scroll.mouse_filter = Control.MOUSE_FILTER_STOP

    var groups_hbox := get_node_or_null("UI/VBox/GroupsScroll/GroupsHBox") as Control
    if groups_hbox:
        groups_hbox.mouse_filter = Control.MOUSE_FILTER_PASS
        groups_hbox.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN

    if not _groups_scroll.gui_input.is_connected(_on_groups_scroll_gui_input):
        _groups_scroll.gui_input.connect(_on_groups_scroll_gui_input)

func _on_groups_scroll_gui_input(event: InputEvent) -> void:
    if not is_inside_tree():
        return
    if _groups_scroll == null:
        return

    if event is InputEventScreenTouch:
        var e := event as InputEventScreenTouch
        if e.pressed:
            _scroll_dragging = true
            _scroll_drag_total = 0.0
        else:
            if _scroll_drag_total >= 14.0:
                _last_scroll_gesture_msec = Time.get_ticks_msec()
            _scroll_dragging = false
        return

    if event is InputEventScreenDrag:
        var e := event as InputEventScreenDrag
        if _scroll_dragging:
            _groups_scroll.scroll_horizontal = int(_groups_scroll.scroll_horizontal - e.relative.x)
            _scroll_drag_total += absf(e.relative.x) + absf(e.relative.y)
            get_viewport().set_input_as_handled()
        return

    if event is InputEventMouseButton:
        var e := event as InputEventMouseButton
        if e.button_index == MOUSE_BUTTON_LEFT:
            if e.pressed:
                _scroll_dragging = true
                _scroll_drag_total = 0.0
            else:
                if _scroll_drag_total >= 14.0:
                    _last_scroll_gesture_msec = Time.get_ticks_msec()
                _scroll_dragging = false
        return

    if event is InputEventMouseMotion:
        var e := event as InputEventMouseMotion
        if _scroll_dragging and (e.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
            _groups_scroll.scroll_horizontal = int(_groups_scroll.scroll_horizontal - e.relative.x)
            _scroll_drag_total += absf(e.relative.x) + absf(e.relative.y)
            get_viewport().set_input_as_handled()

func _is_recent_scroll_gesture() -> bool:
    return (Time.get_ticks_msec() - _last_scroll_gesture_msec) < 250

func _load_currency_icons() -> void:
    var coin_candidates: Array = [
        "res://assets/coin_animation/png/2x/Coin.png",
        "res://assets/icon/icon_coin2x_96x96.png",
        "res://assets/coin_animation/png/2x/image_1.png"
    ]
    for p in coin_candidates:
        if ResourceLoader.exists(p):
            _coin_icon_tex = load(p)
            break

    var gem_candidates: Array = [
        "res://assets/diamond_animation/diamond-1024x1024.png",
        "res://assets/diamond_animation/diamond-sprite-256px-36.png"
    ]
    for p in gem_candidates:
        if ResourceLoader.exists(p):
            _gem_icon_tex = load(p)
            break

func _apply_shop_number_font(lbl: Label) -> void:
    if lbl == null:
        return
    if _shop_title_font:
        lbl.add_theme_font_override("font", _shop_title_font)
    lbl.add_theme_constant_override("outline_size", 3)
    lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))

func _setup_currency_display(coins_label: Label, gems_label: Label) -> void:
    var coins_icon := get_node_or_null("UI/VBox/CurrencyRow/CoinsIcon") as TextureRect
    var gems_icon := get_node_or_null("UI/VBox/CurrencyRow/GemsIcon") as TextureRect

    if coins_icon and _coin_icon_tex:
        coins_icon.texture = _coin_icon_tex
        coins_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        coins_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        coins_icon.custom_minimum_size = Vector2(32, 32)

    if gems_icon and _gem_icon_tex:
        gems_icon.texture = _gem_icon_tex
        gems_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        gems_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        gems_icon.custom_minimum_size = Vector2(32, 32)

    if coins_label and coins_label is Label:
        (coins_label as Label).text = str(current_coins)
        _apply_shop_number_font(coins_label)
    if gems_label and gems_label is Label:
        (gems_label as Label).text = str(current_gems)
        _apply_shop_number_font(gems_label)

func _load_coins() -> int:
    var cfg := ConfigFile.new()
    var err := cfg.load(SAVE_PATH)
    if err != OK:
        return 0
    return int(cfg.get_value("progress", "total_coins", 0))

func _load_gems() -> int:
    var cfg := ConfigFile.new()
    var err := cfg.load(SAVE_PATH)
    if err != OK:
        return 0
    return int(cfg.get_value("progress", "total_gems", 0))

func _save_coins(value: int) -> void:
    var cfg := ConfigFile.new()
    cfg.load(SAVE_PATH)
    cfg.set_value("progress", "total_coins", value)
    cfg.save(SAVE_PATH)

func _save_gems(value: int) -> void:
    var cfg := ConfigFile.new()
    cfg.load(SAVE_PATH)
    cfg.set_value("progress", "total_gems", value)
    cfg.save(SAVE_PATH)


func _get_today_claim_bucket() -> int:
    return int(Time.get_unix_time_from_system() / 86400)


func _load_daily_claim_progress() -> void:
    var cfg := ConfigFile.new()
    var err := cfg.load(SAVE_PATH)
    if err == OK:
        _daily_claim_day_bucket = int(cfg.get_value("shop", "daily_coins_claim_day", -1))
        _daily_claim_count = maxi(int(cfg.get_value("shop", "daily_coins_claim_count", 0)), 0)
    else:
        _daily_claim_day_bucket = -1
        _daily_claim_count = 0
    _sync_daily_claim_state(true)


func _save_daily_claim_progress() -> void:
    var cfg := ConfigFile.new()
    var err := cfg.load(SAVE_PATH)
    if err != OK:
        cfg = ConfigFile.new()
    cfg.set_value("shop", "daily_coins_claim_day", _daily_claim_day_bucket)
    cfg.set_value("shop", "daily_coins_claim_count", maxi(_daily_claim_count, 0))
    cfg.save(SAVE_PATH)


func _sync_daily_claim_state(save_if_reset: bool = false) -> void:
    var today := _get_today_claim_bucket()
    if _daily_claim_day_bucket == today:
        return
    _daily_claim_day_bucket = today
    _daily_claim_count = 0
    if save_if_reset:
        _save_daily_claim_progress()


func _is_daily_free_claim_available() -> bool:
    _sync_daily_claim_state()
    return _daily_claim_count <= 0


func _is_rewarded_available_for_daily_claim() -> bool:
    if _ad_manager == null:
        return false
    if _ad_manager.has_method("is_rewarded_available"):
        return bool(_ad_manager.call("is_rewarded_available"))
    return true


func _find_buy_button_for_item_id(item_id: String) -> BaseButton:
    if item_id.is_empty():
        return null
    for e_any in buy_buttons:
        if not (e_any is Dictionary):
            continue
        var e: Dictionary = e_any
        var item_any = e.get("item")
        if not (item_any is Dictionary):
            continue
        var item: Dictionary = item_any
        if String(item.get("id", "")) != item_id:
            continue
        var btn_any = e.get("button")
        if btn_any is BaseButton:
            return btn_any as BaseButton
    return null


func _on_reward_granted(reason: String) -> void:
    if reason != _awaiting_rewarded_reason:
        return
    _awaiting_rewarded_reason = ""
    if reason == _DAILY_CLAIM_AD_REASON:
        _grant_daily_claim_coins(true)


func _on_daily_claim_pressed() -> void:
    _sync_daily_claim_state()
    if _is_daily_free_claim_available():
        _grant_daily_claim_coins(false)
        return
    if _ad_manager == null or not _ad_manager.has_method("show_rewarded"):
        _set_status_text(tr("Ad not available."))
        _update_buy_buttons_state()
        return
    if not _is_rewarded_available_for_daily_claim():
        _set_status_text(tr("Ad not available."))
        _update_buy_buttons_state()
        return
    _awaiting_rewarded_reason = _DAILY_CLAIM_AD_REASON
    _ad_manager.call("show_rewarded", _awaiting_rewarded_reason)


func _grant_daily_claim_coins(via_ad: bool) -> void:
    _sync_daily_claim_state()
    if not via_ad and _daily_claim_count > 0:
        return

    var gain := _fx_rng.randi_range(_DAILY_CLAIM_MIN_COINS, _DAILY_CLAIM_MAX_COINS)
    current_coins += gain
    _save_coins(current_coins)

    _daily_claim_count += 1
    _save_daily_claim_progress()

    var coins_label := get_node_or_null("UI/VBox/CurrencyRow/CoinsLabel") as Label
    if coins_label:
        coins_label.text = str(current_coins)

    if is_instance_valid(TransitionManager) and TransitionManager.has_method("play_sfx"):
        TransitionManager.play_sfx(&"mission_claim")

    var from_btn := _find_buy_button_for_item_id(_DAILY_CLAIM_ITEM_ID) as Control
    var to_icon := get_node_or_null("UI/VBox/CurrencyRow/CoinsIcon") as Control
    var coin_count := clampi(int(round(float(gain) / 40.0)), 6, 14)
    _play_claim_coin_fly(from_btn, to_icon, coin_count)

    _update_buy_buttons_state()
    _set_status_text(tr("Daily coins claimed: +%d") % [gain])


func _play_claim_coin_fly(from_control: Control, to_control: Control, count: int) -> void:
    if from_control == null:
        return
    if _coin_icon_tex == null:
        return
    if count <= 0:
        return
    var ui_layer := get_node_or_null("UI") as CanvasLayer
    if ui_layer == null:
        return

    var from_rect := from_control.get_global_rect()
    var from_center := from_rect.position + from_rect.size * 0.5

    var to_center := Vector2(56, 56)
    if to_control != null:
        var to_rect := to_control.get_global_rect()
        to_center = to_rect.position + to_rect.size * 0.5

    for i in range(count):
        var coin := TextureRect.new()
        coin.texture = _coin_icon_tex
        coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
        coin.set_as_top_level(true)
        coin.size = Vector2(24, 24)
        coin.pivot_offset = coin.size * 0.5
        ui_layer.add_child(coin)

        var start_offset := Vector2(
            _fx_rng.randf_range(-24.0, 24.0),
            _fx_rng.randf_range(-18.0, 18.0)
        )
        coin.global_position = (from_center + start_offset) - coin.pivot_offset
        coin.modulate = Color(1, 1, 1, 1)
        coin.scale = Vector2.ONE * _fx_rng.randf_range(0.85, 1.05)

        var t := create_tween()
        t.tween_interval(_fx_rng.randf_range(0.0, 0.12))
        t.tween_property(coin, "global_position", to_center - coin.pivot_offset, _fx_rng.randf_range(0.35, 0.55)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
        t.parallel().tween_property(coin, "modulate:a", 0.0, _fx_rng.randf_range(0.35, 0.55)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
        t.finished.connect(func():
            if coin:
                coin.queue_free()
        )


func _connect_viewport_resize() -> void:
    var vp := get_viewport()
    if vp == null:
        return
    var cb := Callable(self, "_on_viewport_size_changed")
    if not vp.size_changed.is_connected(cb):
        vp.size_changed.connect(cb)
    call_deferred("_on_viewport_size_changed")


func _on_viewport_size_changed() -> void:
    if not is_inside_tree():
        return
    var viewport := get_viewport()
    if viewport == null:
        return
    var vp := viewport.get_visible_rect().size
    var vp_i := Vector2i(int(vp.x), int(vp.y))
    if vp_i == _last_viewport_size:
        return
    _last_viewport_size = vp_i
    _apply_responsive_layout(vp)


func _apply_responsive_layout(vp: Vector2) -> void:
    if _parallax_bg:
        var bg_sprite := _parallax_bg.get_node_or_null("BG/Sprite") as Sprite2D
        if bg_sprite and bg_sprite.texture:
            var ts := bg_sprite.texture.get_size()
            if ts.x > 0.0 and ts.y > 0.0:
                # Scale to fill viewport while maintaining aspect ratio
                var s: float = max(vp.x / ts.x, vp.y / ts.y)
                bg_sprite.scale = Vector2(s, s)
                bg_sprite.position = Vector2.ZERO

                # Update mirroring to match new scaled size for seamless parallax
                var bg_layer := _parallax_bg.get_node_or_null("BG") as ParallaxLayer
                if bg_layer:
                    # Use floor to avoid sub-pixel seams
                    bg_layer.motion_mirroring = (ts * s).floor()

    if _ui_vbox:
        # Kunci VBox Shop agar selalu memenuhi viewport dan tidak bergeser
        _ui_vbox.anchor_left = 0.0
        _ui_vbox.anchor_top = 0.0
        _ui_vbox.anchor_right = 1.0
        _ui_vbox.anchor_bottom = 1.0

        _ui_vbox.offset_left = 0.0
        _ui_vbox.offset_top = 0.0
        _ui_vbox.offset_right = 0.0
        _ui_vbox.offset_bottom = 0.0
    _apply_products_padding(_get_products_padding(vp.x))

func _get_products_padding(vp_width: float) -> int:
    if vp_width < 768.0:
        return 8
    if vp_width <= 1024.0:
        return 12
    return 16

func _apply_products_padding(pad: int) -> void:
    for n in _edge_padding_nodes:
        if n is Control:
            (n as Control).custom_minimum_size.x = pad
    for m in _items_margin_nodes:
        if m is MarginContainer:
            (m as MarginContainer).add_theme_constant_override("margin_left", pad)
            (m as MarginContainer).add_theme_constant_override("margin_right", pad)


func _load_powerups_data() -> Dictionary:
    var cfg := ConfigFile.new()
    var err := cfg.load(SAVE_PATH)
    if err != OK:
        return {}
    var value: Variant = cfg.get_value("powerups", "data", {})
    if value is Dictionary:
        return value
    return {}


func _save_powerups_data(data: Dictionary) -> void:
    var cfg := ConfigFile.new()
    var err := cfg.load(SAVE_PATH)
    if err != OK:
        cfg = ConfigFile.new()
    cfg.set_value("powerups", "data", data)
    cfg.save(SAVE_PATH)


func _load_cosmetics_data() -> Dictionary:
    var cfg := ConfigFile.new()
    var err := cfg.load(SAVE_PATH)
    if err != OK:
        return {}
    var value: Variant = cfg.get_value("cosmetics", "data", {})
    if value is Dictionary:
        return value
    return {}


func _save_cosmetics_data(data: Dictionary) -> void:
    var cfg := ConfigFile.new()
    var err := cfg.load(SAVE_PATH)
    if err != OK:
        cfg = ConfigFile.new()
    cfg.set_value("cosmetics", "data", data)
    cfg.save(SAVE_PATH)

func _init_shop_data() -> void:
    shop_groups.clear()
    buy_buttons.clear()

    var all_skills_items: Array = [
        {
            "id": _DAILY_CLAIM_ITEM_ID,
            "name": "Daily Coins Claim",
            "description": "Klaim %d-%d koin harian. Klaim berikutnya di hari yang sama perlu iklan." % [_DAILY_CLAIM_MIN_COINS, _DAILY_CLAIM_MAX_COINS],
            "price": 0,
            "currency": "coins",
            "icon": "res://assets/coin_animation/png/2x/Coin.png",
            "rarity": "common"
        },
        {
            "id": "magnet_30s",
            "name": "Magnet 30s",
            "description": "Menarik koin otomatis selama 30 detik.",
            "price": 150,
            "currency": "coins",
            "icon": "res://assets/icon/icon_magnet_timer_96x96.png",
            "rarity": "common"
        },
        {
            "id": "shield_1hit",
            "name": "Perisai 1 Hit",
            "description": "Melindungi dari satu kali tabrakan.",
            "price": 200,
            "currency": "coins",
            "icon": "res://assets/icon/icon_shield.png",
            "rarity": "rare"
        },
        {
            "id": "double_coins_run",
            "name": "Double Coins (1 Run)",
            "description": "Mendapatkan koin 2x lipat selama satu sesi lari.",
            "price": 250,
            "currency": "coins",
            "icon": "res://assets/icon/icon_coinduble_96x96.png",
            "rarity": "rare"
        },
        {
            "id": "speed_boost_run",
            "name": "Speed Boost (1 Run)",
            "description": "Meningkatkan kecepatan lari dasar sebesar 50%.",
            "price": 200,
            "currency": "coins",
            "icon": "res://assets/icon/icon_boost_96x96.png",
            "rarity": "rare"
        }
    ]

    var upgrade_coin_items: Array = [
        {
            "id": "max_heart_plus1",
            "name": "Upgrade Nyawa Maks +1",
            "description": "Meningkatkan kapasitas nyawa maksimal secara permanen.",
            "price": 1000,
            "currency": "coins",
            "icon": "res://assets/icon/icon_heart_96x96.png",
            "rarity": "epic"
        },
        {
            "id": "magnet_duration_plus10",
            "name": "Upgrade Durasi Magnet +10%",
            "description": "Menambah durasi efek magnet secara permanen.",
            "price": 800,
            "currency": "coins",
            "icon": "res://assets/icon/icon_magnet_timer_96x96.png",
            "rarity": "rare"
        },
        {
            "id": "shield_duration_plus10",
            "name": "Upgrade Durasi Shield +10%",
            "description": "Menambah durasi perlindungan perisai secara permanen.",
            "price": 800,
            "currency": "coins",
            "icon": "res://assets/icon/icon_shield.png",
            "rarity": "rare"
        },
        {
            "id": "double_coins_duration_plus10",
            "name": "Upgrade Durasi Double Coins +10%",
            "description": "Menambah durasi efek double coins secara permanen.",
            "price": 900,
            "currency": "coins",
            "icon": "res://assets/icon/icon_coinduble_96x96.png",
            "rarity": "rare"
        },
        {
            "id": "double_coins_multiplier_plus025",
            "name": "Upgrade Multiplier Double Coins +0.25x",
            "description": "Menambah multiplier gain koin saat double coins aktif.",
            "price": 1200,
            "currency": "coins",
            "icon": "res://assets/icon/icon_coin_multiplier_96x96.png",
            "rarity": "epic"
        },
        {
            "id": "speed_boost_duration_plus10",
            "name": "Upgrade Durasi Speed Boost +10%",
            "description": "Menambah durasi efek speed boost secara permanen.",
            "price": 900,
            "currency": "coins",
            "icon": "res://assets/icon/icon_boost_96x96.png",
            "rarity": "rare"
        }
    ]

    var upgrade_gem_items: Array = [
        {
            "id": "max_heart_plus1",
            "name": "Upgrade Nyawa Maks +1",
            "description": "Meningkatkan kapasitas nyawa maksimal secara permanen.",
            "price": 30,
            "currency": "gems",
            "icon": "res://assets/icon/icon_heart_96x96.png",
            "rarity": "epic"
        },
        {
            "id": "magnet_duration_plus10",
            "name": "Upgrade Durasi Magnet +10%",
            "description": "Menambah durasi efek magnet secara permanen.",
            "price": 24,
            "currency": "gems",
            "icon": "res://assets/icon/icon_magnet_timer_96x96.png",
            "rarity": "rare"
        },
        {
            "id": "shield_duration_plus10",
            "name": "Upgrade Durasi Shield +10%",
            "description": "Menambah durasi perlindungan perisai secara permanen.",
            "price": 24,
            "currency": "gems",
            "icon": "res://assets/icon/icon_shield.png",
            "rarity": "rare"
        },
        {
            "id": "double_coins_duration_plus10",
            "name": "Upgrade Durasi Double Coins +10%",
            "description": "Menambah durasi efek double coins secara permanen.",
            "price": 24,
            "currency": "gems",
            "icon": "res://assets/icon/icon_coinduble_96x96.png",
            "rarity": "rare"
        },
        {
            "id": "double_coins_multiplier_plus025",
            "name": "Upgrade Multiplier Double Coins +0.25x",
            "description": "Menambah multiplier gain koin saat double coins aktif.",
            "price": 32,
            "currency": "gems",
            "icon": "res://assets/icon/icon_coin_multiplier_96x96.png",
            "rarity": "epic"
        },
        {
            "id": "speed_boost_duration_plus10",
            "name": "Upgrade Durasi Speed Boost +10%",
            "description": "Menambah durasi efek speed boost secara permanen.",
            "price": 24,
            "currency": "gems",
            "icon": "res://assets/icon/icon_boost_96x96.png",
            "rarity": "rare"
        }
    ]

    var cosmetic_coin_items: Array = [
        {
            "id": "skin_basic",
            "name": "Skin Basic",
            "description": "Skin standar untuk petualang pemula.",
            "price": 150,
            "currency": "coins",
            "icon": "res://assets/profile/profile_basic.png",
            "rarity": "common"
        },
        {
            "id": "skin_premium",
            "name": "Skin Premium",
            "description": "Skin dengan detail emas yang elegan.",
            "price": 400,
            "currency": "coins",
            "icon": "res://assets/profile/profile_premium.png",
            "rarity": "rare"
        }
    ]

    var cosmetic_gem_items: Array = [
        {
            "id": "skin_neon",
            "name": "Skin Neon",
            "description": "Skin futuristik yang menyala dalam gelap.",
            "price": 25,
            "currency": "gems",
            "icon": "res://assets/profile/profile_neon.png",
            "rarity": "epic"
        },
        {
            "id": "skin_shadow",
            "name": "Skin Shadow",
            "description": "Skin misterius yang terbuat dari bayangan.",
            "price": 40,
            "currency": "gems",
            "icon": "res://assets/profile/profile_ninja.png",
            "rarity": "legendary"
        }
    ]

    var border_items: Array = [
        {
            "id": "border_gold",
            "name": "Gold Border",
            "description": "Bingkai emas mewah untuk profilmu.",
            "price": 500,
            "currency": "coins",
            "icon": "res://assets/icon/icon_border_avatar_gold_128x128.png",
            "rarity": "rare",
            "type": "border"
        },
        {
            "id": "border_silver",
            "name": "Silver Border",
            "description": "Bingkai perak yang elegan dan bersih.",
            "price": 250,
            "currency": "coins",
            "icon": "res://assets/icon/icon_border_avatar_gold_128x128.png",
            "rarity": "common",
            "type": "border"
        },
        {
            "id": "border_neon",
            "name": "Neon Border",
            "description": "Bingkai futuristik dengan efek cahaya biru.",
            "price": 20,
            "currency": "gems",
            "icon": "res://assets/icon/icon_border_avatar_gold_128x128.png",
            "rarity": "epic",
            "type": "border"
        },
        {
            "id": "border_shadow",
            "name": "Shadow Border",
            "description": "Bingkai misterius dengan aura gelap.",
            "price": 35,
            "currency": "gems",
            "icon": "res://assets/icon/icon_border_avatar_gold_128x128.png",
            "rarity": "legendary",
            "type": "border"
        }
    ]

    var gem_pack_real_items: Array = [
        {
            "id": "gems_small",
            "name": "Small Gem Pack (100)",
            "description": "Paket kecil gems untuk kebutuhan mendesak.",
            "price": 15000,
            "currency": "real",
            "display_price": "Rp 15.000",
            "icon": "res://assets/diamond_animation/diamond-1024x1024.png"
        },
        {
            "id": "gems_standard",
            "name": "Standard Gem Pack (300 +30)",
            "description": "Paket standar dengan bonus gems 10%.",
            "price": 45000,
            "currency": "real",
            "display_price": "Rp 45.000",
            "icon": "res://assets/diamond_animation/diamond-1024x1024.png"
        },
        {
            "id": "gems_big",
            "name": "Big Gem Pack (800 +150)",
            "description": "Paket besar dengan bonus gems melimpah.",
            "price": 99000,
            "currency": "real",
            "display_price": "Rp 99.000",
            "icon": "res://assets/diamond_animation/diamond-1024x1024.png"
        },
        {
            "id": "gems_mega",
            "name": "Mega Gem Pack (2000 +500)",
            "description": "Pilihan terbaik untuk kolektor sejati.",
            "price": 199000,
            "currency": "real",
            "display_price": "Rp 199.000",
            "icon": "res://assets/diamond_animation/diamond-1024x1024.png"
        }
    ]

    var bundle_real_items: Array = [
        {
            "id": "starter_bundle",
            "name": "Starter Pack",
            "description": "Koin, Gems, dan Power-ups untuk memulai.",
            "price": 29000,
            "currency": "real",
            "display_price": "Rp 29.000",
            "icon": "res://assets/icon/icon_trophy_128x128.png"
        },
        {
            "id": "progress_bundle",
            "name": "Progress Pack",
            "description": "Boost kemajuanmu dengan koin dan power-ups.",
            "price": 59000,
            "currency": "real",
            "display_price": "Rp 59.000",
            "icon": "res://assets/icon/icon_trophy_128x128.png"
        },
        {
            "id": "cosmetic_bundle",
            "name": "Cosmetic Starter",
            "description": "Paket hemat koin dan gems untuk beli skin.",
            "price": 49000,
            "currency": "real",
            "display_price": "Rp 49.000",
            "icon": "res://assets/icon/icon_trophy_128x128.png"
        }
    ]

    shop_groups.append({
        "id": "all_skills_coins",
        "title": "Skills & Power-ups (Coins)",
        "items": all_skills_items
    })

    shop_groups.append({
        "id": "upgrades_coins",
        "title": "Upgrades (Coins)",
        "items": upgrade_coin_items
    })

    shop_groups.append({
        "id": "upgrades_gems",
        "title": "Upgrades (Gems)",
        "items": upgrade_gem_items
    })

    shop_groups.append({
        "id": "cosmetics_coins",
        "title": "Cosmetics (Coins)",
        "items": cosmetic_coin_items
    })

    shop_groups.append({
        "id": "cosmetic_gems",
        "title": "Cosmetic Skins (Gems)",
        "items": cosmetic_gem_items
    })

    shop_groups.append({
        "id": "avatar_borders",
        "title": "Avatar Borders",
        "items": border_items
    })

    shop_groups.append({
        "id": "gems_real",
        "title": "Gem Packs (Real)",
        "items": gem_pack_real_items
    })

    shop_groups.append({
        "id": "bundles_real",
        "title": "Bundles (Real)",
        "items": bundle_real_items
    })

func _init_editor_dummy_data() -> void:
    var powerup_items = [
        {"id": _DAILY_CLAIM_ITEM_ID, "name": "Daily Coins Claim", "description": "Klaim %d-%d koin harian. Klaim berikutnya di hari yang sama perlu iklan." % [_DAILY_CLAIM_MIN_COINS, _DAILY_CLAIM_MAX_COINS], "price": 0, "currency": "coins", "icon": "res://assets/coin_animation/png/2x/Coin.png", "rarity": "common"},
        {"id": "magnet_30s", "name": "Magnet 30s", "description": "Menarik koin otomatis selama 30 detik.", "price": 150, "currency": "coins", "icon": "res://assets/icon/icon_magnet_v1_96x96.png", "rarity": "common"},
        {"id": "shield_1hit", "name": "Perisai 1 Hit", "description": "Melindungi dari satu kali tabrakan.", "price": 200, "currency": "coins", "icon": "res://assets/icon/icon_shield.png", "rarity": "rare"},
        {"id": "double_coins_run", "name": "Double Coins (1 Run)", "description": "Mendapatkan koin 2x lipat selama satu sesi lari.", "price": 250, "currency": "coins", "icon": "res://assets/icon/icon_coinduble_96x96.png", "rarity": "rare"},
        {"id": "speed_boost_run", "name": "Speed Boost (1 Run)", "description": "Meningkatkan kecepatan lari dasar sebesar 50%.", "price": 200, "currency": "coins", "icon": "res://assets/icon/icon_boost_96x96.png", "rarity": "rare"}
    ]
    shop_groups.append({
        "id": "powerups_coins",
        "title": "Skills & Power-ups (Coins)",
        "items": powerup_items
    })

    var upgrade_items: Array = [
        {
            "id": "max_heart_plus1",
            "name": "Upgrade Nyawa Maks +1",
            "description": "Meningkatkan kapasitas nyawa maksimal secara permanen.",
            "price": 1000,
            "currency": "coins",
            "icon": "res://assets/coin_animation/png/2x/Coin.png",
            "rarity": "epic"
        },
        {
            "id": "magnet_duration_plus10",
            "name": "Upgrade Durasi Magnet +10%",
            "description": "Menambah durasi efek magnet secara permanen.",
            "price": 800,
            "currency": "coins",
            "icon": "res://assets/icon/icon_magnet_v1_96x96.png",
            "rarity": "rare"
        },
        {
            "id": "shield_duration_plus10",
            "name": "Upgrade Durasi Shield +10%",
            "description": "Menambah durasi perlindungan perisai secara permanen.",
            "price": 800,
            "currency": "coins",
            "icon": "res://assets/icon/icon_shield.png",
            "rarity": "rare"
        },
        {
            "id": "double_coins_duration_plus10",
            "name": "Upgrade Durasi Double Coins +10%",
            "description": "Menambah durasi efek double coins secara permanen.",
            "price": 900,
            "currency": "coins",
            "icon": "res://assets/icon/icon_coinduble_96x96.png",
            "rarity": "rare"
        },
        {
            "id": "double_coins_multiplier_plus025",
            "name": "Upgrade Multiplier Double Coins +0.25x",
            "description": "Menambah multiplier gain koin saat double coins aktif.",
            "price": 1200,
            "currency": "coins",
            "icon": "res://assets/coin_animation/png/2x/Coin.png",
            "rarity": "epic"
        },
        {
            "id": "speed_boost_duration_plus10",
            "name": "Upgrade Durasi Speed Boost +10%",
            "description": "Menambah durasi efek speed boost secara permanen.",
            "price": 900,
            "currency": "coins",
            "icon": "res://assets/icon/icon_boost_96x96.png",
            "rarity": "rare"
        }
    ]
    shop_groups.append({
        "id": "upgrades_coins",
        "title": "Upgrades (Coins)",
        "items": upgrade_items
    })

    var upgrade_gem_items: Array = [
        {
            "id": "max_heart_plus1",
            "name": "Upgrade Nyawa Maks +1",
            "description": "Meningkatkan kapasitas nyawa maksimal secara permanen.",
            "price": 30,
            "currency": "gems",
            "icon": "res://assets/coin_animation/png/2x/Coin.png",
            "rarity": "epic"
        },
        {
            "id": "magnet_duration_plus10",
            "name": "Upgrade Durasi Magnet +10%",
            "description": "Menambah durasi efek magnet secara permanen.",
            "price": 24,
            "currency": "gems",
            "icon": "res://assets/icon/icon_magnet_v1_96x96.png",
            "rarity": "rare"
        },
        {
            "id": "shield_duration_plus10",
            "name": "Upgrade Durasi Shield +10%",
            "description": "Menambah durasi perlindungan perisai secara permanen.",
            "price": 24,
            "currency": "gems",
            "icon": "res://assets/icon/icon_shield.png",
            "rarity": "rare"
        },
        {
            "id": "double_coins_duration_plus10",
            "name": "Upgrade Durasi Double Coins +10%",
            "description": "Menambah durasi efek double coins secara permanen.",
            "price": 24,
            "currency": "gems",
            "icon": "res://assets/icon/icon_coinduble_96x96.png",
            "rarity": "rare"
        },
        {
            "id": "double_coins_multiplier_plus025",
            "name": "Upgrade Multiplier Double Coins +0.25x",
            "description": "Menambah multiplier gain koin saat double coins aktif.",
            "price": 32,
            "currency": "gems",
            "icon": "res://assets/coin_animation/png/2x/Coin.png",
            "rarity": "epic"
        },
        {
            "id": "speed_boost_duration_plus10",
            "name": "Upgrade Durasi Speed Boost +10%",
            "description": "Menambah durasi efek speed boost secara permanen.",
            "price": 24,
            "currency": "gems",
            "icon": "res://assets/icon/icon_boost_96x96.png",
            "rarity": "rare"
        }
    ]
    shop_groups.append({
        "id": "upgrades_gems",
        "title": "Upgrades (Gems)",
        "items": upgrade_gem_items
    })

    # 3. Cosmetics (Coins) Dummy - 2 items
    var cosmetic_coin_items: Array = [
        {
            "id": "skin_basic",
            "name": "Skin Basic",
            "price": 150,
            "currency": "coins",
            "icon": "res://assets/mc/run/idle_run.png",
            "rarity": "common"
        },
        {
            "id": "skin_premium",
            "name": "Skin Premium",
            "price": 400,
            "currency": "coins",
            "icon": "res://assets/mc/run/idle_run.png",
            "rarity": "rare"
        }
    ]
    shop_groups.append({
        "id": "cosmetics_coins",
        "title": "Cosmetics (Coins)",
        "items": cosmetic_coin_items
    })

    # 4. Cosmetics (Gems) Dummy - 2 items
    var cosmetic_gem_items: Array = [
        {
            "id": "skin_neon",
            "name": "Skin Neon",
            "price": 25,
            "currency": "gems",
            "icon": "res://assets/mc/run/idle_run.png",
            "rarity": "epic"
        },
        {
            "id": "skin_shadow",
            "name": "Skin Shadow",
            "price": 40,
            "currency": "gems",
            "icon": "res://assets/mc/run/idle_run.png",
            "rarity": "legendary"
        }
    ]
    shop_groups.append({
        "id": "cosmetics_gems",
        "title": "Cosmetics (Gems)",
        "items": cosmetic_gem_items
    })

    # 5. Gem Packs (Real) Dummy - 4 items
    var gem_items: Array = [
        {
            "id": "gems_small",
            "name": "Small Gem Pack (100)",
            "price": 15000,
            "currency": "real",
            "display_price": "Rp 15.000",
            "icon": "res://assets/diamond_animation/diamond-1024x1024.png"
        },
        {
            "id": "gems_standard",
            "name": "Standard Gem Pack (300 +30)",
            "price": 45000,
            "currency": "real",
            "display_price": "Rp 45.000",
            "icon": "res://assets/diamond_animation/diamond-1024x1024.png"
        },
        {
            "id": "gems_big",
            "name": "Big Gem Pack (800 +150)",
            "price": 99000,
            "currency": "real",
            "display_price": "Rp 99.000",
            "icon": "res://assets/diamond_animation/diamond-1024x1024.png"
        },
        {
            "id": "gems_mega",
            "name": "Mega Gem Pack (2000 +500)",
            "price": 199000,
            "currency": "real",
            "display_price": "Rp 199.000",
            "icon": "res://assets/diamond_animation/diamond-1024x1024.png"
        }
    ]
    shop_groups.append({
        "id": "gems_real",
        "title": "Gem Packs (Real)",
        "items": gem_items
    })

    # 6. Bundles (Real) Dummy - 3 items
    var bundle_items: Array = [
        {
            "id": "starter_bundle",
            "name": "Starter Pack",
            "price": 29000,
            "currency": "real",
            "display_price": "Rp 29.000",
            "icon": "res://assets/icon/icon_trophy_128x128.png"
        },
        {
            "id": "progress_bundle",
            "name": "Progress Pack",
            "price": 59000,
            "currency": "real",
            "display_price": "Rp 59.000",
            "icon": "res://assets/icon/icon_trophy_128x128.png"
        },
        {
            "id": "cosmetic_bundle",
            "name": "Cosmetic Starter",
            "price": 49000,
            "currency": "real",
            "display_price": "Rp 49.000",
            "icon": "res://assets/icon/icon_trophy_128x128.png"
        }
    ]
    shop_groups.append({
        "id": "bundles_real",
        "title": "Bundles (Real)",
        "items": bundle_items
    })

func _build_groups_ui() -> void:
    var groups_root := get_node_or_null("UI/VBox/GroupsScroll/GroupsHBox") as HBoxContainer
    var status_label := get_node_or_null("UI/VBox/StatusLabel") as Label
    if groups_root == null:
        if status_label:
            status_label.text = tr("[Error] Groups container (HBox) not found")
        return

    groups_root.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
    groups_root.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

    # In editor, we must be careful with node cleanup
    for child in groups_root.get_children():
        if Engine.is_editor_hint():
            child.free() # Immediate removal in editor
        else:
            child.queue_free()

    buy_buttons.clear()
    _edge_padding_nodes.clear()
    _items_margin_nodes.clear()
    var edge_padding := _get_products_padding(get_viewport_rect().size.x)

    var left_pad := Control.new()
    left_pad.custom_minimum_size.x = edge_padding
    left_pad.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
    left_pad.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
    left_pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
    groups_root.add_child(left_pad)
    _edge_padding_nodes.append(left_pad)

    for g in shop_groups:
        if not (g is Dictionary):
            continue

        var group_container := VBoxContainer.new()
        group_container.mouse_filter = Control.MOUSE_FILTER_PASS
        # Allow group to take natural width based on content
        group_container.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
        group_container.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
        group_container.add_theme_constant_override("separation", 16)

        # Add Title
        var title_txt := String(g.get("title", ""))
        if not title_txt.is_empty():
            var lbl := Label.new()
            lbl.text = tr(title_txt)
            lbl.add_theme_font_size_override("font_size", 24)
            lbl.add_theme_color_override("font_color", Color(1, 0.9, 0.4, 1))
            lbl.mouse_filter = Control.MOUSE_FILTER_PASS
            group_container.add_child(lbl)

        var items_margin := MarginContainer.new()
        items_margin.mouse_filter = Control.MOUSE_FILTER_PASS
        items_margin.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
        items_margin.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
        items_margin.add_theme_constant_override("margin_left", edge_padding)
        items_margin.add_theme_constant_override("margin_right", edge_padding)
        _items_margin_nodes.append(items_margin)

        var items_row := HBoxContainer.new()
        items_row.mouse_filter = Control.MOUSE_FILTER_PASS
        items_row.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
        items_row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
        items_row.add_theme_constant_override("separation", 16)

        var items_data = g.get("items", [])
        if items_data is Array:
            var items: Array = items_data
            for item in items:
                if not (item is Dictionary):
                    continue
                var card := _create_item_card(item)
                if card:
                    items_row.add_child(card)

        items_margin.add_child(items_row)
        group_container.add_child(items_margin)
        groups_root.add_child(group_container)

    var right_pad := Control.new()
    right_pad.custom_minimum_size.x = edge_padding
    right_pad.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
    right_pad.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
    right_pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
    groups_root.add_child(right_pad)
    _edge_padding_nodes.append(right_pad)

    if status_label and Engine.is_editor_hint():
        status_label.text = "Groups: " + str(shop_groups.size()) + ", Items: " + str(buy_buttons.size())

    # Update total scroll container width in editor to fit all groups
    if Engine.is_editor_hint():
        # Ensure it is set to SHOW_NEVER in editor too if desired, or keep default
        var groups_scroll := groups_root.get_parent() as ScrollContainer
        if groups_scroll:
            groups_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
            # Make sure the container is wide enough to show everything in editor
            groups_scroll.custom_minimum_size.x = 6000 # Set a large width for editor preview

func _create_item_card(item: Dictionary) -> Control:
    var panel := PanelContainer.new()

    var card_min_size: Vector2 = card_default_min_size
    var card_min_size_override: Variant = item.get("card_min_size", null)
    if card_min_size_override is Vector2:
        card_min_size = card_min_size_override
    else:
        var card_w_override: Variant = item.get("card_w", null)
        if card_w_override is float or card_w_override is int:
            card_min_size.x = float(card_w_override)
        var card_h_override: Variant = item.get("card_h", null)
        if card_h_override is float or card_h_override is int:
            card_min_size.y = float(card_h_override)

    card_min_size.x = clampf(card_min_size.x, 160.0, 600.0)
    card_min_size.y = clampf(card_min_size.y, 180.0, 800.0)
    panel.custom_minimum_size = card_min_size
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
    panel.mouse_filter = Control.MOUSE_FILTER_PASS

    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.15, 0.15, 0.15, 0.9)
    style.set_corner_radius_all(12)
    style.set_border_width_all(2)
    style.content_margin_left = 12
    style.content_margin_right = 12
    style.content_margin_top = 12
    style.content_margin_bottom = 12

    # Rarity color border
    var rarity := String(item.get("rarity", "common"))
    match rarity:
        "common": style.border_color = Color(0.5, 0.5, 0.5)
        "rare": style.border_color = Color(0.2, 0.6, 1.0)
        "epic": style.border_color = Color(0.7, 0.3, 1.0)
        "legendary": style.border_color = Color(1.0, 0.8, 0.2)
        _: style.border_color = Color(0.3, 0.3, 0.3)

    panel.add_theme_stylebox_override("panel", style)

    var vbox := VBoxContainer.new()
    vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    vbox.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
    vbox.add_theme_constant_override("separation", 8)
    vbox.mouse_filter = Control.MOUSE_FILTER_PASS
    panel.add_child(vbox)

    var icon := TextureRect.new()
    icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    icon.custom_minimum_size = card_icon_min_size
    icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    icon.mouse_filter = Control.MOUSE_FILTER_PASS
    vbox.add_child(icon)

    var icon_path := String(item.get("icon", ""))
    if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
        var item_icon_tex = load(icon_path)
        if item_icon_tex:
            icon.texture = item_icon_tex
        else:
            icon.modulate = Color(1.0, 1.0, 1.0, 0.0)
    else:
        icon.modulate = Color(1.0, 1.0, 1.0, 0.0)

    # Name
    var name_lbl := Label.new()
    name_lbl.text = tr(String(item.get("name", "Item")))
    name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    name_lbl.max_lines_visible = 2
    name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_WORD
    name_lbl.clip_text = true
    name_lbl.custom_minimum_size.y = 44.0
    name_lbl.add_theme_font_size_override("font_size", 18)
    name_lbl.mouse_filter = Control.MOUSE_FILTER_PASS
    vbox.add_child(name_lbl)

    # Price
    var id := String(item.get("id", ""))
    var display_price := String(item.get("display_price", ""))
    var price := int(item.get("price", 0))
    var currency := String(item.get("currency", "coins"))
    var price_text := ""
    if id == _DAILY_CLAIM_ITEM_ID:
        price_text = "%d-%d" % [_DAILY_CLAIM_MIN_COINS, _DAILY_CLAIM_MAX_COINS]
    elif display_price.is_empty():
        price_text = str(price)
    else:
        price_text = display_price

    var use_currency_icon := currency == "coins" or currency == "gems"
    var icon_tex: Texture2D = null
    if currency == "coins":
        icon_tex = _coin_icon_tex
    elif currency == "gems":
        icon_tex = _gem_icon_tex

    if use_currency_icon and icon_tex != null and display_price.is_empty():
        var price_row := HBoxContainer.new()
        price_row.alignment = BoxContainer.ALIGNMENT_CENTER
        price_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        price_row.mouse_filter = Control.MOUSE_FILTER_PASS
        price_row.add_theme_constant_override("separation", 8)

        var price_icon := TextureRect.new()
        price_icon.texture = icon_tex
        price_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        price_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        price_icon.custom_minimum_size = Vector2(28, 28)
        price_icon.mouse_filter = Control.MOUSE_FILTER_PASS
        price_row.add_child(price_icon)

        var price_lbl := Label.new()
        price_lbl.text = price_text
        price_lbl.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
        price_lbl.add_theme_font_size_override("font_size", 20)
        price_lbl.mouse_filter = Control.MOUSE_FILTER_PASS
        _apply_shop_number_font(price_lbl)
        price_row.add_child(price_lbl)

        vbox.add_child(price_row)
    else:
        var price_lbl := Label.new()
        var currency_suffix := ""
        if display_price.is_empty():
            if currency == "coins":
                currency_suffix = " " + tr("Coins")
            elif currency == "gems":
                currency_suffix = " " + tr("Gems")
        price_lbl.text = price_text + currency_suffix
        price_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        price_lbl.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
        price_lbl.add_theme_font_size_override("font_size", 20)
        price_lbl.mouse_filter = Control.MOUSE_FILTER_PASS
        _apply_shop_number_font(price_lbl)
        vbox.add_child(price_lbl)

    var is_coming_soon := false
    if id == _DAILY_CLAIM_ITEM_ID:
        is_coming_soon = false
    elif _is_skin_id(id):
        is_coming_soon = true
    else:
        var item_currency := String(item.get("currency", "coins"))
        if item_currency == "real":
            if id.begins_with("gems_") or id.ends_with("_bundle"):
                is_coming_soon = true

    if is_coming_soon:
        var coming_soon_lbl := Label.new()
        coming_soon_lbl.text = tr("Coming Soon")
        coming_soon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        coming_soon_lbl.add_theme_font_size_override("font_size", 14)
        coming_soon_lbl.add_theme_color_override("font_color", Color(1.0, 0.6, 0.0))
        coming_soon_lbl.mouse_filter = Control.MOUSE_FILTER_PASS
        vbox.add_child(coming_soon_lbl)

    var button := Button.new()
    button.text = tr("Claim") if id == _DAILY_CLAIM_ITEM_ID else tr("Buy")
    button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    button.custom_minimum_size = Vector2(0, 40)
    button.mouse_filter = Control.MOUSE_FILTER_PASS
    vbox.add_child(button)

    var entry := {
        "button": button,
        "item": item
    }
    buy_buttons.append(entry)
    button.pressed.connect(Callable(self, "_on_item_buy_pressed").bind(item))
    return panel

func _update_buy_buttons_state() -> void:
    var cosmetics := _load_cosmetics_data()
    var owned_set: Dictionary = {}
    var owned_value = cosmetics.get("owned_skins", [])
    if owned_value is Array:
        for s in owned_value:
            owned_set[String(s)] = true
    var owned_borders_set: Dictionary = {}
    var owned_borders_value = cosmetics.get("owned_borders", [])
    if owned_borders_value is Array:
        for b in owned_borders_value:
            owned_borders_set[String(b)] = true

    var equipped_skin := String(cosmetics.get("equipped_skin", "skin_basic"))
    var equipped_border := String(cosmetics.get("equipped_border", ""))

    for e in buy_buttons:
        if not (e is Dictionary):
            continue
        var b = e.get("button")
        var it = e.get("item")
        if b == null or it == null:
            continue
        if not (b is BaseButton):
            continue
        var id := String(it.get("id", ""))
        var currency := String(it.get("currency", "coins"))

        if id == _DAILY_CLAIM_ITEM_ID:
            var free_claim := _is_daily_free_claim_available()
            var allowed := free_claim or _is_rewarded_available_for_daily_claim()
            (b as BaseButton).disabled = not allowed
            if b is Button:
                if free_claim:
                    (b as Button).text = tr("Claim")
                else:
                    (b as Button).text = tr("Claim") + " +Ad"
            continue

        if _is_skin_id(id):
            var owned := owned_set.has(id)
            var equipped := (equipped_skin == id)
            var price_skin := int(it.get("price", 0))

            if b is Button:
                if equipped:
                    (b as Button).text = tr("Equipped")
                    (b as BaseButton).disabled = true
                elif owned:
                    (b as Button).text = tr("Equip")
                    (b as BaseButton).disabled = false
                else:
                    (b as Button).text = tr("Buy")
                    if currency == "gems":
                        (b as BaseButton).disabled = current_gems < price_skin
                    else:
                        (b as BaseButton).disabled = current_coins < price_skin
            continue

        if _is_border_id(id):
            var owned := owned_borders_set.has(id)
            var equipped := (equipped_border == id)
            var price_border := int(it.get("price", 0))

            if b is Button:
                if equipped:
                    (b as Button).text = tr("Equipped")
                    (b as BaseButton).disabled = true
                elif owned:
                    (b as Button).text = tr("Equip")
                    (b as BaseButton).disabled = false
                else:
                    (b as Button).text = tr("Buy")
                    if currency == "gems":
                        (b as BaseButton).disabled = current_gems < price_border
                    else:
                        (b as BaseButton).disabled = current_coins < price_border
            continue
        var price := int(it.get("price", 0))
        match currency:
            "coins":
                (b as BaseButton).disabled = current_coins < price
            "gems":
                (b as BaseButton).disabled = current_gems < price
            "real":
                (b as BaseButton).disabled = false
            _:
                (b as BaseButton).disabled = true


func _on_item_buy_pressed(item: Dictionary) -> void:
    if not is_inside_tree():
        return
    if _is_recent_scroll_gesture():
        return
    if not Engine.is_editor_hint():
        if is_instance_valid(TransitionManager) and TransitionManager.has_method("play_sfx"):
            TransitionManager.play_sfx(&"click")
    var price := int(item.get("price", 0))
    var currency := String(item.get("currency", "coins"))
    var id := String(item.get("id", ""))

    if id == _DAILY_CLAIM_ITEM_ID:
        _on_daily_claim_pressed()
        return

    if _is_skin_id(id) and _is_skin_owned(id):
        _equip_skin(id)
        return

    if _is_border_id(id) and _is_border_owned(id):
        _equip_border(id)
        return

    # Show confirmation popup
    var confirm_scene := load("res://scenes/ConfirmPanel.tscn") as PackedScene
    if confirm_scene:
        var popup := confirm_scene.instantiate()
        var ui_layer := get_node_or_null("UI") as CanvasLayer
        if ui_layer:
            ui_layer.add_child(popup)
        else:
            add_child(popup)

        var msg := popup.get_node_or_null("Message") as Label
        if msg:
            var currency_name := tr("Coins") if currency == "coins" else (tr("Gems") if currency == "gems" else tr("Money"))
            msg.text = tr("Buy %s\nfor %d %s?") % [tr(String(item.get("name", "Item"))), price, currency_name]

        var yes := popup.get_node_or_null("Buttons/YesButton") as TextureButton
        var no := popup.get_node_or_null("Buttons/NoButton") as TextureButton

        if yes:
            yes.pressed.connect(func():
                popup.queue_free()
                _execute_purchase(item)
            )
        if no:
            no.pressed.connect(func():
                popup.queue_free()
            )
    else:
        # Fallback to direct purchase if popup scene missing
        _execute_purchase(item)

func _execute_purchase(item: Dictionary) -> void:
    if Engine.is_editor_hint():
        return
    var price := int(item.get("price", 0))
    var currency := String(item.get("currency", "coins"))
    var id := String(item.get("id", ""))

    match currency:
        "coins":
            if current_coins < price:
                _set_status_text(tr("Not enough coins."))
                return
            current_coins -= price
            _save_coins(current_coins)
            if _is_skin_id(id):
                _unlock_skin(id)
            elif _is_border_id(id):
                _unlock_border(id)
            else:
                _apply_item_to_powerups(item)

            var coins_label := get_node_or_null("UI/VBox/CurrencyRow/CoinsLabel") as Label
            if coins_label:
                coins_label.text = str(current_coins)
            _build_groups_ui()
            _update_buy_buttons_state()
            _set_status_text(tr("Purchase successful: %s") % tr(String(item.get("name", "Item"))))
        "gems":
            if current_gems < price:
                _set_status_text(tr("Not enough gems."))
                return
            current_gems -= price
            _save_gems(current_gems)
            if _is_skin_id(id):
                _unlock_skin(id)
            elif _is_border_id(id):
                _unlock_border(id)
            else:
                _apply_item_to_powerups(item)

            var gems_label := get_node_or_null("UI/VBox/CurrencyRow/GemsLabel") as Label
            if gems_label:
                gems_label.text = str(current_gems)
            _build_groups_ui()
            _update_buy_buttons_state()
            _set_status_text(tr("Purchase successful: %s") % tr(String(item.get("name", "Item"))))
        "real":
            var ok := _apply_real_purchase(item)
            _build_groups_ui()
            _update_buy_buttons_state()
            _update_buy_buttons_state()
            _set_status_text(tr("Purchase processed.") if ok else tr("Not supported."))
        _:
            _set_status_text(tr("Not supported."))
            return


func _on_language_changed(_locale: String) -> void:
    if not is_inside_tree():
        return
    if Engine.is_editor_hint():
        return
    var title := get_node_or_null("UI/VBox/TitleLabel") as Label
    if title:
        title.text = tr("Shop")
    _build_groups_ui()
    _update_buy_buttons_state()


func _apply_real_purchase(item: Dictionary) -> bool:
    var id := String(item.get("id", ""))
    if id.is_empty():
        return false
    var gems_gain := 0
    var coins_gain := 0
    var powerups_gain: Dictionary = {}
    match id:
        "gems_small":
            gems_gain = 100
        "gems_standard":
            gems_gain = 330
        "gems_big":
            gems_gain = 950
        "gems_mega":
            gems_gain = 2500
        "starter_bundle":
            gems_gain = 100
            coins_gain = 1000
            powerups_gain = {
                "magnet_30s_tokens": 2,
                "shield_1hit_charges": 1,
                "double_coins_run_tokens": 1
            }
        "progress_bundle":
            gems_gain = 250
            coins_gain = 2500
            powerups_gain = {
                "magnet_30s_tokens": 3,
                "shield_1hit_charges": 2,
                "double_coins_run_tokens": 2
            }
        "cosmetic_bundle":
            gems_gain = 200
            coins_gain = 1500
            powerups_gain = {
                "shield_1hit_charges": 2
            }
        _:
            return false

    if coins_gain > 0:
        current_coins += coins_gain
        _save_coins(current_coins)
        var coins_label := get_node_or_null("UI/VBox/CurrencyRow/CoinsLabel") as Label
        if coins_label:
            coins_label.text = str(current_coins)

    if gems_gain > 0:
        current_gems += gems_gain
        _save_gems(current_gems)
        var gems_label := get_node_or_null("UI/VBox/CurrencyRow/GemsLabel") as Label
        if gems_label:
            gems_label.text = str(current_gems)

    if not powerups_gain.is_empty():
        var data := _load_powerups_data()
        for k in powerups_gain.keys():
            data[String(k)] = int(data.get(String(k), 0)) + int(powerups_gain[k])
        _save_powerups_data(data)
    return true


func _apply_item_to_powerups(item: Dictionary) -> void:
    var id := String(item.get("id", ""))
    if id == "":
        return
    var data := _load_powerups_data()
    match id:
        "magnet_30s":
            data["magnet_30s_tokens"] = int(data.get("magnet_30s_tokens", 0)) + 1
        "shield_1hit":
            data["shield_1hit_charges"] = int(data.get("shield_1hit_charges", 0)) + 1
        "double_coins_run":
            data["double_coins_run_tokens"] = int(data.get("double_coins_run_tokens", 0)) + 1
        "max_heart_plus1":
            data["max_heart_bonus"] = int(data.get("max_heart_bonus", 0)) + 1
        "magnet_duration_plus10":
            data["magnet_duration_multiplier"] = float(data.get("magnet_duration_multiplier", 1.0)) + 0.1
        "shield_duration_plus10":
            data["shield_duration_multiplier"] = float(data.get("shield_duration_multiplier", 1.0)) + 0.1
        "pickup_range_plus1":
            data["pickup_range_bonus"] = float(data.get("pickup_range_bonus", 0.0)) + 1.0
        "double_coins_duration_plus10":
            data["double_coins_duration_multiplier"] = float(data.get("double_coins_duration_multiplier", 1.0)) + 0.1
        "double_coins_multiplier_plus025":
            data["double_coins_gain_multiplier"] = float(data.get("double_coins_gain_multiplier", 2.0)) + 0.25
        "speed_boost_duration_plus10":
            data["speed_boost_duration_multiplier"] = float(data.get("speed_boost_duration_multiplier", 1.0)) + 0.1
        "speed_boost_multiplier_plus10":
            data["speed_boost_multiplier_multiplier"] = float(data.get("speed_boost_multiplier_multiplier", 1.0)) + 0.1
        "speed_boost_run":
            data["speed_boost_tokens"] = int(data.get("speed_boost_tokens", 0)) + 1
        _:
            pass
    _save_powerups_data(data)


func _is_skin_id(id: String) -> bool:
    return id.begins_with("skin_")

func _is_border_id(id: String) -> bool:
    return id.begins_with("border_")

func _is_skin_owned(id: String) -> bool:
    var cosmetics := _load_cosmetics_data()
    var owned_value = cosmetics.get("owned_skins", [])
    if owned_value is Array:
        return owned_value.has(id)
    return false

func _is_border_owned(id: String) -> bool:
    var cosmetics := _load_cosmetics_data()
    var owned_value = cosmetics.get("owned_borders", [])
    if owned_value is Array:
        return owned_value.has(id)
    return false

func _unlock_skin(id: String) -> void:
    var cosmetics := _load_cosmetics_data()
    var owned_value = cosmetics.get("owned_skins", [])
    var owned: Array = []
    if owned_value is Array:
        owned = owned_value
    if not owned.has(id):
        owned.append(id)
    cosmetics["owned_skins"] = owned
    # Auto-equip if newly purchased
    cosmetics["equipped_skin"] = id
    _save_cosmetics_data(cosmetics)

func _unlock_border(id: String) -> void:
    var cosmetics := _load_cosmetics_data()
    var owned_value = cosmetics.get("owned_borders", [])
    var owned: Array = []
    if owned_value is Array:
        owned = owned_value
    if not owned.has(id):
        owned.append(id)
    cosmetics["owned_borders"] = owned
    # Auto-equip if newly purchased
    cosmetics["equipped_border"] = id
    _save_cosmetics_data(cosmetics)

func _equip_border(id: String) -> void:
    var cosmetics := _load_cosmetics_data()
    cosmetics["equipped_border"] = id
    _save_cosmetics_data(cosmetics)
    _update_buy_buttons_state()
    _set_status_text(tr("Border equipped!"))

func _equip_skin(id: String) -> void:
    var cosmetics := _load_cosmetics_data()
    cosmetics["equipped_skin"] = id
    _save_cosmetics_data(cosmetics)
    _update_buy_buttons_state()
    _set_status_text(tr("Skin equipped!"))

func _on_back_pressed() -> void:
    if not is_inside_tree():
        return
    if Engine.is_editor_hint():
        return
    if _closing:
        return
    _closing = true
    if is_instance_valid(TransitionManager) and TransitionManager.has_method("play_sfx"):
        TransitionManager.play_sfx(&"click")

    if _ui_vbox:
        var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
        tween.tween_property(_ui_vbox, "modulate:a", 0.0, 0.2)
        tween.tween_property(_ui_vbox, "scale", Vector2(0.9, 0.9), 0.2)
        await tween.finished

    get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _apply_ui_font(node: Node, font: Font) -> void:
    if node is Label:
        (node as Label).add_theme_font_override("font", font)
    elif node is BaseButton:
        (node as BaseButton).add_theme_font_override("font", font)
    for child in node.get_children():
        if child is Node:
            _apply_ui_font(child, font)

func _editor_init_and_build() -> void:
    if not Engine.is_editor_hint(): return
    _init_shop_data()
    _build_groups_ui()
    if _ui_vbox:
        _apply_responsive_layout(get_viewport_rect().size)
    var coins_label := get_node_or_null("UI/VBox/CurrencyRow/CoinsLabel") as Label
    var gems_label := get_node_or_null("UI/VBox/CurrencyRow/GemsLabel") as Label
    if coins_label:
        coins_label.text = "123456789"
        _apply_shop_number_font(coins_label)
    if gems_label:
        gems_label.text = "123456789"
        _apply_shop_number_font(gems_label)

func _set_owner_recursive(node: Node, root: Node) -> void:
    if node != root:
        node.owner = root
    for child in node.get_children():
        _set_owner_recursive(child, root)
