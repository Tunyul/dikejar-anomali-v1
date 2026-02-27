extends CanvasLayer

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

@onready var _scroll_container: ScrollContainer = find_child("Scroll")

var _reward_item_scene = preload("res://scenes/SeasonRewardItem.tscn")
var _all_items_data: Array = []
var _spawned_items: Dictionary = {} # {lvl: node}
var _item_width: float = 170.0 # Diperkecil dari 200
var _visible_range_buffer: int = 4 # Ditambah buffer agar scrolling lebih halus dengan item lebih kecil
var _opening_frame: bool = false # Flag untuk mencegah penutupan di frame yang sama saat dibuka

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
    _refresh_list()

func show_menu() -> void:
    _refresh_list()
    _opening_frame = true

    # Update texts with tr()
    _season_title.text = tr("SEASON_REWARDS_TITLE")
    _claim_all_button.text = tr("CLAIM_ALL")
    if _time_left_label:
        _time_left_label.text = tr("TIME_REMAINING_HINT")

    # Debug print to see what tr() returns
    print("Locale: ", TranslationServer.get_locale())
    print("Title tr: ", tr("SEASON_REWARDS_TITLE"))

    print("Menampilkan menu season rewards (UI Updated)...")
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
    print("Animasi menu dimulai.")

    # Tunggu 1 frame agar layout selesai dan flag _opening_frame mati
    await get_tree().process_frame
    _opening_frame = false

    # Update ulang setelah layout selesai agar viewport_width akurat
    _update_visible_items()

func _on_close_pressed() -> void:
    TransitionManager.play_sfx(&"click")
    _hide_menu()

func _hide_menu() -> void:
    var tw = create_tween().set_parallel(true)
    tw.tween_property(_overlay, "modulate:a", 0.0, 0.2)
    tw.tween_property(_inner_panel, "modulate:a", 0.0, 0.2)
    tw.tween_property(_inner_panel, "scale", Vector2(0.9, 0.9), 0.2)
    await tw.finished
    visible = false

func _on_overlay_gui_input(event: InputEvent) -> void:
    if _opening_frame: return
    if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch and event.pressed):
        _on_close_pressed()

func _refresh_list() -> void:
    # Simpan data hadiah ke array agar tidak spawn node sekaligus
    _all_items_data.clear()

    # Hapus item yang sudah di-spawn
    for child in _reward_list.get_children():
        child.queue_free()
    _spawned_items.clear()

    var current_level = 1
    var current_xp = 0
    var xp_required = 100

    var cfg = ConfigFile.new()
    if cfg.load("user://save.cfg") == OK:
        current_level = int(cfg.get_value("progress", "player_level", 1))
        current_xp = int(cfg.get_value("progress", "player_xp", 0))
        xp_required = int(cfg.get_value("progress", "player_xp_required", 100))

    if _level_label:
        _level_label.text = "LVL %d" % current_level
    if _xp_label:
        _xp_label.text = "PROGRESS: %d/%d XP" % [current_xp, xp_required]
    if _progress_bar:
        _progress_bar.max_value = xp_required
        _progress_bar.value = current_xp

    if not GameManager: return

    # Ambil pending rewards
    var pending_rewards = []
    var save_cfg = ConfigFile.new()
    if save_cfg.load("user://save.cfg") == OK:
        pending_rewards = save_cfg.get_value("rewards", "pending_level_rewards", [])

    # Siapkan data untuk 1000 level
    for lvl in range(1, 1001):
        var reward = GameManager.get_season_reward_for_level(lvl)
        if reward.is_empty(): continue

        var is_unlocked = lvl <= current_level
        var is_pending = false
        for p in pending_rewards:
            if p is Dictionary and p.get("level") == lvl:
                is_pending = true
                break
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

    # Panggil update pertama kali
    _update_visible_items()

func _on_scroll_changed(_value: float) -> void:
    _update_visible_items()

func _on_scroll_gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed:
                _is_dragging = true
                _drag_start_pos = event.global_position
                _drag_start_scroll = _scroll_container.scroll_horizontal
            else:
                _is_dragging = false

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
        else:
            _is_dragging = false

    elif event is InputEventScreenDrag:
        if _is_dragging:
            var diff = event.position.x - _drag_start_pos.x
            _scroll_container.scroll_horizontal = _drag_start_scroll - int(diff)

func _update_visible_items() -> void:
    if not _scroll_container or _all_items_data.is_empty(): return

    var scroll_x = _scroll_container.scroll_horizontal
    var viewport_width = _scroll_container.size.x

    # Tentukan indeks item yang terlihat berdasarkan posisi scroll
    var start_idx = max(0, int(scroll_x / _item_width) - _visible_range_buffer)
    var end_idx = min(_all_items_data.size() - 1, int((scroll_x + viewport_width) / _item_width) + _visible_range_buffer)

    var visible_lvls = []
    for i in range(start_idx, end_idx + 1):
        visible_lvls.append(_all_items_data[i].lvl)

    # Hapus item yang sudah tidak terlihat
    var lvls_to_remove = []
    for lvl in _spawned_items.keys():
        if not lvl in visible_lvls:
            lvls_to_remove.append(lvl)

    for lvl in lvls_to_remove:
        var item = _spawned_items[lvl]
        if is_instance_valid(item):
            item.queue_free()
        _spawned_items.erase(lvl)

    # Spawn item baru yang terlihat
    for i in range(start_idx, end_idx + 1):
        var data = _all_items_data[i]
        if not data.lvl in _spawned_items:
            var item = _reward_item_scene.instantiate()
            _reward_list.add_child(item)

            # Posisikan item secara manual di dalam HBox menggunakan dummy/spacer jika perlu,
            # tapi cara termudah adalah menggunakan set_position jika layout_mode memungkinkan,
            # atau biarkan HBox mengaturnya tapi kita harus mengatur urutan child.
            # Namun, karena ini HBox, kita gunakan dummy nodes atau margin di kiri item.

            item.setup(data.lvl, data.reward, data.is_unlocked, data.is_claimed)
            if item.has_signal("claim_requested"):
                item.claim_requested.connect(_on_item_claim_requested)

            # Atur posisi di dalam Control RewardList
            # Horizontal: i * _item_width
            # Vertical: Kartu hadiah diperkecil agar tidak terpotong
            item.scale = Vector2(0.8, 0.8) # Perkecil ukuran card
            item.position = Vector2(i * _item_width, 15)
            _spawned_items[data.lvl] = item

func _on_item_claim_requested(lvl: int) -> void:
    if GameManager and GameManager.has_method("claim_season_reward"):
        var result = GameManager.claim_season_reward(lvl)
        if not result.is_empty():
            _refresh_list()
            # Update MainMenu HUD
            var main_menu = get_tree().root.find_child("MainMenu", true, false)
            if main_menu:
                if main_menu.has_method("_refresh_currency_display"):
                    main_menu._refresh_currency_display()
                elif main_menu.has_method("_update_reward_icon"):
                    main_menu._update_reward_icon()

func _is_reward_already_claimed(lvl: int) -> bool:
    # Logic to check if reward level X is already claimed
    # For now, if it's not in pending_level_rewards but lvl <= current_level, it's claimed
    var cfg = ConfigFile.new()
    if cfg.load("user://save.cfg") != OK: return false

    var pending = cfg.get_value("rewards", "pending_level_rewards", [])
    for p in pending:
        if p.get("level") == lvl:
            return false # It's pending, not claimed yet

    var current_level = int(cfg.get_value("progress", "player_level", 1))
    return lvl < current_level # Simplified logic

func _on_claim_all_pressed() -> void:
    TransitionManager.play_sfx(&"click")
    if GameManager and GameManager.has_method("claim_all_pending_rewards"):
        var result = GameManager.claim_all_pending_rewards()
        if result.get("count", 0) > 0:
            _refresh_list()
            var main_menu = get_tree().root.find_child("MainMenu", true, false)
            if main_menu:
                if main_menu.has_method("_refresh_currency_display"):
                    main_menu._refresh_currency_display()
                elif main_menu.has_method("_update_reward_icon"):
                    main_menu._update_reward_icon()
