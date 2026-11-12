extends SceneTree
var failures:Array=[]
func _initialize(): call_deferred("run")
func check(value:bool,label:String):
 print(("PASS " if value else "FAIL ")+label)
 if not value: failures.append(label)
func click(point:Vector2,pressed:bool,double:bool=false):
 var e=InputEventMouseButton.new()
 e.button_index=MOUSE_BUTTON_LEFT;e.position=point;e.pressed=pressed;e.double_click=double
 Input.parse_input_event(e)
 await process_frame
func run():
 var s=WorldState.fresh()
 var inv=InventoryService.new(JSON.parse_string(FileAccess.get_file_as_string("res://data/items.json")).items)
 inv.setup(s)
 var pack=inv.spawn(s,"backpack_small","warehouse")
 inv.equip(s,pack.id,"backpack")
 var item=inv.spawn(s,"rifle_basic","warehouse")
 var p=InventoryPanel.new()
 p.bind_state(s,inv);root.add_child(p);p.open_panel()
 await process_frame
 await process_frame
 var start=p.grid.global_position+p.item_rect(s.items[item.id],"warehouse",true).position+Vector2(10,10)
 await click(start,true)
 await click(p.grid.global_position+Vector2(44*3+10,28+44*2+10),false)
 check(s.items[item.id].container_id=="bag","cross grid transfer")
 check(s.items[item.id].cell==[3,2],"cross grid respects drop cell (3,2) actual="+str(s.items[item.id].cell))
 # Leaving base with warehouse tab selected must not retain access.
 inv.spawn(s,"medical_needle","warehouse",5);p.source="warehouse";p.refresh();p.close_panel();p.at_base=false;p.open_panel()
 check(p.visible_items(p.source).is_empty() or p.source!="warehouse","field cannot expose persisted warehouse tab")
 p.at_base=true;p.source="bag";p.refresh()
 var needle=inv.items_in(s,"warehouse")[0]
 var np=p.grid.global_position+p.item_rect(needle,"warehouse",true).position+Vector2(10,10)
 await click(np,true,true)
 await click(np,false)
 check(s.items.has(needle.id) and s.items[needle.id].container_id=="bag","complete double click retains transfer")
 np=p.grid.global_position+p.item_rect(s.items[needle.id],"bag",false).position+Vector2(10,10)
 await click(np,true,true)
 await click(np,false)
 check(s.items[needle.id].container_id=="warehouse","complete reverse double click retains transfer")
 var snap=WorldState.encode(s)
 var gp=p.grid.global_position+p.item_rect(s.items[item.id],"bag",false).position+Vector2(50,10)
 await click(gp,true)
 await click(gp,false)
 check(WorldState.encode(s)==snap,"ordinary interior click does not relocate")
 var gun2=inv.spawn(s,"rifle_basic","warehouse")
 p.refresh()
 var before=WorldState.encode(s)
 await click(p.grid.global_position+p.item_rect(s.items[gun2.id],"warehouse",true).position+Vector2(10,10),true)
 await click(p.grid.global_position+Vector2(44*3+10,28+44*2+10),false)
 check(WorldState.encode(s)==before,"occupied drop preserves entire state")
 s.containers.bag.maximum_weight=3.0
 before=WorldState.encode(s)
 await click(p.grid.global_position+p.item_rect(s.items[gun2.id],"warehouse",true).position+Vector2(10,10),true)
 await click(p.grid.global_position+Vector2(10,38),false)
 check(WorldState.encode(s)==before,"overweight drop preserves entire state")
 p.at_base=false
 before=WorldState.encode(s)
 check(not p.transfer_item(gun2.id,"bag") and WorldState.encode(s)==before,"field warehouse transfer denied atomically")
 p.at_base=true;s.containers.bag.maximum_weight=30.0
 var rs=p.grid.global_position+p.item_rect(s.items[gun2.id],"warehouse",true).position+Vector2(10,10)
 await click(rs,true)
 var ke=InputEventKey.new();ke.keycode=KEY_R;ke.pressed=true;Input.parse_input_event(ke)
 var motion=InputEventMouseMotion.new();motion.position=p.grid.global_position+Vector2(10,38);motion.button_mask=MOUSE_BUTTON_MASK_LEFT;Input.parse_input_event(motion)
 await process_frame
 await click(motion.position,false)
 check(s.items[gun2.id].container_id=="bag" and s.items[gun2.id].rotated and s.items[gun2.id].cell==[0,0],"real drag motion and R rotation")
 s.player.quick[0]="medical_needle"
 inv.spawn(s,"medical_needle","bag",20)
 p.refresh()
 check(inv.quick_count(s,0)==20,"quick total four stacks")
 var quickrow=p.get_child(0).get_child(3)
 var active_color=quickrow.get_child(0).modulate
 for entry in inv.items_in(s,"bag"):
  if entry.definition_id=="medical_needle":s.items.erase(entry.id)
 p.refresh()
 check(quickrow.get_child(0).disabled or quickrow.get_child(0).modulate!=active_color,"empty bound quick slot visually grays")
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://docs/testing/DEV-204-qa.png")
 print("QA_FAILURES "+str(failures))
 quit(1 if failures.size() else 0)




