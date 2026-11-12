extends SceneTree
var failures=[]
var chosen=[]
func _initialize():call_deferred("run")
func ck(v,l):
 print(("PASS " if v else "FAIL ")+l)
 if not v:failures.append(l)
func mouse(pos,down):
 var e=InputEventMouseButton.new();e.position=pos;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=down;Input.parse_input_event(e)
 await process_frame
func tap(pos):
 await mouse(pos,true)
 await mouse(pos,false)
func popup_click(dialog,button):
 await process_frame
 await process_frame
 for down in [true,false]:
  var e=InputEventMouseButton.new();e.position=button.get_global_rect().get_center();e.button_index=MOUSE_BUTTON_LEFT;e.pressed=down
  e.position+=Vector2(dialog.position)
  Input.parse_input_event(e)
  await process_frame
func run():
 root.gui_embed_subwindows=true
 var s=WorldState.fresh();var inv=InventoryService.new(JSON.parse_string(FileAccess.get_file_as_string("res://data/items.json")).items);inv.setup(s)
 var pack=inv.spawn(s,"backpack_small","warehouse");inv.equip(s,pack.id,"backpack")
 var ids=[]
 for loc in ["bag","bag","warehouse"]:ids.append(inv.spawn(s,"rifle_basic",loc).id)
 inv.equip(s,ids[0],"weapon_1")
 var p=InventoryPanel.new();p.bind_state(s,inv);root.add_child(p);p.open_panel()
 await process_frame
 await process_frame
 for n in range(3):
  p.open_selector(func(i):return i.definition_id=="rifle_basic",func(id):chosen.append(id),true)
  await process_frame
  await process_frame
  await tap(p.tabs_by_source[["equipment","bag","warehouse"][n]].get_global_rect().get_center())
  await tap(p.grid.global_position+p.item_rect(s.items[ids[n]],p.source,false).position+Vector2(8,8))
  print("SOURCE ",p.source," CELL ",s.items[ids[n]].cell," SELECTED ",p.selected," WANT ",ids[n])
  ck(p.selected==ids[n],"selector exact source instance "+str(n))
  p.confirm_selection()
  ck(chosen.back()==ids[n],"callback stable ID "+str(n))
 p.open_selector(func(i):return false,func(id):chosen.append(id),true)
 var count=chosen.size();p.selected=ids[1];p.confirm_selection();ck(chosen.size()==count,"filter blocks confirmation")
 p.close_panel();p.confirm_selection();ck(chosen.size()==count,"cancel clears callback")
 p.open_selector(func(i):return true,func(id):chosen.append(id),true)
 p.at_base=false;p.refresh();p.selected=ids[2];p.confirm_selection()
 ck(not p.tabs_by_source.warehouse.visible and chosen.size()==count,"field hides warehouse and rejects stale callback")
 p.close_panel();p.at_base=true;p.source="bag";p.open_panel()
 await process_frame
 await process_frame
 var g=ids[1]
 await mouse(p.grid.global_position+p.item_rect(s.items[g],"bag",false).position+Vector2(8,8),true)
 await mouse(p.slot_buttons.weapon_2.get_global_rect().get_center(),false)
 ck(s.player.equipment.weapon_2==g,"bag to equipment slot")
 await mouse(p.slot_buttons.weapon_2.get_global_rect().get_center(),true)
 await mouse(p.grid.global_position+Vector2(10,160),false)
 ck(s.items[g].container_id=="bag" and s.player.equipment.weapon_2=="","equipment slot to bag")
 p.close_panel();p.at_base=true
 p.bind_external_container("warehouse",func():return false)
 p.open_panel()
 var before=WorldState.encode(s)
 await process_frame
 await process_frame
 var from=p.grid.global_position+p.item_rect(s.items[ids[2]],"warehouse",true).position+Vector2(8,8)
 await mouse(from,true)
 await mouse(p.grid.global_position+Vector2(10,116),false)
 ck(WorldState.encode(s)==before,"revoked external permission denies GUI transfer")
 p.close_panel();p.open_panel()
 ck(p.transfer_item(ids[2],"bag"),"close external context restores legitimate transfer")
 inv.move(s,ids[2],"warehouse")
 p.bind_external_container("warehouse",func():return true,func(i):return i.definition_id=="medical_needle")
 before=WorldState.encode(s)
 ck(not p.transfer_item(ids[2],"bag") and WorldState.encode(s)==before,"external filter blocks stale item atomically")
 var product=inv.spawn(s,"medical_needle","warehouse",5)
 p.refresh()
 await process_frame
 var total=s.items.size()
 await mouse(p.grid.global_position+p.item_rect(s.items[product.id],"warehouse",true).position+Vector2(8,8),true)
 await mouse(p.grid.global_position+Vector2(230,160),false)
 ck(s.items[product.id].container_id=="bag" and s.items.size()==total,"production actual item drag no duplicate")
 p.close_panel();p.at_base=true;p.source="bag";p.open_panel()
 p.selected=""
 for n in range(5):inv.spawn(s,"rifle_basic","bag")
 p.refresh()
 await process_frame
 before=WorldState.encode(s)
 await mouse(p.slot_buttons.backpack.get_global_rect().get_center(),true)
 await mouse(p.grid.global_position+Vector2(400+230,28+230),false)
 ck(p.dialog.visible and WorldState.encode(s)==before,"overflow preview no mutation")
 await popup_click(p.dialog,p.dialog.get_cancel_button())
 ck(WorldState.encode(s)==before,"overflow cancel atomic")
 p.selected=""
 await mouse(p.slot_buttons.backpack.get_global_rect().get_center(),true)
 await mouse(p.grid.global_position+Vector2(400+230,28+230),false)
 if p.dialog.visible:await popup_click(p.dialog,p.dialog.get_ok_button())
 p.dialog.hide()
 ck(s.player.equipment.backpack=="","overflow confirm unequips")
 print("QA_FAILURES "+str(failures));quit(1 if failures.size() else 0)









