extends CharacterBody2D
var arena:Node2D
var id:String
var cooldown:=0.0
var invulnerable:=0.0
var returning:=false
var post:=Vector2.ZERO
var visual:Node2D
var charge_sound_left:=0.0
func data()->Dictionary:
 for r in arena.state.base.residents:
  if r.id==id:return r
 return {}
func _ready():
 collision_layer=64;collision_mask=1+32
 var cs:=CollisionShape2D.new();var circle:=CircleShape2D.new();circle.radius=12;cs.shape=circle;add_child(cs)
 visual=load('res://scripts/art/survivor_visual.gd').new();visual.scale=Vector2(2,2);add_child(visual)
func receive_damage(amount:float,_direction:Vector2=Vector2.ZERO):
 var r:=data()
 if r.is_empty() or r.hp<=0 or invulnerable>0:return
 var hp_before:float=r.hp
 r.hp=maxf(0,r.hp-amount);invulnerable=0.3
 arena.show_blood(hp_before-r.hp,position,_direction)
 if r.hp<=0:arena.blood_layer().show_death('resident:'+id,position)
 if r.hp<=0:
  arena.inventory.move(arena.state,r.weapon_instance,'ground');collision_layer=0
func _physics_process(dt):
 var r:=data()
 if r.is_empty() or r.hp<=0:visible=false;return
 if not arena.running:return
 invulnerable=maxf(0,invulnerable-dt);cooldown=maxf(0,cooldown-dt)
 charge_sound_left=maxf(0,charge_sound_left-dt)
 var weapon:Dictionary=arena.state.items[r.weapon_instance]
 if weapon.energy<1:returning=true
 if returning:
  var destination:Vector2=arena.station+arena.grid.logical_vector_to_world(Vector2(0,90))
  if position.distance_to(destination)>12:velocity=arena.walk_direction(position,destination)*90
  else:
   velocity=Vector2.ZERO
   if arena.station_active():
    var moved:float=EnergyService.transfer(arena.state.base.energy_store,weapon,30*dt)
    if moved>0 and charge_sound_left<=0:
     arena.emit_sfx('charge_in',position,true,id);charge_sound_left=1.0
   if weapon.energy>=weapon.capacity:returning=false
 else:
  velocity=arena.walk_direction(position,post)*90 if position.distance_to(post)>12 else Vector2.ZERO
  var enemy=arena.nearest_enemy(position,350)
  if enemy!=null and cooldown<=0 and weapon.energy>=1:
   weapon.energy-=1;arena.fire_base(position,enemy.position,15,false);cooldown=0.35
   arena.emit_sfx('shot_rifle',position,true,id)
 move_and_slide()
 var logical:Vector2=arena.grid.world_to_logical(position)
 logical.x=minf(logical.x,1115);position=arena.grid.logical_to_world(logical)
 r.weapon_energy=weapon.energy;r.position=[position.x,position.y]



