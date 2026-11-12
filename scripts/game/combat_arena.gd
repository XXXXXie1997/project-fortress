extends Node2D
signal presentation_sound(event: String, world_position: Vector2, spatial: bool, source_id: String)

func emit_sfx(event: String, point: Vector2, spatial := false, source_id := "player") -> void:
 presentation_sound.emit(event, point, spatial, source_id)
var session_context: Dictionary = {}
var state: Dictionary
var inventory: InventoryService
var config: Dictionary
var weapons:Dictionary
var player: CharacterBody2D
var targets: Array[Node2D] = []
var hud: CanvasLayer
var floor_atlas:AtlasTexture
var capture_frames:=0
var station := Vector2(180,280)
func _ready():
 if not session_context.is_empty():
  await preload('res://scripts/game/session/world_mount.gd').mount(self,'combat')
  return
 InputBindings.install()
 texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 floor_atlas=AtlasTexture.new();floor_atlas.atlas=load('res://assets/runtime/environment/dungeon.png');floor_atlas.region=Rect2(0,64,16,16)
 config=JSON.parse_string(FileAccess.get_file_as_string('res://data/combat.json'))
 weapons=preload('res://scripts/content/catalog.gd').weapons()
 state=WorldState.fresh()
 inventory=InventoryService.new(preload('res://scripts/content/catalog.gd').items())
 inventory.setup(state)
 state.base.energy_store.energy=600.0
 for pair in [['backpack_small','backpack'],['rifle_basic','weapon_1'],['knife_basic','weapon_2'],['armor_basic','armor']]:
  var id: String=inventory.spawn(state,pair[0],'ground').id
  inventory.equip(state,id,pair[1],true)
 for i in range(3):
  var id: String=inventory.spawn(state,'battery_basic','bag').id
  state.items[id].energy=100.0
 inventory.spawn(state,'medical_needle','bag',5)
 for plugin_type in ['light','laser','launcher']:
  var plugin:Dictionary=inventory.spawn(state,'tactical_'+plugin_type,'ground')
  state.items[plugin.id].energy=100.0
  if plugin_type=='light':
   state.items[plugin.id].container_id='plugin'
   state.items[state.player.equipment.weapon_1].plugins.tactical=plugin.id
 state.player.quick[0]='medical_needle'
 state.player.vitals={'hp':100.0,'max_hp':100.0}
 state.player.combat=ActionRules.fresh(config)
 state.world.combat_targets={}
 for rect in [Rect2(0,0,1440,32),Rect2(0,960,1440,32),Rect2(0,0,32,960),Rect2(1408,0,32,960),Rect2(650,250,48,320)]:wall(rect)
 wall(Rect2(850,600,150,24),true)
 for p in [Vector2(780,180),Vector2(930,400),Vector2(550,650)]:
  var target=StaticBody2D.new()
  target.position=p;target.collision_layer=4;target.collision_mask=2
  var shape=CollisionShape2D.new();var circle=CircleShape2D.new();circle.radius=18;shape.shape=circle
  target.name='Target%d'%targets.size();target.add_child(shape);target.set_meta('hp',100.0);add_child(target);targets.append(target)
  state.world.combat_targets[str(target.name)]={'vitals':{'hp':100.0,'max_hp':100.0},'action':ActionRules.fresh(config),'armor':{}}
 player=load('res://scripts/game/player_actor.gd').new();player.arena=self;player.position=Vector2(320,360);add_child(player)
 hud=load('res://scripts/ui/combat_hud.gd').new();hud.arena=self;add_child(hud)
func wall(rect:Rect2,low:bool=false):
 var node=StaticBody2D.new();node.position=rect.get_center();node.collision_layer=8 if low else 1
 var shape=CollisionShape2D.new();var box=RectangleShape2D.new();box.size=rect.size;shape.shape=box;node.add_child(shape)
 var visual=Polygon2D.new();visual.polygon=PackedVector2Array([-box.size/2,Vector2(box.size.x,-box.size.y)/2,box.size/2,Vector2(-box.size.x,box.size.y)/2]);visual.color=Color('465360');node.add_child(visual)
 var occluder=LightOccluder2D.new();var polygon=OccluderPolygon2D.new();polygon.polygon=visual.polygon;occluder.occluder=polygon;node.add_child(occluder);add_child(node)
func clear_line(a:Vector2,b:Vector2,mask:int=9)->bool:
 var query:=PhysicsRayQueryParameters2D.create(a,b,mask);query.hit_from_inside=true
 return get_world_2d().direct_space_state.intersect_ray(query).is_empty()
func hit(target:Node2D,damage:float,attack:Dictionary={},direction:Vector2=Vector2.ZERO):
 # Only explicitly registered fixture targets use this fallback. Formal map
 # obstacles have no damage record and must not create fixture world state.
 var fixture_targets:Dictionary=state.get('world',{}).get('combat_targets',{})
 if not is_instance_valid(target) or not fixture_targets.has(str(target.name)):return
 var record:Dictionary=fixture_targets[str(target.name)]
 var packet:Dictionary=attack.duplicate();packet.damage=damage
 var result:Dictionary=DamageRules.hit(record.vitals,record.action,record.armor,packet,config,'enemy')
 if result.hp_loss>0 or result.armor_loss>0:emit_sfx('melee_hit' if packet.get('sfx_melee',false) else 'hit_enemy',target.position,true,str(target.name))
 target.set_meta('hp',record.vitals.hp)
 if record.vitals.hp<=0:target.collision_layer=0
 if result.knockback>0 and direction!=Vector2.ZERO:
  var end:Vector2=target.position+direction.normalized()*result.knockback
  var collision=get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(target.position,end,9))
  target.position=collision.position+collision.normal*20 if not collision.is_empty() else end
func _process(_dt):
 queue_redraw()
 capture_frames+=1
 if '--capture' in OS.get_cmdline_user_args() and capture_frames==30:
  await RenderingServer.frame_post_draw
  get_viewport().get_texture().get_image().save_png('res://scenes/game/dev102-window.png')
  get_tree().quit()
func _draw():
 draw_rect(Rect2(0,0,1440,992),Color('202f35'))
 if floor_atlas!=null:
  for y in range(0,960,48):
   for x in range(0,1440,48):draw_texture_rect(floor_atlas,Rect2(x,y,48,48),false,Color(0.6,0.7,0.75))
 draw_circle(station,80,Color(0.1,0.6,0.7,0.15));draw_rect(Rect2(station-Vector2(18,22),Vector2(36,44)),Color('56c5cb'))
 for target in targets:
  if target.has_method('record'):continue
  if player!=null and not clear_line(player.global_position,target.position):continue
  draw_circle(target.position,18,Color('d18b67') if target.get_meta('hp')>0 else Color('3d4142'))
  draw_line(target.position+Vector2(-20,-30),target.position+Vector2(-20+40*target.get_meta('hp')/100,-30),Color('d36868'),4)









