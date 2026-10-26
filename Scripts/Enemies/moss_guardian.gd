extends Boss

# Guardian de Musgo: un monolito que salta hacia el jugador y al caer manda
# dos ondas por el piso. Cada tanto sacude el techo y caen rocas.
# Segunda fase: encadena dos saltos y caen mas rocas.

enum State { IDLE, JUMP, SUMMON }

const SHOCKWAVE := preload("res://Scenes/Enemies/Shockwave.tscn")
const FALLING_ROCK := preload("res://Scenes/Enemies/FallingRock.tscn")
const JUMP_VELOCITY: float = -430.0
const AIR_TIME: float = 0.95
# Distancia del centro a los pies.
const FEET: float = 48.0

var state: State = State.IDLE
var jumps_left: int = 0
var attacks_done: int = 0
var base_scale: Vector2
var time: float = 0.0


func _ready() -> void:
	super()
	base_scale = sprite.scale


func start(rect: Rect2) -> void:
	super(rect)
	state_time = 1.0


func _behave(delta: float) -> void:
	_apply_gravity(delta)
	state_time -= delta
	time += delta
	sprite.scale = base_scale

	match state:
		State.IDLE:
			velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
			sprite.scale.y = base_scale.y * (1.0 + sin(time * 6.0) * 0.03)
			if state_time <= 0.0 and is_on_floor():
				attacks_done += 1
				if jumps_left > 0:
					# Segundo salto de la cadena: no se corta con una invocacion.
					_jump()
				elif attacks_done % 3 == 0:
					state = State.SUMMON
					state_time = 0.8
				else:
					jumps_left = 2 if is_phase_two() else 1
					_jump()
		State.JUMP:
			if is_on_floor() and state_time <= 0.0:
				_land()
		State.SUMMON:
			velocity.x = 0.0
			sprite.position.x = randf_range(-2.0, 2.0)
			if state_time <= 0.0:
				sprite.position.x = 0.0
				_drop_rocks(6 if is_phase_two() else 4)
				state = State.IDLE
				state_time = 1.2


func _jump() -> void:
	var player := _player()
	var target_x: float = player.global_position.x if player else global_position.x
	target_x = clampf(target_x, arena_rect.position.x + 40.0, arena_rect.end.x - 40.0)
	velocity.y = JUMP_VELOCITY
	velocity.x = (target_x - global_position.x) / AIR_TIME
	state = State.JUMP
	# Evita detectar el piso en el mismo cuadro del salto.
	state_time = 0.15


func _land() -> void:
	velocity.x = 0.0
	GameManager.shake(7.0)
	for dir in [-1.0, 1.0]:
		var wave: Node2D = SHOCKWAVE.instantiate()
		wave.direction = dir
		wave.limits = Vector2(arena_rect.position.x, arena_rect.end.x)
		wave.position = position + Vector2(dir * 30.0, FEET)
		get_parent().add_child(wave)
	jumps_left -= 1
	state = State.IDLE
	# Pausa corta entre los saltos de una cadena y descanso al terminarla.
	state_time = 0.35 if jumps_left > 0 else 1.3


func _drop_rocks(count: int) -> void:
	var player := _player()
	for i in count:
		var rock: Node2D = FALLING_ROCK.instantiate()
		var x: float = randf_range(arena_rect.position.x + 24.0, arena_rect.end.x - 24.0)
		# La primera siempre cae sobre el jugador.
		if i == 0 and player:
			x = player.global_position.x
		rock.global_position = Vector2(x, arena_rect.position.y + 16.0)
		rock.delay = 0.5 + i * 0.25
		get_parent().add_child(rock)
