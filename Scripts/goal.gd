extends Area2D

@export var required_arena: String = ""

var reached: bool = false


func _physics_process(_delta: float) -> void:
	if reached:
		return
	if required_arena != "" and not GameManager.cleared_arenas.has(required_arena):
		return
	for body in get_overlapping_bodies():
		if body.is_in_group("player"):
			_reach()
			return


func _reach() -> void:
	reached = true
	Sfx.play("unlock")
	GameManager.finish_game()
