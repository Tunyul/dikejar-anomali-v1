extends Control

signal bgm_volume_changed(v: float)
signal sfx_volume_changed(v: float)
signal bgm_mute_changed(muted: bool)
signal sfx_mute_changed(muted: bool)
signal overlay_closed
signal resume_pressed
signal restart_pressed
signal menu_pressed

@onready var _ui: CanvasLayer = %UI
@onready var _panel: TextureRect = %Panel
@onready var _close_btn: TextureButton = %CloseButton
@onready var _scroll: ScrollContainer = %Scroll
@onready var _vbox: VBoxContainer = %VBox
@onready var _lang_option: OptionButton = %LanguageOption
@onready var _bgm_slider: HSlider = %BGMSlider
@onready var _bgm_mute: CheckBox = %BGMMute
@onready var _sfx_slider: HSlider = %SFXSlider
@onready var _sfx_mute: CheckBox = %SFXMute
@onready var _menu_btn: Button = %MenuButton
@onready var _restart_btn: Button = %RestartButton
@onready var _resume_btn: Button = %ResumeButton
@onready var _title_label: Label = %TitleLabel

var _flag_id: Texture2D = null
var _flag_en: Texture2D = null
var _flag_zh: Texture2D = null
var _last_viewport_size: Vector2i = Vector2i(-1, -1)
var _scroll_drag_active: bool = false
var _scroll_drag_last_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS

    if _resume_btn:
        _resume_btn.pressed.connect(func(): emit_signal("resume_pressed"); _on_back_pressed())
    if _restart_btn:
        _restart_btn.pressed.connect(func(): emit_signal("restart_pressed"))
    if _menu_btn:
        _menu_btn.pressed.connect(func(): emit_signal("menu_pressed"))

    if _panel:
        _panel.pivot_offset = _panel.size * 0.5
    if _scroll:
        _scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
        _scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER

    if _vbox:
        _vbox.mouse_filter = Control.MOUSE_FILTER_PASS
        for child in _vbox.get_children():
            if child is Control:
                child.mouse_filter = Control.MOUSE_FILTER_PASS
                for sub_child in child.get_children():
                    if sub_child is Control and not (sub_child is Slider or sub_child is Button or sub_child is OptionButton):
                        sub_child.mouse_filter = Control.MOUSE_FILTER_PASS

    var margin = _scroll.get_child(0) if _scroll and _scroll.get_child_count() > 0 else null
    if margin and margin is MarginContainer:
        margin.mouse_filter = Control.MOUSE_FILTER_PASS

    if _bgm_slider:
        _bgm_slider.min_value = 0.0
        _bgm_slider.max_value = 1.0
        _bgm_slider.step = 0.01
    if _sfx_slider:
        _sfx_slider.min_value = 0.0
        _sfx_slider.max_value = 1.0
        _sfx_slider.step = 0.01
    if _lang_option:
        _init_language_icons()
        _refresh_language_option_items()
    _sync_controls_from_save()
    if _bgm_slider:
        _bgm_slider.value_changed.connect(_on_bgm_volume_changed)
    if _sfx_slider:
        _sfx_slider.value_changed.connect(_on_sfx_volume_changed)
    if _bgm_mute:
        _bgm_mute.toggled.connect(_on_bgm_mute_toggled)
    if _sfx_mute:
        _sfx_mute.toggled.connect(_on_sfx_mute_toggled)
    if _lang_option:
        _lang_option.item_selected.connect(_on_language_selected)
        if TransitionManager and TransitionManager.has_signal("language_changed"):
            var cb := Callable(self, "_on_translation_changed")
            if not TransitionManager.language_changed.is_connected(cb):
                TransitionManager.language_changed.connect(cb)
    if _close_btn:
        _close_btn.pressed.connect(_on_back_pressed)
    if get_tree().current_scene != self:
        if _ui:
            _ui.visible = false
        visible = false
    var ui_font := load("res://assets/font/Fredoka Nunito/Nunito/static/Nunito-Regular.ttf") as Font
    var title_font := load("res://assets/font/Fredoka Nunito/Fredoka/static/Fredoka-Bold.ttf") as Font
    if ui_font:
        _apply_ui_font(self, ui_font)
    if title_font:
        if _title_label:
            _title_label.add_theme_font_override("font", title_font)
            _title_label.add_theme_color_override("font_color", Color(1, 1, 0, 1))
            _title_label.add_theme_constant_override("outline_size", 3)
            _title_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
            _title_label.add_theme_font_size_override("font_size", 36)
    _connect_viewport_resize()


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
    if _panel == null:
        return
    var safe := Rect2(Vector2.ZERO, vp)
    if OS.has_feature("android") or OS.has_feature("ios"):
        var sa := DisplayServer.get_display_safe_area()
        if sa.size.x > 0 and sa.size.y > 0:
            safe = Rect2(Vector2(sa.position), Vector2(sa.size))
    var margin := 16.0
    var safe_size := Vector2(maxf(safe.size.x - margin * 2.0, 1.0), maxf(safe.size.y - margin * 2.0, 1.0))
    var base_panel_size := Vector2(704.0, 448.0)
    var fit: float = minf(safe_size.x / base_panel_size.x, safe_size.y / base_panel_size.y)
    fit = clampf(fit, 0.4, 0.9)
    _panel.scale = Vector2(fit, fit)
    _panel.position = (vp - _panel.size * fit) * 0.5


func _input(event: InputEvent) -> void:
    if not is_inside_tree() or not visible or _scroll == null:
        return

    # Mouse Wheel is handled automatically, but for touch/drag we need manual logic
    if event is InputEventScreenTouch:
        var e := event as InputEventScreenTouch
        if e.pressed:
            var rect := _scroll.get_global_rect()
            if rect.has_point(e.position):
                _scroll_drag_active = true
                _scroll_drag_last_pos = e.position
        else:
            _scroll_drag_active = false
        return

    if event is InputEventScreenDrag:
        var e := event as InputEventScreenDrag
        if _scroll_drag_active:
            # Scroll vertically
            var old_scroll = _scroll.scroll_vertical
            _scroll.scroll_vertical = int(_scroll.scroll_vertical - e.relative.y)
            # If scroll actually changed, consume the event so sliders don't move
            if _scroll.scroll_vertical != old_scroll:
                get_viewport().set_input_as_handled()
        return

    if event is InputEventMouseButton:
        var e := event as InputEventMouseButton
        if e.button_index == MOUSE_BUTTON_LEFT:
            if e.pressed:
                var rect := _scroll.get_global_rect()
                if rect.has_point(e.global_position):
                    _scroll_drag_active = true
                    _scroll_drag_last_pos = e.global_position
            else:
                _scroll_drag_active = false
        return

    if event is InputEventMouseMotion:
        var e := event as InputEventMouseMotion
        if _scroll_drag_active:
            var old_scroll = _scroll.scroll_vertical
            _scroll.scroll_vertical = int(_scroll.scroll_vertical - e.relative.y)
            if _scroll.scroll_vertical != old_scroll:
                get_viewport().set_input_as_handled()
        return


func _read_settings_from_save() -> Dictionary:
    if GameManager and GameManager.has_method("get_settings_snapshot"):
        var snapshot: Variant = GameManager.get_settings_snapshot()
        if snapshot is Dictionary:
            return snapshot
    var bgm_volume: float = 0.8
    var sfx_volume: float = 0.8
    var bgm_muted: bool = false
    var sfx_muted: bool = false
    var language: String = ""
    var cfg := ConfigFile.new()
    var err := cfg.load("user://save.cfg")
    if err == OK:
        bgm_volume = float(cfg.get_value("settings", "bgm_volume", 0.8))
        sfx_volume = float(cfg.get_value("settings", "sfx_volume", 0.8))
        bgm_muted = bool(cfg.get_value("settings", "bgm_muted", false))
        sfx_muted = bool(cfg.get_value("settings", "sfx_muted", false))
        language = str(cfg.get_value("settings", "language", ""))
    return {
        "bgm_volume": clampf(bgm_volume, 0.0, 1.0),
        "sfx_volume": clampf(sfx_volume, 0.0, 1.0),
        "bgm_muted": bgm_muted,
        "sfx_muted": sfx_muted,
        "language": language,
    }


func _sync_controls_from_save() -> void:
    var s := _read_settings_from_save()
    if _bgm_slider:
        _bgm_slider.set_block_signals(true)
        _bgm_slider.value = float(s["bgm_volume"])
        _bgm_slider.set_block_signals(false)
    if _sfx_slider:
        _sfx_slider.set_block_signals(true)
        _sfx_slider.value = float(s["sfx_volume"])
        _sfx_slider.set_block_signals(false)
    if _bgm_mute:
        _bgm_mute.set_block_signals(true)
        _bgm_mute.button_pressed = bool(s["bgm_muted"])
        _bgm_mute.set_block_signals(false)
    if _sfx_mute:
        _sfx_mute.set_block_signals(true)
        _sfx_mute.button_pressed = bool(s["sfx_muted"])
        _sfx_mute.set_block_signals(false)
    if _lang_option:
        var idx := _language_to_index(str(s["language"]))
        _lang_option.set_block_signals(true)
        _lang_option.select(idx)
        _lang_option.set_block_signals(false)
    TransitionManager.set_sfx_volume(float(s["sfx_volume"]))
    TransitionManager.set_sfx_muted(bool(s["sfx_muted"]))


func _refresh_language_option_items() -> void:
    if _lang_option == null:
        return
    var selected := _lang_option.get_selected_id()
    _lang_option.clear()
    _lang_option.add_item(tr("Indonesian"), 0)
    _lang_option.add_item(tr("English"), 1)
    _lang_option.add_item(tr("Chinese"), 2)
    if _flag_id:
        _lang_option.set_item_icon(0, _flag_id)
    if _flag_en:
        _lang_option.set_item_icon(1, _flag_en)
    if _flag_zh:
        _lang_option.set_item_icon(2, _flag_zh)
    if selected >= 0:
        _lang_option.select(clampi(selected, 0, 2))


func _init_language_icons() -> void:
    if DisplayServer.get_name() == "headless":
        return
    if _flag_id == null:
        _flag_id = _load_flag_texture("res://assets/icon/icon_flag_INA.png")
        if _flag_id == null:
            _flag_id = _make_flag_indonesia(48, 32)
    if _flag_en == null:
        _flag_en = _load_flag_texture("res://assets/icon/icon_flag_US.png")
        if _flag_en == null:
            _flag_en = _make_flag_usa(48, 32)
    if _flag_zh == null:
        _flag_zh = _load_flag_texture("res://assets/icon/icon_flag_CN.png")
        if _flag_zh == null:
            _flag_zh = _make_flag_china(48, 32)


func _load_flag_texture(path: String) -> Texture2D:
    if not ResourceLoader.exists(path):
        return null
    return load(path) as Texture2D


func _make_flag_indonesia(w: int, h: int) -> Texture2D:
    var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
    img.fill(Color(1, 1, 1, 1))
    for y in range(int(h * 0.5)):
        for x in range(w):
            img.set_pixel(x, y, Color(0.86, 0.12, 0.16, 1))
    return ImageTexture.create_from_image(img)


func _make_flag_china(w: int, h: int) -> Texture2D:
    var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
    img.fill(Color(0.86, 0.06, 0.12, 1))
    _draw_star(img, int(w * 0.22), int(h * 0.32), int(min(w, h) * 0.16), Color(0.98, 0.84, 0.0, 1))
    return ImageTexture.create_from_image(img)


func _make_flag_usa(w: int, h: int) -> Texture2D:
    var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
    img.fill(Color(1, 1, 1, 1))
    var stripe_count := 13
    for i in range(stripe_count):
        if i % 2 == 0:
            var y0 := int(round(float(i) * float(h) / float(stripe_count)))
            var y1 := int(round(float(i + 1) * float(h) / float(stripe_count)))
            for y in range(y0, y1):
                for x in range(w):
                    img.set_pixel(x, y, Color(0.70, 0.1, 0.18, 1))
    var canton_w := int(round(float(w) * 0.45))
    var canton_h := int(round(float(h) * 0.54))
    for y in range(canton_h):
        for x in range(canton_w):
            img.set_pixel(x, y, Color(0.18, 0.2, 0.44, 1))
    return ImageTexture.create_from_image(img)


func _draw_star(img: Image, cx: int, cy: int, r: int, col: Color) -> void:
    var w := img.get_width()
    var h := img.get_height()
    var outer := float(r)
    var inner := float(r) * 0.45
    var pts: PackedVector2Array = PackedVector2Array()
    for i in range(10):
        var ang := -PI / 2.0 + float(i) * (PI / 5.0)
        var rr := (outer if (i % 2 == 0) else inner)
        pts.append(Vector2(float(cx) + cos(ang) * rr, float(cy) + sin(ang) * rr))
    var min_x := w - 1
    var max_x := 0
    var min_y := h - 1
    var max_y := 0
    for p in pts:
        min_x = mini(min_x, int(floor(p.x)))
        max_x = maxi(max_x, int(ceil(p.x)))
        min_y = mini(min_y, int(floor(p.y)))
        max_y = maxi(max_y, int(ceil(p.y)))
    min_x = clampi(min_x, 0, w - 1)
    max_x = clampi(max_x, 0, w - 1)
    min_y = clampi(min_y, 0, h - 1)
    max_y = clampi(max_y, 0, h - 1)
    for y in range(min_y, max_y + 1):
        for x in range(min_x, max_x + 1):
            if _point_in_poly(Vector2(float(x) + 0.5, float(y) + 0.5), pts):
                img.set_pixel(x, y, col)


func _point_in_poly(p: Vector2, poly: PackedVector2Array) -> bool:
    var inside := false
    var j := poly.size() - 1
    for i in range(poly.size()):
        var pi := poly[i]
        var pj := poly[j]
        var intersect := ((pi.y > p.y) != (pj.y > p.y)) and (p.x < (pj.x - pi.x) * (p.y - pi.y) / (pj.y - pi.y + 0.000001) + pi.x)
        if intersect:
            inside = not inside
        j = i
    return inside


func _language_to_index(locale: String) -> int:
    var lc := locale.strip_edges().to_lower()
    if lc.begins_with("en"):
        return 1
    if lc.begins_with("zh"):
        return 2
    return 0


func _index_to_language(i: int) -> String:
    if i == 1:
        return "en"
    if i == 2:
        return "zh"
    return "id"


func _on_language_selected(_index: int) -> void:
    if _lang_option == null:
        return
    var locale := _index_to_language(_lang_option.get_selected_id())
    if GameManager and GameManager.has_method("update_settings"):
        GameManager.update_settings({"language": locale}, true)
    if TransitionManager and TransitionManager.has_method("set_language"):
        TransitionManager.set_language(locale)
    _refresh_language_option_items()


func _on_translation_changed(_locale: String = "") -> void:
    _refresh_language_option_items()

func _on_bgm_volume_changed(v: float) -> void:
    emit_signal("bgm_volume_changed", v)
    if GameManager and GameManager.has_method("update_settings"):
        GameManager.update_settings({"bgm_volume": v}, true)
    elif TransitionManager and TransitionManager.has_method("set_bgm_volume"):
        TransitionManager.set_bgm_volume(v)

func _on_sfx_volume_changed(v: float) -> void:
    emit_signal("sfx_volume_changed", v)
    if GameManager and GameManager.has_method("update_settings"):
        GameManager.update_settings({"sfx_volume": v}, true)
    elif TransitionManager and TransitionManager.has_method("set_sfx_volume"):
        TransitionManager.set_sfx_volume(v)

func _on_bgm_mute_toggled(pressed: bool) -> void:
    emit_signal("bgm_mute_changed", pressed)
    if GameManager and GameManager.has_method("update_settings"):
        GameManager.update_settings({"bgm_muted": pressed}, true)
    elif TransitionManager and TransitionManager.has_method("set_bgm_muted"):
        TransitionManager.set_bgm_muted(pressed)

func _on_sfx_mute_toggled(pressed: bool) -> void:
    emit_signal("sfx_mute_changed", pressed)
    if GameManager and GameManager.has_method("update_settings"):
        GameManager.update_settings({"sfx_muted": pressed}, true)
    elif TransitionManager and TransitionManager.has_method("set_sfx_muted"):
        TransitionManager.set_sfx_muted(pressed)

func show_overlay(is_ingame: bool = false) -> void:
    _sync_controls_from_save()
    if _resume_btn:
        _resume_btn.visible = is_ingame
    if _restart_btn:
        _restart_btn.visible = is_ingame
    if _menu_btn:
        _menu_btn.visible = is_ingame

    if _ui:
        _ui.visible = true
    visible = true

func _unhandled_input(event: InputEvent) -> void:
    if get_tree().current_scene == self:
        return
    if not visible:
        return
    var mb := event as InputEventMouseButton
    if mb == null:
        return
    if not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
        return
    if _panel == null:
        return
    var rect := _panel.get_global_rect()
    if rect.has_point(mb.position):
        return
    _on_back_pressed()

func _on_back_pressed() -> void:
    TransitionManager.play_sfx(&"click")
    if get_tree().current_scene == self:
        if Preloader and Preloader.has_method("set_next_scene"):
            Preloader.set_next_scene("res://scenes/MainMenu.tscn")
        await TransitionManager.play_transition_to_scene("res://scenes/LoadingScreen.tscn")
        return
    if _ui:
        _ui.visible = false
    visible = false
    emit_signal("overlay_closed")

func _apply_ui_font(node: Node, font: Font) -> void:
    if node is Label:
        (node as Label).add_theme_font_override("font", font)
    elif node is BaseButton:
        (node as BaseButton).add_theme_font_override("font", font)
    for child in node.get_children():
        if child is Node:
            _apply_ui_font(child, font)
