extends CanvasLayer
const QuestPresentation = preload("res://scripts/ui/progression/quest_presentation.gd")
signal committed(revision:int)
var actor:CharacterBody2D
var mode:='talents'
var box:PanelContainer
var rows:VBoxContainer
var feedback:Label
var permission:Callable
var terminal:=false
var reset_dialog:ConfirmationDialog
var revision:=''
var names:Dictionary={'vitality':'体魄：生命上限','stamina':'耐力：体力上限','accuracy':'精准：基础散布','stealth':'潜行：视觉积累减速','hurt_speed':'应激：生命受伤后加速','storage':'仓储技术','agriculture':'稳定返种'}
func _ready():
 layer=20
 box=PanelContainer.new();box.position=Vector2(180,70);box.size=Vector2(920,560);add_child(box)
 var scroll:=ScrollContainer.new();scroll.custom_minimum_size=Vector2(900,530);box.add_child(scroll)
 rows=VBoxContainer.new();rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(rows)
 visible=false
func at_base()->bool:
 if permission.is_valid():return permission.call()
 return actor.arena.has_method('station_active') and not actor.arena.state.expedition.get('active',false) and actor.arena.state.phase in ['morning','dusk']
func handle_input(event):
 if get_tree().paused:get_viewport().set_input_as_handled();return
 if is_instance_valid(reset_dialog) and reset_dialog.visible:
  if event.is_action_pressed('cancel'):reset_dialog.hide();reset_dialog.canceled.emit()
  get_viewport().set_input_as_handled();return
 if event.is_action_pressed('talents') or event.is_action_pressed('quests'):
  if actor.arena.hud!=null and actor.arena.hud.inventory_panel!=null and actor.arena.hud.inventory_panel.visible:return
  var selected:='talents' if event.is_action_pressed('talents') else 'quests'
  if visible and mode==selected:close()
  else:open_view(selected,false)
  get_viewport().set_input_as_handled()
 elif visible and event.is_action_pressed('cancel'):
  close();get_viewport().set_input_as_handled()
func open_view(selected:String,is_terminal:bool=false):
 mode=selected;terminal=is_terminal and at_base();visible=true;actor.progression_ui_blocked=true;refresh()
func close():
 visible=false;actor.progression_ui_blocked=false
 actor.progression_pointer_guard=Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
func _process(_dt):
 if not is_instance_valid(actor):queue_free();return
 if not visible:return
 if terminal and not at_base():terminal=false;refresh()
 var current:=str(actor.arena.state.day)+str(actor.arena.state.player.get('growth',{}))+str(actor.arena.state.quests)
 if revision!=current:revision=current;refresh()
func label(text:String)->Label:
 var item:=Label.new();item.text=text;rows.add_child(item);return item
func button(text:String,callback:Callable):
 var item:=Button.new();item.action_mode=BaseButton.ACTION_MODE_BUTTON_PRESS;item.text=text;bind_button(item,callback);rows.add_child(item);return item
func result(ok:bool):
 refresh();feedback.text='已提交' if ok else '条件不足或状态已变化，未提交'
 if ok:
  var s:Dictionary=actor.arena.state
  s.progression.ui_revision=int(s.progression.get('ui_revision',0))+1
  committed.emit(s.progression.ui_revision)
func refresh():
 for child in rows.get_children():rows.remove_child(child);child.queue_free()
 var s:Dictionary=actor.arena.state
 var inv:InventoryService=actor.arena.inventory
 var growth:PlayerGrowth=actor.growth_bridge.growth
 label('成长与基地终端')
 button('关闭 [Esc]',close)
 if mode=='talents':
  var g:=growth.snapshot(s);label('等级 %d   累计经验 %d   可用点 %d'%[g.level,g.xp,g.points])
  var surface:=Control.new();surface.custom_minimum_size=Vector2(850,250);rows.add_child(surface)
  var positions:Dictionary={'vitality':Vector2(20,10),'stamina':Vector2(290,10),'accuracy':Vector2(560,10),'hurt_speed':Vector2(290,150),'stealth':Vector2(560,150)}
  for id in growth.config.nodes:
   var node:Dictionary=growth.config.nodes[id]
   for required in node.requires:
    var line:=Line2D.new();line.points=PackedVector2Array([positions[required]+Vector2(115,65),positions[id]+Vector2(115,0)]);line.width=3;line.default_color=Color.CYAN;surface.add_child(line)
   var item:=Button.new();item.action_mode=BaseButton.ACTION_MODE_BUTTON_PRESS;item.position=positions[id];item.size=Vector2(245,65);item.text='%s\n%d / %d'%[names[id],g.ranks.get(id,0),node.max_rank];bind_button(item,invest.bind(id));surface.add_child(item)
  label('潜行只减警觉积累；应激只在实际生命损失后触发，重复刷新不叠加。')
  var reset_button=button('基地洗点：预览费用',func():
   var quote:=growth.preview_reset(s,at_base())
   if not quote.ok:result(false);return
   var dialog:=ConfirmationDialog.new();reset_dialog=dialog;dialog.dialog_text='消耗能源 %s、材料 %s，返还天赋点。'%[quote.cost.energy,materials(quote.cost.materials)];add_child(dialog)
   dialog.confirmed.connect(func():result(actor.growth_bridge.reset(s,inv,quote,at_base()));dialog.queue_free())
   dialog.canceled.connect(dialog.queue_free);dialog.popup_centered())
  reset_button.disabled=not at_base()
 elif mode=='technology':
  var tech:=TechnologyService.new(inv)
  var surface:=Control.new();surface.custom_minimum_size=Vector2(850,230);rows.add_child(surface)
  var positions:Dictionary={'storage':Vector2(40,20),'agriculture':Vector2(430,120)}
  for id in tech.config.nodes:
   var node:Dictionary=tech.config.nodes[id]
   for required in node.requires:
    var line:=Line2D.new();line.points=PackedVector2Array([positions[required]+Vector2(160,70),positions[id]+Vector2(160,0)]);line.width=3;line.default_color=Color.CYAN;surface.add_child(line)
   var item:=Button.new();item.action_mode=BaseButton.ACTION_MODE_BUTTON_PRESS;item.position=positions[id];item.size=Vector2(330,80)
   item.text='%s\n能源%s · %s\n%s'%[names.get(id,id),node.energy,materials(node.materials),'已解锁' if s.base.get('technology',{}).has(id) else '解锁']
   bind_button(item,unlock.bind(id));surface.add_child(item)
  var building_config:Dictionary=JSON.parse_string(FileAccess.get_file_as_string('res://data/buildings.json'))
  var storage_level:=1
  for building in s.base.get('buildings',{}).values():
   if building.type=='warehouse':storage_level=int(building.level)
  label('仓库等级 %s → %s，费用：%s'%[storage_level,storage_level+1,materials(building_config.types.warehouse.cost)])
  button('升级仓库',func():
   var buildings:=BuildingService.new(inv,JSON.parse_string(FileAccess.get_file_as_string('res://data/buildings.json')))
   result(terminal and at_base() and actor.growth_bridge.storage_upgrade(s,buildings)))
 else:
  var quests:=QuestService.new(inv);quests.setup(s)
  label('主线不限期；每日最多5个。期限继续，交付后才领奖。')
  if terminal:
   var available:Dictionary=quests.config.definitions.duplicate()
   available.merge(s.quests.offers)
   var daily_index:=0
   var daily_number:=0
   for id in available:
    if quests.config.definitions.has(id) and quests.config.definitions[id].kind!='main':continue
    var definition_id:String=s.quests.offers.get(id,id)
    var definition:Dictionary=quests.config.definitions[definition_id]
    var reason:=''
    if s.quests.active.has(id):reason='已接取'
    elif s.quests.completed.has(id):reason='已完成'
    for required in definition.get('requires',[]):
     if not s.quests.completed.has(required):reason='需先完成：'+quest_name(required)
    if definition.kind=='daily':daily_index+=1
    var prefix:='主线' if definition.kind=='main' else '每日委托 %d'%daily_index
    var item=button('%s · %s\n%s\n%s'%[prefix,quest_name(definition_id),quest_details(definition),reason if reason!='' else '点击接取'],quest_action.bind('accept',id))
    item.disabled=reason!=''
  for id in s.quests.active:
   var q:=quests.status(s,id)
   var presentation:=QuestPresentation.describe(q)
   var quest_label:=label(presentation.text)
   quest_label.add_theme_color_override('font_color',presentation.color)
   label(quest_details(q.definition_data))
   if terminal:button('交付 '+quest_name(q.definition),quest_action.bind('deliver',id))
   button('放弃 '+quest_name(q.definition),quest_action.bind('abandon',id))
  for pending in s.quests.pending_stages:label('阶段%s将在第%s天生效'%[pending.stage,pending.effective_day])
  if s.quests.ending!='':label('已恢复外界联系，可以继续游玩')
 feedback=Label.new();rows.add_child(feedback)


func materials(cost:Dictionary)->String:
 var parts:PackedStringArray=[]
 for id in cost:parts.append('%s×%s'%[{'scrap':'废料','seed_material':'材料作物种子','seed_catalyst':'催化作物种子'}.get(id,'材料'),cost[id]])
 return '无需材料' if parts.is_empty() else '、'.join(parts)
func quest_name(id:String)->String:
 return {'main_1':'调查郊区中继记录','main_2':'恢复城区外界通信','daily_kill':'清理感染者','daily_scrap':'提交废料'}.get(id,'委托')

func bind_button(item:Button,callback:Callable):
 item.gui_input.connect(func(event):
  if item.disabled:return
  if (event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed) or event.is_action_pressed('ui_accept'):
   item.accept_event();callback.call())
func invest(id:String):result(actor.growth_bridge.growth.invest(actor.arena.state,id).ok)
func unlock(id:String):result(TechnologyService.new(actor.arena.inventory).unlock(actor.arena.state,id,terminal and at_base()).ok)
func quest_action(action:String,id:String):
 var quests:=QuestService.new(actor.arena.inventory)
 if action=='abandon':quests.abandon(actor.arena.state,id);result(true)
 else:result(quests.call(action,actor.arena.state,id,terminal and at_base()).ok)

func try_terminal()->bool:
 if not at_base():return false
 var projection=actor.arena.get('grid')
 if projection==null:return false
 for building in actor.arena.state.base.get('buildings',{}).values():
  if building.type not in ['technology','quest'] or building.durability<=0:continue
  var catalog:Dictionary=JSON.parse_string(FileAccess.get_file_as_string('res://data/buildings.json'))
  var size:Array=catalog.types[building.type].size
  var point:Vector2=projection.logical_to_world((Vector2(building.cell[0],building.cell[1])+Vector2(size[0],size[1])*0.5)*48)
  if actor.position.distance_to(point)<100:
   open_view('technology' if building.type=='technology' else 'quests',true);return true
 return false
func quest_details(definition:Dictionary)->String:
 var region:String={'suburbs':'郊区','city':'城区','armory':'武器库'}.get(definition.get('region',''),'待探索区域')
 var objective:String={'kill':'击败感染者','reach':'调查目标','deliver':'提交废料'}.get(definition.objective,'完成目标')
 var reward:Dictionary=definition.reward
 return '%s ×%d · %s · %s\n奖励：经验%d、能源%d、%s'%[objective,definition.count,region,'无限期' if definition.kind=='main' else '%d天内交付'%definition.duration,reward.xp,reward.energy,materials(reward.materials)]



