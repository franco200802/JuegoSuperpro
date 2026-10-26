class_name Boss
extends Enemy

# Base de los jefes: no se mueven hasta que la arena los activa,
# avisan al HUD para la barra de vida y tienen una segunda fase con la mitad de vida.

@export var boss_name: String = "Jefe"

var active: bool = false
# Zona de la pelea (en coordenadas globales), la pasa la arena.
var arena_rect: Rect2
var state_time: float = 0.0


func start(rect: Rect2) -> void:
	arena_rect = rect
	active = true
	GameManager.boss_started.emit(boss_name, max_health)


func _physics_process(delta: float) -> void:
	if not active and not is_dead:
		_apply_gravity(delta)
		move_and_slide()
		return
	super(delta)


func is_phase_two() -> bool:
	return health <= max_health / 2


func _on_hit() -> void:
	GameManager.boss_health_changed.emit(maxi(health, 0))


func die() -> void:
	super()
	GameManager.shake(8.0)
	GameManager.boss_ended.emit()
