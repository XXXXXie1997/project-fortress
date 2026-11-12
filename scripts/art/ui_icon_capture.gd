extends SceneTree
var arena
func _initialize():call_deferred('run')
func snap(name:String):
 for i in 10:await process_frame
 if DisplayServer.get_name()!='headless':
  await RenderingServer.frame_post_draw
  print(name,' ',root.get_texture().get_image().save_png('res://docs/art/integration/ART-103-ui-'+name+'.png'))
func run():
 root.size=Vector2i(1280,720)
 arena=load('res://scenes/ui/base/base_management_arena.tscn').instantiate();root.add_child(arena)
 while arena.management==null:await process_frame
 arena.management.root_panel.hide()
 arena.inventory.definitions.merge(preload('res://scripts/content/catalog.gd').items(),true)
 for id in ['medical_needle','muzzle_basic','capacitor_basic','nightvision']:
  arena.inventory.spawn(arena.state,id,'warehouse')
 var panel:InventoryPanel=arena.management.inventory_panel
 panel.open_panel();panel.refresh()
 await snap('inventory')
 for slot in panel.slot_buttons:
  var id:String=arena.state.player.equipment[slot]
  if not id.is_empty():assert(panel.slot_buttons[slot].icon!=null)
 panel.open_selector(func(_item):return true,func(_id):pass,true)
 panel.source='warehouse';panel.refresh()
 await snap('selector')
 panel.close_panel()
 arena.management.show_trade()
 arena.management.root_panel.show()
 await snap('trade')
 arena.queue_free()
 await process_frame
 arena=load('res://scenes/maps/exploration.tscn').instantiate();root.add_child(arena)
 for i in 6:await physics_frame
 await arena.depart('suburbs','south')
 await snap('hud')
 print('ART103 UI ICON CAPTURE PASS')
 quit()
