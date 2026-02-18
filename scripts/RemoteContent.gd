extends Node

signal progress_changed(progress: float)
signal status_changed(status: String)
signal content_ready
signal failed(message: String)

var _started: bool = false
var _is_ready: bool = false
var _is_failed: bool = false
var _progress: float = 0.0
var _status: String = "Loading"

func start() -> void:
    if _started:
        return
    _started = true
    call_deferred("_run")

func is_ready() -> bool:
    return _is_ready

func is_failed() -> bool:
    return _is_failed

func get_progress() -> float:
    return _progress

func get_status() -> String:
    return _status

func retry() -> void:
    if not _is_failed:
        return
    _started = false
    _is_ready = false
    _is_failed = false
    _set_progress(0.0, "Loading")
    start()

func _run() -> void:
    await get_tree().process_frame
    if not is_inside_tree():
        return

    var base_url := str(ProjectSettings.get_setting("remote_content/base_url", ""))
    var manifest_name := str(ProjectSettings.get_setting("remote_content/manifest_name", "manifest.json"))
    var packs_dir := str(ProjectSettings.get_setting("remote_content/packs_dir", "user://remote_content/packs"))
    var required := bool(ProjectSettings.get_setting("remote_content/required", false))
    var force_redownload := bool(ProjectSettings.get_setting("remote_content/force_redownload", false))

    if base_url == "":
        _set_progress(100.0, "Loading")
        _is_ready = true
        content_ready.emit()
        return

    _set_progress(1.0, "Checking content")
    var manifest_url := base_url.rstrip("/") + "/" + manifest_name
    var manifest_text: String = await _http_get_text(manifest_url)
    if manifest_text == "":
        _fail("Manifest download failed")
        return

    var parsed: Variant = JSON.parse_string(manifest_text)
    if typeof(parsed) != TYPE_DICTIONARY:
        _fail("Manifest invalid")
        return

    var manifest: Dictionary = parsed
    var packs: Array = []
    if manifest.has("packs") and typeof(manifest["packs"]) == TYPE_ARRAY:
        packs = manifest["packs"]

    if packs.is_empty():
        _set_progress(100.0, "Loading")
        _is_ready = true
        content_ready.emit()
        return

    _ensure_dir(packs_dir)

    var total: int = max(1, packs.size())
    var i := 0
    for pack in packs:
        i += 1
        if typeof(pack) != TYPE_DICTIONARY:
            if required:
                _fail("Manifest packs invalid")
                return
            continue

        var p: Dictionary = pack
        var rel_path := str(p.get("path", ""))
        if rel_path == "":
            if required:
                _fail("Manifest pack path missing")
                return
            continue

        var sha256 := str(p.get("sha256", ""))
        var local_path := packs_dir.rstrip("/") + "/" + rel_path
        _ensure_dir(local_path.get_base_dir())

        var pack_ok := false
        if not force_redownload and FileAccess.file_exists(local_path):
            if sha256 == "" or _sha256_file(local_path) == sha256:
                pack_ok = true

        if not pack_ok:
            _set_progress(_progress_for_pack(i - 1, total), "Downloading assets")
            var url := base_url.rstrip("/") + "/" + rel_path
            pack_ok = await _http_download_file(url, local_path)
            if pack_ok and sha256 != "":
                if _sha256_file(local_path) != sha256:
                    pack_ok = false
                    _delete_user_file(local_path)

        if not pack_ok:
            if required:
                _fail("Content download failed")
                return
            continue

        _set_progress(_progress_for_pack(i, total), "Mounting assets")
        var mounted := ProjectSettings.load_resource_pack(local_path, true)
        if not mounted and required:
            _fail("Content mount failed")
            return

    _set_progress(100.0, "Loading")
    _is_ready = true
    content_ready.emit()

func _progress_for_pack(done: int, total: int) -> float:
    var t: int = max(1, total)
    return 3.0 + (float(done) / float(t)) * 95.0

func _http_get_text(url: String) -> String:
    var req := HTTPRequest.new()
    req.timeout = 30
    add_child(req)
    var err := req.request(url)
    if err != OK:
        req.queue_free()
        return ""
    var result: Array = await req.request_completed
    var code := int(result[1])
    var body: PackedByteArray = result[3]
    req.queue_free()
    if code < 200 or code >= 300:
        return ""
    return body.get_string_from_utf8()

func _http_download_file(url: String, target_user_path: String) -> bool:
    var req := HTTPRequest.new()
    req.timeout = 120
    req.download_file = target_user_path
    add_child(req)
    var err := req.request(url)
    if err != OK:
        req.queue_free()
        return false
    var result: Array = await req.request_completed
    var code := int(result[1])
    req.queue_free()
    if code < 200 or code >= 300:
        return false
    return FileAccess.file_exists(target_user_path)

func _ensure_dir(user_path: String) -> void:
    var abs_path := ProjectSettings.globalize_path(user_path)
    DirAccess.make_dir_recursive_absolute(abs_path)

func _delete_user_file(user_path: String) -> void:
    if not FileAccess.file_exists(user_path):
        return
    var abs_path := ProjectSettings.globalize_path(user_path)
    DirAccess.remove_absolute(abs_path)

func _sha256_file(user_path: String) -> String:
    var f := FileAccess.open(user_path, FileAccess.READ)
    if f == null:
        return ""
    var ctx := HashingContext.new()
    ctx.start(HashingContext.HASH_SHA256)
    while f.get_position() < f.get_length():
        ctx.update(f.get_buffer(1024 * 1024))
    var digest := ctx.finish()
    return digest.hex_encode()

func _set_progress(p: float, s: String) -> void:
    _progress = clampf(p, 0.0, 100.0)
    _status = s
    progress_changed.emit(_progress)
    status_changed.emit(_status)

func _fail(message: String) -> void:
    _is_failed = true
    _status = message
    failed.emit(message)
