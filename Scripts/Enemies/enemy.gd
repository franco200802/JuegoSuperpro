class_name Enemy
extends CharacterBody2D

# Base de todos los enemigos: vida, daño por contacto, retroceso, destello al ser golpeado y muerte.
# Cada enemigo concreto implementa _behave(delta) y deja velocity lista para mover.

signal died

const GRAVITY: float = 900.0
const MAX_FALL_SPEED: float = 420.0

@export var max_health: int = 3
@export var contact_damage: int = 1
@export var knockback_strength: float = 160.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurtbox: Area2D = $Hurtbox

var health: int
var is_dead: bool = false
var knockback: float = 0.0
var flash_left: float = 0.0


func _ready() -> void:
	health = max_health
	add_to_group("enemies")


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


# Falso mientras el enemigo esta protegido (por ejemplo, un caracol escondido).
func can_be_hit() -> bool:
	return true


func take_hit(amount: int, from_position: Vector2) -> void:
	if is_dead:
		return
	if not can_be_hit():
		_on_blocked_hit(from_position)
		return
	health -= amount
	sprite.modulate = Color(3.0, 3.0, 3.0)
	flash_left = 0.08
	knockback = signf(global_position.x - from_position.x) * knockback_strength
	_on_hit()
	if health <= 0:
		die()


func _on_hit() -> void:
	pass


func _on_blocked_hit(_from_position: Vector2) -> void:
	sprite.modulate = Color(0.6, 0.6, 0.8)
	flash_left = 0.08


func die() -> void:
	if is_dead:
		return
	is_dead = true
	collision_layer = 0
	hurtbox.set_deferred("monitoring", false)
	sprite.modulate = Color.WHITE
	_spawn_puff()
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


func _player() -> Node2D:
	return get_tree().get_first_node_in_group("player")


# Nube de polvo al morir.
func _spawn_puff() -> void:
	var puff := CPUParticles2D.new()
	puff.one_shot = true
	puff.emitting = true
	puff.amount = 18
	puff.lifetime = 0.6
	puff.explosiveness = 1.0
	puff.spread = 180.0
	puff.gravity = Vector2(0, 60)
	puff.initial_velocity_min = 40.0
	puff.initial_velocity_max = 110.0
	puff.scale_amount_min = 2.0
	puff.scale_amount_max = 4.0
	puff.color = Color(0.9, 0.85, 0.75, 0.8)
	puff.global_position = global_position
	get_parent().add_child(puff)
	get_tree().create_timer(1.0).timeout.connect(puff.queue_free)
