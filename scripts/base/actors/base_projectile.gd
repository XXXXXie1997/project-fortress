extends Node2D
var arena:Node2D
var direction:=Vector2.RIGHT
var damage:=10.0
var hostile:=false
var life:=3.0
func _physics_process(dt):
 if not arena.running:queue_free();return
 var end:Vector2=position+direction*420*dt
 var mask:=1+2+16+32+64 if hostile else 1+4+32
 var hit:=get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(position,end,mask))
 if not hit.is_empty():
  if hostile and hit.collider.has_method('receive_damage'):hit.collider.receive_damage(damage,direction)
  elif not hostile:arena.hit(hit.collider,damage,{'penetration':20.0},direction)
  queue_free()
 else:position=end
 life-=dt
 if life<=0:queue_free()
func _draw():draw_line(-direction*8,Vector2.ZERO,Color.ORANGE if hostile else Color.CYAN,3)



