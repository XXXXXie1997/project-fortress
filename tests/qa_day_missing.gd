extends SceneTree
func _init():
 var defense = load("res://scripts/base/defense_resolution.gd").new()
 var s = {"base":{"buildings":{"warehouse":{"type":"warehouse","durability":100,"maximum":100}},"energy_store":{"energy":100},"residents":[]},"rng_state":"123"}
 var original = defense.capture(s,10,"night:1")
 s.base.buildings.erase("warehouse")
 var remainder = defense.capture(s,5,"night:1")
 remainder.weights = original.weights
 print("QA BEGIN missing original building")
 var result = defense.resolve(remainder)
 print("QA RESULT ",result)
 quit()
