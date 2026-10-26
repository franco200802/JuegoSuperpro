extends Enemy

# Murcielago: flota quieto hasta ver al jugador y despues lo persigue en zigzag.

@export var speed: float = 65.0
@export var sight_range: float = 170.0

var time: float = 0.0
var home: Vector2
var awake: bool = false


func _ready() -> void:
	super()
	home = global_position
	time = randf() * TAU


func _behave(delta: float) -> void:
	time += delta
	var player := _player()
	if player and not awake and global_position.distance_to(player.global_position) < sight_range:
		awake = true

	var target: Vector2 = home
	if awake and player:
		target = player.global_position + Vector2(0, -6)
	var to_target := target - global_position
	var desired := Vector2.ZERO
	if to_target.length() > 4.0:
		desired = to_target.normalized() * speed
	desired.y += sin(time * 5.0) * 30.0
	velocity = velocity.move_toward(desired, 240.0 * delta)
	sprite.flip_h = velocity.x > 0.0
