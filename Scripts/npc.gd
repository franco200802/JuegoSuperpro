extends Area2D

@export var npc_name: String = "Caracol"
@export var npc_line: String = "Mas adelante hay lugares a los que todavia no podras llegar."
@export var player_name: String = "Protagonista"
@export var player_line: String = "Entonces tendre que volver cuando consiga nuevas habilidades."

@onready var prompt: Label = $InteractPrompt

var dialogue_box: Node = null


func _ready() -> void:
	prompt.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _get_dialogue_box() -> Node:
	if dialogue_box == null:
		dialogue_box = get_tree().get_first_node_in_group("dialogue_box")
	return dialogue_box


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		var box: Node = _get_dialogue_box()
		if box:
			box.nearby_npc = self


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		var box: Node = _get_dialogue_box()
		if box and box.nearby_npc == self:
			box.nearby_npc = null


func _process(_delta: float) -> void:
	var box: Node = _get_dialogue_box()
	var is_near: bool = box != null and box.nearby_npc == self
	prompt.visible = is_near and not box.visible
