extends RefCounted

const NORMAL := Color("#ffffff")
const MAIN := Color("#9edce8")
const URGENT := Color("#ffbd70")
const EXPIRED := Color("#ff8787")

static func title(definition: String) -> String:
	return {"main_1":"调查郊区中继", "main_2":"恢复外界通信", "daily_kill":"清理感染者", "daily_scrap":"提交废料"}.get(definition, "委托")

static func describe(status: Dictionary) -> Dictionary:
	if status.is_empty(): return {"text":"", "color":NORMAL}
	var main: bool = status.definition_data.kind == "main"
	var detail := "主线 · 不限期" if main else "每日委托 · 剩余%d天" % int(status.days_remaining)
	var color := MAIN if main else NORMAL
	if status.expired:
		detail = "! 已过期 · 无法交付"
		color = EXPIRED
	elif status.near_deadline:
		detail = "! 剩余%d天 · 即将到期" % int(status.days_remaining)
		color = URGENT
	return {"text":"%s %s / %s\n%s" % [title(status.definition), status.progress, status.definition_data.count, detail], "color":color}

static func tracker(state: Dictionary, quests: QuestService) -> String:
	var active: Dictionary = state.get("quests", {}).get("active", {})
	if active.is_empty(): return "任务追踪：尚无任务"
	var lines := PackedStringArray(["任务追踪"])
	for id in active:
		var presentation := describe(quests.status(state, id))
		lines.append("[color=#%s]%s[/color]" % [presentation.color.to_html(false), presentation.text])
	return "\n".join(lines)
