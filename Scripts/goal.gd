extends Area2D

@export var required_arena: String = ""

@onready var message: CanvasLayer = $Message


func _ready() -> void:
	message.visible = false


func _physics_process(_delta: float) -> void:
	if message.visible:
		return
	if required_arena != "" and not GameManager.cleared_arenas.has(required_arena):
		return
	for body in get_overlapping_bodies():
		if body.is_in_group("player"):
			message.visible = true
			Sfx.play("unlock")
