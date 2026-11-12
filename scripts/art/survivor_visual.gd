extends Node2D

var body := Sprite2D.new()
var pivot := Node2D.new()
var arm := Sprite2D.new()
var weapon := Sprite2D.new()
var battery := Sprite2D.new()
var attachment := Sprite2D.new()
var elapsed := 0.0
var aim := Vector2.RIGHT
var moving := false
var charging := false
var dodging := false
var weapon_index := 0
var attachment_index := 0
var fixed_direction := -1
var dodge_time := 0.0

func _ready() -> void:
 texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 body.texture=load("res://assets/runtime/characters/survivor.png")
 body.hframes=4
 body.vframes=4
 body.offset=Vector2(0,-12)
 add_child(body)
 pivot.position=Vector2(0,-9)
 add_child(pivot)
 for s in [arm,weapon,battery,attachment]:
  s.texture=load("res://assets/runtime/weapons/equipment.png")
  s.hframes=4
  s.vframes=3
  pivot.add_child(s)
 arm.frame=3
 arm.scale=Vector2(0.35,0.35)
 arm.position=Vector2(3,1)
 weapon.position=Vector2(10,0)
 attachment.scale=Vector2(0.45,0.45)
 attachment.position=Vector2(12,4)
 battery.frame=7
 battery.scale=Vector2(0.42,0.42)
 battery.position=Vector2(6,4)

func _process(delta: float) -> void:
 elapsed+=delta
 var dir := fixed_direction
 if dir<0:
  if absf(aim.x)>absf(aim.y): dir=2 if aim.x>=0 else 1
  else: dir=0 if aim.y>=0 else 3
 var step := 1+int(elapsed*8.0)%3 if moving else 0
 body.frame=dir*4+step
 dodge_time=fmod(dodge_time+delta,0.36) if dodging else 0.0
 body.rotation=(dodge_time/0.36)*TAU if dodging else 0.0
 body.position.y=-3 if dodging else 0
 # Internal sibling order keeps the whole actor on its world Y-sort plane.
 var layer_index:=0 if dir==3 else 1
 if pivot.get_index()!=layer_index:move_child(pivot,layer_index)
 pivot.rotation=aim.angle()+(-0.4 if aim.x>=0 else 0.4)*(1.0 if charging else 0.0)
 pivot.scale.y=-1 if aim.x<0 else 1
 weapon.frame=weapon_index if weapon_index<3 else weapon_index+1
 attachment.frame=8+attachment_index
 attachment.visible=weapon_index<3
 battery.visible=charging and weapon_index<3
 battery.modulate=Color(0.65,1.0,1.0,0.8+0.2*sin(elapsed*10.0))

