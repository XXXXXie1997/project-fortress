extends SceneTree
func _initialize():call_deferred("run")
func run():
	var arena=load("res://scenes/enemies/enemy_arena.tscn").instantiate()
	root.add_child(arena)
	await physics_frame
	await process_frame
	assert(arena.hud.quick_slots[0].modulate==Color.WHITE)
	arena.inventory.consume(arena.state,"medical_needle",5)
	await process_frame
	assert(arena.hud.quick_slots[0].modulate!=Color.WHITE)
	arena.inventory.spawn(arena.state,"medical_needle","bag",1)
	await process_frame
	assert(arena.hud.quick_slots[0].modulate==Color.WHITE)
	arena.queue_free()
	await process_frame
	print("QUICK_GRAY_RESTORE_PASS")
	quit()
