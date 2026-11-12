extends SceneTree
var failures=[]
func _initialize():call_deferred("run")
func ck(v,l):
 print(("PASS " if v else "FAIL ")+l)
 if not v:failures.append(l)
func event(pos,down):
 var e=InputEventMouseButton.new();e.position=pos;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=down;Input.parse_input_event(e)
 await process_frame
func popup(d,b):
 await process_frame
 await process_frame
 var pos=Vector2(d.position)+b.get_global_rect().get_center()
 await event(pos,true)
 await event(pos,false)
 await process_frame
 await process_frame
func drag(p,pos):
 await event(p.slot_buttons.backpack.get_global_rect().get_center(),true)
 await event(p.grid.global_position+pos,false)
func run():
 root.gui_embed_subwindows=true
 var s=WorldState.fresh();var inv=InventoryService.new(JSON.parse_string(FileAccess.get_file_as_string("res://data/items.json")).items);inv.setup(s)
 var pack=inv.spawn(s,"backpack_small","warehouse");inv.equip(s,pack.id,"backpack")
 var gun=inv.spawn(s,"rifle_basic","bag");inv.relocate(s,gun.id,Vector2i(3,2),false)
 var p=InventoryPanel.new();p.bind_state(s,inv);root.add_child(p);p.at_base=false;p.open_panel()
 await process_frame
 await process_frame
 var before=WorldState.encode(s)
 await drag(p,Vector2(10,38))
 ck(p.dialog.visible and WorldState.encode(s)==before,"legal field overflow previews atomically")
 await popup(p.dialog,p.dialog.get_cancel_button())
 ck(not p.dialog.visible and WorldState.encode(s)==before,"actual cancel unchanged")
 await drag(p,Vector2(10,38))
 # A new item at the previously legal target must be revalidated.
 var blocker=inv.spawn(s,"medical_needle","bag",1)
 before=WorldState.encode(s)
 await popup(p.dialog,p.dialog.get_ok_button())
 ck(WorldState.encode(s)==before and not p.last_feedback.is_empty(),"confirm drift visibly fails atomically")
 # Invalid target is rejected before consent.
 await drag(p,Vector2(10,38))
 ck(not p.dialog.visible and WorldState.encode(s)==before and p.feedback.visible and not p.feedback.text.is_empty(),"invalid target visibly refused before dialog")
 s.items.erase(blocker.id);p.refresh()
 before=WorldState.encode(s)
 await drag(p,Vector2(10,38))
 ck(p.dialog.visible,"legal retry offers confirmation")
 await popup(p.dialog,p.dialog.get_ok_button())
 ck(s.player.equipment.backpack=="" and s.items[pack.id].container_id=="bag","actual confirm unequips same pack ID")
 ck(s.items.has(gun.id) and s.items[gun.id].container_id=="ground" and s.items.size()==2,"overflow same item ID in actual ground container")
 if DisplayServer.get_name()!="headless":
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://docs/testing/DEV-204-R7.png")
 print("QA_FAILURES ",failures);quit(1 if failures.size() else 0)


