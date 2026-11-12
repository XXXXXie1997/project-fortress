extends SceneTree
var failures=0
func _initialize():call_deferred('run')
func frames(n):
 for i in range(n):await physics_frame
func check(ok,label):
 print(('PASS ' if ok else 'FAIL ')+label)
 if not ok:failures+=1
func snap(name):
 for target in root.get_child(root.get_child_count()-1).targets:target.queue_redraw()
 await process_frame
 if DisplayServer.get_name()!='headless':
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png('res://docs/testing/DEV-202-'+name+'.png')
func run():
 root.size=Vector2i(1280,720)
 var a=load('res://scenes/enemies/enemy_arena.tscn').instantiate();root.add_child(a);await frames(5)
 a.player.set_physics_process(false)
 for e in a.targets:e.set_physics_process(false)
 var e=a.targets[0];e.position=Vector2(480,360);a.player.position=Vector2(320,360);a.player.camera.force_update_scroll();a.ambient_brightness=0.05;await frames(3)
 await snap('dark')
 var motion=InputEventMouseMotion.new();motion.position=e.get_global_transform_with_canvas()*Vector2.ZERO;motion.global_position=motion.position;Input.parse_input_event(motion);Input.warp_mouse(motion.position)
 a.player.tactical.toggle();await frames(5)
 e.position=a.player.position+a.player.position.direction_to(a.player.get_global_mouse_position())*160;await frames(2)
 check(e.visible_to_player(),'lamp cone reveals enemy')
 check(e.record().mode=='idle','lamp alone does not trigger investigation')
 await snap('lamp')
 a.player.tactical.toggle();await process_frame;await process_frame;await frames(3);check(not e.visible_to_player(),'lamp off hides enemy')
 var g=a.inventory.spawn(a.state,'nightvision','ground');a.state.items[g.id].energy=10;a.inventory.equip(a.state,g.id,'extra_1');await frames(3);await snap('nightvision')
 e.position=Vector2(900,400);await frames(3);await snap('wall')
 # Actual projectile traverses wall x650 region, cannot hit player behind it.
 var r=a.targets[3];r.position=Vector2(600,400);a.player.position=Vector2(750,400);a.state.player.vitals.hp=100;a.state.player.combat.hurt_iframe=0
 r.resolve_attack(a.player.position);await frames(60);check(a.state.player.vitals.hp==100,'hostile projectile blocked by wall')
 # Real AI windup then move player after aim capture.
 r.position=Vector2(450,360);a.player.position=Vector2(320,360);r.struck(a.player.position);r.set_physics_process(true);await frames(3)
 check(r.record().attack_left>0 and a.state.player.vitals.hp==100,'ranged windup before damage')
 a.player.position=Vector2(320,550);r.set_physics_process(false)
 # Keep windup processing with player outside range; aim remains historical.
 r.set_physics_process(true);await frames(50);r.set_physics_process(false);await frames(50)
 check(a.state.player.vitals.hp==100,'moving away evades aimed projectile')
 # Wall-hidden enemy hears explosion at empty point, not current player.
 e.position=Vector2(500,400);a.player.position=Vector2(900,400);a.player.tactical.explode(Vector2(500,650));e.set_physics_process(true);await frames(3)
 check(e.record().last_known==[500.0,650.0] and not e.record().alerted,'missed explosion investigates historical blast position')
 e.set_physics_process(false)
 # Real movement input + dodge event against stationary enemy.
 a.player.position=Vector2(320,360);e.position=Vector2(380,360);a.player.set_physics_process(true)
 Input.action_press('move_right');await frames(20);Input.action_release('move_right')
 check(a.player.position.x<360,'normal movement blocked by enemy')
 Input.action_press('move_right');var ev=InputEventAction.new();ev.action='dodge';ev.pressed=true;Input.parse_input_event(ev);await frames(13);Input.action_release('move_right')
 check(a.player.position.x>400,'dodge crosses enemy')
 print('FAILURES ',failures);quit(1 if failures else 0)



