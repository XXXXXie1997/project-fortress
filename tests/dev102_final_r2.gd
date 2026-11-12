extends SceneTree
var failures=0
func _initialize():call_deferred('run')
func frames(n):
 for i in range(n):await physics_frame
func check(v,t):
 print(('PASS ' if v else 'FAIL ')+t)
 if not v:failures+=1
func run():
 var s=load('res://scenes/main.tscn').instantiate();root.add_child(s);await frames(8)
 var p=s.player
 Input.action_press('aim');await frames(60)
 check(p.camera.position.distance_to((p.get_global_mouse_position()-p.global_position)*0.5)<1,'aim camera midpoint converges')
 Input.action_release('aim');await frames(3);check(p.camera.position==Vector2.ZERO and p.camera.zoom==Vector2.ONE,'release resets camera no zoom')
 p.set_physics_process(false)
 for low in [false,true]:
  p.position=Vector2(100,800);s.targets[0].position=Vector2(1200,800)
  var wallx=1100 if low else 1000;s.wall(Rect2(wallx,760,20,80),low);await frames(3)
  var bullet=load('res://scripts/game/projectile.gd').new();bullet.arena=s;bullet.position=Vector2(wallx-30,800);bullet.direction=Vector2.RIGHT;s.add_child(bullet);await frames(20)
  check(s.targets[0].get_meta('hp')==100 and not is_instance_valid(bullet),'projectile blocked wall low='+str(low))
 p.position=Vector2(320,360);p.slot=2;p.camera.force_update_scroll();await frames(3)
 var aim=(p.get_global_mouse_position()-p.position).normalized()
 s.targets[0].position=p.position+aim*70
 s.wall(Rect2(p.position+aim*40-Vector2(8,8),Vector2(16,16)));await frames(3)
 p.set_physics_process(true);Input.action_press('fire');await frames(2);Input.action_release('fire');p.set_physics_process(false)
 check(s.targets[0].get_meta('hp')==100,'melee in range actual wall occlusion')
 var spec=s.weapons.rifle_basic
 for aiming in [true,false]:
  check(WeaponRules.spread(spec,0.1,false,aiming,0.8)<WeaponRules.spread(spec,0.1,false,aiming,1.0),'laser precision improves aiming='+str(aiming))
 p.slot=1;p.tactical.sync();p.tactical.install_next_fixture();p.set_physics_process(true);await frames(3);check(p.tactical.mode==1 and p.visual.attachment_index==1,'installed laser visual matches actual plugin');print('FAILURES ',failures);quit(failures)

