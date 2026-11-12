extends "res://scripts/ui/base/management_mouse_self_check.gd"
func run():
 root.gui_embed_subwindows=true
 arena=load("res://scenes/ui/base/base_management_arena.tscn").instantiate();root.add_child(arena)
 while arena.management==null:await process_frame
 ui=arena.management
 await create_timer(0.5).timeout
 var s=arena.state
 var inv=arena.inventory
 assert(ui.submit_order("building_4","medical",3))
 var before=WorldState.encode(s)
 for n in range(10):assert(ui.production_status("building_4").contains("医疗针"))
 assert(before==WorldState.encode(s))
 s.base.buildings.building_4.durability=0
 before=WorldState.encode(s)
 assert(ui.production_status("building_4").contains("废墟暂停"))
 assert(before==WorldState.encode(s))
 s.base.buildings.building_4.durability=100
 assert(ui.services.production.settle(s,"qa303:r2"))
 assert(ui.production_status("building_4").contains("已产 1 / 总量 3"))
 assert(ui.services.production.cancel(s,"building_4"))
 var farm=arena.building.build(s,"farm",[9,7],Rect2i(0,0,24,18))
 inv.spawn(s,"seed_material","warehouse")
 assert(ui.services.farming.plant(s,farm,"material"))
 s.containers.warehouse.width=1;s.containers.warehouse.height=1
 ui.services.farming.settle(s,"qa303:f1",true);ui.services.farming.settle(s,"qa303:f2",true)
 before=WorldState.encode(s)
 for n in range(10):assert(ui.farm_status(farm).contains("满仓留田"))
 assert(before==WorldState.encode(s))
 s.containers.warehouse.width=12;s.containers.warehouse.height=8
 assert(ui.services.farming.collect_ready(s)==1)
 assert(ui.services.farming.collect_ready(s)==0)
 ui.show_buildings()
 await click("建造炮塔")
 var count=s.base.buildings.size()
 await world_tap(Vector2i(13,11))
 assert(s.base.buildings.size()==count+1)
 ui.show_buildings();await click("建造炮塔")
 var energy=s.base.energy_store.energy
 await world_tap(Vector2i(13,11))
 assert(s.base.buildings.size()==count+1 and s.base.energy_store.energy==energy)
 ui.inspect("building_1");await click("移动")
 await world_tap(Vector2i(16,7))
 assert(s.base.buildings.building_1.cell==[16,7])
 var stations=0
 for b in s.base.buildings.values():
  if b.type=="warehouse":stations+=1
 assert(stations==1)
 ui.inspect("building_1");await click("拆除")
 assert(s.base.buildings.has("building_1"))
 ui.show_farm(farm)
 await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://docs/testing/qa303-r2.png")
 print("QA303_R2_GUI_AND_STATUS_PASS")
 arena.queue_free();await process_frame;quit()
