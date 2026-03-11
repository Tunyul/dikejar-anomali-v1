extends Control

signal overlay_closed
const _BANNER_LOCK_ID := "daily_missions_overlay"


@onready var _ui: CanvasLayer = %UI
@onready var _title_label: Label = %TitleLabel
@onready var _daily_button: Button = %DailyButton
@onready var _mission_button: Button = %MissionButton
@onready var _weekly_button: Button = %WeeklyButton
@onready var _monthly_button: Button = %MonthlyButton
@onready var _challenge_button: Button = %ChallengeButton
@onready var _back_button: Button = %BackButton
@onready var _close_button: TextureButton = %CloseButton
@onready var _mission_panel: Control = %MissionPanel
@onready var _panel_content: Control = %PanelContent
@onready var _tabs_row: HBoxContainer = get_node_or_null("UI/MissionPanel/PanelContent/VBox/Tabs") as HBoxContainer
@onready var _reset_header_row: HBoxContainer = %ResetHeaderRow
@onready var _reset_label: Label = %ResetTimeLabel
@onready var _reset_daily_button: Button = %ResetDailyButton
@onready var _reset_spacer: Control = %Spacer
@onready var _daily_summary: Control = %DailyGroup
@onready var _daily_total_label: Label = %DailyTotalLabel
@onready var _daily_total_bar: ProgressBar = %DailyTotalBar
@onready var _daily_all_reward_label: Label = %DailyAllRewardLabel
@onready var _daily_all_claim_button: Button = %ClaimDailyAllButton
@onready var _missions_scroll: ScrollContainer = %MissionsScroll
@onready var _missions_panel_node: VBoxContainer = %MissionsPanel
@onready var _confirm_panel: Control = %ConfirmPanel

var _confirm_message: Label = null
var _confirm_yes: BaseButton = null
var _confirm_no: BaseButton = null

var _current_tab := "daily"
var _reset_time_accum: float = 0.0
var _tab_style_normal: StyleBox = null
var _tab_style_active: StyleBox = null
var _claim_tex_active: Texture2D = null
var _claim_tex_disabled: Texture2D = null
var _coin_fx_tex: Texture2D = null
var _diamond_fx_tex: Texture2D = null
var _coin_fx_rng := RandomNumberGenerator.new()

@export var daily_all_complete_reward_gems: int = 1

var _pending_action: String = ""
var _awaiting_rewarded_reason: String = ""
var _ad_manager: Node = null
var _missions_manager: Node = null
var _last_viewport_size: Vector2i = Vector2i(-1, -1)
var _mission_panel_target_scale: float = 1.0
var _banner_lock_active: bool = false

const _MISSION_PANEL_BASE_SIZE := Vector2(685.0, 385.0)
const _MISSION_PANEL_SCALE_MIN := 0.35
const _MISSION_PANEL_SCALE_MAX := 0.90


func _notification(what: int) -> void:
    if what == NOTIFICATION_TRANSLATION_CHANGED:
        _refresh_all_ui_texts()

func _refresh_all_ui_texts() -> void:
    # Update Judul
    if _title_label:
        _title_label.text = tr("MISSIONS")

    # Update Tab Buttons
    if _daily_button: _daily_button.text = tr("DAILY")
    if _mission_button: _mission_button.text = tr("MISSION")
    if _weekly_button: _weekly_button.text = tr("WEEKLY")
    if _monthly_button: _monthly_button.text = tr("MONTHLY")
    if _challenge_button: _challenge_button.text = tr("CHALLENGE")

    # Update Back Button
    if _back_button: _back_button.text = tr("BACK")

    # Update Mission List
    if _missions_panel_node:
        _refresh_missions_panel(_missions_panel_node)

    # Update Daily Summary
    if _daily_summary and _daily_summary.visible:
        _update_daily_summary([])

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _refresh_all_ui_texts()
    if _back_button:
        _back_button.pressed.connect(_on_back_pressed)
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
    if _reset_label:
        _reset_label.add_theme_color_override("font_color", Color(0, 0, 0))
    _apply_mission_name_color()
    _apply_mission_reward_color()
    if ui_font and _daily_total_label:
        _daily_total_label.add_theme_font_override("font", ui_font)
        _daily_total_label.add_theme_color_override("font_color", Color(0, 0, 0, 1))
        _daily_total_label.add_theme_constant_override("outline_size", 0)
        _daily_total_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0))
        _daily_total_label.add_theme_font_size_override("font_size", 18)
    if _daily_all_claim_button and not _daily_all_claim_button.pressed.is_connected(_on_claim_daily_all_pressed):
        _daily_all_claim_button.pressed.connect(_on_claim_daily_all_pressed)
    _apply_daily_summary_color()
    var tex_normal := load("res://assets/tombol/tombol_tab_mission_120x48.png") as Texture2D
    if tex_normal:
        var sb_normal := StyleBoxTexture.new()
        sb_normal.texture = tex_normal
        _tab_style_normal = sb_normal
    var tex_active := load("res://assets/tombol/tombol_tab_mission_hijau_120x48.png") as Texture2D
    if tex_active:
        var sb_active := StyleBoxTexture.new()
        sb_active.texture = tex_active
        _tab_style_active = sb_active

    _claim_tex_active = _load_button_texture("res://assets/tombol/tombol_claim_aktif_108x64.png")
    _claim_tex_disabled = _load_button_texture("res://assets/tombol/tombol_claim_nonaktif_108x64.png")
    _coin_fx_tex = load("res://assets/coin_animation/png/2x/Coin.png") as Texture2D
    _diamond_fx_tex = load("res://assets/diamond_animation/diamond-1024x1024.png") as Texture2D
    if _missions_panel_node:
        _refresh_missions_panel(_missions_panel_node)
        _connect_claim_buttons(_missions_panel_node)
    if _daily_button:
        _daily_button.pressed.connect(func(): _on_tab_pressed("daily"))
    if _mission_button:
        _mission_button.pressed.connect(func(): _on_tab_pressed("mission"))
    if _weekly_button:
        _weekly_button.pressed.connect(func(): _on_tab_pressed("week"))
    if _monthly_button:
        _monthly_button.pressed.connect(func(): _on_tab_pressed("month"))
    if _challenge_button:
        _challenge_button.pressed.connect(func(): _on_tab_pressed("challenge"))
    _update_tab_buttons()
    _update_reset_time_label()

    if _reset_daily_button:
        _reset_daily_button.pressed.connect(_on_reset_daily_pressed)
        if _reset_header_row:
            var h := maxf(_reset_header_row.custom_minimum_size.y, _reset_daily_button.custom_minimum_size.y)
            if h <= 0.0:
                h = 44.0
            _reset_header_row.custom_minimum_size = Vector2(_reset_header_row.custom_minimum_size.x, h)

    if _confirm_panel:
        _confirm_panel.visible = false
        _confirm_message = _confirm_panel.get_node("%Message") as Label
        _confirm_yes = _confirm_panel.get_node("%YesButton") as BaseButton
        _confirm_no = _confirm_panel.get_node("%NoButton") as BaseButton

        if _confirm_yes:
            _confirm_yes.pressed.connect(_on_confirm_yes_pressed)
        if _confirm_no:
            _confirm_no.pressed.connect(_on_confirm_no_pressed)

    _ad_manager = AdManager
    _missions_manager = MissionsManager
    if _ad_manager and _ad_manager.has_signal("reward_granted"):
        var cb := Callable(self, "_on_reward_granted")
        if not _ad_manager.is_connected("reward_granted", cb):
            _ad_manager.connect("reward_granted", cb)
    if _missions_manager and _missions_manager.has_signal("missions_data_changed"):
        var cb_missions := Callable(self, "_on_missions_data_changed")
        if not _missions_manager.is_connected("missions_data_changed", cb_missions):
            _missions_manager.connect("missions_data_changed", cb_missions)

    _update_reset_daily_button_state()
    _update_reset_header_layout()
    if _close_button and not _close_button.pressed.is_connected(_on_close_pressed):
        _close_button.pressed.connect(_on_close_pressed)
    if get_tree().current_scene != self:
        if _ui:
            _ui.visible = false
        visible = false

    _connect_viewport_resize()
    if TransitionManager and TransitionManager.has_signal("language_changed"):
        var cb_lang := Callable(self, "_on_language_changed")
        if not TransitionManager.language_changed.is_connected(cb_lang):
            TransitionManager.language_changed.connect(cb_lang)

func _exit_tree() -> void:
    _release_banner_lock()


func _on_language_changed(_locale: String) -> void:
    _refresh_all_ui_texts()
    _update_reset_time_label()
    if _missions_panel_node:
        _refresh_missions_panel(_missions_panel_node)

func _on_missions_data_changed() -> void:
    if _missions_panel_node:
        _refresh_missions_panel(_missions_panel_node)
    _update_reset_daily_button_state()


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


func _get_mission_panel_base_size() -> Vector2:
    var base := _MISSION_PANEL_BASE_SIZE
    if _mission_panel is TextureRect:
        var tex_rect := _mission_panel as TextureRect
        if tex_rect.texture:
            var ts := tex_rect.texture.get_size()
            if ts.x > 0.0 and ts.y > 0.0:
                base = ts
    base.x = maxf(base.x, 1.0)
    base.y = maxf(base.y, 1.0)
    return base


func _apply_responsive_layout(vp: Vector2) -> void:
    if _mission_panel == null:
        return
    var safe := Rect2(Vector2.ZERO, vp)
    if OS.has_feature("android") or OS.has_feature("ios"):
        var sa := DisplayServer.get_display_safe_area()
        if sa.size.x > 0 and sa.size.y > 0:
            safe = Rect2(Vector2(sa.position), Vector2(sa.size))

    var margin := 16.0
    var safe_size := Vector2(maxf(safe.size.x - margin * 2.0, 1.0), maxf(safe.size.y - margin * 2.0, 1.0))
    var base_size := _get_mission_panel_base_size()
    var fit := minf(safe_size.x / base_size.x, safe_size.y / base_size.y)
    fit = clampf(fit, _MISSION_PANEL_SCALE_MIN, _MISSION_PANEL_SCALE_MAX)
    _mission_panel_target_scale = fit

    _mission_panel.anchor_left = 0.5
    _mission_panel.anchor_top = 0.5
    _mission_panel.anchor_right = 0.5
    _mission_panel.anchor_bottom = 0.5
    _mission_panel.offset_left = -base_size.x * 0.5
    _mission_panel.offset_top = -base_size.y * 0.5
    _mission_panel.offset_right = base_size.x * 0.5
    _mission_panel.offset_bottom = base_size.y * 0.5
    _mission_panel.pivot_offset = base_size * 0.5
    _mission_panel.scale = Vector2.ONE * _mission_panel_target_scale

    if _panel_content:
        var lm := clampf(base_size.x * 0.08, 44.0, 72.0)
        var tm := clampf(base_size.y * 0.145, 52.0, 84.0)
        var bm := clampf(base_size.y * 0.11, 40.0, 72.0)
        _panel_content.offset_left = lm
        _panel_content.offset_right = -lm
        _panel_content.offset_top = tm
        _panel_content.offset_bottom = -bm
    _apply_responsive_chrome(vp, safe_size)


func _apply_responsive_chrome(vp: Vector2, safe_size: Vector2) -> void:
    var compact := vp.x < 980.0 or vp.y < 560.0
    var large := vp.x >= 1500.0
    var tab_font_size: int = 15 if compact else (20 if large else 17)
    var tab_min_h: float = 42.0 if compact else (54.0 if large else 48.0)
    var tab_sep: int = 2 if compact else (8 if large else 4)
    var header_sep: int = 4 if compact else (8 if large else 6)
    var summary_font_size: int = 14 if compact else (20 if large else 18)
    var reset_font_size: int = 12 if compact else (16 if large else 14)
    var reset_btn_w: float = 76.0 if compact else (96.0 if large else 88.0)
    var reset_btn_h: float = 40.0 if compact else (48.0 if large else 44.0)
    var reward_claim_h: float = 40.0 if compact else (48.0 if large else 44.0)
    var list_min_h: float = clampf(safe_size.y * (0.48 if compact else 0.52), 150.0, 260.0)
    var scroll_min_h: float = clampf(list_min_h - (20.0 if compact else 28.0), 120.0, 230.0)

    if _tabs_row:
        _tabs_row.add_theme_constant_override("separation", tab_sep)

    var tabs: Array[Button] = [_daily_button, _mission_button, _weekly_button, _monthly_button, _challenge_button]
    for b in tabs:
        if b == null:
            continue
        b.custom_minimum_size.y = tab_min_h
        b.add_theme_font_size_override("font_size", tab_font_size)

    if _reset_header_row:
        _reset_header_row.add_theme_constant_override("separation", header_sep)
    if _daily_summary and _daily_summary is HBoxContainer:
        (_daily_summary as HBoxContainer).add_theme_constant_override("separation", header_sep)
    if _daily_total_label:
        _daily_total_label.add_theme_font_size_override("font_size", summary_font_size)
    if _daily_all_reward_label:
        _daily_all_reward_label.add_theme_font_size_override("font_size", maxi(summary_font_size - 2, 12))
    if _daily_total_bar:
        _daily_total_bar.custom_minimum_size = Vector2(_daily_total_bar.custom_minimum_size.x, 8.0 if compact else (10.0 if large else 9.0))
    if _reset_label:
        _reset_label.add_theme_font_size_override("font_size", reset_font_size)
    if _reset_daily_button:
        _reset_daily_button.custom_minimum_size = Vector2(reset_btn_w, reset_btn_h)
        _reset_daily_button.add_theme_font_size_override("font_size", reset_font_size)
    if _daily_all_claim_button:
        _daily_all_claim_button.custom_minimum_size = Vector2(_daily_all_claim_button.custom_minimum_size.x, reward_claim_h)

    if _missions_panel_node:
        _missions_panel_node.add_theme_constant_override("separation", 12 if compact else (18 if large else 16))
    if _missions_scroll:
        _missions_scroll.custom_minimum_size.y = scroll_min_h
    var list_container := _missions_scroll.get_parent() as Control if _missions_scroll else null
    if list_container:
        list_container.custom_minimum_size.y = list_min_h


func _apply_mission_name_color() -> void:
    if _missions_panel_node == null:
        return
    for slot in _missions_panel_node.get_children():
        var row := slot as Control
        if row == null:
            continue
        var name_label := row.get_node_or_null("Name") as Label
        if name_label:
            name_label.add_theme_color_override("font_color", Color(0, 0, 0))


func _apply_mission_reward_color() -> void:
    if _missions_panel_node == null:
        return
    for slot in _missions_panel_node.get_children():
        var row := slot as Control
        if row == null:
            continue
        var reward_label := row.get_node_or_null("Reward") as Label
        if reward_label:
            reward_label.add_theme_color_override("font_color", Color(0, 0, 0))


func _apply_daily_summary_color() -> void:
    if _daily_total_label:
        _daily_total_label.add_theme_color_override("font_color", Color(0, 0, 0))
    if _daily_all_reward_label:
        _daily_all_reward_label.add_theme_color_override("font_color", Color(0, 0, 0))


func _get_mission_rows(panel: Node) -> Array[HBoxContainer]:
    var out: Array[HBoxContainer] = []
    var vbox := panel as VBoxContainer
    if vbox == null:
        return out
    for child in vbox.get_children():
        var row := child as HBoxContainer
        if row:
            out.append(row)
    return out


func _ensure_mission_rows(panel: Node, count: int) -> Array[HBoxContainer]:
    var vbox := panel as VBoxContainer
    if vbox == null:
        return []
    var rows := _get_mission_rows(vbox)
    if rows.is_empty():
        return rows
    var template := rows[0]
    while rows.size() < count:
        var dup := template.duplicate() as HBoxContainer
        if dup == null:
            break
        dup.name = "Mission" + str(rows.size() + 1)
        vbox.add_child(dup)
        rows.append(dup)
    return rows


func _clear_mission_row(row: Control) -> void:
    if row == null:
        return
    var name_label := row.get_node_or_null("Name") as Label
    var bar := row.get_node_or_null("Bar") as ProgressBar
    var reward_label := row.get_node_or_null("Reward") as Label
    var claim_button := row.get_node_or_null("ClaimButton") as BaseButton
    if name_label:
        name_label.visible = true
        name_label.add_theme_color_override("font_color", Color(0, 0, 0))
        name_label.text = ""
        name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        name_label.clip_text = false
        name_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
    if bar:
        bar.visible = false
        bar.value = 0
    if reward_label:
        reward_label.visible = false
        reward_label.text = ""
    if claim_button:
        claim_button.visible = false
        claim_button.disabled = true
        _apply_claim_button_style(claim_button)
        claim_button.set_meta("mission_id", "")

func show_overlay() -> void:
    _acquire_banner_lock()
    if _ui:
        _ui.visible = true
    visible = true

    var vp := get_viewport().get_visible_rect().size
    _apply_responsive_layout(vp)

    _refresh_all_ui_texts()

    if _mission_panel:
        var target_scale := Vector2.ONE * _mission_panel_target_scale
        _mission_panel.modulate.a = 0.0
        _mission_panel.scale = target_scale * 0.8
        # Ensure pivot is centered for scaling
        _mission_panel.pivot_offset = _mission_panel.size * 0.5
        var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
        tween.tween_property(_mission_panel, "modulate:a", 1.0, 0.3)
        tween.tween_property(_mission_panel, "scale", target_scale, 0.3)

    _reset_missions_scroll_to_top()
    if _missions_panel_node:
        _refresh_missions_panel(_missions_panel_node)
    _update_tab_buttons()
    _update_reset_time_label()
    _update_reset_daily_button_state()
    _update_reset_header_layout()


func _reset_missions_scroll_to_top() -> void:
    if _missions_scroll:
        _missions_scroll.scroll_vertical = 0


func _unhandled_input(_event: InputEvent) -> void:
    return


func _close_overlay_only() -> void:
    if _confirm_panel:
        _confirm_panel.visible = false

    if _mission_panel:
        var close_scale := Vector2.ONE * (_mission_panel_target_scale * 0.8)
        var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
        tween.tween_property(_mission_panel, "modulate:a", 0.0, 0.2)
        tween.tween_property(_mission_panel, "scale", close_scale, 0.2)
        await tween.finished

    if _ui:
        _ui.visible = false
    visible = false
    _release_banner_lock()
    overlay_closed.emit()


func _on_close_pressed() -> void:
    TransitionManager.play_sfx(&"click")
    if get_tree().current_scene == self:
        _on_back_pressed()
        return
    _close_overlay_only()

func _on_back_pressed() -> void:
    TransitionManager.play_sfx(&"click")
    if get_tree().current_scene == self:
        if Preloader and Preloader.has_method("set_next_scene"):
            Preloader.set_next_scene("res://scenes/MainMenu.tscn")
        await TransitionManager.play_transition_to_scene("res://scenes/LoadingScreen.tscn")
        return
    _close_overlay_only()

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


func _on_tab_pressed(tab: String) -> void:
    TransitionManager.play_sfx(&"click")
    _current_tab = tab
    _update_tab_buttons()
    _reset_missions_scroll_to_top()
    if _missions_panel_node:
        _refresh_missions_panel(_missions_panel_node)
    _update_reset_time_label()
    _update_reset_daily_button_state()
    _update_reset_header_layout()


func _are_all_daily_missions_completed(missions: Array) -> bool:
    var total := 0
    var completed := 0
    for m_any in missions:
        if not (m_any is Dictionary):
            continue
        var m: Dictionary = m_any
        var mt: String = String(m.get("type", ""))
        if mt == "challenge":
            continue
        if not (mt.is_empty() or mt == "daily"):
            continue
        var target: float = float(m.get("target", 0))
        if target <= 0.0:
            continue
        total += 1
        var prog: float = float(m.get("progress", 0))
        if prog >= target:
            completed += 1
    return total > 0 and completed >= total


func _are_all_daily_missions_completed_in_save() -> bool:
    if _missions_manager and _missions_manager.has_method("can_reset_daily_with_ad"):
        return bool(_missions_manager.call("can_reset_daily_with_ad"))
    return false


func _update_reset_daily_button_state() -> void:
    if _reset_daily_button == null:
        return
    var can_show := _current_tab == "daily" and _are_all_daily_missions_completed_in_save()
    _reset_daily_button.visible = can_show
    if can_show:
        var available := false
        if _ad_manager and _ad_manager.has_method("is_rewarded_available"):
            available = bool(_ad_manager.call("is_rewarded_available"))
        _reset_daily_button.disabled = not available
    else:
        _reset_daily_button.disabled = true
    _update_reset_header_layout()


func _update_reset_header_layout() -> void:
    if _reset_header_row == null:
        return

    _reset_header_row.visible = true

    if _reset_spacer == null:
        return

    if _current_tab == "daily":
        if _reset_spacer:
            _reset_spacer.visible = true
        _reset_header_row.alignment = BoxContainer.ALIGNMENT_BEGIN
    else:
        if _reset_spacer:
            _reset_spacer.visible = false
        _reset_header_row.alignment = BoxContainer.ALIGNMENT_CENTER


func _on_reset_daily_pressed() -> void:
    TransitionManager.play_sfx(&"click")
    if _current_tab != "daily":
        return
    if not _are_all_daily_missions_completed_in_save():
        _update_reset_daily_button_state()
        return
    var available := false
    if _ad_manager and _ad_manager.has_method("is_rewarded_available"):
        available = bool(_ad_manager.call("is_rewarded_available"))
    if not available:
        _update_reset_daily_button_state()
        return
    if _ad_manager and _ad_manager.has_method("show_rewarded"):
        _awaiting_rewarded_reason = "reset_daily_missions"
        _ad_manager.call("show_rewarded", _awaiting_rewarded_reason)


func _on_confirm_yes_pressed() -> void:
    TransitionManager.play_sfx(&"click")
    var action := _pending_action
    _pending_action = ""
    if _confirm_panel:
        _confirm_panel.visible = false
    if action == "reset_daily":
        if _ad_manager and _ad_manager.has_method("show_rewarded"):
            _awaiting_rewarded_reason = "reset_daily_missions"
            _ad_manager.call("show_rewarded", _awaiting_rewarded_reason)


func _on_confirm_no_pressed() -> void:
    TransitionManager.play_sfx(&"click")
    _pending_action = ""
    if _confirm_panel:
        _confirm_panel.visible = false


func _on_reward_granted(reason: String) -> void:
    if reason != _awaiting_rewarded_reason:
        return
    _awaiting_rewarded_reason = ""
    _apply_rewarded_daily_reset()


func _apply_rewarded_daily_reset() -> void:
    var did_reset := false
    if _missions_manager and _missions_manager.has_method("apply_daily_reset"):
        var res = _missions_manager.call("apply_daily_reset")
        did_reset = bool(res.get("ok", false))
    elif _missions_manager and _missions_manager.has_method("reset_daily_missions"):
        _missions_manager.call("reset_daily_missions")
        did_reset = true
    if did_reset:
        if _missions_panel_node:
            _refresh_missions_panel(_missions_panel_node)
        _update_reset_time_label()
        _update_reset_daily_button_state()
        var root_scene := get_tree().current_scene
        if root_scene and root_scene.has_method("refresh_missions_badge_from_save"):
            root_scene.call("refresh_missions_badge_from_save")


func _reset_daily_in_save_direct() -> bool:
    return false


func _update_daily_summary(missions: Array) -> void:
    if _daily_summary == null:
        return
    _daily_summary.visible = _current_tab == "daily"
    if not _daily_summary.visible:
        return

    var source_missions: Array = missions
    if _missions_manager and _missions_manager.has_method("get_missions_snapshot"):
        source_missions = _missions_manager.call("get_missions_snapshot", "daily")

    var total := 0
    var completed := 0
    for m_any in source_missions:
        if not (m_any is Dictionary):
            continue
        var m: Dictionary = m_any
        var mt: String = String(m.get("type", ""))
        if mt == "challenge":
            continue
        if not (mt.is_empty() or mt == "daily"):
            continue
        var target: float = float(m.get("target", 0))
        if target <= 0.0:
            continue
        total += 1
        var prog: float = float(m.get("progress", 0))
        if prog >= target:
            completed += 1

    if _daily_total_label:
        _daily_total_label.text = tr("Daily") + ": %d/%d" % [completed, total]
    if _daily_total_bar:
        _daily_total_bar.max_value = float(maxi(total, 1))
        _daily_total_bar.value = float(completed)



    var all_done := total > 0 and completed >= total
    var reward_claimed := false
    if _missions_manager:
        reward_claimed = bool(_missions_manager.get("daily_all_reward_claimed"))

    var reward_amt := maxi(daily_all_complete_reward_gems, 0)
    if all_done and reward_amt > 0:
        if reward_claimed:
            if _daily_all_reward_label:
                _daily_all_reward_label.visible = true
                _daily_all_reward_label.text = tr("Gems") + ": " + tr("Owned")
            if _daily_all_claim_button:
                _daily_all_claim_button.visible = false
        else:
            if _daily_all_reward_label:
                _daily_all_reward_label.visible = true
                _daily_all_reward_label.text = "+%d " % reward_amt + tr("Gems")
            if _daily_all_claim_button:
                _daily_all_claim_button.visible = true
                _daily_all_claim_button.disabled = false
                _apply_claim_button_style(_daily_all_claim_button)
    else:
        if _daily_all_reward_label:
            _daily_all_reward_label.visible = false
        if _daily_all_claim_button:
            _daily_all_claim_button.visible = false


func _on_claim_daily_all_pressed() -> void:
    TransitionManager.play_sfx(&"mission_claim")
    if _missions_manager == null or not _missions_manager.has_method("claim_daily_all_reward"):
        return
    var result: Dictionary = _missions_manager.call("claim_daily_all_reward")
    if not bool(result.get("ok", false)):
        return

    var claimed: Dictionary = result.get("reward_or_totals", {})
    var reward_amt := int(claimed.get("gems", maxi(daily_all_complete_reward_gems, 0)))
    if reward_amt <= 0:
        reward_amt = maxi(daily_all_complete_reward_gems, 0)

    var root_scene := get_tree().current_scene
    var gem_target := root_scene.get_node_or_null("UI/GemHUD/GemIcon") as Control if root_scene else null
    var diamond_count := clampi(reward_amt * 3, 4, 10)
    _play_claim_diamond_fly(_daily_all_claim_button as Control, gem_target, diamond_count)

    if _missions_panel_node:
        _refresh_missions_panel(_missions_panel_node)
    root_scene = get_tree().current_scene
    if root_scene and root_scene.has_method("_refresh_currency_display"):
        root_scene.call("_refresh_currency_display")
    elif root_scene and root_scene.has_method("refresh_gems_from_save"):
        root_scene.call("refresh_gems_from_save")


func _process(delta: float) -> void:
    if not is_inside_tree():
        return
    if get_tree().current_scene == self:
        return
    if not visible:
        return
    _reset_time_accum += delta
    if _reset_time_accum >= 1.0:
        _reset_time_accum = 0.0
        _update_reset_time_label()


func _update_tab_buttons() -> void:
    var daily_btn := _daily_button
    var mission_btn := _mission_button
    var weekly_btn := _weekly_button
    var monthly_btn := _monthly_button
    var challenge_btn := _challenge_button

    _apply_tab_style(daily_btn, _current_tab == "daily")
    _apply_tab_style(mission_btn, _current_tab == "mission")
    _apply_tab_style(weekly_btn, _current_tab == "week")
    _apply_tab_style(monthly_btn, _current_tab == "month")
    _apply_tab_style(challenge_btn, _current_tab == "challenge")


func _apply_tab_style(btn: BaseButton, active: bool) -> void:
    if btn == null:
        return
    var style := _tab_style_normal
    if active and _tab_style_active != null:
        style = _tab_style_active
    if style != null:
        btn.add_theme_stylebox_override("normal", style)
        btn.add_theme_stylebox_override("hover", style)
        btn.add_theme_stylebox_override("pressed", style)
        btn.add_theme_stylebox_override("focus", style)
    if active:
        btn.add_theme_color_override("font_color", Color(0, 0, 0))
        btn.add_theme_color_override("font_hover_color", Color(0, 0, 0))
        btn.add_theme_color_override("font_pressed_color", Color(0, 0, 0))
        btn.add_theme_color_override("font_focus_color", Color(0, 0, 0))
    else:
        btn.add_theme_color_override("font_color", Color(1, 1, 1))
        btn.add_theme_color_override("font_hover_color", Color(1, 1, 1))
        btn.add_theme_color_override("font_pressed_color", Color(1, 1, 1))
        btn.add_theme_color_override("font_focus_color", Color(1, 1, 1))


func _apply_ui_font(node: Node, font: Font) -> void:
    if node is Label:
        var lbl := node as Label
        lbl.add_theme_font_override("font", font)
    elif node is BaseButton:
        var btn := node as BaseButton
        btn.add_theme_font_override("font", font)
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


func _refresh_missions_panel(panel: Node) -> void:
    var panel_vbox := panel as VBoxContainer
    if panel_vbox == null:
        panel.visible = false
        return
    var missions: Array = []
    if _missions_manager and _missions_manager.has_method("get_missions_snapshot"):
        missions = _missions_manager.call("get_missions_snapshot", "")

    _update_daily_summary(missions)
    var kill_missions: Array = []
    var other_missions: Array = []
    for m in missions:
        if not (m is Dictionary):
            continue
        var t: String = String(m.get("type", ""))
        var mname: String = String(m.get("name", ""))
        var kind: String = String(m.get("kind", ""))
        var is_kill := kind == "enemies" or (kind.is_empty() and (mname.begins_with("Kalahkan") or mname.begins_with("Defeat") or mname.begins_with("击败")))
        if t.is_empty():
            if _current_tab == "daily" or _current_tab == "mission":
                if is_kill:
                    kill_missions.append(m)
                else:
                    other_missions.append(m)
            continue
        match _current_tab:
            "daily":
                if t == "daily":
                    if is_kill:
                        kill_missions.append(m)
                    else:
                        other_missions.append(m)
            "mission":
                if t == "mission":
                    if is_kill:
                        kill_missions.append(m)
                    else:
                        other_missions.append(m)
            "week":
                if t == "week":
                    if is_kill:
                        kill_missions.append(m)
                    else:
                        other_missions.append(m)
            "month":
                if t == "month":
                    if is_kill:
                        kill_missions.append(m)
                    else:
                        other_missions.append(m)
            "challenge":
                if t == "challenge":
                    if is_kill:
                        kill_missions.append(m)
                    else:
                        other_missions.append(m)
            _:
                pass
    var filtered: Array = []
    filtered.append_array(kill_missions)
    filtered.append_array(other_missions)
    panel.visible = true

    var rows := _ensure_mission_rows(panel_vbox, filtered.size())
    var compact := _last_viewport_size.x > 0 and (_last_viewport_size.x < 980 or _last_viewport_size.y < 560)
    var large := _last_viewport_size.x >= 1500
    var row_h: float = 56.0 if compact else (72.0 if large else 64.0)
    var name_min_x: float = 120.0 if compact else (210.0 if large else 180.0)
    var bar_min_x: float = 96.0 if compact else (140.0 if large else 120.0)
    var reward_min_x: float = 64.0 if compact else (92.0 if large else 80.0)
    var claim_size := Vector2(64.0, 42.0) if compact else (Vector2(80.0, 52.0) if large else Vector2(72.0, 48.0))
    var mission_name_font_size: int = 16 if compact else (22 if large else 20)
    var reward_font_size: int = 14 if compact else (18 if large else 16)
    for i in range(rows.size()):
        var slot := rows[i] as Control
        if slot == null:
            continue
        if i >= filtered.size():
            slot.visible = false
            continue

        slot.visible = true
        slot.custom_minimum_size.y = row_h
        slot.alignment = BoxContainer.ALIGNMENT_CENTER
        slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL

        var m_any = filtered[i]
        if not (m_any is Dictionary):
            _clear_mission_row(slot)
            continue

        var m: Dictionary = m_any
        var name_label := slot.get_node_or_null("Name") as Label
        var bar := slot.get_node_or_null("Bar") as ProgressBar
        var reward_label := slot.get_node_or_null("Reward") as Label
        var claim_button := slot.get_node_or_null("ClaimButton") as BaseButton

        var mname: String = String(m.get("name", ""))
        var target: float = float(m.get("target", 1))
        if target <= 0.0:
            target = 1.0
        var prog: float = float(m.get("progress", 0))
        var reward: int = int(m.get("reward", 0))
        var id_str := String(m.get("id", ""))
        var is_completed := prog >= target
        var is_claimed := bool(m.get("is_claimed", false))

        if name_label:
            name_label.visible = true
            name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER # Center teks secara vertikal
            name_label.add_theme_color_override("font_color", Color(0, 0, 0))
            name_label.layout_direction = Control.LAYOUT_DIRECTION_LTR
            name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
            name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
            name_label.custom_minimum_size.x = name_min_x
            name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
            name_label.clip_text = false
            name_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
            name_label.add_theme_font_size_override("font_size", mission_name_font_size)

            var localized_text := tr(mname)
            if localized_text.contains("{n}"):
                localized_text = localized_text.replace("{n}", str(int(target)))
            name_label.text = localized_text

            name_label.add_theme_color_override("font_color", Color(0, 0, 0))
        if bar:
            bar.visible = true
            bar.show_percentage = false
            bar.max_value = target
            bar.value = clampf(prog, 0.0, target)
            bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
            bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            bar.custom_minimum_size.x = bar_min_x
            var default_h: float
            if bar.has_meta("default_min_h"):
                default_h = float(bar.get_meta("default_min_h"))
            else:
                default_h = float(bar.custom_minimum_size.y)
                bar.set_meta("default_min_h", default_h)
            var h := default_h
            bar.custom_minimum_size = Vector2(bar.custom_minimum_size.x, h)
        if reward_label:
            reward_label.visible = true
            reward_label.add_theme_color_override("font_color", Color(0, 0, 0))
            reward_label.text = "+" + str(reward) + "c"
            reward_label.custom_minimum_size.x = reward_min_x
            reward_label.add_theme_font_size_override("font_size", reward_font_size)
            reward_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
            reward_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
        if claim_button:
            claim_button.visible = true
            claim_button.disabled = not is_completed or is_claimed or reward <= 0 or id_str.is_empty()
            claim_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
            claim_button.custom_minimum_size = claim_size
            _apply_claim_button_style(claim_button)
            claim_button.set_meta("mission_id", id_str)

    _connect_claim_buttons(panel_vbox)
    _update_reset_daily_button_state()


func _apply_claim_button_style(btn: BaseButton) -> void:
    if btn == null:
        return
    if btn is Button:
        var b := btn as Button
        b.text = ""
        b.flat = true
        b.focus_mode = Control.FOCUS_NONE
    var tex := _claim_tex_active
    if btn.disabled and _claim_tex_disabled != null:
        tex = _claim_tex_disabled
    if tex != null:
        if btn is Button:
            var b2 := btn as Button
            b2.icon = tex
            b2.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
            b2.expand_icon = true


func _load_button_texture(path: String) -> Texture2D:
    var t := load(path) as Texture2D
    if t != null:
        return t
    var img := Image.new()
    var err := img.load(path)
    if err != OK:
        return null
    return ImageTexture.create_from_image(img)


func _get_reset_type_for_current_tab() -> String:
    match _current_tab:
        "daily":
            return "daily"
        "week":
            return "week"
        "month":
            return "month"
        _:
            return ""


func _get_reset_interval_sec(t: String) -> int:
    match t:
        "daily":
            return 24 * 60 * 60
        "week":
            return 7 * 24 * 60 * 60
        "month":
            return 30 * 24 * 60 * 60
        _:
            return 0


func _get_remaining_reset_seconds(t: String) -> int:
    var interval := _get_reset_interval_sec(t)
    if interval <= 0:
        return 0
    var last: int = 0
    if _missions_manager:
        match t:
            "daily":
                last = int(_missions_manager.get("last_reset_daily"))
            "week":
                last = int(_missions_manager.get("last_reset_week"))
            "month":
                last = int(_missions_manager.get("last_reset_month"))
            _:
                return 0
    var now: int = int(Time.get_unix_time_from_system())
    if last <= 0:
        return interval
    var elapsed: int = now - last
    if elapsed < 0:
        elapsed = 0
    var remaining: int = interval - elapsed
    if remaining < 0:
        remaining = 0
    return remaining


func _update_reset_time_label() -> void:
    if _reset_label == null:
        return
    var t := _get_reset_type_for_current_tab()
    if t == "":
        _reset_label.visible = false
        _update_reset_header_layout()
        return
    var remaining := _get_remaining_reset_seconds(t)
    _reset_label.visible = true
    var prefix := tr("Reset")
    match t:
        "daily":
            prefix = tr("Daily Reset")
        "week":
            prefix = tr("Weekly Reset")
        "month":
            prefix = tr("Monthly Reset")
        _:
            prefix = tr("Reset")
    if remaining <= 0:
        _reset_label.text = tr("%s: Now") % [prefix]
        if _missions_panel_node:
            _refresh_missions_panel(_missions_panel_node)
        return
    var hours: int = int(remaining / 3600.0)
    var minutes: int = int((remaining % 3600) / 60.0)
    var seconds: int = remaining % 60
    var time_str := "%02d:%02d:%02d" % [hours, minutes, seconds]
    _reset_label.text = tr("%s in %s") % [prefix, time_str]
    _update_reset_header_layout()


func _connect_claim_buttons(panel: Node) -> void:
    var rows := _get_mission_rows(panel)
    for slot in rows:
        var claim_button := slot.get_node_or_null("ClaimButton") as BaseButton
        if claim_button == null:
            continue

        # Hapus koneksi lama untuk menghindari duplikat
        for connection in claim_button.pressed.get_connections():
            if connection.callable.get_object() == self and connection.callable.get_method() == "_on_claim_button_pressed":
                claim_button.pressed.disconnect(connection.callable)

        # Tambahkan koneksi baru
        var cb := Callable(self, "_on_claim_button_pressed").bind(claim_button)
        claim_button.pressed.connect(cb)


func _on_claim_button_pressed(button: BaseButton) -> void:
    if button == null:
        return
    if button.disabled:
        return
    var mission_id := ""
    if button.has_meta("mission_id"):
        mission_id = String(button.get_meta("mission_id"))
    if mission_id.is_empty():
        return
    if _missions_manager == null or not _missions_manager.has_method("claim_mission"):
        return
    button.disabled = true
    _apply_claim_button_style(button)
    var result: Dictionary = _missions_manager.call("claim_mission", mission_id)
    if not bool(result.get("ok", false)):
        var err := String(result.get("error", ""))
        if err == "mission_already_claimed":
            if _missions_panel_node:
                _refresh_missions_panel(_missions_panel_node)
            var root_scene_claimed := get_tree().current_scene
            if root_scene_claimed and root_scene_claimed.has_method("refresh_missions_badge_from_save"):
                root_scene_claimed.call("refresh_missions_badge_from_save")
            return
        button.disabled = false
        _apply_claim_button_style(button)
        return
    TransitionManager.play_sfx(&"mission_claim")

    var root_scene := get_tree().current_scene
    var coin_target := root_scene.get_node_or_null("UI/CoinHUD/CoinIcon") as Control if root_scene else null
    var coin_count: int = _coin_fx_rng.randi_range(5, 10)
    _play_claim_coin_fly(button as Control, coin_target, coin_count)

    if _missions_panel_node:
        _refresh_missions_panel(_missions_panel_node)
    if root_scene and root_scene.has_method("_refresh_currency_display"):
        root_scene.call("_refresh_currency_display")
    elif root_scene and root_scene.has_method("refresh_coin_from_save"):
        root_scene.call("refresh_coin_from_save")
    if root_scene and root_scene.has_method("refresh_missions_badge_from_save"):
        root_scene.call("refresh_missions_badge_from_save")


func _play_claim_coin_fly(from_control: Control, to_control: Control, count: int) -> void:
    if from_control == null:
        return
    if _coin_fx_tex == null:
        return
    if count <= 0:
        return
    var ui_layer := _ui
    if ui_layer == null:
        return

    var from_rect := from_control.get_global_rect()
    var from_center := from_rect.position + from_rect.size * 0.5

    var to_center := Vector2(56, 96)
    if to_control != null:
        var to_rect := to_control.get_global_rect()
        to_center = to_rect.position + to_rect.size * 0.5

    for i in range(count):
        var coin := TextureRect.new()
        coin.texture = _coin_fx_tex
        coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
        coin.set_as_top_level(true)
        coin.size = Vector2(24, 24)
        coin.pivot_offset = coin.size * 0.5
        ui_layer.add_child(coin)

        var start_offset := Vector2(
            _coin_fx_rng.randf_range(-26.0, 26.0),
            _coin_fx_rng.randf_range(-18.0, 18.0)
        )
        coin.global_position = (from_center + start_offset) - coin.pivot_offset
        coin.modulate = Color(1, 1, 1, 1)
        coin.scale = Vector2.ONE * _coin_fx_rng.randf_range(0.85, 1.05)

        var t := create_tween()
        t.tween_interval(_coin_fx_rng.randf_range(0.0, 0.12))
        t.tween_property(coin, "global_position", to_center - coin.pivot_offset, _coin_fx_rng.randf_range(0.35, 0.55)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
        t.parallel().tween_property(coin, "modulate:a", 0.0, _coin_fx_rng.randf_range(0.35, 0.55)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
        t.finished.connect(func():
            if coin:
                coin.queue_free()
        )


func _play_claim_diamond_fly(from_control: Control, to_control: Control, count: int) -> void:
    if from_control == null:
        return
    if _diamond_fx_tex == null:
        return
    if count <= 0:
        return
    var ui_layer := _ui
    if ui_layer == null:
        return

    var from_rect := from_control.get_global_rect()
    var from_center := from_rect.position + from_rect.size * 0.5

    var to_center := Vector2(96, 56)
    if to_control != null:
        var to_rect := to_control.get_global_rect()
        to_center = to_rect.position + to_rect.size * 0.5

    for i in range(count):
        var d := TextureRect.new()
        d.texture = _diamond_fx_tex
        d.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        d.mouse_filter = Control.MOUSE_FILTER_IGNORE
        d.set_as_top_level(true)
        d.size = Vector2(22, 22)
        d.pivot_offset = d.size * 0.5
        ui_layer.add_child(d)

        var start_offset := Vector2(
            _coin_fx_rng.randf_range(-20.0, 20.0),
            _coin_fx_rng.randf_range(-16.0, 16.0)
        )
        d.global_position = (from_center + start_offset) - d.pivot_offset
        d.modulate = Color(1, 1, 1, 1)
        d.scale = Vector2.ONE * _coin_fx_rng.randf_range(0.75, 1.05)
        d.rotation = _coin_fx_rng.randf_range(-0.2, 0.2)

        var t := create_tween()
        t.tween_interval(_coin_fx_rng.randf_range(0.0, 0.1))
        t.tween_property(d, "global_position", to_center - d.pivot_offset, _coin_fx_rng.randf_range(0.45, 0.7)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
        t.parallel().tween_property(d, "rotation", _coin_fx_rng.randf_range(-0.9, 0.9), _coin_fx_rng.randf_range(0.45, 0.7)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
        t.parallel().tween_property(d, "modulate:a", 0.0, _coin_fx_rng.randf_range(0.45, 0.7)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
        t.finished.connect(func():
            if d:
                d.queue_free()
        )
