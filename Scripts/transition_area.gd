class_name TransitionArea
extends Area2D

@export var door_id: String = ""
@export_file("*.tscn") var target_scene: String = ""
@export var target_door_id: String = ""
@export var area_size: Vector2 = Vector2(16, 64)
@export var spawn_offset: Vector2 = Vector2(-40, 12)


func _ready() -> void:
	add_to_group("transition_areas")
	var shape := RectangleShape2D.new()
	shape.size = area_size
	$CollisionShape2D.shape = shape
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player") or GameManager.is_transitioning:
		return
	if target_scene.is_empty():
		push_warning("TransitionArea '%s' no tiene target_scene" % door_id)
		return
	GameManager.change_room(target_scene, target_door_id)


func get_spawn_position() -> Vector2:
	return global_position + spawn_offset
