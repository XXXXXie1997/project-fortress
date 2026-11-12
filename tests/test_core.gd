extends SceneTree
const W = preload("res://scripts/core/world_state.gd")
const E = preload("res://scripts/core/energy_service.gd")
const P = preload("res://scripts/core/phase_service.gd")
const I = preload("res://scripts/core/input_bindings.gd")
var failures: int = 0
func check(value: bool, label: String) -> void:
	print("PASS " if value else "FAIL ", label)
	if not value: failures += 1
func _initialize() -> void:
	var a = {"energy": 5.0, "capacity": 10.0}
	var b = {"energy": 8.0, "capacity": 10.0}
	check(E.transfer(a,b,9.0)==2.0 and a.energy==3.0 and b.energy==10.0, "bounded conservation")
	check(E.transfer(a,a,1.0)==0.0 and a.energy==3.0, "same store")
	check(E.transfer(a,b,-1.0)==0.0, "negative request")
	check(E.transfer({"energy":-1,"capacity":10},b,1)==0, "invalid store")
	check(E.transfer(a,b,INF)==0, "nonfinite request")
	for source in ["morning","day","dusk","night"]:
		for target in ["morning","day","dusk","night","invalid"]:
			var state=W.fresh();state.phase=source
			var before=W.encode(state)
			var allowed = (source=="morning" and target in ["day","dusk"]) or (source=="day" and target=="dusk") or (source=="dusk" and target=="night") or (source=="night" and target=="morning")
			check(P.advance(state,target).ok==allowed and (allowed or W.encode(state)==before), "phase "+source+" -> "+target)
	var state=W.fresh()
	var item=W.create_item(state,"battery","bag")
	var restored=W.decode(W.encode(state))
	check(restored.items.has(item.id) and W.create_item(restored,"battery","bag").id!=item.id,"JSON identity continuation")
	state.schema_version=99
	check(W.decode(W.encode(state)).is_empty(),"incompatible schema")
	for pair in [["day","bad"],["day",0],["next_id",-1],["phase",123],["phase","unknown"],["rng_state",[]]]:
		state=W.fresh();state[pair[0]]=pair[1]
		check(W.decode(W.encode(state)).is_empty(),"reject invalid scalar "+str(pair))
	state=W.fresh();W.create_item(state,"battery","bag");state.next_id=1
	check(W.decode(W.encode(state)).is_empty(),"reject ID collision state")
	I.install();var counts={}
	for action in I.KEYS: counts[action]=InputMap.action_get_events(action).size()
	I.install()
	for action in I.KEYS: check(InputMap.action_get_events(action).size()==counts[action] and counts[action]>0,"input idempotent "+action)
	check(InputMap.has_action("fire") and InputMap.has_action("aim"),"mouse actions")
	print("FAILURES ",failures)
	quit(1 if failures else 0)
