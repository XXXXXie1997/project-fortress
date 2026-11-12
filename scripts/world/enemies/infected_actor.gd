extends CharacterBody2D
var arena:Node2D
var enemy_id:String
var kind:String
var spec:Dictionary
var home:Vector2
var path:PackedVector2Array=[]
var path_timer:=0.0
var push:=Vector2.ZERO
var art_visual:Node2D
func record()->Dictionary:
 return arena.state.expedition.maps[arena.state.expedition.map_id].enemies[enemy_id].ai
func _ready():
 collision_layer=4;collision_mask=11
 var shape=CollisionShape2D.new();var circle=CircleShape2D.new();circle.radius=spec.radius;shape.shape=circle;add_child(shape)
 set_meta('hp',spec.hp)
 art_visual=load('res://scripts/art/enemy_visual.gd').new();art_visual.kind=kind;add_child(art_visual)
func _process(_dt):
 if art_visual==null:return
 var r:Dictionary=record()
 art_visual.visible=visible_to_player()
 if velocity.length_squared()>1:art_visual.facing=velocity.normalized()
 if r.vitals.hp<=0:art_visual.action='dead'
 elif r.attack_left>0 or r.call_left>0:art_visual.action='windup'
 elif r.cooldown>maxf(0.0,float(spec.interval)-0.12):art_visual.action='strike'
 elif velocity.length_squared()>1:art_visual.action='walk'
 else:art_visual.action='idle'
func see_player()->bool:
 return global_position.distance_to(arena.player.global_position)<arena.ai_config.vision_range and arena.clear_line(global_position,arena.player.global_position,1)
func hear(source:Vector2,already_alert:bool=false):
 var r:Dictionary=record()
 if r.vitals.hp<=0:return
 r.last_known=[source.x,source.y];r.search_left=arena.ai_config.search_seconds
 if already_alert:r.alerted=true;r.meter=1.0
 r.mode='search' if r.alerted else 'investigate'
func struck(source:Vector2):
 var r:Dictionary=record()
 hear(source,true)
 if r.call_left>0:r.call_left=0.0;r.call_retry=3.0
func reset_boss(saved_record:Dictionary={}):
 var r:Dictionary=record() if saved_record.is_empty() else saved_record
 global_position=home
 r.vitals.hp=spec.hp;r.armor.durability=spec.armor
 r.mode='idle';r.meter=0.0;r.alerted=false
 r.attack_left=0.0;r.search_left=0.0;r.cooldown=0.0
 r.call_left=0.0;r.call_retry=0.0;r.lost_time=0.0
 r.position=[home.x,home.y];r.last_known=r.position.duplicate()
 r.attack_position=r.position.duplicate();r.call_position=r.position.duplicate()
 # Preserve `called`: a successful call remains once per enemy lifetime.
 r.action=ActionRules.fresh(arena.config)
 velocity=Vector2.ZERO;push=Vector2.ZERO;path.clear();path_timer=0.0
 set_meta('hp',r.vitals.hp);queue_redraw()
func _physics_process(dt):
 var r:Dictionary=record()
 if r.vitals.hp<=0:collision_layer=0;velocity=Vector2.ZERO;queue_redraw();return
 arena.telemetry.perception+=1
 var player_position:Vector2=arena.player.global_position
 if spec.get('boss',false) and (player_position.distance_to(home)>spec.leash or global_position.distance_to(home)>spec.leash):
  reset_boss()
  return
 var sees:bool=see_player() and arena.state.player.vitals.hp>0
 r.cooldown=maxf(0,r.cooldown-dt);r.call_retry=maxf(0,r.call_retry-dt)
 if sees:
  r.lost_time=0.0;r.last_known=[player_position.x,player_position.y];r.search_left=arena.ai_config.search_seconds
  if not r.alerted:
   var distance_factor:float=1.0-global_position.distance_to(player_position)/arena.ai_config.vision_range
   r.meter=minf(1.0,r.meter+dt/arena.ai_config.alert_seconds*(0.25+distance_factor)*arena.illumination_at(player_position)*arena.state.player.vitals.get('visual_accumulation_factor',1.0))
   if r.meter>=1:r.alerted=true
  if r.alerted:r.mode='attack'
 else:
  r.lost_time+=dt
  if not r.alerted and r.lost_time>arena.ai_config.decay_delay:r.meter=maxf(0,r.meter-dt*arena.ai_config.decay_rate)
  if r.mode!='idle':
   r.search_left=maxf(0,r.search_left-dt)
   r.mode='search' if r.alerted else 'investigate'
   if r.search_left<=0:r.mode='idle';r.alerted=false;r.meter=0.0
 if r.call_left>0:
  r.call_left-=dt
  if r.call_left<=0:
   r.called=true;arena.broadcast_call(self,Vector2(r.call_position[0],r.call_position[1]))
 elif r.alerted and sees and spec.get('call',false) and not r.called and r.call_retry<=0:
  r.call_left=arena.ai_config.call_windup;r.call_position=r.last_known.duplicate()
 if r.attack_left>0:
  r.attack_left-=dt
  if r.attack_left<=0:
   resolve_attack(Vector2(r.attack_position[0],r.attack_position[1]));r.cooldown=spec.interval
 elif r.alerted and sees and global_position.distance_to(player_position)<=spec.range and r.cooldown<=0 and r.call_left<=0:
  r.attack_left=spec.windup;r.attack_position=[player_position.x,player_position.y]
 var direction:=Vector2.ZERO
 if r.mode!='idle' and r.attack_left<=0 and r.call_left<=0:
  var goal:=Vector2(r.last_known[0],r.last_known[1])
  if global_position.distance_to(goal)>spec.range*0.75 or not sees:
   path_timer-=dt
   if path_timer<=0:path=arena.find_path(global_position,goal);path_timer=0.35+float(get_instance_id()%10)*0.02
   while not path.is_empty() and global_position.distance_to(path[0])<14:path.remove_at(0)
   if not path.is_empty():direction=global_position.direction_to(path[0])
 var separation:Vector2=arena.separation(self)
 velocity=(direction*spec.speed+separation*40+push)
 push=push.move_toward(Vector2.ZERO,500*dt)
 if r.mode!='idle':arena.telemetry.engaged+=1
 if velocity.length()>1:arena.telemetry.moving+=1
 move_and_slide()
 r.position=[position.x,position.y]
 set_meta('hp',r.vitals.hp);queue_redraw()
func resolve_attack(aim_position:Vector2):
 arena.telemetry.attacks_total+=1
 if spec.get('ranged',false):
  var bullet=load('res://scripts/game/projectile.gd').new();bullet.arena=arena;bullet.hostile=true;bullet.speed=240;bullet.damage=spec.damage;bullet.position=position;bullet.direction=position.direction_to(aim_position);arena.add_child(bullet)
 elif position.distance_to(arena.player.position)<=spec.range and position.direction_to(aim_position).dot(position.direction_to(arena.player.position))>0.3 and arena.clear_line(position,arena.player.position):
  arena.player.receive_attack({'damage':spec.damage,'penetration':2.0,'knockback':45.0},position.direction_to(arena.player.position))
func visible_to_player()->bool:
 var screen:Vector2=get_global_transform_with_canvas()*Vector2.ZERO
 return get_viewport_rect().has_point(screen) and arena.clear_line(arena.player.global_position,global_position,1) and arena.perceived_brightness(global_position)>0.12
func _draw():
 if not visible_to_player():return
 var r:Dictionary=record()
 if r.vitals.hp<=0:return
 draw_line(Vector2(-22,-spec.radius-10),Vector2(-22+44*r.vitals.hp/spec.hp,-spec.radius-10),Color.RED,3)
 if spec.armor>0:draw_line(Vector2(-22,-spec.radius-15),Vector2(-22+44*r.armor.durability/spec.armor,-spec.radius-15),Color.LIGHT_BLUE,2)
 if not r.alerted and r.meter>0:draw_arc(Vector2.ZERO,spec.radius+5,-PI/2,-PI/2+TAU*r.meter,24,Color.YELLOW,2)
 if r.attack_left>0 or r.call_left>0:draw_arc(Vector2.ZERO,spec.radius+8,0,TAU,24,Color.ORANGE,3)


