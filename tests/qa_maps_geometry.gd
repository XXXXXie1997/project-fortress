extends SceneTree
var arena
var failures:=0
func _initialize():call_deferred('run')
func frames(n:=3):
 for i in range(n):await physics_frame
func check(ok:bool,label:String):
 print(('PASS ' if ok else 'FAIL ')+label)
 if not ok:failures+=1
func walk(goal:Vector2)->bool:
 var path=arena.find_path(arena.player.position,goal)
 if path.is_empty():return false
 for p in path:
  for frame in range(180):
   var delta:Vector2=p-arena.player.position
   if delta.length()<6:break
   var dir:=delta.normalized()
   for a in ['move_left','move_right','move_up','move_down']:Input.action_release(a)
   if absf(dir.x)>.25:Input.action_press('move_right' if dir.x>0 else 'move_left',absf(dir.x))
   if absf(dir.y)>.25:Input.action_press('move_down' if dir.y>0 else 'move_up',absf(dir.y))
   arena.state.player.vitals.hp=100
   await physics_frame
  if arena.player.position.distance_to(p)>30:
   print('STUCK ',arena.player.position,' target ',p)
   for a in ['move_left','move_right','move_up','move_down']:Input.action_release(a)
   return false
 for a in ['move_left','move_right','move_up','move_down']:Input.action_release(a)
 return arena.player.position.distance_to(goal)<70
func run():
 root.size=Vector2i(1280,720)
 arena=load('res://scenes/maps/exploration.tscn').instantiate();root.add_child(arena);await frames(6)
 await arena.depart('suburbs','south');await frames(5)
 var initial:Vector2=arena.player.position
 Input.action_press('move_right');await frames(12);Input.action_release('move_right')
 check(arena.player.position.x>initial.x+10 and absf(arena.player.position.y-initial.y)<2,'screen right input')
 for map_id in ['suburbs','armory','city']:
  if map_id!='suburbs':
   arena.queue_free();await frames(3)
   arena=load('res://scenes/maps/exploration.tscn').instantiate();root.add_child(arena);await frames(6)
   arena.exploration.unlock_map(arena.state,map_id)
   await arena.depart(map_id,arena.catalog[map_id].initial_spawn);await frames(5)
  for t in arena.targets: t.collision_layer=0;t.set_physics_process(false)
  var data:Dictionary=arena.catalog[map_id]
  for id in data.points:
   var p:Vector2=Vector2(data.points[id].position[0],data.points[id].position[1])
   check(await walk(p),map_id+' physical walk to '+id)
  for box in data.containers:
   var p:=Vector2(box.position[0],box.position[1])
   var path=arena.find_path(arena.player.position,p)
   print('PATH ',map_id,' ',box.id,' ',path.size())
 print('QA MAP ROUTE failures=',failures)
 quit(1 if failures else 0)


