extends SceneTree
func _initialize():call_deferred('run')
func run():
 root.size=Vector2i(1280,720)
 for id in ['suburbs','armory','city']:
  var a=load('res://scenes/maps/exploration.tscn').instantiate();root.add_child(a)
  while not a.ready_world:await process_frame
  a.exploration.unlock_map(a.state,id)
  assert(await a.depart(id,a.logical_catalog[id].initial_spawn))
  for enemy in a.targets:enemy.set_physics_process(false)
  var trees:Array=a.logical_catalog[id].trees
  print(id,' existing trees ',trees.size())
  if not trees.is_empty():
   var p:Vector2=a.projection.logical_to_world(Vector2(trees[0][0],trees[0][1]))
   for side in [-1,1]:
    a.player.position=p+Vector2(0,side*26);a.player.velocity=Vector2.ZERO
    for i in 12:await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png('res://docs/art/integration/ART-104-tree-'+id+'-'+str(side)+'.png')
  a.queue_free();await process_frame
 quit()
