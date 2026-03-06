extends Control

const _TOKEN_ORDER := [
    "magnet_duration",
    "shield_duration",
    "double_coins_duration",
    "speed_boost_duration"
]
const _BANNER_LOCK_ID := "shop_skill_progress_panel"

const _TOKEN_LABEL_MAP := {
    "magnet_duration": "Magnet Tokens",
    "shield_duration": "Shield Charges",
    "double_coins_duration": "Double Coins Tokens",
    "speed_boost_duration": "Speed Boost Tokens"
}

const _TOKEN_ICON_MAP := {
    "magnet_duration": "res://assets/icon/icon_magnet_timer_96x96.png",
    "shield_duration": "res://assets/icon/icon_shield.png",
    "double_coins_duration": "res://assets/icon/icon_coinduble_96x96.png",
    "speed_boost_duration": "res://assets/icon/icon_boost_96x96.png"
}

const _TOKEN_ACCENT_MAP := {
    "magnet_duration": Color(0.08, 0.78, 1.0, 1.0),
    "shield_duration": Color(0.34, 0.84, 1.0, 1.0),
    "double_coins_duration": Color(0.98, 0.77, 0.22, 1.0),
    "speed_boost_duration": Color(0.96, 0.53, 0.18, 1.0)
}

@onready var _overlay: ColorRect = %Overlay
@onready var _panel: PanelContainer = %Panel
@onready var _scroll: ScrollContainer = %Scroll
@onready var _title_label: Label = %TitleLabel
@onready var _close_button: Button = %CloseButton
@onready var _skill_list: HBoxContainer = %SkillList
@onready var _token_panel: PanelContainer = %TokenPanel
@onready var _token_title: Label = %TokenTitle
@onready var _token_grid: GridContainer = %TokenGrid

var _icon_cache: Dictionary = {}
var _title_font: Font = null
var _body_font: Font = null
var _value_font: Font = null
var _last_snapshot: Array = []
var _opening_frame: bool = false
var _closing: bool = false
var _dragging: bool = false
var _drag_pointer_id: int = -1
var _drag_start_x: float = 0.0
var _drag_start_scroll: int = 0
var _layout_busy: bool = false
var _last_layout_size: Vector2 = Vector2.ZERO
var _last_layout_child_count: int = -1
var _banner_lock_active: bool = false
var _last_panel_viewport_size: Vector2 = Vector2.ZERO

func _ready() -> void:
    visible = false
    mouse_filter = Control.MOUSE_FILTER_STOP
    if _close_button and not _close_button.pressed.is_connected(_on_close_pressed):
        _close_button.pressed.connect(_on_close_pressed)
    if _overlay and not _overlay.gui_input.is_connected(_on_overlay_gui_input):
        _overlay.gui_input.connect(_on_overlay_gui_input)
    if _scroll:
        _scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
        _scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
        _scroll.size_flags_vertical = Control.SIZE_FILL
        var scroll_margin := _scroll.get_parent() as Control
        if scroll_margin:
            scroll_margin.size_flags_vertical = Control.SIZE_FILL
        if not _scroll.resized.is_connected(_on_layout_changed):
            _scroll.resized.connect(_on_layout_changed)
    _connect_viewport_resize()
    if GameManager and GameManager.has_signal("powerups_changed"):
        var cb_powerups := Callable(self, "_on_powerups_changed")
        if not GameManager.powerups_changed.is_connected(cb_powerups):
            GameManager.powerups_changed.connect(cb_powerups)
    if TransitionManager and TransitionManager.has_signal("language_changed"):
        var cb_lang := Callable(self, "_on_language_changed")
        if not TransitionManager.language_changed.is_connected(cb_lang):
            TransitionManager.language_changed.connect(cb_lang)
    _load_fonts()
    _apply_visual_theme()
    _apply_panel_layout_for_viewport()
    _refresh_texts()
    call_deferred("_apply_content_layout")

func _exit_tree() -> void:
    _release_banner_lock()
    if GameManager and GameManager.has_signal("powerups_changed"):
        var cb_powerups := Callable(self, "_on_powerups_changed")
        if GameManager.powerups_changed.is_connected(cb_powerups):
            GameManager.powerups_changed.disconnect(cb_powerups)
    if TransitionManager and TransitionManager.has_signal("language_changed"):
        var cb_lang := Callable(self, "_on_language_changed")
        if TransitionManager.language_changed.is_connected(cb_lang):
            TransitionManager.language_changed.disconnect(cb_lang)

func open_panel() -> void:
    _acquire_banner_lock()
    _refresh_texts()
    if visible:
        _refresh_content()
        _apply_content_layout()
        _reset_scroll_position()
        return
    _closing = false
    _dragging = false
    _drag_pointer_id = -1
    visible = true
    _opening_frame = true
    if _overlay:
        _overlay.modulate.a = 0.0
    if _panel:
        _panel.modulate.a = 0.0
    var tw := create_tween().set_parallel(true)
    if _overlay:
        tw.tween_property(_overlay, "modulate:a", 1.0, 0.16)
    if _panel:
        tw.tween_property(_panel, "modulate:a", 1.0, 0.16)
    await get_tree().process_frame
    _refresh_content()
    _apply_content_layout()
    _reset_scroll_position()
    _opening_frame = false

func close_panel() -> void:
    if not visible:
        _release_banner_lock()
        return
    if _closing:
        return
    _closing = true
    _dragging = false
    _drag_pointer_id = -1
    var tw := create_tween().set_parallel(true)
    if _overlay:
        tw.tween_property(_overlay, "modulate:a", 0.0, 0.14)
    if _panel:
        tw.tween_property(_panel, "modulate:a", 0.0, 0.14)
    await tw.finished
    visible = false
    _closing = false
    _release_banner_lock()

func _on_close_pressed() -> void:
    if TransitionManager and TransitionManager.has_method("play_sfx"):
        TransitionManager.play_sfx(&"click")
    close_panel()

func _on_overlay_gui_input(event: InputEvent) -> void:
    if _opening_frame:
        return
    if event is InputEventMouseButton:
        var mb := event as InputEventMouseButton
        if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
            _on_close_pressed()
            return
    if event is InputEventScreenTouch:
        var st := event as InputEventScreenTouch
        if st.pressed:
            _on_close_pressed()

func _on_powerups_changed(_powerups: Dictionary) -> void:
    if visible:
        _refresh_content()

func _on_language_changed(_locale: String) -> void:
    _refresh_texts()
    if visible:
        _refresh_content()

func _on_layout_changed() -> void:
    _apply_panel_layout_for_viewport()
    call_deferred("_apply_content_layout")

func _connect_viewport_resize() -> void:
    var vp := get_viewport()
    if vp == null:
        return
    var cb := Callable(self, "_on_viewport_size_changed")
    if not vp.size_changed.is_connected(cb):
        vp.size_changed.connect(cb)

func _on_viewport_size_changed() -> void:
    _apply_panel_layout_for_viewport()
    call_deferred("_apply_content_layout")

func _apply_panel_layout_for_viewport() -> void:
    if _panel == null:
        return
    var vp := get_viewport()
    if vp == null:
        return
    var vp_size: Vector2 = vp.get_visible_rect().size
    if vp_size.x <= 0.0 or vp_size.y <= 0.0:
        return
    if absf(vp_size.x - _last_panel_viewport_size.x) < 1.0 and absf(vp_size.y - _last_panel_viewport_size.y) < 1.0:
        return
    _last_panel_viewport_size = vp_size

    # Keep the panel compact and responsive across small/medium/large screens.
    var landscape: bool = vp_size.x >= vp_size.y
    var ratio: float = 0.58 if landscape else 0.8
    var min_h: float = 210.0 if landscape else 320.0
    var max_h: float = maxf(vp_size.y - 20.0, min_h)
    var target_h: float = clampf(vp_size.y * ratio, min_h, max_h)
    var top: float = floor((vp_size.y - target_h) * 0.5)
    var bottom: float = top + target_h
    _panel.anchor_top = 0.0
    _panel.anchor_bottom = 0.0
    _panel.offset_top = top
    _panel.offset_bottom = bottom

func _acquire_banner_lock() -> void:
    if _banner_lock_active:
        return
    if AdManager and AdManager.has_method("acquire_banner_lock"):
        AdManager.acquire_banner_lock(_BANNER_LOCK_ID)
    _banner_lock_active = true

func _release_banner_lock() -> void:
    if not _banner_lock_active:
        return
    if AdManager and AdManager.has_method("release_banner_lock"):
        AdManager.release_banner_lock(_BANNER_LOCK_ID)
    _banner_lock_active = false

func _input(event: InputEvent) -> void:
    if _scroll == null or not visible:
        return
    var max_scroll := _get_max_horizontal_scroll()
    if max_scroll <= 0:
        return
    var scroll_rect := _scroll.get_global_rect()
    if scroll_rect.size.x <= 0.0 or scroll_rect.size.y <= 0.0:
        return
    if event is InputEventMouseButton:
        var mb := event as InputEventMouseButton
        if mb.button_index == MOUSE_BUTTON_LEFT:
            if mb.pressed:
                if scroll_rect.has_point(mb.position):
                    _dragging = true
                    _drag_pointer_id = 0
                    _drag_start_x = mb.global_position.x
                    _drag_start_scroll = _scroll.scroll_horizontal
            else:
                if _drag_pointer_id == 0:
                    _dragging = false
                    _drag_pointer_id = -1
        return
    if event is InputEventMouseMotion:
        var mm := event as InputEventMouseMotion
        if _dragging and _drag_pointer_id == 0 and (mm.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
            var dx := mm.global_position.x - _drag_start_x
            _scroll.scroll_horizontal = clampi(_drag_start_scroll - int(dx), 0, max_scroll)
            get_viewport().set_input_as_handled()
        return
    if event is InputEventScreenTouch:
        var st := event as InputEventScreenTouch
        if st.pressed:
            if scroll_rect.has_point(st.position):
                _dragging = true
                _drag_pointer_id = st.index
                _drag_start_x = st.position.x
                _drag_start_scroll = _scroll.scroll_horizontal
        elif st.index == _drag_pointer_id:
            _dragging = false
            _drag_pointer_id = -1
        return
    if event is InputEventScreenDrag:
        var sd := event as InputEventScreenDrag
        if _dragging and sd.index == _drag_pointer_id:
            var dx2 := sd.position.x - _drag_start_x
            _scroll.scroll_horizontal = clampi(_drag_start_scroll - int(dx2), 0, max_scroll)
            get_viewport().set_input_as_handled()

func _get_max_horizontal_scroll() -> int:
    if _scroll == null:
        return 0
    var max_scroll := 0
    var bar := _scroll.get_h_scroll_bar()
    if bar:
        max_scroll = maxi(max_scroll, int(bar.max_value))
    if _skill_list:
        max_scroll = maxi(max_scroll, int(maxf(_skill_list.size.x - _scroll.size.x, 0.0)))
    return maxi(max_scroll, 0)

func _refresh_texts() -> void:
    if _title_label:
        _title_label.text = tr("Skill Progress")
    if _close_button:
        _close_button.text = tr("Tutup")
    if _token_title:
        _token_title.text = tr("Skill Tokens")

func _load_fonts() -> void:
    _title_font = load("res://assets/font/Fredoka Nunito/Fredoka/static/Fredoka-Bold.ttf") as Font
    _body_font = load("res://assets/font/Fredoka Nunito/Nunito/static/Nunito-Medium.ttf") as Font
    _value_font = load("res://assets/font/Fredoka Nunito/Nunito/static/Nunito-Bold.ttf") as Font

func _reset_scroll_position() -> void:
    if _scroll:
        _scroll.scroll_horizontal = 0
        _scroll.scroll_vertical = 0

func _apply_visual_theme() -> void:
    if _overlay:
        _overlay.color = Color(0.01, 0.05, 0.11, 0.62)

    if _panel:
        var panel_style := StyleBoxFlat.new()
        panel_style.bg_color = Color(0.03, 0.09, 0.17, 0.97)
        panel_style.border_color = Color(0.06, 0.72, 0.96, 0.86)
        panel_style.set_border_width_all(2)
        panel_style.set_corner_radius_all(18)
        panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.34)
        panel_style.shadow_size = 10
        panel_style.shadow_offset = Vector2(0, 3)
        _panel.add_theme_stylebox_override("panel", panel_style)

    if _scroll:
        var scroll_style := StyleBoxFlat.new()
        scroll_style.bg_color = Color(0.01, 0.06, 0.12, 0.46)
        scroll_style.set_corner_radius_all(12)
        _scroll.add_theme_stylebox_override("panel", scroll_style)

    if _token_panel:
        var token_style := StyleBoxFlat.new()
        token_style.bg_color = Color(0.02, 0.07, 0.13, 0.95)
        token_style.border_color = Color(0.98, 0.83, 0.2, 0.75)
        token_style.set_border_width_all(1)
        token_style.set_corner_radius_all(12)
        _token_panel.add_theme_stylebox_override("panel", token_style)

    if _title_label:
        if _title_font:
            _title_label.add_theme_font_override("font", _title_font)
        _title_label.add_theme_font_size_override("font_size", 28)
        _title_label.add_theme_color_override("font_color", Color(0.99, 0.87, 0.22, 1.0))
        _title_label.add_theme_constant_override("outline_size", 0)

    if _token_title:
        if _title_font:
            _token_title.add_theme_font_override("font", _title_font)
        _token_title.add_theme_font_size_override("font_size", 19)
        _token_title.add_theme_color_override("font_color", Color(0.99, 0.83, 0.17, 1.0))

    if _close_button:
        if _title_font:
            _close_button.add_theme_font_override("font", _title_font)
        _close_button.add_theme_font_size_override("font_size", 18)
        _close_button.add_theme_color_override("font_color", Color(0.95, 0.96, 1.0, 1.0))
        var close_normal := StyleBoxFlat.new()
        close_normal.bg_color = Color(0.08, 0.2, 0.34, 0.95)
        close_normal.border_color = Color(0.1, 0.74, 0.95, 0.9)
        close_normal.set_border_width_all(2)
        close_normal.set_corner_radius_all(9)
        var close_hover := close_normal.duplicate() as StyleBoxFlat
        close_hover.bg_color = Color(0.1, 0.27, 0.42, 1.0)
        var close_pressed := close_normal.duplicate() as StyleBoxFlat
        close_pressed.bg_color = Color(0.05, 0.12, 0.2, 1.0)
        _close_button.add_theme_stylebox_override("normal", close_normal)
        _close_button.add_theme_stylebox_override("hover", close_hover)
        _close_button.add_theme_stylebox_override("pressed", close_pressed)
        _close_button.add_theme_stylebox_override("focus", close_normal)

func _refresh_content() -> void:
    if _skill_list == null:
        return
    var old_children := _skill_list.get_children()
    for child in old_children:
        _skill_list.remove_child(child)
        child.queue_free()

    var snapshot: Array = []
    if GameManager and GameManager.has_method("get_skill_progress_snapshot"):
        snapshot = GameManager.get_skill_progress_snapshot()
    _last_snapshot = snapshot.duplicate(true)

    for item_any in snapshot:
        if not (item_any is Dictionary):
            continue
        var row: Dictionary = item_any
        var card := _build_skill_card(row)
        _skill_list.add_child(card)

    _last_layout_size = Vector2.ZERO
    _last_layout_child_count = -1
    _refresh_token_inventory(snapshot)
    call_deferred("_apply_content_layout")

func _apply_content_layout() -> void:
    if _layout_busy:
        return
    if _scroll == null or _skill_list == null:
        return
    var size_key := _scroll.size
    if size_key.x <= 0.0 or size_key.y <= 0.0:
        return
    var child_count := 0
    for child in _skill_list.get_children():
        if child is Control:
            child_count += 1
    if absf(size_key.x - _last_layout_size.x) < 1.0 and absf(size_key.y - _last_layout_size.y) < 1.0 and child_count == _last_layout_child_count:
        var max_scroll_unchanged := int(_scroll.get_h_scroll_bar().max_value)
        _scroll.scroll_horizontal = clampi(_scroll.scroll_horizontal, 0, max_scroll_unchanged)
        _update_token_grid_columns()
        return

    _layout_busy = true
    _last_layout_size = size_key
    _last_layout_child_count = child_count
    var basis_h: float = _last_panel_viewport_size.y if _last_panel_viewport_size.y > 0.0 else _scroll.size.y
    var basis_w: float = _last_panel_viewport_size.x if _last_panel_viewport_size.x > 0.0 else _scroll.size.x
    var landscape: bool = basis_w >= basis_h
    var card_height_ratio: float = 0.25 if landscape else 0.2
    var card_height := clampf(basis_h * card_height_ratio, 102.0, 138.0)
    var card_width := clampf(_scroll.size.x * 0.78, 300.0, 500.0)
    var target_scroll_height := card_height + 12.0
    _scroll.custom_minimum_size.y = target_scroll_height
    var scroll_margin := _scroll.get_parent() as Control
    if scroll_margin:
        scroll_margin.custom_minimum_size.y = target_scroll_height
    for child in _skill_list.get_children():
        if child is Control:
            var ctl := child as Control
            ctl.custom_minimum_size = Vector2(card_width, card_height)
    var gap := float(_skill_list.get_theme_constant("separation"))
    var total_width := 24.0
    if child_count > 0:
        total_width += float(child_count) * card_width
        total_width += float(maxi(child_count - 1, 0)) * gap
    _skill_list.custom_minimum_size = Vector2(maxf(total_width, _scroll.size.x), card_height)
    var max_scroll := _get_max_horizontal_scroll()
    _scroll.scroll_horizontal = clampi(_scroll.scroll_horizontal, 0, max_scroll)
    _update_token_grid_columns()
    _layout_busy = false

func _build_skill_card(item: Dictionary) -> Control:
    var category := String(item.get("category", ""))
    var accent := _category_color(category)

    var card := PanelContainer.new()
    card.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
    card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
    card.clip_contents = true
    card.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var card_style := StyleBoxFlat.new()
    card_style.bg_color = Color(0.05, 0.12, 0.2, 0.94)
    card_style.border_color = accent
    card_style.set_border_width_all(1)
    card_style.set_corner_radius_all(12)
    card_style.content_margin_left = 7
    card_style.content_margin_right = 7
    card_style.content_margin_top = 6
    card_style.content_margin_bottom = 6
    card.add_theme_stylebox_override("panel", card_style)

    var root := VBoxContainer.new()
    root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    root.size_flags_vertical = Control.SIZE_EXPAND_FILL
    root.add_theme_constant_override("separation", 5)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    card.add_child(root)

    var top := HBoxContainer.new()
    top.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    top.add_theme_constant_override("separation", 6)
    top.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(top)

    var icon_wrap := PanelContainer.new()
    icon_wrap.custom_minimum_size = Vector2(40, 40)
    icon_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var icon_style := StyleBoxFlat.new()
    icon_style.bg_color = accent.darkened(0.67)
    icon_style.border_color = accent
    icon_style.set_border_width_all(1)
    icon_style.set_corner_radius_all(30)
    icon_wrap.add_theme_stylebox_override("panel", icon_style)
    top.add_child(icon_wrap)

    var icon := TextureRect.new()
    icon.custom_minimum_size = Vector2(24, 24)
    icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var icon_path := String(item.get("icon_path", ""))
    var tex := _get_icon(icon_path)
    if tex:
        icon.texture = tex
    else:
        icon.modulate = Color(1, 1, 1, 0.0)
    icon_wrap.add_child(icon)

    var title_row := HBoxContainer.new()
    title_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
    top.add_child(title_row)

    var title := Label.new()
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title.text = tr(String(item.get("name_key", "")))
    title.autowrap_mode = TextServer.AUTOWRAP_OFF
    title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    title.clip_text = true
    title.mouse_filter = Control.MOUSE_FILTER_IGNORE
    if _title_font:
        title.add_theme_font_override("font", _title_font)
    elif _value_font:
        title.add_theme_font_override("font", _value_font)
    title.add_theme_font_size_override("font_size", 17)
    title.add_theme_color_override("font_color", Color(0.96, 0.97, 1.0, 1.0))
    title_row.add_child(title)

    var lv := Label.new()
    lv.custom_minimum_size = Vector2(72, 20)
    lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    lv.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    lv.text = "%s %d/%d" % [tr("Lv"), int(item.get("level_current", 1)), int(item.get("level_max", 1))]
    if _value_font:
        lv.add_theme_font_override("font", _value_font)
    lv.add_theme_font_size_override("font_size", 13)
    lv.add_theme_color_override("font_color", Color(0.99, 0.86, 0.2, 1.0))
    lv.autowrap_mode = TextServer.AUTOWRAP_OFF
    lv.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    lv.clip_text = true
    lv.mouse_filter = Control.MOUSE_FILTER_IGNORE
    title_row.add_child(lv)

    var progress := ProgressBar.new()
    progress.custom_minimum_size = Vector2(0, 8)
    progress.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    progress.max_value = float(maxi(int(item.get("level_max", 1)), 1))
    progress.value = float(clampi(int(item.get("level_current", 1)), 1, int(progress.max_value)))
    progress.show_percentage = false
    progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var p_bg := StyleBoxFlat.new()
    p_bg.bg_color = Color(0.02, 0.05, 0.09, 0.96)
    p_bg.set_corner_radius_all(6)
    var p_fill := StyleBoxFlat.new()
    p_fill.bg_color = accent
    p_fill.set_corner_radius_all(6)
    progress.add_theme_stylebox_override("background", p_bg)
    progress.add_theme_stylebox_override("fill", p_fill)
    root.add_child(progress)

    var stats := HFlowContainer.new()
    stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    stats.add_theme_constant_override("h_separation", 6)
    stats.add_theme_constant_override("v_separation", 6)
    stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(stats)

    var unit := String(item.get("unit", ""))
    var current_value := _format_value(item.get("current_value"), unit)
    var next_value := (tr("MAX") if bool(item.get("is_max", false)) else _format_value(item.get("next_value"), unit))
    var base_value := _format_value(item.get("base_value"), unit)
    stats.add_child(_make_stat_chip(tr("Current"), current_value, accent))
    stats.add_child(_make_stat_chip(tr("Next"), next_value, accent, true))
    stats.add_child(_make_stat_chip(tr("Base"), base_value, accent))

    return card

func _make_stat_chip(label_text: String, value_text: String, accent: Color, emphasize: bool = false) -> Control:
    var chip := PanelContainer.new()
    chip.size_flags_horizontal = Control.SIZE_FILL
    chip.custom_minimum_size = Vector2(96.0, 36.0)
    chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var chip_style := StyleBoxFlat.new()
    chip_style.bg_color = (accent.darkened(0.8) if emphasize else Color(0.04, 0.09, 0.15, 0.9))
    chip_style.border_color = (accent if emphasize else accent.darkened(0.4))
    chip_style.set_border_width_all(1)
    chip_style.set_corner_radius_all(6)
    chip_style.content_margin_left = 7
    chip_style.content_margin_right = 7
    chip_style.content_margin_top = 4
    chip_style.content_margin_bottom = 4
    chip.add_theme_stylebox_override("panel", chip_style)

    var row := VBoxContainer.new()
    row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_theme_constant_override("separation", 1)
    row.mouse_filter = Control.MOUSE_FILTER_IGNORE
    chip.add_child(row)

    var label := Label.new()
    label.size_flags_horizontal = Control.SIZE_FILL
    label.text = label_text
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    label.autowrap_mode = TextServer.AUTOWRAP_OFF
    label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    label.clip_text = true
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    if _body_font:
        label.add_theme_font_override("font", _body_font)
    label.add_theme_font_size_override("font_size", 9)
    label.add_theme_color_override("font_color", (Color(0.86, 0.95, 1.0, 1.0) if emphasize else Color(0.74, 0.88, 1.0, 0.95)))
    row.add_child(label)

    var value := Label.new()
    value.custom_minimum_size = Vector2(0, 0)
    value.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    value.text = value_text
    value.autowrap_mode = TextServer.AUTOWRAP_OFF
    value.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    value.clip_text = true
    value.mouse_filter = Control.MOUSE_FILTER_IGNORE
    if _value_font:
        value.add_theme_font_override("font", _value_font)
    value.add_theme_font_size_override("font_size", (14 if emphasize else 13))
    value.add_theme_color_override("font_color", (accent.lightened(0.35) if emphasize else Color(0.97, 0.98, 1.0, 1.0)))
    row.add_child(value)

    return chip

func _refresh_token_inventory(snapshot: Array) -> void:
    if _token_grid == null:
        return
    var counts := {
        "magnet_duration": 0,
        "shield_duration": 0,
        "double_coins_duration": 0,
        "speed_boost_duration": 0
    }
    for item_any in snapshot:
        if not (item_any is Dictionary):
            continue
        var item: Dictionary = item_any
        var id := String(item.get("id", ""))
        if counts.has(id):
            counts[id] = int(item.get("token_count", 0))

    for child in _token_grid.get_children():
        child.queue_free()
    _token_grid.add_theme_constant_override("h_separation", 8)
    _token_grid.add_theme_constant_override("v_separation", 8)

    for token_id in _TOKEN_ORDER:
        var accent := Color(_TOKEN_ACCENT_MAP.get(token_id, Color(0.67, 0.79, 0.89, 1.0)))
        var card := PanelContainer.new()
        card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        card.custom_minimum_size.y = 64.0
        var card_style := StyleBoxFlat.new()
        card_style.bg_color = Color(0.05, 0.1, 0.17, 0.92)
        card_style.border_color = accent
        card_style.set_border_width_all(1)
        card_style.set_corner_radius_all(10)
        card_style.content_margin_left = 7
        card_style.content_margin_right = 7
        card_style.content_margin_top = 5
        card_style.content_margin_bottom = 5
        card.add_theme_stylebox_override("panel", card_style)

        var row := HBoxContainer.new()
        row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row.add_theme_constant_override("separation", 6)
        card.add_child(row)

        var icon := TextureRect.new()
        icon.custom_minimum_size = Vector2(24, 24)
        icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        var icon_tex := _get_icon(String(_TOKEN_ICON_MAP.get(token_id, "")))
        if icon_tex:
            icon.texture = icon_tex
        row.add_child(icon)

        var right := VBoxContainer.new()
        right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        right.add_theme_constant_override("separation", 2)
        row.add_child(right)

        var name_lbl := Label.new()
        name_lbl.text = tr(String(_TOKEN_LABEL_MAP.get(token_id, token_id)))
        name_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
        name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
        name_lbl.clip_text = true
        if _body_font:
            name_lbl.add_theme_font_override("font", _body_font)
        name_lbl.add_theme_font_size_override("font_size", 12)
        name_lbl.add_theme_color_override("font_color", Color(0.78, 0.9, 1.0, 0.95))
        right.add_child(name_lbl)

        var value_lbl := Label.new()
        value_lbl.text = str(int(counts.get(token_id, 0)))
        value_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
        if _title_font:
            value_lbl.add_theme_font_override("font", _title_font)
        value_lbl.add_theme_font_size_override("font_size", 20)
        value_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))
        right.add_child(value_lbl)

        _token_grid.add_child(card)

    _update_token_grid_columns()

func _update_token_grid_columns() -> void:
    if _token_grid == null:
        return
    var width_ref := _token_grid.size.x
    if width_ref <= 0.0 and _token_panel:
        width_ref = _token_panel.size.x - 20.0
    var columns := 4
    if width_ref > 0.0 and width_ref < 620.0:
        columns = 2
    _token_grid.columns = columns

func _category_color(category: String) -> Color:
    match category:
        "duration":
            return Color(0.11, 0.78, 1.0, 1.0)
        "gain":
            return Color(0.99, 0.76, 0.23, 1.0)
        "boost":
            return Color(0.95, 0.52, 0.2, 1.0)
        "survivability":
            return Color(0.96, 0.35, 0.44, 1.0)
        "utility":
            return Color(0.49, 0.91, 0.59, 1.0)
        _:
            return Color(0.67, 0.79, 0.89, 1.0)

func _format_value(raw_value: Variant, unit: String) -> String:
    if raw_value == null:
        return "-"
    match unit:
        "heart":
            return str(int(raw_value))
        "s":
            return "%.1fs" % float(raw_value)
        "x":
            return "%.2fx" % float(raw_value)
        "tile":
            return "%.1f tile" % float(raw_value)
        _:
            if raw_value is float:
                return "%.2f" % float(raw_value)
            return str(raw_value)

func _get_icon(path: String) -> Texture2D:
    if path.is_empty():
        return null
    if _icon_cache.has(path):
        return _icon_cache[path]
    if not ResourceLoader.exists(path):
        return null
    var tex := load(path) as Texture2D
    _icon_cache[path] = tex
    return tex
