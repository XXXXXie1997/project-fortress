extends Node2D
const Art=preload("res://scripts/art/fortress_art.gd")
var kind:="warehouse"
var alive:=true
var aim:=Vector2.RIGHT
var body:Sprite2D
var attachment:Sprite2D
var crops:Array[Sprite2D]=[]
var record_provider:Callable
func _ready():
 texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 body=Sprite2D.new();body.offset=Vector2(0,-32);body.scale=Vector2(3,3);add_child(body)
 attachment=Sprite2D.new();attachment.scale=Vector2(3,3);add_child(attachment)
 if get_parent().has_method('data'):record_provider=Callable(get_parent(),'data')
 for i in 2:
  var crop:=Sprite2D.new();crop.scale=Vector2(1.4,1.4);crop.offset=Vector2(0,-24);crop.position=Vector2(-40+80*i,-12);crop.visible=false;add_child(crop);crops.append(crop)
func _process(_dt):
 if kind=='farm':
  body.visible=false;attachment.visible=false
  var record:Dictionary=record_provider.call() if record_provider.is_valid() else {}
  var batches:Array=record.get('batches',[])
  for i in crops.size():
   crops[i].visible=alive and i<batches.size()
   if crops[i].visible:
    var batch:Dictionary=batches[i]
    var stage:int=2 if not batch.get('harvest',{}).is_empty() else clampi(int(batch.get('age',0)),0,2)
    crops[i].texture=Art.crop_texture(batch.get('crop','catalyst'),stage)
  queue_redraw()
  return
 body.texture=Art.facility_texture(kind,not alive and kind!='shield')
 attachment.visible=alive and kind in ["turret","shield"]
 if kind=="turret":
  attachment.texture=Art.facility_texture("turret_barrel");attachment.offset=Vector2(18,-21);attachment.position=Vector2(0,-72);attachment.rotation=aim.angle()
 elif kind=="shield":
  attachment.texture=Art.facility_texture("shield_energy");attachment.scale=Vector2(2.35,2.35);attachment.position=Vector2(0,-78)
func _draw():
 if kind!='farm':return
 var color:=Color('5f493b') if alive else Color('383333')
 draw_colored_polygon(PackedVector2Array([Vector2(0,-90),Vector2(90,-45),Vector2(0,0),Vector2(-90,-45)]),color)
 for i in range(-2,3):
  draw_line(Vector2(-50+i*12,-60-i*6),Vector2(20+i*12,-25-i*6),Color('80634a') if alive else Color('49403b'),3)
