extends SceneTree
var failures:=0
func check(ok:bool,label:String):
 print(('PASS ' if ok else 'FAIL ')+label)
 if not ok:failures+=1
func _initialize():call_deferred('run')
func frames(count:int):
 for i in range(count):await physics_frame
func run():
 var scene=load('res://scenes/main.tscn').instantiate();root.add_child(scene);await frames(5)
 var actor=scene.player
 actor.set_physics_process(false);actor.tactical.set_process(false)
 scene.state.player.vitals.hp=50.0
 DamageRules.start_heal(actor.heals,{'cast_time':5.0,'instant':30.0,'interrupt_cast':true})
 actor.tactical.explode(actor.position)
 check(actor.heals.is_empty() and scene.state.player.vitals.hp<50,'self explosion interrupts configured cast')
 DamageRules.start_heal(actor.heals,{'cast_time':5.0,'instant':30.0,'interrupt_cast':true})
 actor.tactical.explode(actor.position)
 check(actor.heals.size()==1,'protected explosion does not interrupt cast')
 actor.heals.clear();scene.state.player.combat.hurt_iframe=0
 DamageRules.start_heal(actor.heals,{'cast_time':5.0,'instant':30.0,'interrupt_cast':false})
 actor.tactical.explode(actor.position)
 check(actor.heals.size()==1,'noninterruptible cast survives real self hit')
 actor.heals.clear()
 var plugin_id:String=actor.item().plugins.tactical
 var first_weapon:String=actor.item().id
 var new_id:String=scene.inventory.spawn(scene.state,'rifle_basic','ground').id
 scene.inventory.equip(scene.state,new_id,'weapon_3',true)
 actor.slot=3;actor.tactical.sync();actor.tactical.install_next_fixture()
 var owners:=0
 for item in scene.state.items.values():
  if plugin_id in item.plugins.values():owners+=1
 check(owners==1 and scene.state.items[first_weapon].plugins.tactical=='' and actor.item().plugins.tactical==plugin_id,'plugin transfer has exactly one parent')
 var snapshot:String=WorldState.encode(scene.state)
 check(not actor.tactical.install_fixture_plugin('missing') and snapshot==WorldState.encode(scene.state),'invalid plugin transaction unchanged')
 actor.slot=1;actor.position=Vector2(636,400);actor.item().energy=60.0;actor.cooldown=0;actor.camera.position=Vector2.ZERO;actor.camera.force_update_scroll();await frames(2)
 var screen:Vector2=scene.get_global_transform_with_canvas()*Vector2(930,400)
 var motion=InputEventMouseMotion.new();motion.position=screen;motion.global_position=screen;Input.parse_input_event(motion)
 Input.action_press('fire');actor.set_physics_process(true);await frames(45);Input.action_release('fire');actor.set_physics_process(false);await frames(30)
 check(actor.item().energy<60,'wall regression fires through actual actor input')
 check(scene.targets[1].get_meta('hp')==100.0,'wall stops close range actor shots before target')
 print('FAILURES ',failures);quit(1 if failures else 0)
