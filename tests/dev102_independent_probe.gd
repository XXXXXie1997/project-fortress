extends SceneTree
func _initialize():call_deferred('run')
func run():
 var scene=load('res://scenes/main.tscn').instantiate();root.add_child(scene)
 for i in range(5):await physics_frame
 var actor=scene.player
 actor.set_physics_process(false)
 actor.tactical.set_process(false)
 actor.position=Vector2(320,360)
 scene.state.player.vitals.hp=50.0
 DamageRules.start_heal(actor.heals,{'cast_time':5.0,'instant':30.0,'interrupt_cast':true})
 actor.tactical.explode(actor.position)
 print('SELF_HIT hp=',scene.state.player.vitals.hp,' pending_heals=',actor.heals.size(),' EXPECT pending_heals=0')
 var old_id:String=actor.item().plugins.tactical
 var new_id:String=scene.inventory.spawn(scene.state,'rifle_basic','ground').id
 scene.inventory.equip(scene.state,new_id,'weapon_3',true)
 actor.slot=3;actor.tactical.sync();actor.tactical.install_next_fixture()
 print('PLUGIN weapon1=',scene.state.items[scene.state.player.equipment.weapon_1].plugins.tactical,' weapon3=',actor.item().plugins.tactical,' same=',old_id==actor.item().plugins.tactical,' EXPECT distinct ownership')
 quit()
