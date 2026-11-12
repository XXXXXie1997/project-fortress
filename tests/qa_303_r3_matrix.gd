extends SceneTree
func _initialize():call_deferred("run")
func run():
 var a=load("res://scenes/ui/base/base_management_arena.tscn").instantiate();root.add_child(a)
 while a.management==null:await process_frame
 var u=a.management
 var s=a.state
 var inv=a.inventory
 var chosen=[]
 var ids=[a.player.item().id,inv.spawn(s,"rifle_basic","bag").id,inv.spawn(s,"rifle_basic","warehouse").id]
 for id in ids:
  u.select_item(func(i):return i.definition_id=="rifle_basic",func(selected):chosen.append(selected))
  u.inventory_panel.selected=id
  u.inventory_panel.confirm_selection()
 assert(chosen==ids)
 var before=WorldState.encode(s)
 u.select_item(func(i):return true,func(selected):chosen.append(selected))
 u.inventory_panel.selected=ids[2];u.inventory_panel.close_panel()
 assert(chosen==ids and before==WorldState.encode(s))
 var shop=inv.spawn(s,"knife_basic","shop").id
 while not inv.spawn(s,"scope_basic","warehouse").is_empty():pass
 u.buy_basket=[shop];u.target="warehouse";u.commit_trade(false)
 assert(s.items[shop].container_id=="bag")
 var shop2=inv.spawn(s,"knife_basic","shop").id
 while not inv.spawn(s,"scope_basic","bag").is_empty():pass
 u.buy_basket=[shop2];u.commit_trade(false)
 assert(s.items[shop2].container_id not in ["shop","bag","warehouse"])
 print("QA303_R3_SELECTOR_AND_FALLBACK_PASS")
 a.queue_free();await process_frame;quit()
