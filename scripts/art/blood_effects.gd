extends Node2D
# Scene-local, read-only presentation. No RNG, services or saved-state writes.
const MAX_BURSTS:=24
const MAX_STAINS:=64
var bursts:Array=[]
var stains:Dictionary={}
var corpses:Dictionary={}
var arena:Node2D
func _ready():y_sort_enabled=true
func restore_dead(id:String,point:Vector2,kind:String)->void:
 show_death(id,point)
 if corpses.has(id) or corpses.size()>=MAX_STAINS:return
 var v=load('res://scripts/art/enemy_visual.gd').new();v.kind=kind;v.action='dead';v.position=point
 add_child(v);corpses[id]=v
func can_show(point:Vector2)->bool:
 return arena==null or (arena.clear_line(arena.player.global_position,point,1) and arena.perceived_brightness(point)>0.12)
func sprite(frame:int)->Sprite2D:
 var s:=Sprite2D.new();s.texture=load('res://assets/runtime/effects/blood/blood.png')
 s.hframes=2;s.vframes=2;s.frame=frame;s.scale=Vector2(3,3)
 s.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 return s
func show_hit(hp_loss:float,point:Vector2,direction:Vector2=Vector2.ZERO)->void:
 if hp_loss<=0:return
 while bursts.size()>=MAX_BURSTS:bursts.pop_front().node.queue_free()
 var s:=sprite(bursts.size()%2);s.position=point+Vector2(0,-24);add_child(s)
 bursts.append({'node':s,'age':0.0,'motion':direction.normalized()*28})
func show_death(stable_id:String,point:Vector2)->void:
 if stable_id.is_empty() or stains.has(stable_id):return
 # Retain first bounded IDs so repeated restoration cannot churn duplicates.
 if stains.size()>=MAX_STAINS:return
 var s:=sprite(2+stains.size()%2);s.position=point+Vector2(0,-1);s.offset=Vector2(0,2);add_child(s)
 stains[stable_id]=s
func clear_effects()->void:
 for b in bursts:b.node.queue_free()
 for s in stains.values():s.queue_free()
 for c in corpses.values():c.queue_free()
 bursts.clear();stains.clear();corpses.clear()
func _process(dt:float)->void:
 for s in stains.values():s.visible=can_show(s.global_position)
 for c in corpses.values():c.visible=can_show(c.global_position)
 for i in range(bursts.size()-1,-1,-1):
  var b:Dictionary=bursts[i];b.age+=dt
  b.node.visible=can_show(b.node.global_position)
  b.node.position+=b.motion*dt;b.node.modulate.a=1.0-b.age/0.22
  if b.age>=0.22:b.node.queue_free();bursts.remove_at(i)


