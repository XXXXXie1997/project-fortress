extends RefCounted
static var textures:Dictionary={}
static func texture(kind:String,theme:String='suburbs',variant:int=0)->AtlasTexture:
 var key:=kind+':'+theme+':'+str(variant)
 if textures.has(key):return textures[key]
 var result:=AtlasTexture.new()
 if kind=='tree':
  var index:=posmod(variant,4)
  result.atlas=load('res://assets/runtime/environment_iso/nature/trees.png')
  result.region=Rect2((index%2)*32,(index/2)*48,32,48)
 else:
  var column:int={'suburbs':0,'armory':1,'city':2}.get(theme,0)
  result.atlas=load('res://assets/runtime/environment_iso/nature/terrain.png')
  result.region=Rect2(column*16,16 if kind=='road' else 0,16,16)
 textures[key]=result
 return result
