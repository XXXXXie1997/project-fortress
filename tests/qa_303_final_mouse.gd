extends "res://scripts/ui/base/management_mouse_self_check.gd"
func run():
 root.gui_embed_subwindows=true
 arena=load("res://scenes/ui/base/base_management_arena.tscn").instantiate();root.add_child(arena)
 while arena.management==null:await process_frame
 ui=arena.management
 await create_timer(0.3).timeout
 var s=arena.state
 var p=ui.inventory_panel
 var ids=[arena.player.item().id,arena.inventory.spawn(s,"rifle_basic","bag").id,arena.inventory.spawn(s,"rifle_basic","warehouse").id]
 var result=[]
 for n in range(3):
  ui.select_item(func(i):return i.definition_id=="rifle_basic",func(id):result.append(id))
  await process_frame;await process_frame
  var source=["equipment","bag","warehouse"][n]
  await tap(p.tabs_by_source[source].get_global_rect().get_center())
  await process_frame;await process_frame
  await tap(p.grid.global_position+p.item_rect(s.items[ids[n]],source,false).position+Vector2(8,8))
  await process_frame;await process_frame
  var confirm=find_button(p.listing,"确认选中物品")
  assert(confirm!=null)
  await tap(confirm.get_global_rect().get_center())
 assert(result==ids)
 print("QA303_MOUSE_THREE_SOURCES_PASS")
 ui.show_buildings()
 var gun=arena.player.item().id
 s.items[gun].energy=50
 for resident in arena.residents:resident.set_physics_process(false)
 arena.player.position=Vector2(700,500)
 await process_frame;await process_frame
 var close=find_button(ui.content,"关闭面板")
 await mouse(close.get_global_rect().get_center(),true)
 for n in range(8):await physics_frame
 print("QA303_CLOSE_HELD_ENERGY=",s.items[gun].energy," PANEL_VISIBLE=",ui.root_panel.visible)
 await mouse(close.get_global_rect().get_center(),false)
 ui.show_buildings()
 await process_frame
 var energy=s.items[gun].energy
 Input.action_press("fire")
 for n in range(8):await physics_frame
 Input.action_release("fire")
 assert(s.items[gun].energy==energy)
 print("QA303_OPEN_PANEL_FIRE_BLOCK_PASS")
 var old_slot=arena.player.slot
 for action in ["charge","dodge","weapon_next","weapon_previous","tactical","quick_1"]:
  var event=InputEventAction.new();event.action=action;event.pressed=true;Input.parse_input_event(event)
  event=InputEventAction.new();event.action=action;event.pressed=false;Input.parse_input_event(event)
  await process_frame
 assert(arena.player.slot==old_slot)
 assert(not s.player.combat.charging and s.player.combat.dodge_left<=0)
 print("QA303_PANEL_SHORTCUT_BLOCK_PASS")
 p.close_panel()
 for id in s.items.keys():
  if s.items[id].container_id in ["warehouse","shop","bag"]:arena.inventory.destroy(s,id)
 var sold=arena.inventory.spawn(s,"armor_basic","warehouse").id
 while not arena.inventory.spawn(s,"scope_basic","warehouse").is_empty():pass
 while not arena.inventory.spawn(s,"scope_basic","bag").is_empty():pass
 var bought=arena.inventory.spawn(s,"armor_basic","shop").id
 s.base.energy_store.energy=500
 ui.show_trade()
 await process_frame;await process_frame
 var sell=find_button(ui.content,"基础护甲")
 if sell==null:sell=find_button(ui.content,"护甲")
 assert(sell!=null)
 ui.scroll.ensure_control_visible(sell);await process_frame
 await tap(sell.get_global_rect().get_center())
 assert(ui.sell_basket==[sold])
 await process_frame;await process_frame
 var buy=find_shop(ui.content)
 assert(buy!=null)
 ui.scroll.ensure_control_visible(buy);await process_frame
 await tap(buy.get_global_rect().get_center())
 assert(ui.buy_basket==[bought])
 await click("统一成交")
 assert(s.items[sold].container_id=="buyback")
 assert(s.items[bought].container_id=="warehouse")
 print("QA303_MOUSE_SELL_FREES_BUY_PASS")
 arena.queue_free();await process_frame;quit()
func find_shop(node:Node)->Button:
 for child in node.get_children():
  if child is Button and "商店 ·" in child.text:return child
  var b=find_shop(child)
  if b!=null:return b
 return null



