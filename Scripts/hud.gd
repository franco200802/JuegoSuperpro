extends CanvasLayer

const HEART_FULL := preload("res://Assets/Sprites/Combat/heart_full.png")
const HEART_EMPTY := preload("res://Assets/Sprites/Combat/heart_empty.png")
const NOTICE_TIME: float = 2.5

@onready var hearts: HBoxContainer = $Hearts
@onready var boss_panel: Control = $BossPanel
@onready var boss_name: Label = $BossPanel/Name
@onready var boss_bar: ProgressBar = $BossPanel/Bar
@onready var notice: Label = $Notice

var notice_tween: Tween


func _ready() -> void:
	boss_panel.visible = false
	notice.modulate.a = 0.0
	GameManager.health_changed.connect(_on_health_changed)
	GameManager.boss_started.connect(_on_boss_started)
	GameManager.boss_health_changed.connect(_on_boss_health_changed)
	GameManager.boss_ended.connect(func() -> void: boss_panel.visible = false)
	GameManager.notice.connect(_on_notice)
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


func _on_notice(text: String) -> void:
	notice.text = text
	if notice_tween:
		notice_tween.kill()
	notice_tween = create_tween()
	notice_tween.tween_property(notice, "modulate:a", 1.0, 0.2)
	notice_tween.tween_interval(NOTICE_TIME)
	notice_tween.tween_property(notice, "modulate:a", 0.0, 0.6)
