extends SceneTree
var fails=[]
func _initialize():call_deferred("run")
func ck(v,label):
 print(("PASS " if v else "FAIL ")+label)
 if not v:fails.append(label)
func key(code):
 var e=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=true;Input.parse_input_event(e)
 await process_frame
 e=e.duplicate();e.pressed=false;Input.parse_input_event(e)
 await process_frame
func mouseclick(pos):
 var e=InputEventMouseButton.new();e.position=pos;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=true;Input.parse_input_event(e)
 await process_frame
 e=e.duplicate();e.pressed=false;Input.parse_input_event(e)
 await process_frame
func run():
 var a=load("res://scenes/enemies/enemy_arena.tscn").instantiate();root.add_child(a)
 await physics_frame
 await physics_frame
 await key(KEY_TAB)
 var p=a.hud.inventory_panel
 ck(p!=null and p.visible and not paused,"Tab opens live inventory")
 var old_energy=a.player.item().energy
 await key(KEY_R)
 ck(not a.state.player.combat.charging and a.player.item().energy==old_energy,"R rotation does not start charge")
 var battery=a.inventory.items_in(a.state,"bag").filter(func(i):return i.get("is_battery",false))[0]
 a.player.item().energy=0
 await mouseclick(p.grid.global_position+p.item_rect(battery,"bag",false).position+Vector2(8,8))
 ck(p.selected==battery.id,"battery selection exact instance")
 for b in p.listing.get_children():
  if b is Button and b.text=="选择此电池供电":
   await mouseclick(b.global_position+b.size/2)
   break
 ck(p.battery_id==battery.id,"battery supply button selects instance")
 p.source="equipment";p.refresh()
 await process_frame
 var wid=a.player.item().id
 await mouseclick(p.grid.global_position+p.item_rect(a.state.items[wid],"equipment",false).position+Vector2(8,8))
 ck(p.selected==wid,"equipment grid exact weapon instance")
 for b in p.listing.get_children():
  if b is Button and b.text.ends_with("持续充电"):
   await mouseclick(b.global_position+b.size/2)
   break
 ck(a.player.item().energy<a.player.item().capacity,"charge request not instant")
 await create_timer(0.12).timeout
 ck(a.player.item().energy>0 and a.player.item().energy<a.player.item().capacity,"charge progresses physical frames")
 await key(KEY_ESCAPE)
 ck(not p.visible and not paused,"Esc closes inventory before pause")
 var bid=a.state.expedition.maps[a.state.expedition.map_id].containers.keys()[0]
 a.exploration.box(a.state,bid).search_seconds=0.5
 a.hud.open_inventory(bid)
 var initial_box=a.exploration.box(a.state,bid)
 var hidden_ids=a.inventory.items_in(a.state,initial_box.container_id).map(func(i):return i.id)
 for button in p.listing.get_children():
  if button is Button and button.text=="全部拾取已揭示":
   await mouseclick(button.get_global_rect().get_center())
   break
 ck(hidden_ids.all(func(id):return a.state.items[id].container_id==initial_box.container_id),"take all excludes unrevealed")
 ck(a.player.inventory_movement_locked and not paused,"loot locks movement world unpaused")
 var shot_before=a.player.item().energy
 var tactical_before=a.player.item().plugins.duplicate(true)
 await key(KEY_F)
 ck(a.player.item().plugins==tactical_before,"F does not mutate while inventory open")
 var fire=InputEventMouseButton.new();fire.position=Vector2(700,500);fire.button_index=MOUSE_BUTTON_LEFT;fire.pressed=true;Input.parse_input_event(fire)
 await create_timer(0.1).timeout
 fire=fire.duplicate();fire.pressed=false;Input.parse_input_event(fire)
 ck(a.player.item().energy>=shot_before,"mouse UI does not consume shot energy")
 var enemy=a.targets[0];var epos=enemy.position
 var record=a.state.expedition.maps[a.state.expedition.map_id].enemies[enemy.enemy_id].ai
 record.alerted=true;record.mode="search";record.search_left=10.0;record.call_left=0.0;record.called=true;record.last_known=[a.player.position.x,a.player.position.y]
 var pos=a.player.position
 Input.action_press("move_right")
 await create_timer(0.15).timeout
 Input.action_release("move_right")
 ck(enemy.position.distance_to(epos)>0.01,"enemy continues movement with loot open")
 ck(a.player.position.distance_to(pos)<0.01,"loot movement physically locked")
 a.player.receive_attack({"damage":2,"penetration":100})
 ck(p.visible,"damage does not close loot")
 p.close_panel()
 ck(a.state.expedition.search.is_empty() and not a.player.inventory_movement_locked,"close aborts unfinished search unlocks")
 a.state.player.quick[0]="medical_needle"
 a.inventory.spawn(a.state,"medical_needle","bag",5)
 await process_frame
 var full_color=a.hud.quick_slots[0].modulate
 for i in a.inventory.items_in(a.state,"bag"):
  if i.definition_id=="medical_needle":a.state.items.erase(i.id)
 await process_frame
 ck(a.hud.quick_slots[0].modulate!=full_color or "[color" in a.hud.quick.text,"HUD depleted quick slot gray")
 a.inventory.spawn(a.state,"medical_needle","bag",5)
 await process_frame
 ck(a.hud.quick_slots[0].modulate==full_color,"HUD refill restores slot color")
 a.hud.open_inventory(bid)
 ck(a.state.expedition.search.elapsed==0.0,"reopen resets incomplete search timer")
 await create_timer(0.55).timeout
 var revealed=a.exploration.box(a.state,bid).revealed.duplicate()
 ck(not revealed.is_empty(),"timed reveal while world runs")
 for button in p.listing.get_children():
  if button is Button and button.text=="全部拾取已揭示":
   await mouseclick(button.get_global_rect().get_center())
   break
 ck(revealed.all(func(id):return not a.state.items.has(id) or a.state.items[id].container_id=="bag"),"take all transfers revealed items")
 p.close_panel()
 print("QA_FAILURES "+str(fails));quit(1 if fails.size() else 0)






