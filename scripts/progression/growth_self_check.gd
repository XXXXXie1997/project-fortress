extends SceneTree

func _init() -> void:
	var service = load("res://scripts/progression/player_growth.gd").new()
	var state := {"player": {}, "base": {"tech": ["keep"]}}
	assert(service.award(state, "kill", 350, "enemy_1").levels == 3)
	assert(service.award(state, "kill", 350, "enemy_1").duplicate)
	assert(state.player.growth.points == 3)
	assert(not service.invest(state, "hurt_speed").ok)
	assert(service.invest(state, "stamina").ok)
	assert(service.invest(state, "hurt_speed").ok)
	assert(not service.invest(state, "hurt_speed").ok)
	assert(service.effects(state).hurt_speed_enabled)
	var before: Dictionary = service.snapshot(state)
	assert(service.exploration_failed(state) == before)
	assert(not service.preview_reset(state, false).ok)
	var quote: Dictionary = service.preview_reset(state, true)
	assert(not service.commit_reset(state, quote, true, false).ok)
	assert(service.snapshot(state) == before)
	assert(service.commit_reset(state, quote, true, true).ok)
	assert(not service.commit_reset(state, quote, true, true).ok)
	assert(state.player.growth.points == 3)
	assert(service.award(state, "quest", 2000, "quest_1").ok)
	for id in ["vitality", "stamina", "accuracy", "stealth", "hurt_speed"]:
		for rank in int(service.config.nodes[id].max_rank):
			assert(service.invest(state, id).ok)
		assert(not service.invest(state, id).ok)
	assert(service.effects(state).alert_accumulation_multiplier < 1.0)
	var restored: Dictionary = JSON.parse_string(JSON.stringify(state))
	for key in ["xp", "level", "points", "revision"]:
		assert(int(restored.player.growth[key]) == int(state.player.growth[key]))
	for id in state.player.growth.ranks:
		assert(int(restored.player.growth.ranks[id]) == int(state.player.growth.ranks[id]))
	assert(service.award(restored, "quest", 2000, "quest_1").duplicate)
	assert(service.effects(restored) == service.effects(state))
	service.new_survivor(state)
	assert(state.player.growth == service.fresh())
	assert(state.base.tech == ["keep"])
	print("DEV-311 SELF CHECK PASS")
	quit()
