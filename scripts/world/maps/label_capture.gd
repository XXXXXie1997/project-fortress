extends SceneTree
func _initialize():call_deferred('run')
func run():
 root.size=Vector2i(1280,720)
 var a=load('res://scenes/maps/exploration.tscn').instantiate();root.add_child(a)
 for i in range(5):await physics_frame
 await a.depart('suburbs','south')
 a.hud.map_view.position=Vector2(240,70);a.hud.map_view.size=Vector2(800,560)
 for id in ['suburbs','armory','city']:
  a.exploration.unlock_map(a.state,id);a.exploration.ensure_map(a.state,id);a.state.expedition.map_id=id;a.state.expedition.point_id=a.catalog[id].initial_spawn
  await a.rebuild_map()
  for key in a.catalog[id].points:
   var p=a.catalog[id].points[key]
   if p.kind=='spawn':a.exploration.discover(a.state,key)
   if p.kind=='travel':a.state.world.exploration.travel[id+':'+key]=true
  for i in range(5):await process_frame
  await RenderingServer.frame_post_draw
  for rect in a.hud.map_view.label_rects:assert(Rect2(Vector2.ZERO,Vector2(800,560)).encloses(rect))
  root.get_texture().get_image().save_png('res://scenes/maps/labels-'+id+'.png')
 print('THREE MAP LABEL BOUNDS PASS');quit()
