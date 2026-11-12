class_name WorldState
extends RefCounted

const VERSION := 1

static func fresh() -> Dictionary:
	return {"schema_version": VERSION, "next_id": 1, "day": 1, "phase": "morning",
		"items": {}, "containers": {}, "unique_items": {}, "player": {},
		"base": {}, "progression": {}, "quests": {}, "trade": {},
		"expedition": {}, "world": {}, "events": [], "settled_ids": [], "rng_state": "0"}

static func create_item(state: Dictionary, definition_id: String, container_id: String) -> Dictionary:
	if definition_id.is_empty() or container_id.is_empty() or not valid(state):
		return {}
	var id := "item_%d" % int(state.next_id)
	state.next_id = int(state.next_id) + 1
	var item := {"id": id, "definition_id": definition_id, "container_id": container_id,
		"quantity": 1, "quality": 1, "durability": 0.0, "energy": 0.0,
		"capacity": 0.0, "plugins": {}, "cell": [0, 0], "rotated": false}
	state.items[id] = item
	return item

static func encode(state: Dictionary) -> String:
	return JSON.stringify(state)

static func decode(encoded: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(encoded)
	if not parsed is Dictionary or parsed.get("schema_version", -1) != VERSION:
		return {}
	return parsed if valid(parsed) else {}

static func integer(value: Variant, minimum: int = 0) -> bool:
	return (value is int or value is float) and is_finite(value) and value >= minimum and value <= 9007199254740991 and value == floor(value)

static func valid(parsed: Dictionary) -> bool:
	var required := fresh()
	for key in required:
		if not parsed.has(key):
			return false
		if required[key] is Dictionary and not parsed[key] is Dictionary:
			return false
		if required[key] is Array and not parsed[key] is Array:
			return false
	if parsed.schema_version != VERSION or not integer(parsed.day, 1) or not integer(parsed.next_id, 1):
		return false
	if not parsed.phase is String or not parsed.phase in ["morning", "day", "dusk", "night"]:
		return false
	if not parsed.rng_state is String or not parsed.rng_state.is_valid_int():
		return false
	for id: Variant in parsed.items:
		if not id is String or not id.begins_with("item_"):
			return false
		var suffix: String = id.trim_prefix("item_")
		if not suffix.is_valid_int() or suffix != str(int(suffix)) or int(suffix) < 1 or int(suffix) >= parsed.next_id:
			return false
		var item: Variant = parsed.items[id]
		if not item is Dictionary or item.get("id") != id:
			return false
		if not item.has_all(["definition_id", "container_id", "quantity", "quality", "durability", "energy", "capacity", "plugins", "cell", "rotated"]):
			return false
		if not item.definition_id is String or item.definition_id.is_empty() or not item.container_id is String or item.container_id.is_empty():
			return false
		if not integer(item.quantity, 1) or not integer(item.quality, 1) or not EnergyService.valid_store(item):
			return false
		if not (item.durability is float or item.durability is int) or not is_finite(item.durability) or item.durability < 0:
			return false
		if not item.plugins is Dictionary or not item.rotated is bool or not item.cell is Array or item.cell.size() != 2:
			return false
		if not integer(item.cell[0]) or not integer(item.cell[1]):
			return false
	return true
