extends SceneTree
const Coordinator = preload("res://scripts/game/session/session_coordinator.gd")
func _initialize(): call_deferred("run")
func run():
	for choice in ["new","plus","latest","morning"]:
		var c = Coordinator.new("user://failure-choice-%s-%s" % [choice,Time.get_ticks_usec()])
		assert(c.create_world(22).ok)
		var old_gun: String = c.state.player.equipment.weapon_1
		c.state.items[old_gun].energy = 19.0
		for building: Dictionary in c.state.base.buildings.values(): building.durability = 0
		assert(c.to_dusk().ok)
		assert(c.begin_night("rest",true).ok)
		var result: Dictionary = c.finish_night()
		assert(result.ok and not result.held and c.state.run_failed)
		assert(c.shutdown().ok)
		assert(c.saver.load_snapshot(c.slot,"failure").state.run_failed)
		assert(not c.saver.load_snapshot(c.slot,"latest").state.run_failed)
		assert(c.failure_choice(choice,33).ok)
		if choice == "plus":
			assert(c.state.items.has(old_gun))
			assert(c.state.items[old_gun].container_id.begins_with("relics_"))
			assert(c.state.items[old_gun].energy == 19.0)
			assert(c.state.player.equipment.weapon_1 == "")
			assert(c.services.inventory.equip(c.state,old_gun,"weapon_1").ok)
			assert(c.state.items[old_gun].energy == 19.0)
			for building: Dictionary in c.state.base.buildings.values(): assert(building.durability == 0)
		elif choice in ["new","morning"]:
			assert(c.state.phase == "morning" and c.state.day == 1)
			for building: Dictionary in c.state.base.buildings.values(): assert(building.durability == building.maximum)
		else:
			assert(c.state.phase == "night")
			assert(not c.state.cycle.failed)
		assert(c.shutdown().ok)
	print("SESSION_FAILURE_FOUR_CHOICES_RELIC_ID_PASS")
	quit()
