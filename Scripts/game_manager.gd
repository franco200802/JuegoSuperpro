extends Node

signal health_changed(health: int, max_health: int)
signal boss_started(boss_name: String, max_health: int)
signal boss_health_changed(health: float)
signal boss_ended
signal notice(text: String)

const FADE_TIME: float = 0.25
const MAX_HEALTH: int = 5
const DEATH_DELAY: float = 1.2
const KILLS_PER_HEART: int = 3

var target_door_id: String = ""
var last_door_id: String = ""
var is_transitioning: bool = false

var checkpoint_scene: String = ""
var checkpoint_door_id: String = ""
var in_boss_fight: bool = false

var health: int = MAX_HEALTH
var cleared_arenas: Dictionary = {}
var has_dash: bool = false
var has_moss_blade: bool = false
var has_double_jump: bool = true

var kills: int = 0
var kills_for_heart: int = 0
var deaths: int = 0
var play_time: float = 0.0

var fade_rect: ColorRect
var shake_strength: float = 0.0
var death_menu: CanvasLayer
var end_menu: CanvasLayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

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
	death_menu = preload("res://Scenes/DeathMenu.tscn").instantiate()
	add_child(death_menu)
	end_menu = preload("res://Scenes/EndMenu.tscn").instantiate()
	add_child(end_menu)

	checkpoint_scene = ProjectSettings.get_setting("application/run/main_scene")
	boss_started.connect(func(_boss_name: String, _max_health: int) -> void: in_boss_fight = true)
	boss_ended.connect(func() -> void: in_boss_fight = false)


func _process(delta: float) -> void:
	if not get_tree().paused:
		play_time += delta
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
	get_tree().change_scene_to_file.call_deferred(scene_path)
	await get_tree().scene_changed
	await _fade_to(0.0)

	Player.input_locked = false
	is_transitioning = false


func damage_player(amount: int) -> bool:
	health = maxi(0, health - amount)
	health_changed.emit(health, MAX_HEALTH)
	shake(4.0)
	hitstop(0.08)
	return health == 0


func heal(amount: int) -> void:
	if health >= MAX_HEALTH:
		return
	health = mini(health + amount, MAX_HEALTH)
	health_changed.emit(health, MAX_HEALTH)
	Sfx.play("heal")


func enemy_killed() -> void:
	kills += 1
	kills_for_heart += 1
	if kills_for_heart >= KILLS_PER_HEART:
		kills_for_heart = 0
		heal(1)


func heal_full() -> void:
	health = MAX_HEALTH
	health_changed.emit(health, MAX_HEALTH)


func rest(scene_path: String, spot_id: String) -> void:
	checkpoint_scene = scene_path
	checkpoint_door_id = spot_id
	last_door_id = spot_id
	heal_full()
	Sfx.play("rest")
	notice.emit("Descansaste: si caés ante un jefe, volvés acá")


func is_checkpoint(scene_path: String, spot_id: String) -> bool:
	return checkpoint_scene == scene_path and checkpoint_door_id == spot_id


func grant_dash() -> void:
	has_dash = true
	Sfx.play("unlock")
	notice.emit("Conseguiste el dash: Shift")


func grant_moss_blade() -> void:
	has_moss_blade = true
	Sfx.play("unlock")
	notice.emit("Conseguiste la Hoja de Musgo: pega más fuerte y hiere a la Sombra")


func player_died() -> void:
	if is_transitioning:
		return
	is_transitioning = true
	Player.input_locked = true
	var died_to_boss: bool = in_boss_fight
	deaths += 1

	await get_tree().create_timer(DEATH_DELAY).timeout
	death_menu.open(died_to_boss)
	await death_menu.retry_pressed
	await _fade_to(1.0)
	boss_ended.emit()
	heal_full()
	var scene_path: String = get_tree().current_scene.scene_file_path
	target_door_id = last_door_id
	if died_to_boss:
		scene_path = checkpoint_scene
		target_door_id = checkpoint_door_id
		last_door_id = checkpoint_door_id
	get_tree().change_scene_to_file.call_deferred(scene_path)
	await get_tree().scene_changed
	await _fade_to(0.0)

	Player.input_locked = false
	is_transitioning = false


func finish_game() -> void:
	Player.input_locked = true
	end_menu.open()


func restart_game() -> void:
	if is_transitioning:
		return
	is_transitioning = true
	await _fade_to(1.0)
	get_tree().paused = false
	boss_ended.emit()
	health = MAX_HEALTH
	cleared_arenas.clear()
	has_dash = false
	has_moss_blade = false
	has_double_jump = true
	kills = 0
	kills_for_heart = 0
	deaths = 0
	play_time = 0.0
	checkpoint_scene = ProjectSettings.get_setting("application/run/main_scene")
	checkpoint_door_id = ""
	last_door_id = ""
	target_door_id = ""
	health_changed.emit(health, MAX_HEALTH)
	get_tree().change_scene_to_file.call_deferred(checkpoint_scene)
	await get_tree().scene_changed
	await _fade_to(0.0)

	Player.input_locked = false
	is_transitioning = false


func shake(strength: float) -> void:
	shake_strength = maxf(shake_strength, strength)


func hitstop(duration: float) -> void:
	Engine.time_scale = 0.05
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0


func _fade_to(alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate:a", alpha, FADE_TIME)
	await tween.finished
