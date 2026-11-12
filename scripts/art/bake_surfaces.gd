extends SceneTree
func _initialize():
 var im:=Image.load_from_file("res://assets/runtime/environment_iso/surfaces-source.png")
 im.resize(48,32,Image.INTERPOLATE_NEAREST)
 print("SURFACES ",im.save_png("res://assets/runtime/environment_iso/surfaces.png"))
 quit()
