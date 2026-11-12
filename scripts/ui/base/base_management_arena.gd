extends "res://scripts/base/actors/base_arena.gd"
var management: BaseManagementUI
var placing_type := ""
var moving_id := ""
var layout_signature := ""
var warehouse_signature := ""
func _ready():
	if not session_context.is_empty():
		await preload('res://scripts/game/session/world_mount.gd').mount(self,'management')
		return
	super._ready()
	while cycle==null or player.get_script()!=load("res://scripts/base/actors/base_player.gd"):await get_tree().physics_frame
	var catalog:Dictionary=preload("res://scripts/content/catalog.gd").equipment()
	var production:=ProductionService.new(building,preload("res://scripts/content/catalog.gd").recipes())
	var crop:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/crops.json"))
	var trade_catalog:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/trade.json"))
	management=BaseManagementUI.new()
	management.bind_context(state,{"inventory":inventory,"building":building,"production":production,"farming":FarmingService.new(building,crop.crops),"workstation":WorkstationService.new(production,catalog),"trade":TradeService.new(inventory,trade_catalog)})
	add_child(management)
	cycle.services.production=production
	cycle.services.farming=management.services.farming
	cycle.services.trade=management.services.trade
	management.world_changed.connect(sync_layout)
	management.placement_requested.connect(func(type,id):placing_type=type;moving_id=id)
	management.services.trade.refresh(state,1)
	bind_inventory_player()
	status_label.text="B 基地经营 · 点击设施查看 · 选择建造后点击菱形地格 · Esc取消"
func _input(event):
	if management==null or management.is_modal_open():return
	if event is InputEventKey and event.pressed and event.keycode==KEY_B:
		management.show_buildings();get_viewport().set_input_as_handled()
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE and not placing_type.is_empty():
		placing_type="";moving_id="";get_viewport().set_input_as_handled()
func _unhandled_input(event):
	if management==null or management.is_modal_open() or management.inventory_panel.visible:return
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
		hud.opened=true
		var cell:=grid.world_to_cell(get_canvas_transform().affine_inverse()*event.position)
		if not placing_type.is_empty():
			var size:Array=building.config.types[placing_type].size
			var polygon:=grid.rect_polygon(Rect2(Vector2(cell)*48,Vector2(size[0],size[1])*48))
			var visible_footprint:=true
			for point:Vector2 in polygon:
				if not get_viewport_rect().has_point(get_canvas_transform()*point):visible_footprint=false
			var ok:=false
			if visible_footprint:
				var bounds:Array=state.base.bounds
				var allowed:=Rect2i(bounds[0],bounds[1],bounds[2],bounds[3])
				if moving_id.is_empty():ok=not building.build(state,placing_type,[cell.x,cell.y],allowed).is_empty()
				else:ok=building.move(state,moving_id,[cell.x,cell.y],allowed)
			management.report(ok,"建设完成","无法施工：镜头外、占格/入口冲突、阶段或材料不足。")
			if ok:placing_type="";moving_id=""
		else:
			for id:String in state.base.buildings:
				var b:Dictionary=state.base.buildings[id]
				var size:Array=building.config.types[b.type].size
				if Rect2i(b.cell[0],b.cell[1],size[0],size[1]).has_point(cell):management.inspect(id);break
		get_viewport().set_input_as_handled()
func _process(dt):
	super._process(dt)
	if management==null:return
	hud.opened=management.root_panel.visible or management.inventory_panel.visible or not placing_type.is_empty()
	var stock_signature:=JSON.stringify(inventory.items_in(state,"warehouse"))
	if stock_signature!=warehouse_signature:
		management.services.farming.collect_ready(state)
		warehouse_signature=JSON.stringify(inventory.items_in(state,"warehouse"))
	sync_layout()
	queue_redraw()
func sync_layout() -> void:
	# Read authoritative state after every UI transaction; preserve capacitor/order data.
	var signature:=""
	for id:String in state.base.buildings:signature+=id+str(state.base.buildings[id].cell)
	if signature!=layout_signature:
		layout_signature=signature
		for actor in fixtures.duplicate():
			if actor.kind!="shield":actor.retire()
		for id:String in state.base.buildings:
			var b:Dictionary=state.base.buildings[id]
			var actor=load("res://scripts/base/actors/defense_fixture.gd").new()
			actor.arena=self;actor.id=id;actor.kind=b.type
			var size:Array=building.config.types[b.type].size
			actor.logical_rect=Rect2(Vector2(b.cell[0],b.cell[1])*48,Vector2(size[0],size[1])*48)
			actor.position=grid.logical_to_world(actor.logical_rect.get_center());add_child(actor);fixtures.append(actor)
			if b.type=="warehouse":station=actor.position
	queue_redraw()
func _draw():
	super._draw()
	if management==null or placing_type.is_empty():return
	var cell:=grid.world_to_cell(get_global_mouse_position())
	var size:Array=building.config.types[placing_type].size
	var poly:=grid.rect_polygon(Rect2(Vector2(cell)*48,Vector2(size[0],size[1])*48))
	var bounds:Array=state.base.bounds
	var valid:bool=building.valid_position(state,placing_type,[cell.x,cell.y],Rect2i(bounds[0],bounds[1],bounds[2],bounds[3]),moving_id)
	for point:Vector2 in poly:
		if not get_viewport_rect().has_point(get_canvas_transform()*point):valid=false
	draw_colored_polygon(poly,Color(0.3,0.9,0.6,0.4) if valid else Color(0.9,0.2,0.2,0.4))
	for zone:Array in building.config.forbidden:
		draw_colored_polygon(grid.rect_polygon(Rect2(zone[0]*48,zone[1]*48,zone[2]*48,zone[3]*48)),Color(1,0.4,0.1,0.35))


# Public composition hook; repeated calls must not duplicate dispatch.
func bind_inventory_player() -> void:
	if management==null or player==null:return
	var panel:InventoryPanel=management.inventory_panel
	var charge_callback:=Callable(self,"_on_inventory_charge")
	var movement_callback:=Callable(self,"_on_inventory_movement_lock")
	if not panel.charging_requested.is_connected(charge_callback):
		panel.charging_requested.connect(charge_callback)
	if not panel.movement_lock_changed.is_connected(movement_callback):
		panel.movement_lock_changed.connect(movement_callback)
	hud.inventory_panel=panel

func _on_inventory_charge(target_id:String,battery_id:String) -> void:
	if is_instance_valid(player):player.request_inventory_charge(target_id,battery_id)

func _on_inventory_movement_lock(locked:bool) -> void:
	if is_instance_valid(player):player.inventory_movement_locked=locked
