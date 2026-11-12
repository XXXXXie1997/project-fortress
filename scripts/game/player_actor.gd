extends CharacterBody2D
var growth_bridge:=preload('res://scripts/progression/effect_bridge.gd').new()
var progression_panel:CanvasLayer
var progression_ui_blocked:=false
var progression_pointer_guard:=false
var arena:Node2D
var camera:=Camera2D.new()
var visual:Node2D
var slot:=1
var cooldown:=0.0
var bloom:=0.0
var heals:Array=[]
var tactical:Node2D
var sprint_latched:=false
var inventory_movement_locked:=false
var selected_charge_battery:=""
var selected_charge_target:=""
var footstep_distance:=0.0
func _ready():
 # Apply visibility after the art component has updated its own animation frame.
 process_priority=10
 collision_layer=2;collision_mask=13
 var shape=CollisionShape2D.new();var circle=CircleShape2D.new();circle.radius=12;shape.shape=circle;add_child(shape)
 visual=load('res://scripts/art/survivor_visual.gd').new();visual.scale=Vector2(3,3);add_child(visual);add_child(camera)
 visual.process_priority=0
 tactical=load('res://scripts/game/tactical_preview.gd').new();tactical.actor=self;arena.add_child.call_deferred(tactical)
 progression_panel=load('res://scripts/ui/progression/progression_panel.gd').new();progression_panel.actor=self;add_child.call_deferred(progression_panel)
func item()->Dictionary:
 return arena.state.items.get(arena.state.player.equipment['weapon_%d'%slot],{})
func _unhandled_input(event):
 if progression_ui_blocked:return
 var s:Dictionary=arena.state.player.combat
 if arena.hud!=null and (arena.hud.opened or (arena.hud.inventory_panel!=null and arena.hud.inventory_panel.visible)):return
 if event.is_action_pressed('weapon_next') or event.is_action_pressed('weapon_previous'):
  var previous_id:String=item().get('id','')
  slot=posmod(slot-1+(1 if event.is_action_pressed('weapon_next') else -1),3)+1;ActionRules.switch_weapon(s);tactical.sync()
  if item().get('id','')!=previous_id:arena.emit_sfx('weapon_switch',global_position)
 if event.is_action_pressed('sprint') and arena.hud.sprint_toggle:sprint_latched=not sprint_latched
 if event.is_action_pressed('tactical'):tactical.toggle()
 if event.is_action_pressed('interact') and tactical.fixture_shortcuts_allowed() and global_position.distance_to(arena.station)<80:tactical.install_next_fixture()
 if event.is_action_pressed('charge') and not item().is_empty():s.charging=not s.charging
 if event.is_action_pressed('dodge'):
  if ActionRules.dodge(s,Input.get_vector('move_left','move_right','move_up','move_down'),get_global_mouse_position()-global_position,effective_config(),action_stamina_factor()):arena.emit_sfx('dodge',global_position)
 for i in range(6):
  if event.is_action_pressed('quick_%d'%(i+1)):
   var type:String=arena.state.player.quick[i]
   if type!='' and arena.inventory.consume(arena.state,type,1):DamageRules.start_heal(heals,arena.inventory.definitions[type].get('heal',{}))
func _physics_process(dt):
 if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):progression_pointer_guard=false
 growth_bridge.observe(arena.state,arena.inventory)
 tactical.sync()
 var s:Dictionary=arena.state.player.combat
 var extras:Array=[]
 for key in arena.state.player.equipment:
  if key.begins_with('extra_') and arena.state.items.has(arena.state.player.equipment[key]):extras.append(arena.state.items[arena.state.player.equipment[key]])
 var effects:Dictionary=WeaponRules.extra_effects(extras,effective_config())
 var burden:Dictionary=encumbrance()
 var stamina_factor:float=effects.stamina_factor*burden.stamina_factor
 var move=Input.get_vector('move_left','move_right','move_up','move_down')
 if inventory_movement_locked:move=Vector2.ZERO
 var aim:Vector2=(get_global_mouse_position()-global_position).normalized()
 var ui_open:bool=progression_ui_blocked or progression_pointer_guard or (arena.hud!=null and (arena.hud.opened or (arena.hud.inventory_panel!=null and arena.hud.inventory_panel.visible)))
 ActionRules.tick(s,dt,effective_config(),Input.is_action_pressed('aim') and not ui_open,(sprint_latched if arena.hud.sprint_toggle else Input.is_action_pressed('sprint')),move!=Vector2.ZERO,false,stamina_factor)
 velocity=move*180.0*ActionRules.movement_factor(s,effective_config())*burden.speed_factor
 if s.dodge_left>0 and not inventory_movement_locked:velocity=Vector2(s.dodge_direction[0],s.dodge_direction[1])*500*burden.speed_factor
 collision_mask=collision_mask_for_action(s.dodge_left>0)
 var before_move:=global_position
 move_and_slide()
 if move!=Vector2.ZERO and s.dodge_left<=0:
  footstep_distance+=global_position.distance_to(before_move)
  if footstep_distance>=48.0:
   footstep_distance=fmod(footstep_distance,48.0);arena.emit_sfx('footstep',global_position)
 var camera_rules=preload('res://scripts/game/aim_camera_rules.gd')
 var view_zoom:float=camera_rules.zoom_for(arena.weapons.get(item().get('definition_id',''),{}),s.aiming)
 camera.zoom=Vector2.ONE*view_zoom
 camera.position=camera_rules.camera_offset(get_viewport().get_mouse_position(),get_viewport_rect().size,view_zoom,s.aiming)
 camera.force_update_scroll()
 aim=(get_global_mouse_position()-global_position).normalized()
 var weapon:Dictionary=item()
 if s.charging and not weapon.is_empty():
  var target_id:String=selected_charge_target if selected_charge_target!="" else weapon.id
  var transferred=ChargingService.charge_weapon(arena.state,target_id,30*dt,selected_charge_battery)
  if transferred<=0 or arena.state.items[target_id].energy>=arena.state.items[target_id].capacity:s.charging=false;selected_charge_target="";selected_charge_battery=""
 ChargingService.wireless(arena.state,dt,15,global_position.distance_to(arena.station)<80,wireless_station_active(),false)
 ChargingService.drain_passives(arena.state,dt,effective_config().extra_drain,false)
 DamageRules.tick_heals(arena.state.player.vitals,heals,dt)
 cooldown=maxf(0,cooldown-dt)
 bloom=WeaponRules.recover_bloom(bloom,effective_config().weapons.rifle,dt)
 if Input.is_action_pressed('fire') and not ui_open and cooldown<=0 and ActionRules.can_attack(s) and not weapon.is_empty():
  var spec:Dictionary=arena.weapons.get(weapon.definition_id,{})
  if spec.is_empty():return
  var melee:bool=spec.kind=='melee'
  var params=WeaponRules.attack_parameters(weapon,spec)
  if tactical.enabled and tactical.mode==2:
   if tactical.fire():cooldown=0.5
   return
  if not params.is_empty():
   if melee:
    if ActionRules.start_melee(s,spec.stamina_cost*stamina_factor,effective_config()):
     weapon.energy-=params.energy_cost
     arena.emit_sfx('melee_swing',global_position)
     params.sfx_melee=true
     for target in arena.targets:
      var offset:Vector2=target.position-global_position
      if offset.length()<spec.range and aim.dot(offset.normalized())>0.4 and arena.clear_line(global_position,target.position):arena.hit(target,params.damage,params,aim)
     cooldown=spec.interval
   else:
    weapon.energy-=params.energy_cost
    arena.emit_sfx('shot_heavy' if spec.get('pellets',1)>1 or spec.interval>=0.5 else ('shot_smg' if spec.interval<0.12 else 'shot_rifle'),global_position)
    if arena.has_method('emit_sound'):arena.emit_sound(global_position)
    params.source_position=[global_position.x,global_position.y]
    for pellet in range(spec.get('pellets',1)):
     var bullet=load('res://scripts/game/projectile.gd').new();bullet.arena=arena;bullet.position=global_position;bullet.damage=params.damage;bullet.attack=params.duplicate()
     var precision:float=growth_bridge.spread_factor(arena.state)*effects.precision_factor*(0.8 if tactical.enabled and tactical.mode==1 and tactical.battery().get('energy',0)>0 else 1.0)
     bullet.direction=aim.rotated(randf_range(-1,1)*WeaponRules.spread(spec,bloom,move!=Vector2.ZERO,s.aiming,precision));arena.add_child(bullet)
    bloom=WeaponRules.after_shot(bloom,spec);cooldown=spec.interval
 sync_visual_state()
 queue_redraw()

func _process(_dt):
 sync_visual_state()

# Read actual equipped IDs every time: inventory transactions replace dictionaries.
# The art component owns animation; this adapter supplies equipment state through
# its existing public fields and child sprites without modifying the art script.
func sync_visual_state():
 if not is_instance_valid(visual) or not is_instance_valid(tactical):return
 var weapon:Dictionary=item()
 var s:Dictionary=arena.state.player.combat
 var spec:Dictionary=arena.weapons.get(weapon.get('definition_id',''),{})
 var plugin:Dictionary=tactical.battery()
 var definition:Dictionary=arena.inventory.definitions.get(plugin.get('definition_id',''),{})
 var attachment_type:int=['light','laser','launcher'].find(definition.get('tactical_type',''))
 var ranged:bool=spec.get('kind','')=='ranged'
 var attached:bool=ranged and attachment_type>=0 and plugin.get('container_id','')=='plugin'
 visual.aim=(get_global_mouse_position()-global_position).normalized()
 visual.moving=velocity.length()>0
 visual.charging=s.charging and ranged
 visual.dodging=s.dodge_left>0
 visual.weapon_index=spec.get('visual',0)
 visual.attachment_index=attachment_type if attached else 0
 visual.attachment.frame=8+visual.attachment_index
 visual.attachment.visible=attached
 var active:bool=weapon.get('tactical_enabled',false) and (attachment_type==2 or plugin.get('energy',0.0)>0.0)
 visual.attachment.self_modulate=Color.WHITE if active else Color(0.65,0.65,0.65)
 visual.weapon.visible=not weapon.is_empty()
 visual.arm.visible=not weapon.is_empty()
 visual.battery.visible=visual.charging
func _draw():
 if arena==null:return
 if cooldown>0 and arena.weapons.get(item().get('definition_id',''),{}).get('kind','')=='melee':
  var angle:float=(get_global_mouse_position()-global_position).angle()
  draw_arc(Vector2.ZERO,90,angle-0.8,angle+0.8,16,Color(0.7,0.95,1,0.4),4)
 var s:Dictionary=arena.state.player.combat
 draw_arc(get_local_mouse_position()+Vector2(0,10),12,0,PI*s.stamina/effective_config().max_stamina,24,Color.RED if s.exhausted else Color.YELLOW,2)




func receive_damage(amount:float,direction:Vector2):
 return receive_attack({'damage':amount,'penetration':2.0,'knockback':100.0},direction)

# All real hit sources share the same aftermath, including explosion self-damage.
func receive_attack(attack:Dictionary,direction:Vector2=Vector2.ZERO,self_hit:bool=false)->Dictionary:
 var state:Dictionary=arena.state
 var armor:Dictionary=state.items.get(state.player.equipment.armor,{})
 var result:Dictionary=DamageRules.hit(state.player.vitals,state.player.combat,armor,attack,effective_config(),'player',self_hit)
 if arena.has_method('show_blood'):arena.show_blood(result.hp_loss,global_position,direction)
 if result.hp_loss>0:arena.emit_sfx('hit_health',global_position)
 elif result.armor_loss>0:arena.emit_sfx('hit_armor',global_position)
 if result.hp_loss>0 or result.armor_loss>0:DamageRules.interrupt_heals(heals)
 if result.knockback>0:velocity+=direction*result.knockback;move_and_slide()
 return result








func request_inventory_charge(target_id:String,battery_id:String):
 if not arena.state.items.has(target_id) or not arena.state.items.has(battery_id):return
 var target:Dictionary=arena.state.items[target_id]
 if target.container_id not in ['bag','equipment'] or target.capacity<=0:return
 if arena.state.items[battery_id].container_id!='bag':return
 selected_charge_target=target_id
 selected_charge_battery=battery_id
 arena.state.player.combat.charging=true

# 场景适配查询；默认探索/操作行为保持不变。
func collision_mask_for_action(is_dodging:bool)->int:
 return 9 if is_dodging else 13
func wireless_station_active()->bool:
 return true

func effective_config()->Dictionary:
 return growth_bridge.apply(arena.state,arena.config)




func encumbrance()->Dictionary:
 return preload('res://scripts/game/encumbrance_rules.gd').current(arena.state,arena.inventory,effective_config())
func action_stamina_factor()->float:
 var extras:Array=[]
 for key in arena.state.player.equipment:
  if key.begins_with('extra_') and arena.state.items.has(arena.state.player.equipment[key]):extras.append(arena.state.items[arena.state.player.equipment[key]])
 return encumbrance().stamina_factor*WeaponRules.extra_effects(extras,effective_config()).stamina_factor

