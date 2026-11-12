extends SceneTree
var failures:=0
func check(ok:bool,label:String):
 print(('PASS ' if ok else 'FAIL ')+label)
 if not ok:failures+=1
func _initialize():call_deferred('run')
func frames(n:int):
 for i in range(n):await physics_frame
func run():
 root.size=Vector2i(1280,720)
 var scene=load('res://scenes/enemies/enemy_arena.tscn').instantiate();root.add_child(scene);await frames(5)
 scene.player.set_physics_process(false)
 for enemy in scene.targets:enemy.set_physics_process(false)
 check(scene.targets.size()==5,'four enemy types plus boss instantiated')
 var enemy=scene.targets[0];enemy.position=Vector2(480,360);scene.player.position=Vector2(320,360)
 var hp:float=scene.state.player.vitals.hp
 enemy._physics_process(0.05)
 check(enemy.record().meter>0 and not enemy.record().alerted and scene.state.player.vitals.hp==hp,'visual meter not immediate contact damage')
 scene.player.position=Vector2(900,400);enemy.position=Vector2(500,400)
 check(not enemy.see_player(),'real wall blocks visual detection')
 var source:=Vector2(540,650);enemy.hear(source);enemy._physics_process(0.1)
 check(enemy.record().last_known==[source.x,source.y] and not enemy.record().alerted,'sound only historical investigation')
 scene.hit(enemy,1.0,{'penetration':20.0,'source_position':[510.0,410.0]})
 check(enemy.record().alerted and enemy.record().last_known==[510.0,410.0],'damage immediately alerts at historical source')
 enemy.record().call_left=1.0;scene.hit(enemy,1.0,{'source_position':[510.0,410.0]})
 check(enemy.record().call_left==0 and not enemy.record().called,'hit interrupts pending call')
 enemy.record().call_retry=0;enemy.position=Vector2(480,360);scene.player.position=Vector2(320,360)
 for i in range(40):enemy._physics_process(0.1)
 check(enemy.record().called and scene.calls_completed==1,'successful call exactly once')
 var path:PackedVector2Array=scene.find_path(Vector2(600,400),Vector2(750,400))
 check(path.size()>3,'navigation routes around wall')
 var ranged=scene.targets[3];ranged.position=Vector2(420,360);scene.player.position=Vector2(320,360);scene.state.player.combat.hurt_iframe=0
 var before_hp:float=scene.state.player.vitals.hp
 ranged.resolve_attack(scene.player.position);await frames(40)
 check(scene.state.player.vitals.hp<before_hp,'ranged physical projectile reaches actual player')
 scene.state.player.combat.hurt_iframe=0;scene.state.player.vitals.hp=100;scene.player.position=Vector2(320,360)
 var old_hp:float=scene.state.player.vitals.hp
 enemy.position=Vector2(340,360);enemy.resolve_attack(scene.player.position)
 check(scene.state.player.vitals.hp<old_hp,'melee actual windup resolution damages in range')
 scene.state.player.combat.hurt_iframe=0;scene.state.player.vitals.hp=100
 enemy.resolve_attack(Vector2(500,360));scene.player.position=Vector2(100,360)
 enemy.resolve_attack(Vector2(320,360));check(scene.state.player.vitals.hp==100,'out of reach melee misses')
 var fast=scene.targets[1]
 scene.hit(fast,10000,{'penetration':10000.0});var map:Dictionary=scene.state.expedition.maps.suburbs
 check(map.enemies[fast.enemy_id].dead and map.containers.has('loot_'+fast.enemy_id),'kill persists and creates searchable exploration loot')
 var count:int=map.containers.size();scene.hit(fast,10000)
 check(scene.state.expedition.maps.suburbs.containers.size()==count,'death loot once')
 var boss=scene.targets[4];boss.record().vitals.hp=10;boss.record().alerted=true;scene.player.position=Vector2(100,100);boss._physics_process(0.1)
 check(boss.record().vitals.hp==boss.spec.hp and boss.position==boss.home,'boss withdrawal resets')
 enemy.position=Vector2(480,360);scene.player.position=Vector2(320,360);scene.player.camera.position=Vector2.ZERO;scene.player.camera.force_update_scroll();scene.ambient_brightness=0.05;await frames(2)
 check(not enemy.visible_to_player(),'dark enemy invisible')
 var motion:=InputEventMouseMotion.new();motion.position=enemy.get_global_transform_with_canvas()*Vector2.ZERO;motion.global_position=motion.position;Input.parse_input_event(motion)
 scene.player.tactical.toggle();await frames(3)
 check(enemy.visible_to_player(),'actual powered lamp reveals enemy inside cone')
 scene.player.tactical.toggle();await frames(2)
 var gear:Dictionary=scene.inventory.spawn(scene.state,'nightvision','ground');scene.state.items[gear.id].energy=10;scene.inventory.equip(scene.state,gear.id,'extra_1')
 check(enemy.visible_to_player(),'powered nightvision reveals unoccluded enemy')
 enemy.position=Vector2(900,400)
 check(not enemy.visible_to_player(),'nightvision does not reveal behind wall')
 enemy.position=Vector2(3000,200)
 check(not enemy.visible_to_player(),'outside screen enemy invisible')
 check(scene.exploration.exit_map(scene.state,'armory_road'),'map exit allowed')
 await frames(3)
 check(scene.targets.size()==1 and scene.targets[0].enemy_id=='guard_01','cross map clears old pursuers')
 check(scene.exploration.exit_map(scene.state,'road'),'return same expedition')
 await frames(3)
 var fast_present:=false
 for node in scene.targets:
  if node.enemy_id=='ai_1':fast_present=true
 check(not fast_present,'same expedition killed enemy remains absent')
 scene.exploration.finish(scene.state,false,[0,0],3,'escape');scene.state.day+=1
 check(scene.exploration.start(scene.state,'suburbs','south','day'),'next day expedition starts')
 await frames(3)
 check(scene.targets.size()==5,'new expedition respawns all four types and boss')
 print('FAILURES ',failures);quit(1 if failures else 0)




