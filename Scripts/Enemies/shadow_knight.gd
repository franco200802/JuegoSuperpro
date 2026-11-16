extends Boss

enum State { CHASE, SLASH, DASH_WINDUP, DASH, JUMP_ATTACK, RECOVER }

const RUN_SPEED: float = 115.0
const DASH_SPEED: float = 400.0
const DASH_TIME: float = 0.32
const SLASH_RANGE: float = 48.0
const SLASH_OFFSET: float = 28.0
const BASE_COLOR := Color(0.38, 0.28, 0.55)

@onready var slash: Area2D = $Slash

var state: State = State.CHASE
var facing: float = -1.0
var combo_left: int = 0
var dashes_left: int = 0
var slash_active: bool = false
var last_warning_ms: int = -10000


func _ready() -> void:
	super()
	sprite.self_modulate = BASE_COLOR
	sprite.animation_finished.connect(_on_animation_finished)


func start(rect: Rect2) -> void:
	super(rect)
	_set_state(State.CHASE, 1.0)


func _behave(delta: float) -> void:
	state_time -= delta
	var player := _player()
	var dx: float = player.global_position.x - global_position.x if player else 0.0
	var speed: float = RUN_SPEED * (1.3 if is_phase_two() else 1.0)

	if state == State.DASH:
		velocity.y = 0.0
	else:
		_apply_gravity(delta)

	match state:
		State.CHASE:
			facing = signf(dx) if dx != 0.0 else facing
			velocity.x = move_toward(velocity.x, facing * speed, 800.0 * delta)
			_play_move_animation()
			if absf(dx) < SLASH_RANGE and is_on_floor():
				combo_left = 2 if is_phase_two() else 1
				_start_slash()
			elif state_time <= 0.0 and is_on_floor():
				if absf(dx) > 120.0 or randf() < 0.4:
					dashes_left = 2 if is_phase_two() else 1
					_start_dash_windup()
				else:
					_start_jump_attack(dx)
		State.SLASH:
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
		State.DASH_WINDUP:
			velocity.x = 0.0
			sprite.self_modulate = BASE_COLOR.lerp(Color(1.6, 1.2, 2.0), 0.5 + 0.5 * sin(state_time * 40.0))
			if state_time <= 0.0:
				sprite.self_modulate = BASE_COLOR
				sprite.play("attack_b")
				Sfx.play("dash")
				slash_active = true
				_set_state(State.DASH, DASH_TIME)
		State.DASH:
			velocity.x = facing * DASH_SPEED
			if state_time <= 0.0 or is_on_wall():
				slash_active = false
				velocity.x = 0.0
				dashes_left -= 1
				if dashes_left > 0:
					facing = signf(dx) if dx != 0.0 else -facing
					_start_dash_windup(0.25)
				else:
					_set_state(State.RECOVER, 0.6)
		State.JUMP_ATTACK:
			if velocity.y > 0.0 and not slash_active and sprite.animation != "attack_a":
				sprite.play("attack_a")
				slash_active = true
			if is_on_floor() and state_time <= 0.0:
				slash_active = false
				_set_state(State.RECOVER, 0.5)
		State.RECOVER:
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			if is_on_floor():
				sprite.play("idle")
			if state_time <= 0.0:
				_set_state(State.CHASE, randf_range(1.0, 1.8) * (0.7 if is_phase_two() else 1.0))

	sprite.flip_h = facing < 0.0
	slash.position.x = SLASH_OFFSET * facing
	if slash_active:
		_slash_damage()


func _on_blocked_hit(from_position: Vector2) -> void:
	super(from_position)
	if Time.get_ticks_msec() - last_warning_ms < 4000:
		return
	last_warning_ms = Time.get_ticks_msec()
	GameManager.notice.emit("Tus golpes no la atraviesan: la Sombra solo teme a la Hoja de Musgo")


func _start_slash() -> void:
	velocity.x = facing * 60.0
	sprite.play("attack_a" if combo_left % 2 == 1 else "attack_b")
	Sfx.play("attack")
	slash_active = true
	_set_state(State.SLASH, 0.4)


func _start_dash_windup(duration: float = 0.45) -> void:
	_set_state(State.DASH_WINDUP, duration)
	sprite.play("idle")
	Sfx.play("growl")


func _start_jump_attack(dx: float) -> void:
	facing = signf(dx) if dx != 0.0 else facing
	velocity.y = -360.0
	velocity.x = clampf(dx / 0.8, -220.0, 220.0)
	sprite.play("jump")
	_set_state(State.JUMP_ATTACK, 0.2)


func _on_animation_finished() -> void:
	if state == State.SLASH and sprite.animation.begins_with("attack"):
		slash_active = false
		combo_left -= 1
		if combo_left > 0:
			_start_slash()
		else:
			_set_state(State.RECOVER, 0.5)
	elif sprite.animation.begins_with("attack"):
		slash_active = false


func _slash_damage() -> void:
	for body in slash.get_overlapping_bodies():
		if body.is_in_group("player"):
			body.take_damage(1, global_position)


func _play_move_animation() -> void:
	if not is_on_floor():
		sprite.play("jump" if velocity.y < 0.0 else "fall")
	elif absf(velocity.x) > 10.0:
		sprite.play("run")
	else:
		sprite.play("idle")


func _set_state(new_state: State, duration: float) -> void:
	state = new_state
	state_time = duration
