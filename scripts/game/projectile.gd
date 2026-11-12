extends Node2D
var direction:=Vector2.RIGHT
var speed:=700.0
var damage:=15.0
var arena:Node2D
var lifetime:=2.0
var hostile:=false
var attack:Dictionary={}
var map_context:=''
func _ready():
 add_to_group('combat_map_transients')
 if arena.has_method('combat_context'):map_context=arena.combat_context()
func _physics_process(dt):
 if arena.has_method('combat_context') and map_context!=arena.combat_context():
  set_physics_process(false);queue_free();return
 var end:Vector2=global_position+direction*speed*dt
 var result=get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(global_position,end,11 if hostile else 13))
 if not result.is_empty():
  if hostile and result.collider.has_method('receive_damage'):result.collider.receive_damage(damage,direction)
  else:arena.hit(result.collider,damage,attack,direction)
  queue_free()
 else:global_position=end
 lifetime-=dt
 if lifetime<=0:queue_free()
func _draw():draw_line(-direction*8,Vector2.ZERO,Color('ff9673') if hostile else Color('83efff'),3)



