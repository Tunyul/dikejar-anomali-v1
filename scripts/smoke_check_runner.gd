extends SceneTree

const _TIMEOUT_MS := 15000

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var errors: Array[String] = []
    _check_translations(errors)
    _check_scene_instantiation(errors)
    await _check_preloader_pipeline(errors)
    _check_shop_confirm_text(errors)
    await _check_collectible_heart_integrity(errors)
    await _check_coin_pool_state_reset(errors)

    if errors.is_empty():
        print("SMOKE_CHECK_OK")
        quit(0)
        return

    for err in errors:
        push_error(err)
    quit(1)

func _check_translations(errors: Array[String]) -> void:
    var tpaths: Array[String] = [
        "res://i18n/translations.id.translation",
        "res://i18n/translations.en.translation",
        "res://i18n/translations.zh.translation"
    ]
    for tp in tpaths:
        if not ResourceLoader.exists(tp):
            errors.append("Missing translation resource: %s" % tp)
            continue
        load(tp)

func _check_scene_instantiation(errors: Array[String]) -> void:
    var paths: Array[String] = [
        "res://scenes/LoadingScreen.tscn",
        "res://scenes/MainMenu.tscn",
        "res://scenes/Main.tscn",
        "res://scenes/DailyMissionsMenu.tscn",
        "res://scenes/SeasonRewardsMenu.tscn",
        "res://scenes/SkillProgressPanel.tscn",
        "res://scenes/ShopMenu.tscn",
        "res://scenes/Coin.tscn",
        "res://scenes/Diamond.tscn"
    ]
    for p in paths:
        var res := load(p)
        if res is PackedScene:
            var inst := (res as PackedScene).instantiate()
            if inst:
                inst.free()
        else:
            errors.append("Failed to load scene: %s" % p)

func _check_shop_confirm_text(errors: Array[String]) -> void:
    var shop_script := load("res://scripts/ShopMenu.gd") as Script
    if shop_script == null:
        errors.append("Failed to load ShopMenu script.")
        return

    var shop_any: Variant = shop_script.new()
    if not (shop_any is Node):
        errors.append("ShopMenu script instance is invalid.")
        return
    var shop := shop_any as Node

    if not shop.has_method("_build_confirm_purchase_text"):
        errors.append("ShopMenu missing _build_confirm_purchase_text().")
        shop.free()
        return

    var upgrade_text := String(shop.call(
        "_build_confirm_purchase_text",
        {"name": "Upgrade Durasi Magnet +10%", "is_upgrade": true},
        "coins",
        1114,
        ""
    ))
    if upgrade_text.find("\n") < 0:
        errors.append("Shop confirm text should use 2-line compact format.")
    var first_line := upgrade_text.get_slice("\n", 0).strip_edges()
    if first_line.begins_with("Upgrade "):
        errors.append("Shop confirm text still contains redundant 'Upgrade ' prefix.")
    if upgrade_text.find("1.114") < 0:
        errors.append("Shop confirm text should format grouped price (e.g. 1.114).")

    var money_text := String(shop.call(
        "_build_confirm_purchase_text",
        {"name": "Starter Pack", "is_upgrade": false},
        "money",
        15000,
        "Rp 15.000"
    ))
    if money_text.find("Rp 15.000") < 0:
        errors.append("Shop confirm text should preserve display_price for real-money items.")

    shop.free()

func _check_coin_pool_state_reset(errors: Array[String]) -> void:
    var coin_scene := load("res://scenes/Coin.tscn") as PackedScene
    if coin_scene == null:
        errors.append("Failed to load Coin.tscn for pool reset check.")
        return

    var coin_any := coin_scene.instantiate()
    if not (coin_any is Node):
        errors.append("Coin scene instance is invalid.")
        return
    var coin := coin_any as Node
    get_root().add_child(coin)
    await process_frame
    coin.set("always_magnet", true)
    coin.set("magnet_speed", 480.0)
    coin.set("source_segment", "A")
    if coin.has_method("reset"):
        coin.call("reset")
    else:
        errors.append("Coin node missing reset() method.")
        coin.free()
        return

    if bool(coin.get("always_magnet")):
        errors.append("Coin reset should clear always_magnet state for pooled instances.")
    var speed := float(coin.get("magnet_speed"))
    if speed > 200.0:
        errors.append("Coin reset should restore normal magnet speed for pooled instances.")
    var segment := String(coin.get("source_segment"))
    if not segment.is_empty():
        errors.append("Coin reset should clear source_segment for pooled instances.")
    if is_instance_valid(coin):
        coin.queue_free()
        await process_frame

func _check_collectible_heart_integrity(errors: Array[String]) -> void:
    var heart_scene := load("res://scenes/CollectibleHeart.tscn") as PackedScene
    if heart_scene == null:
        errors.append("Failed to load CollectibleHeart.tscn.")
        return

    var heart_any := heart_scene.instantiate()
    if not (heart_any is Area2D):
        errors.append("CollectibleHeart scene root should be Area2D.")
        return
    var heart := heart_any as Area2D

    var shape_node := heart.get_node_or_null("CollisionShape2D") as CollisionShape2D
    if shape_node == null:
        errors.append("CollectibleHeart missing CollisionShape2D node.")
    elif shape_node.shape == null:
        errors.append("CollectibleHeart collision shape is null (pickup won't work).")

    if heart.has_method("reset"):
        heart.call("reset")
    if not heart.monitoring:
        errors.append("CollectibleHeart should be monitoring after reset().")

    if is_instance_valid(heart):
        heart.free()

func _check_preloader_pipeline(errors: Array[String]) -> void:
    var preloader_script := load("res://scripts/Preloader.gd") as Script
    if preloader_script == null:
        errors.append("Failed to load Preloader script.")
        return

    var preloader_any: Variant = preloader_script.new()
    if not (preloader_any is Node):
        errors.append("Preloader script instance is invalid.")
        return
    var preloader := preloader_any as Node
    get_root().add_child(preloader)

    if preloader.has_method("set_next_scene"):
        preloader.call("set_next_scene", "res://scenes/Main.tscn")
    if preloader.has_method("start_preloading"):
        preloader.call("start_preloading")
    else:
        errors.append("Preloader missing start_preloading().")
        preloader.queue_free()
        return

    var boot_ok := await _wait_for_method_true(preloader, "is_ready", _TIMEOUT_MS)
    if not boot_ok:
        errors.append("Preloader boot stage timeout/failure.")

    if preloader.has_method("start_deferred_preloading"):
        preloader.call("start_deferred_preloading")
    else:
        errors.append("Preloader missing start_deferred_preloading().")
    var deferred_ok := await _wait_for_method_true(preloader, "is_deferred_ready", _TIMEOUT_MS)
    if not deferred_ok:
        errors.append("Preloader deferred stage timeout/failure.")

    if preloader.has_method("start_warmup"):
        preloader.call("start_warmup")
    else:
        errors.append("Preloader missing start_warmup().")
    var warmup_ok := await _wait_for_method_true(preloader, "is_warmup_ready", _TIMEOUT_MS)
    if not warmup_ok:
        errors.append("Preloader warmup stage timeout/failure.")

    if is_instance_valid(preloader):
        preloader.queue_free()
        await process_frame

func _wait_for_method_true(target: Object, method_name: String, timeout_ms: int) -> bool:
    if target == null:
        return false
    if not target.has_method(method_name):
        return false

    var start_ms := Time.get_ticks_msec()
    while true:
        if not is_instance_valid(target):
            return false
        var value: Variant = target.call(method_name)
        if bool(value):
            return true
        if Time.get_ticks_msec() - start_ms >= timeout_ms:
            return false
        await process_frame
    return false
