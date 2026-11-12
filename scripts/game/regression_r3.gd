extends SceneTree
var failures:=0
func check(ok:bool,label:String):
 print(('PASS ' if ok else 'FAIL ')+label)
 if not ok:failures+=1
func _initialize():call_deferred('run')
func settle():
 for i in range(4):await process_frame
func run():
 var scene=load('res://scenes/main.tscn').instantiate();root.add_child(scene);await settle()
 var actor=scene.player
 actor.set_physics_process(false)
 check(actor.visual.attachment_index==0 and actor.visual.attachment.visible,'actual light displayed')
 actor.tactical.install_next_fixture();await settle()
 check(actor.visual.attachment_index==1 and actor.visual.attachment.frame==9 and actor.visual.attachment.visible,'actual laser displayed')
 actor.tactical.install_next_fixture();await settle()
 check(actor.visual.attachment_index==2 and actor.visual.attachment.frame==10,'actual launcher displayed')
 actor.tactical.toggle();await settle()
 check(actor.visual.attachment.self_modulate==Color.WHITE,'active attachment feedback')
 actor.slot=2;await settle()
 check(not actor.visual.attachment.visible and actor.visual.weapon.visible,'melee hides attachment')
 actor.slot=3;await settle()
 check(not actor.visual.attachment.visible and not actor.visual.weapon.visible and not actor.visual.battery.visible,'empty slot hides held equipment')
 actor.slot=1;await settle()
 check(actor.visual.attachment_index==2 and actor.visual.attachment.visible,'return restores actual equipped launcher')
 var id:String=actor.item().plugins.tactical
 actor.item().plugins.tactical='';scene.state.items[id].container_id='ground';await settle()
 check(not actor.visual.attachment.visible,'ranged without plugin stays hidden after art frame')
 actor.tactical.install_fixture_plugin(id);await settle()
 check(actor.visual.attachment_index==2 and actor.visual.attachment.visible,'reinstall updates after transaction')
 print('FAILURES ',failures);quit(1 if failures else 0)
