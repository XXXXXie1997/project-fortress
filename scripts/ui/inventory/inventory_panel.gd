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
var pending: Callable
var battery_id := ""
var warehouse_page := 0
var gesture: Dictionary = {}
const DRAG_THRESHOLD := 6.0
var dialog: ConfirmationDialog
const CELL := 44
func bind_state(s: Dictionary, inv: InventoryService, exp: ExplorationService = null) -> void:
	state = s
	inventory = inv
	exploration = exp
func _ready() -> void:
	var background := StyleBoxFlat.new()
	background.bg_color=Color("#1d2b32")
	add_theme_stylebox_override("panel",background)
	position = Vector2(30,30)
	size = Vector2(1220,660)
	var root := VBoxContainer.new()
	add_child(root)
	var tabs := HBoxContainer.new()
	root.add_child(tabs)
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
	button(tabs,"仓库左右分页",func(): warehouse_page=8 if warehouse_page==0 else 0; refresh())
	button(tabs,"关闭 Esc",close_panel)
	info = Label.new()
	root.add_child(info)
	feedback=Label.new()
	feedback.modulate=Color("#f0ba7a")
	root.add_child(feedback)
	var body := HBoxContainer.new()
	root.add_child(body)
	grid = Control.new()
	grid.custom_minimum_size = Vector2(800,440)
	body.add_child(grid)
	grid.draw.connect(draw_grid)
	grid.gui_input.connect(grid_input)
	listing = VBoxContainer.new()
	body.add_child(listing)
	var quick := HBoxContainer.new()
	root.add_child(quick)
	for n in range(6):
		button(quick,str(n+1)+" 绑定选中",func():
			if accessible_item(selected): state.player.quick[n] = state.items[selected].definition_id
			refresh())
	dialog = ConfirmationDialog.new()
	add_child(dialog)
	dialog.confirmed.connect(func(): pending.call(); refresh())
	hide()
func button(parent: Node, text: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = text
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
	show()
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
	hide()
	movement_lock_changed.emit(false)
func _input(event: InputEvent) -> void:
	if not visible: return
	if event.is_action_pressed("ui_cancel"):
		close_panel()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_R:
		rotated=not rotated
		grid.queue_redraw()
		get_viewport().set_input_as_handled()
func _process(dt: float) -> void:
	if visible and not box_id.is_empty() and exploration != null:
		var revealed_before: int = exploration.box(state,box_id).get("revealed",[]).size()
		exploration.tick_search(state,dt,get_tree().paused)
		if exploration.box(state,box_id).get("revealed",[]).size() != revealed_before: refresh()
func refresh() -> void:
	if info == null or state.is_empty(): return
	if is_instance_valid(held_button):
		refresh_pending=true
		grid.queue_redraw()
		return
	var counts: Array = []
	for n in range(6): counts.append(str(n+1)+":"+str(inventory.quick_count(state,n)))
	info.modulate = Color("#ef8d75") if inventory.weight(state,"bag") > state.containers.bag.maximum_weight * 0.8 else Color.WHITE
	info.text = "背包重量 %.1f / %.1f   快捷数量 %s\n选中 %s   R旋转，拖拽放置，双击转移" % [inventory.weight(state,"bag"),state.containers.bag.maximum_weight,"  ".join(counts),display_name(selected)]
	for location in tabs_by_source: tabs_by_source[location].visible=location!="warehouse" or at_base
	for child in listing.get_children():
		if child not in slot_buttons.values(): listing.remove_child(child); child.queue_free()
	for slot: String in state.player.equipment:
		var id: String = state.player.equipment[slot]
		if slot_buttons.has(slot):
			slot_buttons[slot].text=slot_buttons[slot].text.split(":")[0]+": "+display_name(id)
			slot_buttons[slot].icon=preload('res://scripts/art/fortress_art.gd').item_icon(state.items[id].definition_id) if state.items.has(id) else null
			continue
		var slot_button := button(listing,{"weapon_1":"武器一","weapon_2":"武器二","weapon_3":"武器三","armor":"护甲","backpack":"背包","extra_1":"额外一","extra_2":"额外二","extra_3":"额外三","extra_4":"额外四"}[slot]+": "+display_name(id),func():
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
					gesture={"id":current_id,"source":"equipment","cell":state.items[current_id].cell.duplicate(),"start":event.position+slot_button.global_position-grid.global_position,"dragging":false}
				elif not event.pressed and not gesture.is_empty():
					suppress_slot_click=(event.position+slot_button.global_position-grid.global_position).distance_to(gesture.start)>=DRAG_THRESHOLD
					var copy: InputEventMouseButton=event.duplicate()
					copy.position=event.position+slot_button.global_position-grid.global_position
					grid_input(copy))
	if selector_callback.is_valid(): button(listing,"确认选中物品",confirm_selection)
	if accessible_item(selected):
		var item: Dictionary = state.items[selected]
		var detail := Label.new()
		detail.text = "%s [%s]\n品质%s 耐久%s 电量%s/%s\n插件%s" % [display_name(item.id),item.id,item.quality,item.durability,item.energy,item.capacity,str(item.plugins)]
		listing.add_child(detail)
		if item.container_id == "bag" and item.get("is_battery",false):
			button(listing,"选择此电池供电",func(): battery_id=selected; refresh())
		if state.items.has(battery_id) and battery_id != selected:
			button(listing,"使用"+display_name(battery_id)+"持续充电",func():
				if accessible_item(selected) and accessible_item(battery_id) and state.items[battery_id].container_id=="bag":
					charging_requested.emit(selected,battery_id)
				refresh())
	button(listing,"清除选择（用于卸下）",func(): selected=""; refresh())
	if not box_id.is_empty() and exploration != null:
		var box: Dictionary = exploration.box(state,box_id)
		button(listing,"全部拾取已揭示",func(): exploration.take_all(state,box_id); refresh())
		for id: String in box.get("revealed",[]):
			if state.items.has(id) and state.items[id].container_id == box.container_id:
				button(listing,"拾取 "+display_name(id),func(): exploration.pickup(state,box_id,id); refresh())
	grid.queue_redraw()
func display_name(id: String) -> String:
	if not state.items.has(id): return "空"
	var d: String = state.items[id].definition_id
	return {"rifle_basic":"步枪","medical_needle":"医疗针","battery_basic":"电池","backpack_small":"小背包","knife_basic":"短刀","armor_basic":"护甲","scrap":"废料","nightvision":"夜视镜","exoskeleton":"外骨骼","aim_assist":"辅助瞄准"}.get(d,inventory.definitions[d].get("display_name","物资"))

func remote_location() -> String:
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

func item_rect(item: Dictionary, location: String, right: bool) -> Rect2:
	var pos := Vector2(item.cell[0]-(warehouse_page if location=="warehouse" else 0),item.cell[1])*CELL
	if location == "equipment" or (right and not box_id.is_empty()):
		var index: int = visible_items(location).find(item)
		pos=Vector2((index%3)*132,(index/3)*100)
	return Rect2(pos+Vector2(400 if right else 0,28),Vector2(inventory.dimensions(item))*CELL)

func draw_grid() -> void:
	if state.is_empty(): return
	for right in [false,true]:
		var location: String = remote_location() if right else source
		if location.is_empty(): continue
		var origin := Vector2(400 if right else 0,28)
		grid.draw_string(ThemeDB.fallback_font,origin-Vector2(0,8),"搜刮 · 已揭示物品" if right and not box_id.is_empty() else ("仓库" if location=="warehouse" else ("装备" if location=="equipment" else "随身背包")),HORIZONTAL_ALIGNMENT_LEFT,390,18)
		var c: Dictionary = state.containers.get(location,{"width":8,"height":8})
		for y in range(mini(8,maxi(1,int(c.height)))):
			for x in range(mini(8,maxi(1,int(c.width)))):
				grid.draw_rect(Rect2(origin+Vector2(x,y)*CELL,Vector2.ONE*CELL),Color("#405d68"),false)
		for item: Dictionary in visible_items(location):
			var rect := item_rect(item,location,right)
			if rect.position.x < origin.x or rect.position.x >= origin.x+352: continue
			grid.draw_rect(rect.grow(-2),Color("#526c66") if item.id != selected else Color("#ae854b"))
			var icon:Texture2D=preload('res://scripts/art/fortress_art.gd').item_icon(item.definition_id)
			if icon!=null:
				grid.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
				grid.draw_texture_rect(icon,Rect2(rect.position+Vector2((rect.size.x-20)*.5,15),Vector2(20,20)),false)
			grid.draw_string(ThemeDB.fallback_font,rect.position+Vector2(3,12),display_name(item.id),HORIZONTAL_ALIGNMENT_LEFT,rect.size.x-4,11)
			grid.draw_string(ThemeDB.fallback_font,rect.position+Vector2(3,42),"×%s" % item.quantity,HORIZONTAL_ALIGNMENT_LEFT,rect.size.x-4,10)
	if selected != "" and state.items.has(selected) and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var point := grid.get_local_mouse_position()
		var right: bool = point.x >= 400
		var location: String = remote_location() if right else source
		var cell := Vector2i((point-Vector2(400 if right else 0,28))/CELL)
		var preview: Dictionary = state.items[selected].duplicate(true)
		preview.rotated=rotated
		var valid := not location.is_empty() and location != "equipment" and inventory.fits(state,preview,location,cell)
		grid.draw_rect(Rect2(Vector2(cell)*CELL+Vector2(400 if right else 0,28),Vector2(inventory.dimensions(preview))*CELL),Color(0,1,0,0.3) if valid else Color(1,0,0,0.3))

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
	if feedback!=null: feedback.text=reason
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
	var right: bool = event.position.x >= 400
	var location: String = remote_location() if right else source
	if event.pressed:
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
				if slot_buttons[slot].get_global_rect().has_point(grid.global_position+event.position):
					if ended.source!="equipment": drop_equipment(id,slot)
					return
		var moved: bool = ended.dragging or event.position.distance_to(ended.start)>=DRAG_THRESHOLD
		if not moved or not accessible_location(location) or location=="equipment" or not accessible_item(id): return
		# A changed/consumed item or a tab/location switch cancels stale drags.
		if state.items[id].container_id != ended.source or state.items[id].cell != ended.cell: return
		if not Rect2(Vector2.ZERO,grid.size).has_point(event.position): return
		var cell := Vector2i((event.position-Vector2(400 if right else 0,28))/CELL)
		if location=="warehouse": cell.x+=warehouse_page
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


