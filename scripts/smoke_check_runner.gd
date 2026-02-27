extends SceneTree

func _initialize() -> void:
    var tpaths: Array[String] = [
        "res://i18n/translations.id.translation",
        "res://i18n/translations.en.translation",
        "res://i18n/translations.zh.translation"
    ]
    for tp in tpaths:
        load(tp)
    var paths: Array[String] = [
        "res://scenes/LoadingScreen.tscn",
        "res://scenes/MainMenu.tscn",
        "res://scenes/Main.tscn",
        "res://scenes/DailyMissionsMenu.tscn",
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
    quit()
