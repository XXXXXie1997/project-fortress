class_name DefenseResolution
extends RefCounted
var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/threat.json"))
func capture(s: Dictionary, enemy_power: float, id: String) -> Dictionary:
	var weights := {}
	for key in s.base.buildings:
		var b: Dictionary = s.base.buildings[key]
		weights[key] = config.core_weight if b.type in ["warehouse", "generator"] else config.normal_weight
	return {"id":id,"base":s.base.duplicate(true),"enemy_power":enemy_power,"weights":weights,"rng_state":s.rng_state}
func evaluate(snapshot: Dictionary) -> Dictionary:
	var base: Dictionary = snapshot.base
	var raw := 0.0
	var station := false
	for b in base.buildings.values():
		if b.durability <= 0: continue
		if b.type == "warehouse": station = true
		if b.type == "turret": raw += float(config.turret_power)
	for r in base.get("residents", []):
		if r.get("hp", 0) > 0: raw += float(r.get("power", config.resident_power))
	var usable := float(base.energy_store.energy) if station else 0.0
	var power := minf(raw, usable / float(config.energy_per_power))
	var ratio := power / maxf(0.01, float(snapshot.enemy_power))
	return {"power":power,"raw_power":raw,"energy":usable,"rating":"advantage" if ratio >= 1.2 else ("critical" if ratio >= 0.8 else "weak")}
func resolve(snapshot: Dictionary) -> Dictionary:
	var out := snapshot.duplicate(true)
	var assessment := evaluate(snapshot)
	var rng := RandomNumberGenerator.new()
	rng.state = int(snapshot.rng_state)
	var winning: bool = assessment.rating == "advantage" or assessment.power >= snapshot.enemy_power * rng.randf_range(0.85, 1.15)
	var spent := minf(float(out.base.energy_store.energy), minf(assessment.power, snapshot.enemy_power) * float(config.energy_per_power))
	out.base.energy_store.energy -= spent
	var destroyed: Array = []
	# 护盾是独立耐久；仅消耗已有护盾，不从能源站自动补充。
	if out.base.has("shield"):
		out.base.shield.energy = maxf(0.0, float(out.base.shield.get("energy", 0)) - float(snapshot.enemy_power))
	for id in out.weights:
		# 异常恢复缺失实例仍在固定分母中算完全损毁，不创造替代实例。
		if not out.base.buildings.has(id):
			destroyed.append(id)
			continue
		var b: Dictionary = out.base.buildings[id]
		if b.durability <= 0: continue
		var damage := float(b.maximum) * (rng.randf_range(0.0, 0.03) if winning else rng.randf_range(0.5, 1.0))
		b.durability = maxf(minf(float(b.durability), 1.0) if winning else 0.0, float(b.durability) - damage)
		if b.durability == 0: destroyed.append(id)
	var dead: Array = []
	for r in out.base.get("residents", []):
		if r.get("hp", 0) <= 0: continue
		if not winning and rng.randf() < 0.5:
			r.hp = 0
			dead.append(r.id)
		else: r.hp = r.get("max_hp", r.hp)
	out.rng_state = str(rng.state)
	out.result = {"energy_spent":spent,"destroyed":destroyed,"dead":dead,"held":not lost(out),"loot":config.loot.duplicate(true)}
	return out
func lost(snapshot: Dictionary) -> bool:
	var total := 0.0
	var damage := 0.0
	for id in snapshot.weights:
		var weight := float(snapshot.weights[id])
		total += weight
		if not snapshot.base.buildings.has(id) or snapshot.base.buildings[id].durability <= 0: damage += weight
	return total > 0 and damage / total >= float(config.loss_threshold)

# Presentation only. Frozen night weights are paired with CURRENT buildings.
func warning_state(s: Dictionary) -> Dictionary:
	var weights:Dictionary={}
	var frozen:Dictionary=s.get("cycle",{}).get("night",{}).get("snapshot",{})
	if s.get("phase","")=="night" and frozen.has("weights"):
		weights=frozen.weights.duplicate()
	else:
		for id in s.base.buildings:
			weights[id]=config.core_weight if s.base.buildings[id].type in ["warehouse","generator"] else config.normal_weight
	var total:=0.0
	var destroyed:=0.0
	for id in weights:
		total+=float(weights[id])
		if not s.base.buildings.has(id) or s.base.buildings[id].durability<=0:destroyed+=float(weights[id])
	var fraction:=destroyed/total if total>0 else 0.0
	var threshold:float=float(config.loss_threshold)
	return {"visible":total>0 and fraction>=threshold*float(config.get("warning_threshold_fraction",0.75)),"destroyed_weight":destroyed,"total_weight":total,"fraction":fraction,"threshold_reached":total>0 and fraction>=threshold}
