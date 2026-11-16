extends Node2D

const LIFETIME: float = 0.12
const SEGMENTS: int = 10

const NORMAL_COLOR := Color(1.0, 0.97, 0.88, 0.8)
const BLADE_COLOR := Color(0.55, 1.0, 0.45, 0.9)

var time_left: float = 0.0
var color: Color = NORMAL_COLOR


func _ready() -> void:
	visible = false


func play(direction: Vector2, blade: bool = false) -> void:
	rotation = direction.angle()
	scale = Vector2.ONE * (1.35 if blade else 1.0)
	color = BLADE_COLOR if blade else NORMAL_COLOR
	time_left = LIFETIME
	visible = true
	queue_redraw()


func _process(delta: float) -> void:
	if time_left <= 0.0:
		return
	time_left -= delta
	if time_left <= 0.0:
		visible = false
	queue_redraw()


func _draw() -> void:
	var progress: float = 1.0 - time_left / LIFETIME
	var sweep: float = lerpf(0.6, 1.2, progress)
	var points := PackedVector2Array()
	for i in SEGMENTS + 1:
		var angle: float = lerpf(-sweep, sweep, float(i) / SEGMENTS)
		points.append(Vector2(8.0, 0.0) + Vector2.from_angle(angle) * 24.0)
	for i in range(SEGMENTS, -1, -1):
		var angle: float = lerpf(-sweep, sweep, float(i) / SEGMENTS) * 0.8
		points.append(Vector2.from_angle(angle) * 22.0)
	draw_colored_polygon(points, Color(color.r, color.g, color.b, color.a * (1.0 - progress)))
