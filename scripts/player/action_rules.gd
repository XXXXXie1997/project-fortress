class_name ActionRules
extends RefCounted

static func fresh(cfg: Dictionary) -> Dictionary:
	return {"stamina": cfg.max_stamina, "exhausted": false, "recovery_delay": 0.0, "dodge_left": 0.0, "dodge_cooldown": 0.0, "dodge_direction": [0.0, 1.0], "charging": false, "melee": false, "aiming": false, "sprinting": false, "hurt_iframe": 0.0, "hurt_boost": 0.0}

static func spend(s: Dictionary, amount: float, cfg: Dictionary) -> bool:
	if s.exhausted or s.stamina <= 0.0 or not is_finite(amount) or amount < 0.0:
		return false
	s.stamina = maxf(0.0, s.stamina - amount)
	s.recovery_delay = cfg.recovery_delay
	s.exhausted = s.stamina <= 0.0
	return true

static func can_attack(s: Dictionary) -> bool:
	return s.dodge_left <= 0.0 and not s.charging

static func start_melee(s: Dictionary, cost: float, cfg: Dictionary) -> bool:
	if not can_attack(s) or not spend(s, cost, cfg):
		return false
	s.melee = true
	return true

static func dodge(s: Dictionary, move: Vector2, aim: Vector2, cfg: Dictionary, cost_factor: float = 1.0) -> bool:
	if s.dodge_cooldown > 0.0 or s.dodge_left > 0.0 or not spend(s, cfg.dodge_cost * cost_factor, cfg):
		return false
	var direction := move.normalized() if move.length_squared() > 0.0 else -aim.normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.DOWN
	s.dodge_direction = [direction.x, direction.y]
	s.dodge_left = cfg.dodge_duration
	s.dodge_cooldown = cfg.dodge_cooldown
	s.melee = false
	return true

static func switch_weapon(s: Dictionary) -> void:
	s.charging = false
	s.melee = false

static func tick(s: Dictionary, dt: float, cfg: Dictionary, aim: bool, sprint: bool, moving: bool, paused: bool = false, cost_factor: float = 1.0) -> void:
	if paused or not is_finite(dt) or dt <= 0.0:
		return
	for timer in ["dodge_left", "dodge_cooldown", "hurt_iframe", "hurt_boost"]:
		s[timer] = maxf(0.0, s[timer] - dt)
	s.aiming = aim
	s.sprinting = sprint and moving and not aim and not s.exhausted and s.dodge_left <= 0.0
	if s.sprinting:
		spend(s, cfg.sprint_cost * cost_factor * dt, cfg)
	else:
		var recover_time := maxf(0.0, dt - s.recovery_delay)
		s.recovery_delay = maxf(0.0, s.recovery_delay - dt)
		s.stamina = minf(cfg.max_stamina, s.stamina + recover_time * cfg.recovery_rate)
		if s.stamina >= cfg.max_stamina:
			s.exhausted = false

static func movement_factor(s: Dictionary, cfg: Dictionary) -> float:
	var factor: float = cfg.aim_speed if s.aiming else (cfg.sprint_speed if s.sprinting else 1.0)
	return factor * (cfg.hurt_speed if s.hurt_boost > 0.0 else 1.0)
