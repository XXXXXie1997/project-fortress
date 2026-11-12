extends SceneTree
func _initialize():call_deferred("run")
func run():
 var arena=load("res://scenes/enemies/enemy_arena.tscn").instantiate()
 root.add_child(arena)
 await physics_frame
 await physics_frame
 arena.hud.open_inventory()
 assert(arena.hud.inventory_panel.visible and not paused)
 var panel:InventoryPanel=arena.hud.inventory_panel
 var weapon:Dictionary=arena.player.item()
 weapon.energy=0
 var battery:String=arena.inventory.items_in(arena.state,"bag").filter(func(i):return i.get("is_battery",false))[0].id
 arena.player.request_inventory_charge(weapon.id,battery)
 var initial:float=weapon.energy
 await physics_frame
 await physics_frame
 assert(arena.player.item().energy>initial and arena.player.item().energy<arena.player.item().capacity)
 var box_id:String=arena.state.expedition.maps[arena.state.expedition.map_id].containers.keys()[0]
 panel.close_panel()
 arena.hud.open_inventory(box_id)
 assert(arena.player.inventory_movement_locked)
 arena.player.receive_attack({"damage":2,"penetration":100})
 assert(panel.visible and not paused)
 await create_timer(1.0).timeout
 assert(not arena.exploration.box(arena.state,box_id).revealed.is_empty())
 var candidates:Array=panel.visible_items(panel.remote_location())
 var loot_id:String=candidates[0].id
 var event:=InputEventMouseButton.new()
 event.button_index=MOUSE_BUTTON_LEFT;event.pressed=true;event.double_click=true
 event.position=panel.grid.global_position+panel.item_rect(candidates[0],panel.remote_location(),true).position+Vector2(10,10)
 Input.parse_input_event(event)
 await process_frame
 event=event.duplicate();event.pressed=false
 Input.parse_input_event(event)
 await process_frame
 assert(arena.state.items[loot_id].container_id=="bag")
 event=event.duplicate();event.pressed=true
 event.position=panel.grid.global_position+panel.item_rect(arena.state.items[loot_id],"bag",false).position+Vector2(10,10)
 Input.parse_input_event(event)
 await process_frame
 event=event.duplicate();event.pressed=false
 Input.parse_input_event(event)
 await process_frame
 assert(arena.state.items[loot_id].container_id==panel.remote_location())
 event=event.duplicate();event.double_click=false;event.pressed=true
 event.position=panel.grid.global_position+panel.item_rect(arena.state.items[loot_id],panel.remote_location(),true).position+Vector2(10,10)
 Input.parse_input_event(event)
 await process_frame
 event=event.duplicate();event.pressed=false
 event.position=panel.grid.global_position+Vector2(200,180)
 Input.parse_input_event(event)
 await process_frame
 event=event.duplicate();event.pressed=false
 Input.parse_input_event(event)
 await process_frame
 assert(arena.state.items[loot_id].container_id=="bag")
 if "--capture-ui" in OS.get_cmdline_user_args():
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://scenes/ui/inventory/integration.png")
 panel.close_panel()
 assert(not arena.player.inventory_movement_locked and arena.state.expedition.search.is_empty())
 print("INVENTORY_INTEGRATION_PASS")
 arena.queue_free()
 await process_frame
 quit()




