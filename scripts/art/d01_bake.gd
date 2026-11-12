extends "res://scripts/art/build_art103_atlases.gd"
func _initialize():
 for kind in ['ranged','fast']:bake('enemies/'+kind,6,4,Vector2i(32,32),Vector2i(28,28),true)
 quit()
