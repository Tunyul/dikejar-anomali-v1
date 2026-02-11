extends Node

signal ready_to_claim_changed(can_claim: bool)
signal mission_became_ready(mission_id: String, mission_name: String)

const _SAVE_DEBOUNCE_SEC: float = 1.0

var coins_collected: int = 0
var max_distance: int = 0
var current_run_distance: int = 0
var enemies_killed: int = 0
var jumps_total: int = 0
var runs_played: int = 0
var skills_collected: int = 0
var shield_skills_collected: int = 0
var double_coins_skills_collected: int = 0
var missions: Array = []
var mission_reward_claimed: Dictionary = {}
var daily_all_reward_claimed: bool = false

var challenge_kill_level: int = 1
var challenge_base_enemies: int = 0
var challenge_coins_level: int = 1
var challenge_base_coins: int = 0
var challenge_distance_level: int = 1
var challenge_base_distance: int = 0
var challenge_shield_level: int = 1
var challenge_base_shield: int = 0
var challenge_double_coins_level: int = 1
var challenge_base_double_coins: int = 0

var _last_ready_to_claim: bool = false

var last_reset_daily: int = 0
var last_reset_week: int = 0
var last_reset_month: int = 0

var daily_base_coins: int = 0
var daily_base_enemies: int = 0
var daily_base_jumps: int = 0
var daily_base_runs: int = 0
var daily_base_skills: int = 0
var daily_base_distance: int = 0
var daily_max_distance: int = 0

var week_base_coins: int = 0
var week_base_enemies: int = 0
var week_base_jumps: int = 0
var week_base_runs: int = 0
var week_base_skills: int = 0
var week_base_distance: int = 0
var week_max_distance: int = 0

var month_base_coins: int = 0
var month_base_enemies: int = 0
var month_base_jumps: int = 0
var month_base_runs: int = 0
var month_base_skills: int = 0
var month_base_distance: int = 0
var month_max_distance: int = 0

var _save_pending: bool = false
var _save_timer: Timer = null


func _ready() -> void:
    _ensure_save_timer()
    _load()
    if missions.is_empty():
        _init_default()
    else:
        _ensure_missions_upgraded()
    _apply_time_resets_if_needed()
    refresh_ready_to_claim_state(false)


func _exit_tree() -> void:
    if _save_pending:
        _save_pending = false
        _save()


func _ensure_save_timer() -> void:
    if _save_timer != null:
        return
    var t := Timer.new()
    t.one_shot = true
    t.wait_time = _SAVE_DEBOUNCE_SEC
    add_child(t)
    _save_timer = t
    t.timeout.connect(_flush_save)


func _request_save() -> void:
    _save_pending = true
    if _save_timer != null and _save_timer.is_stopped():
        _save_timer.start()


func _flush_save() -> void:
    if not _save_pending:
        return
    _save_pending = false
    _save()


func has_ready_to_claim_missions_in_save(save_path: String = "user://save.cfg") -> bool:
    var cfg := ConfigFile.new()
    var err := cfg.load(save_path)
    if err != OK:
        return false
    
    # Cek daily all claim status
    var daily_all_claimed := bool(cfg.get_value("missions", "daily_all_reward_claimed", false))
    
    # Cek individual missions
    var missions_data = cfg.get_value("missions", "missions", [])
    var counts := {
        "coins": int(cfg.get_value("progress", "total_coins", 0)),
        "distance": int(cfg.get_value("progress", "max_distance", 0)),
        "enemies": int(cfg.get_value("missions", "enemies_killed", 0)),
        "jumps": int(cfg.get_value("missions", "jumps_total", 0)),
        "runs": int(cfg.get_value("missions", "runs_played", 0)),
        "skills": int(cfg.get_value("missions", "skills_collected", 0))
    }

    if missions_data is Array:
        var claimed_data = cfg.get_value("missions", "mission_reward_claimed", {})
        
        for m in missions_data:
            if m is Dictionary:
                var id = str(m.get("id", ""))
                if id == "" or claimed_data.get(id, false):
                    continue
                
                var goal = int(m.get("goal", 0))
                var type = str(m.get("type", ""))
                var current = 0
                
                match type:
                    "collect_coins": current = counts.coins
                    "distance": current = counts.distance
                    "kill_enemies": current = counts.enemies
                    "jump": current = counts.jumps
                    "play_runs": current = counts.runs
                    "collect_skills": current = counts.skills
                
                if current >= goal:
                    return true

    # Cek jika daily all ready (semua daily mission selesai tapi belum di-claim)
    if not daily_all_claimed:
        var daily_ready_count = 0
        var total_daily = 0
        for m in missions_data:
            if m is Dictionary and str(m.get("tab", "")) == "daily":
                total_daily += 1
                var _id = str(m.get("id", ""))
                var goal = int(m.get("goal", 0))
                var type = str(m.get("type", ""))
                var current = 0
                match type:
                    "collect_coins": current = counts.coins
                    "distance": current = counts.distance
                    "kill_enemies": current = counts.enemies
                    "jump": current = counts.jumps
                    "play_runs": current = counts.runs
                    "collect_skills": current = counts.skills
                if current >= goal:
                    daily_ready_count += 1
        if total_daily > 0 and daily_ready_count >= total_daily:
            return true

    return false


func refresh_ready_to_claim_state(emit_on_change: bool = true) -> bool:
    var can_claim := _has_ready_to_claim_missions_in_memory()
    if emit_on_change and can_claim != _last_ready_to_claim:
        _last_ready_to_claim = can_claim
        ready_to_claim_changed.emit(can_claim)
    else:
        _last_ready_to_claim = can_claim
    return can_claim


func _has_ready_to_claim_missions_in_memory() -> bool:
    for m_any in missions:
        if not (m_any is Dictionary):
            continue
        var m: Dictionary = m_any
        var id_str := String(m.get("id", ""))
        if id_str.is_empty():
            continue
        var mt: String = String(m.get("type", "daily"))
        if mt != "challenge":
            if mission_reward_claimed.has(id_str) and bool(mission_reward_claimed[id_str]):
                continue
        var reward: int = int(m.get("reward", 0))
        if reward <= 0:
            continue
        var target: float = float(m.get("target", 0))
        if target <= 0.0:
            continue
        var prog: float = float(m.get("progress", 0))
        if prog >= target:
            return true
    return false

func _init_default() -> void:
    missions = [
        {"id": "m1", "name": "Kumpulkan 50 koin", "target": 50, "progress": 0, "type": "daily", "reward": 25, "kind": "coins"},
        {"id": "m2", "name": "Dapatkan 1 skill", "target": 1, "progress": 0, "type": "daily", "reward": 30, "kind": "skills"},
        {"id": "m3", "name": "Lompat 50 kali", "target": 50, "progress": 0, "type": "daily", "reward": 35, "kind": "jumps"},

        {"id": "m4", "name": "Kalahkan 5 musuh", "target": 5, "progress": 0, "type": "daily", "reward": 40, "kind": "enemies"},
        {"id": "m5", "name": "Capai jarak 1000m", "target": 1000, "progress": 0, "type": "daily", "reward": 45, "kind": "distance"},

        {"id": "ms1", "name": "Kumpulkan 200 koin", "target": 200, "progress": 0, "type": "mission", "reward": 70, "kind": "coins"},
        {"id": "ms2", "name": "Dapatkan 3 skill", "target": 3, "progress": 0, "type": "mission", "reward": 90, "kind": "skills"},
        {"id": "ms3", "name": "Lompat 200 kali", "target": 200, "progress": 0, "type": "mission", "reward": 120, "kind": "jumps"},
        {"id": "ms4", "name": "Kalahkan 20 musuh", "target": 20, "progress": 0, "type": "mission", "reward": 140, "kind": "enemies"},

        {"id": "w1", "name": "Kumpulkan 1000 koin", "target": 1000, "progress": 0, "type": "week", "reward": 150, "kind": "coins"},
        {"id": "w2", "name": "Dapatkan 10 skill", "target": 10, "progress": 0, "type": "week", "reward": 200, "kind": "skills"},
        {"id": "w3", "name": "Mainkan 20 run", "target": 20, "progress": 0, "type": "week", "reward": 260, "kind": "runs"},
        {"id": "w4", "name": "Kalahkan 60 musuh", "target": 60, "progress": 0, "type": "week", "reward": 300, "kind": "enemies"},

        {"id": "mo1", "name": "Kumpulkan 5000 koin", "target": 5000, "progress": 0, "type": "month", "reward": 350, "kind": "coins"},
        {"id": "mo2", "name": "Capai jarak 20000m", "target": 20000, "progress": 0, "type": "month", "reward": 450, "kind": "distance"},
        {"id": "mo3", "name": "Kalahkan 150 musuh", "target": 150, "progress": 0, "type": "month", "reward": 550, "kind": "enemies"}
    ]
    coins_collected = 0
    max_distance = 0
    enemies_killed = 0
    jumps_total = 0
    runs_played = 0
    skills_collected = 0
    shield_skills_collected = 0
    double_coins_skills_collected = 0
    challenge_kill_level = 1
    challenge_base_enemies = 0
    challenge_coins_level = 1
    challenge_base_coins = 0
    challenge_distance_level = 1
    challenge_base_distance = 0
    challenge_shield_level = 1
    challenge_base_shield = 0
    challenge_double_coins_level = 1
    challenge_base_double_coins = 0
    mission_reward_claimed.clear()
    _set_challenge_missions_in_memory()
    _refresh_all_mission_progress()
    _save()


func _infer_kind_from_name(mname: String) -> String:
    if mname.begins_with("Kumpulkan"):
        return "coins"
    if mname.begins_with("Capai jarak"):
        return "distance"
    if mname.begins_with("Kalahkan"):
        return "enemies"
    if mname.begins_with("Lompat"):
        return "jumps"
    if mname.begins_with("Mainkan"):
        return "runs"
    if mname.begins_with("Dapatkan"):
        return "skills"
    return ""


func _ensure_missions_upgraded() -> void:
    var ids := {}
    var seen_ids := {}
    var filtered: Array = []
    for m in missions:
        if not (m is Dictionary):
            continue
        var id_str := String(m.get("id", ""))
        if not id_str.is_empty():
            ids[id_str] = true
            if seen_ids.has(id_str):
                continue
            seen_ids[id_str] = true
        if id_str == "m6":
            if mission_reward_claimed.has("m6"):
                mission_reward_claimed.erase("m6")
            continue
        if not m.has("type"):
            m["type"] = "daily"
        if not m.has("reward"):
            m["reward"] = 0
        var mt: String = String(m.get("type", "daily"))
        if mt == "challenge":
            if mission_reward_claimed.has(id_str):
                mission_reward_claimed.erase(id_str)
            continue
        match id_str:
            "m1":
                m["name"] = "Kumpulkan 50 koin"
                m["target"] = 50
                m["type"] = "daily"
                m["reward"] = 25
                m["kind"] = "coins"
            "m2":
                m["name"] = "Dapatkan 1 skill"
                m["target"] = 1
                m["type"] = "daily"
                m["reward"] = 30
                m["kind"] = "skills"
            "m3":
                m["name"] = "Lompat 50 kali"
                m["target"] = 50
                m["type"] = "daily"
                m["reward"] = 35
                m["kind"] = "jumps"
            "m4":
                m["name"] = "Kalahkan 5 musuh"
                m["target"] = 5
                m["type"] = "daily"
                m["reward"] = 40
                m["kind"] = "enemies"
            "m5":
                m["name"] = "Capai jarak 1000m"
                m["target"] = 1000
                m["type"] = "daily"
                m["reward"] = 45
                m["kind"] = "distance"
            "ms1":
                m["name"] = "Kumpulkan 200 koin"
                m["target"] = 200
                m["type"] = "mission"
                m["reward"] = 70
                m["kind"] = "coins"
            "ms2":
                m["name"] = "Dapatkan 3 skill"
                m["target"] = 3
                m["type"] = "mission"
                m["reward"] = 90
                m["kind"] = "skills"
            "ms3":
                m["name"] = "Lompat 200 kali"
                m["target"] = 200
                m["type"] = "mission"
                m["reward"] = 120
                m["kind"] = "jumps"
            "ms4":
                m["name"] = "Kalahkan 20 musuh"
                m["target"] = 20
                m["type"] = "mission"
                m["reward"] = 140
                m["kind"] = "enemies"
            "w1":
                m["name"] = "Kumpulkan 1000 koin"
                m["target"] = 1000
                m["type"] = "week"
                m["reward"] = 150
                m["kind"] = "coins"
            "w2":
                m["name"] = "Dapatkan 10 skill"
                m["target"] = 10
                m["type"] = "week"
                m["reward"] = 200
                m["kind"] = "skills"
            "w3":
                m["name"] = "Mainkan 20 run"
                m["target"] = 20
                m["type"] = "week"
                m["reward"] = 260
                m["kind"] = "runs"
            "w4":
                m["name"] = "Kalahkan 60 musuh"
                m["target"] = 60
                m["type"] = "week"
                m["reward"] = 300
                m["kind"] = "enemies"
            "mo1":
                m["name"] = "Kumpulkan 5000 koin"
                m["target"] = 5000
                m["type"] = "month"
                m["reward"] = 350
                m["kind"] = "coins"
            "mo2":
                m["name"] = "Capai jarak 20000m"
                m["target"] = 20000
                m["type"] = "month"
                m["reward"] = 450
                m["kind"] = "distance"
            "mo3":
                m["name"] = "Kalahkan 150 musuh"
                m["target"] = 150
                m["type"] = "month"
                m["reward"] = 550
                m["kind"] = "enemies"
            _:
                pass

        if not m.has("kind") or String(m.get("kind", "")).is_empty():
            var inferred := _infer_kind_from_name(String(m.get("name", "")))
            if not inferred.is_empty():
                m["kind"] = inferred
        filtered.append(m)
    missions = filtered
    if not ids.has("m5"):
        missions.append({"id": "m5", "name": "Capai jarak 1000m", "target": 1000, "progress": 0, "type": "daily", "reward": 45, "kind": "distance"})
    if not ids.has("ms1"):
        missions.append({"id": "ms1", "name": "Kumpulkan 200 koin", "target": 200, "progress": 0, "type": "mission", "reward": 70, "kind": "coins"})
    if not ids.has("ms2"):
        missions.append({"id": "ms2", "name": "Dapatkan 3 skill", "target": 3, "progress": 0, "type": "mission", "reward": 90, "kind": "skills"})
    if not ids.has("ms3"):
        missions.append({"id": "ms3", "name": "Lompat 200 kali", "target": 200, "progress": 0, "type": "mission", "reward": 120, "kind": "jumps"})
    if not ids.has("ms4"):
        missions.append({"id": "ms4", "name": "Kalahkan 20 musuh", "target": 20, "progress": 0, "type": "mission", "reward": 140, "kind": "enemies"})
    if not ids.has("w1"):
        missions.append({"id": "w1", "name": "Kumpulkan 1000 koin", "target": 1000, "progress": 0, "type": "week", "reward": 150, "kind": "coins"})
    if not ids.has("w2"):
        missions.append({"id": "w2", "name": "Dapatkan 10 skill", "target": 10, "progress": 0, "type": "week", "reward": 200, "kind": "skills"})
    if not ids.has("w3"):
        missions.append({"id": "w3", "name": "Mainkan 20 run", "target": 20, "progress": 0, "type": "week", "reward": 260, "kind": "runs"})
    if not ids.has("w4"):
        missions.append({"id": "w4", "name": "Kalahkan 60 musuh", "target": 60, "progress": 0, "type": "week", "reward": 300, "kind": "enemies"})
    if not ids.has("mo1"):
        missions.append({"id": "mo1", "name": "Kumpulkan 5000 koin", "target": 5000, "progress": 0, "type": "month", "reward": 350, "kind": "coins"})
    if not ids.has("mo2"):
        missions.append({"id": "mo2", "name": "Capai jarak 20000m", "target": 20000, "progress": 0, "type": "month", "reward": 450, "kind": "distance"})
    if not ids.has("mo3"):
        missions.append({"id": "mo3", "name": "Kalahkan 150 musuh", "target": 150, "progress": 0, "type": "month", "reward": 550, "kind": "enemies"})
    for m in missions:
        if not (m is Dictionary):
            continue
        if not m.has("reward"):
            m["reward"] = 0
        var mt2: String = String(m.get("type", "daily"))
        if mt2 != "challenge":
            var kind2: String = String(m.get("kind", ""))
            if kind2.is_empty():
                var inferred2 := _infer_kind_from_name(String(m.get("name", "")))
                if not inferred2.is_empty():
                    m["kind"] = inferred2
    if challenge_kill_level < 1:
        challenge_kill_level = 1
    if challenge_base_enemies < 0:
        challenge_base_enemies = 0
    if challenge_base_enemies > enemies_killed:
        challenge_base_enemies = enemies_killed
    if challenge_coins_level < 1:
        challenge_coins_level = 1
    if challenge_base_coins < 0:
        challenge_base_coins = 0
    if challenge_base_coins > coins_collected:
        challenge_base_coins = coins_collected

    if challenge_distance_level < 1:
        challenge_distance_level = 1
    if challenge_base_distance < 0:
        challenge_base_distance = 0
    if challenge_base_distance > max_distance:
        challenge_base_distance = max_distance

    if challenge_shield_level < 1:
        challenge_shield_level = 1
    if challenge_base_shield < 0:
        challenge_base_shield = 0
    if challenge_base_shield > shield_skills_collected:
        challenge_base_shield = shield_skills_collected

    if challenge_double_coins_level < 1:
        challenge_double_coins_level = 1
    if challenge_base_double_coins < 0:
        challenge_base_double_coins = 0
    if challenge_base_double_coins > double_coins_skills_collected:
        challenge_base_double_coins = double_coins_skills_collected

    _set_challenge_missions_in_memory()
    _refresh_all_mission_progress()
    _save()


func _challenge_kill_target_for_abs_level(abs_level: int) -> int:
    var tiers: Array[int] = [1, 5, 10, 20, 30, 50, 75, 100, 150, 200]
    if abs_level < 1:
        abs_level = 1
    if abs_level <= tiers.size():
        return tiers[abs_level - 1]
    return tiers[tiers.size() - 1] + (abs_level - tiers.size()) * 50


func _challenge_kill_reward_for_abs_level(abs_level: int) -> int:
    var tiers: Array[int] = [200, 250, 300, 400, 500, 650, 800, 950, 1100, 1300]
    if abs_level < 1:
        abs_level = 1
    if abs_level <= tiers.size():
        return tiers[abs_level - 1]
    return tiers[tiers.size() - 1] + (abs_level - tiers.size()) * 150


func _challenge_coins_target_for_abs_level(abs_level: int) -> int:
    var tiers: Array[int] = [100, 250, 500, 1000, 2000, 3000, 5000, 7500, 10000, 15000]
    if abs_level < 1:
        abs_level = 1
    if abs_level <= tiers.size():
        return tiers[abs_level - 1]
    return tiers[tiers.size() - 1] + (abs_level - tiers.size()) * 2500


func _challenge_distance_target_for_abs_level(abs_level: int) -> int:
    var tiers: Array[int] = [500, 1000, 2000, 3000, 5000, 7500, 10000, 15000, 20000, 30000]
    if abs_level < 1:
        abs_level = 1
    if abs_level <= tiers.size():
        return tiers[abs_level - 1]
    return tiers[tiers.size() - 1] + (abs_level - tiers.size()) * 5000


func _challenge_powerup_target_for_abs_level(abs_level: int) -> int:
    var tiers: Array[int] = [1, 2, 3, 5, 7, 10, 15, 20, 25, 30]
    if abs_level < 1:
        abs_level = 1
    if abs_level <= tiers.size():
        return tiers[abs_level - 1]
    return tiers[tiers.size() - 1] + (abs_level - tiers.size()) * 5


func _challenge_generic_reward_for_abs_level(abs_level: int) -> int:
    var tiers: Array[int] = [200, 250, 300, 400, 500, 650, 800, 950, 1100, 1300]
    if abs_level < 1:
        abs_level = 1
    if abs_level <= tiers.size():
        return tiers[abs_level - 1]
    return tiers[tiers.size() - 1] + (abs_level - tiers.size()) * 150


func _set_challenge_missions_in_memory() -> void:
    if mission_reward_claimed.has("ck"):
        mission_reward_claimed.erase("ck")
    if mission_reward_claimed.has("cc"):
        mission_reward_claimed.erase("cc")
    if mission_reward_claimed.has("cd"):
        mission_reward_claimed.erase("cd")
    if mission_reward_claimed.has("csh"):
        mission_reward_claimed.erase("csh")
    if mission_reward_claimed.has("cdc"):
        mission_reward_claimed.erase("cdc")
    for k in range(1, 11):
        var key := "ck" + str(k)
        if mission_reward_claimed.has(key):
            mission_reward_claimed.erase(key)
    if mission_reward_claimed.has("c1"):
        mission_reward_claimed.erase("c1")
    if mission_reward_claimed.has("c2"):
        mission_reward_claimed.erase("c2")
    if mission_reward_claimed.has("c3"):
        mission_reward_claimed.erase("c3")
    for i in range(missions.size() - 1, -1, -1):
        var m_any = missions[i]
        if not (m_any is Dictionary):
            continue
        var m: Dictionary = m_any
        if String(m.get("type", "")) == "challenge":
            missions.remove_at(i)

    var kill_target := _challenge_kill_target_for_abs_level(challenge_kill_level)
    missions.append({
        "id": "ck",
        "name": "Kalahkan %d musuh" % kill_target,
        "target": kill_target,
        "progress": 0,
        "type": "challenge",
        "reward": _challenge_kill_reward_for_abs_level(challenge_kill_level)
    })

    var shield_target := _challenge_powerup_target_for_abs_level(challenge_shield_level)
    missions.append({
        "id": "csh",
        "name": "Dapatkan Shield %d kali" % shield_target,
        "target": shield_target,
        "progress": 0,
        "type": "challenge",
        "reward": _challenge_generic_reward_for_abs_level(challenge_shield_level)
    })

    var double_target := _challenge_powerup_target_for_abs_level(challenge_double_coins_level)
    missions.append({
        "id": "cdc",
        "name": "Dapatkan DoubleCoins %d kali" % double_target,
        "target": double_target,
        "progress": 0,
        "type": "challenge",
        "reward": _challenge_generic_reward_for_abs_level(challenge_double_coins_level)
    })

    var coins_target := _challenge_coins_target_for_abs_level(challenge_coins_level)
    missions.append({
        "id": "cc",
        "name": "Kumpulkan %d koin" % coins_target,
        "target": coins_target,
        "progress": 0,
        "type": "challenge",
        "reward": _challenge_generic_reward_for_abs_level(challenge_coins_level)
    })

    var dist_target := _challenge_distance_target_for_abs_level(challenge_distance_level)
    missions.append({
        "id": "cd",
        "name": "Capai jarak %dm" % dist_target,
        "target": dist_target,
        "progress": 0,
        "type": "challenge",
        "reward": _challenge_generic_reward_for_abs_level(challenge_distance_level)
    })


func reset_daily_missions() -> void:
    _reset_missions_of_type("daily", true)


func reset_weekly_missions() -> void:
    _reset_missions_of_type("week", true)


func reset_monthly_missions() -> void:
    _reset_missions_of_type("month", true)


func _get_reset_interval_sec(t: String) -> int:
    match t:
        "daily":
            return 24 * 60 * 60
        "week":
            return 7 * 24 * 60 * 60
        "month":
            return 30 * 24 * 60 * 60
        _:
            return 0


func _get_last_reset(t: String) -> int:
    match t:
        "daily":
            return last_reset_daily
        "week":
            return last_reset_week
        "month":
            return last_reset_month
        _:
            return 0


func _initialize_type_reset_if_missing(t: String, now: int) -> bool:
    if _get_last_reset(t) > 0:
        return false
    _set_type_baselines_to_current(t)
    _reset_type_max_distance(t)
    _set_last_reset(t, now)
    return true


func _apply_time_reset_for_type(t: String, interval: int, now: int) -> bool:
    if interval <= 0:
        return false
    if _initialize_type_reset_if_missing(t, now):
        return true
    var last := _get_last_reset(t)
    if now - last >= interval:
        _reset_missions_of_type(t, false, now)
        return true
    return false


func _apply_time_resets_if_needed() -> void:
    var now: int = int(Time.get_unix_time_from_system())
    var changed := false
    var types: Array[String] = ["daily", "week", "month"]
    for t in types:
        var interval := _get_reset_interval_sec(t)
        if _apply_time_reset_for_type(t, interval, now):
            changed = true

    if changed:
        _refresh_all_mission_progress()
        _save()


func _reset_missions_of_type(t: String, save_after: bool, now_override: int = -1) -> void:
    var now: int = now_override
    if now <= 0:
        now = int(Time.get_unix_time_from_system())

    var ids_to_clear: Array[String] = []
    for m_any in missions:
        if not (m_any is Dictionary):
            continue
        var m: Dictionary = m_any
        var mt: String = String(m.get("type", "daily"))
        if mt == t:
            m["progress"] = 0
            var mid: String = String(m.get("id", ""))
            if not mid.is_empty():
                ids_to_clear.append(mid)
    for mid in ids_to_clear:
        if mission_reward_claimed.has(mid):
            mission_reward_claimed.erase(mid)

    if t == "daily":
        daily_all_reward_claimed = false

    _set_type_baselines_to_current(t)
    _reset_type_max_distance(t)
    _set_last_reset(t, now)

    if save_after:
        _save()
        refresh_ready_to_claim_state()


func _set_last_reset(t: String, now: int) -> void:
    match t:
        "daily":
            last_reset_daily = now
        "week":
            last_reset_week = now
        "month":
            last_reset_month = now
        _:
            pass


func _set_type_baselines_to_current(t: String) -> void:
    match t:
        "daily":
            daily_base_coins = coins_collected
            daily_base_enemies = enemies_killed
            daily_base_jumps = jumps_total
            daily_base_runs = runs_played
            daily_base_skills = skills_collected
            daily_base_distance = current_run_distance
        "week":
            week_base_coins = coins_collected
            week_base_enemies = enemies_killed
            week_base_jumps = jumps_total
            week_base_runs = runs_played
            week_base_skills = skills_collected
            week_base_distance = current_run_distance
        "month":
            month_base_coins = coins_collected
            month_base_enemies = enemies_killed
            month_base_jumps = jumps_total
            month_base_runs = runs_played
            month_base_skills = skills_collected
            month_base_distance = current_run_distance
        _:
            pass


func _reset_type_max_distance(t: String) -> void:
    match t:
        "daily":
            daily_max_distance = 0
        "week":
            week_max_distance = 0
        "month":
            month_max_distance = 0
        _:
            pass


func _get_base_value_for_type(t: String, kind: String) -> int:
    match t:
        "challenge":
            match kind:
                "enemies":
                    return challenge_base_enemies
                _:
                    return 0
        "daily":
            match kind:
                "coins":
                    return daily_base_coins
                "enemies":
                    return daily_base_enemies
                "jumps":
                    return daily_base_jumps
                "runs":
                    return daily_base_runs
                "skills":
                    return daily_base_skills
                _:
                    return 0
        "week":
            match kind:
                "coins":
                    return week_base_coins
                "enemies":
                    return week_base_enemies
                "jumps":
                    return week_base_jumps
                "runs":
                    return week_base_runs
                "skills":
                    return week_base_skills
                _:
                    return 0
        "month":
            match kind:
                "coins":
                    return month_base_coins
                "enemies":
                    return month_base_enemies
                "jumps":
                    return month_base_jumps
                "runs":
                    return month_base_runs
                "skills":
                    return month_base_skills
                _:
                    return 0
        _:
            return 0


func _get_distance_progress_for_type(t: String) -> int:
    match t:
        "daily":
            return daily_max_distance
        "week":
            return week_max_distance
        "month":
            return month_max_distance
        _:
            return max_distance


func _update_mission_progress_from_counters(m: Dictionary) -> void:
    var mt: String = String(m.get("type", "daily"))
    if mt == "challenge":
        var mid: String = String(m.get("id", ""))
        match mid:
            "ck":
                m["progress"] = max(enemies_killed - challenge_base_enemies, 0)
            "cc":
                m["progress"] = max(coins_collected - challenge_base_coins, 0)
            "cd":
                m["progress"] = max(max_distance - challenge_base_distance, 0)
            "csh":
                m["progress"] = max(shield_skills_collected - challenge_base_shield, 0)
            "cdc":
                m["progress"] = max(double_coins_skills_collected - challenge_base_double_coins, 0)
            _:
                m["progress"] = 0
        return
    var kind: String = String(m.get("kind", ""))
    match kind:
        "coins":
            var base := _get_base_value_for_type(mt, "coins")
            m["progress"] = max(coins_collected - base, 0)
        "distance":
            m["progress"] = max(_get_distance_progress_for_type(mt), 0)
        "enemies":
            var base2 := _get_base_value_for_type(mt, "enemies")
            m["progress"] = max(enemies_killed - base2, 0)
        "jumps":
            var base3 := _get_base_value_for_type(mt, "jumps")
            m["progress"] = max(jumps_total - base3, 0)
        "runs":
            var base4 := _get_base_value_for_type(mt, "runs")
            m["progress"] = max(runs_played - base4, 0)
        "skills":
            var base5 := _get_base_value_for_type(mt, "skills")
            m["progress"] = max(skills_collected - base5, 0)
        _:
            var mname: String = String(m.get("name", ""))
            if mname.begins_with("Kumpulkan"):
                var base6 := _get_base_value_for_type(mt, "coins")
                m["progress"] = max(coins_collected - base6, 0)
            elif mname.begins_with("Capai jarak"):
                m["progress"] = max(_get_distance_progress_for_type(mt), 0)
            elif mname.begins_with("Kalahkan"):
                var base7 := _get_base_value_for_type(mt, "enemies")
                m["progress"] = max(enemies_killed - base7, 0)
            elif mname.begins_with("Lompat"):
                var base8 := _get_base_value_for_type(mt, "jumps")
                m["progress"] = max(jumps_total - base8, 0)
            elif mname.begins_with("Mainkan"):
                var base9 := _get_base_value_for_type(mt, "runs")
                m["progress"] = max(runs_played - base9, 0)
            elif mname.begins_with("Dapatkan"):
                var base10 := _get_base_value_for_type(mt, "skills")
                m["progress"] = max(skills_collected - base10, 0)


func _refresh_all_mission_progress() -> void:
    for m_any in missions:
        if not (m_any is Dictionary):
            continue
        var m: Dictionary = m_any
        var id_str := String(m.get("id", ""))
        var mt: String = String(m.get("type", "daily"))
        var reward: int = int(m.get("reward", 0))
        var target: float = float(m.get("target", 0))
        var prev_prog: float = float(m.get("progress", 0))
        var eligible := (reward > 0) and (target > 0.0) and (not id_str.is_empty())
        if eligible and mt != "challenge":
            if mission_reward_claimed.has(id_str) and bool(mission_reward_claimed[id_str]):
                eligible = false

        _update_mission_progress_from_counters(m)

        if eligible:
            var new_prog: float = float(m.get("progress", 0))
            if prev_prog < target and new_prog >= target:
                mission_became_ready.emit(id_str, String(m.get("name", "")))

func add_coins(n: int) -> void:
    coins_collected += n
    _refresh_all_mission_progress()
    _request_save()
    refresh_ready_to_claim_state()


func update_distance(d: float) -> void:
    var di := int(round(d))
    var changed := false
    if di < current_run_distance:
        daily_base_distance = 0
        week_base_distance = 0
        month_base_distance = 0
    current_run_distance = di
    if di > max_distance:
        max_distance = di
        changed = true
    var daily_delta: int = maxi(di - daily_base_distance, 0)
    if daily_delta > daily_max_distance:
        daily_max_distance = daily_delta
        changed = true
    var week_delta: int = maxi(di - week_base_distance, 0)
    if week_delta > week_max_distance:
        week_max_distance = week_delta
        changed = true
    var month_delta: int = maxi(di - month_base_distance, 0)
    if month_delta > month_max_distance:
        month_max_distance = month_delta
        changed = true
    if changed:
        _refresh_all_mission_progress()
        _request_save()
        refresh_ready_to_claim_state()


func add_enemy_kill() -> void:
    if enemies_killed < 0:
        enemies_killed = 0
    enemies_killed += 1
    _refresh_all_mission_progress()
    _request_save()
    refresh_ready_to_claim_state()


func add_jump() -> void:
    if jumps_total < 0:
        jumps_total = 0
    jumps_total += 1
    _refresh_all_mission_progress()
    _request_save()
    refresh_ready_to_claim_state()


func add_run_played() -> void:
    if runs_played < 0:
        runs_played = 0
    runs_played += 1
    _refresh_all_mission_progress()
    _request_save()
    refresh_ready_to_claim_state()


func add_skill() -> void:
    if skills_collected < 0:
        skills_collected = 0
    skills_collected += 1
    _refresh_all_mission_progress()
    _request_save()
    refresh_ready_to_claim_state()


func add_shield_skill() -> void:
    if shield_skills_collected < 0:
        shield_skills_collected = 0
    shield_skills_collected += 1
    _refresh_all_mission_progress()
    _request_save()
    refresh_ready_to_claim_state()


func add_double_coins_skill() -> void:
    if double_coins_skills_collected < 0:
        double_coins_skills_collected = 0
    double_coins_skills_collected += 1
    _refresh_all_mission_progress()
    _request_save()
    refresh_ready_to_claim_state()


func get_missions_text() -> String:
    var lines := []
    for m in missions:
        var prog := int(m.progress)
        var tgt := int(m.target)
        var mname: String = String(m.name)
        var rw := 0
        if m is Dictionary and m.has("reward"):
            rw = int(m.reward)
        lines.append(mname + " (" + str(min(prog, tgt)) + "/" + str(tgt) + ") +" + str(rw) + "c")
    return "\n".join(lines)


func get_mission_type(mission_id: String) -> String:
    if mission_id.is_empty():
        return ""
    for m_any in missions:
        if not (m_any is Dictionary):
            continue
        var m: Dictionary = m_any
        if String(m.get("id", "")) == mission_id:
            return String(m.get("type", "daily"))
    return ""


func get_type_title(t: String) -> String:
    match t:
        "daily":
            return tr("Daily")
        "mission":
            return tr("Missions")
        "week":
            return tr("Week")
        "month":
            return tr("Month")
        "challenge":
            return tr("Challenge")
        _:
            if t.is_empty():
                return tr("Missions")
            return tr(t.substr(0, 1).to_upper() + t.substr(1))


func is_type_fully_completed(t: String) -> bool:
    if t.is_empty():
        return false
    var any: bool = false
    for m_any in missions:
        if not (m_any is Dictionary):
            continue
        var m: Dictionary = m_any
        if String(m.get("type", "daily")) != t:
            continue
        any = true
        var target: float = float(m.get("target", 0))
        if target <= 0.0:
            return false
        var prog: float = float(m.get("progress", 0))
        if prog < target:
            return false
    return any


func get_ingame_missions_text() -> String:
    var grouped: Dictionary = {}
    var order: Array[String] = ["daily", "mission", "week", "month", "challenge"]
    var extra_types: Array[String] = []
    for m_any in missions:
        if not (m_any is Dictionary):
            continue
        var m: Dictionary = m_any
        var t: String = String(m.get("type", "daily"))
        if not grouped.has(t):
            grouped[t] = []
            if not order.has(t):
                extra_types.append(t)
        (grouped[t] as Array).append(m)

    var types: Array[String] = []
    for t2 in order:
        if grouped.has(t2):
            types.append(t2)
    for t3 in extra_types:
        types.append(t3)

    var out_lines: Array[String] = []
    for t4 in types:
        var arr: Array = grouped.get(t4, [])
        var total: int = 0
        var done: int = 0
        var claimable: int = 0
        for m_any2 in arr:
            if not (m_any2 is Dictionary):
                continue
            var m2: Dictionary = m_any2
            total += 1
            var target: float = float(m2.get("target", 0))
            var prog: float = float(m2.get("progress", 0))
            var completed: bool = target > 0.0 and prog >= target
            if completed:
                done += 1
            var rw: int = int(m2.get("reward", 0))
            var id_str: String = String(m2.get("id", ""))
            var claimed: bool = false
            if t4 != "challenge" and not id_str.is_empty():
                if mission_reward_claimed.has(id_str) and bool(mission_reward_claimed[id_str]):
                    claimed = true
            var ready_claim: bool = completed and rw > 0 and (t4 == "challenge" or not claimed)
            if ready_claim:
                claimable += 1

        var header := get_type_title(t4) + ": " + str(done) + "/" + str(total) + " selesai"
        if claimable > 0 and t4 != "challenge":
            header += " | " + str(claimable) + " siap claim"
        out_lines.append(header)

        for m_any3 in arr:
            if not (m_any3 is Dictionary):
                continue
            var m3: Dictionary = m_any3
            var mission_name: String = String(m3.get("name", ""))
            var target_i: int = int(float(m3.get("target", 0)))
            var prog_i: int = int(float(m3.get("progress", 0)))
            var rw_i: int = int(m3.get("reward", 0))
            var completed2: bool = target_i > 0 and prog_i >= target_i
            var id_str2: String = String(m3.get("id", ""))
            var claimed2: bool = false
            if t4 != "challenge" and not id_str2.is_empty():
                if mission_reward_claimed.has(id_str2) and bool(mission_reward_claimed[id_str2]):
                    claimed2 = true
            var ready_claim2: bool = completed2 and rw_i > 0 and (t4 == "challenge" or not claimed2)
            var prefix := ("✓" if completed2 else "•")
            var suffix := ""
            if ready_claim2:
                suffix = " [CLAIM]"
            elif completed2 and claimed2:
                suffix = " [SUDAH]"
            out_lines.append(prefix + " " + mission_name + " (" + str(min(prog_i, target_i)) + "/" + str(target_i) + ") +" + str(rw_i) + "c" + suffix)
        out_lines.append("")

    if out_lines.size() > 0 and out_lines[out_lines.size() - 1].is_empty():
        out_lines.remove_at(out_lines.size() - 1)
    return "\n".join(out_lines)

func _load() -> void:
    var cfg := ConfigFile.new()
    var err := cfg.load("user://save.cfg")
    if err == OK:
        coins_collected = int(cfg.get_value("missions", "coins_collected", 0))
        max_distance = int(cfg.get_value("missions", "max_distance", 0))
        current_run_distance = int(cfg.get_value("missions", "current_run_distance", 0))
        enemies_killed = int(cfg.get_value("missions", "enemies_killed", 0))
        jumps_total = int(cfg.get_value("missions", "jumps_total", 0))
        runs_played = int(cfg.get_value("missions", "runs_played", 0))
        skills_collected = int(cfg.get_value("missions", "skills_collected", 0))
        shield_skills_collected = int(cfg.get_value("missions", "shield_skills_collected", 0))
        double_coins_skills_collected = int(cfg.get_value("missions", "double_coins_skills_collected", 0))

        last_reset_daily = int(cfg.get_value("missions", "last_reset_daily", 0))
        last_reset_week = int(cfg.get_value("missions", "last_reset_week", 0))
        last_reset_month = int(cfg.get_value("missions", "last_reset_month", 0))

        daily_base_coins = int(cfg.get_value("missions", "base_daily_coins", 0))
        daily_base_enemies = int(cfg.get_value("missions", "base_daily_enemies", 0))
        daily_base_jumps = int(cfg.get_value("missions", "base_daily_jumps", 0))
        daily_base_runs = int(cfg.get_value("missions", "base_daily_runs", 0))
        daily_base_skills = int(cfg.get_value("missions", "base_daily_skills", 0))
        daily_base_distance = int(cfg.get_value("missions", "base_daily_distance", 0))
        daily_max_distance = int(cfg.get_value("missions", "daily_max_distance", 0))

        week_base_coins = int(cfg.get_value("missions", "base_week_coins", 0))
        week_base_enemies = int(cfg.get_value("missions", "base_week_enemies", 0))
        week_base_jumps = int(cfg.get_value("missions", "base_week_jumps", 0))
        week_base_runs = int(cfg.get_value("missions", "base_week_runs", 0))
        week_base_skills = int(cfg.get_value("missions", "base_week_skills", 0))
        week_base_distance = int(cfg.get_value("missions", "base_week_distance", 0))
        week_max_distance = int(cfg.get_value("missions", "week_max_distance", 0))

        month_base_coins = int(cfg.get_value("missions", "base_month_coins", 0))
        month_base_enemies = int(cfg.get_value("missions", "base_month_enemies", 0))
        month_base_jumps = int(cfg.get_value("missions", "base_month_jumps", 0))
        month_base_runs = int(cfg.get_value("missions", "base_month_runs", 0))
        month_base_skills = int(cfg.get_value("missions", "base_month_skills", 0))
        month_base_distance = int(cfg.get_value("missions", "base_month_distance", 0))
        month_max_distance = int(cfg.get_value("missions", "month_max_distance", 0))

        challenge_kill_level = int(cfg.get_value("missions", "challenge_kill_level", 1))
        challenge_base_enemies = int(cfg.get_value("missions", "challenge_base_enemies", 0))

        challenge_coins_level = int(cfg.get_value("missions", "challenge_coins_level", 1))
        challenge_base_coins = int(cfg.get_value("missions", "challenge_base_coins", 0))
        challenge_distance_level = int(cfg.get_value("missions", "challenge_distance_level", 1))
        challenge_base_distance = int(cfg.get_value("missions", "challenge_base_distance", 0))
        challenge_shield_level = int(cfg.get_value("missions", "challenge_shield_level", 1))
        challenge_base_shield = int(cfg.get_value("missions", "challenge_base_shield", 0))
        challenge_double_coins_level = int(cfg.get_value("missions", "challenge_double_coins_level", 1))
        challenge_base_double_coins = int(cfg.get_value("missions", "challenge_base_double_coins", 0))

        var ms: Array = cfg.get_value("missions", "list", [])
        if ms is Array:
            missions = ms
        var claimed_value = cfg.get_value("missions", "reward_claimed", {})
        if claimed_value is Dictionary:
            mission_reward_claimed = claimed_value
        else:
            mission_reward_claimed.clear()

        daily_all_reward_claimed = bool(cfg.get_value("missions", "daily_all_reward_claimed", false))

    _refresh_all_mission_progress()

func _save() -> void:
    var cfg := ConfigFile.new()
    var err := cfg.load("user://save.cfg")
    if err != OK:
        cfg = ConfigFile.new()
    cfg.set_value("missions", "coins_collected", coins_collected)
    cfg.set_value("missions", "max_distance", max_distance)
    cfg.set_value("missions", "current_run_distance", current_run_distance)
    cfg.set_value("missions", "enemies_killed", enemies_killed)
    cfg.set_value("missions", "jumps_total", jumps_total)
    cfg.set_value("missions", "runs_played", runs_played)
    cfg.set_value("missions", "skills_collected", skills_collected)
    cfg.set_value("missions", "shield_skills_collected", shield_skills_collected)
    cfg.set_value("missions", "double_coins_skills_collected", double_coins_skills_collected)

    cfg.set_value("missions", "last_reset_daily", last_reset_daily)
    cfg.set_value("missions", "last_reset_week", last_reset_week)
    cfg.set_value("missions", "last_reset_month", last_reset_month)

    cfg.set_value("missions", "base_daily_coins", daily_base_coins)
    cfg.set_value("missions", "base_daily_enemies", daily_base_enemies)
    cfg.set_value("missions", "base_daily_jumps", daily_base_jumps)
    cfg.set_value("missions", "base_daily_runs", daily_base_runs)
    cfg.set_value("missions", "base_daily_skills", daily_base_skills)
    cfg.set_value("missions", "base_daily_distance", daily_base_distance)
    cfg.set_value("missions", "daily_max_distance", daily_max_distance)

    cfg.set_value("missions", "base_week_coins", week_base_coins)
    cfg.set_value("missions", "base_week_enemies", week_base_enemies)
    cfg.set_value("missions", "base_week_jumps", week_base_jumps)
    cfg.set_value("missions", "base_week_runs", week_base_runs)
    cfg.set_value("missions", "base_week_skills", week_base_skills)
    cfg.set_value("missions", "base_week_distance", week_base_distance)
    cfg.set_value("missions", "week_max_distance", week_max_distance)

    cfg.set_value("missions", "base_month_coins", month_base_coins)
    cfg.set_value("missions", "base_month_enemies", month_base_enemies)
    cfg.set_value("missions", "base_month_jumps", month_base_jumps)
    cfg.set_value("missions", "base_month_runs", month_base_runs)
    cfg.set_value("missions", "base_month_skills", month_base_skills)
    cfg.set_value("missions", "base_month_distance", month_base_distance)
    cfg.set_value("missions", "month_max_distance", month_max_distance)

    cfg.set_value("missions", "challenge_kill_level", challenge_kill_level)
    cfg.set_value("missions", "challenge_base_enemies", challenge_base_enemies)

    cfg.set_value("missions", "challenge_coins_level", challenge_coins_level)
    cfg.set_value("missions", "challenge_base_coins", challenge_base_coins)
    cfg.set_value("missions", "challenge_distance_level", challenge_distance_level)
    cfg.set_value("missions", "challenge_base_distance", challenge_base_distance)
    cfg.set_value("missions", "challenge_shield_level", challenge_shield_level)
    cfg.set_value("missions", "challenge_base_shield", challenge_base_shield)
    cfg.set_value("missions", "challenge_double_coins_level", challenge_double_coins_level)
    cfg.set_value("missions", "challenge_base_double_coins", challenge_base_double_coins)

    cfg.set_value("missions", "list", missions)
    cfg.set_value("missions", "reward_claimed", mission_reward_claimed)
    cfg.set_value("missions", "daily_all_reward_claimed", daily_all_reward_claimed)
    cfg.save("user://save.cfg")


func reload_from_save() -> void:
    _load()
    if missions.is_empty():
        _init_default()
    else:
        _ensure_missions_upgraded()
    _apply_time_resets_if_needed()
    refresh_ready_to_claim_state(false)
