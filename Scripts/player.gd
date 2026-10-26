class_name Player
extends CharacterBody2D

# Bloquea el movimiento del jugador mientras hay un dialogo abierto o una transicion.
static var input_locked: bool = false

const SPEED: float = 140.0
const ACCELERATION: float = 900.0
const FRICTION: float = 900.0

const GRAVITY: float = 900.0
const MAX_FALL_SPEED: float = 420.0
const JUMP_VELOCITY: float = -300.0
const DOUBLE_JUMP_VELOCITY: float = -260.0

const DASH_SPEED: float = 380.0
const DASH_TIME: float = 0.15
const DASH_COOLDOWN: float = 0.5

const ATTACK_DAMAGE: int = 1
const ATTACK_COOLDOWN: float = 0.3
# Retroceso del jugador al pegarle a algo.
const ATTACK_RECOIL: float = 110.0
const HITBOX_OFFSET: float = 26.0

const INVULNERABLE_TIME: float = 1.0
const HURT_TIME: float = 0.25
const KNOCKBACK := Vector2(200.0, -180.0)

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox

var double_jump_enabled: bool = true
var dash_enabled: bool = true

var facing: int = 1
var jumps_left: int = 1

var is_dashing: bool = false
var dash_time_left: float = 0.0
var dash_cooldown_left: float = 0.0
var dash_direction: float = 1.0

var is_attacking: bool = false
var attack_cooldown_left: float = 0.0
# Alterna entre los dos cortes de la animacion de ataque.
var next_attack_b: bool = false

var invulnerable_left: float = 0.0
var hurt_left: float = 0.0
var is_dead: bool = false
# Frame de fisica del ultimo corazon perdido.
var last_damage_frame: int = -2


func _ready() -> void:
	add_to_group("player")
	sprite.animation_finished.connect(_on_animation_finished)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_double_jump"):
		double_jump_enabled = not double_jump_enabled
		print("Doble salto activado" if double_jump_enabled else "Doble salto desactivado")
	elif event.is_action_pressed("toggle_dash"):
		dash_enabled = not dash_enabled
		print("Dash activado" if dash_enabled else "Dash desactivado")


func _process(delta: float) -> void:
	# Parpadeo mientras dura la invulnerabilidad.
	if invulnerable_left > 0.0 and not is_dead:
		invulnerable_left -= delta
		sprite.self_modulate.a = 0.35 if int(invulnerable_left * 15.0) % 2 == 0 else 1.0
	else:
		sprite.self_modulate.a = 1.0


func _physics_process(delta: float) -> void:
	if attack_cooldown_left > 0.0:
		attack_cooldown_left -= delta

	if is_dead or input_locked or hurt_left > 0.0:
		hurt_left -= delta
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta * (0.4 if hurt_left > 0.0 else 1.0))
		velocity.y = 0.0 if is_on_floor() and velocity.y > 0.0 else min(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)
		move_and_slide()
		_update_animation()
		return

	if dash_cooldown_left > 0.0:
		dash_cooldown_left -= delta

	if Input.is_action_just_pressed("dash") and dash_enabled and not is_dashing and dash_cooldown_left <= 0.0:
		_start_dash()

	if is_dashing:
		dash_time_left -= delta
		velocity.x = dash_direction * DASH_SPEED
		velocity.y = 0.0
		if dash_time_left <= 0.0:
			is_dashing = false
			sprite.modulate.a = 1.0
	else:
		_handle_movement(delta)
		_handle_jump()
		if Input.is_action_just_pressed("attack") and attack_cooldown_left <= 0.0:
			_attack()

	move_and_slide()

	if is_on_floor():
		jumps_left = 1 if double_jump_enabled else 0

	_update_animation()


func _handle_movement(delta: float) -> void:
	var input_dir: float = Input.get_axis("move_left", "move_right")

	if input_dir != 0.0:
		velocity.x = move_toward(velocity.x, input_dir * SPEED, ACCELERATION * delta)
		# No se da vuelta en medio de un corte.
		if not is_attacking:
			facing = signi(input_dir)
	else:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)

	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y = min(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)


func _handle_jump() -> void:
	if not Input.is_action_just_pressed("jump"):
		return

	if is_on_floor():
		velocity.y = JUMP_VELOCITY
	elif jumps_left > 0:
		velocity.y = DOUBLE_JUMP_VELOCITY
		jumps_left -= 1


func _start_dash() -> void:
	var input_dir: float = Input.get_axis("move_left", "move_right")
	dash_direction = input_dir if input_dir != 0.0 else float(facing)
	is_dashing = true
	is_attacking = false
	dash_time_left = DASH_TIME
	dash_cooldown_left = DASH_COOLDOWN
	sprite.modulate.a = 0.6


func _attack() -> void:
	is_attacking = true
	attack_cooldown_left = ATTACK_COOLDOWN
	sprite.play("attack_b" if next_attack_b else "attack_a")
	next_attack_b = not next_attack_b

	hitbox.position.x = HITBOX_OFFSET * facing
	var hit_something: bool = false
	for body in _bodies_in_hitbox():
		if body.has_method("take_hit"):
			body.take_hit(ATTACK_DAMAGE, global_position)
			hit_something = true
	if hit_something:
		velocity.x = -facing * ATTACK_RECOIL
		GameManager.shake(2.0)


# El Area2D recien actualiza sus solapamientos en el proximo paso de fisica,
# asi que se consulta el espacio con la forma ya ubicada del lado al que mira.
func _bodies_in_hitbox() -> Array[Node2D]:
	var shape_node: CollisionShape2D = hitbox.get_node("CollisionShape2D")
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape_node.shape
	query.transform = shape_node.global_transform
	query.collision_mask = hitbox.collision_mask
	query.exclude = [get_rid()]
	var bodies: Array[Node2D] = []
	for hit in get_world_2d().direct_space_state.intersect_shape(query):
		if hit.collider not in bodies:
			bodies.append(hit.collider)
	return bodies


# Ataques de enemigos y proyectiles: respetan la invulnerabilidad.
func take_damage(amount: int, from_position: Vector2) -> void:
	if invulnerable_left > 0.0:
		return
	_apply_damage(amount, from_position)


# Caer al vacio cuesta un corazon aunque el jugador sea invulnerable a los ataques,
# salvo que un golpe ya le haya quitado uno en este mismo instante.
func take_fall_damage(amount: int) -> void:
	if Engine.get_physics_frames() - last_damage_frame <= 1:
		return
	_apply_damage(amount, global_position)


func _apply_damage(amount: int, from_position: Vector2) -> void:
	if is_dead or GameManager.is_transitioning:
		return
	last_damage_frame = Engine.get_physics_frames()
	is_dashing = false
	is_attacking = false
	sprite.modulate.a = 1.0
	if GameManager.damage_player(amount):
		_die()
		return
	invulnerable_left = INVULNERABLE_TIME
	hurt_left = HURT_TIME
	var away: float = signf(global_position.x - from_position.x)
	if away == 0.0:
		away = -facing
	velocity = Vector2(away * KNOCKBACK.x, KNOCKBACK.y)


func _die() -> void:
	is_dead = true
	velocity.x = 0.0
	sprite.play("dead")
	GameManager.player_died()


func _on_animation_finished() -> void:
	if sprite.animation.begins_with("attack"):
		is_attacking = false


func _update_animation() -> void:
	sprite.flip_h = facing < 0
	if is_dead:
		return
	if is_attacking:
		return

	if not is_on_floor():
		sprite.play("jump" if velocity.y < 0.0 else "fall")
	elif absf(velocity.x) > 10.0:
		sprite.play("run")
	else:
		sprite.play("idle")
