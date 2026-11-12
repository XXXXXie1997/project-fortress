extends StaticBody2D
var arena:Node2D
var id:String
var kind:String
var cooldown:=0.0
var logical_rect:Rect2
var footprint:=PackedVector2Array()
var art_visual:Node2D
var charge_sound_left:=0.0
var retired:=false
# Layout transactions replace/delete the authoritative instance before queue_free runs.
# Retire all callback/physics surfaces immediately; never fabricate fallback building data.
func retire() -> void:
 if retired:return
 retired=true
 process_mode=Node.PROCESS_MODE_DISABLED
 set_process(false);set_physics_process(false)
 collision_layer=0;collision_mask=0
 hide()
 if is_instance_valid(arena):arena.fixtures.erase(self)
 queue_free()
func live_instance() -> bool:
 if retired:return false
 if not is_instance_valid(arena):
  retire();return false
 if kind!='shield' and not arena.state.base.buildings.has(id):
  retire();return false
 return true
func data()->Dictionary:
 return arena.state.base.shield if kind=='shield' else arena.state.base.buildings[id]
func _ready():
 collision_layer=16 if kind=='shield' else 32
 collision_mask=4
 for point in arena.grid.rect_polygon(logical_rect):footprint.append(point-position)
 var shape:=CollisionPolygon2D.new();shape.polygon=footprint;add_child(shape)
 art_visual=load('res://scripts/art/facility_visual.gd').new();art_visual.kind=kind
 art_visual.position=arena.grid.logical_to_world(logical_rect.end)-position
 var width:float=arena.grid.world_bounds(logical_rect).size.x
 art_visual.scale=Vector2.ONE*clampf(width/180.0,0.45,2.0)
 add_child(art_visual)
func _process(_dt):
 if not live_instance() or art_visual==null:return
 var d:=data()
 art_visual.alive=d.energy>0 if kind=='shield' else d.durability>0
 if kind=='turret' and art_visual.alive:
  var target=arena.nearest_enemy(position,360)
  if target!=null:art_visual.aim=position.direction_to(target.position)
func receive_damage(amount:float,_direction:Vector2=Vector2.ZERO):
 if not live_instance():return
 var d:=data()
 if kind=='shield':d.energy=maxf(0,d.energy-amount)
 else:d.durability=maxf(0,d.durability-amount)
func _physics_process(dt):
 if not live_instance():return
 charge_sound_left=maxf(0,charge_sound_left-dt)
 var d:=data()
 var alive:bool=d.energy>0 if kind=='shield' else d.durability>0
 collision_layer=(16 if kind=='shield' else 32) if alive else 0
 if kind=='turret' and alive and arena.running:
  cooldown=maxf(0,cooldown-dt)
  if not d.has('capacitor'):d.capacitor={'energy':0.0,'capacity':60.0}
  if not d.capacitor.has('charging'):d.capacitor.charging=d.capacitor.energy<d.capacitor.capacity
  if d.capacitor.energy<1:d.capacitor.charging=true
  if d.capacitor.charging:
   if arena.station_active():
    var moved:float=EnergyService.transfer(arena.state.base.energy_store,d.capacitor,30*dt)
    if moved>0 and charge_sound_left<=0:
     arena.emit_sfx('charge_in',position,true,id);charge_sound_left=1.0
   if d.capacitor.energy>=d.capacitor.capacity:d.capacitor.charging=false
  elif cooldown<=0:
   var enemy=arena.nearest_enemy(position,360)
   if enemy!=null:
    d.capacitor.energy-=1;arena.fire_base(position,enemy.position,18,false);cooldown=0.25
    arena.emit_sfx('shot_rifle',position,true,id)
 queue_redraw()
func _draw():
 if not live_instance():return
 var d:=data()
 var alive:bool=d.energy>0 if kind=='shield' else d.durability>0
 var color:=Color('68dbed') if kind=='shield' else Color('7c969d')
 if not alive:color=Color('3c3031')
 draw_colored_polygon(footprint,color.darkened(0.35))
 var title:String={'warehouse':'仓库能源站','generator':'发电厂','technology':'科技终端','quest':'任务终端','workstation':'工作站','trade':'贸易站','farm':'农田','turret':'炮塔','shield':'防护罩'}.get(kind,'设施')
 draw_string(ThemeDB.fallback_font,Vector2(-24,-40),title,HORIZONTAL_ALIGNMENT_LEFT,-1,12)
 if kind!='shield':draw_line(Vector2(-25,-48),Vector2(-25+50*d.durability/d.maximum,-48),Color.GREEN,3)

