class_name FortressArt
extends RefCounted
const ITEMS={"battery_basic":0,"medical_needle":1,"scrap":2,"armor_basic":3,"backpack_small":4,"nightvision":5,"exoskeleton":6,"aim_assist":7,"seed_catalyst":8,"seed_material":9,"catalyst":10,"suburbs_key":11,"armory_key":11,"city_key":11,"bandage":12,"medkit":13,"boss_core":14,"scope_basic":15}
const FACILITIES={"warehouse":0,"generator":1,"technology":2,"quest":3,"workstation":4,"trade":5,"turret":6,"turret_barrel":7,"shield":8,"shield_energy":9,"ruin_building":10,"ruin_machine":11}
const WEAPONS={"rifle_basic":0,"rifle_advanced":0,"scatter_basic":1,"sniper_basic":2,"knife_basic":4,"energy_blade":5,"unique_blade":6,"trade_blade":6,"tactical_light":8,"tactical_laser":9,"tactical_launcher":10}
static var cache:Dictionary={}
const ALIASES={"scatter_advanced":"scatter_basic","sniper_advanced":"sniper_basic","knife_advanced":"knife_basic","energy_blade_advanced":"energy_blade","armor_advanced":"armor_basic","backpack_large":"backpack_small","scope_advanced":"scope_basic","tactical_light_advanced":"tactical_light","tactical_laser_advanced":"tactical_laser","tactical_launcher_advanced":"tactical_launcher"}
static func region(path:String,index:int,cols:int,cell:Vector2i)->AtlasTexture:
 var key:=path+str(index)
 if cache.has(key):return cache[key]
 var t:=AtlasTexture.new();t.atlas=load(path);t.region=Rect2((index%cols)*cell.x,(index/cols)*cell.y,cell.x,cell.y);cache[key]=t;return t
static func item_icon(id:String)->Texture2D:
 if ALIASES.has(id):id=ALIASES[id]
 if id in ['muzzle_basic','muzzle_advanced','capacitor_basic','capacitor_advanced']:
  return region('res://assets/runtime/items/attachments.png',0 if id.begins_with('muzzle_') else 1,2,Vector2i(20,20))
 if ITEMS.has(id):return region("res://assets/runtime/items/items.png",ITEMS[id],4,Vector2i(20,20))
 if WEAPONS.has(id):return region("res://assets/runtime/weapons/equipment.png",WEAPONS[id],4,Vector2i(24,16))

 push_warning("ART103 unmapped item: "+id)
 return null
static func facility_texture(kind:String,ruined:bool=false)->Texture2D:
 var index:int=FACILITIES.get(kind,0)
 if ruined:index=11 if kind in ["generator","turret"] else 10
 return region("res://assets/runtime/environment_iso/facilities.png",index,4,Vector2i(64,64))
static func crop_texture(kind:String,stage:int)->Texture2D:
 return region("res://assets/runtime/environment_iso/crops.png",clampi(stage,0,2)+(3 if kind=="material" else 0),3,Vector2i(64,48))


