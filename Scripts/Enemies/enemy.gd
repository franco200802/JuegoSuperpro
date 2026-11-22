class_name Enemy
extends CharacterBody2D

signal died

const GRAVITY: float = 900.0
const MAX_FALL_SPEED: float = 420.0

@export var max_health: int = 3
@export var contact_damage: int = 1
@export var knockback_strength: float = 160.0
@export var blade_only: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurtbox: Area2D = $Hurtbox

var health: float
var is_dead: bool = false
var knockback: float = 0.0
var flash_left: float = 0.0


func _ready() -> void:
	health = max_health
	add_to_group("enemies")
	_pass_through_player.call_deferred()


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_behave(delta)
	if knockback != 0.0:
		velocity.x = knockback
		knockback = move_toward(knockback, 0.0, 900.0 * delta)
	move_and_slide()
	_damage_touching_player()

	if flash_left > 0.0:
		flash_left -= delta
		if flash_left <= 0.0:
			sprite.modulate = Color.WHITE


func _behave(_delta: float) -> void:
	pass


func can_be_hit() -> bool:
	return true


func take_hit(amount: float, from_position: Vector2) -> void:
	if is_dead:
		return
	if not can_be_hit() or (blade_only and not GameManager.has_moss_blade):
		_on_blocked_hit(from_position)
		return
	health -= amount
	sprite.modulate = Color(3.0, 3.0, 3.0)
	flash_left = 0.08
	knockback = signf(global_position.x - from_position.x) * knockback_strength
	_burst(8, Color(1.0, 0.95, 0.8), 60.0, 140.0, 0.25, from_position.direction_to(global_position))
	Sfx.play("hit")
	_on_hit()
	if health <= 0:
		GameManager.enemy_killed()
		die()


func _on_hit() -> void:
	pass


func _on_blocked_hit(_from_position: Vector2) -> void:
	sprite.modulate = Color(0.6, 0.6, 0.8)
	flash_left = 0.08
	Sfx.play("block")


func die() -> void:
	if is_dead:
		return
	is_dead = true
	collision_layer = 0
	hurtbox.set_deferred("monitoring", false)
	sprite.modulate = Color.WHITE
	_burst(18, Color(0.9, 0.85, 0.75, 0.8), 40.0, 110.0, 0.6, Vector2.ZERO)
	Sfx.play("enemy_die")
	died.emit()
	if sprite.sprite_frames.has_animation("dead"):
		sprite.play("dead")
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.6).set_delay(0.3)
	tween.tween_callback(queue_free)


func _damage_touching_player() -> void:
	if contact_damage <= 0:
		return
	for body in hurtbox.get_overlapping_bodies():
		if body.is_in_group("player"):
			body.take_damage(contact_damage, global_position)


func _apply_gravity(delta: float) -> void:
	if is_on_floor() and velocity.y > 0.0:
		velocity.y = 0.0
	else:
		velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)


func _pass_through_player() -> void:
	var player := _player()
	if player:
		add_collision_exception_with(player)


func _player() -> Node2D:
	return get_tree().get_first_node_in_group("player")


func _burst(amount: int, color: Color, speed_min: float, speed_max: float, lifetime: float, direction: Vector2) -> void:
	var particles := CPUParticles2D.new()
	particles.one_shot = true
	particles.emitting = true
	particles.amount = amount
	particles.lifetime = lifetime
	particles.explosiveness = 1.0
	particles.direction = direction if direction != Vector2.ZERO else Vector2.UP
	particles.spread = 180.0 if direction == Vector2.ZERO else 45.0
	particles.gravity = Vector2(0, 60)
	particles.initial_velocity_min = speed_min
	particles.initial_velocity_max = speed_max
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	particles.color = color
	particles.global_position = global_position
	get_parent().add_child(particles)
	get_tree().create_timer(lifetime + 0.4).timeout.connect(particles.queue_free)
