extends CanvasLayer

@onready var name_label: Label = $Panel/NameLabel
@onready var text_label: Label = $Panel/TextLabel

# NPC con el que el jugador esta en rango de interactuar (null si no hay ninguno).
var nearby_npc: Node = null

var lines: Array = []
var index: int = 0


func _ready() -> void:
	add_to_group("dialogue_box")
	visible = false


func _process(_delta: float) -> void:
	if not Input.is_action_just_pressed("interact"):
		return

	if visible:
		_advance()
	elif nearby_npc != null:
		start(nearby_npc.npc_name, nearby_npc.npc_line, nearby_npc.player_name, nearby_npc.player_line)


func start(npc_name: String, npc_line: String, player_name: String, player_line: String) -> void:
	lines = [
		{"name": npc_name, "text": npc_line},
		{"name": player_name, "text": player_line},
	]
	index = 0
	visible = true
	Player.input_locked = true
	_show_current()


func _show_current() -> void:
	name_label.text = lines[index]["name"]
	text_label.text = lines[index]["text"]


func _advance() -> void:
	index += 1
	if index >= lines.size():
		_close()
	else:
		_show_current()


func _close() -> void:
	visible = false
	Player.input_locked = false
