extends SceneTree
func action(name:String):
 var event:=InputEventAction.new();event.action=name;event.pressed=true;Input.parse_input_event(event)
 await process_frame
 event=InputEventAction.new();event.action=name;event.pressed=false;Input.parse_input_event(event)
 await process_frame
func _initialize():
 var a=load('res://scenes/base/base_defense.tscn').instantiate();root.add_child(a)
 for i in 20:await physics_frame
 for fixture in a.fixtures:
  if fixture.kind=='technology':a.player.position=fixture.position
 await action('interact')
 var panel=a.player.progression_panel
 assert(panel.visible and panel.terminal and panel.mode=='technology')
 panel.close()
 for fixture in a.fixtures:
  if fixture.kind=='quest':a.player.position=fixture.position
 await action('interact')
 assert(panel.visible and panel.terminal and panel.mode=='quests')
 a.state.expedition.active=true
 for i in 3:await process_frame
 assert(not panel.terminal)
 assert(not a.player.growth_bridge.reset(a.state,a.inventory,a.player.growth_bridge.growth.preview_reset(a.state,true),panel.at_base()))
 print('DEV313 ACTUAL BASE TERMINAL LOCATION GUARD PASS')
 quit()
