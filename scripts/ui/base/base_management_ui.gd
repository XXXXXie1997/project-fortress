class_name BaseManagementUI
extends CanvasLayer
signal world_changed
signal placement_requested(type: String, moving_id: String)
var state: Dictionary
var services: Dictionary
var inventory_panel: InventoryPanel
var root_panel: PanelContainer
var content: VBoxContainer
var scroll: ScrollContainer
var message: Label
var resource_status: Label
var inventory_energy: Label
var presentation_obscured := false
var feedback_obscured := false
var activity_label: Label
var activity_id := ""
var activity_kind := ""
var selected_building := ""
var sell_basket: Array = []
var buy_basket: Array = []
var target := "warehouse"
var confirmation: ConfirmationDialog
var pending: Callable
func bind_context(s: Dictionary, context: Dictionary) -> void:
	state=s
	services=context
	# Catalog augmentation belongs to runtime composition, not a second inventory.
	for file in ["crops","trade","equipment_recipes"]:
		var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/"+file+".json"))
		services.inventory.definitions.merge(data.get("item_definitions",{}))
func _ready() -> void:
	root_panel=PanelContainer.new()
	var background:=StyleBoxFlat.new();background.bg_color=Color("#1d2b32");root_panel.add_theme_stylebox_override("panel",background)
	root_panel.position=Vector2(18,80)
	root_panel.size=Vector2(390,570)
	add_child(root_panel)
	scroll=ScrollContainer.new();scroll.custom_minimum_size=Vector2(390,570);root_panel.add_child(scroll)
	content=VBoxContainer.new();content.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(content)
	message=Label.new();message.position=Vector2(400,8);message.size=Vector2(380,60);message.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;add_child(message)
	inventory_panel=InventoryPanel.new();inventory_panel.bind_state(state,services.inventory);add_child(inventory_panel)
	inventory_energy=Label.new()
	inventory_energy.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var inventory_content:Node=inventory_panel.get_child(0)
	inventory_content.add_child(inventory_energy);inventory_content.move_child(inventory_energy,1)
	resource_status=Label.new();resource_status.position=Vector2(800,12);add_child(resource_status)
	preload("res://scripts/ui/hud_backdrop.gd").attach(resource_status)
	confirmation=ConfirmationDialog.new();add_child(confirmation)
	confirmation.canceled.connect(func():pending=Callable())
	confirmation.confirmed.connect(func():
		var action:=pending
		pending=Callable()
		if action.is_valid():action.call())
	show_buildings()
func button(label: String, callback: Callable, parent: Node = null) -> Button:
	var b:=Button.new();b.text=label
	(parent if parent!=null else content).add_child(b);b.pressed.connect(callback);return b
func clear(title: String) -> void:
	activity_label=null
	activity_id=""
	activity_kind=""
	scroll.set_deferred("scroll_vertical",0)
	scroll.custom_minimum_size=Vector2(390,570)
	root_panel.size=Vector2(390,570)
	for child in content.get_children():content.remove_child(child);child.queue_free()
	var label:=Label.new();label.text=title;content.add_child(label)
	button("关闭面板 · 继续鼠标施工",func():root_panel.hide())
func report(ok: bool, success: String, failure: String = "操作被拒绝：请检查阶段、设施状态、材料及容量。") -> void:
	message.text=success if ok else failure
	if ok and services.has("farming"): services.farming.collect_ready(state)
	if ok:world_changed.emit()
func show_buildings() -> void:
	root_panel.show();clear("基地建设")
	for type: String in ["generator","turret","farm"]:
		button({"generator":"建造发电厂","turret":"建造炮塔","farm":"开垦农田"}[type],func():placement_requested.emit(type,"");root_panel.hide())
	button("扩建区域 / 居民位",func():report(services.building.expand(state),"扩建完成"))
	button("打开仓库与装备",func():inventory_panel.open_panel())
	var storage:=Label.new();storage.text="仓库等级 %d · 能源 %.0f / %.0f
格子 %d × %d" % [state.base.get("station_level",1),state.base.energy_store.energy,state.base.energy_store.capacity,state.containers.warehouse.width,state.containers.warehouse.height];content.add_child(storage)
func inspect(id: String) -> void:
	if not state.base.buildings.has(id):return
	selected_building=id;root_panel.show()
	var b: Dictionary=state.base.buildings[id]
	clear("设施：%s  等级%s
耐久 %.0f / %.0f" % [name_for(b.type),b.level,b.durability,b.maximum])
	button("移动（免费）",func():placement_requested.emit(b.type,id);root_panel.hide())
	button("维修 / 原位重建",func():report(services.building.repair(state,id),"设施修复完成");inspect(id))
	button("升级",func():report(upgrade_building(id),"设施升级完成");inspect(id))
	button("拆除并返还材料",func():report(services.building.demolish(state,id),"拆除完成","无法拆除：预置设施、未清订单/作物或退款空间不足。");show_buildings())
	if b.type=="workstation":
		button("制作与订单",func():show_production(id))
		button("维修 / 强化 / 拆解 / 插件",func():show_workstation(id))
	if b.type=="farm":button("农业批次",func():show_farm(id))
	if b.type=="trade":button("进入双篮交易",show_trade)
	if b.type=="warehouse":button("仓库 / 能源 / 装备",func():inventory_panel.open_panel())
	button("返回建设",show_buildings)
func name_for(type: String) -> String:
	return {"generator":"发电厂","turret":"炮塔","farm":"农田","warehouse":"仓库能源站","technology":"科技终端","quest":"任务终端","workstation":"工作站","trade":"贸易站"}.get(type,"设施")
func show_production(id: String) -> void:
	clear("工作站 · 阶段生产")
	var quantity:=SpinBox.new();quantity.min_value=1;quantity.max_value=99;content.add_child(quantity)
	for recipe: String in services.production.recipes:
		var r: Dictionary=services.production.recipes[recipe]
		var recipe_button:=button("制作 "+definition_name(r.output.keys()[0])+"\n每份材料："+cost_text(r.cost)+"\n每份能源："+str(r.energy),func():report(submit_order(id,recipe,int(quantity.value)),"已预付并下单",order_block_reason(id,recipe,int(quantity.value)));show_production(id))
		recipe_button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	activity_id=id;activity_kind="production"
	activity_label=Label.new();activity_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	content.add_child(activity_label)
	activity_label.text=production_status(id)
	button("取消订单 · 退还未产部分",func():report(services.production.cancel(state,id),"已取消并退未产成本",cancel_block_reason(id));show_production(id))
	button("查看已产成品（真实仓库）",func():
		var products:Array=[]
		for r: Dictionary in services.production.recipes.values():products.append_array(r.output.keys())
		load("res://scripts/ui/inventory/consumer_adapters.gd").production(inventory_panel,products))
	button("返回设施",func():inspect(id))
func show_farm(id: String) -> void:
	clear("农田 · 独立批次")
	for crop: String in services.farming.crops:
		var c: Dictionary=services.farming.crops[crop]
		button("种植 "+("催化作物" if crop=="catalyst" else "材料作物")+" 材料"+cost_text(c.cost),func():report(services.farming.plant(state,id,crop),"已种植",plant_block_reason(id,crop));show_farm(id))
	activity_id=id;activity_kind="farm"
	activity_label=Label.new();activity_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	content.add_child(activity_label)
	activity_label.text=farm_status(id)
	button("返回设施",func():inspect(id))
func select_item(filter: Callable, callback: Callable) -> void:
	inventory_panel.open_selector(filter,callback,true)
func show_workstation(id: String) -> void:
	clear("工作站 · 选择准确实例")
	for action: String in ["repair","dismantle"]:
		button({"repair":"维修指定装备","dismantle":"拆解指定物品"}[action],func():
			select_item(func(i):return true,func(item_id):
				pending=func():report(services.workstation.modify(state,id,item_id,action,"",true),"操作完成")
				var item:Dictionary=state.items[item_id]
				var maximum:float=services.inventory.definitions[item.definition_id].get("durability",0)
				var amount:int=maxi(1,ceili(services.workstation.config.repair_scrap*(1.0-float(item.durability)/maximum))) if maximum>0 else 0
				confirmation.dialog_text="确认"+("维修" if action=="repair" else "拆解")+"："+inventory_panel.display_name(item_id)+"\n"+("消耗废料×"+str(amount) if action=="repair" else "返还废料×"+str(services.workstation.config.dismantle_scrap))+"；背包可能溢出。"
				confirmation.popup_centered()))
	button("强化 / 升级",func():
		select_item(func(i):return services.workstation.config.tiers.has(i.definition_id),func(item_id):
			clear("选择目标等级")
			var old: Dictionary=services.workstation.config.tiers[state.items[item_id].definition_id]
			for target_id: String in services.workstation.config.tiers:
				var tier: Dictionary=services.workstation.config.tiers[target_id]
				if tier.family==old.family and int(tier.level)==int(old.level)+1:
					button("升级 · 本次材料"+tier_difference(old,tier)+" 能源"+str(float(tier.energy)-float(old.energy)),func():report(services.workstation.modify(state,id,item_id,"upgrade",target_id),"升级完成，保留电量与插件");show_workstation(id))))
	button("装入插件",func():
		select_item(func(i):return services.inventory.definitions[i.definition_id].category=="ranged",func(weapon_id):
			select_item(func(i):return services.inventory.definitions[i.definition_id].category=="plugin",func(plugin_id):report(services.workstation.modify(state,id,weapon_id,"install",plugin_id),"插件已安装"))))
	button("卸下插件",func():
		select_item(func(i):return not i.plugins.is_empty(),func(weapon_id):
			clear("选择插件槽")
			for slot: String in state.items[weapon_id].plugins:button("卸下 "+slot,func():report(services.workstation.modify(state,id,weapon_id,"uninstall",slot),"已卸回仓库"))))
	button("返回设施",func():inspect(id))
func show_trade() -> void:
	clear("贸易 · 双方放入交易篮后统一结算")
	scroll.custom_minimum_size=Vector2(1050,570);root_panel.size=Vector2(1050,570)
	var columns:=HBoxContainer.new();content.add_child(columns)
	var net:=0
	for side in ["sell","buy"]:
		var half:=VBoxContainer.new();half.custom_minimum_size.x=510;columns.add_child(half)
		var header:=Label.new();header.text="我方 · 出售" if side=="sell" else "商人 · 购买 / 当日回购";half.add_child(header)
		var pair:=HBoxContainer.new();half.add_child(pair)
		var available:=VBoxContainer.new();available.custom_minimum_size.x=245;pair.add_child(available)
		var basket_view:=VBoxContainer.new();basket_view.custom_minimum_size.x=245;pair.add_child(basket_view)
		var label:=Label.new();label.text="可选物品（点击放入）";available.add_child(label)
		var basket_title:=Label.new();basket_title.text="交易篮（点击撤回）";basket_view.add_child(basket_title)
		var locations:Array=["bag","warehouse","equipment"] if side=="sell" else ["shop","buyback"]
		var basket:Array=sell_basket if side=="sell" else buy_basket
		for location:String in locations:
			for item:Dictionary in services.inventory.items_in(state,location):
				var price:int=trade_price(item.id,side=="sell")
				var name:String=definition_name(item.definition_id)
				if name=="物资":name=inventory_panel.display_name(item.id)
				var label_text:String=name+" ×"+str(item.quantity)+" · "+str(price)+" 能源\n"+{"bag":"背包","warehouse":"仓库","equipment":"已装备","shop":"商店","buyback":"当日回购"}[location]+" · 电量 "+str(item.energy)+"/"+str(item.capacity)
				var dest:Node=basket_view if item.id in basket else available
				var row:=button(label_text,func():
					if item.id in basket:basket.erase(item.id)
					else:basket.append(item.id)
					show_trade(),dest)
				row.icon=preload('res://scripts/art/fortress_art.gd').item_icon(item.definition_id)
				row.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
				row.tooltip_text="品质%s · 耐久%s · 电量%s/%s\n%s" % [item.quality,item.durability,item.energy,item.capacity,"当日原价回购" if location=="buyback" else "价格不受电量影响"]
				if item.id in basket:net+=price if side=="sell" else -price
	var summary:=Label.new();summary.text="卖出 %d 件 / 买入 %d 件  净能源 %+d · 当前 %.0f / %.0f" % [sell_basket.size(),buy_basket.size(),net,state.base.energy_store.energy,state.base.energy_store.capacity];content.add_child(summary)
	button("送到："+("仓库" if target=="warehouse" else "背包"),func():target="bag" if target=="warehouse" else "warehouse";show_trade())
	button("统一成交",func():commit_trade(false))
	button("清空两篮",func():sell_basket.clear();buy_basket.clear();show_trade())
	button("返回建设",show_buildings)
func trade_price(id: String, selling: bool) -> int:
	if not selling and state.items[id].container_id=="buyback":return int(state.trade.buyback_prices[id])
	return services.trade.price(state,id,selling)
func commit_trade(confirmed: bool) -> void:
	var result:Dictionary=services.trade.transact(state,sell_basket,buy_basket,target,confirmed)
	if result.get("confirmation_required",false):
		confirmation.dialog_text="确认能源损失 %.0f / 可能背包溢出 %s" % [result.get("lost_energy",0),str(result.get("overflow",[]))]
		pending=func():commit_trade(true)
		confirmation.popup_centered();return
	report(result.ok,trade_result_text(result),"交易未提交：检查资源、设施、阶段或已变动商品。")
	if result.ok:sell_basket.clear();buy_basket.clear()
	show_trade()


func upgrade_building(id: String) -> bool:
	var b: Dictionary=state.base.buildings[id]
	if b.type=="warehouse":
		if not state.base.get("technology",{}).has("storage") or int(b.level)>=2:
			message.text="仓库升级需要对应科技许可。"
			return false
	return services.building.upgrade(state,id)


func definition_name(type: String) -> String:
	return preload("res://scripts/content/catalog.gd").item_name(type)

func cost_text(cost: Dictionary) -> String:
	var parts:PackedStringArray=[]
	for type:String in cost:parts.append(definition_name(type)+"×"+str(cost[type]))
	return " / ".join(parts)
func tier_difference(old: Dictionary, next: Dictionary) -> String:
	var costs:Dictionary={}
	for key:String in next.materials:
		var difference:int=int(next.materials[key])-int(old.materials.get(key,0))
		if difference>0:costs[key]=difference
	return cost_text(costs)
func submit_order(id: String, recipe: String, quantity: int) -> bool:
	if services.workstation.config.recipes.has(recipe):return services.workstation.craft(state,id,recipe,quantity)
	return services.production.order(state,id,recipe,quantity)


func _process(_dt: float) -> void:
	if resource_status==null:return
	if is_instance_valid(activity_label) and state.base.buildings.has(activity_id):
		activity_label.text=production_status(activity_id) if activity_kind=="production" else farm_status(activity_id)
	var station_active:=false
	for b:Dictionary in state.base.buildings.values():
		if b.type=="warehouse":station_active=b.durability>0
	resource_status.text="能源 %.1f / %.0f  仓库 %d×%d\n无线站：%s · 范围80 · %s" % [state.base.energy_store.energy,state.base.energy_store.capacity,state.containers.warehouse.width,state.containers.warehouse.height,"运行" if station_active else "废墟停用","正在充电" if state.player.get("combat",{}).get("charging",false) else "就近自动充电"]
	inventory_energy.text="基地能源 %.1f / %.0f · 仓库 %d×%d" % [state.base.energy_store.energy,state.base.energy_store.capacity,state.containers.warehouse.width,state.containers.warehouse.height]
	resource_status.visible=not presentation_obscured and not inventory_panel.visible
	message.visible=not presentation_obscured and not feedback_obscured and not inventory_panel.visible

func presentation_open() -> bool:
	return root_panel.visible or inventory_panel.visible or is_modal_open()

func is_modal_open() -> bool:
	return confirmation.visible or (inventory_panel!=null and inventory_panel.dialog.visible)


func trade_result_text(result: Dictionary) -> String:
	var text:="交易完成，净能源 %+d。" % int(result.get("actual_net",0))
	var counts:Dictionary={}
	for destination:Dictionary in result.get("destinations",{}).values():
		var location:String=destination.get("destination","")
		counts[location]=int(counts.get(location,0))+1
	for location:String in counts:
		text+=" %s收到%d件。" % [{"bag":"背包","warehouse":"仓库","ground":"地面箱"}.get(location,"容器"),counts[location]]
	if not result.get("overflow",[]).is_empty():text+=" 背包缩容溢出已按确认安置。"
	return text


func phase_note() -> String:
	return {"morning":"清晨准备","day":"白天","dusk":"黄昏准备","night":"夜间"}.get(state.phase,"当前阶段")

func action_restriction() -> String:
	if state.base.get("combat",false):return "战斗中：不能下单、取消或种植。"
	if not services.building.preparation(state):return phase_note()+"：仅清晨或黄昏准备阶段可下单、取消或种植。"
	return phase_note()+"：可安排生产与种植。"

func production_status(id: String) -> String:
	var b:Dictionary=state.base.buildings[id]
	var text:=action_restriction()
	if not b.has("order"):
		return text+"\n当前无进行中订单。"+("设施已成废墟，修复后可开工。" if not services.building.active(state,id) else "可选择配方与数量。")
	var order:Dictionary=b.order
	var recipe:Dictionary=services.production.recipes[order.recipe]
	text+="\n配方："+definition_name(recipe.output.keys()[0])+"\n已产 %d / 总量 %d · 剩余 %d\n每阶段最多 %d 份" % [order.produced,int(order.produced)+int(order.remaining),order.remaining,recipe.capacity]
	if not services.building.active(state,id):text+="\n废墟暂停：保留订单与预付款，修复后继续。"
	elif not services.inventory.exchange(state,{},recipe.output,false).ok:text+="\n满仓暂停：下一份成品无法入库，请先腾出仓库空间。"
	else:text+="\n正常待产：白天或夜间结束时结算，不随现实等待产出。"
	return text

func farm_status(id: String) -> String:
	var b:Dictionary=state.base.buildings[id]
	var batches:Array=b.get("batches",[])
	var text:=action_restriction()+"\n已种 %d / %d 批" % [batches.size(),services.building.config.types.farm.plots]
	if not services.building.active(state,id):text+="\n废墟暂停：作物批次保留，修复后继续生长和收获。"
	if batches.is_empty():text+="\n当前没有作物。"
	for index in range(batches.size()):
		var batch:Dictionary=batches[index]
		var crop:Dictionary=services.farming.crops[batch.crop]
		var ready:bool=not batch.harvest.is_empty()
		var state_text:="生长中，等待阶段结束"
		if ready:
			state_text="成熟待收"
			if not services.inventory.exchange(state,{},batch.harvest,false).ok:state_text+=" · 满仓留田，请腾出仓库空间"
			else:state_text+=" · 入库空间已具备"
		if not services.building.active(state,id):state_text+=" · 设施已毁暂停"
		text+="\n第%d批 %s\n阶段 %d / %d · 剩余 %d 阶段\n%s" % [index+1,"催化作物" if batch.crop=="catalyst" else "材料作物",batch.age,crop.stages,maxi(0,int(crop.stages)-int(batch.age)),state_text]
	return text

func missing_materials(cost:Dictionary,quantity:int=1) -> String:
	var missing:PackedStringArray=[]
	for type:String in cost:
		var shortage:int=int(cost[type])*quantity-services.inventory.count(state,type,"warehouse")
		if shortage>0:missing.append(definition_name(type)+"缺"+str(shortage))
	return "、".join(missing)

func order_block_reason(id:String,recipe_id:String,quantity:int) -> String:
	if not services.building.preparation(state):return action_restriction()
	if not services.building.active(state,id):return "工作站已成废墟，请先修复。"
	if state.base.buildings[id].has("order"):return "已有生产订单；每设施仅一单，请完成或取消当前订单。"
	var recipe:Dictionary=services.production.recipes[recipe_id]
	var missing:=missing_materials(recipe.cost,quantity)
	if not missing.is_empty():return "材料不足："+missing
	if state.base.energy_store.energy<float(recipe.energy)*quantity:return "基地能源不足：整单需 "+str(float(recipe.energy)*quantity)
	for tech in recipe.get("requires",[]):
		if not state.base.get("technology",{}).has(tech):return "尚未解锁该配方所需科技。"
	return "无法下单，请重新检查设施与配方资格。"

func plant_block_reason(id:String,crop_id:String) -> String:
	if not services.building.preparation(state):return action_restriction()
	if not services.building.active(state,id):return "农田已成废墟，请先修复。"
	if state.base.buildings[id].get("batches",[]).size()>=services.building.config.types.farm.plots:return "农田批次已满，请等待收获入库。"
	var missing:=missing_materials(services.farming.crops[crop_id].cost)
	return "种植材料不足："+missing if not missing.is_empty() else "当前不能种植，请重新检查农田状态。"

func cancel_block_reason(id:String) -> String:
	if not services.building.preparation(state):return action_restriction()
	var b:Dictionary=state.base.buildings[id]
	if not b.has("order"):return "当前没有可取消的订单。"
	var order:Dictionary=b.order
	var recipe:Dictionary=services.production.recipes[order.recipe]
	var refund_energy:float=float(recipe.energy)*int(order.remaining)
	if state.base.energy_store.energy+refund_energy>state.base.energy_store.capacity:return "无法取消：退回未产部分能源后将超过储能上限，请先腾出储能空间。"
	return "无法取消：仓库放不下未产部分退料，请先腾出物品空间。"
