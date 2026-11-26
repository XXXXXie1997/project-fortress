extends Node2D
var arena: Node2D
var candidate_id := ""
var label := Label.new()
func _ready():
	preload("res://scripts/ui/wasteland_theme.gd").apply(label)
	var visual = load("res://scripts/art/survivor_visual.gd").new()
	visual.scale = Vector2(2,2); add_child(visual)
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	label.size=Vector2(160,44)
	label.position=Vector2(-80,-76)
	label.add_theme_color_override("font_shadow_color",Color.BLACK)
	label.add_theme_constant_override("shadow_offset_y",1)
	add_child(label)
func _process(_delta):
	var screen_scale:float=(get_viewport().get_stretch_transform()*label.get_global_transform_with_canvas()).get_scale().x
	label.add_theme_font_size_override('font_size',maxi(preload("res://scripts/ui/keeper_theme.gd").FONT_BODY,ceili(10.0/maxf(.01,screen_scale))))
	var candidate: Dictionary = arena.state.world.recruitment.candidates[candidate_id]
	visible = not candidate.accepted
	var nearby:bool=arena.player.position.distance_to(position)<70 and arena.clear_line(arena.player.position,position,41)
	label.text = candidate.name + ("\n[F] 交谈" if nearby else "")
