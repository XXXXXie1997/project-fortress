extends SceneTree
var failures:=0
func check(ok:bool,label:String):
 print(('PASS ' if ok else 'FAIL ')+label)
 if not ok:failures+=1
func _initialize():call_deferred('run')
func frames(n:int):
 for i in range(n):await physics_frame
func run():
 var arena=load('res://scenes/enemies/enemy_arena.tscn').instantiate();root.add_child(arena);await frames(5)
 arena.player.set_physics_process(false)
 for enemy in arena.targets:enemy.set_physics_process(false)
 var boss=arena.targets[4]
 var r:Dictionary=boss.record()
 r.meter=0.4;r.vitals.hp=30;r.alerted=false;r.attack_left=0.7;r.call_left=0.8;r.search_left=4;r.position=[1100,700]
 boss.position=Vector2(1100,700);boss.velocity=Vector2(20,30);boss.push=Vector2(50,60)
 var wounded=arena.targets[0];wounded.record().vitals.hp=25
 var dead=arena.targets[1];arena.hit(dead,10000,{'penetration':10000})
 var bullets:Array=[]
 for hostile in [true,false]:
  var bullet=load('res://scripts/game/projectile.gd').new();bullet.arena=arena;bullet.hostile=hostile;bullet.position=Vector2(1200,200);bullet.direction=Vector2.DOWN;bullet.speed=5;arena.add_child(bullet);bullets.append(bullet)
 var t=arena.player.tactical;t.sync();t.install_next_fixture();t.install_next_fixture();t.toggle();arena.player.item().energy=60;t.landing=Vector2(300,300)
 check(t.fire(),'actual grenade flight starts')
 t.pulse=0.15
 check(arena.exploration.exit_map(arena.state,'armory_road'),'switch map with combat effects in flight')
 await frames(4)
 check(not is_instance_valid(bullets[0]) and not is_instance_valid(bullets[1]),'both hostile and player bullets removed')
 check(t.flight==0 and t.pulse==0,'old grenade and explosion pulse cleared')
 var old:Dictionary=arena.state.expedition.maps.suburbs.enemies
 var reset:Dictionary=old.ai_4.ai
 check(reset.meter==0 and reset.attack_left==0 and reset.call_left==0 and reset.search_left==0 and reset.vitals.hp==arena.ai_config.types.boss.hp,'map departure resets partial boss fight')
 check(old.ai_0.ai.vitals.hp==25 and old.ai_1.dead and arena.state.expedition.maps.suburbs.containers.has('loot_ai_1'),'ordinary wounds deaths and loot remain persistent')
 for enemy in arena.targets:enemy.set_physics_process(false)
 var hp:float=arena.state.player.vitals.hp
 await frames(40)
 check(t.flight==0 and arena.state.player.vitals.hp==hp,'cancelled grenade does not resolve later')
 print('FAILURES ',failures);quit(1 if failures else 0)

