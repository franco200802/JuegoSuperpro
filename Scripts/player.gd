class_name Player
extends CharacterBody2D

# Bloquea el movimiento del jugador mientras hay un dialogo abierto.
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

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var double_jump_enabled: bool = true
var dash_enabled: bool = true

var facing: int = 1
var jumps_left: int = 1

var is_dashing: bool = false
var dash_time_left: float = 0.0
var dash_cooldown_left: float = 0.0
var dash_direction: float = 1.0


func _ready() -> void:
	add_to_group("player")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_double_jump"):
		double_jump_enabled = not double_jump_enabled
		print("Doble salto activado" if double_jump_enabled else "Doble salto desactivado")
	elif event.is_action_pressed("toggle_dash"):
		dash_enabled = not dash_enabled
		print("Dash activado" if dash_enabled else "Dash desactivado")


func _physics_process(delta: float) -> void:
	if input_locked:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
		velocity.y = 0.0 if is_on_floor() else min(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)
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

	move_and_slide()

	if is_on_floor():
		jumps_left = 1 if double_jump_enabled else 0

	_update_animation()


func _handle_movement(delta: float) -> void:
	var input_dir: float = Input.get_axis("move_left", "move_right")

	if input_dir != 0.0:
		velocity.x = move_toward(velocity.x, input_dir * SPEED, ACCELERATION * delta)
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
	dash_time_left = DASH_TIME
	dash_cooldown_left = DASH_COOLDOWN
	sprite.modulate.a = 0.6


func _update_animation() -> void:
	sprite.flip_h = facing < 0

	if not is_on_floor():
		sprite.play("jump" if velocity.y < 0.0 else "fall")
	elif absf(velocity.x) > 10.0:
		sprite.play("run")
	else:
		sprite.play("idle")
