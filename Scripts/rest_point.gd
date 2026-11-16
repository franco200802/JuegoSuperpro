extends Area2D

@export var spot_id: String = ""

@onready var sprite: Sprite2D = $Sprite2D
@onready var flame: CPUParticles2D = $Flame
@onready var prompt: Label = $InteractPrompt

var player_near: bool = false
var room_path: String = ""


func _ready() -> void:
	add_to_group("rest_points")
	room_path = owner.scene_file_path if owner else ""
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_update_light()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_near = true


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_near = false


func _process(_delta: float) -> void:
	var can_rest: bool = player_near and not Player.input_locked and not GameManager.in_boss_fight
	prompt.visible = can_rest
	if can_rest and Input.is_action_just_pressed("interact"):
		GameManager.rest(room_path, spot_id)
		_update_light()


func get_spawn_position() -> Vector2:
	return global_position + Vector2(-20, -22)


func _update_light() -> void:
	var lit: bool = GameManager.is_checkpoint(room_path, spot_id)
	flame.emitting = lit
	sprite.modulate = Color(1.25, 1.15, 0.95) if lit else Color(0.65, 0.65, 0.72)
