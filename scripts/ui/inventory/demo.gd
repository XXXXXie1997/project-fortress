extends Node2D
func _ready() -> void:
	var s := WorldState.fresh()
	var inv := InventoryService.new(JSON.parse_string(FileAccess.get_file_as_string("res://data/items.json")).items)
	inv.setup(s)
	var pack := inv.spawn(s,"backpack_small","warehouse")
	inv.equip(s,pack.id,"backpack")
	inv.spawn(s,"rifle_basic","bag")
	inv.spawn(s,"medical_needle","bag",20)
	inv.spawn(s,"backpack_small","warehouse")
	var panel := InventoryPanel.new()
	panel.bind_state(s,inv)
	add_child(panel)
	panel.open_panel()

	await get_tree().create_timer(0.5).timeout
	if "--capture-ui" in OS.get_cmdline_user_args():
		get_viewport().get_texture().get_image().save_png("res://scenes/ui/inventory/preview.png")
		get_tree().quit()

