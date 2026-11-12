extends SceneTree
var failures=0
func _initialize():call_deferred('run')
func settle():
 for i in range(6):await process_frame
func check(v,t):
 print(('PASS ' if v else 'FAIL ')+t)
 if not v:failures+=1
func capture(name):
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png('res://docs/testing/DEV102-r3-'+name+'.png')
func run():
 var s=load('res://scenes/main.tscn').instantiate();root.add_child(s);await settle()
 var p=s.player
 for mode in range(3):
  check(p.visual.attachment.visible and p.visual.attachment.frame==8+mode,'real plugin frame '+str(mode))
  p.tactical.toggle();await settle();check(p.visual.attachment.self_modulate==Color.WHITE,'enabled state '+str(mode))
  await capture(str(mode))
  p.tactical.toggle();await settle();check(p.visual.attachment.self_modulate!=Color.WHITE,'disabled state '+str(mode))
  if mode<2:p.tactical.install_next_fixture();await settle()
 p.slot=2;await settle();check(not p.visual.attachment.visible and p.visual.weapon.visible,'melee equipment')
 p.slot=3;await settle();check(not p.visual.weapon.visible and not p.visual.battery.visible and not p.visual.attachment.visible,'empty equipment')
 p.slot=1;await settle();check(p.visual.attachment.frame==10 and p.visual.attachment.visible,'return launcher')
 var plugin=p.item().plugins.tactical;p.item().plugins.tactical='';s.state.items[plugin].container_id='ground';await settle()
 check(not p.visual.attachment.visible,'removed plugin hidden')
 p.tactical.install_fixture_plugin(plugin);await settle();check(p.visual.attachment.visible and p.visual.attachment.frame==10,'transaction reinstall')
 print('FAILURES ',failures);quit(failures)
