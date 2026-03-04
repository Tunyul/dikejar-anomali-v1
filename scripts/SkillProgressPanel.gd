extends Control

const _TOKEN_ORDER := [
    "magnet_duration",
    "shield_duration",
    "double_coins_duration",
    "speed_boost_duration"
]

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
    "magnet_duration": Color(0.13, 0.74, 1.0, 1.0),
    "shield_duration": Color(0.48, 0.86, 1.0, 1.0),
    "double_coins_duration": Color(0.99, 0.75, 0.2, 1.0),
    "speed_boost_duration": Color(0.94, 0.48, 0.2, 1.0)
}

@onready var _overlay: ColorRect = %Overlay
@onready var _panel: PanelContainer = %Panel
@onready var _scroll: ScrollContainer = %Scroll
@onready var _title_label: Label = %TitleLabel
@onready var _subtitle_label: Label = %SubtitleLabel
@onready var _close_button: Button = %CloseButton
@onready var _skill_list: BoxContainer = %SkillList
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
var _drag_start_y: float = 0.0
var _drag_start_scroll: int = 0

func _ready() -> void:
    visible = false
    mouse_filter = Control.MOUSE_FILTER_STOP
    if _close_button and not _close_button.pressed.is_connected(_on_close_pressed):
        _close_button.pressed.connect(_on_close_pressed)
    if _overlay and not _overlay.gui_input.is_connected(_on_overlay_gui_input):
        _overlay.gui_input.connect(_on_overlay_gui_input)
    if _scroll and not _scroll.resized.is_connected(_on_layout_changed):
        _scroll.resized.connect(_on_layout_changed)
        _scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
        _scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
        if not _scroll.gui_input.is_connected(_on_scroll_gui_input):
            _scroll.gui_input.connect(_on_scroll_gui_input)
    if _skill_list and not _skill_list.gui_input.is_connected(_on_scroll_gui_input):
        _skill_list.gui_input.connect(_on_scroll_gui_input)
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
    _refresh_texts()
    call_deferred("_apply_content_layout")

func _exit_tree() -> void:
    if GameManager and GameManager.has_signal("powerups_changed"):
        var cb_powerups := Callable(self, "_on_powerups_changed")
        if GameManager.powerups_changed.is_connected(cb_powerups):
            GameManager.powerups_changed.disconnect(cb_powerups)
    if TransitionManager and TransitionManager.has_signal("language_changed"):
        var cb_lang := Callable(self, "_on_language_changed")
        if TransitionManager.language_changed.is_connected(cb_lang):
            TransitionManager.language_changed.disconnect(cb_lang)

func open_panel() -> void:
    _refresh_texts()
    _refresh_content()
    if visible:
        return
    _closing = false
    visible = true
    _opening_frame = true
    _reset_scroll_position()
    _overlay.modulate.a = 0.0
    _panel.modulate.a = 0.0
    var tw := create_tween().set_parallel(true)
    tw.tween_property(_overlay, "modulate:a", 1.0, 0.18)
    tw.tween_property(_panel, "modulate:a", 1.0, 0.18)
    await get_tree().process_frame
    _opening_frame = false

func close_panel() -> void:
    if not visible or _closing:
        return
    _closing = true
    var tw := create_tween().set_parallel(true)
    tw.tween_property(_overlay, "modulate:a", 0.0, 0.15)
    tw.tween_property(_panel, "modulate:a", 0.0, 0.15)
    await tw.finished
    visible = false
    _closing = false

func _on_close_pressed() -> void:
    if is_instance_valid(TransitionManager) and TransitionManager.has_method("play_sfx"):
        TransitionManager.play_sfx(&"click")
    close_panel()

func _on_overlay_gui_input(event: InputEvent) -> void:
    if _opening_frame:
        return
    var is_mouse_close: bool = false
    if event is InputEventMouseButton:
        var mb := event as InputEventMouseButton
        is_mouse_close = mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT
    var is_touch_close: bool = false
    if event is InputEventScreenTouch:
        var st := event as InputEventScreenTouch
        is_touch_close = st.pressed
    if is_mouse_close or is_touch_close:
        _on_close_pressed()

func _on_powerups_changed(_powerups: Dictionary) -> void:
    if visible:
        _refresh_content()

func _on_layout_changed() -> void:
    _apply_content_layout()

func _on_scroll_gui_input(event: InputEvent) -> void:
    if _scroll == null:
        return
    var max_scroll := int(_scroll.get_h_scroll_bar().max_value)
    if event is InputEventMouseButton:
        var mb := event as InputEventMouseButton
        if mb.button_index == MOUSE_BUTTON_LEFT:
            if mb.pressed:
                _dragging = true
                _drag_pointer_id = 0
                _drag_start_y = mb.global_position.x
                _drag_start_scroll = _scroll.scroll_horizontal
            else:
                _dragging = false
                _drag_pointer_id = -1
        return
    if event is InputEventMouseMotion:
        var mm := event as InputEventMouseMotion
        if _dragging and _drag_pointer_id == 0 and (mm.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
            var dx := mm.global_position.x - _drag_start_y
            _scroll.scroll_horizontal = clampi(_drag_start_scroll - int(dx), 0, max_scroll)
            get_viewport().set_input_as_handled()
        return
    if event is InputEventScreenTouch:
        var st := event as InputEventScreenTouch
        if st.pressed:
            _dragging = true
            _drag_pointer_id = st.index
            _drag_start_y = st.position.x
            _drag_start_scroll = _scroll.scroll_horizontal
        elif st.index == _drag_pointer_id:
            _dragging = false
            _drag_pointer_id = -1
        return
    if event is InputEventScreenDrag:
        var sd := event as InputEventScreenDrag
        if _dragging and sd.index == _drag_pointer_id:
            var dx2 := sd.position.x - _drag_start_y
            _scroll.scroll_horizontal = clampi(_drag_start_scroll - int(dx2), 0, max_scroll)
            get_viewport().set_input_as_handled()

func _on_language_changed(_locale: String) -> void:
    _refresh_texts()
    if visible:
        _refresh_content()

func _refresh_texts() -> void:
    if _title_label:
        _title_label.text = tr("Skill Progress")
    if _subtitle_label:
        _subtitle_label.text = ""
        _subtitle_label.visible = false
    if _close_button:
        _close_button.text = tr("Tutup")
    if _token_title:
        _token_title.text = tr("Skill Tokens")

func _load_fonts() -> void:
    _title_font = load("res://assets/font/Fredoka Nunito/Fredoka/static/Fredoka-SemiBold.ttf") as Font
    _body_font = load("res://assets/font/Fredoka Nunito/Nunito/static/Nunito-Medium.ttf") as Font
    _value_font = load("res://assets/font/Fredoka Nunito/Nunito/static/Nunito-Bold.ttf") as Font

func _reset_scroll_position() -> void:
    if _scroll == null:
        return
    _scroll.scroll_horizontal = 0
    _scroll.scroll_vertical = 0

func _apply_visual_theme() -> void:
    _overlay.color = Color(0.02, 0.05, 0.1, 0.62)
    if _panel:
        var frame := StyleBoxFlat.new()
        frame.bg_color = Color(0.04, 0.09, 0.16, 0.96)
        frame.border_color = Color(0.08, 0.68, 0.9, 0.82)
        frame.set_border_width_all(2)
        frame.set_corner_radius_all(16)
        frame.shadow_color = Color(0.0, 0.0, 0.0, 0.4)
        frame.shadow_size = 10
        frame.shadow_offset = Vector2(0, 3)
        _panel.add_theme_stylebox_override("panel", frame)
    if _token_panel:
        var token_box := StyleBoxFlat.new()
        token_box.bg_color = Color(0.03, 0.07, 0.12, 0.9)
        token_box.border_color = Color(0.98, 0.8, 0.15, 0.5)
        token_box.set_border_width_all(1)
        token_box.set_corner_radius_all(10)
        token_box.content_margin_left = 8
        token_box.content_margin_right = 8
        token_box.content_margin_top = 8
        token_box.content_margin_bottom = 8
        _token_panel.add_theme_stylebox_override("panel", token_box)
    if _scroll:
        var scroll_bg := StyleBoxFlat.new()
        scroll_bg.bg_color = Color(0.02, 0.06, 0.1, 0.3)
        scroll_bg.set_corner_radius_all(12)
        _scroll.add_theme_stylebox_override("panel", scroll_bg)
    if _title_label:
        if _title_font:
            _title_label.add_theme_font_override("font", _title_font)
        _title_label.add_theme_font_size_override("font_size", 28)
        _title_label.add_theme_color_override("font_color", Color(0.99, 0.87, 0.22, 1.0))
        _title_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.0))
        _title_label.add_theme_constant_override("outline_size", 0)
    if _subtitle_label:
        if _body_font:
            _subtitle_label.add_theme_font_override("font", _body_font)
        _subtitle_label.add_theme_color_override("font_color", Color(0.76, 0.9, 1.0, 0.9))
        _subtitle_label.add_theme_font_size_override("font_size", 13)
    if _token_title:
        if _title_font:
            _token_title.add_theme_font_override("font", _title_font)
        _token_title.add_theme_color_override("font_color", Color(0.99, 0.83, 0.17, 1.0))
        _token_title.add_theme_font_size_override("font_size", 20)
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
        close_hover.bg_color = Color(0.1, 0.26, 0.42, 1.0)
        var close_pressed := close_normal.duplicate() as StyleBoxFlat
        close_pressed.bg_color = Color(0.04, 0.11, 0.2, 1.0)
        _close_button.add_theme_stylebox_override("normal", close_normal)
        _close_button.add_theme_stylebox_override("hover", close_hover)
        _close_button.add_theme_stylebox_override("pressed", close_pressed)
        _close_button.add_theme_stylebox_override("focus", close_normal)

func _animate_rows() -> void:
    if _skill_list == null:
        return
    for child in _skill_list.get_children():
        if not (child is Control):
            continue
        var c := child as Control
        c.modulate.a = 1.0

func _category_color(category: String) -> Color:
    match category:
        "duration":
            return Color(0.13, 0.74, 1.0, 1.0)
        "gain":
            return Color(0.99, 0.75, 0.2, 1.0)
        "boost":
            return Color(0.94, 0.48, 0.2, 1.0)
        "survivability":
            return Color(0.95, 0.34, 0.42, 1.0)
        "utility":
            return Color(0.47, 0.91, 0.58, 1.0)
        _:
            return Color(0.67, 0.79, 0.89, 1.0)

func _refresh_content() -> void:
    for child in _skill_list.get_children():
        child.queue_free()
    var snapshot: Array = []
    if GameManager and GameManager.has_method("get_skill_progress_snapshot"):
        snapshot = GameManager.get_skill_progress_snapshot()
    _last_snapshot = snapshot.duplicate(true)
    for item_any in snapshot:
        if not (item_any is Dictionary):
            continue
        var row := _build_skill_row(item_any)
        _skill_list.add_child(row)
    _apply_content_layout()
    _refresh_token_inventory(snapshot)
    _animate_rows()

func _apply_content_layout() -> void:
    if _skill_list == null:
        return
    var card_width := 320.0
    var card_height := 138.0
    if _scroll:
        card_height = clampf(_scroll.size.y * 0.86, 120.0, 182.0)
        card_width = clampf(card_height * 2.05, 300.0, 388.0)
    var child_count := 0
    for child in _skill_list.get_children():
        if child is Control:
            var ctl := child as Control
            ctl.custom_minimum_size = Vector2(card_width, card_height)
            child_count += 1
    var gap := 10.0
    if _skill_list is BoxContainer:
        var box := _skill_list as BoxContainer
        gap = float(box.get_theme_constant("separation"))
    var total_width := 12.0
    if child_count > 0:
        total_width += float(child_count) * card_width
        total_width += float(maxi(child_count - 1, 0)) * gap
    _skill_list.custom_minimum_size = Vector2(maxf(total_width, card_width), card_height)
    if _scroll:
        var max_scroll := int(_scroll.get_h_scroll_bar().max_value)
        _scroll.scroll_horizontal = clampi(_scroll.scroll_horizontal, 0, max_scroll)
    _update_token_grid_columns()

func _build_skill_row(item: Dictionary) -> Control:
    var panel := PanelContainer.new()
    panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
    panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    panel.custom_minimum_size.y = 138.0
    panel.clip_contents = true
    panel.mouse_filter = Control.MOUSE_FILTER_PASS
    var category := String(item.get("category", ""))
    var accent := _category_color(category)
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.06, 0.12, 0.2, 0.92)
    style.border_color = accent.lerp(Color(1.0, 1.0, 1.0, 1.0), 0.1)
    style.set_border_width_all(1)
    style.set_corner_radius_all(11)
    style.content_margin_left = 0
    style.content_margin_right = 0
    style.content_margin_top = 0
    style.content_margin_bottom = 0
    panel.add_theme_stylebox_override("panel", style)

    var frame := HBoxContainer.new()
    frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
    frame.add_theme_constant_override("separation", 0)
    frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
    panel.add_child(frame)

    var accent_bar := ColorRect.new()
    accent_bar.color = accent
    accent_bar.custom_minimum_size = Vector2(5, 0)
    accent_bar.size_flags_vertical = Control.SIZE_EXPAND_FILL
    accent_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
    frame.add_child(accent_bar)

    var content_margin := MarginContainer.new()
    content_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
    content_margin.add_theme_constant_override("margin_left", 9)
    content_margin.add_theme_constant_override("margin_right", 9)
    content_margin.add_theme_constant_override("margin_top", 8)
    content_margin.add_theme_constant_override("margin_bottom", 8)
    content_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
    frame.add_child(content_margin)

    var hbox := HBoxContainer.new()
    hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
    hbox.add_theme_constant_override("separation", 9)
    hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
    content_margin.add_child(hbox)

    var icon_wrap := PanelContainer.new()
    icon_wrap.custom_minimum_size = Vector2(42, 42)
    icon_wrap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    icon_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var icon_style := StyleBoxFlat.new()
    icon_style.bg_color = accent.darkened(0.65)
    icon_style.border_color = accent
    icon_style.set_border_width_all(2)
    icon_style.set_corner_radius_all(28)
    icon_wrap.add_theme_stylebox_override("panel", icon_style)
    hbox.add_child(icon_wrap)

    var icon := TextureRect.new()
    icon.custom_minimum_size = Vector2(28, 28)
    icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    icon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var icon_path := String(item.get("icon_path", ""))
    var tex := _get_icon(icon_path)
    if tex:
        icon.texture = tex
    else:
        icon.modulate = Color(1, 1, 1, 0.0)
    icon_wrap.add_child(icon)

    var body := VBoxContainer.new()
    body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    body.size_flags_vertical = Control.SIZE_EXPAND_FILL
    body.add_theme_constant_override("separation", 7)
    body.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hbox.add_child(body)

    var top_row := HBoxContainer.new()
    top_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    top_row.add_theme_constant_override("separation", 6)
    top_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
    body.add_child(top_row)

    var name_lbl := Label.new()
    name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    name_lbl.custom_minimum_size.y = 24.0
    name_lbl.text = tr(String(item.get("name_key", "")))
    if _title_font:
        name_lbl.add_theme_font_override("font", _title_font)
    elif _value_font:
        name_lbl.add_theme_font_override("font", _value_font)
    name_lbl.add_theme_font_size_override("font_size", 17)
    name_lbl.add_theme_color_override("font_color", Color(0.96, 0.96, 0.99, 1.0))
    name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    name_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
    name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    name_lbl.clip_text = true
    name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
    top_row.add_child(name_lbl)

    var lv_lbl := Label.new()
    lv_lbl.custom_minimum_size = Vector2(74, 22)
    lv_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    lv_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    lv_lbl.text = "%s %d/%d" % [
        tr("Lv"),
        int(item.get("level_current", 1)),
        int(item.get("level_max", 1))
    ]
    if _value_font:
        lv_lbl.add_theme_font_override("font", _value_font)
    elif _title_font:
        lv_lbl.add_theme_font_override("font", _title_font)
    lv_lbl.add_theme_font_size_override("font_size", 15)
    lv_lbl.add_theme_color_override("font_color", Color(1.0, 0.86, 0.24, 1.0))
    lv_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    lv_lbl.clip_text = true
    lv_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
    top_row.add_child(lv_lbl)

    var progress := ProgressBar.new()
    progress.custom_minimum_size = Vector2(0, 7)
    progress.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    progress.max_value = float(maxi(int(item.get("level_max", 1)), 1))
    progress.value = float(clampi(int(item.get("level_current", 1)), 1, int(progress.max_value)))
    progress.show_percentage = false
    progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var pb_bg := StyleBoxFlat.new()
    pb_bg.bg_color = Color(0.02, 0.04, 0.08, 0.95)
    pb_bg.set_corner_radius_all(5)
    var pb_fill := StyleBoxFlat.new()
    pb_fill.bg_color = accent
    pb_fill.set_corner_radius_all(5)
    progress.add_theme_stylebox_override("background", pb_bg)
    progress.add_theme_stylebox_override("fill", pb_fill)
    body.add_child(progress)

    var stats_row := VBoxContainer.new()
    stats_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    stats_row.add_theme_constant_override("separation", 5)
    stats_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
    body.add_child(stats_row)

    var unit := String(item.get("unit", ""))
    var current_value := _format_value(item.get("current_value"), unit)
    var next_value := tr("MAX") if bool(item.get("is_max", false)) else _format_value(item.get("next_value"), unit)
    stats_row.add_child(_make_value_pill(tr("Current"), current_value, accent))
    stats_row.add_child(_make_value_pill(tr("Next"), next_value, accent))

    return panel

func _make_value_pill(label_text: String, value_text: String, accent: Color) -> Control:
    var block := PanelContainer.new()
    block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    block.custom_minimum_size.y = 28.0
    block.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var block_style := StyleBoxFlat.new()
    block_style.bg_color = Color(0.05, 0.09, 0.15, 0.9)
    block_style.border_color = accent.darkened(0.4)
    block_style.set_border_width_all(1)
    block_style.set_corner_radius_all(6)
    block_style.content_margin_left = 6
    block_style.content_margin_right = 6
    block_style.content_margin_top = 2
    block_style.content_margin_bottom = 2
    block.add_theme_stylebox_override("panel", block_style)

    var row := HBoxContainer.new()
    row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_theme_constant_override("separation", 8)
    row.mouse_filter = Control.MOUSE_FILTER_IGNORE
    block.add_child(row)

    var title_lbl := Label.new()
    title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    title_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    title_lbl.text = label_text
    title_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
    title_lbl.clip_text = true
    title_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    if _body_font:
        title_lbl.add_theme_font_override("font", _body_font)
    title_lbl.add_theme_font_size_override("font_size", 12)
    title_lbl.add_theme_color_override("font_color", Color(0.76, 0.88, 0.98, 0.94))
    title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
    row.add_child(title_lbl)

    var value_lbl := Label.new()
    value_lbl.custom_minimum_size.x = 96.0
    value_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    value_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    value_lbl.text = value_text
    value_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
    value_lbl.clip_text = true
    value_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    if _value_font:
        value_lbl.add_theme_font_override("font", _value_font)
    elif _body_font:
        value_lbl.add_theme_font_override("font", _body_font)
    value_lbl.add_theme_font_size_override("font_size", 12)
    value_lbl.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0, 1.0))
    value_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
    row.add_child(value_lbl)
    return block

func _refresh_token_inventory(snapshot: Array) -> void:
    var counts := {
        "magnet_duration": 0,
        "shield_duration": 0,
        "double_coins_duration": 0,
        "speed_boost_duration": 0
    }
    for item_any in snapshot:
        if not (item_any is Dictionary):
            continue
        var id := String(item_any.get("id", ""))
        if counts.has(id):
            counts[id] = int(item_any.get("token_count", 0))

    for child in _token_grid.get_children():
        child.queue_free()

    _update_token_grid_columns()
    _token_grid.add_theme_constant_override("h_separation", 10)
    _token_grid.add_theme_constant_override("v_separation", 10)

    for token_id in _TOKEN_ORDER:
        var accent := Color(_TOKEN_ACCENT_MAP.get(token_id, Color(0.67, 0.79, 0.89, 1.0)))
        var token_card := PanelContainer.new()
        token_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        token_card.custom_minimum_size.y = 72.0
        token_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
        var token_style := StyleBoxFlat.new()
        token_style.bg_color = Color(0.05, 0.1, 0.17, 0.9)
        token_style.border_color = accent
        token_style.set_border_width_all(1)
        token_style.set_corner_radius_all(9)
        token_style.content_margin_left = 8
        token_style.content_margin_right = 8
        token_style.content_margin_top = 6
        token_style.content_margin_bottom = 6
        token_card.add_theme_stylebox_override("panel", token_style)

        var row := HBoxContainer.new()
        row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row.add_theme_constant_override("separation", 8)
        row.mouse_filter = Control.MOUSE_FILTER_IGNORE
        token_card.add_child(row)

        var icon := TextureRect.new()
        icon.custom_minimum_size = Vector2(28, 28)
        icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
        var icon_tex := _get_icon(String(_TOKEN_ICON_MAP.get(token_id, "")))
        if icon_tex:
            icon.texture = icon_tex
        row.add_child(icon)

        var right := VBoxContainer.new()
        right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        right.add_theme_constant_override("separation", 2)
        right.mouse_filter = Control.MOUSE_FILTER_IGNORE
        row.add_child(right)

        var label_text := tr(String(_TOKEN_LABEL_MAP.get(token_id, token_id)))
        var name_lbl := Label.new()
        if _body_font:
            name_lbl.add_theme_font_override("font", _body_font)
        name_lbl.add_theme_font_size_override("font_size", 13)
        name_lbl.add_theme_color_override("font_color", Color(0.78, 0.9, 1.0, 0.95))
        name_lbl.text = label_text
        name_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
        name_lbl.clip_text = true
        name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
        right.add_child(name_lbl)

        var value_lbl := Label.new()
        if _title_font:
            value_lbl.add_theme_font_override("font", _title_font)
        value_lbl.add_theme_font_size_override("font_size", 24)
        value_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))
        value_lbl.text = str(int(counts.get(token_id, 0)))
        value_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
        value_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
        right.add_child(value_lbl)

        _token_grid.add_child(token_card)

func _update_token_grid_columns() -> void:
    if _token_grid == null:
        return
    var width_ref := _token_grid.size.x
    if width_ref <= 0.0 and _token_panel:
        width_ref = _token_panel.size.x - 16.0
    var columns := 4
    if width_ref > 0.0 and width_ref < 560.0:
        columns = 2
    if _token_grid.columns != columns:
        _token_grid.columns = columns

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
