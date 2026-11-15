extends Node2D
var arena: Node2D
var candidate_id := ""
var label := Label.new()
func _ready():
	preload("res://scripts/ui/wasteland_theme.gd").apply(label)
	var visual = load("res://scripts/art/survivor_visual.gd").new()
	visual.scale = Vector2(2,2); add_child(visual)
	label.position = Vector2(-45,-65); add_child(label)
func _process(_delta):
	var screen_scale:float=(get_viewport().get_stretch_transform()*label.get_global_transform_with_canvas()).get_scale().x
	label.add_theme_font_size_override('font_size',maxi(24,ceili(10.0/maxf(.01,screen_scale))))
	var candidate: Dictionary = arena.state.world.recruitment.candidates[candidate_id]
	visible = not candidate.accepted
	label.text = candidate.name + "\nF 交谈"
