extends "res://scripts/world/enemies/infected_actor.gd"
var base_target:Node2D
func _physics_process(dt):
 if not arena.running:return
 var r:Dictionary=record()
 if r.vitals.hp<=0:collision_layer=0;collision_mask=0;return
 base_target=arena.nearest_defense(position)
 if not is_instance_valid(base_target):return
 r.cooldown=maxf(0,r.cooldown-dt)
 if r.attack_left>0:
  r.attack_left-=dt
  if r.attack_left<=0:
   if spec.get('ranged',false):arena.fire_base(position,base_target.position,spec.damage,true)
   elif position.distance_to(base_target.position)<=spec.range+26 and arena.clear_line(position,base_target.position,1):base_target.receive_damage(spec.damage,position.direction_to(base_target.position))
   r.cooldown=spec.interval
 elif position.distance_to(base_target.position)<=spec.range+20 and r.cooldown<=0:
  r.attack_left=spec.windup
 var goal:Vector2=base_target.position
 var geometry=preload('res://scripts/base/base_geometry.gd')
 if geometry.approach_side(arena.grid.world_to_logical(position),arena.state.base.bounds) and not geometry.approach_side(arena.grid.world_to_logical(goal),arena.state.base.bounds):goal=arena.grid.logical_to_world(arena.gate_logical)
 velocity=arena.walk_direction(position,goal)*spec.speed if position.distance_to(goal)>spec.range*0.65 and r.attack_left<=0 else Vector2.ZERO
 velocity+=arena.separation(self)*35
 move_and_slide()
 r.position=[position.x,position.y];set_meta('hp',r.vitals.hp);queue_redraw()
func visible_to_player()->bool:return true



