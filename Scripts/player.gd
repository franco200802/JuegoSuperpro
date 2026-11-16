class_name Player
extends CharacterBody2D

static var input_locked: bool = false

const SPEED: float = 140.0
const ACCELERATION: float = 900.0
const FRICTION: float = 900.0

const GRAVITY: float = 900.0
const MAX_FALL_SPEED: float = 420.0
const JUMP_VELOCITY: float = -300.0
const DOUBLE_JUMP_VELOCITY: float = -260.0
const JUMP_CUT: float = 0.45
const COYOTE_TIME: float = 0.1
const JUMP_BUFFER: float = 0.12

const DASH_SPEED: float = 380.0
const DASH_TIME: float = 0.15
const DASH_COOLDOWN: float = 0.5

const ATTACK_DAMAGE: float = 1.25
const ATTACK_COOLDOWN: float = 0.3
const ATTACK_RECOIL: float = 110.0
const HITBOX_OFFSET: float = 26.0
const HITBOX_REACH: float = 32.0
const POGO_VELOCITY: float = -290.0

const INVULNERABLE_TIME: float = 1.0
const HURT_TIME: float = 0.25
const KNOCKBACK := Vector2(200.0, -180.0)
const SAFE_GROUND_FRAMES: int = 10

# Para las demos: tocar 5, 6 y 7 seguidos prende o apaga el modo dios
# (no lo lastiman y pega mucho mas fuerte).
const CHEAT_KEYS: Array[int] = [KEY_5, KEY_6, KEY_7]
const GOD_MODE_DAMAGE: float = 5.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox
@onready var slash: Node2D = $Slash

var facing: int = 1
var jumps_left: int = 1
var coyote_left: float = 0.0
var jump_buffer_left: float = 0.0
var is_jumping: bool = false

var is_dashing: bool = false
var dash_time_left: float = 0.0
var dash_cooldown_left: float = 0.0
var dash_direction: float = 1.0
var air_dash_used: bool = false

var is_attacking: bool = false
var attack_cooldown_left: float = 0.0
var next_attack_b: bool = false

var invulnerable_left: float = 0.0
var hurt_left: float = 0.0
var is_dead: bool = false
var last_damage_frame: int = -2

var god_mode: bool = false
var cheat_step: int = 0

var safe_position: Vector2
var ground_trail: Array[Vector2] = []


func _ready() -> void:
	add_to_group("player")
	safe_position = global_position
	sprite.animation_finished.connect(_on_animation_finished)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		_check_cheat(event.physical_keycode)

	if event.is_action_pressed("toggle_double_jump"):
		GameManager.has_double_jump = not GameManager.has_double_jump
		print("Doble salto activado" if GameManager.has_double_jump else "Doble salto desactivado")
	elif event.is_action_pressed("toggle_dash"):
		GameManager.has_dash = not GameManager.has_dash
		print("Dash activado" if GameManager.has_dash else "Dash desactivado")


func _check_cheat(key: int) -> void:
	if key == CHEAT_KEYS[cheat_step]:
		cheat_step += 1
	else:
		# Si se equivoca pero toca el 5, arranca la secuencia de nuevo.
		cheat_step = 1 if key == CHEAT_KEYS[0] else 0

	if cheat_step < CHEAT_KEYS.size():
		return

	cheat_step = 0
	god_mode = not god_mode
	var text: String = "Modo dios activado" if god_mode else "Modo dios desactivado"
	print(text)
	GameManager.notice.emit(text)


func _process(delta: float) -> void:
	if invulnerable_left > 0.0 and not is_dead:
		invulnerable_left -= delta
		sprite.self_modulate.a = 0.35 if int(invulnerable_left * 15.0) % 2 == 0 else 1.0
	else:
		sprite.self_modulate.a = 1.0


func _physics_process(delta: float) -> void:
	if attack_cooldown_left > 0.0:
		attack_cooldown_left -= delta

	if is_dead or input_locked or hurt_left > 0.0:
		hurt_left = maxf(hurt_left - delta, 0.0)
		jump_buffer_left = 0.0
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta * (0.4 if hurt_left > 0.0 else 1.0))
		velocity.y = 0.0 if is_on_floor() and velocity.y > 0.0 else minf(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)
		move_and_slide()
		_update_animation()
		return

	if dash_cooldown_left > 0.0:
		dash_cooldown_left -= delta
	if Input.is_action_just_pressed("jump"):
		jump_buffer_left = JUMP_BUFFER
	else:
		jump_buffer_left -= delta

	if Input.is_action_just_pressed("dash") and _can_dash():
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
	_update_ground(delta)
	_update_animation()


func _handle_movement(delta: float) -> void:
	var input_dir: float = Input.get_axis("move_left", "move_right")

	if input_dir != 0.0:
		velocity.x = move_toward(velocity.x, input_dir * SPEED, ACCELERATION * delta)
		if not is_attacking:
			facing = signi(input_dir)
	else:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)

	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)


func _handle_jump() -> void:
	if jump_buffer_left > 0.0 and coyote_left > 0.0:
		_jump(JUMP_VELOCITY, "jump")
	elif jump_buffer_left > 0.0 and jumps_left > 0:
		jumps_left -= 1
		_jump(DOUBLE_JUMP_VELOCITY, "double_jump")

	if is_jumping and (velocity.y >= 0.0 or not Input.is_action_pressed("jump")):
		if velocity.y < 0.0:
			velocity.y *= JUMP_CUT
		is_jumping = false


func _jump(jump_velocity: float, sound: String) -> void:
	velocity.y = jump_velocity
	is_jumping = true
	coyote_left = 0.0
	jump_buffer_left = 0.0
	Sfx.play(sound)


func _update_ground(delta: float) -> void:
	if not is_on_floor():
		coyote_left -= delta
		ground_trail.clear()
		return
	coyote_left = COYOTE_TIME
	jumps_left = 1 if GameManager.has_double_jump else 0
	air_dash_used = false
	ground_trail.append(global_position)
	if ground_trail.size() > SAFE_GROUND_FRAMES:
		safe_position = ground_trail.pop_front()


func _can_dash() -> bool:
	if not GameManager.has_dash or is_dashing or dash_cooldown_left > 0.0:
		return false
	return is_on_floor() or not air_dash_used


func _start_dash() -> void:
	var input_dir: float = Input.get_axis("move_left", "move_right")
	dash_direction = input_dir if input_dir != 0.0 else float(facing)
	facing = int(dash_direction)
	is_dashing = true
	is_jumping = false
	is_attacking = false
	air_dash_used = not is_on_floor()
	dash_time_left = DASH_TIME
	dash_cooldown_left = DASH_COOLDOWN
	sprite.modulate.a = 0.6
	Sfx.play("dash")


func _attack() -> void:
	is_attacking = true
	attack_cooldown_left = ATTACK_COOLDOWN
	sprite.play("attack_b" if next_attack_b else "attack_a")
	next_attack_b = not next_attack_b

	var direction := Vector2(facing, 0.0)
	if Input.is_action_pressed("move_up"):
		direction = Vector2.UP
	elif Input.is_action_pressed("move_down") and not is_on_floor():
		direction = Vector2.DOWN
	hitbox.position = Vector2(HITBOX_OFFSET * facing, -2.0) if direction.y == 0.0 else direction * HITBOX_REACH
	slash.play(direction)
	Sfx.play("attack")

	var damage: float = GOD_MODE_DAMAGE if god_mode else ATTACK_DAMAGE
	var hit_enemy: bool = false
	var hit_spikes: bool = false
	for collider in _colliders_in_hitbox():
		if collider.has_method("take_hit"):
			collider.take_hit(damage, global_position)
			hit_enemy = true
		elif collider.is_in_group("spikes"):
			hit_spikes = true
	if not hit_enemy and not hit_spikes:
		return

	if direction == Vector2.DOWN:
		_pogo()
	elif direction.y == 0.0:
		velocity.x = -facing * ATTACK_RECOIL
	if hit_enemy:
		GameManager.shake(2.0)
		GameManager.hitstop(0.035)


func _pogo() -> void:
	velocity.y = POGO_VELOCITY
	is_jumping = false
	jumps_left = 1 if GameManager.has_double_jump else 0
	air_dash_used = false
	Sfx.play("pogo")


func _colliders_in_hitbox() -> Array[Node2D]:
	var shape_node: CollisionShape2D = hitbox.get_node("CollisionShape2D")
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape_node.shape
	query.transform = shape_node.global_transform
	query.collision_mask = hitbox.collision_mask
	query.collide_with_areas = true
	query.exclude = [get_rid()]
	var colliders: Array[Node2D] = []
	for hit in get_world_2d().direct_space_state.intersect_shape(query):
		if hit.collider not in colliders:
			colliders.append(hit.collider)
	return colliders


func take_damage(amount: int, from_position: Vector2) -> void:
	if invulnerable_left > 0.0:
		return
	_apply_damage(amount, from_position)


func take_fall_damage(amount: int) -> void:
	if Engine.get_physics_frames() - last_damage_frame <= 1:
		return
	_apply_damage(amount, global_position)


func hurt_by_hazard() -> void:
	if is_dead or GameManager.is_transitioning:
		return
	take_fall_damage(1)
	global_position = safe_position
	velocity = Vector2.ZERO
	ground_trail.clear()
	is_jumping = false


func _apply_damage(amount: int, from_position: Vector2) -> void:
	if is_dead or GameManager.is_transitioning or god_mode:
		return
	last_damage_frame = Engine.get_physics_frames()
	is_dashing = false
	is_attacking = false
	is_jumping = false
	sprite.modulate.a = 1.0
	if GameManager.damage_player(amount):
		_die()
		return
	Sfx.play("hurt")
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
	Sfx.play("death")
	GameManager.player_died()


func _on_animation_finished() -> void:
	if sprite.animation.begins_with("attack"):
		is_attacking = false


func _update_animation() -> void:
	sprite.flip_h = facing < 0
	if is_dead or is_attacking:
		return

	if not is_on_floor():
		sprite.play("jump" if velocity.y < 0.0 else "fall")
	elif absf(velocity.x) > 10.0:
		sprite.play("run")
	else:
		sprite.play("idle")
