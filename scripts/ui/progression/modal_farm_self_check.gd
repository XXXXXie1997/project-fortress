extends SceneTree
func key(action:String):
 var e:=InputEventAction.new();e.action=action;e.pressed=true;Input.parse_input_event(e)
 await process_frame
 e=InputEventAction.new();e.action=action;e.pressed=false;Input.parse_input_event(e)
 await process_frame
func _initialize():
 var a=load('res://scenes/ui/progression/demo.tscn').instantiate();root.add_child(a)
 for i in 10:await physics_frame
 var ui=a.player.progression_panel
 ui.close()
 await key('talents');assert(ui.visible and not paused)
 await key('talents');assert(not ui.visible and not paused)
 await key('quests');assert(ui.visible and ui.mode=='quests')
 await key('cancel');assert(not ui.visible and not paused)
 await key('cancel');assert(paused)
 await key('talents');assert(not ui.visible and paused)
 await key('cancel');assert(not paused)
 ui.open_view('talents')
 ui.reset_dialog=ConfirmationDialog.new();ui.add_child(ui.reset_dialog);ui.reset_dialog.popup_centered()
 await process_frame
 ui.handle_input(action_event('cancel'))
 assert(not ui.reset_dialog.visible and ui.visible and not paused)
 ui.close()
 var crops:Dictionary=JSON.parse_string(FileAccess.get_file_as_string('res://data/crops.json'))
 a.inventory.definitions.merge(crops.item_definitions)
 var b:=BuildingService.new(a.inventory,JSON.parse_string(FileAccess.get_file_as_string('res://data/buildings.json')))
 var farm_id:=b.build(a.state,'farm',[8,8],Rect2i(0,0,24,18));assert(farm_id!='')
 a.inventory.spawn(a.state,'seed_material','warehouse',1)
 var tech:=TechnologyService.new(a.inventory)
 assert(tech.unlock(a.state,'storage',true).ok);assert(tech.unlock(a.state,'agriculture',true).ok)
 crops.crops.material.seed_chance=0.0
 var farm:=FarmingService.new(b,crops.crops)
 assert(farm.plant(a.state,farm_id,'material'))
 farm.settle(a.state,'test:dusk',a.state.base.technology.has('agriculture'))
 farm.settle(a.state,'test:morning',a.state.base.technology.has('agriculture'))
 assert(a.inventory.count(a.state,'seed_material','warehouse')==1)
 print('DEV313 MODAL INPUT FARM GUARANTEED SEEDS PASS')
 quit()
func action_event(action:String)->InputEventAction:
 var event:=InputEventAction.new();event.action=action;event.pressed=true;return event
