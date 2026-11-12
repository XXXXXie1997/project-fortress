extends SceneTree
var a
var failures:=0
func _initialize():call_deferred('run')
func frames(n:=8):
 for i in range(n):await physics_frame
func check(ok:bool,s:String):
 print(('PASS ' if ok else 'FAIL ')+s)
 if not ok:failures+=1
func action(name:String,pressed:bool):
 var e:=InputEventAction.new();e.action=name;e.pressed=pressed;Input.parse_input_event(e)
func snap(name:String):
 for i in range(8):await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png('res://docs/testing/DEV-203-r2-'+name+'.png')
func run():
 root.size=Vector2i(1280,720)
 for map_id in ['suburbs','armory','city']:
  a=load('res://scenes/maps/exploration.tscn').instantiate();root.add_child(a);await frames()
  a.exploration.unlock_map(a.state,map_id);await a.depart(map_id,a.catalog[map_id].initial_spawn);await frames()
  var points_before=a.catalog[map_id].points.duplicate(true)
  for key in a.catalog[map_id].points:
   var p=a.catalog[map_id].points[key]
   if p.kind=='spawn':a.state.world.exploration.spawns[map_id].append(key)
   if p.kind=='travel':a.state.world.exploration.travel[map_id+':'+key]=true
  action('map',true);await frames(1);action('map',false);await snap(map_id)
  var view=a.hud.map_view
  check(a.hud.full_map,'M opens map '+map_id)
  for i in range(view.label_rects.size()):
   check(Rect2(Vector2.ZERO,view.size).encloses(view.label_rects[i]),'label contained '+map_id+str(i))
   for j in range(i):check(not view.label_rects[i].intersects(view.label_rects[j]),'no label overlap')
  check(points_before==a.catalog[map_id].points,'world points unchanged '+map_id)
  action('map',true);await frames(1);action('map',false);await frames()
  if map_id=='suburbs':
   var target=a.targets.filter(func(t):return t.kind=='basic')[0]
   a.player.position=target.position+Vector2(-110,0)
   var initial=float(target.get_meta('hp'))
   a.state.items[a.state.player.equipment.weapon_1].energy=100
   var b:=InputEventMouseButton.new();b.button_index=MOUSE_BUTTON_LEFT;b.pressed=true;Input.parse_input_event(b)
   for i in range(140):
    if not is_instance_valid(target) or target.get_meta('hp')<=0:break
    var m:=InputEventMouseMotion.new();m.position=a.get_viewport().get_canvas_transform()*target.global_position;Input.warp_mouse(m.position);Input.parse_input_event(m)
    a.state.player.vitals.hp=100
    await physics_frame
   b=InputEventMouseButton.new();b.button_index=MOUSE_BUTTON_LEFT;b.pressed=false;Input.parse_input_event(b)
   await frames()
   check(float(target.get_meta('hp'))<initial,'actual mouse button and aim projectile damages enemy')
   print('TARGET HP ',initial,' -> ',target.get_meta('hp'))
   await snap('battle')
  a.queue_free();await frames()
 print('R2 FAILURES ',failures);quit(1 if failures else 0)

