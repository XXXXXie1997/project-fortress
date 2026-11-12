class_name PlayerGrowth
extends RefCounted

var config: Dictionary

func _init() -> void:
	config = JSON.parse_string(FileAccess.get_file_as_string("res://data/talents.json"))

func fresh() -> Dictionary:
	return {"xp": 0, "level": 1, "points": 0, "ranks": {}, "awarded_events": {}, "revision": 0}

func snapshot(state: Dictionary) -> Dictionary:
	return state.get("player", {}).get("growth", fresh()).duplicate(true)

func _store(state: Dictionary, growth: Dictionary) -> void:
	if not state.has("player"):
		state.player = {}
	state.player.growth = growth

func award(state: Dictionary, source: String, amount: int, event_id: String = "") -> Dictionary:
	if amount <= 0 or source not in ["kill", "survival", "quest"]:
		return {"ok": false, "reason": "invalid_award"}
	var g := snapshot(state)
	if not event_id.is_empty() and g.awarded_events.has(event_id):
		return {"ok": true, "duplicate": true, "levels": 0}
	# 保持JSON整数精度；没有人为等级上限，足够点满所有节点。
	if amount > 9007199254740991 - int(g.xp):
		return {"ok": false, "reason": "xp_overflow"}
	var old_level := int(g.level)
	g.xp = int(g.xp) + amount
	g.level = 1 + int(g.xp) / int(config.xp_per_level)
	var gained := int(g.level) - old_level
	g.points = int(g.points) + gained * int(config.points_per_level)
	if not event_id.is_empty():
		g.awarded_events[event_id] = source
	g.revision = int(g.revision) + 1
	_store(state, g)
	return {"ok": true, "duplicate": false, "levels": gained}

func invest(state: Dictionary, node_id: String) -> Dictionary:
	if not config.nodes.has(node_id):
		return {"ok": false, "reason": "unknown_node"}
	var g := snapshot(state)
	var node: Dictionary = config.nodes[node_id]
	var rank := int(g.ranks.get(node_id, 0))
	if rank >= int(node.max_rank) or int(g.points) < 1:
		return {"ok": false, "reason": "rank_or_points"}
	for prerequisite in node.requires:
		if int(g.ranks.get(prerequisite, 0)) < 1:
			return {"ok": false, "reason": "prerequisite"}
	g.ranks[node_id] = rank + 1
	g.points = int(g.points) - 1
	g.revision = int(g.revision) + 1
	_store(state, g)
	return {"ok": true}

func effects(state: Dictionary) -> Dictionary:
	var result := {"max_hp_bonus": 0.0, "max_stamina_bonus": 0.0, "base_spread_reduction": 0.0,
		"alert_accumulation_multiplier": 1.0, "hurt_speed_enabled": false,
		"hurt_speed_multiplier": 1.0, "hurt_speed_duration": 0.0}
	var g := snapshot(state)
	for id in config.nodes:
		var node: Dictionary = config.nodes[id]
		var rank := int(g.ranks.get(id, 0))
		var value := rank * float(node.per_rank)
		match str(node.effect):
			"alert_accumulation_reduction": result.alert_accumulation_multiplier = clampf(1.0 - value, 0.0, 1.0)
			"hurt_speed_bonus":
				result.hurt_speed_enabled = rank > 0
				result.hurt_speed_multiplier = 1.0 + value
				result.hurt_speed_duration = float(node.duration) if rank > 0 else 0.0
			_: result[node.effect] = value
	return result

func preview_reset(state: Dictionary, at_base: bool) -> Dictionary:
	if not at_base:
		return {"ok": false, "reason": "base_only"}
	return {"ok": true, "before": snapshot(state), "cost": config.reset_cost.duplicate(true)}

# 必须在上层完整资源事务副本内调用，成功后才整体替换世界状态。
# resources_paid仅代表调用方已完成扣费模拟，不是另建货币或授权凭证。
func commit_reset(state: Dictionary, quote: Dictionary, at_base: bool, resources_paid: bool) -> Dictionary:
	if not at_base or not resources_paid or not quote.get("ok", false):
		return {"ok": false, "reason": "reset_not_authorized"}
	var g := snapshot(state)
	if quote.get("before", {}) != g or quote.get("cost", {}) != config.reset_cost:
		return {"ok": false, "reason": "stale_quote"}
	for rank in g.ranks.values():
		g.points = int(g.points) + int(rank)
	g.ranks = {}
	g.revision = int(g.revision) + 1
	_store(state, g)
	return {"ok": true}

func exploration_failed(state: Dictionary) -> Dictionary:
	# 查询返回供失败结算验证；不回退即时成长。
	return snapshot(state)

func new_survivor(state: Dictionary) -> void:
	_store(state, fresh())
