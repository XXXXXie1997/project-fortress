class_name WeaponRules
extends RefCounted

static func spread(weapon: Dictionary, bloom: float, moving: bool, aiming: bool, precision_factor: float = 1.0) -> float:
	var base: float = weapon.base_spread * maxf(0.0, precision_factor)
	return base * (weapon.aim_factor if aiming else 1.0) + (weapon.move_spread if moving else 0.0) + bloom

static func recover_bloom(bloom: float, weapon: Dictionary, dt: float, paused: bool = false) -> float:
	return bloom if paused else maxf(0.0, bloom - weapon.bloom_recovery * maxf(0.0, dt))

static func after_shot(bloom: float, weapon: Dictionary) -> float:
	return minf(weapon.max_bloom, bloom + weapon.bloom_per_shot)

static func attack_parameters(item: Dictionary, weapon: Dictionary) -> Dictionary:
	if item.get("durability", 0.0) <= 0.0:
		return {}
	var cost: float = weapon.get("energy_cost", 0.0)
	var powered: bool = item.get("energy", 0.0) >= cost
	if weapon.kind == "ranged" and not powered:
		return {}
	var damage: float = weapon.damage
	if weapon.kind == "melee" and powered:
		damage += weapon.get("energy_bonus", 0.0)
	var degraded: bool = item.durability < weapon.get("degrade_threshold", 0.0)
	return {"damage": damage * (weapon.get("degraded_factor", 1.0) if degraded else 1.0), "energy_cost": cost if powered else 0.0, "penetration": weapon.penetration, "knockback": weapon.knockback}

# Read-only projection. ChargingService owns passive energy drain.
static func extra_effects(items: Array, cfg: Dictionary) -> Dictionary:
	var effects := {"brightness": 0.0, "stamina_factor": 1.0, "precision_factor": 1.0}
	for item: Dictionary in items:
		if item.get("energy", 0.0) <= 0.0:
			continue
		if item.energy <= 0.0:
			continue
		match item.definition_id:
			"nightvision": effects.brightness = cfg.night_brightness
			"exoskeleton": effects.stamina_factor = cfg.exoskeleton_factor
			"aim_assist": effects.precision_factor = cfg.aim_assist_factor
	return effects


