extends SceneTree
func frames(n:=8):
 for i in range(n):await process_frame
func _initialize():call_deferred('run')
func run():
 root.size=Vector2i(1280,720)
 var a=load('res://scenes/maps/exploration.tscn').instantiate();root.add_child(a);await frames();await a.depart('suburbs','south');await frames()
 for id in ['suburbs','armory','city']:
  var old=a.geometry.ground_layer
  a.exploration.ensure_map(a.state,id);a.state.expedition.map_id=id;a.state.expedition.point_id=a.catalog[id].initial_spawn
  await a.rebuild_map();await frames();assert(not is_instance_valid(old))
  var ground=a.geometry.ground_layer;var count:int=ground.draw_count
  a.player.position=a.projection.logical_to_world(Vector2(1250,940));await frames(30)
  assert(ground.draw_count==count and count>0)
  assert(ground.z_index<0 and a.geometry.y_sort_enabled)
  if id=='suburbs':assert(a.geometry.roofs[2].node.modulate.a<.1)
  if DisplayServer.get_name()!='headless':
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png('res://scenes/maps/DEV511-'+id+'.png')
  print('PASS ',id,' retained draw count=',count,' previous layer freed')
 quit()
