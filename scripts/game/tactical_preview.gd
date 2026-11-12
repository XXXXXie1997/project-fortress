extends Node2D
var actor:CharacterBody2D
var enabled:=false
var mode:=0
var selected_weapon:=''
var light:=PointLight2D.new()
var landing:=Vector2.ZERO
var flight:=0.0
var flight_start:=Vector2.ZERO
var destination:=Vector2.ZERO
var pulse:=0.0
var map_context:=''
var fixture_shortcuts_enabled:=false
var flight_damage_factor:=1.0
func fixture_shortcuts_allowed()->bool:
 return fixture_shortcuts_enabled and actor!=null and actor.arena.session_context.is_empty()
func reset_map_effects():
 flight=0.0;pulse=0.0;flight_start=Vector2.ZERO;destination=Vector2.ZERO;landing=Vector2.ZERO
 light.enabled=false
 queue_redraw()
func ensure_map_context()->bool:
 if not actor.arena.has_method('combat_context'):return true
 var current:String=canonical_context(actor.arena.combat_context())
 map_context=canonical_context(map_context)
 if current!=map_context:
  reset_map_effects();map_context=current
 return actor.arena.combat_map_ready()
func canonical_context(value:String)->String:
 # JSON restores integer expedition IDs as floats. That is the same expedition,
 # not a map transition; retain in-flight effects across both old encodings.
 var parts:=value.split('|',true,1)
 if parts.size()==2 and parts[0].is_valid_float():
  var number:=parts[0].to_float()
  if is_finite(number) and number==floor(number):return str(int(number))+'|'+parts[1]
 return value
func battery()->Dictionary:
 var weapon:Dictionary=actor.item()
 return actor.arena.state.items.get(weapon.get('plugins',{}).get('tactical',''),{})
func _process(dt):
 if actor==null:return
 if not ensure_map_context():return
 sync()
 pulse=maxf(0,pulse-dt)
 if flight>0:
  flight-=dt
  if flight<=0:explode(destination)
 landing=clamp_landing(get_global_mouse_position())
 light.global_position=actor.global_position
 light.rotation=(get_global_mouse_position()-actor.global_position).angle()
 light.enabled=enabled and mode==0 and battery().get('energy',0)>0
 var power:Dictionary=battery()
 if enabled and mode<2 and not power.is_empty():power.energy=maxf(0,power.energy-dt*0.02)
 queue_redraw()
func fire()->bool:
 if not ensure_map_context():return false
 if not enabled or mode!=2 or flight>0 or battery().is_empty():return false
 var item:Dictionary=actor.item()
 if item.get('energy',0)<15 or item.get('durability',0)<=0:return false
 var spec:Dictionary=actor.arena.weapons.get(item.get('definition_id',''),{})
 flight_damage_factor=WeaponRules.durability_factor(item,spec)
 item.energy-=15
 WeaponRules.wear_after_attack(item,spec,actor.effective_config())
 actor.arena.emit_sfx('shot_heavy',actor.global_position,false,'player_launcher')
 destination=landing;flight_start=actor.global_position;flight=0.5
 return true
func explode(center:Vector2):
 if not ensure_map_context():return
 actor.arena.emit_sfx('explosion',center,true,'player_explosion')
 if actor.arena.has_method('emit_player_noise'):actor.arena.emit_player_noise('explosion',center)
 pulse=0.2;destination=center
 for target in actor.arena.targets:
  var distance:float=center.distance_to(target.global_position)
  if distance<=120 and actor.arena.clear_line(center,target.global_position):actor.arena.hit(target,(45 if distance<55 else 20)*flight_damage_factor,{'penetration':10.0,'knockback':20.0},target.position-center)
 var distance:float=center.distance_to(actor.global_position)
 if distance<=120 and actor.arena.clear_line(center,actor.global_position):
  actor.receive_attack({'damage':(45 if distance<55 else 20)*flight_damage_factor,'penetration':10},actor.global_position-center,true)
func polygon(center:Vector2,radius:float)->PackedVector2Array:
 var points:=PackedVector2Array()
 for i in range(64):
  var end:=center+Vector2.from_angle(TAU*i/64)*radius
  var query=PhysicsRayQueryParameters2D.create(center,end,9);query.hit_from_inside=true
  var result=get_world_2d().direct_space_state.intersect_ray(query)
  points.append(to_local(result.position if not result.is_empty() else end))
 return points
func _draw():
 if actor==null:return
 if actor.arena.has_method('combat_map_ready') and not actor.arena.combat_map_ready():return
 if enabled and not battery().is_empty():
  var start:=to_local(actor.global_position)
  var aim:Vector2=(landing-actor.global_position).normalized()
  if mode==2:
   draw_colored_polygon(polygon(landing,120),Color(1,0.55,0.15,0.15))
   draw_colored_polygon(polygon(landing,55),Color(1,0.25,0.1,0.25))
  elif battery().get('energy',0)>0:
   if mode==1:
    var end:Vector2=actor.global_position+aim*600
    var result=get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(actor.global_position,end,13))
    draw_line(start,to_local(result.position if not result.is_empty() else end),Color(0.8,0.1,0.1,0.7),1)
   else:
    var cone:=PackedVector2Array([start])
    for i in range(21):
     var end:Vector2=actor.global_position+aim.rotated(-0.35+i*0.035)*260
     var result=get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(actor.global_position,end,1))
     cone.append(to_local(result.position if not result.is_empty() else end))
    draw_colored_polygon(cone,Color(1,0.9,0.6,0.18))
 if flight>0:
  var t:=1-flight/0.5
  draw_circle(to_local(flight_start.lerp(destination,t))+Vector2(0,-100*sin(t*PI)),6,Color.ORANGE)
 if pulse>0:draw_colored_polygon(polygon(destination,120),Color(1,0.4,0.05,pulse*2))




func sync():
 var weapon:Dictionary=actor.item()
 enabled=weapon.get('tactical_enabled',false)
 var definition:Dictionary=actor.arena.inventory.definitions.get(battery().get('definition_id',''),{})
 mode=['light','laser','launcher'].find(definition.get('tactical_type',''))
func toggle():
 if actor.item().is_empty() or battery().is_empty():return
 actor.item().tactical_enabled=not actor.item().get('tactical_enabled',false)
 sync()
func install_next_fixture():
 if not fixture_shortcuts_allowed():return
 if actor.item().is_empty() or actor.arena.inventory.definitions[actor.item().definition_id].category!='ranged':return
 var next_type:String=['light','laser','launcher'][(mode+1)%3]
 for entry in actor.arena.state.items.values():
  if entry.definition_id=='tactical_'+next_type:
   install_fixture_plugin(entry.id)
   return

# Test-station replacement is still an atomic ownership transaction. Never leave
# a selected plugin referenced by its previous weapon, even between callbacks.
func install_fixture_plugin(plugin_id:String)->bool:
 if not fixture_shortcuts_allowed():return false
 var state:Dictionary=actor.arena.state
 var weapon_id:String=actor.item().get('id','')
 if not state.items.has(plugin_id) or not state.items.has(weapon_id):return false
 var definition:Dictionary=actor.arena.inventory.definitions.get(state.items[plugin_id].definition_id,{})
 if definition.get('category','')!='plugin' or not definition.has('tactical_type'):return false
 var trial:Dictionary=state.duplicate(true)
 var previous_id:String=trial.items[weapon_id].plugins.get('tactical','')
 for parent:Dictionary in trial.items.values():
  for slot:String in parent.plugins.keys():
   if parent.plugins[slot]==plugin_id:parent.plugins[slot]=''
 trial.items[weapon_id].plugins.tactical=plugin_id
 trial.items[plugin_id].container_id='plugin'
 if previous_id!=plugin_id and trial.items.has(previous_id):
  var still_owned:=false
  for parent:Dictionary in trial.items.values():
   if previous_id in parent.plugins.values():still_owned=true
  if not still_owned:trial.items[previous_id].container_id='ground'
 InventoryService.commit(state,trial)
 sync()
 return true
func clamp_landing(point:Vector2)->Vector2:
 var query=PhysicsRayQueryParameters2D.create(actor.global_position,point,1);query.hit_from_inside=true
 var collision=get_world_2d().direct_space_state.intersect_ray(query)
 return collision.position+collision.normal*2 if not collision.is_empty() else point
func _ready():
 var mask=Image.create(128,128,false,Image.FORMAT_RGBA8)
 for y in range(128):
  for x in range(64,128):
   var offset=Vector2(x-64,y-64)
   if absf(offset.angle())<0.35 and offset.length()<64:
    mask.set_pixel(x,y,Color(1,1,1,1-offset.length()/64))
 light.texture=ImageTexture.create_from_image(mask);light.texture_scale=5.0;light.color=Color(1,0.93,0.7);light.energy=1.4;light.shadow_enabled=true;add_child(light)



