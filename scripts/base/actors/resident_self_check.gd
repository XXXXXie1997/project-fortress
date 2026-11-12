extends SceneTree
func _init() -> void:
	var s := WorldState.fresh()
	var inv := InventoryService.new(JSON.parse_string(FileAccess.get_file_as_string("res://data/items.json")).items)
	inv.setup(s)
	s.base.resident_capacity = 1
	s.base.residents = []
	var service = load("res://scripts/base/actors/resident_service.gd").new(inv)
	var result: Dictionary = service.recruit(s,"visit:1")
	assert(result.ok)
	assert(not service.recruit(s,"visit:1").ok)
	assert(not service.recruit(s,"visit:2").ok)
	var weapon: String = s.base.residents[0].weapon_instance
	assert(s.items.has(weapon))
	assert(service.dismiss(s,result.id))
	assert(not s.items.has(weapon))
	assert(not service.recruit(s,"visit:1").ok)
	assert(service.recruit(s,"visit:2").ok)
	assert(s.base.residents[0].id != result.id)
	print("DEV402 RESIDENT SELF CHECK PASS")
	quit()
