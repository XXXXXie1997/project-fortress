extends SceneTree
func _initialize():call_deferred('run')
func capture(a,id,tag,roof):
 for i in 4:await process_frame
 print(id,' ',tag,' logical=',a.projection.world_to_logical(a.player.position),' alpha=',roof.node.modulate.a)
 if DisplayServer.get_name()!='headless':
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png('res://docs/art/integration/ART-104-door-'+id+'-'+tag+'.png')
func walk(a,target):
 for i in 180:
  var v=target-a.player.position
  if v.length()<5:break
  v=v.normalized()
  for pair in [['move_right',maxf(v.x,0)],['move_left',maxf(-v.x,0)],['move_down',maxf(v.y,0)],['move_up',maxf(-v.y,0)]]:Input.action_press(pair[0],pair[1])
  await physics_frame
 for key in ['move_right','move_left','move_down','move_up']:Input.action_release(key)
func run():
 root.size=Vector2i(1280,720)
 for id in ['suburbs','armory','city']:
  var a=load('res://scenes/maps/exploration.tscn').instantiate();root.add_child(a)
  while not a.ready_world:await process_frame
  a.exploration.unlock_map(a.state,id)
  for room in a.logical_catalog[id].rooms:a.state.world.exploration.doors[id+':'+room.id]=true
  assert(await a.depart(id,a.logical_catalog[id].initial_spawn))
  for enemy in a.targets:enemy.set_physics_process(false)
  var room=a.logical_catalog[id].rooms[0];var r=Rect2(room.rect[0],room.rect[1],room.rect[2],room.rect[3]);var d=Rect2(room.door[0],room.door[1],room.door[2],room.door[3]);var roof=a.geometry.roofs[0]
  var outside=Vector2(d.get_center().x,r.end.y+60);var inside=Vector2(outside.x,r.end.y-90)
  a.player.position=a.projection.logical_to_world(outside);a.player.velocity=Vector2.ZERO
  await capture(a,id,'before',roof);assert(roof.node.modulate.a>.9)
  await walk(a,a.projection.logical_to_world(inside));await capture(a,id,'inside',roof);assert(roof.node.modulate.a<.1)
  await walk(a,a.projection.logical_to_world(outside));await capture(a,id,'after',roof);assert(roof.node.modulate.a>.9)
  var p=Vector2(r.position.x+50,r.position.y-40);var q=p+Vector2(0,100)
  var ray=PhysicsRayQueryParameters2D.create(a.projection.logical_to_world(p),a.projection.logical_to_world(q),1)
  assert(not a.get_world_2d().direct_space_state.intersect_ray(ray).is_empty());print(id,' HIGH_WALL_RAY_BLOCK PASS')
  a.queue_free();await process_frame
 print('THREE_MAP_NATURAL_DOOR_PASS');quit()

