class_name InventoryPanel
extends PanelContainer
signal movement_lock_changed(locked: bool)
signal item_selected(id: String)
signal charging_requested(target_id: String, battery_id: String)
var selector_filter: Callable
var selector_callback: Callable
var external_container := ""
var external_permission: Callable
var external_filter: Callable
var tabs_by_source := {}
var slot_buttons := {}
var held_button: Button
var refresh_pending := false
var suppress_slot_click := false
var state: Dictionary
var inventory: InventoryService
var exploration: ExplorationService
var box_id := ""
var selected := ""
var rotated := false
var loot_panel: Panel
var loot_take: Button
var usage_caption: Label
var footer_line: ColorRect
var left_panel: Panel
var grid: Control
var source := "bag"
var at_base := true:
	set(value):
		at_base=value
		if not value and source=="warehouse": source="bag"
		selected=""
		battery_id=""
var last_feedback := ""
var feedback: Label
var info: Label
var listing: VBoxContainer
var equipment_layout:Control
var weight_bar:ProgressBar
var sort_warehouse_button:Button
var sort_bag_button:Button
var binding_row:GridContainer
var tabs:HBoxContainer
var detail_scroll:ScrollContainer
var pending: Callable
var battery_id := ""
var detail_label: Label
var detail_id := ""
var plugin_charge_rows: Array = []
var warehouse_page := 0
var reference_ui:Dictionary={}
var grid_surfaces:Array[Control]=[]
var grid_hscroll:Array[HScrollBar]=[]
var grid_vscroll:Array[VScrollBar]=[]
const ReferenceLayout=preload("res://scripts/ui/inventory/extraction_layout.gd")
var gesture: Dictionary = {}
const DRAG_THRESHOLD := 6.0
var dialog: ConfirmationDialog
var hover_id := ""
var tip_layer:CanvasLayer
var tip:PanelContainer
var tip_text:Label
var transition:Tween
var closing:=false
const CELL := 44
func bind_state(s: Dictionary, inv: InventoryService, exp: ExplorationService = null) -> void:
	state = s
	inventory = inv
	exploration = exp
func _ready() -> void:
	preload("res://scripts/ui/keeper_theme.gd").apply(self)
	position = Vector2(56,44)
	size = Vector2(1248,632)
	var root := Control.new()
	add_child(root)
	add_theme_stylebox_override("panel",StyleBoxEmpty.new())
	left_panel=Panel.new();left_panel.size=Vector2(620,632);left_panel.mouse_filter=Control.MOUSE_FILTER_IGNORE;root.add_child(left_panel)
	loot_panel=Panel.new();loot_panel.position=Vector2(628,64);loot_panel.mouse_filter=Control.MOUSE_FILTER_IGNORE;root.add_child(loot_panel)
	loot_take=button(loot_panel,"全部拾取",func():exploration.take_all(state,box_id);refresh())
	tabs = HBoxContainer.new()
	var heading:=Label.new();heading.text="背包与装备";heading.add_theme_font_size_override("font_size",preload("res://scripts/ui/keeper_theme.gd").FONT_TITLE);root.add_child(heading);heading.position=Vector2(24,24)
	heading.add_theme_font_override("font",preload("res://scripts/ui/keeper_theme.gd").pixel_font(12))
	root.add_child(tabs);tabs.position=Vector2(310,66)
	for location in ["bag","warehouse","equipment"]:
		tabs_by_source[location]=button(tabs,{"bag":"背包","warehouse":"仓库","equipment":"已装备"}[location],func():
			if location=="warehouse" and not at_base: return
			source=location; refresh())
		tabs_by_source[location].gui_input.connect(func(event):
			if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
				if location=="warehouse" and not at_base: return
				source=location
				refresh())
	button(tabs,"整理",func(): inventory.sort_container(state,source); refresh())
	button(tabs,"旋转选中 (R)",func(): rotated=not rotated; refresh())
	button(tabs,"翻页",func(): warehouse_page=12 if warehouse_page==0 else 0; refresh())
	button(tabs,"关闭 Esc",close_panel)
	info = Label.new()
	root.add_child(info);info.position=Vector2(302,350)
	weight_bar=ProgressBar.new();weight_bar.position=Vector2(302,376);weight_bar.show_percentage=false;weight_bar.size=Vector2(264,8);root.add_child(weight_bar)
	var fill:=StyleBoxFlat.new();fill.bg_color=preload("res://scripts/ui/keeper_theme.gd").ACCENT;weight_bar.add_theme_stylebox_override("fill",fill)
	feedback=Label.new()
	feedback.add_theme_color_override("font_color",preload("res://scripts/ui/keeper_theme.gd").WARNING)
	root.add_child(feedback);feedback.position=Vector2(16,570)
	var body := Control.new()
	root.add_child(body)
	for line_rect in [Rect2(16,64,584,1),Rect2(16,106,240,1),Rect2(302,106,290,1),Rect2(16,480,584,1)]:
		var line:=ColorRect.new();line.position=line_rect.position;line.size=line_rect.size;line.color=Color("4b504b");line.mouse_filter=Control.MOUSE_FILTER_IGNORE;root.add_child(line)
		if line_rect.position.y==480:footer_line=line
	var close_button:=button(root,"关闭",close_panel)
	close_button.position=Vector2(524,20);close_button.size=Vector2(80,48)
	sort_bag_button=button(root,"整理背包",func():inventory.sort_container(state,"bag");refresh())
	sort_warehouse_button=button(loot_panel,"整理仓库",func():if at_base:inventory.sort_container(state,"warehouse");refresh())
	for compact in [sort_bag_button,sort_warehouse_button,loot_take]:preload("res://scripts/ui/keeper_theme.gd").compact_button(compact)
	sort_bag_button.position=Vector2(476,76);sort_bag_button.size=Vector2(128,44)
	for tab in tabs.get_children():
		if tab is Button:preload("res://scripts/ui/keeper_theme.gd").compact_button(tab)
	for data in [["装备",Vector2(16,76)],["额外装备 / 4个通用槽",Vector2(16,450)],["双击转移 / 拖动放置 / R旋转",Vector2(302,392)]]:
		var caption:=Label.new();caption.text=data[0];caption.position=data[1];caption.add_theme_color_override("font_color",preload("res://scripts/ui/keeper_theme.gd").MUTED);root.add_child(caption)
		caption.add_theme_font_size_override("font_size",preload("res://scripts/ui/keeper_theme.gd").FONT_SECTION if data[0]=="装备" else preload("res://scripts/ui/keeper_theme.gd").FONT_CAPTION)
		if data[0]=="装备":caption.add_theme_color_override("font_color",preload("res://scripts/ui/keeper_theme.gd").TEXT)
		if data[0].begins_with("双击"):usage_caption=caption
	grid = Control.new()
	grid.position=Vector2(302,94);grid.size=Vector2(934,432)
	body.add_child(grid)


	listing = VBoxContainer.new()
	detail_scroll=ScrollContainer.new();detail_scroll.position=Vector2(302,458);detail_scroll.size=Vector2(302,100);detail_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;body.add_child(detail_scroll);detail_scroll.add_child(listing)
	equipment_layout=Control.new();equipment_layout.position=Vector2(16,122);body.add_child(equipment_layout)
	listing.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var quick := GridContainer.new();quick.columns=3;binding_row=quick
	root.add_child(quick);quick.position=Vector2(302,570)
	for n in range(6):
		button(quick,str(n+1),func():
			if accessible_item(selected): state.player.quick[n] = state.items[selected].definition_id
			refresh())
	dialog = ConfirmationDialog.new()
	preload("res://scripts/ui/keeper_theme.gd").configure_dialog(dialog)
	dialog.theme=preload("res://scripts/ui/keeper_theme.gd").get_theme()
	add_child(dialog)
	dialog.confirmed.connect(func(): pending.call(); refresh())
	setup_pixel_tip()
	ReferenceLayout.setup(self)
	hide()
func button(parent: Node, text: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size.y=preload("res://scripts/ui/keeper_theme.gd").BUTTON_HEIGHT
	if parent==listing:
		b.clip_text=true
		b.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		b.tooltip_text=text
	parent.add_child(b)
	b.pressed.connect(callback)
	b.button_down.connect(func(): held_button=b)
	b.button_up.connect(func():
		if held_button==b: held_button=null
		flush_refresh.call_deferred())
	return b
func flush_refresh() -> void:
	if refresh_pending and held_button==null:
		refresh_pending=false
		if visible: refresh()
func open_panel(id: String = "") -> void:
	gesture.clear()
	if not at_base and source=="warehouse": source="bag"
	if not accessible_item(selected): selected=""
	box_id=id
	if not id.is_empty() and exploration != null: exploration.open_search(state,id)
	closing=false
	if transition:transition.kill()
	show()
	modulate.a=0.0
	transition=create_tween();transition.tween_property(self,"modulate:a",1.0,0.09)
	movement_lock_changed.emit(not id.is_empty())
	refresh()
func close_panel() -> void:
	held_button=null
	refresh_pending=false
	selector_callback=Callable()
	selector_filter=Callable()
	external_container=""
	gesture.clear()
	if exploration != null and not box_id.is_empty(): exploration.close_search(state)
	box_id=""
	closing=true
	if transition:transition.kill()
	if is_instance_valid(tip):tip.hide()
	transition=create_tween();transition.tween_property(self,"modulate:a",0.0,0.08)
	transition.tween_callback(func():hide();closing=false)
	movement_lock_changed.emit(false)
# Button.button_up may not fire when an equipment drag releases outside it.
# Settle after GUI dispatch so the drop/click transaction runs before refresh.
func finish_pointer_release() -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):return
	held_button=null
	suppress_slot_click=false
	flush_refresh()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and not event.pressed:
		finish_pointer_release.call_deferred()
	if not visible or closing: return
	if event.is_action_pressed("ui_cancel"):
		close_panel()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_R:
		rotated=not rotated
		grid.queue_redraw()
		get_viewport().set_input_as_handled()
func _process(dt: float) -> void:
	fit_viewport()
	update_pixel_tip()
	if visible:
		update_charge_details()
		for surface in grid_surfaces:surface.queue_redraw()
	if visible and not box_id.is_empty() and exploration != null:
		var revealed_before: int = exploration.box(state,box_id).get("revealed",[]).size()
		exploration.tick_search(state,dt,get_tree().paused)
		if exploration.box(state,box_id).get("revealed",[]).size() != revealed_before: refresh()
		grid.queue_redraw()

# Mutate existing presentation nodes only. Charging must not replace a button
# under a held pointer or disrupt focus, drag state, or selection callbacks.
func update_charge_details() -> void:
	if is_instance_valid(detail_label) and accessible_item(detail_id):
		var item: Dictionary = state.items[detail_id]
		detail_label.text = "%s\n品质 %s   耐久 %s\n电量 %s / %s" % [display_name(item.id),item.quality,item.durability,item.energy,item.capacity]
	for row: Dictionary in plugin_charge_rows:
		if not is_instance_valid(row.label): continue
		var valid: bool = selected==row.parent and accessible_item(row.parent) and ChargingService.manual_target_allowed(state,row.id,row.parent,inventory.definitions)
		if valid:
			var plugin: Dictionary = state.items[row.id]
			row.label.text="已装%s [%s] 电量%.1f/%.1f" % [display_name(row.id),row.id,plugin.energy,plugin.capacity]
		else:
			row.label.text="已装物品已不可充电"
		if is_instance_valid(row.button):
			row.button.disabled=not valid or battery_id!=row.battery or not ChargingService.manual_battery_allowed(state,row.battery) or state.items[row.id].energy>=state.items[row.id].capacity

func refresh() -> void:
	if info == null or state.is_empty(): return
	if is_instance_valid(held_button):
		refresh_pending=true
		grid.queue_redraw()
		return
	var counts: Array = []
	for n in range(6): counts.append(str(n+1)+":"+str(inventory.quick_count(state,n)))
	info.add_theme_color_override("font_color",preload("res://scripts/ui/keeper_theme.gd").WARNING if inventory.weight(state,"bag") > state.containers.bag.maximum_weight * 0.8 else preload("res://scripts/ui/keeper_theme.gd").TEXT)
	info.text = "负重  %.1f / %.1f kg" % [inventory.weight(state,"bag"),state.containers.bag.maximum_weight]
	tabs.visible=selector_callback.is_valid()
	for child in tabs.get_children():child.visible=child in tabs_by_source.values() or (child is Button and child.text=="翻页" and source=="warehouse" and int(state.containers.warehouse.width)>12)
	tabs.position=Vector2(302,76)
	binding_row.visible=not selected.is_empty()
	weight_bar.max_value=state.containers.bag.maximum_weight;weight_bar.value=inventory.weight(state,"bag");weight_bar.size=Vector2(264,8)
	detail_scroll.visible=not selected.is_empty() or selector_callback.is_valid()
	sort_bag_button.visible=not selector_callback.is_valid()
	sort_warehouse_button.visible=at_base and box_id.is_empty()
	for location in tabs_by_source: tabs_by_source[location].visible=location!="warehouse" or at_base
	detail_label=null
	detail_id=""
	plugin_charge_rows.clear()
	for child in listing.get_children():
		if child not in slot_buttons.values(): listing.remove_child(child); child.queue_free()
	for slot: String in state.player.equipment:
		var id: String = state.player.equipment[slot]
		if slot_buttons.has(slot):
			slot_buttons[slot].text=slot_buttons[slot].text.split(":")[0]+": "+display_name(id)
			slot_buttons[slot].icon=preload('res://scripts/art/fortress_art.gd').item_icon(state.items[id].definition_id) if state.items.has(id) else null
			continue
		var slot_button := button(equipment_layout,{"weapon_1":"武器一","weapon_2":"武器二","weapon_3":"武器三","armor":"护甲","backpack":"背包","extra_1":"额外一","extra_2":"额外二","extra_3":"额外三","extra_4":"额外四"}[slot]+": "+display_name(id),func():
			if suppress_slot_click:
				suppress_slot_click=false
				return
			if selected!="" and not accessible_item(selected): return
			var result: Dictionary
			if selected != "" and accessible_item(selected) and state.items[selected].container_id in ["bag","warehouse","equipment"]: result = inventory.equip(state,selected,slot,false,at_base)
			else: result = inventory.unequip(state,slot,false,at_base)
			if result.get("confirmation_required",false):
				dialog.dialog_text="缩小背包将转移 %d 件物品。%s" % [result.get("overflow",[]).size(),"基地先放仓库，剩余放地面箱。" if at_base else "野外溢出物品直接放地面掉落箱。"]
				pending=func():
					if selected!="" and not accessible_item(selected): return
					if selected != "" and accessible_item(selected) and state.items[selected].container_id in ["bag","warehouse","equipment"]: inventory.equip(state,selected,slot,true,at_base)
					else: inventory.unequip(state,slot,true,at_base)
				dialog.popup_centered()
			refresh())
		slot_buttons[slot]=slot_button
		slot_button.icon=preload('res://scripts/art/fortress_art.gd').item_icon(state.items[id].definition_id) if state.items.has(id) else null
		slot_button.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
		slot_button.gui_input.connect(func(event):
			var current_id: String=state.player.equipment[slot]
			if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
				if event.pressed and accessible_item(current_id):
					selected=current_id
					rotated=state.items[current_id].rotated
					gesture={"id":current_id,"source":"equipment","cell":state.items[current_id].cell.duplicate(),"start":grid.get_global_transform().affine_inverse() * (slot_button.get_global_transform() * event.position),"dragging":false}
				elif not event.pressed and not gesture.is_empty():
					suppress_slot_click=(grid.get_global_transform().affine_inverse() * (slot_button.get_global_transform() * event.position)).distance_to(gesture.start)>=DRAG_THRESHOLD
					var copy: InputEventMouseButton=event.duplicate()
					copy.position=grid.get_global_transform().affine_inverse() * (slot_button.get_global_transform() * event.position)
					grid_input(copy))
	if selector_callback.is_valid(): button(listing,"确认选中物品",confirm_selection)
	if accessible_item(selected):
		var item: Dictionary = state.items[selected]
		var detail := Label.new()
		detail_label=detail
		detail_id=item.id
		detail.text = "%s\n品质 %s   耐久 %s\n电量 %s / %s" % [display_name(item.id),item.quality,item.durability,item.energy,item.capacity]
		listing.add_child(detail)
		if item.container_id == "bag" and item.get("is_battery",false):
			var supply_id: String = item.id
			button(listing,"选择此电池供电",func():
				if visible and selected==supply_id and ChargingService.manual_battery_allowed(state,supply_id): battery_id=supply_id
				refresh())
		var target_id: String = item.id
		var supply_id: String = battery_id
		if ChargingService.manual_battery_allowed(state,supply_id) and ChargingService.manual_target_allowed(state,target_id,"",inventory.definitions):
			button(listing,"使用"+display_name(battery_id)+"持续充电",func():
				if visible and selected==target_id and battery_id==supply_id and accessible_item(target_id) and ChargingService.manual_target_allowed(state,target_id,"",inventory.definitions) and ChargingService.manual_battery_allowed(state,supply_id):
					charging_requested.emit(target_id,supply_id)
				refresh())
		for plugin_id: String in item.get("plugins",{}).values():
			if ChargingService.installed_charge_parent(state,plugin_id,inventory.definitions) != target_id: continue
			var plugin: Dictionary = state.items[plugin_id]
			var plugin_info := Label.new()
			plugin_info.text="已装%s [%s] 电量%.1f/%.1f" % [display_name(plugin_id),plugin_id,plugin.energy,plugin.capacity]
			listing.add_child(plugin_info)
			var row := {"id":plugin_id,"parent":target_id,"battery":supply_id,"label":plugin_info,"button":null}
			plugin_charge_rows.append(row)
			if not ChargingService.manual_battery_allowed(state,supply_id): continue
			var charge_button := button(listing,"为已装"+display_name(plugin_id)+"充电",func():
				if visible and selected==target_id and battery_id==supply_id and accessible_item(target_id) and ChargingService.manual_target_allowed(state,plugin_id,target_id,inventory.definitions) and ChargingService.manual_battery_allowed(state,supply_id):
					charging_requested.emit(plugin_id,supply_id)
				refresh())
			charge_button.disabled=plugin.energy>=plugin.capacity
			row.button=charge_button
	if not selected.is_empty():button(listing,"清除选择",func(): selected=""; refresh())
	loot_panel.visible=not remote_location().is_empty()
	loot_take.visible=not box_id.is_empty()
	if loot_panel.visible:
		var c:Dictionary=state.containers.get(remote_location(),{"width":6,"height":4})
		loot_panel.size=Vector2(maxi(280,mini(12,int(c.width))*48+24),mini(8,int(c.height))*48+(114 if remote_location()=="warehouse" else 82))
		loot_take.custom_minimum_size.y=preload("res://scripts/ui/keeper_theme.gd").COMPACT_HEIGHT
		loot_take.position=Vector2(loot_panel.size.x-144,16)
		loot_take.size=Vector2(128,preload("res://scripts/ui/keeper_theme.gd").COMPACT_HEIGHT)
		sort_warehouse_button.position=loot_take.position
		sort_warehouse_button.custom_minimum_size.y=preload("res://scripts/ui/keeper_theme.gd").COMPACT_HEIGHT
		sort_warehouse_button.size=loot_take.size
	layout_inventory_content()
	layout_inventory_content.call_deferred()
	arrange_equipment()
	grid.queue_redraw()
func display_name(id: String) -> String:
	if not state.items.has(id): return "空"
	var d: String = state.items[id].definition_id
	return {"rifle_basic":"步枪","medical_needle":"医疗针","battery_basic":"电池","backpack_small":"小背包","knife_basic":"短刀","armor_basic":"护甲","scrap":"废料","nightvision":"夜视镜","exoskeleton":"外骨骼","aim_assist":"辅助瞄准"}.get(d,inventory.definitions[d].get("display_name","物资"))

func remote_location() -> String:
	if selector_callback.is_valid():return ""
	if not external_container.is_empty(): return external_container
	if not box_id.is_empty() and exploration != null: return exploration.box(state,box_id).get("container_id","")
	return "warehouse" if at_base else ""

func entries() -> Array:
	return visible_items(source)

func visible_items(location: String) -> Array:
	if not accessible_location(location): return []
	var result := inventory.items_in(state,location)
	if selector_callback.is_valid() and selector_filter.is_valid(): result=result.filter(selector_filter)
	if location==external_container and external_filter.is_valid(): result=result.filter(external_filter)
	if not box_id.is_empty() and location == remote_location():
		var revealed: Array = exploration.box(state,box_id).get("revealed",[])
		result = result.filter(func(item: Dictionary): return item.id in revealed)
	return result

# Concealed loot exposes only footprint; input continues to use visible_items.
func displayed_items(location: String) -> Array:
	if not box_id.is_empty() and location == remote_location() and accessible_location(location):
		return inventory.items_in(state,location)
	return visible_items(location)

func concealed_item(id: String) -> bool:
	return not box_id.is_empty() and state.items.has(id) and state.items[id].container_id == remote_location() and not id in exploration.box(state,box_id).get("revealed",[])

func draw_concealed(rect: Rect2, searching: bool, paint:Control) -> void:
	paint.draw_rect(rect.grow(-2),Color("303634"))
	paint.draw_rect(rect.grow(-2),preload("res://scripts/ui/keeper_theme.gd").ACCENT if searching else Color("656c65"),false,1)
	var center := rect.get_center()
	if searching:
		var box: Dictionary = exploration.box(state,box_id)
		var progress := clampf(float(state.expedition.search.get("elapsed",0.0))/maxf(0.01,box.get("search_seconds",0.5)),0.0,1.0)
		paint.draw_arc(center,9,0,TAU,24,Color("656c65"),2)
		if progress>0: paint.draw_arc(center,9,-PI/2,-PI/2+TAU*progress,24,preload("res://scripts/ui/keeper_theme.gd").ACCENT,2)
	else:
		paint.draw_string(theme.default_font,center+Vector2(-5,6),"?",HORIZONTAL_ALIGNMENT_LEFT,16,preload("res://scripts/ui/keeper_theme.gd").FONT_BODY,preload("res://scripts/ui/keeper_theme.gd").MUTED)

func item_rect(item: Dictionary, location: String, right: bool) -> Rect2:
	var pos := Vector2(item.cell[0],item.cell[1])*cell_size(right)
	if location == "equipment":
		var index: int = visible_items(location).find(item)
		pos=Vector2((index%3)*100,int(index/3)*80)
		return Rect2(pos+grid_origin(right)-grid_offset(right),Vector2(92,72))
	return Rect2(pos+grid_origin(right)-grid_offset(right),Vector2(inventory.dimensions(item))*cell_size(right))

func draw_grid_side(right:bool,paint:Control) -> void:
	if state.is_empty():return
	paint.draw_set_transform(-grid_origin(right))
	var location: String = remote_location() if right else source
	if location.is_empty(): return
	var origin := grid_origin(right)-grid_offset(right)
	var c: Dictionary = state.containers.get(location,{"width":8,"height":8})
	for y in range(0 if location=="equipment" else maxi(1,int(c.height))):
		for x in range(maxi(1,int(c.width))):
			preload("res://scripts/ui/keeper_theme.gd").box("slot").draw(paint.get_canvas_item(),Rect2(origin+Vector2(x,y)*cell_size(right),Vector2.ONE*cell_size(right)).grow(-1))
	var search_started := false
	for item: Dictionary in displayed_items(location):
		var rect := item_rect(item,location,right)
		if concealed_item(item.id):
			draw_concealed(rect,not search_started,paint)
			search_started=true
			continue
		preload("res://scripts/ui/keeper_theme.gd").box(("hover" if item.id==hover_id else "slot_normal") if item.id!=selected else "slot_selected",4).draw(paint.get_canvas_item(),rect.grow(-2))
		var icon:Texture2D=preload('res://scripts/art/fortress_art.gd').item_icon(item.definition_id)
		if icon!=null:
			paint.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
			var extent:=Vector2(minf(48,rect.size.x-8),minf(40,rect.size.y-24))
			var icon_size:=Vector2(extent.x,minf(extent.y,extent.x*icon.get_height()/icon.get_width()))
			paint.draw_texture_rect(icon,Rect2(rect.position+Vector2((rect.size.x-icon_size.x)*.5,22),icon_size),false)

		var title:String=display_name(item.id)
		while title.length()>1 and theme.default_font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,20).x>rect.size.x-8:title=title.left(title.length()-2)+"…"
		paint.draw_string(theme.default_font,rect.position+Vector2(4,20),title,HORIZONTAL_ALIGNMENT_LEFT,rect.size.x-8,20,Color("c5cdcf"))
		var amount:=str(int(item.energy)) if item.get("is_battery",false) else (str(item.quantity) if item.quantity>1 else "")
		if not amount.is_empty():
			var tw:=theme.default_font.get_string_size(amount,HORIZONTAL_ALIGNMENT_LEFT,-1,20).x
			paint.draw_rect(Rect2(rect.end-Vector2(tw+6,24),Vector2(tw+4,22)),Color("171c23"))
			paint.draw_string(theme.default_font,rect.end-Vector2(tw+4,6),amount,HORIZONTAL_ALIGNMENT_LEFT,tw+2,20,preload("res://scripts/ui/keeper_theme.gd").TEXT)

	if not gesture.is_empty() and gesture.get("dragging",false) and accessible_item(gesture.id):
		var pointer:=grid.get_local_mouse_position()
		if Rect2(grid_origin(right),paint.size).has_point(pointer):
			var cell:=Vector2i((pointer-origin)/cell_size(right))
			var preview:Dictionary=state.items[gesture.id].duplicate(true);preview.rotated=rotated
			var valid:bool=inventory.fits(state,preview,location,cell)
			var bounds:=Rect2(origin+Vector2(cell)*cell_size(right),Vector2(inventory.dimensions(preview))*cell_size(right)).grow(-2)
			paint.draw_rect(bounds,Color(0.3,0.8,0.8,0.24) if valid else Color(0.9,0.2,0.2,0.3))
			paint.draw_rect(bounds,Color("64d7df") if valid else Color("df7378"),false,2)

func accessible_location(location: String) -> bool:
	if not external_container.is_empty() and location==external_container:
		return external_allowed() and (at_base or location!="warehouse")
	if location in ["bag","equipment"]: return true
	if location=="warehouse": return at_base
	return not location.is_empty() and not box_id.is_empty() and exploration!=null and location==remote_location() and state.expedition.get("search",{}).get("box_id","")==box_id

func accessible_item(id: String) -> bool:
	if not state.items.has(id): return false
	var location: String = state.items[id].container_id
	if not accessible_location(location): return false
	if selector_callback.is_valid() and selector_filter.is_valid() and not selector_filter.call(state.items[id]): return false
	if location==external_container and external_filter.is_valid() and not external_filter.call(state.items[id]): return false
	if not box_id.is_empty() and location==remote_location():
		return id in exploration.box(state,box_id).get("revealed",[])
	return true

# Automatic double-click transfer keeps stack merging and automatic placement.
# Explicit drag runs the entire move and requested cell on a private trial.
func fail_transfer(reason: String) -> bool:
	last_feedback=reason
	if feedback!=null:
		feedback.text=reason
		layout_inventory_content()
	return false

func transfer_item(id: String, destination: String, cell: Vector2i = Vector2i(-1,-1), explicit: bool = false, confirmed: bool = false) -> bool:
	last_feedback=""
	if feedback!=null: feedback.text=""
	if not accessible_item(id) or not accessible_location(destination) or destination=="equipment":
		return fail_transfer("无法转移：物品或目标容器已不可访问。")
	if destination==external_container and external_filter.is_valid() and not external_filter.call(state.items[id]):
		return fail_transfer("无法转移：该设施不接受此类物品。")
	var trial := state.duplicate(true)
	var needs_confirmation := false
	var overflow: Array = []
	var desired_rotation: bool = rotated
	if trial.items[id].container_id=="equipment":
		for slot in trial.player.equipment:
			if trial.player.equipment[slot]==id:
				var result:=inventory.unequip(trial,slot,confirmed,at_base)
				if not result.ok:
					if not result.get("confirmation_required",false):
						return fail_transfer("无法卸下：背包空间或承重不足。")
					needs_confirmation=true
					overflow=result.get("overflow",[]).duplicate()
					# Preview the complete confirmed operation on the private trial.
					# No inventory or equipment mutation escapes before user consent.
					if not inventory.unequip(trial,slot,true,at_base).ok:
						return fail_transfer("无法卸下：溢出物品无法安全安置。")
				break
	if explicit:
		var preview: Dictionary = trial.items[id].duplicate(true)
		preview.rotated=desired_rotation
		if cell.x<0 or cell.y<0 or not inventory.fits(trial,preview,destination,cell):
			return fail_transfer("无法放置：指定格子在缩容后被占用或超出边界。请另选空位；物品未移动。")
	var mover: InventoryService = inventory
	if explicit:
		var definitions: Dictionary = inventory.definitions.duplicate(true)
		var type: String = trial.items[id].definition_id
		if definitions[type].get("category","") in ["material","consumable"]:
			# Placement policy must not change whether an item has per-instance state.
			definitions[type].suppress_stack_merge=true
		mover=InventoryService.new(definitions)
	if not explicit and not box_id.is_empty() and trial.items[id].container_id==remote_location():
		if not exploration.pickup(trial,box_id,id):
			return fail_transfer("无法拾取：物品未揭示或背包空间/承重不足。")
	elif not mover.move(trial,id,destination).ok:
		return fail_transfer("无法转移：目标空间、承重或能源容量不足。")
	if explicit:
		if not trial.items.has(id) or not inventory.relocate(trial,id,cell,desired_rotation):
			return fail_transfer("无法放置：指定落点已失效，未改变任何物品。")
	if not box_id.is_empty() and destination==remote_location():
		var revealed: Array = exploration.box(trial,box_id).revealed
		if not id in revealed: revealed.append(id)
	if needs_confirmation and not confirmed:
		dialog.dialog_text="落点可用，卸下背包将转移 %d 件溢出物品。%s" % [overflow.size(),"优先仓库，剩余地面箱。" if at_base else "野外直接地面箱。"]
		pending=func():
			rotated=desired_rotation
			transfer_item(id,destination,cell,explicit,true)
		dialog.popup_centered()
		return false
	inventory.commit(state,trial)
	return true
func grid_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if not gesture.is_empty() and event.position.distance_to(gesture.start) >= DRAG_THRESHOLD:
			gesture.dragging=true
		grid.queue_redraw()
	if not event is InputEventMouseButton or event.button_index != MOUSE_BUTTON_LEFT: return
	grid.accept_event()
	var right: bool = not remote_location().is_empty() and Rect2(grid_origin(true),grid_surfaces[1].size).has_point(event.position)
	var location: String = remote_location() if right else source
	if event.pressed:
		if not Rect2(grid_origin(right),grid_surfaces[int(right)].size).has_point(event.position):return
		gesture.clear()
		if not accessible_location(location): return
		for item: Dictionary in visible_items(location):
			if item_rect(item,location,right).has_point(event.position):
				selected=item.id
				rotated=item.rotated
				item_selected.emit(selected)
				if event.double_click:
					# This press owns the only transaction. The matching release
					# has no gesture and can never turn into a drag.
					if location != "equipment": transfer_item(selected,"bag" if right else remote_location())
				else:
					gesture={"id":item.id,"source":location,"cell":item.cell.duplicate(),"start":event.position,"dragging":false}
				break
	else:
		var ended: Dictionary = gesture.duplicate(true)
		gesture.clear()
		if ended.is_empty(): return
		var id: String = ended.id
		if accessible_item(id):
			for slot in slot_buttons:
				if slot_buttons[slot].get_global_rect().has_point(grid.get_global_transform() * event.position):
					if ended.source!="equipment": drop_equipment(id,slot)
					return
		var moved: bool = ended.dragging or event.position.distance_to(ended.start)>=DRAG_THRESHOLD
		if not Rect2(grid_origin(right),grid_surfaces[int(right)].size).has_point(event.position):return
		if not moved or not accessible_location(location) or location=="equipment" or not accessible_item(id): return
		# A changed/consumed item or a tab/location switch cancels stale drags.
		if state.items[id].container_id != ended.source or state.items[id].cell != ended.cell: return
		if not Rect2(Vector2.ZERO,grid.size).has_point(event.position): return
		var cell := Vector2i((event.position-grid_origin(right)+grid_offset(right))/cell_size(right))

		if state.items[id].container_id != location:
			transfer_item(id,location,cell,true)
		else:
			inventory.relocate(state,id,cell,rotated)
	refresh()

func external_allowed() -> bool:
	return not external_container.is_empty() and state.containers.has(external_container) and external_permission.is_valid() and bool(external_permission.call())

func bind_external_container(id: String, permission: Callable, filter: Callable = Callable()) -> void:
	external_container=id
	external_permission=permission
	external_filter=filter
	gesture.clear()
	selected=""

func open_selector(filter: Callable, callback: Callable, base_permission: bool) -> void:
	selector_filter=filter
	selector_callback=callback
	at_base=base_permission
	source="equipment"
	open_panel()

func confirm_selection() -> void:
	if not selector_callback.is_valid() or not accessible_item(selected): return
	var item: Dictionary=state.items[selected]
	if not item.container_id in ["equipment","bag","warehouse"]: return
	if selector_filter.is_valid() and not selector_filter.call(item): return
	var callback:=selector_callback
	selector_callback=Callable()
	close_panel()
	callback.call(selected)


func drop_equipment(id: String, slot: String, confirmed: bool = false) -> void:
	if not accessible_item(id): return
	var result:=inventory.equip(state,id,slot,confirmed,at_base)
	if result.get("confirmation_required",false):
		dialog.dialog_text="装备背包将溢出物品。"+("优先仓库，剩余地面箱。" if at_base else "野外直接地面箱。")
		pending=func(): drop_equipment(id,slot,true)
		dialog.popup_centered()
	refresh()



func cell_size(_right:bool)->int:
	return 64
func grid_origin(right:bool)->Vector2:
	return grid_surfaces[int(right)].position
func grid_offset(right:bool)->Vector2:
	return Vector2(grid_hscroll[int(right)].value,grid_vscroll[int(right)].value)
func layout_inventory_content():
	ReferenceLayout.arrange(self)
func arrange_equipment():
	ReferenceLayout.equipment(self)

func fit_viewport():
	var vp:=get_viewport_rect().size
	var desired:=preload("res://scripts/ui/pixel_layout.gd").ui_scale(vp)
	var inherited:=get_canvas_transform().get_scale().x
	scale=Vector2.ONE*desired/inherited
	position=Vector2((vp.x/inherited-size.x*scale.x)*0.5,16*desired/inherited)

func setup_pixel_tip():
	tip_layer=CanvasLayer.new();tip_layer.layer=60;add_child(tip_layer)
	tip=PanelContainer.new();tip.mouse_filter=Control.MOUSE_FILTER_IGNORE;tip_layer.add_child(tip)
	preload("res://scripts/ui/keeper_theme.gd").apply(tip)
	tip_text=Label.new();tip_text.mouse_filter=Control.MOUSE_FILTER_IGNORE;tip.add_child(tip_text);tip.hide()
	tip_text.add_theme_font_override("font",preload("res://scripts/ui/keeper_theme.gd").pixel_font(12))
	tip_text.add_theme_font_size_override("font_size",24)

func update_pixel_tip():
	if tip==null:return
	if not visible or closing:tip.hide();return
	var hit:=""
	var point:=grid.get_local_mouse_position()
	for right in [false,true]:
		var location:String=remote_location() if right else source
		if not Rect2(grid_origin(right),grid_surfaces[int(right)].size).has_point(point):continue
		for item:Dictionary in visible_items(location):
			if item_rect(item,location,right).has_point(point):hit=item.id;break
	for slot in slot_buttons:
		var b:Button=slot_buttons[slot]
		if Rect2(Vector2.ZERO,b.size).has_point(b.get_local_mouse_position()):hit=state.player.equipment[slot]
	if hover_id!=hit:hover_id=hit;grid.queue_redraw()
	if hit.is_empty() or not accessible_item(hit) or not gesture.is_empty():tip.hide();return
	var item:Dictionary=state.items[hit]
	tip_text.text=display_name(hit)+"\n────────────\n品质  %s   耐久  %s"%[item.quality,item.durability]
	if item.get("capacity",0)>0:tip_text.text+="\n能量  %.0f / %.0f"%[item.energy,item.capacity]
	if item.quantity>1:tip_text.text+="\n数量  %d"%item.quantity
	tip_text.text+="\n\n拖动放置  ·  双击转移"
	var factor:=preload("res://scripts/ui/pixel_layout.gd").ui_scale(get_viewport_rect().size)
	tip_layer.transform=Transform2D(Vector2(factor,0),Vector2(0,factor),Vector2.ZERO)
	tip.size=tip.get_combined_minimum_size()
	var pointer:=get_viewport().get_mouse_position()/factor
	var mouse:=pointer+Vector2(18,18)
	var limit:=get_viewport_rect().size/factor-tip.size-Vector2(12,12)
	if mouse.x>limit.x:mouse.x=pointer.x-tip.size.x-18
	if mouse.y>limit.y:mouse.y=pointer.y-tip.size.y-18
	tip.position=mouse.clamp(Vector2(12,12),limit);tip.show()
