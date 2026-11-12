extends SceneTree
func click_button(ui:Node,text:String):
 var target:Button
 for child in ui.find_children('*','Button',true,false):
  if child.text.contains(text):target=child;break
 assert(target!=null)
 var point:=target.get_global_rect().get_center()
 var motion:=InputEventMouseMotion.new();motion.position=point;Input.parse_input_event(motion)
 await process_frame
 var press:=InputEventMouseButton.new();press.position=point;press.button_index=MOUSE_BUTTON_LEFT;press.pressed=true;press.button_mask=MOUSE_BUTTON_MASK_LEFT;Input.parse_input_event(press)
 await process_frame
 var release:=InputEventMouseButton.new();release.position=point;release.button_index=MOUSE_BUTTON_LEFT;release.pressed=false;Input.parse_input_event(release)
 await process_frame
func _initialize():
 root.size=Vector2i(1280,720)
 var a=load('res://scenes/ui/progression/demo.tscn').instantiate();root.add_child(a)
 for i in 10:await physics_frame
 var ui=a.player.progression_panel
 var hp:float=a.state.player.vitals.hp
 a.state.items[a.state.player.equipment.weapon_1].energy=60
 var energy:float=a.state.items[a.state.player.equipment.weapon_1].energy
 await click_button(ui,'体魄')
 assert(a.state.player.growth.ranks.vitality==1)
 for i in 2:await physics_frame
 assert(a.state.player.vitals.max_hp==hp+10 and a.state.player.vitals.hp==hp)
 assert(a.state.items[a.state.player.equipment.weapon_1].energy==energy)
 ui.open_view('technology',true)
 for i in 2:await process_frame
 await click_button(ui,'仓储技术')
 assert(a.state.base.technology.storage)
 var width:int=a.state.containers.warehouse.width
 await click_button(ui,'升级仓库')
 assert(a.state.containers.warehouse.width==width+2)
 var before:=JSON.stringify(a.state)
 await click_button(ui,'升级仓库')
 assert(JSON.stringify(a.state)==before)
 await click_button(ui,'稳定返种')
 assert(a.state.base.technology.agriculture)
 ui.open_view('quests',true)
 for i in 2:await process_frame
 await click_button(ui,'主线 · 调查郊区中继记录')
 assert(a.state.quests.active.has('main_1'))
 ui.open_view('quests',false)
 for child in ui.find_children('*','Button',true,false):assert(not child.text.begins_with('交付'))
 ui.open_view('talents')
 for i in 3:await process_frame
 var close_button:Button
 for child in ui.find_children('*','Button',true,false):
  if child.text.begins_with('关闭'):close_button=child;break
 var point:=close_button.get_global_rect().get_center()
 var before_close:float=a.state.items[a.state.player.equipment.weapon_1].energy
 var press:=InputEventMouseButton.new();press.position=point;press.button_index=MOUSE_BUTTON_LEFT;press.button_mask=MOUSE_BUTTON_MASK_LEFT;press.pressed=true;Input.parse_input_event(press)
 for i in 3:await physics_frame
 assert(not ui.visible and a.state.items[a.state.player.equipment.weapon_1].energy==before_close)
 var release:=InputEventMouseButton.new();release.position=point;release.button_index=MOUSE_BUTTON_LEFT;release.pressed=false;Input.parse_input_event(release)
 ui.open_view('talents')
 if '--render' in OS.get_cmdline_user_args():
  for i in 3:await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png('res://scenes/ui/progression/preview.png')
 print('DEV313 REAL GUI ROUTE TECH CAPACITY QUEST PASS')
 quit()








