extends Boss

enum State { IDLE, JUMP, SUMMON, WINDUP, CHARGE, STUNNED }
enum Attack { JUMP, SUMMON, CHARGE }

const SHOCKWAVE := preload("res://Scenes/Enemies/Shockwave.tscn")
const FALLING_ROCK := preload("res://Scenes/Enemies/FallingRock.tscn")
const JUMP_VELOCITY: float = -430.0
const FEET: float = 48.0
const CHARGE_SPEED: float = 300.0
const CHARGE_MAX_TIME: float = 2.0
const PATTERN_ONE := [Attack.JUMP, Attack.JUMP, Attack.SUMMON, Attack.CHARGE]
const PATTERN_TWO := [Attack.JUMP, Attack.CHARGE, Attack.SUMMON, Attack.JUMP, Attack.CHARGE]
const ANGRY_EYES := Color(1.8, 0.35, 0.3)

@onready var body_shape: CollisionShape2D = $CollisionShape2D
@onready var hurt_shape: CollisionShape2D = $Hurtbox/CollisionShape2D

var state: State = State.IDLE
var jumps_left: int = 0
var attacks_done: int = 0
var charge_dir: float = 1.0
var enraged: bool = false
var base_scale: Vector2
var base_position: Vector2
var time: float = 0.0


func _ready() -> void:
	super()
	base_scale = sprite.scale
	base_position = sprite.position
	# Las formas se comparten entre instancias: se duplican para poder agacharlo sin dejar rastro.
	body_shape.shape = body_shape.shape.duplicate()
	hurt_shape.shape = hurt_shape.shape.duplicate()


func start(rect: Rect2) -> void:
	super(rect)
	state_time = 0.8


func _behave(delta: float) -> void:
	_apply_gravity(delta)
	state_time -= delta
	time += delta
	sprite.scale = base_scale
	sprite.position = base_position
	sprite.rotation = 0.0
	sprite.self_modulate = Color.WHITE
	_check_enrage()

	match state:
		State.IDLE:
			velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
			sprite.scale.y = base_scale.y * (1.0 + sin(time * 6.0) * 0.03)
			if state_time < 0.25 and _peek_attack() == Attack.JUMP:
				sprite.scale = base_scale * Vector2(1.08, 0.9)
			if state_time <= 0.0 and is_on_floor():
				_begin_attack()
		State.JUMP:
			if is_on_floor() and state_time <= 0.0:
				_land()
		State.SUMMON:
			velocity.x = 0.0
			sprite.position.x += randf_range(-2.0, 2.0)
			if state_time <= 0.0:
				_drop_rocks(8 if enraged else 5)
				state = State.IDLE
				state_time = 0.7 if enraged else 1.0
		State.WINDUP:
			velocity.x = 0.0
			_pose_rolled()
			sprite.position.x += randf_range(-1.5, 1.5)
			sprite.self_modulate = Color.WHITE.lerp(Color(1.8, 0.7, 0.6), 0.5 + 0.5 * sin(time * 40.0))
			if state_time <= 0.0:
				Sfx.play("dash")
				state = State.CHARGE
				state_time = CHARGE_MAX_TIME
		State.CHARGE:
			velocity.x = charge_dir * CHARGE_SPEED * (1.25 if enraged else 1.0)
			_pose_rolled()
			if is_on_wall() or state_time <= 0.0:
				_end_charge(is_on_wall())
		State.STUNNED:
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			sprite.rotation = sin(time * 14.0) * 0.07
			sprite.self_modulate = Color(0.75, 0.85, 1.0)
			if state_time <= 0.0:
				state = State.IDLE
				state_time = 0.5


func _peek_attack() -> Attack:
	if jumps_left > 0:
		return Attack.JUMP
	var pattern: Array = PATTERN_TWO if enraged else PATTERN_ONE
	return pattern[attacks_done % pattern.size()]


func _begin_attack() -> void:
	if jumps_left > 0:
		_jump()
		return
	var attack: Attack = _peek_attack()
	attacks_done += 1
	match attack:
		Attack.JUMP:
			jumps_left = 3 if enraged else 2
			_jump()
		Attack.SUMMON:
			state = State.SUMMON
			state_time = 0.6 if enraged else 0.8
		Attack.CHARGE:
			if _charge_blocked():
				jumps_left = 2 if enraged else 1
				_jump()
			else:
				_start_windup()


func _check_enrage() -> void:
	if enraged or not is_phase_two():
		return
	enraged = true
	Sfx.play("growl")
	GameManager.shake(6.0)
	$AnimatedSprite2D/EyeLeft.color = ANGRY_EYES
	$AnimatedSprite2D/EyeRight.color = ANGRY_EYES


func _jump() -> void:
	var player := _player()
	var target_x: float = player.global_position.x if player else global_position.x
	target_x = clampf(target_x, arena_rect.position.x + 40.0, arena_rect.end.x - 40.0)
	velocity.y = JUMP_VELOCITY
	velocity.x = (target_x - global_position.x) / 0.95
	state = State.JUMP
	state_time = 0.15


func _land() -> void:
	velocity.x = 0.0
	GameManager.shake(7.0)
	Sfx.play("thud")
	for dir in [-1.0, 1.0]:
		var wave: Node2D = SHOCKWAVE.instantiate()
		wave.direction = dir
		wave.speed = 260.0 if enraged else 210.0
		wave.limits = Vector2(arena_rect.position.x, arena_rect.end.x)
		wave.position = position + Vector2(dir * 30.0, FEET)
		get_parent().add_child(wave)
	jumps_left -= 1
	state = State.IDLE
	state_time = 0.3 if jumps_left > 0 else (0.7 if enraged else 1.0)


# Si una plataforma baja le cierra el paso, salta en lugar de embestir contra la nada.
func _charge_blocked() -> bool:
	var player := _player()
	var dx: float = player.global_position.x - global_position.x if player else 1.0
	return test_move(global_transform, Vector2(signf(dx) if dx != 0.0 else 1.0, 0.0) * 160.0)


func _start_windup() -> void:
	var player := _player()
	var dx: float = player.global_position.x - global_position.x if player else 1.0
	charge_dir = signf(dx) if dx != 0.0 else 1.0
	Sfx.play("growl")
	_set_crouch(true)
	state = State.WINDUP
	state_time = 0.55 if enraged else 0.75


func _end_charge(hit_wall: bool) -> void:
	velocity.x = 0.0
	_set_crouch(false)
	if hit_wall:
		GameManager.shake(9.0)
		Sfx.play("thud")
		_drop_rocks(4 if enraged else 3, false)
	state = State.STUNNED
	state_time = 0.7 if enraged else 1.0


# Rodando es mas bajo: se puede saltar por encima, pero hay que leer el aviso.
func _pose_rolled() -> void:
	var squash: float = 0.62
	sprite.scale = base_scale * Vector2(1.15, squash)
	sprite.position.y = base_position.y + 39.0 * base_scale.y * (1.0 - squash)


func _set_crouch(on: bool) -> void:
	var body: RectangleShape2D = body_shape.shape
	var hurt: RectangleShape2D = hurt_shape.shape
	if on:
		body.size = Vector2(56.0, 52.0)
		body_shape.position.y = 22.0
		hurt.size = Vector2(66.0, 56.0)
		hurt_shape.position.y = 22.0
	else:
		body.size = Vector2(56.0, 96.0)
		body_shape.position.y = 0.0
		hurt.size = Vector2(62.0, 100.0)
		hurt_shape.position.y = 0.0


func _drop_rocks(count: int, aim_first: bool = true) -> void:
	var player := _player()
	for i in count:
		var rock: Node2D = FALLING_ROCK.instantiate()
		var x: float = randf_range(arena_rect.position.x + 24.0, arena_rect.end.x - 24.0)
		if aim_first and i < 2 and player:
			x = clampf(player.global_position.x + (i * 36.0), arena_rect.position.x + 24.0, arena_rect.end.x - 24.0)
		rock.global_position = Vector2(x, arena_rect.position.y + 16.0)
		rock.delay = 0.5 + i * 0.2
		get_parent().add_child(rock)
