extends Area2D

const TEXTURE := preload("res://Assets/Sprites/Assets/Hive.png")
const REGION := Rect2(0, 160, 16, 16)
const TILE: float = 16.0

@export var length: int = 3


func _ready() -> void:
	add_to_group("spikes")
	var shape := RectangleShape2D.new()
	shape.size = Vector2(length * TILE - 6.0, 8.0)
	$CollisionShape2D.shape = shape
	$CollisionShape2D.position = Vector2(length * TILE / 2.0, -4.0)
	for i in length:
		var sprite := Sprite2D.new()
		sprite.texture = TEXTURE
		sprite.region_enabled = true
		sprite.region_rect = REGION
		sprite.centered = false
		sprite.position = Vector2(i * TILE, -TILE)
		add_child(sprite)


func _physics_process(_delta: float) -> void:
	for body in get_overlapping_bodies():
		if body.is_in_group("player"):
			body.hurt_by_hazard()
