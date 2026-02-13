# ==============================================================================
# CORE SYSTEM: PARALLAX AUTO SCROLL
# STATUS: LOCKED / PROTECTED
# ==============================================================================
# PERINGATAN: Jangan mengubah logika dasar pergerakan di script ini tanpa
# koordinasi sistem kamera. Perubahan pada follow_viewport_enabled atau
# penggunaan scroll_offset (bukan scroll_base_offset) akan merusak sinkronisasi
# di scene Main.
# ==============================================================================

extends ParallaxBackground

@export_group("Settings")
@export var speed: float = 300.0 # Kecepatan default (pixels per second)
@export var snap_px: float = 0.0
@export var use_smooth_scrolling: bool = true
@export var wrap_width: float = 0.0

# Kecepatan saat ini yang dikontrol oleh Game Manager
var current_speed: float = 0.0 : set = set_speed

func _ready() -> void:
    # CRITICAL: Matikan follow_viewport_enabled.
    # Jika bernilai TRUE, ParallaxBackground akan mencoba mengikuti posisi Camera2D
    # secara otomatis, yang akan menimpa (overwrite) pergerakan manual kita
    # melalui scroll_base_offset.x.
    follow_viewport_enabled = false

    # Penentuan behavior awal berdasarkan scene
    var scene_name = get_tree().current_scene.name
    if scene_name == "Main":
        current_speed = 0.0 # Berhenti saat countdown di scene Main
    else:
        current_speed = speed # Langsung jalan di Main Menu atau scene lain

    # Memastikan script tetap berjalan saat game di-pause jika diperlukan
    # (Saat ini diatur mengikuti parent / INHERIT)
    process_mode = PROCESS_MODE_INHERIT

    # Konfigurasi Layer
    for i in range(get_child_count()):
        var child = get_child(i)
        if child is ParallaxLayer:
            # Mirroring otomatis jika belum diatur di editor
            if child.motion_mirroring.x == 0:
                child.motion_mirroring.x = 1024
            # Reset offset untuk menghindari lompatan posisi saat start
            child.motion_offset = Vector2.ZERO

    print("[Parallax] System Locked & Initialized: Scene=", scene_name, " Speed=", current_speed)

func _process(delta: float) -> void:
    # Pergerakan menggunakan delta agar konsisten di berbagai framerate
    var move_amount = current_speed * delta

    # CRITICAL: Gunakan scroll_base_offset.x
    # scroll_base_offset bekerja secara absolut terhadap koordinat layer,
    # sedangkan scroll_offset bisa dipengaruhi oleh transformasi viewport.
    scroll_base_offset.x -= move_amount

    # Monitor status via console (hanya jika bergerak)
    if Engine.get_frames_drawn() % 120 == 0 and current_speed > 0:
        _verify_system_integrity()

func set_speed(new_speed: float) -> void:
    current_speed = new_speed
    # Opsional: Tambahkan logika akselerasi/smoothing di sini jika ingin transisi halus

func get_layer_speed(layer_index: int = 0) -> float:
    if get_child_count() > layer_index:
        var parallax_layer = get_child(layer_index)
        if parallax_layer is ParallaxLayer:
            return current_speed * parallax_layer.motion_scale.x
    return current_speed

# Fungsi internal untuk memastikan settingan kritis tidak berubah saat runtime
func _verify_system_integrity() -> void:
    if follow_viewport_enabled:
        push_warning("[Parallax] WARNING: follow_viewport_enabled terdeteksi TRUE! Memaksa kembali ke FALSE untuk mencegah bug visual.")
        follow_viewport_enabled = false

    if Engine.get_frames_drawn() % 300 == 0:
        print("[Parallax] Integrity Check OK - Offset: ", int(scroll_base_offset.x))
