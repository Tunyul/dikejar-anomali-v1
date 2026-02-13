extends ParallaxBackground

@export var speed: float = 300.0 # pixels per second
@export var snap_px: float = 0.0
@export var use_smooth_scrolling: bool = true
@export var wrap_width: float = 0.0

var current_speed: float = 0.0

func _ready() -> void:
    # Matikan follow_viewport_enabled agar pergerakan manual via scroll_offset
    # tidak ditimpa oleh posisi Camera2D di scene Main.
    follow_viewport_enabled = false

    # Ambil scene name untuk menentukan behavior awal
    var scene_name = get_tree().current_scene.name
    if scene_name == "Main":
        current_speed = 0.0
    else:
        current_speed = speed

    # Paksa process_mode ke INHERIT untuk memastikan script berjalan
    process_mode = PROCESS_MODE_INHERIT

    # Pastikan semua layer memiliki mirroring agar tidak hilang saat bergerak
    for i in range(get_child_count()):
        var child = get_child(i)
        if child is ParallaxLayer:
            # Gunakan 1024 sebagai default mirroring (sesuai resolusi asset yang di-scale)
            if child.motion_mirroring.x == 0:
                child.motion_mirroring.x = 1024
            # Reset offset awal
            child.motion_offset = Vector2.ZERO

    print("Parallax Initialized: CurrentSpeed=", current_speed, " FollowViewport=", follow_viewport_enabled)

func _process(delta: float) -> void:
    # Parallax bergerak sesuai current_speed
    var move_amount = current_speed * delta

    # Gunakan scroll_base_offset karena ParallaxBackground seringkali
    # bekerja lebih stabil dengan base_offset ketika follow_viewport_enabled dimatikan
    scroll_base_offset.x -= move_amount

    # Debugging setiap 60 frame
    if Engine.get_frames_drawn() % 60 == 0 and current_speed > 0:
        print("Parallax Debug - Speed: ", current_speed, " Scroll Base Offset: ", scroll_base_offset.x)

func set_speed(new_speed: float) -> void:
    current_speed = new_speed
    print("Parallax Speed Changed to: ", current_speed)

func get_layer_speed(layer_index: int = 0) -> float:
    if get_child_count() > layer_index:
        var parallax_layer = get_child(layer_index)
        if parallax_layer is ParallaxLayer:
            return current_speed * parallax_layer.motion_scale.x
    return current_speed
