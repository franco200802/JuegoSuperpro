extends Node

# Autoload "GameManager": sobrevive a los cambios de escena y guarda
# la informacion que una sala necesita de la anterior (puerta, vida, peleas ganadas).

signal health_changed(health: int, max_health: int)
signal boss_started(boss_name: String, max_health: int)
signal boss_health_changed(health: int)
signal boss_ended

const FADE_TIME: float = 0.25
const MAX_HEALTH: int = 5
const DEATH_DELAY: float = 1.2

# door_id de la TransitionArea donde debe aparecer el jugador en la proxima sala.
var target_door_id: String = ""
# Puerta por la que se entro a la sala actual: ahi se reaparece al morir.
var last_door_id: String = ""
var is_transitioning: bool = false

var health: int = MAX_HEALTH
# arena_id de las peleas ya ganadas (no se repiten).
var cleared_arenas: Dictionary = {}

var fade_rect: ColorRect
var shake_strength: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Capa negra por encima de todo para el fade entre salas.
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)

	fade_rect = ColorRect.new()
	fade_rect.color = Color.BLACK
	fade_rect.modulate.a = 0.0
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(fade_rect)

	add_child(preload("res://Scenes/HUD.tscn").instantiate())


func _process(delta: float) -> void:
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera == null:
		return
	if shake_strength > 0.0:
		camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake_strength
		shake_strength = move_toward(shake_strength, 0.0, 30.0 * delta)
	else:
		camera.offset = Vector2.ZERO


func change_room(scene_path: String, door_id: String) -> void:
	if is_transitioning:
		return
	is_transitioning = true
	target_door_id = door_id
	Player.input_locked = true

	await _fade_to(1.0)
	boss_ended.emit()
	# Diferido: no se puede liberar la sala actual en medio del callback de fisicas.
	get_tree().change_scene_to_file.call_deferred(scene_path)
	await get_tree().scene_changed
	await _fade_to(0.0)

	Player.input_locked = false
	is_transitioning = false


# Resta vida; devuelve true si el jugador murio.
func damage_player(amount: int) -> bool:
	health = maxi(0, health - amount)
	health_changed.emit(health, MAX_HEALTH)
	shake(4.0)
	hitstop(0.08)
	return health == 0


func heal_full() -> void:
	health = MAX_HEALTH
	health_changed.emit(health, MAX_HEALTH)


# Al morir: se espera la animacion, se recarga la sala y se aparece en la ultima puerta.
func player_died() -> void:
	if is_transitioning:
		return
	is_transitioning = true
	Player.input_locked = true

	await get_tree().create_timer(DEATH_DELAY).timeout
	await _fade_to(1.0)
	boss_ended.emit()
	heal_full()
	target_door_id = last_door_id
	get_tree().change_scene_to_file.call_deferred(get_tree().current_scene.scene_file_path)
	await get_tree().scene_changed
	await _fade_to(0.0)

	Player.input_locked = false
	is_transitioning = false


func shake(strength: float) -> void:
	shake_strength = maxf(shake_strength, strength)


# Congela el juego un instante para que los golpes se sientan.
func hitstop(duration: float) -> void:
	Engine.time_scale = 0.05
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0


func _fade_to(alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate:a", alpha, FADE_TIME)
	await tween.finished
