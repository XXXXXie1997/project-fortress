extends SceneTree
var failures=0
func _initialize():call_deferred('run')
func frames(n):
 for i in range(n):await physics_frame
func check(ok,label):
 print(('PASS ' if ok else 'FAIL ')+label)
 if not ok:failures+=1
func run():
 root.size=Vector2i(1280,720)
 var a=load('res://scenes/enemies/enemy_arena.tscn').instantiate();root.add_child(a);await frames(5)
 a.player.set_physics_process(false)
 for e in a.targets:e.set_physics_process(false)
 var boss=a.targets[4];a.hit(boss,99999,{'penetration':99999});boss.set_physics_process(true);a.player.position=Vector2(100,100);await frames(10)
 check(boss.record().vitals.hp<=0,'dead boss cannot reset')
 var e=a.targets[0];e.position=Vector2(480,360);a.player.position=Vector2(320,360);a.player.camera.force_update_scroll();a.ambient_brightness=0.05;await frames(3)
 check(not e.visible_to_player(),'dark enemy hidden')
 # Independent real-frame accumulation comparison before nightvision setup.
 var meters=[]
 for setting in [[160,1.0,1.0],[300,1.0,1.0],[160,0.2,1.0],[160,1.0,0.5]]:
  e.position=Vector2(320+setting[0],360);e.record().meter=0;e.record().alerted=false;e.record().mode='idle';a.ambient_brightness=setting[1];a.state.player.vitals.visual_accumulation_factor=setting[2];e.set_physics_process(true);await frames(10);e.set_physics_process(false);meters.append(e.record().meter)
 check(meters[0]>meters[1] and meters[0]>meters[2] and meters[0]>meters[3],'distance darkness and stealth slow actual accumulation')
 a.ambient_brightness=0.05;e.position=Vector2(480,360);a.state.player.vitals.visual_accumulation_factor=1.0
 var g=a.inventory.spawn(a.state,'nightvision','ground');a.state.items[g.id].energy=10;a.inventory.equip(a.state,g.id,'extra_1');await frames(3)
 check(e.visible_to_player(),'nightvision visible')
 check(a.illumination_at(e.position)==0.05,'nightvision does not emit actual light')
 e.position=Vector2(900,400);await frames(3);check(not e.visible_to_player(),'nightvision wall blocked')
 e.position=Vector2(3000,200);await frames(3);check(not e.visible_to_player(),'offscreen hidden')
 var p=load('res://scripts/game/projectile.gd').new();p.arena=a;p.position=Vector2(100,800);p.direction=Vector2.RIGHT;a.add_child(p)
 a.exploration.exit_map(a.state,'armory_road');await frames(4);check(not is_instance_valid(p),'player projectile cleared')
 a.exploration.exit_map(a.state,'road');await frames(4)
 var alive_boss=false
 for target in a.targets:
  if target.kind=='boss':alive_boss=true
 check(not alive_boss,'dead boss remains absent on return')
 print('FAILURES ',failures);quit(1 if failures else 0)

