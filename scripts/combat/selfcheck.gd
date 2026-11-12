extends SceneTree
const A = preload("res://scripts/player/action_rules.gd")
const D = preload("res://scripts/combat/damage_rules.gd")
const W = preload("res://scripts/combat/weapon_rules.gd")
func _initialize():
 var cfg = JSON.parse_string(FileAccess.get_file_as_string("res://data/combat.json"))
 var s = A.fresh(cfg)
 s.stamina = 1.0
 s.charging = true
 assert(A.dodge(s,Vector2.ZERO,Vector2.RIGHT,cfg))
 assert(s.exhausted and s.charging and not A.can_attack(s) and s.dodge_direction[0] == -1.0)
 A.tick(s,1.0,cfg,false,false,false)
 assert(s.exhausted)
 A.tick(s,5.0,cfg,false,false,false)
 assert(not s.exhausted)
 A.tick(s,0.1,cfg,true,true,true)
 assert(s.aiming and not s.sprinting)
 var vitals = {"hp":100.0,"max_hp":100.0,"hurt_speed_talent":true}
 var armor = {"durability":100.0,"rating":10.0}
 var hit = D.hit(vitals,s,armor,{"damage":10.0,"penetration":0.0},cfg)
 assert(hit.hp_loss == 0 and hit.armor_loss > 0 and s.hurt_iframe > 0 and s.hurt_boost == 0)
 assert(D.hit(vitals,s,armor,{"damage":10.0},cfg).blocked)
 var heals = []
 vitals.hp = 50.0
 D.start_heal(heals,{"cast_time":1.0,"instant":10.0,"duration":2.0,"rate":5.0})
 D.tick_heals(vitals,heals,2.0)
 assert(vitals.hp == 65.0)
 D.tick_heals(vitals,heals,1.0)
 assert(vitals.hp == 70.0 and heals.is_empty())
 assert(W.attack_parameters({"durability":10.0,"energy":0.0},cfg.weapons.energy_blade).damage == 12.0)
 assert(W.attack_parameters({"durability":0.0,"energy":10.0},cfg.weapons.energy_blade).is_empty())
 var previous_fraction = -1.0
 for penetration in [0.0, 1.0, 10.0, 100.0, 1000000000.0]:
  var fraction = D.armored_damage_fraction(penetration,10.0,cfg)
  assert(fraction >= previous_fraction and fraction < 1.0)
  previous_fraction = fraction
  var target = {"hp":100.0,"max_hp":100.0}
  var protection = {"durability":100.0,"rating":10.0}
  var result = D.hit(target,A.fresh(cfg),protection,{"damage":10.0,"penetration":penetration},cfg)
  assert(result.hp_loss < 10.0 and result.armor_loss > 0.0)
 for protection in [{},{"durability":0.0,"rating":10.0}]:
  var result = D.hit({"hp":100.0},A.fresh(cfg),protection,{"damage":10.0,"penetration":100.0},cfg)
  assert(result.hp_loss == 10.0 and result.armor_loss == 0.0)
 print("DEV-101 selfcheck PASS")
 quit()
