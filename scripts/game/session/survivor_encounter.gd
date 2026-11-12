extends Node2D
var arena: Node2D
var candidate_id := ""
var label := Label.new()
func _ready():
	var visual = load("res://scripts/art/survivor_visual.gd").new()
	visual.scale = Vector2(2,2); add_child(visual)
	label.position = Vector2(-45,-65); add_child(label)
func _process(_delta):
	var candidate: Dictionary = arena.state.world.recruitment.candidates[candidate_id]
	visible = not candidate.accepted
	label.text = candidate.name + "\nF 交谈"
