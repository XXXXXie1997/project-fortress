extends Node2D

const SOURCES = {"town": preload("res://assets/runtime/environment/town.png"), "dungeon": preload("res://assets/runtime/environment/dungeon.png")}
const REGIONS = {
 "grass": ["town",0,0,16,16], "path": ["town",16,32,16,16],
 "tree": ["town",48,0,16,32], "tree_round": ["town",48,0,16,32],
 "wall": ["dungeon",32,16,16,16], "floor": ["dungeon",0,64,16,16],
 "crate": ["dungeon",80,112,16,16], "chest": ["dungeon",96,112,16,16],
 "knife": ["dungeon",160,128,16,16], "door": ["dungeon",160,48,16,16]
}

func _ready() -> void:
 texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
 RenderingServer.set_default_clear_color(Color("111c28"))
 label("FORTRESS / ENVIRONMENT STUDY 01", Vector2(48,24),24)
 label("Cold outskirts",Vector2(48,70),20)
 label("Warm shelter",Vector2(672,70),20)
 build_zone(Vector2(48,112),false)
 build_zone(Vector2(672,112),true)
 label("16 px source grid / 3x integer scale / foot anchor + Y sorting",Vector2(48,624),18)
 label("Environment batch only. Characters, combat layers and functional buildings pending.",Vector2(48,658),16)
 if "--capture" in OS.get_cmdline_user_args():
  await get_tree().process_frame
  await get_tree().process_frame
  await RenderingServer.frame_post_draw
  var img := get_viewport().get_texture().get_image()
  var result := img.save_png("res://docs/art/integration/ART-101-render.png")
  print("ART_CAPTURE ",result)
  get_tree().quit(result)

func label(value: String, at: Vector2, size: int) -> void:
 var l := Label.new()
 l.text=value
 l.position=at
 l.add_theme_font_size_override("font_size",size)
 add_child(l)

func material(warm: bool) -> ShaderMaterial:
 var mat := ShaderMaterial.new()
 mat.shader=load("res://scripts/art/environment_palette.gdshader")
 mat.set_shader_parameter("warm",warm)
 return mat

func tile(key: String, position_value: Vector2, parent: Node2D, mat: ShaderMaterial) -> void:
 var spec: Array = REGIONS[key]
 var atlas := AtlasTexture.new()
 atlas.atlas=SOURCES[spec[0]]
 atlas.region=Rect2(spec[1],spec[2],spec[3],spec[4])
 var sprite := Sprite2D.new()
 sprite.texture=atlas
 sprite.position=position_value
 sprite.offset=Vector2(0,-float(spec[4])/2.0)
 sprite.material=mat
 sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 parent.add_child(sprite)

func build_zone(origin: Vector2,warm: bool) -> void:
 var zone := Node2D.new()
 zone.position=origin
 zone.scale=Vector2(3,3)
 add_child(zone)
 var mat := material(warm)
 var ground := Node2D.new()
 zone.add_child(ground)
 for y in range(10):
  for x in range(11):
   var key := "floor" if warm else "grass"
   if not warm and (x==5 or y==6): key="path"
   tile(key,Vector2(x*16+8,y*16+16),ground,mat)
 var objects := Node2D.new()
 objects.y_sort_enabled=true
 zone.add_child(objects)
 if warm:
  for x in range(11):
   tile("wall",Vector2(x*16+8,16),objects,mat)
  for x in [1,3,8]: tile("crate",Vector2(x*16+8,64),objects,mat)
  tile("chest",Vector2(136,112),objects,mat)
  tile("knife",Vector2(72,112),objects,mat)
  tile("door",Vector2(88,16),objects,mat)
 else:
  for p in [Vector2(24,40),Vector2(40,64),Vector2(136,48),Vector2(152,128),Vector2(24,144)]:
   tile("tree",p,objects,mat)
  tile("tree_round",Vector2(120,144),objects,mat)
  tile("chest",Vector2(120,80),objects,mat)

