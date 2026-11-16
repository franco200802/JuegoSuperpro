extends Area2D

const GRAVITY: float = 900.0

var delay: float = 0.5
var velocity: float = 0.0
var falling: bool = false


func _ready() -> void:
	add_to_group("hazards")
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if not falling:
		delay -= delta
		$Sprite2D.position.x = randf_range(-1.5, 1.5)
		if delay <= 0.0:
			falling = true
			$Sprite2D.position.x = 0.0
		return
	velocity = minf(velocity + GRAVITY * delta, 500.0)
	position.y += velocity * delta


func _on_body_entered(body: Node) -> void:
	if not falling:
		return
	if body.is_in_group("player"):
		body.take_damage(1, global_position)
		_break()
	elif not body.is_in_group("enemies"):
		_break()


func _break() -> void:
	set_deferred("monitoring", false)
	falling = false
	set_physics_process(false)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.4, 0.3), 0.08)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.25)
	tween.tween_callback(queue_free)
