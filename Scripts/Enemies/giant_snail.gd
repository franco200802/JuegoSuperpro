extends Boss

# Caracol Gigante: se arrastra hacia el jugador, se esconde en el caparazon y embiste
# hasta chocar contra una pared. Solo se le puede pegar cuando esta afuera del caparazon.
# Segunda fase: embiste mas rapido y al salir del caparazon llama a una cria.

enum State { CRAWL, HIDE, CHARGE, STUNNED, UNHIDE }

const SNAIL := preload("res://Scenes/Enemies/Snail.tscn")
const MAX_MINIONS: int = 2

@export var crawl_speed: float = 35.0
@export var charge_speed: float = 240.0

var state: State = State.CRAWL
var direction: float = -1.0
var minions: Array[Node] = []


func start(rect: Rect2) -> void:
	super(rect)
	_set_state(State.CRAWL, 1.5)


func _behave(delta: float) -> void:
	_apply_gravity(delta)
	state_time -= delta
	var player := _player()

	match state:
		State.CRAWL:
			if player:
				direction = signf(player.global_position.x - global_position.x)
			velocity.x = direction * crawl_speed
			if state_time <= 0.0:
				velocity.x = 0.0
				sprite.play("hide")
				_set_state(State.HIDE, 0.6)
		State.HIDE:
			velocity.x = 0.0
			if state_time <= 0.0:
				if player:
					direction = signf(player.global_position.x - global_position.x)
				_set_state(State.CHARGE, 3.0)
		State.CHARGE:
			velocity.x = direction * charge_speed * (1.35 if is_phase_two() else 1.0)
			if is_on_wall() or state_time <= 0.0:
				GameManager.shake(6.0)
				velocity.x = 0.0
				knockback = -direction * 120.0
				_set_state(State.STUNNED, 0.9)
		State.STUNNED:
			velocity.x = 0.0
			if state_time <= 0.0:
				sprite.play_backwards("hide")
				if is_phase_two():
					_spawn_minion()
				_set_state(State.UNHIDE, 0.5)
		State.UNHIDE:
			velocity.x = 0.0
			if state_time <= 0.0:
				sprite.play("walk")
				_set_state(State.CRAWL, randf_range(2.0, 3.0))

	if state != State.CHARGE:
		sprite.flip_h = direction > 0.0


func can_be_hit() -> bool:
	return state == State.CRAWL or state == State.UNHIDE


func _set_state(new_state: State, duration: float) -> void:
	state = new_state
	state_time = duration


func _spawn_minion() -> void:
	minions = minions.filter(func(m: Node) -> bool: return is_instance_valid(m) and not m.is_dead)
	if minions.size() >= MAX_MINIONS:
		return
	var snail: Enemy = SNAIL.instantiate()
	snail.position = position + Vector2(-direction * 40.0, 32.0)
	get_parent().add_child(snail)
	minions.append(snail)


func die() -> void:
	for minion in minions:
		if is_instance_valid(minion):
			minion.die()
	super()
