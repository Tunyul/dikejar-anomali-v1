@tool
extends Control

const _TOKEN_ORDER := [
    "magnet_duration",
    "shield_duration",
    "double_coins_duration",
    "speed_boost_duration"
]
const _BANNER_LOCK_ID := "shop_skill_progress_panel"
const _RESP_SMALL_W := 820.0
const _RESP_LARGE_W := 1100.0
const _PREVIEW_SNAPSHOT: Array[Dictionary] = [
    {
        "id": "magnet_duration",
        "name_key": "Magnet Duration",
        "category": "duration",
        "level_current": 3,
        "level_max": 21,
        "is_max": false,
        "base_value": 30.0,
        "current_value": 36.0,
        "next_value": 39.0,
        "unit": "s",
        "token_count": 7,
        "icon_path": "res://assets/icon/icon_magnet_timer_96x96.png"
    },
    {
        "id": "shield_duration",
        "name_key": "Shield Duration",
        "category": "duration",
        "level_current": 5,
        "level_max": 21,
        "is_max": false,
        "base_value": 12.0,
        "current_value": 16.8,
        "next_value": 18.0,
        "unit": "s",
        "token_count": 4,
        "icon_path": "res://assets/icon/icon_shield.png"
    },
    {
        "id": "double_coins_duration",
        "name_key": "Double Coins Duration",
        "category": "duration",
        "level_current": 2,
        "level_max": 21,
        "is_max": false,
        "base_value": 15.0,
        "current_value": 16.5,
        "next_value": 18.0,
        "unit": "s",
        "token_count": 3,
        "icon_path": "res://assets/icon/icon_coinduble_96x96.png"
    },
    {
        "id": "speed_boost_duration",
        "name_key": "Speed Boost Duration",
        "category": "boost",
        "level_current": 4,
        "level_max": 21,
        "is_max": false,
        "base_value": 8.0,
        "current_value": 10.4,
        "next_value": 11.2,
        "unit": "s",
        "token_count": 2,
        "icon_path": "res://assets/icon/icon_boost_96x96.png"
    }
]

const _TOKEN_LABEL_MAP := {
    "magnet_duration": "Magnet",
    "shield_duration": "Shield",
    "double_coins_duration": "Double Coins",
    "speed_boost_duration": "Speed Boost"
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
var _debug_snapshot: Array = []
var _last_token_columns: int = -1

func _ready() -> void:
    if Engine.is_editor_hint():
        _setup_editor_preview()
        return
    visible = false
    mouse_filter = Control.MOUSE_FILTER_STOP
    if _close_button and not _close_button.pressed.is_connected(_on_close_pressed):
        _close_button.pressed.connect(_on_close_pressed)
    if _overlay and not _overlay.gui_input.is_connected(_on_overlay_gui_input):
        _overlay.gui_input.connect(_on_overlay_gui_input)
    _configure_scroll_container()
    _connect_viewport_resize()
    if GameManager and GameManager.has_signal("powerups_changed"):
        var cb_powerups := Callable(self, "_on_powerups_changed")
        if not GameManager.is_connected("powerups_changed", cb_powerups):
            GameManager.connect("powerups_changed", cb_powerups)
    if TransitionManager and TransitionManager.has_signal("language_changed"):
        var cb_lang := Callable(self, "_on_language_changed")
        if not TransitionManager.is_connected("language_changed", cb_lang):
            TransitionManager.connect("language_changed", cb_lang)
    _load_fonts()
    _apply_visual_theme()
    _apply_panel_layout_for_viewport()
    _refresh_texts()
    call_deferred("_apply_content_layout")
    if _is_standalone_preview_context():
        call_deferred("_open_preview_mode")

func _exit_tree() -> void:
    _release_banner_lock()
    if GameManager and GameManager.has_signal("powerups_changed"):
        var cb_powerups := Callable(self, "_on_powerups_changed")
        if GameManager.is_connected("powerups_changed", cb_powerups):
            GameManager.disconnect("powerups_changed", cb_powerups)
    if TransitionManager and TransitionManager.has_signal("language_changed"):
        var cb_lang := Callable(self, "_on_language_changed")
        if TransitionManager.is_connected("language_changed", cb_lang):
            TransitionManager.disconnect("language_changed", cb_lang)

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
    var layout_rect := _get_safe_layout_rect()
    var vp_size := layout_rect.size
    _apply_responsive_chrome(vp_size.x)
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
    var side_margin: float
    if vp_size.x < _RESP_SMALL_W:
        side_margin = 12.0
    elif vp_size.x >= _RESP_LARGE_W:
        side_margin = 24.0
    else:
        side_margin = 18.0
    var left: float = layout_rect.position.x + side_margin
    var right: float = layout_rect.position.x + vp_size.x - side_margin
    var top: float = layout_rect.position.y + floor((vp_size.y - target_h) * 0.5)
    var bottom: float = top + target_h
    _panel.anchor_left = 0.0
    _panel.anchor_right = 0.0
    _panel.offset_left = left
    _panel.offset_right = right
    _panel.anchor_top = 0.0
    _panel.anchor_bottom = 0.0
    _panel.offset_top = top
    _panel.offset_bottom = bottom

func _fit_panel_height_to_content() -> void:
    if _panel == null:
        return
    var layout_rect := _get_safe_layout_rect()
    var vp_size := layout_rect.size
    if vp_size.x <= 0.0 or vp_size.y <= 0.0:
        return
    var vbox := _panel.get_node_or_null("VBox") as VBoxContainer
    if vbox == null:
        return
    var content_h := _measure_vbox_content_height(vbox)
    if content_h <= 0.0:
        content_h = vbox.get_combined_minimum_size().y
    if content_h <= 0.0:
        content_h = vbox.size.y
    if content_h <= 0.0:
        return

    var landscape: bool = vp_size.x >= vp_size.y
    var base_min_h: float = 150.0 if landscape else 200.0
    var max_h: float = maxf(vp_size.y - 20.0, base_min_h)
    var desired_h: float = content_h + 8.0
    var target_h: float = clampf(maxf(desired_h, base_min_h), base_min_h, max_h)
    var top: float = layout_rect.position.y + floor((vp_size.y - target_h) * 0.5)
    var bottom: float = top + target_h
    _panel.anchor_top = 0.0
    _panel.anchor_bottom = 0.0
    _panel.offset_top = top
    _panel.offset_bottom = bottom

func _measure_vbox_content_height(vbox: VBoxContainer) -> float:
    var total := 0.0
    var visible_count := 0
    for child in vbox.get_children():
        if not (child is Control):
            continue
        var ctl := child as Control
        if not ctl.visible:
            continue
        visible_count += 1
        var h := ctl.get_combined_minimum_size().y
        if h <= 0.0:
            h = ctl.custom_minimum_size.y
        if h <= 0.0:
            h = ctl.size.y
        total += maxf(h, 0.0)
    if visible_count > 1:
        total += float(vbox.get_theme_constant("separation")) * float(visible_count - 1)
    return total

func _apply_responsive_chrome(width: float) -> void:
    if width <= 0.0:
        return

    var compact: bool = width < _RESP_SMALL_W
    var large: bool = width >= _RESP_LARGE_W
    var side_pad: int = 12 if compact else (20 if large else 16)
    var top_pad: int = 10 if compact else (14 if large else 12)
    var section_sep: int = 8 if compact else (12 if large else 10)
    var row_gap: int = 6 if compact else (10 if large else 8)
    var close_w: float = 112.0 if compact else (140.0 if large else 126.0)
    var close_h: float = 42.0 if compact else (50.0 if large else 46.0)
    var title_font_size: int = 27 if compact else (34 if large else 31)
    var token_title_font_size: int = 20 if compact else (24 if large else 22)
    var close_font_size: int = 17 if compact else (21 if large else 19)
    var token_inner_lr: int = 8 if compact else (11 if large else 10)
    var token_inner_tb: int = 4 if compact else (7 if large else 6)

    var vbox := _panel.get_node_or_null("VBox") as VBoxContainer
    if vbox:
        vbox.add_theme_constant_override("separation", section_sep)

    var header_margin := _panel.get_node_or_null("VBox/HeaderMargin") as MarginContainer
    if header_margin:
        header_margin.add_theme_constant_override("margin_left", side_pad)
        header_margin.add_theme_constant_override("margin_right", side_pad)
        header_margin.add_theme_constant_override("margin_top", top_pad)

    var header_row := _panel.get_node_or_null("VBox/HeaderMargin/HeaderRow") as HBoxContainer
    if header_row:
        header_row.add_theme_constant_override("separation", row_gap)

    var scroll_margin := _panel.get_node_or_null("VBox/ScrollMargin") as MarginContainer
    if scroll_margin:
        scroll_margin.add_theme_constant_override("margin_left", side_pad)
        scroll_margin.add_theme_constant_override("margin_right", side_pad)

    var token_panel_margin := _panel.get_node_or_null("VBox/TokenPanelMargin") as MarginContainer
    if token_panel_margin:
        token_panel_margin.add_theme_constant_override("margin_left", side_pad)
        token_panel_margin.add_theme_constant_override("margin_right", side_pad)
        token_panel_margin.add_theme_constant_override("margin_bottom", (8 if compact else (10 if large else 9)))

    var token_margin := _panel.get_node_or_null("VBox/TokenPanelMargin/TokenPanel/TokenMargin") as MarginContainer
    if token_margin:
        token_margin.add_theme_constant_override("margin_left", token_inner_lr)
        token_margin.add_theme_constant_override("margin_right", token_inner_lr)
        token_margin.add_theme_constant_override("margin_top", token_inner_tb)
        token_margin.add_theme_constant_override("margin_bottom", token_inner_tb)

    if _title_label:
        _title_label.add_theme_font_size_override("font_size", title_font_size)
    if _token_title:
        _token_title.add_theme_font_size_override("font_size", token_title_font_size)
    if _close_button:
        _close_button.custom_minimum_size = Vector2(close_w, close_h)
        _close_button.add_theme_font_size_override("font_size", close_font_size)
    if _skill_list:
        _skill_list.add_theme_constant_override("separation", (8 if compact else (12 if large else 10)))

func _get_layout_reference_rect() -> Rect2:
    if Engine.is_editor_hint():
        if _overlay:
            var overlay_rect := _overlay.get_rect()
            if overlay_rect.size.x > 0.0 and overlay_rect.size.y > 0.0:
                return overlay_rect
        var vw := float(ProjectSettings.get_setting("display/window/size/viewport_width", 1024))
        var vh := float(ProjectSettings.get_setting("display/window/size/viewport_height", 576))
        if vw > 0.0 and vh > 0.0:
            return Rect2(Vector2.ZERO, Vector2(vw, vh))
        if size.x > 0.0 and size.y > 0.0:
            return Rect2(Vector2.ZERO, size)
    var vp := get_viewport()
    if vp == null:
        return Rect2()
    return vp.get_visible_rect()

func _get_safe_layout_rect() -> Rect2:
    var layout_rect := _get_layout_reference_rect()
    if not (OS.has_feature("android") or OS.has_feature("ios")):
        return layout_rect
    var sa := DisplayServer.get_display_safe_area()
    if sa.size.x <= 0 or sa.size.y <= 0:
        return layout_rect
    if OS.has_feature("android"):
        var inset_top := maxf(float(sa.position.y), 0.0)
        var inset_bottom := maxf(layout_rect.size.y - (float(sa.position.y) + float(sa.size.y)), 0.0)
        return Rect2(
            Vector2(layout_rect.position.x, layout_rect.position.y + inset_top),
            Vector2(layout_rect.size.x, maxf(layout_rect.size.y - inset_top - inset_bottom, 1.0))
        )
    var safe_rect := Rect2(Vector2(sa.position), Vector2(sa.size))
    var merged := layout_rect.intersection(safe_rect)
    if merged.size.x <= 0.0 or merged.size.y <= 0.0:
        return safe_rect
    return merged

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

func _setup_editor_preview() -> void:
    visible = true
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    _configure_scroll_container()
    _load_fonts()
    _apply_visual_theme()
    _apply_panel_layout_for_viewport()
    _refresh_texts()
    set_debug_snapshot(_PREVIEW_SNAPSHOT)
    _refresh_content()
    call_deferred("_apply_content_layout")
    call_deferred("_fit_panel_height_to_content")
    _reset_scroll_position()

func _open_preview_mode() -> void:
    if not _debug_snapshot.is_empty():
        open_panel()
        return
    set_debug_snapshot(_PREVIEW_SNAPSHOT)
    open_panel()

func set_debug_snapshot(snapshot: Array) -> void:
    _debug_snapshot = snapshot.duplicate(true)
    if visible:
        _refresh_content()
        _apply_content_layout()

func _is_standalone_preview_context() -> bool:
    if Engine.is_editor_hint():
        return false
    var tree := get_tree()
    return tree != null and tree.current_scene == self

func _configure_scroll_container() -> void:
    if _scroll == null:
        return
    _scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
    _scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    _scroll.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
    var scroll_margin := _scroll.get_parent() as Control
    if scroll_margin:
        scroll_margin.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
    if not _scroll.resized.is_connected(_on_layout_changed):
        _scroll.resized.connect(_on_layout_changed)

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

    var snapshot: Array = _debug_snapshot.duplicate(true)
    if snapshot.is_empty() and GameManager and GameManager.has_method("get_skill_progress_snapshot"):
        snapshot = GameManager.get_skill_progress_snapshot()
    if snapshot.is_empty() and _is_standalone_preview_context():
        snapshot = _PREVIEW_SNAPSHOT.duplicate(true)
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
        _fit_panel_height_to_content()
        call_deferred("_fit_panel_height_to_content")
        return

    _layout_busy = true
    _last_layout_size = size_key
    _last_layout_child_count = child_count
    var basis_h: float = _last_panel_viewport_size.y if _last_panel_viewport_size.y > 0.0 else _scroll.size.y
    var basis_w: float = _last_panel_viewport_size.x if _last_panel_viewport_size.x > 0.0 else _scroll.size.x
    var landscape: bool = basis_w >= basis_h
    var card_height_ratio: float
    var card_min_h: float
    var card_max_h: float
    var card_width_ratio: float
    if basis_w >= 1100.0:
        card_height_ratio = (0.35 if landscape else 0.29)
        card_min_h = 170.0
        card_max_h = 226.0
        card_width_ratio = 0.62
    elif basis_w >= 820.0:
        card_height_ratio = (0.32 if landscape else 0.27)
        card_min_h = 152.0
        card_max_h = 208.0
        card_width_ratio = 0.74
    else:
        card_height_ratio = 0.29
        card_min_h = 138.0
        card_max_h = 188.0
        card_width_ratio = 0.9

    var card_height: float = clampf(basis_h * card_height_ratio, card_min_h, card_max_h)
    var gap: float = float(_skill_list.get_theme_constant("separation"))
    var min_card_w := 220.0 if basis_w < 900.0 else 260.0
    var card_width: float = clampf(_scroll.size.x * card_width_ratio, min_card_w, 520.0)
    if child_count >= 2 and basis_w >= 900.0:
        var two_card_width: float = floor((_scroll.size.x - gap - 2.0) * 0.5)
        card_width = clampf(two_card_width, min_card_w, 520.0)
    var scroll_extra := 18.0 if basis_w < _RESP_SMALL_W else (24.0 if basis_w >= _RESP_LARGE_W else 20.0)
    var target_scroll_height: float = card_height + scroll_extra
    _scroll.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
    _scroll.custom_minimum_size.y = target_scroll_height
    var scroll_margin := _scroll.get_parent() as Control
    if scroll_margin:
        scroll_margin.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
        scroll_margin.custom_minimum_size.y = target_scroll_height
    for child in _skill_list.get_children():
        if child is Control:
            var ctl := child as Control
            ctl.custom_minimum_size = Vector2(card_width, card_height)
    var total_width := 0.0
    if child_count > 0:
        total_width += float(child_count) * card_width
        total_width += float(maxi(child_count - 1, 0)) * gap
    _skill_list.custom_minimum_size = Vector2(maxf(total_width, _scroll.size.x), card_height)
    var max_scroll := _get_max_horizontal_scroll()
    _scroll.scroll_horizontal = clampi(_scroll.scroll_horizontal, 0, max_scroll)
    _update_token_grid_columns()
    _fit_panel_height_to_content()
    call_deferred("_fit_panel_height_to_content")
    _layout_busy = false

func _build_skill_card(item: Dictionary) -> Control:
    var width_ref := _last_panel_viewport_size.x
    if width_ref <= 0.0:
        width_ref = size.x
    var compact := width_ref > 0.0 and width_ref < _RESP_SMALL_W
    var large := width_ref >= _RESP_LARGE_W
    var icon_wrap_size: float = 46.0 if compact else (56.0 if large else 50.0)
    var icon_size: float = 26.0 if compact else (34.0 if large else 30.0)
    var title_font_size: int = 19 if compact else (24 if large else 22)
    var level_font_size: int = 14 if compact else (18 if large else 16)
    var progress_height: float = 10.0 if compact else (13.0 if large else 12.0)
    var stats_h_gap: int = 6 if compact else (8 if large else 7)
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
    card_style.set_border_width_all(2)
    card_style.set_corner_radius_all(14)
    card_style.content_margin_left = 10
    card_style.content_margin_right = 10
    card_style.content_margin_top = 8
    card_style.content_margin_bottom = 8
    card.add_theme_stylebox_override("panel", card_style)

    var root := VBoxContainer.new()
    root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    root.size_flags_vertical = Control.SIZE_EXPAND_FILL
    root.add_theme_constant_override("separation", 7)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    card.add_child(root)

    var top := HBoxContainer.new()
    top.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    top.add_theme_constant_override("separation", 8)
    top.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(top)

    var icon_wrap := PanelContainer.new()
    icon_wrap.custom_minimum_size = Vector2(icon_wrap_size, icon_wrap_size)
    icon_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var icon_style := StyleBoxFlat.new()
    icon_style.bg_color = accent.darkened(0.67)
    icon_style.border_color = accent
    icon_style.set_border_width_all(1)
    icon_style.set_corner_radius_all(30)
    icon_wrap.add_theme_stylebox_override("panel", icon_style)
    top.add_child(icon_wrap)

    var icon_center := CenterContainer.new()
    icon_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    icon_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
    icon_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
    icon_wrap.add_child(icon_center)

    var icon := TextureRect.new()
    icon.custom_minimum_size = Vector2(icon_size, icon_size)
    icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var icon_path := String(item.get("icon_path", ""))
    var tex := _get_icon(icon_path)
    if tex:
        icon.texture = tex
    else:
        icon.modulate = Color(1, 1, 1, 0.0)
    icon_center.add_child(icon)

    var title_row := HBoxContainer.new()
    title_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title_row.add_theme_constant_override("separation", 8)
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
    title.add_theme_font_size_override("font_size", title_font_size)
    title.add_theme_color_override("font_color", Color(0.96, 0.97, 1.0, 1.0))
    title_row.add_child(title)

    var lv := Label.new()
    lv.custom_minimum_size = Vector2(90, 24)
    lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    lv.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    lv.text = "%s %d/%d" % [tr("Lv"), int(item.get("level_current", 1)), int(item.get("level_max", 1))]
    if _value_font:
        lv.add_theme_font_override("font", _value_font)
    lv.add_theme_font_size_override("font_size", level_font_size)
    lv.add_theme_color_override("font_color", Color(0.99, 0.86, 0.2, 1.0))
    lv.autowrap_mode = TextServer.AUTOWRAP_OFF
    lv.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    lv.clip_text = true
    lv.mouse_filter = Control.MOUSE_FILTER_IGNORE
    title_row.add_child(lv)

    var progress := ProgressBar.new()
    progress.custom_minimum_size = Vector2(0, progress_height)
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

    var stats := GridContainer.new()
    stats.columns = 3
    stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    stats.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
    stats.add_theme_constant_override("h_separation", stats_h_gap)
    stats.add_theme_constant_override("v_separation", 0)
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
    var width_ref := _last_panel_viewport_size.x
    if width_ref <= 0.0:
        width_ref = size.x
    var compact := width_ref > 0.0 and width_ref < _RESP_SMALL_W
    var large := width_ref >= _RESP_LARGE_W
    var chip_h: float = 46.0 if compact else (56.0 if large else 52.0)
    var label_font_size: int = 12 if compact else (15 if large else 14)
    var value_font_size: int = 18 if compact else (24 if large else 22)
    var chip_pad_lr: int = 6 if compact else (8 if large else 7)
    var chip_pad_tb: int = 3 if compact else (5 if large else 4)

    var chip := PanelContainer.new()
    chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    chip.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
    chip.custom_minimum_size = Vector2(0.0, chip_h)
    chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var chip_style := StyleBoxFlat.new()
    chip_style.bg_color = (accent.darkened(0.8) if emphasize else Color(0.04, 0.09, 0.15, 0.9))
    chip_style.border_color = (accent if emphasize else accent.darkened(0.4))
    chip_style.set_border_width_all(1)
    chip_style.set_corner_radius_all(7)
    chip_style.content_margin_left = chip_pad_lr
    chip_style.content_margin_right = chip_pad_lr
    chip_style.content_margin_top = chip_pad_tb
    chip_style.content_margin_bottom = chip_pad_tb
    chip.add_theme_stylebox_override("panel", chip_style)

    var row := VBoxContainer.new()
    row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
    row.add_theme_constant_override("separation", 0)
    row.mouse_filter = Control.MOUSE_FILTER_IGNORE
    chip.add_child(row)

    var label := Label.new()
    label.size_flags_horizontal = Control.SIZE_FILL
    label.text = label_text
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.autowrap_mode = TextServer.AUTOWRAP_OFF
    label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    label.clip_text = true
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    if _body_font:
        label.add_theme_font_override("font", _body_font)
    label.add_theme_font_size_override("font_size", label_font_size)
    label.add_theme_color_override("font_color", (Color(0.86, 0.95, 1.0, 1.0) if emphasize else Color(0.74, 0.88, 1.0, 0.95)))
    row.add_child(label)

    var value := Label.new()
    value.custom_minimum_size = Vector2(0, 0)
    value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    value.text = value_text
    value.autowrap_mode = TextServer.AUTOWRAP_OFF
    value.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    value.clip_text = true
    value.mouse_filter = Control.MOUSE_FILTER_IGNORE
    if _value_font:
        value.add_theme_font_override("font", _value_font)
    value.add_theme_font_size_override("font_size", (value_font_size + 1 if emphasize else value_font_size))
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

    var width_ref: float = _token_grid.size.x
    if width_ref <= 0.0 and _token_panel:
        width_ref = _token_panel.size.x
    if width_ref <= 0.0:
        width_ref = _last_panel_viewport_size.x

    for child in _token_grid.get_children():
        child.queue_free()

    var columns := _compute_token_grid_columns(width_ref)
    var grid_h_gap: int = 8
    var grid_v_gap: int = 8
    if columns == 1:
        grid_h_gap = 8
        grid_v_gap = 8
    elif columns == 2:
        grid_h_gap = 10
        grid_v_gap = 10
    elif width_ref >= _RESP_LARGE_W:
        grid_h_gap = 10
        grid_v_gap = 10
    _token_grid.add_theme_constant_override("h_separation", grid_h_gap)
    _token_grid.add_theme_constant_override("v_separation", grid_v_gap)

    var token_card_h: float
    var token_icon_size: float
    var token_icon_wrap_size: float
    var token_name_font: int
    var token_value_font: int
    var token_pad_lr: float
    var token_pad_tb: float
    var token_header_gap: int
    var token_content_gap: int
    var token_name_wrap: bool = true
    var token_name_min_h: float = 30.0
    var token_value_min_h: float = 28.0

    match columns:
        4:
            token_card_h = 110.0
            token_icon_wrap_size = 40.0
            token_icon_size = 26.0
            token_name_font = 15
            token_value_font = 34
            token_pad_lr = 10.0
            token_pad_tb = 8.0
            token_header_gap = 8
            token_content_gap = 5
            token_name_wrap = true
            token_name_min_h = 36.0
            token_value_min_h = 36.0
        2:
            token_card_h = 116.0
            token_icon_wrap_size = 42.0
            token_icon_size = 28.0
            token_name_font = 16
            token_value_font = 36
            token_pad_lr = 12.0
            token_pad_tb = 9.0
            token_header_gap = 9
            token_content_gap = 6
            token_name_wrap = true
            token_name_min_h = 38.0
            token_value_min_h = 38.0
        _:
            token_card_h = 120.0
            token_icon_wrap_size = 44.0
            token_icon_size = 30.0
            token_name_font = 17
            token_value_font = 38
            token_pad_lr = 12.0
            token_pad_tb = 9.0
            token_header_gap = 10
            token_content_gap = 7
            token_name_wrap = true
            token_name_min_h = 40.0
            token_value_min_h = 40.0

    for token_id in _TOKEN_ORDER:
        var accent := Color(_TOKEN_ACCENT_MAP.get(token_id, Color(0.67, 0.79, 0.89, 1.0)))
        var card := PanelContainer.new()
        card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        card.size_flags_vertical = Control.SIZE_EXPAND_FILL
        card.custom_minimum_size.y = token_card_h
        var card_style := StyleBoxFlat.new()
        card_style.bg_color = Color(0.05, 0.1, 0.17, 0.92)
        card_style.border_color = accent
        card_style.set_border_width_all(1)
        card_style.set_corner_radius_all(10)
        card_style.content_margin_left = token_pad_lr
        card_style.content_margin_right = token_pad_lr
        card_style.content_margin_top = token_pad_tb
        card_style.content_margin_bottom = token_pad_tb
        card.add_theme_stylebox_override("panel", card_style)

        var content := VBoxContainer.new()
        content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        content.size_flags_vertical = Control.SIZE_EXPAND_FILL
        content.add_theme_constant_override("separation", token_content_gap)
        card.add_child(content)

        var header := HBoxContainer.new()
        header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        header.add_theme_constant_override("separation", token_header_gap)
        content.add_child(header)

        var icon_wrap := PanelContainer.new()
        icon_wrap.custom_minimum_size = Vector2(token_icon_wrap_size, token_icon_wrap_size)
        var icon_style := StyleBoxFlat.new()
        icon_style.bg_color = accent.darkened(0.7)
        icon_style.border_color = accent
        icon_style.set_border_width_all(1)
        icon_style.set_corner_radius_all(int(token_icon_wrap_size * 0.5))
        icon_wrap.add_theme_stylebox_override("panel", icon_style)
        header.add_child(icon_wrap)

        var icon_center := CenterContainer.new()
        icon_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        icon_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
        icon_wrap.add_child(icon_center)

        var icon := TextureRect.new()
        icon.custom_minimum_size = Vector2(token_icon_size, token_icon_size)
        icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        var icon_tex := _get_icon(String(_TOKEN_ICON_MAP.get(token_id, "")))
        if icon_tex:
            icon.texture = icon_tex
        icon_center.add_child(icon)

        var name_lbl := Label.new()
        name_lbl.text = tr(String(_TOKEN_LABEL_MAP.get(token_id, token_id)))
        name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        name_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
        name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
        name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        name_lbl.max_lines_visible = (2 if token_name_wrap else 1)
        name_lbl.autowrap_mode = (TextServer.AUTOWRAP_WORD_SMART if token_name_wrap else TextServer.AUTOWRAP_OFF)
        name_lbl.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
        name_lbl.clip_text = false
        name_lbl.custom_minimum_size.y = token_name_min_h
        if _value_font:
            name_lbl.add_theme_font_override("font", _value_font)
        elif _body_font:
            name_lbl.add_theme_font_override("font", _body_font)
        name_lbl.add_theme_font_size_override("font_size", token_name_font)
        name_lbl.add_theme_color_override("font_color", Color(0.9, 0.96, 1.0, 0.98))
        header.add_child(name_lbl)

        var value_lbl := Label.new()
        value_lbl.text = str(int(counts.get(token_id, 0)))
        value_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
        value_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        value_lbl.custom_minimum_size.y = token_value_min_h
        if _value_font:
            value_lbl.add_theme_font_override("font", _value_font)
        elif _title_font:
            value_lbl.add_theme_font_override("font", _title_font)
        value_lbl.add_theme_font_size_override("font_size", token_value_font)
        value_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))
        content.add_child(value_lbl)

        _token_grid.add_child(card)

    _token_grid.columns = columns
    _last_token_columns = columns
    _fit_panel_height_to_content()
    call_deferred("_fit_panel_height_to_content")

func _update_token_grid_columns() -> void:
    if _token_grid == null:
        return
    var width_ref := _token_grid.size.x
    if width_ref <= 0.0 and _token_panel:
        width_ref = _token_panel.size.x - 20.0
    var columns := _compute_token_grid_columns(width_ref)
    if columns != _last_token_columns:
        # Rebuild token cards when grid mode changes (2<->4 cols),
        # so card internals stay proportional after viewport resize.
        _refresh_token_inventory(_last_snapshot)
        return
    _token_grid.columns = columns

func _compute_token_grid_columns(width_ref: float) -> int:
    if width_ref > 0.0 and width_ref < 520.0:
        return 2
    return 4

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
