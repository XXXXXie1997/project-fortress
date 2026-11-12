extends 'res://scripts/ui/progression/ui_self_check.gd'
func key(code):
 var e:=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=true;Input.parse_input_event(e)
 await process_frame
 e=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=false;Input.parse_input_event(e)
 await process_frame
func _initialize():
 root.size=Vector2i(1280,720)
 var a=load('res://scenes/ui/progression/demo.tscn').instantiate();root.add_child(a)
 for i in 10:await physics_frame
 a.player.set_physics_process(false)
 var s:Dictionary=a.state
 var ui=a.player.progression_panel
 s.player.vitals.hp=23.0;s.player.combat.stamina=17.0
 for i in 3:
  await click_button(ui,'体魄')
  await click_button(ui,'耐力')
  a.player.effective_config()
  assert(s.player.vitals.hp==23.0 and s.player.combat.stamina==17.0)
 assert(s.player.vitals.max_hp==130.0)
 var before:=JSON.stringify(s)
 await click_button(ui,'体魄')
 assert(JSON.stringify(s)==before)
 await click_button(ui,'基地洗点')
 assert(ui.reset_dialog.visible)
 await key(KEY_J)
 assert(ui.mode=='talents' and ui.reset_dialog.visible)
 await key(KEY_ESCAPE)
 assert(ui.visible and not paused and JSON.stringify(s)==before)
 await click_button(ui,'基地洗点')
 await key(KEY_ENTER)
 for i in 3:await process_frame
 a.player.effective_config()
 assert(s.player.growth.ranks.is_empty())
 assert(s.player.vitals.hp==23.0 and s.player.combat.stamina==17.0 and s.player.vitals.max_hp==100.0)
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png('res://docs/testing/DEV-313-QA.png')
 print('QA313 INDEPENDENT GUI MULTIRANK CAP CANCEL RESET PASS')
 quit()



