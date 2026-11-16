extends Enemy

enum State { IDLE, HOVER, WINDUP, DIVE, RECOVER }

const WINDUP_TIME: float = 0.5
const DIVE_TIME: float = 0.7
const RECOVER_TIME: float = 0.7

@export var sight_range: float = 210.0
@export var hover_speed: float = 80.0
@export var dive_speed: float = 270.0

var state: State = State.IDLE
var state_time: float = 0.0
var time: float = 0.0
var home: Vector2
var dive_direction := Vector2.ZERO


func _ready() -> void:
	super()
	home = global_position
	time = randf() * TAU


func _behave(delta: float) -> void:
	time += delta
	state_time -= delta
	var player := _player()
	if player == null:
		_fly_towards(home, hover_speed * 0.5, delta)
		return

	match state:
		State.IDLE:
			_fly_towards(home + Vector2(0, sin(time * 3.0) * 6.0), hover_speed * 0.5, delta)
			if global_position.distance_to(player.global_position) < sight_range:
				_set_state(State.HOVER, randf_range(1.2, 1.8))
		State.HOVER:
			var side: float = 1.0 if global_position.x >= player.global_position.x else -1.0
			var spot: Vector2 = player.global_position + Vector2(side * 70.0, -64.0 + sin(time * 4.0) * 8.0)
			_fly_towards(spot, hover_speed, delta)
			if state_time <= 0.0:
				sprite.play("attack")
				Sfx.play("buzz")
				_set_state(State.WINDUP, WINDUP_TIME)
		State.WINDUP:
			velocity = velocity.move_toward(Vector2.ZERO, 600.0 * delta)
			sprite.position = Vector2(randf_range(-1.5, 1.5), randf_range(-1.5, 1.5))
			dive_direction = global_position.direction_to(player.global_position + Vector2(0, -4))
			if state_time <= 0.0:
				sprite.position = Vector2.ZERO
				_set_state(State.DIVE, DIVE_TIME)
		State.DIVE:
			velocity = dive_direction * dive_speed
			if get_slide_collision_count() > 0 or state_time <= 0.0:
				sprite.play("fly")
				_set_state(State.RECOVER, RECOVER_TIME)
		State.RECOVER:
			velocity = velocity.move_toward(Vector2(0, -hover_speed * 0.6), 500.0 * delta)
			if state_time <= 0.0:
				_set_state(State.HOVER, randf_range(1.0, 1.6))

	if state == State.DIVE:
		sprite.flip_h = dive_direction.x > 0.0
	else:
		sprite.flip_h = player.global_position.x > global_position.x


func _fly_towards(target: Vector2, speed: float, delta: float) -> void:
	var to_target: Vector2 = target - global_position
	var desired: Vector2 = to_target.normalized() * speed if to_target.length() > 4.0 else Vector2.ZERO
	velocity = velocity.move_toward(desired, 300.0 * delta)


func _set_state(new_state: State, duration: float) -> void:
	state = new_state
	state_time = duration
