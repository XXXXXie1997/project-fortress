extends SceneTree
func press(action:String):
 var e:=InputEventAction.new();e.action=action;e.pressed=true;Input.parse_input_event(e)
 await process_frame
 e=InputEventAction.new();e.action=action;e.pressed=false;Input.parse_input_event(e)
 await process_frame
func _initialize():
 var a=load('res://scenes/maps/exploration.tscn').instantiate();root.add_child(a)
 for i in 10:await physics_frame
 await press('quests');assert(not a.player.progression_panel.visible and a.hud.menu.visible)
 await a.depart('suburbs','south')
 for i in 10:await physics_frame
 await press('quests');assert(a.player.progression_panel.visible and not a.hud.panel.visible)
 await press('quests');assert(not a.player.progression_panel.visible)
 await press('talents');assert(a.player.progression_panel.visible and not paused)
 await press('cancel');assert(not a.player.progression_panel.visible and not paused)
 await press('map');assert(a.hud.full_map)
 await press('map');assert(not a.hud.full_map)
 print('DEV313 MAP HUD SINGLE INPUT DEPARTURE MODAL PASS')
 quit()
