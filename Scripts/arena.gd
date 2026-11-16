extends Node2D

@export var arena_id: String = ""
@export var heal_on_clear: bool = false
@export var grants_dash: bool = false
@export var grants_blade: bool = false
@export var requires_blade: bool = false

@onready var trigger: Area2D = $Trigger
@onready var gates: Node2D = $Gates

var waves: Array[Node] = []
var current_wave: Node = null
var alive: int = 0
var started: bool = false


func _ready() -> void:
	for child in get_children():
		if child.name.begins_with("Wave"):
			waves.append(child)
	_set_gates(false, false)

	if GameManager.cleared_arenas.has(arena_id):
		for wave in waves:
			wave.queue_free()
		waves.clear()
		trigger.monitoring = false
		return

	for wave in waves:
		wave.process_mode = Node.PROCESS_MODE_DISABLED
		wave.visible = false
	trigger.body_entered.connect(_on_trigger_body_entered)


func _on_trigger_body_entered(body: Node) -> void:
	if started or not body.is_in_group("player"):
		return
	if requires_blade and not GameManager.has_moss_blade:
		GameManager.notice.emit("Una fuerza oscura te repele: necesitás la Hoja de Musgo del Guardián del Bosque")
		return
	started = true
	trigger.set_deferred("monitoring", false)
	_set_gates(true, true)
	_next_wave()


func _next_wave() -> void:
	if waves.is_empty():
		_finish()
		return
	current_wave = waves.pop_front()
	await get_tree().create_timer(0.8).timeout
	current_wave.process_mode = Node.PROCESS_MODE_INHERIT
	current_wave.visible = true
	alive = 0
	for enemy in current_wave.get_children():
		if not enemy is Enemy:
			continue
		alive += 1
		enemy.died.connect(_on_enemy_died)
		enemy.modulate.a = 0.0
		create_tween().tween_property(enemy, "modulate:a", 1.0, 0.4)
		if enemy is Boss:
			enemy.start(_fight_rect())
	if alive == 0:
		_next_wave()


func _on_enemy_died() -> void:
	alive -= 1
	if alive <= 0:
		_next_wave()


func _finish() -> void:
	GameManager.cleared_arenas[arena_id] = true
	for node in get_tree().get_nodes_in_group("enemies"):
		if is_ancestor_of(node) and not node.is_dead:
			node.die()
	for hazard in get_tree().get_nodes_in_group("hazards"):
		if is_ancestor_of(hazard):
			hazard.queue_free()
	if heal_on_clear:
		GameManager.heal_full()
	if grants_dash and not GameManager.has_dash:
		GameManager.grant_dash()
	if grants_blade and not GameManager.has_moss_blade:
		GameManager.grant_moss_blade()
	await get_tree().create_timer(0.6).timeout
	_set_gates(false, true)


func _set_gates(closed: bool, animate: bool) -> void:
	for gate in gates.get_children():
		gate.get_node("CollisionShape2D").set_deferred("disabled", not closed)
		var sprite: Sprite2D = gate.get_node("Sprite2D")
		if not animate:
			sprite.visible = closed
			continue
		sprite.visible = true
		var tween := create_tween()
		if closed:
			sprite.modulate.a = 0.0
			tween.tween_property(sprite, "modulate:a", 1.0, 0.2)
		else:
			tween.tween_property(sprite, "modulate:a", 0.0, 0.4)
			tween.tween_callback(sprite.hide)
	if animate:
		GameManager.shake(3.0)
		Sfx.play("gate")


func _fight_rect() -> Rect2:
	var shape_node: CollisionShape2D = trigger.get_node("CollisionShape2D")
	var size: Vector2 = shape_node.shape.size
	return Rect2(shape_node.global_position - size / 2.0, size)
