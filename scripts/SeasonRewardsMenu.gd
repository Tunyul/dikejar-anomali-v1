extends CanvasLayer
const _BANNER_LOCK_ID := "season_rewards_overlay"
const _CARD_SCALE := Vector2(0.8, 0.8)
const _CARD_VERTICAL_OFFSET := 15.0
const _LOADING_HIDE_DELAY_MS := 140
const _LOADING_SPINNER_SPEED := 240.0
const _LOADING_ICON = preload("res://assets/coin_animation/png/2x/Coin.png")

@onready var _overlay: ColorRect = %Overlay
@onready var _inner_panel: PanelContainer = %Panel
@onready var _reward_list: Control = %RewardList
@onready var _claim_all_button: Button = %ClaimAllButton
@onready var _close_button: Button = %CloseButton
@onready var _season_title: Label = %SeasonTitle
@onready var _time_left_label: Label = %TimeLeftLabel
@onready var _xp_label: Label = %XPLabel
@onready var _level_label: Label = %LevelLabel
@onready var _progress_bar: ProgressBar = %SeasonProgressBar
@onready var _loading_overlay: Control = %LoadingOverlay
@onready var _loading_spinner: TextureRect = %LoadingSpinner
@onready var _loading_label: Label = %LoadingLabel

@onready var _scroll_container: ScrollContainer = find_child("Scroll")

var _reward_item_scene = preload("res://scenes/SeasonRewardItem.tscn")
var _all_items_data: Array = []
var _spawned_items: Dictionary = {} # {lvl: node}
var _item_pool: Array[Control] = []
var _item_width: float = 170.0 # Diperkecil dari 200
var _visible_range_buffer: int = 4 # Ditambah buffer agar scrolling lebih halus dengan item lebih kecil
var _opening_frame: bool = false # Flag untuk mencegah penutupan di frame yang sama saat dibuka
var _banner_lock_active: bool = false
var _visible_refresh_queued: bool = false
var _loading_hold_until_msec: int = 0

# Drag scrolling variables
var _is_dragging: bool = false
var _drag_start_pos: Vector2 = Vector2.ZERO
var _drag_start_scroll: int = 0

func _ready() -> void:
    visible = false # Sembunyikan saat pertama kali muncul
    _close_button.pressed.connect(_on_close_pressed)
    _claim_all_button.pressed.connect(_on_claim_all_pressed)
    _overlay.gui_input.connect(_on_overlay_gui_input)

    if _scroll_container:
        _scroll_container.get_h_scroll_bar().value_changed.connect(_on_scroll_changed)
        # Tambahkan koneksi langsung ke ScrollContainer untuk dragging di mobile/mouse
        _scroll_container.gui_input.connect(_on_scroll_gui_input)
        _scroll_container.resized.connect(_on_scroll_resized)
        _scroll_container.mouse_filter = Control.MOUSE_FILTER_STOP # Handle drag
        _scroll_container.scroll_horizontal_custom_step = 20.0 # Step untuk mouse wheel

        # Tambahkan emulasi drag untuk mouse agar bisa scroll dengan klik-tahan-seret
        _scroll_container.set_meta("drag_scrolling", true)

    _season_title.text = tr("SEASON_REWARDS_TITLE")
    _claim_all_button.text = tr("CLAIM_ALL")
    _close_button.text = "X"

    if _time_left_label:
        _time_left_label.text = tr("TIME_REMAINING_HINT")

    if _reward_list:
        _reward_list.mouse_filter = Control.MOUSE_FILTER_PASS
        _reward_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        _reward_list.custom_minimum_size.y = 310 # Ditambah ruang vertikal agar tidak terpotong
        # Tambahkan koneksi gui_input ke _reward_list juga agar drag di area kosong tetap berfungsi
        _reward_list.gui_input.connect(_on_scroll_gui_input)

    if _loading_spinner:
        _loading_spinner.texture = _LOADING_ICON
        _loading_spinner.pivot_offset = Vector2(14, 14)
    if _loading_overlay:
        _loading_overlay.visible = false

    _refresh_list(false)

func _process(delta: float) -> void:
    if _loading_overlay and _loading_overlay.visible and _loading_spinner:
        _loading_spinner.rotation_degrees = wrapf(
            _loading_spinner.rotation_degrees + (delta * _LOADING_SPINNER_SPEED),
            0.0,
            360.0
        )
    if _loading_overlay and _loading_overlay.visible:
        var should_hide := (not _is_dragging) and (not _visible_refresh_queued) and Time.get_ticks_msec() >= _loading_hold_until_msec
        if should_hide:
            _loading_overlay.visible = false

func _exit_tree() -> void:
    _release_banner_lock()

func show_menu() -> void:
    _acquire_banner_lock()
    _show_loading_indicator("%s..." % tr("Loading"))
    _refresh_list(false)
    _opening_frame = true

    # Update texts with tr()
    _season_title.text = tr("SEASON_REWARDS_TITLE")
    _claim_all_button.text = tr("CLAIM_ALL")
    if _time_left_label:
        _time_left_label.text = tr("TIME_REMAINING_HINT")
    visible = true
    # Pastikan CanvasLayer muncul di depan
    process_mode = Node.PROCESS_MODE_ALWAYS

    # Simple animation
    _inner_panel.modulate.a = 0
    _inner_panel.scale = Vector2(0.9, 0.9)
    _overlay.modulate.a = 0

    var tw = create_tween().set_parallel(true)
    tw.tween_property(_overlay, "modulate:a", 1.0, 0.2)
    tw.tween_property(_inner_panel, "modulate:a", 1.0, 0.2)
    tw.tween_property(_inner_panel, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)

    # Tunggu 1 frame agar layout selesai dan flag _opening_frame mati
    await get_tree().process_frame
    _opening_frame = false

    _scroll_to_current_level()
    _request_visible_items_refresh()
    _hold_loading_indicator()

func _on_close_pressed() -> void:
    TransitionManager.play_sfx(&"click")
    _hide_menu()

func _hide_menu() -> void:
    if not visible:
        _release_banner_lock()
        return
    var tw = create_tween().set_parallel(true)
    tw.tween_property(_overlay, "modulate:a", 0.0, 0.2)
    tw.tween_property(_inner_panel, "modulate:a", 0.0, 0.2)
    tw.tween_property(_inner_panel, "scale", Vector2(0.9, 0.9), 0.2)
    await tw.finished
    visible = false
    _release_banner_lock()

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

func _on_overlay_gui_input(event: InputEvent) -> void:
    if _opening_frame: return
    if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch and event.pressed):
        _on_close_pressed()

func _refresh_list(spawn_visible_items: bool = true) -> void:
    # Simpan data hadiah ke array agar tidak spawn node sekaligus
    _all_items_data.clear()
    _recycle_all_spawned_items()

    var current_level = 1
    var current_xp = 0
    var xp_required = 100
    if GameManager:
        current_level = int(GameManager.player_level)
        current_xp = int(GameManager.player_xp)
        xp_required = int(GameManager.player_xp_required)

    if _level_label:
        _level_label.text = "LVL %d" % current_level
    if _xp_label:
        _xp_label.text = "PROGRESS: %d/%d XP" % [current_xp, xp_required]
    if _progress_bar:
        _progress_bar.max_value = xp_required
        _progress_bar.value = current_xp

    if not GameManager: return

    var pending_rewards = []
    if GameManager:
        pending_rewards = GameManager.pending_level_rewards
    var pending_lookup: Dictionary = {}
    for pending_entry in pending_rewards:
        if pending_entry is Dictionary:
            pending_lookup[int(pending_entry.get("level", -1))] = true

    # Siapkan data untuk 1000 level
    for lvl in range(1, 1001):
        var reward = GameManager.get_season_reward_for_level(lvl)
        if reward.is_empty(): continue

        var is_unlocked = lvl <= current_level
        var is_pending = pending_lookup.has(lvl)
        var is_claimed = is_unlocked and not is_pending

        _all_items_data.append({
            "lvl": lvl,
            "reward": reward,
            "is_unlocked": is_unlocked,
            "is_claimed": is_claimed
        })

    # Set custom minimum width untuk HBox agar scrollbar berfungsi dengan Lazy Loading
    # Total lebar = jumlah item * (lebar item + separation)
    var total_width = _all_items_data.size() * _item_width
    _reward_list.custom_minimum_size.x = total_width

    _claim_all_button.disabled = pending_lookup.is_empty()

    if spawn_visible_items:
        _request_visible_items_refresh()

func _on_scroll_changed(_value: float) -> void:
    if _is_dragging:
        _show_loading_indicator("%s..." % tr("Loading"))
    _request_visible_items_refresh()

func _on_scroll_resized() -> void:
    if visible:
        _request_visible_items_refresh()

func _on_scroll_gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed:
                _is_dragging = true
                _drag_start_pos = event.global_position
                _drag_start_scroll = _scroll_container.scroll_horizontal
                _show_loading_indicator("%s..." % tr("Loading"))
            else:
                _is_dragging = false
                _hold_loading_indicator()

    elif event is InputEventMouseMotion:
        if _is_dragging:
            var diff = event.global_position.x - _drag_start_pos.x
            _scroll_container.scroll_horizontal = _drag_start_scroll - int(diff)
            # _update_visible_items() akan dipanggil oleh signal value_changed dari scrollbar

    elif event is InputEventScreenTouch:
        if event.pressed:
            _is_dragging = true
            _drag_start_pos = event.position
            _drag_start_scroll = _scroll_container.scroll_horizontal
            _show_loading_indicator("%s..." % tr("Loading"))
        else:
            _is_dragging = false
            _hold_loading_indicator()

    elif event is InputEventScreenDrag:
        if _is_dragging:
            var diff = event.position.x - _drag_start_pos.x
            _scroll_container.scroll_horizontal = _drag_start_scroll - int(diff)
            _show_loading_indicator("%s..." % tr("Loading"))

func _update_visible_items() -> void:
    _request_visible_items_refresh()

func _request_visible_items_refresh() -> void:
    if not _scroll_container:
        return
    if _visible_refresh_queued:
        return
    _visible_refresh_queued = true
    call_deferred("_flush_visible_items")

func _flush_visible_items() -> void:
    _visible_refresh_queued = false
    if not _scroll_container or _all_items_data.is_empty():
        _hold_loading_indicator()
        return

    var scroll_x = _scroll_container.scroll_horizontal
    var viewport_width = maxf(_scroll_container.size.x, _item_width)

    # Tentukan indeks item yang terlihat berdasarkan posisi scroll
    var start_idx = max(0, int(scroll_x / _item_width) - _visible_range_buffer)
    var end_idx = min(_all_items_data.size() - 1, int((scroll_x + viewport_width) / _item_width) + _visible_range_buffer)

    var visible_lvls: Dictionary = {}
    for i in range(start_idx, end_idx + 1):
        visible_lvls[int(_all_items_data[i].get("lvl", 0))] = true

    # Hapus item yang sudah tidak terlihat
    var lvls_to_remove = []
    for lvl in _spawned_items.keys():
        if not visible_lvls.has(lvl):
            lvls_to_remove.append(lvl)

    for lvl in lvls_to_remove:
        var item: Control = _spawned_items[lvl]
        _recycle_item_node(item)
        _spawned_items.erase(lvl)

    # Spawn item baru yang terlihat
    for i in range(start_idx, end_idx + 1):
        var data: Dictionary = _all_items_data[i]
        var lvl := int(data.get("lvl", 0))
        var item: Control = _spawned_items.get(lvl, null)
        if item == null or not is_instance_valid(item):
            item = _take_reward_item_from_pool()
            if item == null:
                continue
            _spawned_items[lvl] = item
        _apply_reward_item_state(item, i, data)

    _hold_loading_indicator()

func _recycle_all_spawned_items() -> void:
    for item in _spawned_items.values():
        _recycle_item_node(item)
    _spawned_items.clear()

func _recycle_item_node(item: Control) -> void:
    if item == null or not is_instance_valid(item):
        return
    item.visible = false
    if item.get_parent() == _reward_list:
        _reward_list.remove_child(item)
    item.position = Vector2.ZERO
    item.rotation_degrees = 0.0
    item.modulate = Color.WHITE
    _item_pool.append(item)

func _take_reward_item_from_pool() -> Control:
    while not _item_pool.is_empty():
        var pooled_item: Control = _item_pool.pop_back()
        if is_instance_valid(pooled_item):
            return pooled_item

    var new_item_node = _reward_item_scene.instantiate()
    var new_item := new_item_node as Control
    if new_item == null:
        return null
    if new_item_node.has_signal("claim_requested") and not bool(new_item_node.get_meta("_claim_requested_connected", false)):
        new_item_node.connect("claim_requested", Callable(self, "_on_item_claim_requested"))
        new_item_node.set_meta("_claim_requested_connected", true)
    return new_item

func _apply_reward_item_state(item: Control, index: int, data: Dictionary) -> void:
    if item.get_parent() != _reward_list:
        _reward_list.add_child(item)
    item.visible = true
    item.scale = _CARD_SCALE
    item.position = Vector2(index * _item_width, _CARD_VERTICAL_OFFSET)
    if item.has_method("setup"):
        item.call(
            "setup",
            int(data.get("lvl", 0)),
            data.get("reward", {}),
            bool(data.get("is_unlocked", false)),
            bool(data.get("is_claimed", false))
        )

func _get_reward_index_for_level(level: int) -> int:
    if _all_items_data.is_empty():
        return 0
    for i in range(_all_items_data.size()):
        if int(_all_items_data[i].get("lvl", 0)) >= level:
            return i
    return _all_items_data.size() - 1

func _scroll_to_current_level() -> void:
    if not _scroll_container or _all_items_data.is_empty():
        return
    var current_level := 1
    if GameManager:
        current_level = maxi(1, int(GameManager.player_level))
    var target_index := _get_reward_index_for_level(current_level)
    var viewport_width := maxf(_scroll_container.size.x, _item_width)
    var centered_scroll := int((target_index * _item_width) - ((viewport_width - _item_width) * 0.5))
    var max_scroll := maxi(0, int(_reward_list.custom_minimum_size.x - viewport_width))
    _scroll_container.scroll_horizontal = clampi(centered_scroll, 0, max_scroll)

func _show_loading_indicator(message: String) -> void:
    if _loading_overlay == null:
        return
    _loading_overlay.visible = true
    _loading_hold_until_msec = Time.get_ticks_msec() + _LOADING_HIDE_DELAY_MS
    if _loading_label:
        _loading_label.text = message

func _hold_loading_indicator(delay_ms: int = _LOADING_HIDE_DELAY_MS) -> void:
    _loading_hold_until_msec = Time.get_ticks_msec() + delay_ms

func _on_item_claim_requested(lvl: int) -> void:
    if GameManager and GameManager.has_method("claim_season_reward"):
        var result: Dictionary = GameManager.claim_season_reward(lvl)
        if bool(result.get("ok", false)):
            _refresh_list()
            # Update MainMenu HUD
            var main_menu = get_tree().root.find_child("MainMenu", true, false)
            if main_menu:
                if main_menu.has_method("_refresh_currency_display"):
                    main_menu._refresh_currency_display()
                elif main_menu.has_method("_update_reward_icon"):
                    main_menu._update_reward_icon()

func _is_reward_already_claimed(lvl: int) -> bool:
    if GameManager == null:
        return false
    var pending = GameManager.pending_level_rewards
    for p in pending:
        if p is Dictionary and int(p.get("level", -1)) == lvl:
            return false
    var current_level = int(GameManager.player_level)
    return lvl < current_level

func _on_claim_all_pressed() -> void:
    TransitionManager.play_sfx(&"click")
    if GameManager and GameManager.has_method("claim_all_pending_rewards"):
        var result: Dictionary = GameManager.claim_all_pending_rewards()
        var totals: Dictionary = result.get("reward_or_totals", {})
        if bool(result.get("ok", false)) and int(totals.get("count", 0)) > 0:
            _refresh_list()
            var main_menu = get_tree().root.find_child("MainMenu", true, false)
            if main_menu:
                if main_menu.has_method("_refresh_currency_display"):
                    main_menu._refresh_currency_display()
                elif main_menu.has_method("_update_reward_icon"):
                    main_menu._update_reward_icon()
