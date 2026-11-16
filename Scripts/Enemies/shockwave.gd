extends Area2D

const SPEED: float = 210.0

var direction: float = 1.0
var speed: float = SPEED
var limits := Vector2(-INF, INF)


func _ready() -> void:
	add_to_group("hazards")
	$Sprite2D.flip_h = direction < 0.0


func _physics_process(delta: float) -> void:
	position.x += direction * speed * delta
	for body in get_overlapping_bodies():
		if body.is_in_group("player"):
			body.take_damage(1, global_position - Vector2(direction * 20.0, 0.0))
	if global_position.x < limits.x or global_position.x > limits.y:
		queue_free()
