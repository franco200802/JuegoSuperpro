class_name Room
extends Node2D

# Script base de toda sala: al cargar, ubica al jugador en la puerta
# por la que llego (segun GameManager.target_door_id).

@onready var player: CharacterBody2D = get_tree().get_first_node_in_group("player")


func _ready() -> void:
	_place_player_at_door()


func _place_player_at_door() -> void:
	var door_id: String = GameManager.target_door_id
	if door_id.is_empty() or player == null:
		# Primera sala o sala corrida con F6: queda la posicion del editor.
		return
	GameManager.target_door_id = ""
	GameManager.last_door_id = door_id

	var door: TransitionArea = _find_door(door_id)
	if door == null:
		push_warning("La sala '%s' no tiene una TransitionArea con door_id '%s'" % [name, door_id])
		return

	player.global_position = door.get_spawn_position()
	player.velocity = Vector2.ZERO
	var camera: Camera2D = player.get_node_or_null("Camera2D")
	if camera:
		# Sin esto la camara "viaja" desde la posicion del editor hasta el jugador.
		camera.reset_smoothing()


func _find_door(door_id: String) -> TransitionArea:
	for door in get_tree().get_nodes_in_group("transition_areas"):
		if door.door_id == door_id and is_ancestor_of(door):
			return door
	return null
