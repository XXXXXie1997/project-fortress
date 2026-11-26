extends Node2D
## World-anchored status bars and reticle, composited above the depth pass.
var stage: Node2D
func _process(_dt: float) -> void:queue_redraw()
func _draw() -> void:
	if not is_instance_valid(stage):return
	var arena: Node2D=stage.geometry.arena
	var inv := get_global_transform_with_canvas().affine_inverse()
	for source: Node2D in stage.overlays:
		if source.get_script()!=preload("res://scripts/game/session/survivor_encounter.gd") or not source.visible:continue
		if not stage.visible_at(source.position) or not arena.clear_line(arena.player.position,source.position,1):continue
		var pos:Vector2=inv*(source.get_global_transform_with_canvas()*Vector2(0,-73))
		var name_text:String=source.label.text.get_slice("\n",0)
		draw_string(ThemeDB.fallback_font,pos-Vector2(77,0),name_text,HORIZONTAL_ALIGNMENT_CENTER,154,14,Color("#ece6cb"))
		if source.position.distance_to(arena.player.position)<75:
			draw_string(ThemeDB.fallback_font,pos-Vector2(77,-15),"F 交谈",HORIZONTAL_ALIGNMENT_CENTER,154,13,Color.WHITE)
	for target in arena.targets:
		if not is_instance_valid(target) or not target.visible or not stage.actors.has(target):continue
		var record: Dictionary=target.record()
		if record.vitals.hp<=0:continue
		var avatar: Node3D=stage.actors[target]
		var head:=Vector2(0,-1.9*avatar.size_factor*stage.CELL_PIXELS*cos(PI/6)-5)
		var anchor:Vector2=inv*(target.get_global_transform_with_canvas()*head)
		var width:=40.0
		var x:=anchor-Vector2(width*.5,0)
		draw_line(x,x+Vector2(width,0),Color("#352a25"),3.)
		draw_line(x,x+Vector2(width*record.vitals.hp/target.spec.hp,0),Color("#bc5142"),2.)
		if target.spec.armor>0:
			draw_line(x-Vector2(0,4),x-Vector2(0,4)+Vector2(width*record.armor.durability/target.spec.armor,0),Color("#86b4c0"),2.)
		if record.meter>0 and not record.alerted:
			draw_line(x-Vector2(0,7),x-Vector2(0,7)+Vector2(width*record.meter,0),Color.GOLD,2.)
		if record.attack_left>0 or record.call_left>0:
			draw_arc(anchor+Vector2(0,-6),4.,0.,TAU,12,Color.ORANGE,2.)
	var player:Node2D=arena.player
	var state: Dictionary=arena.state.player.combat
	var cursor:=get_local_mouse_position()+Vector2.DOWN*8
	draw_arc(cursor,9.,0,PI*state.stamina/player.effective_config().max_stamina,24,Color.RED if state.exhausted else Color.YELLOW,1.5)
