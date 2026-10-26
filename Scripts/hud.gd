extends CanvasLayer

# Corazones de vida arriba a la izquierda y barra del jefe abajo.

const HEART_FULL := preload("res://Assets/Sprites/Combat/heart_full.png")
const HEART_EMPTY := preload("res://Assets/Sprites/Combat/heart_empty.png")

@onready var hearts: HBoxContainer = $Hearts
@onready var boss_panel: Control = $BossPanel
@onready var boss_name: Label = $BossPanel/Name
@onready var boss_bar: ProgressBar = $BossPanel/Bar


func _ready() -> void:
	boss_panel.visible = false
	GameManager.health_changed.connect(_on_health_changed)
	GameManager.boss_started.connect(_on_boss_started)
	GameManager.boss_health_changed.connect(_on_boss_health_changed)
	GameManager.boss_ended.connect(func() -> void: boss_panel.visible = false)
	get_tree().scene_changed.connect(func() -> void: boss_panel.visible = false)
	_on_health_changed(GameManager.health, GameManager.MAX_HEALTH)


func _on_health_changed(health: int, max_health: int) -> void:
	for child in hearts.get_children():
		child.queue_free()
	for i in max_health:
		var heart := TextureRect.new()
		heart.texture = HEART_FULL if i < health else HEART_EMPTY
		heart.custom_minimum_size = Vector2(26, 22)
		heart.stretch_mode = TextureRect.STRETCH_SCALE
		hearts.add_child(heart)


func _on_boss_started(display_name: String, max_health: int) -> void:
	boss_name.text = display_name
	boss_bar.max_value = max_health
	boss_bar.value = max_health
	boss_panel.visible = true


func _on_boss_health_changed(health: int) -> void:
	var tween := create_tween()
	tween.tween_property(boss_bar, "value", health, 0.2)
