class_name TransitionArea
extends Area2D

# Puerta o borde de pantalla que lleva a otra sala.

# Identificador de esta puerta dentro de su sala (otras salas apuntan a el).
@export var door_id: String = ""
# Sala a la que lleva esta puerta.
@export_file("*.tscn") var target_scene: String = ""
# door_id de la puerta de la sala destino donde aparece el jugador.
@export var target_door_id: String = ""
# Medida del area de deteccion (angosta y alta para bordes, ancha para huecos de techo/piso).
@export var area_size: Vector2 = Vector2(16, 64)

# Punto donde aparece el jugador al llegar por esta puerta.
# Va fuera del area para que no vuelva a disparar la transicion.
@onready var spawn_point: Marker2D = $SpawnPoint


func _ready() -> void:
	add_to_group("transition_areas")
	# Forma propia por instancia, asi cambiar una puerta no cambia las demas.
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
	return spawn_point.global_position
