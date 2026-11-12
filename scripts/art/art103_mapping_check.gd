extends SceneTree
const Art=preload("res://scripts/art/fortress_art.gd")
func _initialize()->void:
 var definitions:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/items.json")).items
 for path in ["crops","trade","equipment_recipes"]:
  definitions.merge(JSON.parse_string(FileAccess.get_file_as_string("res://data/"+path+".json")).get("item_definitions",{}),true)
 preload("res://scripts/game/fixture_catalog.gd").augment(definitions)
 definitions.merge(JSON.parse_string(FileAccess.get_file_as_string('res://data/content/items.json')).items,true)
 for id in ["suburbs_key","armory_key","city_key","boss_core","tactical_light","tactical_laser","tactical_launcher"]:definitions[id]={}
 var missing:Array=[]
 for id in definitions:
  if Art.item_icon(id)==null:missing.append(id)
 print("ART103_ICON_COUNT ",definitions.size()," MISSING ",missing)
 quit(0 if missing.is_empty() else 1)
