extends SceneTree
var failures:=0
func _initialize():call_deferred('run')
func frames(n):
 for i in range(n):await physics_frame
func check(ok,label):
 print(('PASS ' if ok else 'FAIL ')+label)
 if not ok:failures+=1
func key(a):
 var e=InputEventAction.new();e.action=a;e.pressed=true;Input.parse_input_event(e);await frames(2)
 e=InputEventAction.new();e.action=a;e.pressed=false;Input.parse_input_event(e);await frames(2)
func run():
 var s=load('res://scenes/main.tscn').instantiate();root.add_child(s);await frames(5)
 var p=s.player;p.set_physics_process(false);p.tactical.set_process(false)
 for interrupt in [true,false]:
  p.heals.clear();s.state.player.combat.hurt_iframe=0;s.state.player.vitals.hp=60
  DamageRules.start_heal(p.heals,{'cast_time':4,'interrupt_cast':interrupt})
  p.tactical.explode(p.position)
  check(p.heals.is_empty()==interrupt,'self damage obey cast '+str(interrupt))
 p.heals.clear();DamageRules.start_heal(p.heals,{'cast_time':4,'interrupt_cast':true})
 var hp=s.state.player.vitals.hp;p.tactical.explode(p.position)
 check(p.heals.size()==1 and hp==s.state.player.vitals.hp,'iframe blocks damage and interruption')
 var id=p.item().plugins.tactical
 var new_id=s.inventory.spawn(s.state,'rifle_basic','ground').id;s.inventory.equip(s.state,new_id,'weapon_3',true)
 for slot in [3,1,3,1]:
  p.slot=slot;p.tactical.sync();p.tactical.install_fixture_plugin(id)
  var owners=0
  for item in s.state.items.values():
   if id in item.plugins.values():owners+=1
  check(owners==1 and p.item().plugins.tactical==id,'one parent transfer '+str(slot))
 p.position=Vector2(600,400);await frames(2)
 check(p.tactical.clamp_landing(Vector2(800,400)).x<650,'high wall stops trajectory')
 p.position=Vector2(920,550);await frames(2)
 check(p.tactical.clamp_landing(Vector2(920,690)).y==690,'low wall permits trajectory')
 s.targets[0].position=Vector2(920,640);s.targets[1].position=Vector2(920,530);await frames(2)
 p.tactical.explode(Vector2(920,580))
 check(s.targets[0].get_meta('hp')==100 and s.targets[1].get_meta('hp')<100,'actual explosion low wall blocks only hidden target')
 p.position=Vector2(320,360);p.set_physics_process(true);p.tactical.set_process(true)
 var start=p.position;Input.action_press('move_right');await frames(10);Input.action_release('move_right')
 check(p.position.x>start.x,'actual movement')
 await key('charge');await frames(10);check(p.item().energy>0,'charge real instance')
 await key('weapon_next');check(not s.state.player.combat.charging,'switch stops charging')
 await key('inventory');var old=p.slot;await key('weapon_next');check(p.slot==old and not paused,'UI consumes switch without pause');await key('cancel')
 await key('cancel');var stamina=s.state.player.combat.stamina;await frames(10);check(paused and stamina==s.state.player.combat.stamina,'pause freeze');await key('cancel')
 print('FAILURES ',failures);quit(failures)
