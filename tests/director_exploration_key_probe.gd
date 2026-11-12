extends SceneTree

func _initialize():
	var state := WorldState.fresh()
	var definitions: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/items.json")).items
	definitions.test_key = {"category":"key", "size":[1,1], "weight":0.0, "backpack_stack":1, "warehouse_stack":1}
	var inventory := InventoryService.new(definitions)
	inventory.setup(state)
	var maps: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/maps/exploration.json")).maps
	maps.suburbs.doors.cache = "test_key"
	var exploration := ExplorationService.new(inventory, maps)
	assert(exploration.start(state, "suburbs", "south", "day"))
	assert(not inventory.spawn(state, "test_key", "bag").is_empty())
	assert(exploration.unlock_door(state, "cache", "test_key"))
	assert(exploration.kill(state, "infected_01"))
	assert(exploration.enemy_loot(state, "infected_01", [{"definition_id":"test_key", "quantity":1, "door_key":"suburbs:cache"}]))
	var remaining := 0
	for item: Dictionary in state.items.values():
		if item.definition_id == "test_key": remaining += int(item.quantity)
	print("PERMANENT_DOOR_KEY_REMAINING=", remaining)
	quit(0 if remaining == 0 else 1)
