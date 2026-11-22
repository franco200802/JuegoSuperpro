extends CanvasLayer

signal retry_pressed

@onready var root: Control = $Root
@onready var hint: Label = $Root/Panel/Box/Hint
@onready var retry_button: Button = $Root/Panel/Box/Retry
@onready var quit_button: Button = $Root/Panel/Box/Quit


func _ready() -> void:
	visible = false
	retry_button.pressed.connect(_on_retry_pressed)
	quit_button.pressed.connect(func() -> void: get_tree().quit())


func open(died_to_boss: bool) -> void:
	hint.text = "Volvés al último farol" if died_to_boss else "Volvés a la última puerta"
	visible = true
	get_tree().paused = true
	root.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(root, "modulate:a", 1.0, 0.3)
	# Se espera al fade para que un salto o ataque apretado justo antes no toque un botón sin querer.
	await tween.finished
	retry_button.grab_focus()


func _on_retry_pressed() -> void:
	visible = false
	get_tree().paused = false
	retry_pressed.emit()
