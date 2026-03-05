extends RefCounted
class_name ShopCatalog

const SHOP_ITEMS: Dictionary = {
    "gems_small": {
        "id": "gems_small",
        "category": "gems_real",
        "prices": {"real": 15000},
        "display_price": "Rp 15.000",
        "real_product_id": "gems_small",
        "grants": {
            "coins": 0,
            "gems": 100,
            "powerups": {}
        },
        "unlock_rule": "always",
        "flags": {"coming_soon": false}
    },
    "gems_standard": {
        "id": "gems_standard",
        "category": "gems_real",
        "prices": {"real": 45000},
        "display_price": "Rp 45.000",
        "real_product_id": "gems_standard",
        "grants": {
            "coins": 0,
            "gems": 330,
            "powerups": {}
        },
        "unlock_rule": "always",
        "flags": {"coming_soon": false}
    },
    "gems_big": {
        "id": "gems_big",
        "category": "gems_real",
        "prices": {"real": 99000},
        "display_price": "Rp 99.000",
        "real_product_id": "gems_big",
        "grants": {
            "coins": 0,
            "gems": 950,
            "powerups": {}
        },
        "unlock_rule": "always",
        "flags": {"coming_soon": false}
    },
    "gems_mega": {
        "id": "gems_mega",
        "category": "gems_real",
        "prices": {"real": 199000},
        "display_price": "Rp 199.000",
        "real_product_id": "gems_mega",
        "grants": {
            "coins": 0,
            "gems": 2500,
            "powerups": {}
        },
        "unlock_rule": "always",
        "flags": {"coming_soon": false}
    },
    "starter_bundle": {
        "id": "starter_bundle",
        "category": "bundles_real",
        "prices": {"real": 29000},
        "display_price": "Rp 29.000",
        "real_product_id": "starter_bundle",
        "grants": {
            "coins": 1000,
            "gems": 100,
            "powerups": {
                "magnet_30s_tokens": 2,
                "shield_1hit_charges": 1,
                "double_coins_run_tokens": 1
            }
        },
        "unlock_rule": "always",
        "flags": {"coming_soon": false}
    },
    "progress_bundle": {
        "id": "progress_bundle",
        "category": "bundles_real",
        "prices": {"real": 59000},
        "display_price": "Rp 59.000",
        "real_product_id": "progress_bundle",
        "grants": {
            "coins": 2500,
            "gems": 250,
            "powerups": {
                "magnet_30s_tokens": 3,
                "shield_1hit_charges": 2,
                "double_coins_run_tokens": 2
            }
        },
        "unlock_rule": "always",
        "flags": {"coming_soon": false}
    },
    "cosmetic_bundle": {
        "id": "cosmetic_bundle",
        "category": "bundles_real",
        "prices": {"real": 49000},
        "display_price": "Rp 49.000",
        "real_product_id": "cosmetic_bundle",
        "grants": {
            "coins": 1500,
            "gems": 200,
            "powerups": {
                "shield_1hit_charges": 2
            }
        },
        "unlock_rule": "always",
        "flags": {"coming_soon": false}
    }
}

static func get_shop_item_definition(item_id: String) -> Dictionary:
    var key := item_id.strip_edges()
    if key.is_empty():
        return {}
    var row: Variant = SHOP_ITEMS.get(key, {})
    if row is Dictionary:
        return (row as Dictionary).duplicate(true)
    return {}

static func get_iap_product_ids() -> Array[String]:
    var ids: Array[String] = []
    for key_any in SHOP_ITEMS.keys():
        var row_any: Variant = SHOP_ITEMS[key_any]
        if not (row_any is Dictionary):
            continue
        var row: Dictionary = row_any
        var product_id := String(row.get("real_product_id", "")).strip_edges()
        if product_id.is_empty():
            continue
        if not ids.has(product_id):
            ids.append(product_id)
    return ids

static func get_shop_item_id_by_product_id(product_id: String) -> String:
    var product := product_id.strip_edges()
    if product.is_empty():
        return ""
    for key_any in SHOP_ITEMS.keys():
        var item_id := String(key_any)
        var row_any: Variant = SHOP_ITEMS[key_any]
        if not (row_any is Dictionary):
            continue
        var row: Dictionary = row_any
        if String(row.get("real_product_id", "")).strip_edges() == product:
            return item_id
    return ""

static func get_definition_by_product_id(product_id: String) -> Dictionary:
    var item_id := get_shop_item_id_by_product_id(product_id)
    if item_id.is_empty():
        return {}
    return get_shop_item_definition(item_id)

static func get_iap_grants_by_shop_item_id(item_id: String) -> Dictionary:
    var row := get_shop_item_definition(item_id)
    if row.is_empty():
        return {}
    var grants: Variant = row.get("grants", {})
    if grants is Dictionary:
        return (grants as Dictionary).duplicate(true)
    return {}
