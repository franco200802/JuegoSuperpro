extends Enemy

# Caracol que patrulla: camina hasta una pared o un borde y se da vuelta.

@export var speed: float = 28.0

@onready var ledge_check: RayCast2D = $LedgeCheck

var direction: float = -1.0


func _behave(delta: float) -> void:
	_apply_gravity(delta)
	if is_on_floor() and (is_on_wall() or not ledge_check.is_colliding()):
		direction = -direction
	ledge_check.position.x = 14.0 * direction
	velocity.x = direction * speed
	sprite.flip_h = direction > 0.0
