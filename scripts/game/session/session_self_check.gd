extends SceneTree
const Coordinator = preload("res://scripts/game/session/session_coordinator.gd")
func _initialize(): call_deferred("run")
func run():
	var coordinator = Coordinator.new("user://session_checks/%s" % Time.get_ticks_usec())
	assert(coordinator.create_world(412).ok)
	var s: Dictionary = coordinator.state
	assert(s.base.residents.is_empty())
	assert(s.base.buildings.size() == 6)
	assert(s.player.equipment.weapon_3 == "")
	assert(s.has("run_start_snapshot"))
	var original := WorldState.encode(s)
	assert(not coordinator.transact(func(t: Dictionary) -> Dictionary:
		t.base.energy_store.energy = 0
		return {"ok": false}).ok)
	assert(WorldState.encode(s) == original)
	var spawn_id: String = coordinator.services.exploration.maps.suburbs.initial_spawn
	assert(coordinator.depart("suburbs", spawn_id).ok)
	var id_count: int = s.next_id
	assert(not coordinator.depart("suburbs", spawn_id).ok)
	assert(s.next_id == id_count)
	assert(coordinator.shutdown().ok)
	assert(coordinator.restore().ok)
	assert(coordinator.state.expedition.active)
	assert(coordinator.state.session.location == "exploration")
	assert(coordinator.state.next_id == id_count)
	# Complete finish+settlement is an upper-level transaction, including death bag.
	assert(coordinator.finish_exploration(true, [450.0, 210.0]).ok)
	assert(coordinator.state.phase == "dusk")
	assert(coordinator.state.world.exploration.death_bags.size() == 1)
	original = WorldState.encode(coordinator.state)
	assert(not coordinator.finish_exploration(true, [450.0, 210.0]).ok)
	assert(WorldState.encode(coordinator.state) == original)
	assert(coordinator.shutdown().ok)
	assert(coordinator.restore(true).ok)
	assert(coordinator.state.phase == "morning")
	assert(coordinator.state.world.exploration.death_bags.is_empty())
	assert(coordinator.shutdown().ok)
	print("SESSION_ATOMIC_RESTORE_PASS")
	quit()
