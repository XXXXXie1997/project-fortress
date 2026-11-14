extends CanvasLayer
var arena:Node2D
var opened:=false
var inventory_panel: InventoryPanel
var label:=Label.new()
var card:=Label.new()
var panel:=PanelContainer.new()
var text:=Label.new()
var quick:=HBoxContainer.new()
var quick_slots:Array[Label]=[]
var charge_title:=Label.new()
const QuestPresentation = preload("res://scripts/ui/progression/quest_presentation.gd")
var task_tracker:=RichTextLabel.new()
var quest_service:QuestService
var sprint_toggle:=false
var toggle:=CheckButton.new()
var health_bar:=ProgressBar.new()
var weapon_title:=Label.new()
var energy_caption:=Label.new()
var weapon_icon:=Sprite2D.new()
var tactical_icon:=Sprite2D.new()
func _ready():
 process_mode=Node.PROCESS_MODE_ALWAYS
 var heart:=TextureRect.new();heart.texture=load("res://assets/runtime/ui/wasteland/icon_health.png");heart.position=Vector2(-44,2);heart.size=Vector2(32,32);heart.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;heart.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;label.add_child(heart)
 label.position=Vector2(84,38);label.set_meta("backdrop_rect",Rect2(-60,-14,232,74));label.custom_minimum_size=Vector2(212,58);add_child(label)
 card.position=Vector2(20,625);add_child(card)
 health_bar.position=Vector2(-44,48);health_bar.size=Vector2(190,6);health_bar.show_percentage=false;health_bar.add_theme_font_size_override("font_size",1);health_bar.mouse_filter=Control.MOUSE_FILTER_IGNORE;label.add_child(health_bar)
 var health_fill:=StyleBoxFlat.new();health_fill.bg_color=Color("9a6558");health_fill.content_margin_top=0;health_fill.content_margin_bottom=0;health_bar.add_theme_stylebox_override("fill",health_fill)
 var health_empty:=StyleBoxFlat.new();health_empty.bg_color=Color("101314");health_empty.content_margin_top=0;health_empty.content_margin_bottom=0;health_bar.add_theme_stylebox_override("background",health_empty)
 toggle.text='冲刺：按一下切换（默认按住）';toggle.position=Vector2(410,460);toggle.toggled.connect(func(value):sprint_toggle=value);add_child(toggle);toggle.hide()
 for sprite in [weapon_icon,tactical_icon]:
  sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;sprite.scale=Vector2(1.5,1.5);add_child(sprite)
 weapon_icon.position=Vector2(40,595);tactical_icon.position=Vector2(100,595)
 panel.position=Vector2(390,180);panel.custom_minimum_size=Vector2(500,260);panel.add_child(text);add_child(panel);panel.hide()
 quick.position=Vector2(400,675);quick.add_theme_constant_override("separation",28);add_child(quick)
 for i in range(6):
  var slot_label:=Label.new();slot_label.custom_minimum_size=Vector2(34,60);slot_label.set_meta("backdrop_rect",Rect2(-10,-8,54,76));slot_label.add_theme_font_size_override("font_size",13);quick.add_child(slot_label);quick_slots.append(slot_label)
  preload("res://scripts/ui/hud_backdrop.gd").attach(slot_label)
  var icon:=TextureRect.new();icon.name='ArtIcon';icon.position=Vector2(7,16);icon.size=Vector2(26,26);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.mouse_filter=Control.MOUSE_FILTER_IGNORE;icon.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;slot_label.add_child(icon)
  var amount:=Label.new();amount.name='Amount';amount.position=Vector2(0,44);amount.size=Vector2(34,16);amount.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;amount.add_theme_font_size_override('font_size',13);slot_label.add_child(amount)
 var minimap=load('res://scripts/ui/combat_minimap.gd').new();minimap.arena=arena;minimap.position=Vector2(1044,36);minimap.size=Vector2(200,126);minimap.set_meta("backdrop_rect",Rect2(-12,-12,224,174));add_child(minimap);preload("res://scripts/ui/hud_backdrop.gd").attach(minimap)
 var map_title:=Label.new();map_title.text="避难所";map_title.position=Vector2(4,136);map_title.add_theme_color_override("font_color",Color("a6aaa0"));minimap.add_child(map_title)
 quest_service=QuestService.new(arena.inventory)
 task_tracker.position=Vector2(1048,224);task_tracker.set_meta("backdrop_rect",Rect2(-16,-14,224,112));task_tracker.size=Vector2(192,84);task_tracker.bbcode_enabled=true;task_tracker.add_theme_font_size_override('normal_font_size',16);task_tracker.text='任务追踪：尚无任务';add_child(task_tracker)
 charge_title.position=Vector2(980,640);charge_title.text='测试能源站：靠近无线充能\n靠近后 F 切换测试下挂\nV 开关灯 / 激光 / 发射器';add_child(charge_title)
 preload("res://scripts/ui/hud_backdrop.gd").attach(label)
 card.custom_minimum_size=Vector2(228,28)
 weapon_title.position=Vector2(94,-28);weapon_title.add_theme_font_size_override("font_size",16);weapon_title.add_theme_color_override("font_color",Color("a6aaa0"));card.add_child(weapon_title)
 energy_caption.text="电容 / 随身总电量  [R]";energy_caption.position=Vector2(6,40);energy_caption.add_theme_font_size_override("font_size",16);energy_caption.add_theme_color_override("font_color",Color("a6aaa0"));card.add_child(energy_caption)
 card.add_theme_font_size_override("font_size",28)
 card.add_theme_color_override("font_color",Color("c5a065"))
 preload("res://scripts/ui/hud_backdrop.gd").attach(card,52)
 preload("res://scripts/ui/hud_backdrop.gd").attach(task_tracker)
 preload("res://scripts/ui/hud_backdrop.gd").attach(charge_title)
func _input(event):
 var management=arena.get('management')
 if management!=null and management.has_method('is_modal_open') and management.is_modal_open():
  if event.is_action_pressed('talents') or event.is_action_pressed('quests'):get_viewport().set_input_as_handled()
  return
 if inventory_panel!=null and inventory_panel.visible:
  if event.is_action_pressed('cancel') or event.is_action_pressed('inventory'):
   inventory_panel.close_panel();get_viewport().set_input_as_handled()
  elif event is InputEventKey and event.pressed and event.keycode>=KEY_1 and event.keycode<=KEY_6:
   if inventory_panel.accessible_item(inventory_panel.selected):arena.state.player.quick[event.keycode-KEY_1]=arena.state.items[inventory_panel.selected].definition_id
   inventory_panel.refresh();get_viewport().set_input_as_handled()
  return
 if arena.player.get('progression_panel')!=null and (event.is_action_pressed('talents') or event.is_action_pressed('quests') or (event.is_action_pressed('cancel') and arena.player.progression_panel.visible)):
  arena.player.progression_panel.handle_input(event);return
 if event.is_action_pressed('inventory'):
  open_inventory();get_viewport().set_input_as_handled();return
 if event.is_action_pressed('interact') and arena.player.get('progression_panel')!=null and arena.player.progression_panel.try_terminal():
  get_viewport().set_input_as_handled();return
 if event.is_action_pressed('interact') and arena.state.expedition.get('active',false):
  var exp:ExplorationService=arena.get('exploration')
  if exp!=null:
   for id:String in arena.state.expedition.maps[arena.state.expedition.map_id].containers:
    var box:Dictionary=exp.box(arena.state,id)
    if arena.player.global_position.distance_to(Vector2(box.position[0],box.position[1]))<90:
     open_inventory(id);get_viewport().set_input_as_handled();return
 if event.is_action_pressed('cancel'):
  if opened:panel.hide();toggle.hide();opened=false;get_tree().paused=false
  else:show_panel('暂停\nEsc 继续',true)
  get_viewport().set_input_as_handled()
 for action in ['map','quests','talents']:
  if event.is_action_pressed(action):
   show_panel({'inventory':'背包','map':'地图','quests':'任务','talents':'天赋'}[action]+'\n后续系统接入中\nEsc 关闭',false)
   get_viewport().set_input_as_handled()
func show_panel(content:String,pause:bool):
 text.text=content;panel.show();opened=true;get_tree().paused=pause;toggle.visible=pause
func _process(_dt):
 health_bar.size=Vector2(196,8)
 health_bar.max_value=arena.state.player.vitals.max_hp;health_bar.value=arena.state.player.vitals.hp
 if is_instance_valid(task_tracker):
  var tracked:=QuestPresentation.tracker(arena.state,quest_service)
  if task_tracker.text!=tracked:task_tracker.text=tracked
  label.text='生命\n%.0f / %.0f'%[arena.state.player.vitals.hp,arena.state.player.vitals.max_hp]
 var weapon:Dictionary=arena.player.item()
 var energy:=0.0
 for i in arena.inventory.items_in(arena.state,'bag'):
  if i.get('is_battery',false):energy+=i.energy
 for i in range(6):
  var count:int=arena.inventory.quick_count(arena.state,i)
  quick_slots[i].text=str(i+1);quick_slots[i].vertical_alignment=VERTICAL_ALIGNMENT_TOP
  quick_slots[i].get_node('Amount').text=str(count) if count>0 else '—'
  quick_slots[i].modulate=Color.WHITE
  quick_slots[i].add_theme_color_override("font_color",Color("ddd9cc") if count>0 else Color("75838b"))
  var icon:TextureRect=quick_slots[i].get_node('ArtIcon')
  var quick_id:String=arena.state.player.quick[i]
  icon.texture=preload('res://scripts/art/fortress_art.gd').item_icon(quick_id) if not quick_id.is_empty() else null
 weapon_icon.texture=preload('res://scripts/art/fortress_art.gd').item_icon(weapon.definition_id) if not weapon.is_empty() else null;weapon_icon.visible=not weapon.is_empty()
 var tactical:Dictionary=arena.player.tactical.battery()
 tactical_icon.texture=preload('res://scripts/art/fortress_art.gd').item_icon(tactical.definition_id) if not tactical.is_empty() else null;tactical_icon.visible=not tactical.is_empty()
 card.modulate=Color("e7c18a") if arena.state.player.combat.charging else Color.WHITE
 weapon_title.text=preload('res://scripts/content/catalog.gd').item_name(weapon.get('definition_id',''))
 card.text='      %.0f / %.0f'%[weapon.get('energy',0),energy]
 layout_bottom_hud()




func open_inventory(box_id:String=""):
 if inventory_panel==null:
  inventory_panel=InventoryPanel.new()
  inventory_panel.bind_state(arena.state,arena.inventory)
  add_child(inventory_panel)
  inventory_panel.movement_lock_changed.connect(func(locked):arena.player.inventory_movement_locked=locked)
  inventory_panel.charging_requested.connect(arena.player.request_inventory_charge)
 inventory_panel.exploration=arena.get('exploration') if arena.state.expedition.get('active',false) else null
 inventory_panel.at_base=not arena.state.expedition.get('active',false)
 inventory_panel.open_panel(box_id)







func layout_bottom_hud():
 var viewport_size:=get_viewport().get_visible_rect().size
 card.position=Vector2(34,viewport_size.y-82);card.set_meta("backdrop_rect",Rect2(-10,-42,248,100))
 weapon_icon.position=Vector2(74,card.position.y-4)
 weapon_icon.scale=Vector2(2.5,2.5)
 tactical_icon.position=Vector2(100,card.position.y-26)
 quick.position=Vector2(430+(viewport_size.x-1280)*0.5,viewport_size.y-92)
 charge_title.position=Vector2(maxf(20,viewport_size.x-20-charge_title.get_combined_minimum_size().x),viewport_size.y-76-charge_title.get_combined_minimum_size().y)
