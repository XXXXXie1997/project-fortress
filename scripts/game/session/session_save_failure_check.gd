extends SceneTree
const Coordinator = preload("res://scripts/game/session/session_coordinator.gd")
func _initialize(): call_deferred("run")
func run():
	var directory := "res://.godot-local/session-save-failure-%s" % Time.get_ticks_usec()
	var coordinator = Coordinator.new(directory + "/valid")
	assert(coordinator.create_world(123).ok)
	# A file as the parent produces a real filesystem refusal, with no injection.
	var blocker := FileAccess.open(directory + "/blocker", FileAccess.WRITE)
	blocker.store_string("not a directory")
	blocker.close()
	coordinator.saver.root = ProjectSettings.globalize_path(directory + "/blocker/saves")
	coordinator.state.day = 2
	coordinator.state.base.energy_store.energy = 321.0
	assert(coordinator.request_save().ok)
	assert(not coordinator.shutdown().ok)
	assert(coordinator.saver.pending.has("slot_1/morning"))
	assert(coordinator.saver.pending["slot_1/morning"].state.base.energy_store.energy == 321.0)
	coordinator.state.base.energy_store.energy = 123.0
	assert(coordinator.request_save().ok)
	assert(coordinator.saver.pending["slot_1/morning"].state.base.energy_store.energy == 321.0)
	assert(DirAccess.remove_absolute(ProjectSettings.globalize_path(directory + "/blocker")) == OK)
	assert(coordinator.shutdown().ok)
	assert(coordinator.saver.load_snapshot("slot_1", "morning").state.base.energy_store.energy == 321.0)
	assert(coordinator.saver.load_snapshot("slot_1", "latest").state.base.energy_store.energy == 123.0)
	coordinator.slot = "invalid/slot"
	assert(not coordinator.shutdown().ok)
	assert(coordinator.saver.worker == null)
	print("SESSION_REAL_WRITE_FAILURE_RETRY_PASS")
	quit()
