extends Node2D
var kind:="basic"
var facing:=Vector2.DOWN
var action:="idle"
var progress:=0.0
var sprite:=Sprite2D.new()
var time:=0.0
func _ready()->void:
 texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 sprite.texture=load("res://assets/runtime/enemies/"+kind+".png")
 sprite.hframes=6;sprite.vframes=4
 sprite.offset=Vector2(0,-20 if kind=="boss" else -16)
 sprite.scale=Vector2(3,3)
 add_child(sprite)
func _process(dt:float)->void:
 time+=dt
 var direction:=0
 if absf(facing.x)>absf(facing.y):direction=2 if facing.x>0 else 1
 elif facing.y<0:direction=3
 var frame:=0
 match action:
  "walk":frame=1+int(time*7)%2
  "windup":frame=3
  "strike":frame=4
  "dead":frame=5
 sprite.frame=direction*6+frame
