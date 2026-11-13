extends Control
var arena:Node2D
func _process(_dt):queue_redraw()
func _draw():
 if arena==null:return
 draw_rect(Rect2(0,0,180,124),Color("151919"))
 draw_rect(Rect2(0,0,180,120),Color('4b504b'),false,2)
 draw_rect(Rect2(81,31,6,40),Color('869099'))
 draw_circle(arena.player.global_position/8,3,Color.CYAN)
 var viewport_rect:=get_viewport_rect()
 for target in arena.targets:
  if target.has_method('visible_to_player'):
   if target.get_meta('hp')>0 and target.visible_to_player():draw_circle(target.global_position/8,2,Color.SALMON)
   continue
  var screen:Vector2=arena.get_global_transform_with_canvas()*target.global_position
  if target.get_meta('hp')>0 and viewport_rect.has_point(screen) and arena.clear_line(arena.player.global_position,target.global_position):draw_circle(target.global_position/8,2,Color.SALMON)


