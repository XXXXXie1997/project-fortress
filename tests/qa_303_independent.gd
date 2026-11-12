extends SceneTree
func _initialize():call_deferred("run")
func run():
 var a=load("res://scenes/ui/base/base_management_arena.tscn").instantiate()
 root.add_child(a)
 while a.management==null:await process_frame
 var u=a.management
 var s=a.state
 var inv=a.inventory
 var before=WorldState.encode(s)
 assert(not a.building.demolish(s,"building_1"))
 assert(WorldState.encode(s)==before)
 assert(a.building.build(s,"generator",[10,16],Rect2i(0,0,24,18)).is_empty())
 assert(WorldState.encode(s)==before)
 var battery=inv.spawn(s,"battery_basic","bag")
 s.items[battery.id].energy=17
 s.base.energy_store.energy=s.base.energy_store.capacity
 u.sell_basket=[battery.id]
 before=WorldState.encode(s)
 u.commit_trade(false)
 assert(u.confirmation.visible)
 assert(WorldState.encode(s)==before)
 u.confirmation.canceled.emit();u.confirmation.hide()
 assert(WorldState.encode(s)==before)
 u.commit_trade(true)
 assert(s.items[battery.id].container_id=="buyback")
 assert(s.items[battery.id].energy==17)
 assert(u.sell_basket.is_empty())
 assert(u.submit_order("building_4","medical",2))
 u.show_production("building_4")
 for child in u.content.get_children():
  if child is Label:print("PRODUCTION_LABEL:",child.text)
 var farm=a.building.build(s,"farm",[9,7],Rect2i(0,0,24,18))
 inv.spawn(s,"seed_material","warehouse",1)
 assert(u.services.farming.plant(s,farm,"material"))
 u.show_farm(farm)
 for child in u.content.get_children():
  if child is Label:print("FARM_LABEL:",child.text)
 print("QA303_TRANSACTION_PASS")
 a.queue_free();await process_frame;quit()
