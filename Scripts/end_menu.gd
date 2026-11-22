extends CanvasLayer

@onready var root: Control = $Root
@onready var stats: Label = $Root/Panel/Box/Stats
@onready var restart_button: Button = $Root/Panel/Box/Restart
@onready var quit_button: Button = $Root/Panel/Box/Quit


func _ready() -> void:
	visible = false
	restart_button.pressed.connect(_on_restart_pressed)
	quit_button.pressed.connect(func() -> void: get_tree().quit())


func open() -> void:
	var seconds: int = int(GameManager.play_time)
	stats.text = "Tiempo %d:%02d   Muertes %d   Enemigos %d" % [seconds / 60, seconds % 60, GameManager.deaths, GameManager.kills]
	visible = true
	get_tree().paused = true
	root.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(root, "modulate:a", 1.0, 0.4)
	await tween.finished
	restart_button.grab_focus()


func _on_restart_pressed() -> void:
	visible = false
	GameManager.restart_game()
