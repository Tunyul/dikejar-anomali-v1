extends Control

const SAVE_PATH := "user://save.cfg"

var shop_groups: Array = []
var buy_buttons: Array = []
var current_coins: int = 0

func _ready() -> void:
    var back := get_node_or_null("UI/VBox/BackButton")
    var coins_label := get_node_or_null("UI/VBox/CoinsLabel")
    var status_label := get_node_or_null("UI/VBox/StatusLabel") as Label
    if back:
        back.pressed.connect(_on_back_pressed)
    current_coins = _load_coins()
    if coins_label and coins_label is Label:
        (coins_label as Label).text = "Coins: " + str(current_coins)
    if status_label:
        status_label.text = ""
    var ui_font := load("res://assets/font/Fredoka Nunito/Nunito/static/Nunito-Regular.ttf") as Font
    var title_font := load("res://assets/font/Fredoka Nunito/Fredoka/static/Fredoka-Bold.ttf") as Font
    if ui_font:
        _apply_ui_font(self, ui_font)
    if title_font:
        var title := get_node_or_null("UI/VBox/TitleLabel") as Label
        if title:
            title.add_theme_font_override("font", title_font)
    _init_shop_data()
    _build_groups_ui()
    _update_buy_buttons_state()

    var groups_scroll := get_node_or_null("UI/VBox/GroupsScroll") as ScrollContainer
    if groups_scroll:
        var bg := StyleBoxFlat.new()
        bg.bg_color = Color(0.08, 0.08, 0.08, 1.0)
        bg.border_color = Color(1.0, 1.0, 1.0, 0.12)
        bg.border_width_top = 1
        bg.border_width_bottom = 1
        bg.border_width_left = 1
        bg.border_width_right = 1
        bg.corner_radius_top_left = 8
        bg.corner_radius_top_right = 8
        bg.corner_radius_bottom_left = 8
        bg.corner_radius_bottom_right = 8
        groups_scroll.add_theme_stylebox_override("panel", bg)

func _load_coins() -> int:
    var cfg := ConfigFile.new()
    var err := cfg.load(SAVE_PATH)
    if err != OK:
        return 0
    return int(cfg.get_value("progress", "total_coins", 0))

func _save_coins(value: int) -> void:
    var cfg := ConfigFile.new()
    cfg.load(SAVE_PATH)
    cfg.set_value("progress", "total_coins", value)
    cfg.save(SAVE_PATH)

func _init_shop_data() -> void:
    shop_groups.clear()
    buy_buttons.clear()

    var powerup_coin_items: Array = [
        {
            "id": "magnet_30s",
            "name": "Magnet 30 detik",
            "price": 150,
            "currency": "coins"
        },
        {
            "id": "shield_1hit",
            "name": "Perisai 1 Hit",
            "price": 200,
            "currency": "coins"
        },
        {
            "id": "double_coins_run",
            "name": "Double Coins (1 Run)",
            "price": 250,
            "currency": "coins"
        },
        {
            "id": "extra_heart_run",
            "name": "Extra Heart (1 Run)",
            "price": 300,
            "currency": "coins"
        }
    ]

    var upgrade_coin_items: Array = [
        {
            "id": "max_heart_plus1",
            "name": "Upgrade Nyawa Maks +1",
            "price": 1000,
            "currency": "coins"
        },
        {
            "id": "magnet_duration_plus10",
            "name": "Upgrade Durasi Magnet +10%",
            "price": 800,
            "currency": "coins"
        },
        {
            "id": "shield_duration_plus10",
            "name": "Upgrade Durasi Shield +10%",
            "price": 800,
            "currency": "coins"
        },
        {
            "id": "pickup_range_plus1",
            "name": "Upgrade Jangkauan Pickup +1",
            "price": 600,
            "currency": "coins"
        }
    ]

    var cosmetic_coin_items: Array = [
        {
            "id": "skin_basic",
            "name": "Skin Basic",
            "price": 150,
            "currency": "coins"
        },
        {
            "id": "skin_premium",
            "name": "Skin Premium",
            "price": 400,
            "currency": "coins"
        }
    ]

    var gem_pack_real_items: Array = [
        {
            "id": "gems_small",
            "name": "Small Gem Pack (100)",
            "price": 15000,
            "currency": "real",
            "display_price": "Rp 15.000"
        },
        {
            "id": "gems_standard",
            "name": "Standard Gem Pack (300 +30)",
            "price": 45000,
            "currency": "real",
            "display_price": "Rp 45.000"
        },
        {
            "id": "gems_big",
            "name": "Big Gem Pack (800 +150)",
            "price": 99000,
            "currency": "real",
            "display_price": "Rp 99.000"
        },
        {
            "id": "gems_mega",
            "name": "Mega Gem Pack (2000 +500)",
            "price": 199000,
            "currency": "real",
            "display_price": "Rp 199.000"
        }
    ]

    var bundle_real_items: Array = [
        {
            "id": "starter_bundle",
            "name": "Starter Pack",
            "price": 29000,
            "currency": "real",
            "display_price": "Rp 29.000"
        },
        {
            "id": "progress_bundle",
            "name": "Progress Pack",
            "price": 59000,
            "currency": "real",
            "display_price": "Rp 59.000"
        },
        {
            "id": "cosmetic_bundle",
            "name": "Cosmetic Starter",
            "price": 49000,
            "currency": "real",
            "display_price": "Rp 49.000"
        }
    ]

    shop_groups.append({
        "id": "powerups_coins",
        "title": "Power-ups (Coins)",
        "items": powerup_coin_items
    })

    shop_groups.append({
        "id": "upgrades_coins",
        "title": "Upgrades (Coins)",
        "items": upgrade_coin_items
    })

    shop_groups.append({
        "id": "cosmetics_coins",
        "title": "Cosmetics (Coins)",
        "items": cosmetic_coin_items
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

func _build_groups_ui() -> void:
    var groups_root := get_node_or_null("UI/VBox/GroupsScroll/GroupsVBox") as HBoxContainer
    var status_label := get_node_or_null("UI/VBox/StatusLabel") as Label
    if groups_root == null:
        if status_label:
            status_label.text = "[Error] Groups container tidak ditemukan"
        return
    for child in groups_root.get_children():
        if child is Node:
            child.queue_free()
    buy_buttons.clear()
    for g in shop_groups:
        if not (g is Dictionary):
            continue
        var group_root := VBoxContainer.new()
        group_root.custom_minimum_size = Vector2(260.0, 220.0)
        group_root.size_flags_horizontal = Control.SIZE_FILL
        group_root.add_theme_constant_override("separation", 8)

        var title_label := Label.new()
        title_label.text = String(g.get("title", ""))
        title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        group_root.add_child(title_label)

        var items_row := HBoxContainer.new()
        items_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        items_row.add_theme_constant_override("separation", 12)

        var items_value = g.get("items", [])
        if items_value is Array:
            var items: Array = items_value
            for item in items:
                if not (item is Dictionary):
                    continue
                var card := _create_item_card(item)
                if card:
                    items_row.add_child(card)

        group_root.add_child(items_row)
        groups_root.add_child(group_root)

    if status_label:
        status_label.text = "Groups: " + str(shop_groups.size()) + ", Items: " + str(buy_buttons.size())

func _create_item_card(item: Dictionary) -> Control:
    var panel := PanelContainer.new()
    panel.custom_minimum_size = Vector2(180.0, 140.0)
    panel.size_flags_horizontal = Control.SIZE_FILL

    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.15, 0.15, 0.15, 1.0)
    style.border_color = Color(1.0, 1.0, 1.0, 0.4)
    style.border_width_top = 2
    style.border_width_bottom = 2
    style.border_width_left = 2
    style.border_width_right = 2
    style.corner_radius_top_left = 8
    style.corner_radius_top_right = 8
    style.corner_radius_bottom_left = 8
    style.corner_radius_bottom_right = 8
    panel.add_theme_stylebox_override("panel", style)

    var card := VBoxContainer.new()
    card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    card.add_theme_constant_override("separation", 4)

    var name_label := Label.new()
    name_label.text = String(item.get("name", "Item"))
    name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

    var price_label := Label.new()
    var display_price := String(item.get("display_price", ""))
    if display_price != "":
        price_label.text = display_price
    else:
        var price_value := int(item.get("price", 0))
        var currency := String(item.get("currency", "coins"))
        var currency_label := ""
        if currency == "coins":
            currency_label = "Coins"
        elif currency == "gems":
            currency_label = "Gems"
        else:
            currency_label = currency.capitalize()
        price_label.text = str(price_value) + " " + currency_label
    price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

    var button := Button.new()
    button.text = "Beli"
    button.size_flags_horizontal = Control.SIZE_EXPAND_FILL

    card.add_child(name_label)
    card.add_child(price_label)
    card.add_child(button)
    panel.add_child(card)

    var entry := {
        "button": button,
        "item": item
    }
    buy_buttons.append(entry)
    button.pressed.connect(Callable(self, "_on_item_buy_pressed").bind(item))
    return panel

func _update_buy_buttons_state() -> void:
    for e in buy_buttons:
        if not (e is Dictionary):
            continue
        var b = e.get("button")
        var it = e.get("item")
        if b == null or it == null:
            continue
        if not (b is BaseButton):
            continue
        var price := int(it.get("price", 0))
        (b as BaseButton).disabled = current_coins < price

func _on_item_buy_pressed(item: Dictionary) -> void:
    var status_label := get_node_or_null("UI/VBox/StatusLabel") as Label
    var price := int(item.get("price", 0))
    var currency := String(item.get("currency", "coins"))
    if currency != "coins":
        if status_label:
            status_label.text = "Belum didukung."
        return
    if current_coins < price:
        if status_label:
            status_label.text = "Koin tidak cukup."
        return
    current_coins -= price
    _save_coins(current_coins)
    var coins_label := get_node_or_null("UI/VBox/CoinsLabel") as Label
    if coins_label:
        coins_label.text = "Coins: " + str(current_coins)
    _update_buy_buttons_state()
    if status_label:
        status_label.text = "Pembelian berhasil: " + String(item.get("name", "Item"))

func _on_back_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _apply_ui_font(node: Node, font: Font) -> void:
    if node is Label:
        (node as Label).add_theme_font_override("font", font)
    elif node is BaseButton:
        (node as BaseButton).add_theme_font_override("font", font)
    for child in node.get_children():
        if child is Node:
            _apply_ui_font(child, font)
