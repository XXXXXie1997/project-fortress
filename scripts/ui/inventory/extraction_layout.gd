extends RefCounted
const ThemeStyle=preload('res://scripts/ui/keeper_theme.gd')
static func caption(parent:Node,text:String,at:Vector2)->Label:
 var node:=Label.new();node.text=text;node.position=at;node.mouse_filter=Control.MOUSE_FILTER_IGNORE;parent.add_child(node);return node
static func setup(p):
 var root:Control=p.get_child(0)
 for node in root.get_children():
  if node is ColorRect:node.hide()
  if node is Label and node!=p.info and node!=p.feedback:node.hide()
  if node is Button and node.text=='关闭':node.position=Vector2(1152,14);node.size=Vector2(80,ThemeStyle.BUTTON_HEIGHT)
 p.reference_ui.scrim=ColorRect.new();p.reference_ui.scrim.position=Vector2(-16,-16);p.reference_ui.scrim.size=Vector2(1280,720);p.reference_ui.scrim.color=Color('0c1119');p.reference_ui.scrim.mouse_filter=Control.MOUSE_FILTER_IGNORE;root.add_child(p.reference_ui.scrim);root.move_child(p.reference_ui.scrim,0)
 var top:=Panel.new();top.position=Vector2(-16,-16);top.size=Vector2(1280,72);top.mouse_filter=Control.MOUSE_FILTER_IGNORE;root.add_child(top);root.move_child(top,1)
 p.reference_ui.bag_panel=Panel.new();p.reference_ui.bag_panel.position=Vector2(416,64);p.reference_ui.bag_panel.size=Vector2(416,608);p.reference_ui.bag_panel.mouse_filter=Control.MOUSE_FILTER_IGNORE;root.add_child(p.reference_ui.bag_panel);root.move_child(p.reference_ui.bag_panel,2)
 p.reference_ui.header=caption(root,'物资管理',Vector2(16,12))
 p.reference_ui.header.add_theme_font_size_override('font_size',ThemeStyle.FONT_TITLE)
 caption(root,'装备',Vector2(16,316))
 p.reference_ui.left_title=caption(root,'背包',Vector2(432,76))
 p.reference_ui.right_title=caption(root,'仓库',Vector2(832,76))
 p.reference_ui.bind_title=caption(root,'拖动或选择物品 · 绑定快捷栏',Vector2(448,548))
 p.reference_ui.empty=caption(root,'拖动放置 · 双击转移\nR 旋转选中物品',Vector2(448,372))
 p.reference_ui.empty.modulate=ThemeStyle.MUTED
 p.reference_ui.detail_frame=Panel.new();p.reference_ui.detail_frame.position=Vector2(432,96);p.reference_ui.detail_frame.size=Vector2(368,344);p.reference_ui.detail_frame.mouse_filter=Control.MOUSE_FILTER_STOP;root.add_child(p.reference_ui.detail_frame);root.move_child(p.reference_ui.detail_frame,0)
 p.detail_scroll.reparent(root)
 root.move_child(p.reference_ui.detail_frame,root.get_child_count()-1)
 root.move_child(p.detail_scroll,root.get_child_count()-1)
 p.grid.mouse_filter=Control.MOUSE_FILTER_IGNORE
 p.grid.position=Vector2.ZERO;p.grid.size=Vector2(1248,688)
 for right in [false,true]:
  var surface:=Control.new();surface.clip_contents=true;surface.mouse_filter=Control.MOUSE_FILTER_STOP;p.grid.add_child(surface)
  surface.draw.connect(func():p.draw_grid_side(right,surface))
  surface.gui_input.connect(func(event):
   if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
    p.grid_vscroll[int(right)].value+=(-1 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1)*64;surface.accept_event();return
   if event is InputEventMouse:
    var translated=event.duplicate();translated.position+=surface.position;p.grid_input(translated))
  p.grid_surfaces.append(surface)
  var horizontal:=HScrollBar.new();root.add_child(horizontal);horizontal.step=1;horizontal.value_changed.connect(func(_value):surface.queue_redraw());p.grid_hscroll.append(horizontal)
  var vertical:=VScrollBar.new();root.add_child(vertical);vertical.step=1;vertical.value_changed.connect(func(_value):surface.queue_redraw());p.grid_vscroll.append(vertical)
static func arrange(p):
 if p.reference_ui.is_empty():return
 var selecting:bool=p.selector_callback.is_valid()
 p.reference_ui.scrim.visible=p.at_base
 p.size=Vector2(1248,688)
 p.left_panel.position=Vector2(0,64);p.left_panel.size=Vector2(416,608)
 p.loot_panel.position=Vector2(832,64)
 p.reference_ui.right_title.position=Vector2(848,76)
 p.equipment_layout.visible=not selecting
 p.equipment_layout.position=Vector2(16,112)
 p.info.position=Vector2(16,72);p.info.visible=not selecting
 p.weight_bar.position=Vector2(16,104);p.weight_bar.size=Vector2(384,4);p.weight_bar.visible=not selecting
 p.tabs.position=Vector2(432,76)
 for node in p.tabs.get_children():node.visible=node in p.tabs_by_source.values() and (node!=p.tabs_by_source.warehouse or p.at_base)
 p.sort_bag_button.position=Vector2(712,76);p.sort_bag_button.size=Vector2(104,ThemeStyle.COMPACT_HEIGHT)
 p.reference_ui.left_title.visible=not selecting
 p.reference_ui.right_title.visible=p.loot_panel.visible
 p.reference_ui.right_title.text='战利品' if not p.box_id.is_empty() else ('仓库' if p.remote_location()=='warehouse' else '容器')
 if p.loot_panel.visible:p.reference_ui.right_title.text+=' (%d)'%p.displayed_items(p.remote_location()).size()
 p.reference_ui.header.text='选择物品' if selecting else ('仓库 / 整备' if p.at_base else '背包 / 搜刮')
 p.detail_scroll.visible=(not p.selected.is_empty() or selecting) and p.gesture.is_empty()
 p.detail_scroll.position=Vector2(16,432);p.detail_scroll.size=Vector2(384,152)
 p.reference_ui.detail_frame.position=Vector2(0,416);p.reference_ui.detail_frame.size=Vector2(416,184)
 p.reference_ui.empty.hide()
 p.reference_ui.detail_frame.visible=p.detail_scroll.visible
 p.binding_row.visible=not selecting
 p.reference_ui.left_title.text="背包 (%d)"%p.inventory.items_in(p.state,"bag").size()
 p.binding_row.position=Vector2(16,612)
 p.binding_row.add_theme_constant_override("h_separation",4)
 p.reference_ui.bind_title.position=Vector2(16,600)
 for i in range(p.binding_row.get_child_count()):
  var node:Button=p.binding_row.get_child(i);node.custom_minimum_size=Vector2(60,48);node.text=str(i+1);node.expand_icon=true;node.clip_text=true;node.add_theme_constant_override('icon_max_width',24);node.icon=preload('res://scripts/art/fortress_art.gd').item_icon(p.state.player.quick[i]) if not p.state.player.quick[i].is_empty() else null
 p.reference_ui.bind_title.hide()
 p.reference_ui.bind_title.text='快捷栏'
 p.feedback.position=Vector2(432,14);p.feedback.size=Vector2(672,32);p.feedback.clip_text=true;p.feedback.visible=not p.feedback.text.is_empty()
 p.usage_caption.hide();p.footer_line.hide()
 for right in [false,true]:
  var index:=int(right)
  var location:String=p.remote_location() if right else p.source
  var dims:Dictionary=p.state.containers.get(location,{'width':6,'height':4})
  var origin:=Vector2(848,128) if right else Vector2(432,128)
  var height:=minf(512,float(dims.height)*64) if right else 512.0
  if location=='equipment':height=512
  var width:float=384
  var surface:Control=p.grid_surfaces[index];surface.position=origin;surface.size=Vector2(width,height);surface.visible=not location.is_empty()
  var h:ScrollBar=p.grid_hscroll[index];h.position=origin+Vector2(0,height+4);h.size=Vector2(width,12);h.max_value=float(dims.width)*64;h.page=width;h.visible=surface.visible and h.max_value>h.page
  var v:ScrollBar=p.grid_vscroll[index];v.position=origin+Vector2(width+4,0);v.size=Vector2(12,height);v.max_value=float(dims.height)*64;v.page=height;v.visible=surface.visible and v.max_value>v.page
  if right:p.loot_panel.size=Vector2(416,height+96)
  surface.queue_redraw()
 for button in [p.loot_take,p.sort_warehouse_button]:button.position=Vector2(p.loot_panel.size.x-136,16);button.size=Vector2(120,ThemeStyle.COMPACT_HEIGHT)
static func equipment(p):
 var keys=['weapon_1','weapon_2','weapon_3','armor','backpack','extra_1','extra_2','extra_3','extra_4']
 for i in range(keys.size()):
  if not p.slot_buttons.has(keys[i]):continue
  var b:Button=p.slot_buttons[keys[i]]
  b.position=Vector2(0,i*68) if i<3 else Vector2((i-3)*64,232)
  b.custom_minimum_size=Vector2(192,64) if i<3 else Vector2(60,56)
  b.size=b.custom_minimum_size;b.clip_text=true;b.expand_icon=true;b.add_theme_constant_override('icon_max_width',44)
  b.text='';b.icon=null
  if b.get_node_or_null('ItemArt')==null:
   var art=preload('res://scripts/ui/inventory/equipment_slot_art.gd').new();art.name='ItemArt';art.panel=p;art.slot=keys[i];b.add_child(art)
  if i<3:weapon_modules(p,b,i)
  b.size=b.custom_minimum_size



static func weapon_modules(p,weapon:Button,index:int):
 var id:String=p.state.player.equipment['weapon_'+str(index+1)]
 var item:Dictionary=p.state.items.get(id,{})
 var slots=['scope','muzzle','capacitor','tactical']
 for i in range(4):
  var name:String='Module'+str(i)
  var card:Panel=weapon.get_node_or_null(name)
  if card==null:
   card=Panel.new();card.name=name;card.mouse_filter=Control.MOUSE_FILTER_IGNORE;weapon.add_child(card)
   var label:=Label.new();label.name='Name';label.position=Vector2(4,4);label.add_theme_font_size_override('font_size',14);label.mouse_filter=Control.MOUSE_FILTER_IGNORE;card.add_child(label)
   var icon:=TextureRect.new();icon.name='Icon';icon.position=Vector2(2,12);icon.size=Vector2(40,40);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.mouse_filter=Control.MOUSE_FILTER_IGNORE;card.add_child(icon)
  card.position=Vector2(196+i*48,0);card.size=Vector2(44,64)
  var installed:Dictionary=p.state.items.get(item.get('plugins',{}).get(slots[i],''),{})
  card.get_node('Icon').texture=preload('res://scripts/art/fortress_art.gd').item_icon(installed.get('definition_id','')) if not installed.is_empty() else null
  card.get_node('Name').text=['瞄具','枪口','电容','战术'][i] if installed.is_empty() else ''
  card.modulate=Color('68727a') if installed.is_empty() else Color.WHITE
