extends RefCounted
# Ground collision remains on the actor. These areas are projectile-only silhouettes.
static func install(actor:Node2D,layer:int,center:Vector2,size:Vector2):
 var area:=Area2D.new();area.name='ProjectileBody';area.collision_layer=layer;area.collision_mask=0
 area.monitoring=false;area.set_meta('damage_owner',actor)
 var shape:=CollisionShape2D.new();var capsule:=CapsuleShape2D.new()
 capsule.radius=size.x*0.5;capsule.height=maxf(size.y,size.x);shape.shape=capsule;shape.position=center
 area.add_child(shape);actor.add_child(area)
static func ray(node:Node2D,start:Vector2,end:Vector2,mask:int)->Dictionary:
 var query:=PhysicsRayQueryParameters2D.create(start,end,mask);query.collide_with_areas=true;query.hit_from_inside=true
 while true:
  var result:=node.get_world_2d().direct_space_state.intersect_ray(query)
  if result.is_empty():return result
  if not result.collider.has_meta('damage_owner'):return result
  var actor:Node2D=result.collider.get_meta('damage_owner')
  if actor.collision_layer!=0:
   result.collider=actor
   return result
  var excluded:=query.exclude;excluded.append(result.collider.get_rid());query.exclude=excluded
 return {}

static func center(actor:Node2D)->Vector2:
 var body:=actor.get_node_or_null('ProjectileBody')
 return actor.global_position if body==null else body.get_child(0).global_position
static func safe_muzzle(actor:Node2D,muzzle:Vector2)->Vector2:
 var body:=actor.get_node_or_null('ProjectileBody')
 var targets:=256 if body!=null and body.collision_layer in [128,512] else 128+512
 # Ground-to-barrel guards against projecting the muzzle through a wall.
 var query:=PhysicsRayQueryParameters2D.create(actor.global_position,muzzle,1+8+32)
 query.hit_from_inside=true
 if actor is CollisionObject2D:query.exclude=[actor.get_rid()]
 var hit:=actor.get_world_2d().direct_space_state.intersect_ray(query)
 if not hit.is_empty():return hit.position+actor.global_position.direction_to(muzzle)*0.2
 # Shoulder-to-barrel catches a body closer than the end of a long weapon.
 var origin:=center(actor)
 if actor.get('visual')!=null and actor.visual.has_method('muzzle_position'):origin=actor.visual.to_global(Vector2(0,-9))
 if actor.has_method("aim_origin"):origin=actor.aim_origin()
 var body_hit:=ray(actor,origin,muzzle,targets)
 return body_hit.position+origin.direction_to(muzzle)*0.2 if not body_hit.is_empty() else muzzle
