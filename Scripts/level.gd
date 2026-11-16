extends Room

const TERRAINS := {
	"grass": {"overlay": 0, "top": 1, "middle": [2, 3], "bottom": 4},
	"stone": {"overlay": 5, "top": 6, "middle": [7, 8], "bottom": 9},
}
const PLATFORMS := {
	"grass": [Vector2i(0, 1), Vector2i(2, 1), Vector2i(4, 1)],
	"plank": [Vector2i(5, 6), Vector2i(6, 6), Vector2i(7, 6)],
	"brick": [Vector2i(11, 15), Vector2i(12, 15), Vector2i(13, 15)],
}
const BACK_WALLS := {
	"stone": [Vector2i(1, 7), Vector2i(2, 7), Vector2i(3, 7), Vector2i(1, 8), Vector2i(2, 8), Vector2i(3, 8)],
	"brick": [Vector2i(10, 12), Vector2i(11, 12), Vector2i(12, 12), Vector2i(10, 13), Vector2i(11, 13), Vector2i(12, 13)],
}
const BACK_WALL_COLORS := {"stone": Color(0.65, 0.65, 0.75), "brick": Color(0.55, 0.55, 0.65)}
const FALL_MARGIN: float = 244.0

@export var map: Array[String] = []
@export var camera_margin_top: int = 120
@export var camera_margin_bottom: int = 44
@export_enum("grass", "stone") var terrain: String = "grass"
@export_enum("grass", "plank", "brick") var platform_style: String = "grass"
@export_enum("none", "stone", "brick") var back_wall: String = "none"

@onready var ground: TileMapLayer = $Ground

var fall_limit: float


func _ready() -> void:
	_build_map()
	super()
	fall_limit = map.size() * ground.tile_set.tile_size.y + FALL_MARGIN
	if player:
		player.safe_position = player.global_position
		_fit_camera_to_map()


func _process(_delta: float) -> void:
	if player and player.global_position.y > fall_limit:
		player.hurt_by_hazard()


func _build_map() -> void:
	var style: Dictionary = TERRAINS[terrain]
	var platform: Array = PLATFORMS[platform_style]
	for y in map.size():
		for x in map[y].length():
			if not _is_solid(x, y):
				continue
			var open_left: bool = not _is_solid(x - 1, y)
			var open_right: bool = not _is_solid(x + 1, y)
			var open_up: bool = not _is_solid(x, y - 1)
			var open_down: bool = not _is_solid(x, y + 1)
			var col: int = _edge_column(x, y, open_left, open_right)

			if open_up and open_down:
				var i: int = 0 if open_left and not open_right else (2 if open_right and not open_left else 1)
				ground.set_cell(Vector2i(x, y), 0, platform[i])
				if platform_style == "grass":
					ground.set_cell(Vector2i(x, y - 1), 0, Vector2i(col, style.overlay))
				continue

			var row: int = style.middle[(x + y) % style.middle.size()]
			if open_up:
				row = style.top
			elif open_down:
				row = style.bottom
			ground.set_cell(Vector2i(x, y), 0, Vector2i(col, row))
			if open_up and y > 0:
				ground.set_cell(Vector2i(x, y - 1), 0, Vector2i(col, style.overlay))

	if back_wall != "none":
		_build_back_wall()


func _edge_column(x: int, y: int, open_left: bool, open_right: bool) -> int:
	if open_left and not open_right:
		return 0
	if open_right and not open_left:
		return 4
	return 1 + (x * 7 + y * 3) % 3


func _build_back_wall() -> void:
	var layer := TileMapLayer.new()
	layer.name = "BackWall"
	layer.tile_set = ground.tile_set
	layer.collision_enabled = false
	layer.modulate = BACK_WALL_COLORS[back_wall]
	add_child(layer)
	move_child(layer, ground.get_index())
	var tiles: Array = BACK_WALLS[back_wall]
	for y in map.size():
		for x in map[y].length():
			if not _is_solid(x, y):
				layer.set_cell(Vector2i(x, y), 0, tiles[(x * 5 + y * 3) % tiles.size()])


func _is_solid(x: int, y: int) -> bool:
	if y < 0 or y >= map.size() or x < 0 or x >= map[y].length():
		return true
	return map[y][x] == "#"


func _fit_camera_to_map() -> void:
	var camera: Camera2D = player.get_node_or_null("Camera2D")
	if camera == null or map.is_empty():
		return
	var tile: Vector2i = ground.tile_set.tile_size
	camera.limit_left = 0
	camera.limit_right = map[0].length() * tile.x
	camera.limit_top = -camera_margin_top
	camera.limit_bottom = map.size() * tile.y + camera_margin_bottom
