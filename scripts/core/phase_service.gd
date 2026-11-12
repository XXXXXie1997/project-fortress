class_name PhaseService
extends RefCounted

const NEXT := {"morning": ["day", "dusk"], "day": ["dusk"], "dusk": ["night"], "night": ["morning"]}

# Returns a settlement identity; consumers apply each id only once.
static func advance(state: Dictionary, destination: String) -> Dictionary:
	var previous: String = state.phase
	if not destination in NEXT.get(previous, []):
		return {"ok": false, "reason": "invalid_transition"}
	var settlement := ""
	if destination == "dusk":
		settlement = "%d:day" % int(state.day)
	elif destination == "morning":
		settlement = "%d:night" % int(state.day)
		state.day = int(state.day) + 1
	state.phase = destination
	return {"ok": true, "from": previous, "to": destination, "settlement_id": settlement}
