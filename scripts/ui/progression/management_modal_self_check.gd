extends SceneTree
func _initialize():
 var a=load('res://scenes/ui/base/base_management_arena.tscn').instantiate();root.add_child(a)
 for i in 15:await physics_frame
 var panel=a.player.progression_panel
 a.management.confirmation.popup_centered()
 for action in ['talents','quests']:
  var e:=InputEventAction.new();e.action=action;e.pressed=true;Input.parse_input_event(e)
  await process_frame
  assert(not panel.visible and not paused)
 a.management.confirmation.hide()
 print('DEV313 MANAGEMENT MODAL T J BLOCK PASS')
 quit()

