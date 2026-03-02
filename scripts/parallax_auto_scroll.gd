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

func _exit_tree() -> void:
    set_process(false)
    set_physics_process(false)


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
    var min_width_target: float = 4096.0 # Target width aman (cover 4K screens)

    for i in range(get_child_count()):
        var child = get_child(i)
        if child is ParallaxLayer:
            var sprites: Array[Sprite2D] = []
            for c in child.get_children():
                if c is Sprite2D:
                    sprites.append(c)

            # Logika khusus untuk layer background continuous (biasanya cuma 1 sprite)
            if sprites.size() == 1:
                var sprite = sprites[0]
                if sprite.texture != null:
                    var sprite_w = sprite.texture.get_width() * sprite.scale.x

                    # Jika kurang lebar untuk layar HP modern, duplikasi sprite
                    if sprite_w < min_width_target and sprite_w > 0:
                        var count_needed = ceil(min_width_target / sprite_w)
                        var total_w = sprite_w

                        # Duplikasi sprite untuk memenuhi lebar minimum
                        for n in range(1, int(count_needed)):
                            var dup = sprite.duplicate()
                            dup.position.x = sprite.position.x + (sprite_w * n)
                            child.add_child(dup)
                            total_w += sprite_w

                        child.motion_mirroring.x = total_w
                        print("[Parallax] Layer ", child.name, " extended to width: ", total_w, " (Copies: ", count_needed, ")")

                    # Jika sudah cukup lebar tapi mirroring belum set
                    elif child.motion_mirroring.x == 0:
                        child.motion_mirroring.x = sprite_w

            # Fallback untuk layer kompleks (seperti awan multiple sprites)
            elif child.motion_mirroring.x == 0:
                 # Coba hitung bounding box dari semua children
                 var max_x = 0.0
                 for s in sprites:
                     var right = s.position.x + (s.texture.get_width() * s.scale.x)
                     if right > max_x:
                         max_x = right

                 if max_x > 0:
                     child.motion_mirroring.x = max(max_x, 2048.0)
                 else:
                     child.motion_mirroring.x = 2048.0

            # Reset offset
            child.motion_offset = Vector2.ZERO

    print("[Parallax] System Locked & Initialized: Scene=", scene_name, " Speed=", current_speed)

func _process(delta: float) -> void:
    if not is_inside_tree():
        return

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
    # Hanya log jika terdeteksi masalah (misal: follow_viewport_enabled berubah)
    if follow_viewport_enabled:
        push_warning("[Parallax] WARNING: follow_viewport_enabled terdeteksi TRUE! Memaksa kembali ke FALSE untuk mencegah bug visual.")
        follow_viewport_enabled = false
