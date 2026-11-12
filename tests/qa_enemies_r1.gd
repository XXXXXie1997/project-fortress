extends SceneTree
var failures=0
func _initialize():call_deferred('run')
func frames(n):
 for i in range(n):await physics_frame
func check(ok,label):
 print(('PASS ' if ok else 'FAIL ')+label)
 if not ok:failures+=1
func run():
 var a=load('res://scenes/enemies/enemy_arena.tscn').instantiate();root.add_child(a);await frames(5)
 a.player.set_physics_process(false)
 for e in a.targets:e.set_physics_process(false)
 var e=a.targets[0];e.position=Vector2(480,360);a.player.position=Vector2(320,360);e.set_physics_process(true)
 await frames(20)
 check(e.record().meter>0 and not e.record().alerted,'actual frames accumulate initial alert')
 a.player.position=Vector2(900,400);e.position=Vector2(500,400)
 var historical=Vector2(540,650);e.hear(historical);await frames(10)
 check(e.record().last_known==[540.0,650.0] and not e.record().alerted,'occluded sound does not track')
 await frames(260)
 check(e.record().mode=='idle' and e.record().meter==0,'investigation expires in physics frames')
 e.position=Vector2(480,360);a.player.position=Vector2(320,360);e.struck(a.player.position);await frames(10)
 check(e.record().call_left>0,'call starts')
 a.hit(e,1,{'source_position':[320,360]});check(e.record().call_left==0,'hit interrupts call')
 await frames(250);check(a.calls_completed==1,'call succeeds once after retry')
 await frames(100);check(a.calls_completed==1,'no second call')
 e.set_physics_process(false)
 var boss=a.targets[4];a.player.position=boss.home+Vector2(-150,0);boss.set_physics_process(true)
 await frames(20);var meter=boss.record().meter
 check(meter>0 and not boss.record().alerted,'boss partial detection setup')
 a.player.position=Vector2(100,100);await frames(300)
 check(boss.record().meter==0,'boss withdrawal clears partial alert')
 boss.set_physics_process(false)
 var r=a.targets[3];r.position=Vector2(420,360);a.player.position=Vector2(320,360);a.state.player.vitals.hp=100;a.state.player.combat.hurt_iframe=0
 r.resolve_attack(a.player.position);await frames(1)
 var bullets=[]
 for c in a.get_children():
  if c.get_script()==load('res://scripts/game/projectile.gd'):bullets.append(c)
 check(bullets.size()>0,'real hostile projectile created')
 a.exploration.exit_map(a.state,'armory_road');await frames(3)
 var remaining=0
 for b in bullets:
  if is_instance_valid(b):remaining+=1
 check(remaining==0,'cross map removes old hostile projectiles')
 print('FAILURES ',failures);quit(1 if failures else 0)
