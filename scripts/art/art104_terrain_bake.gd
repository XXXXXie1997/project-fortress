extends SceneTree
func _initialize():
 var im:=Image.load_from_file('res://assets/source/art104/terrain-adapted-source.png')
 im.convert(Image.FORMAT_RGBA8)
 var out:=Image.create(48,32,false,Image.FORMAT_RGBA8)
 for y in 2:
  for x in 3:
   var tile:=im.get_region(Rect2i(x*512+4,y*512+4,504,504))
   tile.resize(16,16,Image.INTERPOLATE_NEAREST)
   out.blit_rect(tile,Rect2i(0,0,16,16),Vector2i(x*16,y*16))
 print('TERRAIN ',out.save_png('res://assets/runtime/environment_iso/nature/terrain.png'))
 quit()

