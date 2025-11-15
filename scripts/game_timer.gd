extends Control

@export var start_time: float = 0.0
@export var running: bool = false

var elapsed_time: float = 0.0

@onready var timer_label = $Label
@onready var timer = $Timer

func _ready() -> void:
    timer.wait_time = 0.1  # Update every 0.1 seconds
    timer.timeout.connect(_on_timer_timeout)
    update_display()

func _on_timer_timeout() -> void:
    if running:
        elapsed_time += 0.1
        update_display()

func update_display() -> void:
    if timer_label:
        var minutes = int(elapsed_time / 60)
        var seconds = int(elapsed_time) % 60
        var tenths = int((elapsed_time - int(elapsed_time)) * 10)
        timer_label.text = str(minutes).pad_zeros(2) + ":" + str(seconds).pad_zeros(2) + "." + str(tenths)

func start() -> void:
    running = true
    timer.start()

func stop() -> void:
    running = false
    timer.stop()

func reset() -> void:
    elapsed_time = start_time
    update_display()

func set_time(seconds: float) -> void:
    elapsed_time = seconds
    update_display()