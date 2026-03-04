@tool
extends SceneTree

func _init() -> void:
    print("--- Asset Sanity Check Started ---")
    var errors: int = 0
    errors += _check_scripts()

    if errors > 0:
        print("--- Check Failed: %d errors found ---" % errors)
        quit(1)
    else:
        print("--- Check Passed: No errors found ---")
        quit(0)

func _check_scripts() -> int:
    var err_count := 0
    var script_dir := "res://scripts/"
    var files := _get_all_files(script_dir, ["gd"])

    for file_path in files:
        var f := FileAccess.open(file_path, FileAccess.READ)
        if not f: continue

        var line_num := 0
        while f.get_position() < f.get_length():
            line_num += 1
            var line := f.get_line()

            # Check for hardcoded "res://" paths
            if "res://" in line:
                var regex := RegEx.new()
                regex.compile('"(res://[^"]+)"')
                var matches := regex.search_all(line)
                for m in matches:
                    var path := m.get_string(1)
                    if not _path_exists(path):
                        if path.ends_with("/"):
                            printerr("WARN: Missing optional directory in %s:%d -> %s" % [file_path, line_num, path])
                        else:
                            printerr("ERR: Broken path in %s:%d -> %s" % [file_path, line_num, path])
                            err_count += 1

            # Check for FileAccess.file_exists usage (should use ResourceLoader.exists for res://)
            if file_path != "res://scripts/tools/sanity_check.gd" and "FileAccess.file_exists" in line and "res://" in line:
                printerr("WARN: FileAccess.file_exists used for res:// path in %s:%d. Use ResourceLoader.exists() instead." % [file_path, line_num])
                # Not an error yet, but a warning
    return err_count

func _path_exists(path: String) -> bool:
    if path == "":
        return false
    if ResourceLoader.exists(path):
        return true
    if FileAccess.file_exists(path):
        return true
    if DirAccess.dir_exists_absolute(path):
        return true
    return false

func _get_all_files(path: String, extensions: Array) -> Array:
    var files := []
    var dir := DirAccess.open(path)
    if dir:
        dir.list_dir_begin()
        var file_name := dir.get_next()
        while file_name != "":
            if dir.current_is_dir():
                if not file_name.begins_with("."):
                    files.append_array(_get_all_files(path + file_name + "/", extensions))
            else:
                for ext in extensions:
                    if file_name.ends_with("." + ext):
                        files.append(path + file_name)
                        break
            file_name = dir.get_next()
    return files
