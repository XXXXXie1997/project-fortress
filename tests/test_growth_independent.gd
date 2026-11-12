extends SceneTree
const Growth = preload("res://scripts/progression/player_growth.gd")
var count := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	count += 1
	if not ok:
		failures += 1
		printerr("FAIL ", label)
func _init() -> void:
	var g = Growth.new()
	var s = {"player": {"hp": 73}, "base": {"tech": ["a"], "energy": 57}, "residents": [{"hp": 8}], "maps": ["unlocked"]}
	check(not g.invest(s, "vitality").ok, "zero points")
	check(g.award(s, "kill", 299, "k").levels == 2, "cross levels")
	check(g.snapshot(s).points == 2 and g.snapshot(s).level == 3, "points")
	var old = s.duplicate(true)
	check(g.award(s, "quest", 999, "k").duplicate and s == old, "global dedup")
	check(g.award(s, "survival", 1, "day").levels == 1, "threshold")
	check(g.award(s, "quest", 700, "q").ok, "quest")
	old = s.duplicate(true)
	check(g.exploration_failed(s) == g.snapshot(s) and s == old, "failure retains")
	check(not g.invest(s, "stealth").ok and s == old, "prerequisite denial atomic")
	check(g.invest(s, "accuracy").ok and g.invest(s, "stealth").ok, "accuracy rank one sufficient")
	check(g.invest(s, "stamina").ok and g.invest(s, "hurt_speed").ok, "stamina rank one sufficient")
	check(g.effects(s).hurt_speed_enabled and is_equal_approx(g.effects(s).alert_accumulation_multiplier, 0.8), "mechanism effects")
	old = s.duplicate(true)
	check(not g.invest(s, "stealth").ok and s == old, "max rank no charge")
	check(not g.preview_reset(s, false).ok and s == old, "field reset denied")
	var quote = g.preview_reset(s, true)
	check(not g.commit_reset(s, quote, true, false).ok and s == old, "payment failure atomic")
	check(not g.commit_reset(s, quote, false, true).ok and s == old, "field commit atomic")
	g.award(s, "kill", 100, "new")
	old = s.duplicate(true)
	check(not g.commit_reset(s, quote, true, true).ok and s == old, "stale quote")
	quote = g.preview_reset(s, true)
	check(g.commit_reset(s, quote, true, true).ok, "reset succeeds")
	check(g.snapshot(s).points == 11 and g.snapshot(s).ranks.is_empty() and g.snapshot(s).xp == 1100, "refund")
	old = s.duplicate(true)
	check(not g.commit_reset(s, quote, true, true).ok and s == old, "replay denied")
	for id in ["vitality", "stamina", "accuracy", "stealth", "hurt_speed"]:
		for n in range(int(g.config.nodes[id].max_rank)):
			check(g.invest(s, id).ok, "full tree " + id)
	check(g.snapshot(s).points == 0, "all eleven points used")
	old = s.duplicate(true)
	for id in g.config.nodes:
		check(not g.invest(s, id).ok and s == old, "no overflow " + id)
	var f = FileAccess.open("user://qa_growth.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(s))
	f.close()
	var loaded = JSON.parse_string(FileAccess.get_file_as_string("user://qa_growth.json"))
	check(g.award(loaded, "quest", 100, "loaded").ok and g.snapshot(loaded).points == 1, "disk JSON award")
	check(g.commit_reset(loaded, g.preview_reset(loaded, true), true, true).ok and g.invest(loaded, "vitality").ok, "disk JSON reset invest")
	var external = loaded.duplicate(true)
	g.new_survivor(loaded)
	external.player.growth = g.fresh()
	check(loaded == external and loaded.player.hp == 73, "NG isolation")
	var poor = {}
	g.award(poor, "kill", 100)
	g.invest(poor, "vitality")
	old = poor.duplicate(true)
	check(not g.invest(poor, "vitality").ok and poor == old, "unmaxed insufficient points atomic")
	print("DEV-311 INDEPENDENT checks=", count, " failures=", failures)
	quit(1 if failures else 0)
