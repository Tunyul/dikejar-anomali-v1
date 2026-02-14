extends Control

signal overlay_closed


var _current_tab := "daily"
var _reset_label: Label = null
var _reset_time_accum: float = 0.0
var _tab_style_normal: StyleBox = null
var _tab_style_active: StyleBox = null
var _claim_tex_active: Texture2D = null
var _claim_tex_disabled: Texture2D = null
var _coin_fx_tex: Texture2D = null
var _diamond_fx_tex: Texture2D = null
var _coin_fx_rng := RandomNumberGenerator.new()

@export var daily_all_complete_reward_gems: int = 1

var _reset_daily_button: BaseButton = null
var _reset_header_row: HBoxContainer = null
var _reset_spacer: Control = null
var _confirm_panel: Control = null
var _confirm_message: Label = null
var _confirm_yes: BaseButton = null
var _confirm_no: BaseButton = null
var _pending_action: String = ""
var _awaiting_rewarded_reason: String = ""
var _ad_manager: Node = null
var _missions_manager: Node = null
var _mission_panel: Control = null
var _last_viewport_size: Vector2i = Vector2i(-1, -1)

var _daily_summary: Control = null
var _daily_total_label: Label = null
var _daily_total_bar: ProgressBar = null
var _daily_all_reward_label: Label = null
var _daily_all_claim_button: BaseButton = null


func _notification(what: int) -> void:
    if what == NOTIFICATION_TRANSLATION_CHANGED:
        _refresh_all_ui_texts()

func _refresh_all_ui_texts() -> void:
    # Update Judul
    var title_label := get_node_or_null("UI/TitleLabel") as Label
    if title_label:
        title_label.text = tr("MISSIONS")

    # Update Tab Buttons
    var daily_btn := get_node_or_null("UI/MissionPanel/PanelContent/VBox/Tabs/DailyButton") as BaseButton
    if daily_btn: daily_btn.text = tr("DAILY")
    var mission_btn := get_node_or_null("UI/MissionPanel/PanelContent/VBox/Tabs/MissionButton") as BaseButton
    if mission_btn: mission_btn.text = tr("MISSION")
    var weekly_btn := get_node_or_null("UI/MissionPanel/PanelContent/VBox/Tabs/WeeklyButton") as BaseButton
    if weekly_btn: weekly_btn.text = tr("WEEKLY")
    var monthly_btn := get_node_or_null("UI/MissionPanel/PanelContent/VBox/Tabs/MonthlyButton") as BaseButton
    if monthly_btn: monthly_btn.text = tr("MONTHLY")
    var challenge_btn := get_node_or_null("UI/MissionPanel/PanelContent/VBox/Tabs/ChallengeButton") as BaseButton
    if challenge_btn: challenge_btn.text = tr("CHALLENGE")

    # Update Back Button
    var back := get_node_or_null("UI/MissionPanel/PanelContent/VBox/BackButton") as BaseButton
    if back: back.text = tr("BACK")

    # Update Reset Label
    if _reset_label:
        # Reset label text biasanya diupdate di _process, tapi kita panggil manual jika perlu
        pass

    # Update Mission List
    var missions_panel := get_node_or_null("UI/MissionPanel/PanelContent/VBox/MissionListContainer/MissionsScroll/MissionsPanel")
    if missions_panel:
        _refresh_missions_panel(missions_panel)

    # Update Daily Summary
    if _daily_summary and _daily_summary.visible:
        var cfg := ConfigFile.new()
        cfg.load("user://save.cfg")
        var missions_value = cfg.get_value("missions", "list", [])
        if missions_value is Array:
            _update_daily_summary(cfg, missions_value)

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _refresh_all_ui_texts()
    var back := get_node_or_null("UI/MissionPanel/PanelContent/VBox/BackButton") as BaseButton
    if back:
        back.pressed.connect(_on_back_pressed)
    var ui_font := load("res://assets/font/Fredoka Nunito/Nunito/static/Nunito-Regular.ttf") as Font
    var title_font := load("res://assets/font/Fredoka Nunito/Fredoka/static/Fredoka-Bold.ttf") as Font
    if ui_font:
        _apply_ui_font(self, ui_font)
    if title_font:
        var title_label := get_node_or_null("UI/TitleLabel") as Label
        if title_label:
            title_label.add_theme_font_override("font", title_font)
            title_label.add_theme_color_override("font_color", Color(1, 1, 0, 1))
            title_label.add_theme_constant_override("outline_size", 3)
            title_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
            title_label.add_theme_font_size_override("font_size", 36)
    _reset_label = get_node_or_null("UI/MissionPanel/PanelContent/VBox/ResetHeaderRow/ResetTimeLabel") as Label
    if _reset_label:
        _reset_label.add_theme_color_override("font_color", Color(0, 0, 0))
    _reset_header_row = get_node_or_null("UI/MissionPanel/PanelContent/VBox/ResetHeaderRow") as HBoxContainer
    _reset_spacer = get_node_or_null("UI/MissionPanel/PanelContent/VBox/ResetHeaderRow/Spacer") as Control
    _apply_mission_name_color()
    _apply_mission_reward_color()
    _daily_summary = get_node_or_null("UI/MissionPanel/PanelContent/VBox/ResetHeaderRow/DailyGroup") as Control
    _daily_total_label = get_node_or_null("UI/MissionPanel/PanelContent/VBox/ResetHeaderRow/DailyGroup/DailyTotalLabel") as Label
    _daily_total_bar = get_node_or_null("UI/MissionPanel/PanelContent/VBox/ResetHeaderRow/DailyGroup/DailyTotalBar") as ProgressBar
    if ui_font and _daily_total_label:
        _daily_total_label.add_theme_font_override("font", ui_font)
        _daily_total_label.add_theme_color_override("font_color", Color(0, 0, 0, 1))
        _daily_total_label.add_theme_constant_override("outline_size", 0)
        _daily_total_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0))
        _daily_total_label.add_theme_font_size_override("font_size", 18)
    _daily_all_reward_label = get_node_or_null("UI/MissionPanel/PanelContent/VBox/ResetHeaderRow/DailyGroup/DailyAllRewardLabel") as Label
    _daily_all_claim_button = get_node_or_null("UI/MissionPanel/PanelContent/VBox/ResetHeaderRow/DailyGroup/ClaimDailyAllButton") as BaseButton
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
    var missions_panel := get_node_or_null("UI/MissionPanel/PanelContent/VBox/MissionListContainer/MissionsScroll/MissionsPanel")
    if missions_panel:
        _refresh_missions_panel(missions_panel)
        _connect_claim_buttons(missions_panel)
    var daily_btn := get_node_or_null("UI/MissionPanel/PanelContent/VBox/Tabs/DailyButton") as BaseButton
    var mission_btn := get_node_or_null("UI/MissionPanel/PanelContent/VBox/Tabs/MissionButton") as BaseButton
    var weekly_btn := get_node_or_null("UI/MissionPanel/PanelContent/VBox/Tabs/WeeklyButton") as BaseButton
    var monthly_btn := get_node_or_null("UI/MissionPanel/PanelContent/VBox/Tabs/MonthlyButton") as BaseButton
    var challenge_btn := get_node_or_null("UI/MissionPanel/PanelContent/VBox/Tabs/ChallengeButton") as BaseButton
    if daily_btn:
        daily_btn.pressed.connect(func(): _on_tab_pressed("daily"))
    if mission_btn:
        mission_btn.pressed.connect(func(): _on_tab_pressed("mission"))
    if weekly_btn:
        weekly_btn.pressed.connect(func(): _on_tab_pressed("week"))
    if monthly_btn:
        monthly_btn.pressed.connect(func(): _on_tab_pressed("month"))
    if challenge_btn:
        challenge_btn.pressed.connect(func(): _on_tab_pressed("challenge"))
    _update_tab_buttons()
    _update_reset_time_label()

    _reset_daily_button = get_node_or_null("UI/MissionPanel/PanelContent/VBox/ResetHeaderRow/ResetDailyButton") as BaseButton
    if _reset_daily_button:
        _reset_daily_button.pressed.connect(_on_reset_daily_pressed)
        if _reset_header_row:
            var h := maxf(_reset_header_row.custom_minimum_size.y, _reset_daily_button.custom_minimum_size.y)
            if h <= 0.0:
                h = 44.0
            _reset_header_row.custom_minimum_size = Vector2(_reset_header_row.custom_minimum_size.x, h)

    _confirm_panel = get_node_or_null("UI/ConfirmPanel") as Control
    _confirm_message = get_node_or_null("UI/ConfirmPanel/Message") as Label
    _confirm_yes = get_node_or_null("UI/ConfirmPanel/Buttons/YesButton") as BaseButton
    _confirm_no = get_node_or_null("UI/ConfirmPanel/Buttons/NoButton") as BaseButton
    if _confirm_panel:
        _confirm_panel.visible = false
    if _confirm_yes:
        _confirm_yes.pressed.connect(_on_confirm_yes_pressed)
    if _confirm_no:
        _confirm_no.pressed.connect(_on_confirm_no_pressed)

    _ad_manager = get_node_or_null("AdManager")
    _missions_manager = get_node_or_null("MissionsManager")
    if _ad_manager and _ad_manager.has_signal("reward_granted"):
        var cb := Callable(self, "_on_reward_granted")
        if not _ad_manager.is_connected("reward_granted", cb):
            _ad_manager.connect("reward_granted", cb)

    _update_reset_daily_button_state()
    _update_reset_header_layout()
    var close_btn := get_node_or_null("UI/MissionPanel/CloseButton") as BaseButton
    if close_btn and not close_btn.pressed.is_connected(_on_close_pressed):
        close_btn.pressed.connect(_on_close_pressed)
    if get_tree().current_scene != self:
        var ui := get_node_or_null("UI")
        if ui:
            ui.visible = false
        visible = false

    _mission_panel = get_node_or_null("UI/MissionPanel") as Control
    _connect_viewport_resize()
    if TransitionManager and TransitionManager.has_signal("language_changed"):
        var cb_lang := Callable(self, "_on_language_changed")
        if not TransitionManager.language_changed.is_connected(cb_lang):
            TransitionManager.language_changed.connect(cb_lang)


func _on_language_changed(_locale: String) -> void:
    _refresh_all_ui_texts()
    _update_reset_time_label()
    var panel := get_node_or_null("UI/MissionPanel/PanelContent/VBox/MissionListContainer/MissionsScroll/MissionsPanel")
    if panel:
        _refresh_missions_panel(panel)


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
    if _mission_panel == null:
        return
    var safe := Rect2(Vector2.ZERO, vp)
    if OS.has_feature("android") or OS.has_feature("ios"):
        var sa := DisplayServer.get_display_safe_area()
        if sa.size.x > 0 and sa.size.y > 0:
            safe = Rect2(Vector2(sa.position), Vector2(sa.size))

    var margin := 16.0
    var safe_size := Vector2(maxf(safe.size.x - margin * 2.0, 1.0), maxf(safe.size.y - margin * 2.0, 1.0))
    var max_w := safe_size.x * 0.58
    var max_h := safe_size.y * 0.54
    var w := max_w
    var h := max_h
    var tex_aspect := 0.0
    if _mission_panel is TextureRect:
        var mission_tr := _mission_panel as TextureRect
        if mission_tr.texture:
            var ts := mission_tr.texture.get_size()
            if ts.y > 0.0:
                tex_aspect = ts.x / ts.y
    if tex_aspect > 0.0:
        if (max_w / max_h) > tex_aspect:
            h = max_h
            w = h * tex_aspect
        else:
            w = max_w
            h = w / tex_aspect
    w = clampf(w, 1.0, safe_size.x)
    h = clampf(h, 1.0, safe_size.y)

    _mission_panel.anchor_left = 0.5
    _mission_panel.anchor_top = 0.5
    _mission_panel.anchor_right = 0.5
    _mission_panel.anchor_bottom = 0.5
    _mission_panel.offset_left = -w * 0.5
    _mission_panel.offset_top = -h * 0.5
    _mission_panel.offset_right = w * 0.5
    _mission_panel.offset_bottom = h * 0.5

    var pc := get_node_or_null("UI/MissionPanel/PanelContent") as Control
    if pc:
        var lm := clampf(w * 0.08, 56.0, 92.0)
        var tm := clampf(h * 0.16, 72.0, 132.0)
        var bm := clampf(h * 0.12, 56.0, 110.0)
        pc.offset_left = lm
        pc.offset_right = -lm
        pc.offset_top = tm
        pc.offset_bottom = -bm


func _apply_mission_name_color() -> void:
    var panel := get_node_or_null("UI/MissionPanel/PanelContent/VBox/MissionListContainer/MissionsScroll/MissionsPanel") as VBoxContainer
    if panel == null:
        return
    for slot in panel.get_children():
        var row := slot as Control
        if row == null:
            continue
        var name_label := row.get_node_or_null("Name") as Label
        if name_label:
            name_label.add_theme_color_override("font_color", Color(0, 0, 0))


func _apply_mission_reward_color() -> void:
    var panel := get_node_or_null("UI/MissionPanel/PanelContent/VBox/MissionListContainer/MissionsScroll/MissionsPanel") as VBoxContainer
    if panel == null:
        return
    for slot in panel.get_children():
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
    var ui := get_node_or_null("UI")
    if ui:
        ui.visible = true
    visible = true

    _refresh_all_ui_texts()

    if _mission_panel:
        _mission_panel.modulate.a = 0.0
        _mission_panel.scale = Vector2(0.8, 0.8)
        # Ensure pivot is centered for scaling
        _mission_panel.pivot_offset = _mission_panel.size * 0.5
        var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
        tween.tween_property(_mission_panel, "modulate:a", 1.0, 0.3)
        tween.tween_property(_mission_panel, "scale", Vector2.ONE, 0.3)

    _reset_missions_scroll_to_top()
    var missions_panel := get_node_or_null("UI/MissionPanel/PanelContent/VBox/MissionListContainer/MissionsScroll/MissionsPanel")
    if missions_panel:
        _refresh_missions_panel(missions_panel)
    _update_tab_buttons()
    _update_reset_time_label()
    _update_reset_daily_button_state()
    _update_reset_header_layout()


func _reset_missions_scroll_to_top() -> void:
    var sc := get_node_or_null("UI/MissionPanel/PanelContent/VBox/MissionListContainer/MissionsScroll") as ScrollContainer
    if sc:
        sc.scroll_vertical = 0

func _unhandled_input(_event: InputEvent) -> void:
    return


func _close_overlay_only() -> void:
    if _confirm_panel:
        _confirm_panel.visible = false

    if _mission_panel:
        var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
        tween.tween_property(_mission_panel, "modulate:a", 0.0, 0.2)
        tween.tween_property(_mission_panel, "scale", Vector2(0.8, 0.8), 0.2)
        await tween.finished

    var ui := get_node_or_null("UI")
    if ui:
        ui.visible = false
    visible = false
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


func _on_tab_pressed(tab: String) -> void:
    TransitionManager.play_sfx(&"click")
    _current_tab = tab
    _update_tab_buttons()
    _reset_missions_scroll_to_top()
    var panel := get_node_or_null("UI/MissionPanel/PanelContent/VBox/MissionListContainer/MissionsScroll/MissionsPanel")
    if panel:
        _refresh_missions_panel(panel)
    _update_reset_time_label()
    _update_reset_daily_button_state()
    _update_reset_header_layout()


func _update_reset_daily_button_state() -> void:
    if _reset_daily_button == null:
        _reset_daily_button = get_node_or_null("UI/MissionPanel/PanelContent/VBox/ResetHeaderRow/ResetDailyButton") as BaseButton
    _reset_daily_button.visible = _current_tab == "daily"
    if _reset_daily_button.visible:
        var available := false
        if _ad_manager and _ad_manager.has_method("is_rewarded_available"):
            available = bool(_ad_manager.call("is_rewarded_available"))
        _reset_daily_button.disabled = not available
    _update_reset_header_layout()


func _update_reset_header_layout() -> void:
    if _reset_header_row == null:
        _reset_header_row = get_node_or_null("UI/MissionPanel/PanelContent/VBox/ResetHeaderRow") as HBoxContainer
    if _reset_header_row == null:
        return

    _reset_header_row.visible = true

    if _reset_spacer == null:
        _reset_spacer = get_node_or_null("UI/MissionPanel/PanelContent/VBox/ResetHeaderRow/Spacer") as Control

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
    _pending_action = "reset_daily"
    if _confirm_panel and _confirm_message:
        _confirm_message.text = tr("Reset misi harian?\nTonton iklan untuk reset.")
        _confirm_panel.visible = true


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
    if _missions_manager and _missions_manager.has_method("reset_daily_missions"):
        _missions_manager.call("reset_daily_missions")
        did_reset = true
    if not did_reset:
        did_reset = _reset_daily_in_save_direct()
    if did_reset:
        var panel := get_node_or_null("UI/MissionPanel/PanelContent/VBox/MissionListContainer/MissionsScroll/MissionsPanel")
        if panel:
            _refresh_missions_panel(panel)
        _update_reset_time_label()
        var root_scene := get_tree().current_scene
        if root_scene and root_scene.has_method("refresh_missions_badge_from_save"):
            root_scene.call("refresh_missions_badge_from_save")


func _reset_daily_in_save_direct() -> bool:
    var cfg := ConfigFile.new()
    var err := cfg.load("user://save.cfg")
    if err != OK:
        return false
    var missions_value = cfg.get_value("missions", "list", [])
    if not (missions_value is Array):
        return false
    var missions: Array = missions_value
    var claimed_value = cfg.get_value("missions", "reward_claimed", {})
    var claimed: Dictionary = {}
    if claimed_value is Dictionary:
        claimed = claimed_value
    _reset_missions_of_type("daily", missions, claimed)
    _apply_reset_bases(cfg, "daily")
    cfg.set_value("missions", "last_reset_daily", int(Time.get_unix_time_from_system()))
    cfg.set_value("missions", "daily_all_reward_claimed", false)
    cfg.set_value("missions", "list", missions)
    cfg.set_value("missions", "reward_claimed", claimed)
    cfg.save("user://save.cfg")
    return true


func _update_daily_summary(cfg: ConfigFile, missions: Array) -> void:
    if _daily_summary == null:
        return
    _daily_summary.visible = _current_tab == "daily"
    if not _daily_summary.visible:
        return

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

    if _daily_total_label:
        _daily_total_label.text = tr("Daily") + ": %d/%d" % [completed, total]
    if _daily_total_bar:
        _daily_total_bar.max_value = float(maxi(total, 1))
        _daily_total_bar.value = float(completed)



    var all_done := total > 0 and completed >= total
    var reward_claimed := false
    if cfg != null:
        reward_claimed = bool(cfg.get_value("missions", "daily_all_reward_claimed", false))

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
    var cfg := ConfigFile.new()
    var err := cfg.load("user://save.cfg")
    if err != OK:
        return
    if bool(cfg.get_value("missions", "daily_all_reward_claimed", false)):
        return

    var missions_value = cfg.get_value("missions", "list", [])
    if not (missions_value is Array):
        return
    var missions: Array = missions_value

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

    if total <= 0 or completed < total:
        return

    var reward_amt := maxi(daily_all_complete_reward_gems, 0)
    if reward_amt <= 0:
        return

    var total_gems: int = int(cfg.get_value("progress", "total_gems", 0))
    total_gems += reward_amt
    cfg.set_value("progress", "total_gems", total_gems)
    cfg.set_value("missions", "daily_all_reward_claimed", true)
    cfg.save("user://save.cfg")

    var root_scene := get_tree().current_scene
    var gem_target := root_scene.get_node_or_null("UI/GemHUD/GemIcon") as Control if root_scene else null
    var diamond_count := clampi(reward_amt * 3, 4, 10)
    _play_claim_diamond_fly(_daily_all_claim_button as Control, gem_target, diamond_count)

    if _missions_manager and _missions_manager.has_method("reload_from_save"):
        _missions_manager.call("reload_from_save")

    var panel := get_node_or_null("UI/MissionPanel/PanelContent/VBox/MissionListContainer/MissionsScroll/MissionsPanel")
    if panel:
        _refresh_missions_panel(panel)
    root_scene = get_tree().current_scene
    if root_scene and root_scene.has_method("refresh_gems_from_save"):
        root_scene.call("refresh_gems_from_save")


func _process(delta: float) -> void:
    if get_tree().current_scene == self:
        return
    if not visible:
        return
    _reset_time_accum += delta
    if _reset_time_accum >= 1.0:
        _reset_time_accum = 0.0
        _update_reset_time_label()


func _update_tab_buttons() -> void:
    var daily_btn := get_node_or_null("UI/MissionPanel/PanelContent/VBox/Tabs/DailyButton") as BaseButton
    var mission_btn := get_node_or_null("UI/MissionPanel/PanelContent/VBox/Tabs/MissionButton") as BaseButton
    var weekly_btn := get_node_or_null("UI/MissionPanel/PanelContent/VBox/Tabs/WeeklyButton") as BaseButton
    var monthly_btn := get_node_or_null("UI/MissionPanel/PanelContent/VBox/Tabs/MonthlyButton") as BaseButton
    var challenge_btn := get_node_or_null("UI/MissionPanel/PanelContent/VBox/Tabs/ChallengeButton") as BaseButton

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
    var cfg := ConfigFile.new()
    var err := cfg.load("user://save.cfg")
    if err != OK:
        if _missions_manager and _missions_manager.has_method("reload_from_save"):
            _missions_manager.call("reload_from_save")
            err = cfg.load("user://save.cfg")
        if err != OK:
            cfg = ConfigFile.new()
            cfg.save("user://save.cfg")
            cfg.load("user://save.cfg")
    var missions_value = cfg.get_value("missions", "list", [])
    var missions: Array = []
    if missions_value is Array:
        missions = missions_value

    # Fix: Force update mission names for localization if they are still hardcoded Indonesian
    var needs_save_fix := false
    for m_idx in range(missions.size()):
        var m_dict = missions[m_idx] as Dictionary
        if m_dict:
            var current_name: String = m_dict.get("name", "")
            var new_name := current_name
            var kind: String = String(m_dict.get("kind", ""))

            # Mapping Indonesian hardcoded names to placeholders
            if current_name.begins_with("Kumpulkan") and current_name.ends_with("koin"):
                new_name = "Kumpulkan {n} koin"
            elif current_name.begins_with("Dapatkan") and current_name.ends_with("skill"):
                new_name = "Dapatkan {n} skill"
            elif current_name.begins_with("Lompat") and current_name.ends_with("kali"):
                new_name = "Lompat {n} kali"
            elif current_name.begins_with("Kalahkan") and current_name.ends_with("musuh"):
                new_name = "Kalahkan {n} musuh"
            elif current_name.begins_with("Capai jarak") and current_name.ends_with("m"):
                new_name = "Capai jarak {n}m"
            elif current_name.begins_with("Mainkan") and current_name.ends_with("run"):
                new_name = "Mainkan {n} run"
            elif current_name.begins_with("Dapatkan Shield"):
                new_name = "Dapatkan Shield {n} kali"
            elif current_name.begins_with("Dapatkan DoubleCoins"):
                new_name = "Dapatkan DoubleCoins {n} kali"

            # Fallback based on kind if name is still Indonesian-like or empty
            if new_name == current_name:
                match kind:
                    "coins": new_name = "Kumpulkan {n} koin"
                    "skills": new_name = "Dapatkan {n} skill"
                    "jumps": new_name = "Lompat {n} kali"
                    "enemies": new_name = "Kalahkan {n} musuh"
                    "distance": new_name = "Capai jarak {n}m"
                    "runs": new_name = "Mainkan {n} run"
                    "shield": new_name = "Dapatkan Shield {n} kali"
                    "double_coins": new_name = "Dapatkan DoubleCoins {n} kali"

            if new_name != current_name:
                m_dict["name"] = new_name
                needs_save_fix = true

    if needs_save_fix:
        cfg.set_value("missions", "list", missions)
        cfg.save("user://save.cfg")
    var claimed_value = cfg.get_value("missions", "reward_claimed", {})
    var claimed: Dictionary = {}
    if claimed_value is Dictionary:
        claimed = claimed_value

    var reset_changed := _apply_mission_resets_if_needed(cfg, missions, claimed)
    var challenge_changed := _ensure_challenge_kill_missions(cfg, missions, claimed)
    var updated := _ensure_missions_defaults(missions)
    if reset_changed or updated or challenge_changed:
        cfg.set_value("missions", "list", missions)
        cfg.set_value("missions", "reward_claimed", claimed)
        cfg.save("user://save.cfg")

    _update_daily_summary(cfg, missions)
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
    for i in range(rows.size()):
        var slot := rows[i] as Control
        if slot == null:
            continue
        if i >= filtered.size():
            slot.visible = false
            continue

        slot.visible = true
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
        var is_claimed := false
        if not id_str.is_empty() and claimed.has(id_str):
            is_claimed = bool(claimed[id_str])

        if name_label:
            name_label.visible = true
            name_label.add_theme_color_override("font_color", Color(0, 0, 0))
            name_label.layout_direction = Control.LAYOUT_DIRECTION_LTR
            name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
            name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_WORD_ELLIPSIS

            # Fix localization with target numbers
            var localized_text := tr(mname)
            if localized_text.contains("{n}"):
                localized_text = localized_text.replace("{n}", str(int(target)))
            name_label.text = localized_text

            # Re-apply styling in case translation changes things
            name_label.add_theme_color_override("font_color", Color(0, 0, 0))
        if bar:
            bar.visible = true
            bar.show_percentage = false
            bar.max_value = target
            bar.value = clampf(prog, 0.0, target)
            var default_h: float
            if bar.has_meta("default_min_h"):
                default_h = float(bar.get_meta("default_min_h"))
            else:
                default_h = float(bar.custom_minimum_size.y)
                bar.set_meta("default_min_h", default_h)
            var h := default_h
            if _current_tab == "daily":
                h = minf(h, 10.0)
            bar.custom_minimum_size = Vector2(bar.custom_minimum_size.x, h)
        if reward_label:
            reward_label.visible = true
            reward_label.add_theme_color_override("font_color", Color(0, 0, 0))
            reward_label.text = "+" + str(reward) + "c"
        if claim_button:
            claim_button.visible = true
            claim_button.disabled = not is_completed or is_claimed or reward <= 0 or id_str.is_empty()
            _apply_claim_button_style(claim_button)
            claim_button.set_meta("mission_id", id_str)

    _connect_claim_buttons(panel_vbox)


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


func _apply_reset_bases(cfg: ConfigFile, t: String) -> void:
    if cfg == null:
        return
    var coins_total: int = int(cfg.get_value("missions", "coins_collected", 0))
    var enemies_total: int = int(cfg.get_value("missions", "enemies_killed", 0))
    var jumps_total: int = int(cfg.get_value("missions", "jumps_total", 0))
    var runs_total: int = int(cfg.get_value("missions", "runs_played", 0))
    var skills_total: int = int(cfg.get_value("missions", "skills_collected", 0))
    var dist_now: int = int(cfg.get_value("missions", "current_run_distance", 0))
    match t:
        "daily":
            cfg.set_value("missions", "base_daily_coins", coins_total)
            cfg.set_value("missions", "base_daily_enemies", enemies_total)
            cfg.set_value("missions", "base_daily_jumps", jumps_total)
            cfg.set_value("missions", "base_daily_runs", runs_total)
            cfg.set_value("missions", "base_daily_skills", skills_total)
            cfg.set_value("missions", "base_daily_distance", dist_now)
            cfg.set_value("missions", "daily_max_distance", 0)
        "week":
            cfg.set_value("missions", "base_week_coins", coins_total)
            cfg.set_value("missions", "base_week_enemies", enemies_total)
            cfg.set_value("missions", "base_week_jumps", jumps_total)
            cfg.set_value("missions", "base_week_runs", runs_total)
            cfg.set_value("missions", "base_week_skills", skills_total)
            cfg.set_value("missions", "base_week_distance", dist_now)
            cfg.set_value("missions", "week_max_distance", 0)
        "month":
            cfg.set_value("missions", "base_month_coins", coins_total)
            cfg.set_value("missions", "base_month_enemies", enemies_total)
            cfg.set_value("missions", "base_month_jumps", jumps_total)
            cfg.set_value("missions", "base_month_runs", runs_total)
            cfg.set_value("missions", "base_month_skills", skills_total)
            cfg.set_value("missions", "base_month_distance", dist_now)
            cfg.set_value("missions", "month_max_distance", 0)
        _:
            pass


func _reset_missions_of_type(t: String, missions: Array, claimed: Dictionary) -> void:
    var ids_to_clear: Array = []
    for m in missions:
        if not (m is Dictionary):
            continue
        var mt: String = String(m.get("type", ("daily" if t == "daily" else "")))
        if mt == t:
            m["progress"] = 0
            var mid: String = String(m.get("id", ""))
            if not mid.is_empty():
                ids_to_clear.append(mid)
    for mid in ids_to_clear:
        if claimed.has(mid):
            claimed.erase(mid)


func _apply_mission_resets_if_needed(cfg: ConfigFile, missions: Array, claimed: Dictionary) -> bool:
    var now: int = int(Time.get_unix_time_from_system())
    var changed := false
    var last_daily: int = int(cfg.get_value("missions", "last_reset_daily", 0))
    var last_week: int = int(cfg.get_value("missions", "last_reset_week", 0))
    var last_month: int = int(cfg.get_value("missions", "last_reset_month", 0))
    var daily_interval := _get_reset_interval_sec("daily")
    var week_interval := _get_reset_interval_sec("week")
    var month_interval := _get_reset_interval_sec("month")
    if daily_interval > 0:
        if last_daily <= 0:
            last_daily = now
            cfg.set_value("missions", "last_reset_daily", last_daily)
            _reset_missions_of_type("daily", missions, claimed)
            cfg.set_value("missions", "daily_all_reward_claimed", false)
            _apply_reset_bases(cfg, "daily")
            changed = true
        elif now - last_daily >= daily_interval:
            _reset_missions_of_type("daily", missions, claimed)
            last_daily = now
            cfg.set_value("missions", "last_reset_daily", last_daily)
            cfg.set_value("missions", "daily_all_reward_claimed", false)
            _apply_reset_bases(cfg, "daily")
            changed = true
    if week_interval > 0:
        if last_week <= 0:
            last_week = now
            cfg.set_value("missions", "last_reset_week", last_week)
            _reset_missions_of_type("week", missions, claimed)
            _apply_reset_bases(cfg, "week")
            changed = true
        elif now - last_week >= week_interval:
            _reset_missions_of_type("week", missions, claimed)
            last_week = now
            cfg.set_value("missions", "last_reset_week", last_week)
            _apply_reset_bases(cfg, "week")
            changed = true
    if month_interval > 0:
        if last_month <= 0:
            last_month = now
            cfg.set_value("missions", "last_reset_month", last_month)
            _reset_missions_of_type("month", missions, claimed)
            _apply_reset_bases(cfg, "month")
            changed = true
        elif now - last_month >= month_interval:
            _reset_missions_of_type("month", missions, claimed)
            last_month = now
            cfg.set_value("missions", "last_reset_month", last_month)
            _apply_reset_bases(cfg, "month")
            changed = true
    return changed


func _get_remaining_reset_seconds(t: String) -> int:
    var cfg := ConfigFile.new()
    var err := cfg.load("user://save.cfg")
    if err != OK:
        return 0
    var interval := _get_reset_interval_sec(t)
    if interval <= 0:
        return 0
    var key := ""
    match t:
        "daily":
            key = "last_reset_daily"
        "week":
            key = "last_reset_week"
        "month":
            key = "last_reset_month"
        _:
            return 0
    var last: int = int(cfg.get_value("missions", key, 0))
    var now: int = int(Time.get_unix_time_from_system())
    if last <= 0:
        last = now
        cfg.set_value("missions", key, last)
        var missions_value = cfg.get_value("missions", "list", [])
        if missions_value is Array:
            var missions: Array = missions_value
            var claimed_value = cfg.get_value("missions", "reward_claimed", {})
            var claimed: Dictionary = {}
            if claimed_value is Dictionary:
                claimed = claimed_value
            _reset_missions_of_type(t, missions, claimed)
            cfg.set_value("missions", "list", missions)
            cfg.set_value("missions", "reward_claimed", claimed)
        if t == "daily":
            cfg.set_value("missions", "daily_all_reward_claimed", false)
        _apply_reset_bases(cfg, t)
        cfg.save("user://save.cfg")
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
        _reset_label = get_node_or_null("UI/MissionPanel/PanelContent/VBox/ResetHeaderRow/ResetTimeLabel") as Label
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
        var panel := get_node_or_null("UI/MissionPanel/PanelContent/VBox/MissionListContainer/MissionsScroll/MissionsPanel")
        if panel:
            _refresh_missions_panel(panel)
        return
    var hours: int = int(remaining / 3600.0)
    var minutes: int = int((remaining % 3600) / 60.0)
    var seconds: int = remaining % 60
    var time_str := "%02d:%02d:%02d" % [hours, minutes, seconds]
    _reset_label.text = tr("%s in %s") % [prefix, time_str]
    _update_reset_header_layout()


func _ensure_missions_defaults(missions: Array) -> bool:
    var ids := {}
    var changed := false
    for m in missions:
        if not (m is Dictionary):
            continue
        var id_str := String(m.get("id", ""))
        if not id_str.is_empty():
            ids[id_str] = true
        if not m.has("type"):
            m["type"] = "daily"
            changed = true
        if not m.has("reward"):
            m["reward"] = 0
            changed = true
        var mt: String = String(m.get("type", "daily"))
        if mt != "challenge":
            var kind: String = String(m.get("kind", ""))
            if kind.is_empty():
                var mname: String = String(m.get("name", ""))
                if mname.begins_with("Kumpulkan"):
                    m["kind"] = "coins"
                    changed = true
                elif mname.begins_with("Capai jarak"):
                    m["kind"] = "distance"
                    changed = true
                elif mname.begins_with("Kalahkan"):
                    m["kind"] = "enemies"
                    changed = true
                elif mname.begins_with("Lompat"):
                    m["kind"] = "jumps"
                    changed = true
                elif mname.begins_with("Mainkan"):
                    m["kind"] = "runs"
                    changed = true
                elif mname.begins_with("Dapatkan"):
                    m["kind"] = "skills"
                    changed = true
    if not ids.has("m4"):
        missions.append({"id": "m4", "name": "Kalahkan {n} musuh", "target": 5, "progress": 0, "type": "daily", "reward": 40, "kind": "enemies"})
        changed = true
    if not ids.has("m5"):
        missions.append({"id": "m5", "name": "Capai jarak {n}m", "target": 1000, "progress": 0, "type": "daily", "reward": 45, "kind": "distance"})
        changed = true
    if not ids.has("m1"):
        missions.append({"id": "m1", "name": "Kumpulkan {n} koin", "target": 50, "progress": 0, "type": "daily", "reward": 25, "kind": "coins"})
        changed = true
    if not ids.has("m2"):
        missions.append({"id": "m2", "name": "Dapatkan {n} skill", "target": 1, "progress": 0, "type": "daily", "reward": 30, "kind": "skills"})
        changed = true
    if not ids.has("m3"):
        missions.append({"id": "m3", "name": "Lompat {n} kali", "target": 50, "progress": 0, "type": "daily", "reward": 35, "kind": "jumps"})
        changed = true
    if not ids.has("ms1"):
        missions.append({"id": "ms1", "name": "Kumpulkan {n} koin", "target": 200, "progress": 0, "type": "mission", "reward": 70, "kind": "coins"})
        changed = true
    if not ids.has("ms2"):
        missions.append({"id": "ms2", "name": "Dapatkan {n} skill", "target": 3, "progress": 0, "type": "mission", "reward": 90, "kind": "skills"})
        changed = true
    if not ids.has("ms3"):
        missions.append({"id": "ms3", "name": "Lompat {n} kali", "target": 200, "progress": 0, "type": "mission", "reward": 120, "kind": "jumps"})
        changed = true
    if not ids.has("ms4"):
        missions.append({"id": "ms4", "name": "Kalahkan {n} musuh", "target": 20, "progress": 0, "type": "mission", "reward": 140, "kind": "enemies"})
        changed = true
    if not ids.has("w1"):
        missions.append({"id": "w1", "name": "Kumpulkan {n} koin", "target": 1000, "progress": 0, "type": "week", "reward": 150, "kind": "coins"})
        changed = true
    if not ids.has("w2"):
        missions.append({"id": "w2", "name": "Dapatkan {n} skill", "target": 10, "progress": 0, "type": "week", "reward": 200, "kind": "skills"})
        changed = true
    if not ids.has("w3"):
        missions.append({"id": "w3", "name": "Mainkan {n} run", "target": 20, "progress": 0, "type": "week", "reward": 260, "kind": "runs"})
        changed = true
    if not ids.has("w4"):
        missions.append({"id": "w4", "name": "Kalahkan {n} musuh", "target": 60, "progress": 0, "type": "week", "reward": 300, "kind": "enemies"})
        changed = true
    if not ids.has("mo1"):
        missions.append({"id": "mo1", "name": "Kumpulkan {n} koin", "target": 5000, "progress": 0, "type": "month", "reward": 350, "kind": "coins"})
        changed = true
    if not ids.has("mo2"):
        missions.append({"id": "mo2", "name": "Capai jarak {n}m", "target": 20000, "progress": 0, "type": "month", "reward": 450, "kind": "distance"})
        changed = true
    if not ids.has("mo3"):
        missions.append({"id": "mo3", "name": "Kalahkan {n} musuh", "target": 150, "progress": 0, "type": "month", "reward": 550, "kind": "enemies"})
        changed = true
    return changed


func _challenge_kill_target_for_abs_level(abs_level: int) -> int:
    var tiers: Array[int] = [1, 5, 10, 20, 30, 50, 75, 100, 150, 200]
    if abs_level < 1:
        abs_level = 1
    if abs_level <= tiers.size():
        return tiers[abs_level - 1]
    return tiers[tiers.size() - 1] + (abs_level - tiers.size()) * 50


func _challenge_kill_reward_for_abs_level(abs_level: int) -> int:
    var tiers: Array[int] = [200, 250, 300, 400, 500, 650, 800, 950, 1100, 1300]
    if abs_level < 1:
        abs_level = 1
    if abs_level <= tiers.size():
        return tiers[abs_level - 1]
    return tiers[tiers.size() - 1] + (abs_level - tiers.size()) * 150


func _challenge_coins_target_for_abs_level(abs_level: int) -> int:
    var tiers: Array[int] = [100, 250, 500, 1000, 2000, 3000, 5000, 7500, 10000, 15000]
    if abs_level < 1:
        abs_level = 1
    if abs_level <= tiers.size():
        return tiers[abs_level - 1]
    return tiers[tiers.size() - 1] + (abs_level - tiers.size()) * 2500


func _challenge_distance_target_for_abs_level(abs_level: int) -> int:
    var tiers: Array[int] = [500, 1000, 2000, 3000, 5000, 7500, 10000, 15000, 20000, 30000]
    if abs_level < 1:
        abs_level = 1
    if abs_level <= tiers.size():
        return tiers[abs_level - 1]
    return tiers[tiers.size() - 1] + (abs_level - tiers.size()) * 5000


func _challenge_powerup_target_for_abs_level(abs_level: int) -> int:
    var tiers: Array[int] = [1, 2, 3, 5, 7, 10, 15, 20, 25, 30]
    if abs_level < 1:
        abs_level = 1
    if abs_level <= tiers.size():
        return tiers[abs_level - 1]
    return tiers[tiers.size() - 1] + (abs_level - tiers.size()) * 5


func _challenge_generic_reward_for_abs_level(abs_level: int) -> int:
    var tiers: Array[int] = [200, 250, 300, 400, 500, 650, 800, 950, 1100, 1300]
    if abs_level < 1:
        abs_level = 1
    if abs_level <= tiers.size():
        return tiers[abs_level - 1]
    return tiers[tiers.size() - 1] + (abs_level - tiers.size()) * 150


func _ensure_challenge_kill_missions(cfg: ConfigFile, missions: Array, claimed: Dictionary) -> bool:
    var old_size := missions.size()
    var removed_any := false
    for i in range(missions.size() - 1, -1, -1):
        var m_any = missions[i]
        if not (m_any is Dictionary):
            continue
        var m: Dictionary = m_any
        if String(m.get("type", "")) == "challenge":
            missions.remove_at(i)
            removed_any = true

    var level := int(cfg.get_value("missions", "challenge_kill_level", 1))
    if level < 1:
        level = 1
    var base_enemies := int(cfg.get_value("missions", "challenge_base_enemies", 0))
    if base_enemies < 0:
        base_enemies = 0
    var enemies_killed := int(cfg.get_value("missions", "enemies_killed", 0))
    if base_enemies > enemies_killed:
        base_enemies = enemies_killed

    var coins_level := int(cfg.get_value("missions", "challenge_coins_level", 1))
    if coins_level < 1:
        coins_level = 1
    var base_coins := int(cfg.get_value("missions", "challenge_base_coins", 0))
    if base_coins < 0:
        base_coins = 0
    var coins_collected := int(cfg.get_value("missions", "coins_collected", 0))
    if base_coins > coins_collected:
        base_coins = coins_collected

    var dist_level := int(cfg.get_value("missions", "challenge_distance_level", 1))
    if dist_level < 1:
        dist_level = 1
    var base_dist := int(cfg.get_value("missions", "challenge_base_distance", 0))
    if base_dist < 0:
        base_dist = 0
    var max_distance := int(cfg.get_value("missions", "max_distance", 0))
    if base_dist > max_distance:
        base_dist = max_distance

    var shield_level := int(cfg.get_value("missions", "challenge_shield_level", 1))
    if shield_level < 1:
        shield_level = 1
    var base_shield := int(cfg.get_value("missions", "challenge_base_shield", 0))
    if base_shield < 0:
        base_shield = 0
    var shield_skills_collected := int(cfg.get_value("missions", "shield_skills_collected", 0))
    if base_shield > shield_skills_collected:
        base_shield = shield_skills_collected

    var dc_level := int(cfg.get_value("missions", "challenge_double_coins_level", 1))
    if dc_level < 1:
        dc_level = 1
    var base_dc := int(cfg.get_value("missions", "challenge_base_double_coins", 0))
    if base_dc < 0:
        base_dc = 0
    var double_coins_skills_collected := int(cfg.get_value("missions", "double_coins_skills_collected", 0))
    if base_dc > double_coins_skills_collected:
        base_dc = double_coins_skills_collected

    if claimed.has("ck"):
        claimed.erase("ck")
    if claimed.has("cc"):
        claimed.erase("cc")
    if claimed.has("cd"):
        claimed.erase("cd")
    if claimed.has("csh"):
        claimed.erase("csh")
    if claimed.has("cdc"):
        claimed.erase("cdc")
    for k in range(1, 11):
        var key := "ck" + str(k)
        if claimed.has(key):
            claimed.erase(key)
    if claimed.has("c1"):
        claimed.erase("c1")
    if claimed.has("c2"):
        claimed.erase("c2")
    if claimed.has("c3"):
        claimed.erase("c3")

    var target := _challenge_kill_target_for_abs_level(level)
    var reward := _challenge_kill_reward_for_abs_level(level)
    var progress := maxi(enemies_killed - base_enemies, 0)
    missions.append({
        "id": "ck",
        "name": "Kalahkan {n} musuh",
        "target": target,
        "progress": progress,
        "type": "challenge",
        "reward": reward,
        "kind": "enemies"
    })

    var shield_target := _challenge_powerup_target_for_abs_level(shield_level)
    missions.append({
        "id": "csh",
        "name": "Dapatkan Shield {n} kali",
        "target": shield_target,
        "progress": maxi(shield_skills_collected - base_shield, 0),
        "type": "challenge",
        "reward": _challenge_generic_reward_for_abs_level(shield_level),
        "kind": "shield"
    })

    var dc_target := _challenge_powerup_target_for_abs_level(dc_level)
    missions.append({
        "id": "cdc",
        "name": "Dapatkan DoubleCoins {n} kali",
        "target": dc_target,
        "progress": maxi(double_coins_skills_collected - base_dc, 0),
        "type": "challenge",
        "reward": _challenge_generic_reward_for_abs_level(dc_level),
        "kind": "double_coins"
    })

    var coins_target := _challenge_coins_target_for_abs_level(coins_level)
    missions.append({
        "id": "cc",
        "name": "Kumpulkan {n} koin",
        "target": coins_target,
        "progress": maxi(coins_collected - base_coins, 0),
        "type": "challenge",
        "reward": _challenge_generic_reward_for_abs_level(coins_level),
        "kind": "coins"
    })

    var dist_target := _challenge_distance_target_for_abs_level(dist_level)
    missions.append({
        "id": "cd",
        "name": "Capai jarak {n}m",
        "target": dist_target,
        "progress": maxi(max_distance - base_dist, 0),
        "type": "challenge",
        "reward": _challenge_generic_reward_for_abs_level(dist_level),
        "kind": "distance"
    })

    cfg.set_value("missions", "challenge_kill_level", level)
    cfg.set_value("missions", "challenge_base_enemies", base_enemies)
    cfg.set_value("missions", "challenge_coins_level", coins_level)
    cfg.set_value("missions", "challenge_base_coins", base_coins)
    cfg.set_value("missions", "challenge_distance_level", dist_level)
    cfg.set_value("missions", "challenge_base_distance", base_dist)
    cfg.set_value("missions", "challenge_shield_level", shield_level)
    cfg.set_value("missions", "challenge_base_shield", base_shield)
    cfg.set_value("missions", "challenge_double_coins_level", dc_level)
    cfg.set_value("missions", "challenge_base_double_coins", base_dc)
    return removed_any or missions.size() != old_size


func _connect_claim_buttons(panel: Node) -> void:
    var rows := _get_mission_rows(panel)
    for slot in rows:
        var claim_button := slot.get_node_or_null("ClaimButton") as BaseButton
        if claim_button == null:
            continue
        var cb := Callable(self, "_on_claim_button_pressed").bind(claim_button)
        if not claim_button.pressed.is_connected(cb):
            claim_button.pressed.connect(cb)


func _on_claim_button_pressed(button: BaseButton) -> void:
    if button == null:
        return
    var mission_id := ""
    if button.has_meta("mission_id"):
        mission_id = String(button.get_meta("mission_id"))
    if mission_id.is_empty():
        return
    var cfg := ConfigFile.new()
    var err := cfg.load("user://save.cfg")
    if err != OK:
        return
    var missions_value = cfg.get_value("missions", "list", [])
    if not (missions_value is Array):
        return
    var missions: Array = missions_value
    var target_mission: Dictionary = {}
    var found_index := -1
    for i in range(missions.size()):
        var m = missions[i]
        if not (m is Dictionary):
            continue
        var id_str := String(m.get("id", ""))
        if id_str == mission_id:
            target_mission = m
            found_index = i
            break
    if found_index == -1:
        return
    var target: int = int(target_mission.get("target", 0))
    if target <= 0:
        return
    var prog: int = int(target_mission.get("progress", 0))
    if prog < target:
        return
    var reward: int = int(target_mission.get("reward", 0))
    if reward <= 0:
        return
    var claimed_value = cfg.get_value("missions", "reward_claimed", {})
    var claimed: Dictionary = {}
    if claimed_value is Dictionary:
        claimed = claimed_value
    var mt: String = String(target_mission.get("type", ""))
    if mt != "challenge":
        if claimed.has(mission_id) and bool(claimed[mission_id]):
            return

    button.disabled = true
    _apply_claim_button_style(button)
    var total_coins: int = int(cfg.get_value("progress", "total_coins", 0))
    total_coins += reward
    TransitionManager.play_sfx(&"mission_claim")

    if mt == "challenge":
        match mission_id:
            "ck":
                var enemies_killed := int(cfg.get_value("missions", "enemies_killed", 0))
                var level := int(cfg.get_value("missions", "challenge_kill_level", 1))
                if level < 1:
                    level = 1
                level += 1
                cfg.set_value("missions", "challenge_kill_level", level)
                cfg.set_value("missions", "challenge_base_enemies", enemies_killed)
            "cc":
                var coins_collected := int(cfg.get_value("missions", "coins_collected", 0))
                var level2 := int(cfg.get_value("missions", "challenge_coins_level", 1))
                if level2 < 1:
                    level2 = 1
                level2 += 1
                cfg.set_value("missions", "challenge_coins_level", level2)
                cfg.set_value("missions", "challenge_base_coins", coins_collected)
            "cd":
                var max_distance := int(cfg.get_value("missions", "max_distance", 0))
                var level3 := int(cfg.get_value("missions", "challenge_distance_level", 1))
                if level3 < 1:
                    level3 = 1
                level3 += 1
                cfg.set_value("missions", "challenge_distance_level", level3)
                cfg.set_value("missions", "challenge_base_distance", max_distance)
            "csh":
                var shield_skills_collected := int(cfg.get_value("missions", "shield_skills_collected", 0))
                var level4 := int(cfg.get_value("missions", "challenge_shield_level", 1))
                if level4 < 1:
                    level4 = 1
                level4 += 1
                cfg.set_value("missions", "challenge_shield_level", level4)
                cfg.set_value("missions", "challenge_base_shield", shield_skills_collected)
            "cdc":
                var double_coins_skills_collected := int(cfg.get_value("missions", "double_coins_skills_collected", 0))
                var level5 := int(cfg.get_value("missions", "challenge_double_coins_level", 1))
                if level5 < 1:
                    level5 = 1
                level5 += 1
                cfg.set_value("missions", "challenge_double_coins_level", level5)
                cfg.set_value("missions", "challenge_base_double_coins", double_coins_skills_collected)
            _:
                pass
        _ensure_challenge_kill_missions(cfg, missions, claimed)
    else:
        claimed[mission_id] = true

    cfg.set_value("missions", "list", missions)
    cfg.set_value("missions", "reward_claimed", claimed)
    cfg.set_value("progress", "total_coins", total_coins)
    cfg.save("user://save.cfg")

    if _missions_manager and _missions_manager.has_method("reload_from_save"):
        _missions_manager.call("reload_from_save")

    var root_scene := get_tree().current_scene
    var coin_target := root_scene.get_node_or_null("UI/CoinHUD/CoinIcon") as Control if root_scene else null
    var coin_count: int = _coin_fx_rng.randi_range(5, 10)
    _play_claim_coin_fly(button as Control, coin_target, coin_count)

    var panel := get_node_or_null("UI/MissionPanel/PanelContent/VBox/MissionListContainer/MissionsScroll/MissionsPanel")
    if panel:
        _refresh_missions_panel(panel)
    if root_scene and root_scene.has_method("refresh_coin_from_save"):
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
    var ui_layer := get_node_or_null("UI") as CanvasLayer
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
    var ui_layer := get_node_or_null("UI") as CanvasLayer
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
