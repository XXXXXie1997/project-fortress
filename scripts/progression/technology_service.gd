class_name TechnologyService
extends RefCounted
var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/technology.json"))
var inventory: InventoryService
func _init(service: InventoryService) -> void:
	inventory = service
func unlock(state: Dictionary, id: String, at_base: bool) -> Dictionary:
	if not at_base or not config.nodes.has(id): return {"ok": false}
	var known: Dictionary = state.base.get("technology", {})
	if known.has(id): return {"ok": false}
	var node: Dictionary = config.nodes[id]
	for required in node.requires:
		if not known.has(required): return {"ok": false}
	var trial := state.duplicate(true)
	if float(trial.base.energy_store.energy) < float(node.energy): return {"ok": false}
	if not inventory.exchange(trial, node.materials, {}).ok: return {"ok": false}
	trial.base.energy_store.energy -= float(node.energy)
	trial.base.technology = known.duplicate(true)
	trial.base.technology[id] = true
	inventory.commit(state, trial)
	return {"ok": true, "effects": node.effects.duplicate(true)}
