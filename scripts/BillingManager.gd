extends Node

signal connection_status_changed(is_connected: bool)
signal product_details_received(products: Array)
signal purchase_status_changed(result: Dictionary)
signal purchase_successful(product_id: String)
signal purchase_failed(error_message: String)
signal purchase_cancelled()
signal purchase_restored(product_id: String)

const _SHOP_CATALOG_SCRIPT := preload("res://scripts/data/ShopCatalog.gd")
const _FALLBACK_PRODUCTS: Array[String] = [
    "gems_small",
    "gems_standard",
    "gems_big",
    "gems_mega",
    "starter_bundle",
    "progress_bundle",
    "cosmetic_bundle"
]
const _NON_CONSUMABLE_PRODUCTS: Array[String] = [
    "remove_ads"
]

var billing: BillingClient = null
var billing_connected: bool = false
var products: Array[String] = []
var _pending_context_by_product: Dictionary = {}
var _pending_context_by_token: Dictionary = {}


func _ready() -> void:
    _refresh_catalog_products()

    billing = BillingClient.new()
    add_child(billing)

    billing.connected.connect(_on_connected)
    billing.disconnected.connect(_on_disconnected)
    billing.connect_error.connect(_on_connect_error)
    billing.query_product_details_response.connect(_on_product_details_query_completed)
    billing.query_purchases_response.connect(_on_purchases_query_completed)
    billing.on_purchase_updated.connect(_on_purchases_updated)
    billing.consume_purchase_response.connect(_on_consume_purchase_response)
    billing.acknowledge_purchase_response.connect(_on_acknowledge_purchase_response)

    start_connection()


func _refresh_catalog_products() -> void:
    products.clear()
    var ids: Array[String] = _SHOP_CATALOG_SCRIPT.get_iap_product_ids()
    for pid in ids:
        var normalized := String(pid).strip_edges()
        if normalized.is_empty():
            continue
        if not products.has(normalized):
            products.append(normalized)
    if products.is_empty():
        for pid in _FALLBACK_PRODUCTS:
            if not products.has(pid):
                products.append(pid)


func start_connection() -> void:
    if billing:
        billing.start_connection()


func is_billing_connected() -> bool:
    return billing_connected


func query_products() -> void:
    if billing and billing_connected:
        billing.query_product_details(products, BillingClient.ProductType.INAPP)


func buy(product_id: String, context: Dictionary = {}) -> Dictionary:
    var pid := product_id.strip_edges()
    if pid.is_empty():
        return {
            "ok": false,
            "error": "invalid_product_id",
            "product_id": "",
            "context": context,
            "status": "failed"
        }

    if not billing or not billing_connected:
        _emit_purchase_status({
            "status": "failed",
            "product_id": pid,
            "error": "billing_not_connected",
            "context": context
        })
        emit_signal("purchase_failed", "Billing service not connected")
        return {
            "ok": false,
            "error": "billing_not_connected",
            "product_id": pid,
            "context": context,
            "status": "failed"
        }

    _pending_context_by_product[pid] = context.duplicate(true)

    var response: Variant = billing.purchase(pid)
    var status_value: int = OK
    if response is Dictionary:
        status_value = int((response as Dictionary).get("status", OK))
    elif response is int:
        status_value = int(response)

    if status_value != OK:
        _emit_purchase_status({
            "status": "failed",
            "product_id": pid,
            "error": "purchase_request_failed",
            "response_code": status_value,
            "context": context
        })
        emit_signal("purchase_failed", "Purchase request failed: " + str(status_value))
        return {
            "ok": false,
            "error": "purchase_request_failed",
            "product_id": pid,
            "context": context,
            "status": "failed",
            "response_code": status_value
        }

    return {
        "ok": true,
        "error": "",
        "product_id": pid,
        "context": context,
        "status": "submitted"
    }


func purchase(product_id: String) -> void:
    buy(product_id, {})


func _on_connected() -> void:
    print("BillingManager: Connected to Google Play Billing")
    billing_connected = true
    emit_signal("connection_status_changed", true)

    query_products()

    if billing:
        billing.query_purchases(BillingClient.ProductType.INAPP)


func _on_disconnected() -> void:
    print("BillingManager: Disconnected from Google Play Billing")
    billing_connected = false
    emit_signal("connection_status_changed", false)


func _on_connect_error(response_code: int, debug_message: String) -> void:
    print("BillingManager: Connect Error: %s - %s" % [response_code, debug_message])
    billing_connected = false
    emit_signal("connection_status_changed", false)


func _on_product_details_query_completed(response: Dictionary) -> void:
    if response.get("status") == OK:
        var product_details: Array = []
        var list_any: Variant = response.get("product_details_list", [])
        if list_any is Array:
            product_details = list_any
        elif response.has("product_details") and response.get("product_details") is Array:
            product_details = response.get("product_details")

        print("BillingManager: Product details received: ", product_details)
        emit_signal("product_details_received", product_details)
    else:
        print("BillingManager: Product query failed: ", response)


func _on_purchases_query_completed(response: Variant) -> void:
    if response is Dictionary and int((response as Dictionary).get("status", -1)) == OK:
        var purchases_any: Variant = (response as Dictionary).get("purchases_list", [])
        if purchases_any is Array:
            _handle_purchases_list(purchases_any, true)
    elif response is Dictionary:
        print("BillingManager: Purchase query failed with status: ", (response as Dictionary).get("status", "unknown"))
    else:
        print("BillingManager: Purchase query response is not a Dictionary: ", response)


func _on_purchases_updated(response: Dictionary) -> void:
    var status: int = int(response.get("status", -1))
    if status == OK:
        var purchases_any: Variant = response.get("purchases_list", [])
        if purchases_any is Array:
            _handle_purchases_list(purchases_any, false)
    elif status == 1:
        _emit_purchase_status({
            "status": "cancelled",
            "product_id": "",
            "context": {}
        })
        emit_signal("purchase_cancelled")
    else:
        _on_purchase_error(status, String(response.get("debug_message", "Unknown error")))


func _handle_purchases_list(purchases: Array, is_restore: bool) -> void:
    for p_any in purchases:
        if not (p_any is Dictionary):
            continue
        var purch: Dictionary = p_any
        var purchase_state: int = int(purch.get("purchase_state", 0))
        if purchase_state == 1:
            _handle_purchase(purch, is_restore)
        elif purchase_state == 2:
            var pending_product := _extract_product_id(purch)
            var pending_token := _extract_purchase_token(purch)
            var pending_ctx := _resolve_context_for_purchase(pending_product, pending_token)
            _emit_purchase_status({
                "status": "pending",
                "product_id": pending_product,
                "purchase_token": pending_token,
                "is_restore": is_restore,
                "context": pending_ctx
            })


func _extract_product_id(purch: Dictionary) -> String:
    var products_any: Variant = purch.get("products", [])
    if products_any is Array and (products_any as Array).size() > 0:
        return String((products_any as Array)[0]).strip_edges()
    var product_id := String(purch.get("product_id", "")).strip_edges()
    if not product_id.is_empty():
        return product_id
    return ""


func _extract_purchase_token(purch: Dictionary) -> String:
    var token := String(purch.get("purchase_token", "")).strip_edges()
    if token.is_empty():
        token = String(purch.get("token", "")).strip_edges()
    return token


func _resolve_context_for_purchase(product_id: String, token: String) -> Dictionary:
    var ctx: Dictionary = {}
    if not token.is_empty() and _pending_context_by_token.has(token):
        var token_ctx_any: Variant = _pending_context_by_token[token]
        if token_ctx_any is Dictionary:
            ctx = (token_ctx_any as Dictionary).duplicate(true)
        return ctx

    if _pending_context_by_product.has(product_id):
        var product_ctx_any: Variant = _pending_context_by_product[product_id]
        if product_ctx_any is Dictionary:
            ctx = (product_ctx_any as Dictionary).duplicate(true)
        if not token.is_empty() and not ctx.is_empty():
            _pending_context_by_token[token] = ctx.duplicate(true)
    return ctx


func _handle_purchase(purch: Dictionary, is_restore: bool) -> void:
    var product_id := _extract_product_id(purch)
    if product_id.is_empty():
        return

    var token := _extract_purchase_token(purch)
    var ctx := _resolve_context_for_purchase(product_id, token)

    if billing != null and not token.is_empty():
        if _is_consumable_product(product_id):
            billing.consumePurchase(token)
        elif (not bool(purch.get("is_acknowledged", false))) and _is_non_consumable_product(product_id):
            billing.acknowledgePurchase(token)

    var status := ("restored" if is_restore else "success")
    _emit_purchase_status({
        "status": status,
        "product_id": product_id,
        "purchase_token": token,
        "purchase_state": int(purch.get("purchase_state", 1)),
        "is_restore": is_restore,
        "context": ctx
    })

    if is_restore:
        emit_signal("purchase_restored", product_id)
    else:
        emit_signal("purchase_successful", product_id)

    if not token.is_empty() and _pending_context_by_token.has(token):
        _pending_context_by_token.erase(token)
    if _pending_context_by_product.has(product_id):
        _pending_context_by_product.erase(product_id)


func _is_non_consumable_product(product_id: String) -> bool:
    return _NON_CONSUMABLE_PRODUCTS.has(product_id)


func _is_consumable_product(product_id: String) -> bool:
    return not _is_non_consumable_product(product_id)


func _on_consume_purchase_response(response: Dictionary) -> void:
    if int(response.get("status", OK)) != OK:
        print("BillingManager: Consume failed: ", response)


func _on_acknowledge_purchase_response(response: Dictionary) -> void:
    if int(response.get("status", OK)) != OK:
        print("BillingManager: Acknowledge failed: ", response)


func _on_purchase_error(response_code: int, error_message: String) -> void:
    print("BillingManager: Purchase error: ", error_message)
    if response_code == 1:
        _emit_purchase_status({
            "status": "cancelled",
            "product_id": "",
            "error": error_message,
            "context": {}
        })
        emit_signal("purchase_cancelled")
    else:
        _emit_purchase_status({
            "status": "failed",
            "product_id": "",
            "error": error_message,
            "response_code": response_code,
            "context": {}
        })
        emit_signal("purchase_failed", error_message)


func _emit_purchase_status(payload: Dictionary) -> void:
    var out: Dictionary = payload.duplicate(true)
    if not out.has("status"):
        out["status"] = "unknown"
    if not out.has("product_id"):
        out["product_id"] = ""
    if not out.has("context"):
        out["context"] = {}
    purchase_status_changed.emit(out)
