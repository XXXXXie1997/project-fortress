extends SceneTree

func _initialize() -> void:
	var s := WorldState.fresh()
	var inv := InventoryService.new(JSON.parse_string(FileAccess.get_file_as_string("res://data/items.json")).items)
	inv.setup(s)
	var gun := inv.spawn(s, "rifle_basic", "ground")
	inv.equip(s, gun.id, "weapon_1")
	var plugin := WorldState.create_item(s, "test_plugin", "plugin")
	plugin.capacity = 100.0
	s.items[gun.id].plugins = {"tactical": plugin.id, "duplicate": plugin.id}
	s.base.energy_store.energy = 100.0
	ChargingService.wireless(s, 1, 10, true, true, false)
	assert(s.items[plugin.id].energy == 10.0, "duplicate references must not double-charge")
	var other := inv.spawn(s, "rifle_basic", "ground")
	s.items[other.id].plugins = {"tactical": plugin.id}
	ChargingService.wireless(s, 1, 10, true, true, false)
	assert(s.items[plugin.id].energy == 10.0, "ambiguous ownership must not charge")
	s.items[other.id].plugins = {}
	inv.move(s, gun.id, "ground")
	ChargingService.wireless(s, 1, 10, true, true, false)
	assert(s.items[plugin.id].energy == 10.0, "unworn weapon must not charge its plugin")
	inv.equip(s, gun.id, "weapon_1")
	var battery := inv.spawn(s, "battery_basic", "bag")
	s.items[battery.id].energy = 20.0
	s.items[gun.id].energy = 0.0
	assert(ChargingService.charge_weapon(s, gun.id, 5.0, "expired_selection") == 5.0)
	s.items[gun.id].energy = s.items[gun.id].capacity
	s.base.energy_store.energy = 3.0
	var before: float = s.items[plugin.id].energy + s.items[battery.id].energy + s.base.energy_store.energy
	ChargingService.wireless(s, 1, 10, true, true, false)
	assert(is_equal_approx(before, s.items[plugin.id].energy + s.items[battery.id].energy + s.base.energy_store.energy))
	assert(s.base.energy_store.energy == 0.0)
	print("CHARGING EDGE SELF CHECK PASSED")
	quit()
