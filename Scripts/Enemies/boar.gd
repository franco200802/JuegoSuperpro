extends Enemy

enum State { PATROL, ALERT, CHARGE, STUNNED }

const ALERT_TIME: float = 0.45
const CHARGE_TIME: float = 1.6
const STUN_TIME: float = 1.1
const BRAKE_TIME: float = 0.5

@export var walk_speed: float = 32.0
@export var charge_speed: float = 230.0
@export var sight_range: float = 190.0

@onready var ledge_check: RayCast2D = $LedgeCheck

var state: State = State.PATROL
var state_time: float = 0.0
var direction: float = -1.0


func _behave(delta: float) -> void:
	_apply_gravity(delta)
	state_time -= delta

	match state:
		State.PATROL:
			if is_on_floor() and (is_on_wall() or not ledge_check.is_colliding()):
				direction = -direction
			velocity.x = direction * walk_speed
			if state_time <= 0.0 and _sees_player():
				direction = signf(_player().global_position.x - global_position.x)
				sprite.play("idle")
				Sfx.play("growl")
				_set_state(State.ALERT, ALERT_TIME)
		State.ALERT:
			velocity.x = 0.0
			sprite.position.x = randf_range(-1.0, 1.0)
			if state_time <= 0.0:
				sprite.position.x = 0.0
				sprite.play("run")
				_set_state(State.CHARGE, CHARGE_TIME)
		State.CHARGE:
			velocity.x = direction * charge_speed
			if is_on_wall():
				GameManager.shake(4.0)
				Sfx.play("thud")
				knockback = -direction * 100.0
				sprite.play("idle")
				sprite.rotation = -0.2 * direction
				_set_state(State.STUNNED, STUN_TIME)
			elif not ledge_check.is_colliding() or state_time <= 0.0:
				velocity.x = 0.0
				sprite.play("idle")
				_set_state(State.STUNNED, BRAKE_TIME)
		State.STUNNED:
			velocity.x = 0.0
			if state_time <= 0.0:
				sprite.rotation = 0.0
				sprite.play("walk")
				_set_state(State.PATROL, 0.8)

	ledge_check.position.x = 16.0 * direction
	sprite.flip_h = direction > 0.0


func _sees_player() -> bool:
	var player := _player()
	if player == null:
		return false
	var offset: Vector2 = player.global_position - global_position
	if absf(offset.y) > 28.0 or absf(offset.x) > sight_range:
		return false
	if signf(offset.x) != direction and absf(offset.x) > 60.0:
		return false
	var query := PhysicsRayQueryParameters2D.create(global_position, player.global_position, 1)
	query.exclude = [get_rid(), player.get_rid()]
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()


func _set_state(new_state: State, duration: float) -> void:
	state = new_state
	state_time = duration
