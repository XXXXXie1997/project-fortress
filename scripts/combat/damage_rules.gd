class_name DamageRules
extends RefCounted

# Active armor always retains some mitigation. Penetration approaches, but never
# exceeds, the configured damage ceiling; the unarmored path bypasses this rule.
static func armored_damage_fraction(penetration: float, rating: float, cfg: Dictionary) -> float:
	var residual := clampf(cfg.get("minimum_armor_mitigation", 0.05), 0.001, 1.0)
	var ceiling := 1.0 - residual
	var minimum := clampf(cfg.minimum_damage_fraction, 0.0, ceiling)
	var scaled := maxf(0.0, penetration) / maxf(0.001, rating) * maxf(0.0, cfg.penetration_scale)
	return lerpf(minimum, ceiling, 1.0 - 1.0 / (1.0 + scaled))

# Armor is the current actual item reference. Never retain it across inventory transactions.
static func hit(vitals: Dictionary, action: Dictionary, armor: Dictionary, attack: Dictionary, cfg: Dictionary, kind: String = "player", self_hit: bool = false) -> Dictionary:
	var result := {"hp_loss": 0.0, "armor_loss": 0.0, "blocked": false, "knockback": 0.0}
	if vitals.hp <= 0.0 or action.dodge_left > 0.0 or (kind != "enemy" and action.hurt_iframe > 0.0):
		result.blocked = true
		return result
	var damage := maxf(0.0, attack.get("damage", 0.0))
	if self_hit:
		damage *= cfg.self_damage_factor
	var hp_damage := damage
	if not armor.is_empty() and armor.get("durability", 0.0) > 0.0:
		var rating := maxf(0.001, armor.get("rating", 1.0))
		hp_damage *= armored_damage_fraction(attack.get("penetration", 0.0), rating, cfg)
		result.armor_loss = minf(armor.durability, damage * cfg.armor_wear)
		armor.durability -= result.armor_loss
	result.hp_loss = minf(vitals.hp, hp_damage)
	vitals.hp -= result.hp_loss
	if result.hp_loss > 0.0 or result.armor_loss > 0.0:
		if kind != "enemy":
			action.hurt_iframe = cfg.hurt_iframe
		result.knockback = maxf(0.0, attack.get("knockback", 0.0)) * clampf(1.0 - vitals.get("knockback_resistance", 0.0), 0.0, 1.0)
	if result.hp_loss > 0.0 and vitals.get("hurt_speed_talent", false):
		action.hurt_boost = cfg.hurt_boost_duration
	return result

static func start_heal(heals: Array, definition: Dictionary) -> void:
	heals.append({"remaining_cast": definition.get("cast_time", 0.0), "remaining_hot": definition.get("duration", 0.0), "instant": definition.get("instant", 0.0), "rate": definition.get("rate", 0.0), "interrupt_cast": definition.get("interrupt_cast", true), "interrupt_hot": definition.get("interrupt_hot", false), "applied": false})

static func interrupt_heals(heals: Array) -> void:
	for i in range(heals.size() - 1, -1, -1):
		var h: Dictionary = heals[i]
		if (not h.applied and h.interrupt_cast) or (h.applied and h.interrupt_hot):
			heals.remove_at(i)

static func tick_heals(vitals: Dictionary, heals: Array, dt: float, paused: bool = false) -> void:
	if paused or not is_finite(dt) or dt <= 0.0 or vitals.hp <= 0.0:
		return
	for i in range(heals.size() - 1, -1, -1):
		var h: Dictionary = heals[i]
		var available := maxf(0.0, dt - h.remaining_cast)
		h.remaining_cast = maxf(0.0, h.remaining_cast - dt)
		if h.remaining_cast > 0.0:
			continue
		if not h.applied:
			vitals.hp = minf(vitals.max_hp, vitals.hp + h.instant)
			h.applied = true
		var elapsed := minf(available, h.remaining_hot)
		vitals.hp = minf(vitals.max_hp, vitals.hp + elapsed * h.rate)
		h.remaining_hot -= elapsed
		if h.remaining_hot <= 0.0:
			heals.remove_at(i)
