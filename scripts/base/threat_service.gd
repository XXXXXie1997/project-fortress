class_name ThreatService
extends RefCounted
var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/threat.json"))
func setup(s: Dictionary) -> void:
	if not s.has("threat"): s.threat = {"stage":1,"entered_day":s.day,"events":{},"consumed_stages":[]}
func morning(s: Dictionary) -> void:
	setup(s)
	for event in s.quests.get("pending_stages", []):
		if event.effective_day <= s.day and event.id not in s.threat.consumed_stages:
			s.threat.consumed_stages.append(event.id)
			if event.stage > s.threat.stage:
				s.threat.stage = event.stage
				s.threat.entered_day = s.day
func strength(s: Dictionary) -> float:
	setup(s)
	var age := int(s.day) - int(s.threat.entered_day)
	var base := float(s.threat.stage) * minf(config.stage_cap, config.stage_base + age * config.daily_growth)
	var total := base * (float(config.period_multiplier) if (age + 1) % int(config.period) == 0 else 1.0)
	for event in s.threat.events.values():
		if event.day == s.day: total += float(event.strength)
	return minf(total, base * float(config.merge_cap))
func schedule(s: Dictionary, id: String, major: bool, at_night: bool, multiplier: float = 0.5) -> bool:
	setup(s)
	if id.is_empty() or s.threat.events.has(id) or multiplier < 0 or not is_finite(multiplier): return false
	s.threat.events[id] = {"day": int(s.day) + (2 if major else (1 if at_night else 0)), "strength": strength(s) * multiplier}
	return true
