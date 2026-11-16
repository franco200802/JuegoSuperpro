extends Enemy

const HIDE_TIME: float = 0.5

@export var speed: float = 28.0

@onready var ledge_check: RayCast2D = $LedgeCheck

var direction: float = -1.0
var hide_left: float = 0.0


func _behave(delta: float) -> void:
	_apply_gravity(delta)
	if hide_left > 0.0:
		hide_left -= delta
		velocity.x = 0.0
		if hide_left <= 0.0:
			sprite.play("walk")
		return
	if is_on_floor() and (is_on_wall() or not ledge_check.is_colliding()):
		direction = -direction
	ledge_check.position.x = 14.0 * direction
	velocity.x = direction * speed
	sprite.flip_h = direction > 0.0


func can_be_hit() -> bool:
	return hide_left <= 0.0


func _on_hit() -> void:
	hide_left = HIDE_TIME
	sprite.play("hide")
