extends SceneTree
var failures := 0
var inv: InventoryService
func check(ok: bool, label: String):
 print(('PASS ' if ok else 'FAIL ') + label)
 if not ok: failures += 1
func fresh() -> Dictionary:
 var s := WorldState.fresh()
 inv.setup(s)
 return s
func _initialize():
 inv = InventoryService.new(JSON.parse_string(FileAccess.get_file_as_string('res://data/items.json')).items)
 var s := fresh()
 var a := inv.spawn(s,'medical_needle','warehouse',20)
 check(inv.move(s,a.id,'bag').ok and inv.items_in(s,'bag').size()==4,'split warehouse stack')
 s.player.quick[0]='medical_needle'
 check(inv.quick_count(s,0)==20 and inv.consume(s,'medical_needle',7) and inv.quick_count(s,0)==13,'quick total and consume')
 var snapshot := WorldState.encode(s)
 check(not inv.consume(s,'medical_needle',99) and snapshot==WorldState.encode(s),'failed consume atomic')
 s=fresh()
 s.containers.warehouse=InventoryService.container(1,1,-1)
 inv.spawn(s,'medical_needle','warehouse',20)
 check(inv.exchange(s,{}, {'medical_needle':5}).ok and inv.count(s,'medical_needle','warehouse')==25,'reward merges full grid')
 snapshot=WorldState.encode(s)
 check(not inv.exchange(s,{'medical_needle':1},{'rifle_basic':1}).ok and snapshot==WorldState.encode(s),'failed exchange atomic')
 s=fresh()
 a=inv.spawn(s,'nightvision','ground')
 check(inv.spawn(s,'nightvision','warehouse').is_empty(),'unique occupied')
 check(inv.equip(s,a.id,'extra_1').ok and inv.spawn(s,'nightvision','warehouse').is_empty(),'unique equipped')
 check(inv.destroy(s,a.id) and not inv.spawn(s,'nightvision','warehouse').is_empty(),'unique freed')
 s=fresh()
 a=inv.spawn(s,'battery_basic','bag')
 s.items[a.id].energy=90
 s.base.energy_store.energy=950
 snapshot=WorldState.encode(s)
 check(not inv.move(s,a.id,'warehouse').ok and snapshot==WorldState.encode(s),'D002 reject atomic')
 s.base.energy_store.energy=0
 check(inv.move(s,a.id,'warehouse').ok and s.base.energy_store.energy==90 and s.items[a.id].energy==0,'battery deposit')
 check(inv.move(s,a.id,'bag').ok and s.base.energy_store.energy==0 and s.items[a.id].energy==90,'battery withdraw partial')
 s=fresh()
 var pack:=inv.spawn(s,'backpack_small','ground')
 inv.equip(s,pack.id,'backpack')
 var gun:=inv.spawn(s,'rifle_basic','bag')
 var battery:=inv.spawn(s,'battery_basic','bag')
 s.base.energy_store.energy=100
 ChargingService.wireless(s,1,10,true,true,false)
 check(s.items[gun.id].energy==0 and s.items[battery.id].energy==10,'wireless bag only battery')
 inv.equip(s,gun.id,'weapon_1')
 var before:float=s.base.energy_store.energy+s.items[battery.id].energy+s.items[gun.id].energy
 ChargingService.wireless(s,1,10,true,true,false)
 ChargingService.charge_weapon(s,gun.id,20)
 check(is_equal_approx(before,s.base.energy_store.energy+s.items[battery.id].energy+s.items[gun.id].energy),'manual wireless conservation')
 snapshot=WorldState.encode(s)
 ChargingService.wireless(s,1,10,true,true,true)
 check(snapshot==WorldState.encode(s),'paused wireless')
 inv.spawn(s,'medical_needle','bag',100)
 snapshot=WorldState.encode(s)
 var result:=inv.unequip(s,'backpack',false,true)
 check(result.get('confirmation_required',false) and snapshot==WorldState.encode(s),'full pack unequip preview')
 check(inv.unequip(s,'backpack',true,true).ok and s.containers.bag.width==3,'full pack unequip confirm')
 check(not WorldState.decode(WorldState.encode(s)).is_empty(),'state roundtrip')
 s=fresh()
 pack=inv.spawn(s,'backpack_small','ground'); inv.equip(s,pack.id,'backpack')
 gun=inv.spawn(s,'rifle_basic','ground'); inv.equip(s,gun.id,'weapon_1')
 var b1:=inv.spawn(s,'battery_basic','bag'); var b2:=inv.spawn(s,'battery_basic','bag')
 s.items[b1.id].energy=5; s.items[b2.id].energy=30
 check(ChargingService.charge_weapon(s,gun.id,20,b1.id)==20,'selected battery auto continues')
 # Powered plugin attached to worn weapon must receive station charge.
 var plugin:=WorldState.create_item(s,'battery_basic','plugin')
 plugin.capacity=100; plugin.energy=0
 s.items[gun.id].plugins={'tactical':plugin.id}
 s.base.energy_store.energy=100
 ChargingService.wireless(s,1,10,true,true,false)
 check(s.items[plugin.id].energy==10,'worn plugin wireless')
 var t:=fresh()
 t.containers.bag=InventoryService.container(1,3,10)
 var rgun:=inv.spawn(t,'rifle_basic','bag')
 check(not rgun.is_empty() and t.items[rgun.id].rotated,'auto rotation narrow container')
 var oldstate:=WorldState.encode(t)
 check(not inv.relocate(t,rgun.id,Vector2i(1,0),true) and oldstate==WorldState.encode(t),'invalid drag atomic')
 t=fresh();t.containers.bag=InventoryService.container(8,8,3)
 var heavy:=inv.spawn(t,'rifle_basic','bag')
 check(not heavy.is_empty() and inv.spawn(t,'scrap','bag').is_empty(),'hard weight boundary')
 inv.equip(t,heavy.id,'weapon_1')
 check(inv.weight(t,'bag')==0 and not inv.spawn(t,'scrap','bag').is_empty(),'equipped weight excluded')
 inv.definitions['rifle_upgrade']=inv.definitions.rifle_basic.duplicate(true)
 inv.definitions.rifle_upgrade.capacity=100
 inv.definitions.rifle_upgrade.durability=200
 inv.definitions.rifle_upgrade.quality=2
 t.items[heavy.id].energy=25
 t.items[heavy.id].plugins={'tactical':'placeholder'}
 check(inv.upgrade(t,heavy.id,'rifle_upgrade').ok and t.items[heavy.id].energy==25 and t.items[heavy.id].durability==200 and t.items[heavy.id].plugins.tactical=='placeholder','upgrade identity energy plugin')
 check(inv.upgrade_station(t,2,14,10,2000) and t.containers.warehouse.width==14 and t.base.energy_store.capacity==2000,'station shared capacity upgrade')
 oldstate=WorldState.encode(t)
 check(not inv.upgrade_station(t,2,14,10,3000) and oldstate==WorldState.encode(t),'station reject atomic')
 t=fresh()
 var packold:=inv.spawn(t,'backpack_small','ground');inv.equip(t,packold.id,'backpack')
 inv.spawn(t,'medical_needle','bag',100)
 inv.definitions['pack_tiny']=inv.definitions.backpack_small.duplicate(true)
 inv.definitions.pack_tiny.bag_width=3;inv.definitions.pack_tiny.bag_height=2;inv.definitions.pack_tiny.bag_weight=10
 var tiny:=inv.spawn(t,'pack_tiny','ground')
 oldstate=WorldState.encode(t)
 check(inv.equip(t,tiny.id,'backpack',false).get('confirmation_required',false) and oldstate==WorldState.encode(t),'replace smaller preview atomic')
 check(inv.equip(t,tiny.id,'backpack',true).ok and t.player.equipment.backpack==tiny.id and inv.count(t,'medical_needle')+inv.count(t,'medical_needle','warehouse')==100,'replace smaller preserves all')
 t=fresh()
 var uv:=inv.spawn(t,'nightvision','ground');inv.equip(t,uv.id,'extra_1');t.items[uv.id].energy=10
 oldstate=WorldState.encode(t);ChargingService.drain_passives(t,5,1,true)
 check(oldstate==WorldState.encode(t),'passive paused')
 ChargingService.drain_passives(t,2,1,false);check(t.items[uv.id].energy==8,'passive time drain')

 print('FAILURES ', failures)
 quit(1 if failures else 0)

