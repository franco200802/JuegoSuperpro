class_name Room
extends Node2D

@onready var player: CharacterBody2D = get_tree().get_first_node_in_group("player")


func _ready() -> void:
	_place_player_at_door()


func _place_player_at_door() -> void:
	var door_id: String = GameManager.target_door_id
	if door_id.is_empty() or player == null:
		return
	GameManager.target_door_id = ""
	GameManager.last_door_id = door_id

	var spot: Node2D = _find_spot(door_id)
	if spot == null:
		push_warning("La sala '%s' no tiene una puerta ni un descanso con id '%s'" % [name, door_id])
		return

	player.global_position = spot.get_spawn_position()
	player.velocity = Vector2.ZERO
	var camera: Camera2D = player.get_node_or_null("Camera2D")
	if camera:
		camera.reset_smoothing()


func _find_spot(spot_id: String) -> Node2D:
	for door in get_tree().get_nodes_in_group("transition_areas"):
		if door.door_id == spot_id and is_ancestor_of(door):
			return door
	for rest_point in get_tree().get_nodes_in_group("rest_points"):
		if rest_point.spot_id == spot_id and is_ancestor_of(rest_point):
			return rest_point
	return null
