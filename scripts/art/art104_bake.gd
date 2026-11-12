extends SceneTree
func _initialize():
 var source:=Image.load_from_file('res://assets/source/art104/trees-adapted-source.png')
 var result:=Image.create(64,96,false,Image.FORMAT_RGBA8)
 for y in 2:
  for x in 2:
   var tile:=source.get_region(Rect2i(x*source.get_width()/2,y*source.get_height()/2,source.get_width()/2,source.get_height()/2))
   for py in tile.get_height():
    for px in tile.get_width():
     var c:=tile.get_pixel(px,py);c.a=0 if c.a<.5 else 1;tile.set_pixel(px,py,c)
   tile=tile.get_region(tile.get_used_rect())
   var ratio:=minf(30.0/tile.get_width(),44.0/tile.get_height())
   if x==1 and y==1:ratio=minf(27.0/tile.get_width(),18.0/tile.get_height())
   tile.resize(maxi(1,roundi(tile.get_width()*ratio)),maxi(1,roundi(tile.get_height()*ratio)),Image.INTERPOLATE_NEAREST)
   tile=tile.get_region(tile.get_used_rect())
   result.blit_rect(tile,Rect2i(Vector2i.ZERO,tile.get_size()),Vector2i(x*32+(32-tile.get_width())/2,y*48+48-tile.get_height()))
 print('ART104 TREES ',result.save_png('res://assets/runtime/environment_iso/nature/trees.png'))
 quit()
