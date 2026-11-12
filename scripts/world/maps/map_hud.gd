extends "res://scripts/ui/combat_hud.gd"
var menu:=PanelContainer.new()
var choices:=VBoxContainer.new()
var map_view:Control
var full_map:=false
var hint:=Label.new()
var quest_list:=RichTextLabel.new()
func _ready():
 super._ready()
 charge_title.hide()
 quest_list.position=Vector2(1050,200);quest_list.size=Vector2(210,400);quest_list.bbcode_enabled=true;quest_list.add_theme_font_size_override('normal_font_size',14);add_child(quest_list)
 # 地图拥有自己的任务追踪，明确释放父HUD同类控件。
 if is_instance_valid(task_tracker):task_tracker.queue_free();task_tracker=null
 for child in get_children():
  if child is Label and child.text.begins_with('任务追踪：'):child.queue_free()
  if child.get_script()!=null and child.get_script().resource_path.ends_with('combat_minimap.gd'):child.queue_free()
 menu.position=Vector2(300,100);menu.custom_minimum_size=Vector2(680,450);menu.add_child(choices);add_child(menu);menu.hide()
 map_view=load('res://scripts/world/maps/map_view.gd').new();map_view.arena=arena;map_view.position=Vector2(1050,20);map_view.size=Vector2(210,170);add_child(map_view)
 hint.position=Vector2(360,630);add_child(hint)
func clear_choices(title:String):
 for child in choices.get_children():choices.remove_child(child);child.queue_free()
 var heading:=Label.new();heading.text=title;choices.add_child(heading)
 menu.show();opened=true
func option(text_value:String,callback:Callable):
 var b:=Button.new();b.text=text_value;choices.add_child(b);b.pressed.connect(callback)
func close_menu():menu.hide();opened=false
func show_departure():
 clear_choices('避难所出发终端 · 第 %d 天 · %s'%[arena.state.day,arena.state.phase])
 if arena.state.cycle.failed:
  option('基地失守：本入口等待最终保存恢复界面接入',func():pass);return
 option('背包与仓库',func():close_menu();open_inventory())
 for id in ['main_1','main_2']:
  option('接取主线 '+id,func():arena.message=str(arena.services.quests.accept(arena.state,id,true));show_departure())
  option('交付主线 '+id,func():arena.message=str(arena.services.quests.deliver(arena.state,id,true));show_departure())
 if arena.state.phase=='morning':
  for id in arena.state.world.exploration.unlocked:
   for spawn in arena.state.world.exploration.spawns[id]:option('白天出发：'+arena.catalog[id].title+' / '+spawn,func():arena.depart(id,spawn))
  option('留在基地直到黄昏',func():arena.cycle.to_dusk(arena.state);show_departure())
 elif arena.state.phase=='dusk':
  for id in arena.state.world.exploration.unlocked:
   for spawn in arena.state.world.exploration.spawns[id]:option('夜间探索：'+arena.catalog[id].title+' / '+spawn,func():confirm_night(id,spawn))
  option('自动守夜至次日（需确认风险）',func():confirm_night('',''))
 option(arena.message,func():pass)
func confirm_night(id:String,spawn:String):
 clear_choices('夜间由基地自动防守。防御不足可能失守，仍要继续？')
 option('确认',func():
  if id.is_empty():
   var result:Dictionary=arena.cycle.begin_night(arena.state,'rest',true)
   if result.ok:arena.cycle.finish_night(arena.state)
   arena.sync_unlocks();show_departure()
  else:arena.depart(id,spawn,true,true))
 option('返回',show_departure)
func show_travel(source:String):
 clear_choices('传送消耗随身电池能源 15；仅可前往已修复点')
 for key in arena.state.world.exploration.travel:
  var part:Array=key.split(':')
  if part[0]==arena.state.expedition.map_id and part[1]==source:continue
  option(arena.catalog[part[0]].title,func():
   if arena.exploration.travel(arena.state,source,part[0],part[1],15):await arena.rebuild_map();close_menu()
   else:arena.message='随身能源不足')
 option('关闭',close_menu)
func _input(event):
 var progression=arena.player.get('progression_panel')
 if event.is_action_pressed('talents') or event.is_action_pressed('quests') or (event.is_action_pressed('cancel') and progression!=null and progression.visible):
  if menu.visible:get_viewport().set_input_as_handled();return
  super._input(event);return
 if progression!=null and progression.visible and event.is_action_pressed('interact'):
  get_viewport().set_input_as_handled();return
 if event.is_action_pressed('map'):
  full_map=not full_map;map_view.position=Vector2(240,70) if full_map else Vector2(1050,20);map_view.size=Vector2(800,560) if full_map else Vector2(210,170);get_viewport().set_input_as_handled();return
 if event.is_action_pressed('interact') and not opened and (inventory_panel==null or not inventory_panel.visible):arena.interact();get_viewport().set_input_as_handled();return
 if menu.visible:
  if event.is_action_pressed('cancel') and arena.state.expedition.get('active',false):close_menu()
  return
 super._input(event)
func _process(dt):
 super._process(dt)
 label.text='生命 %.0f / %.0f · 第 %d 天 %s\n%s'%[arena.state.player.vitals.hp,arena.state.player.vitals.max_hp,arena.state.day,arena.state.phase,arena.catalog.get(arena.state.expedition.get('map_id',''),{}).get('title','避难所')]
 var near:Dictionary=arena.nearby() if arena.ready_world else {}
 hint.text=('F '+near.get('label','')+'\n' if not near.is_empty() else '')+arena.message
 if not arena.state.expedition.get('active',false) and not menu.visible and not opened and (inventory_panel==null or not inventory_panel.visible):show_departure()
 var tracked:=QuestPresentation.tracker(arena.state,arena.services.quests)
 if quest_list.text!=tracked:quest_list.text=tracked
 map_view.queue_redraw()


