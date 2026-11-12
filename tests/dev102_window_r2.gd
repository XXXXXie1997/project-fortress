extends SceneTree
var failures=0
func _initialize():call_deferred('run')
func frames(n):
 for i in range(n):await physics_frame
func check(v,t):
 print(('PASS ' if v else 'FAIL ')+t)
 if not v:failures+=1
func mouse(s,world):
 root.warp_mouse(s.get_global_transform_with_canvas()*world)
func capture(name):
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png('res://docs/testing/'+name+'.png')
func run():
 var s=load('res://scenes/main.tscn').instantiate();root.add_child(s);await frames(8)
 var p=s.player
 p.slot=2;p.position=Vector2(610,400);p.camera.force_update_scroll()
 s.targets[0].position=Vector2(635,375);s.targets[1].position=Vector2(635,425);s.targets[2].position=Vector2(710,400)
 await frames(3);mouse(s,Vector2(800,400));await frames(3);var aim=(p.get_global_mouse_position()-p.position).normalized();s.targets[0].position=p.position+aim.rotated(-0.15)*25;s.targets[1].position=p.position+aim.rotated(0.15)*25;await frames(2);Input.action_press('fire');await frames(2);Input.action_release('fire')
 print('MELEE ',p.position,' mouse ',p.get_global_mouse_position(),' HP ',s.targets[0].get_meta('hp'),' ',s.targets[1].get_meta('hp'));check(s.targets[0].get_meta('hp')<100 and s.targets[1].get_meta('hp')<100,'melee hits both unobstructed targets')
 check(s.targets[2].get_meta('hp')==100,'melee does not hit wall target')
 await capture('DEV102-r2-melee')
 p.position=Vector2(400,700);s.targets[0].position=Vector2(450,700);await frames(3)
 Input.action_press('move_right');var e=InputEventAction.new();e.action='dodge';e.pressed=true;Input.parse_input_event(e);await frames(17);Input.action_release('move_right')
 check(p.position.x>480,'dodge crosses enemy')
 await frames(65);p.position=Vector2(610,400);Input.action_press('move_right');Input.parse_input_event(e);await frames(25);Input.action_release('move_right')
 check(p.position.x<639,'dodge stops at high wall')
 p.slot=1;p.position=Vector2(320,360);p.item().energy=50;p.tactical.toggle();await frames(4)
 check(p.tactical.light.enabled,'real light enabled')
 await capture('DEV102-r2-light')
 p.tactical.install_next_fixture();await frames(3)
 var power=p.tactical.battery().energy;var capacitor=p.item().energy;await frames(12)
 check(p.tactical.battery().energy<power and p.item().energy==capacitor,'laser uses independent power')
 p.tactical.install_next_fixture();await frames(3);mouse(s,Vector2(530,360));await frames(3)
 await capture('DEV102-r2-launcher')
 print('FAILURES ',failures);quit(failures)



