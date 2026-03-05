extends Node

signal purchase_result(result: Dictionary)
signal rewarded_result(result: Dictionary)
signal telemetry_event_logged(event_name: String, payload: Dictionary)

const _TELEMETRY_PATH := "user://monetization_telemetry.log"
const _REWARDED_REQUEST_COOLDOWN_SEC := 1.5
const _AD_RETRY_DELAY_SEC := 2.5

var _active_rewarded_placement: String = ""
var _active_rewarded_granted: bool = false
var _rewarded_cooldown_until_msec: int = 0
var _ad_retry_timer: Timer = null

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _ensure_retry_timer()
    _connect_ad_manager()
    _connect_billing_manager()


func _ensure_retry_timer() -> void:
    if _ad_retry_timer != null:
        return
    var t := Timer.new()
    t.one_shot = true
    t.wait_time = _AD_RETRY_DELAY_SEC
    t.timeout.connect(_on_ad_retry_timeout)
    add_child(t)
    _ad_retry_timer = t


func _connect_ad_manager() -> void:
    var adm = AdManager
    if adm == null:
        return
    if adm.has_signal("reward_granted"):
        var cb_reward := Callable(self, "_on_ad_reward_granted")
        if not adm.is_connected("reward_granted", cb_reward):
            adm.connect("reward_granted", cb_reward)
    if adm.has_signal("rewarded_ad_closed"):
        var cb_closed := Callable(self, "_on_rewarded_ad_closed")
        if not adm.is_connected("rewarded_ad_closed", cb_closed):
            adm.connect("rewarded_ad_closed", cb_closed)
    if adm.has_signal("rewarded_ad_loaded"):
        var cb_loaded := Callable(self, "_on_rewarded_ad_loaded")
        if not adm.is_connected("rewarded_ad_loaded", cb_loaded):
            adm.connect("rewarded_ad_loaded", cb_loaded)
    if adm.has_signal("rewarded_ad_failed_to_load"):
        var cb_failed := Callable(self, "_on_rewarded_ad_failed_to_load")
        if not adm.is_connected("rewarded_ad_failed_to_load", cb_failed):
            adm.connect("rewarded_ad_failed_to_load", cb_failed)


func _connect_billing_manager() -> void:
    var bm = BillingManager
    if bm == null:
        return
    if bm.has_signal("purchase_status_changed"):
        var cb_status := Callable(self, "_on_billing_purchase_status_changed")
        if not bm.is_connected("purchase_status_changed", cb_status):
            bm.connect("purchase_status_changed", cb_status)
        return
    if bm.has_signal("purchase_successful"):
        var cb_ok := Callable(self, "_on_legacy_purchase_success")
        if not bm.is_connected("purchase_successful", cb_ok):
            bm.connect("purchase_successful", cb_ok)
    if bm.has_signal("purchase_cancelled"):
        var cb_cancel := Callable(self, "_on_legacy_purchase_cancelled")
        if not bm.is_connected("purchase_cancelled", cb_cancel):
            bm.connect("purchase_cancelled", cb_cancel)
    if bm.has_signal("purchase_failed"):
        var cb_fail := Callable(self, "_on_legacy_purchase_failed")
        if not bm.is_connected("purchase_failed", cb_fail):
            bm.connect("purchase_failed", cb_fail)


func buy(product_id: String, context: Dictionary = {}) -> Dictionary:
    var pid := product_id.strip_edges()
    if pid.is_empty():
        return {"ok": false, "error": "invalid_product_id", "product_id": ""}

    _log_telemetry("purchase_click", {
        "product_id": pid,
        "shop_item_id": String(context.get("shop_item_id", ""))
    })

    var bm = BillingManager
    if bm == null:
        var no_billing := {
            "ok": false,
            "error": "billing_manager_unavailable",
            "product_id": pid,
            "context": context
        }
        _emit_purchase_result({
            "status": "failed",
            "product_id": pid,
            "error": "billing_manager_unavailable",
            "context": context
        })
        return no_billing

    if bm.has_method("buy"):
        return bm.call("buy", pid, context)

    if bm.has_method("purchase"):
        bm.call("purchase", pid)
        return {
            "ok": true,
            "error": "",
            "product_id": pid,
            "context": context,
            "status": "submitted"
        }

    var unsupported := {
        "ok": false,
        "error": "billing_method_unavailable",
        "product_id": pid,
        "context": context
    }
    _emit_purchase_result({
        "status": "failed",
        "product_id": pid,
        "error": "billing_method_unavailable",
        "context": context
    })
    return unsupported


func on_purchase_result(result: Dictionary) -> void:
    _emit_purchase_result(result)


func show_rewarded(placement: String) -> Dictionary:
    var reason := placement.strip_edges()
    if reason.is_empty():
        return {"ok": false, "error": "invalid_placement", "placement": ""}

    var now_msec: int = Time.get_ticks_msec()
    if now_msec < _rewarded_cooldown_until_msec:
        var wait_ms := _rewarded_cooldown_until_msec - now_msec
        var wait_sec := float(wait_ms) / 1000.0
        var cooldown_res := {
            "ok": false,
            "error": "cooldown",
            "placement": reason,
            "retry_after_sec": wait_sec
        }
        _emit_rewarded_result({
            "status": "cooldown",
            "placement": reason,
            "retry_after_sec": wait_sec
        })
        return cooldown_res

    var adm = AdManager
    if adm == null:
        var no_ad := {"ok": false, "error": "ad_manager_unavailable", "placement": reason}
        _emit_rewarded_result({
            "status": "failed",
            "placement": reason,
            "error": "ad_manager_unavailable"
        })
        return no_ad

    var is_available := false
    if adm.has_method("is_rewarded_available"):
        is_available = bool(adm.call("is_rewarded_available"))

    if not is_available:
        if adm.has_method("load_rewarded"):
            adm.call("load_rewarded")
        if _ad_retry_timer != null and _ad_retry_timer.is_stopped():
            _ad_retry_timer.start()
        _emit_rewarded_result({
            "status": "not_available",
            "placement": reason
        })
        return {"ok": false, "error": "not_available", "placement": reason}

    if not adm.has_method("show_rewarded"):
        _emit_rewarded_result({
            "status": "failed",
            "placement": reason,
            "error": "show_rewarded_unavailable"
        })
        return {"ok": false, "error": "show_rewarded_unavailable", "placement": reason}

    _active_rewarded_placement = reason
    _active_rewarded_granted = false
    _rewarded_cooldown_until_msec = now_msec + int(_REWARDED_REQUEST_COOLDOWN_SEC * 1000.0)

    _log_telemetry("rewarded_impression_request", {
        "placement": reason
    })

    adm.call("show_rewarded", reason)
    return {
        "ok": true,
        "error": "",
        "placement": reason,
        "status": "show_requested"
    }


func is_rewarded_available() -> bool:
    var adm = AdManager
    if adm == null:
        return false
    if not adm.has_method("is_rewarded_available"):
        return false
    return bool(adm.call("is_rewarded_available"))


func _on_ad_reward_granted(reason: String) -> void:
    var placement := reason.strip_edges()
    if placement.is_empty():
        placement = _active_rewarded_placement
    if placement.is_empty():
        return
    _active_rewarded_granted = true
    _emit_rewarded_result({
        "status": "granted",
        "placement": placement
    })
    _log_telemetry("reward_granted", {"placement": placement})


func _on_rewarded_ad_closed() -> void:
    if _active_rewarded_placement.is_empty():
        return
    if _active_rewarded_granted:
        _emit_rewarded_result({
            "status": "closed",
            "placement": _active_rewarded_placement
        })
    else:
        _emit_rewarded_result({
            "status": "cancelled",
            "placement": _active_rewarded_placement
        })
    _active_rewarded_placement = ""
    _active_rewarded_granted = false


func _on_rewarded_ad_loaded() -> void:
    _emit_rewarded_result({
        "status": "loaded",
        "placement": _active_rewarded_placement
    })


func _on_rewarded_ad_failed_to_load(error_code: int) -> void:
    _emit_rewarded_result({
        "status": "load_failed",
        "placement": _active_rewarded_placement,
        "error_code": error_code
    })


func _on_ad_retry_timeout() -> void:
    var adm = AdManager
    if adm != null and adm.has_method("load_rewarded"):
        adm.call("load_rewarded")


func _on_billing_purchase_status_changed(result: Dictionary) -> void:
    _emit_purchase_result(result)


func _on_legacy_purchase_success(product_id: String) -> void:
    _emit_purchase_result({
        "status": "success",
        "product_id": product_id,
        "context": {}
    })


func _on_legacy_purchase_cancelled() -> void:
    _emit_purchase_result({
        "status": "cancelled",
        "product_id": "",
        "context": {}
    })


func _on_legacy_purchase_failed(error_message: String) -> void:
    _emit_purchase_result({
        "status": "failed",
        "product_id": "",
        "error": error_message,
        "context": {}
    })


func _emit_purchase_result(result: Dictionary) -> void:
    var normalized: Dictionary = result.duplicate(true)
    if not normalized.has("status"):
        normalized["status"] = "unknown"
    if not normalized.has("product_id"):
        normalized["product_id"] = ""
    if not normalized.has("context"):
        normalized["context"] = {}
    var context: Dictionary = {}
    var context_any: Variant = normalized.get("context", {})
    if context_any is Dictionary:
        context = context_any
    var status := String(normalized.get("status", "unknown"))
    var telemetry_name := "purchase_" + status
    _log_telemetry(telemetry_name, {
        "status": status,
        "product_id": String(normalized.get("product_id", "")),
        "shop_item_id": String(context.get("shop_item_id", ""))
    })
    purchase_result.emit(normalized)


func _emit_rewarded_result(result: Dictionary) -> void:
    var normalized: Dictionary = result.duplicate(true)
    if not normalized.has("status"):
        normalized["status"] = "unknown"
    if not normalized.has("placement"):
        normalized["placement"] = ""
    var status := String(normalized.get("status", "unknown"))
    if status == "not_available":
        _log_telemetry("rewarded_not_available", {
            "placement": String(normalized.get("placement", ""))
        })
    rewarded_result.emit(normalized)


func _log_telemetry(event_name: String, payload: Dictionary) -> void:
    telemetry_event_logged.emit(event_name, payload)
    var line := {
        "ts": Time.get_unix_time_from_system(),
        "event": event_name,
        "payload": payload
    }
    var file := FileAccess.open(_TELEMETRY_PATH, FileAccess.READ_WRITE)
    if file == null:
        file = FileAccess.open(_TELEMETRY_PATH, FileAccess.WRITE)
    if file == null:
        return
    file.seek_end()
    file.store_line(JSON.stringify(line))
    file.flush()
