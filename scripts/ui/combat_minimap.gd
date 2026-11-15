extends Control
var arena:Node2D
func _process(_dt):queue_redraw()
func _draw():
 if arena==null:return
 if arena.get('grid')!=null and arena.state.base.has('bounds'):
  draw_base_map()
  return
 draw_rect(Rect2(0,0,200,126),Color("151919"))
 draw_rect(Rect2(0,0,200,126),Color('4b504b'),false,2)
 draw_rect(Rect2(81,31,6,40),Color('869099'))
 draw_circle(arena.player.global_position/8,3,Color.CYAN)
 var viewport_rect:=get_viewport_rect()
 for target in arena.targets:
  if target.has_method('visible_to_player'):
   if target.get_meta('hp')>0 and target.visible_to_player():draw_circle(target.global_position/8,2,Color.SALMON)
   continue
  var screen:Vector2=arena.get_global_transform_with_canvas()*target.global_position
  if target.get_meta('hp')>0 and viewport_rect.has_point(screen) and arena.clear_line(arena.player.global_position,target.global_position):draw_circle(target.global_position/8,2,Color.SALMON)

func draw_base_map():
 var projection:GridProjection=arena.grid
 var logical:Rect2=preload('res://scripts/base/base_geometry.gd').bounds_rect(arena.state.base.bounds)
 var bounds:=projection.world_bounds(logical).grow(48)
 var factor:=minf((size.x-16)/bounds.size.x,(size.y-16)/bounds.size.y)
 var origin:Vector2=(size-bounds.size*factor)*.5
 draw_rect(Rect2(Vector2.ZERO,size),Color('171e25'))
 var outline:=PackedVector2Array()
 for point in projection.rect_polygon(logical):outline.append(origin+(point-bounds.position)*factor)
 draw_colored_polygon(outline,Color('303e43'))
 var edges:=outline.duplicate();edges.append(outline[0]);draw_polyline(edges,Color('68797a'),1)
 for id in arena.state.base.buildings:
  var b:Dictionary=arena.state.base.buildings[id]
  var dimensions:Array=arena.building.config.types[b.type].size
  var footprint:=PackedVector2Array()
  for point in projection.rect_polygon(Rect2(Vector2(b.cell[0],b.cell[1])*48,Vector2(dimensions[0],dimensions[1])*48)):
   footprint.append(origin+(point-bounds.position)*factor)
  draw_colored_polygon(footprint,Color('567f85') if b.type in ['generator','warehouse'] else Color('929784'))
 var marker:Vector2=origin+(arena.player.global_position-bounds.position)*factor
 draw_rect(Rect2(marker-Vector2(2,2),Vector2(4,4)),Color('83e4dd'))
 for target in arena.targets:
  if target.get_meta('hp',0)>0 and target.visible and arena.clear_line(arena.player.global_position,target.global_position):
   var p:Vector2=origin+(target.global_position-bounds.position)*factor
   if Rect2(Vector2.ZERO,size).has_point(p):draw_rect(Rect2(p-Vector2.ONE,Vector2(2,2)),Color('df7378'))


