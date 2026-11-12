import json
from pathlib import Path
root=Path('data/maps/content')
def point(kind,x,y,**kw):return dict(kind=kind,position=[x,y],**kw)
def room(name,x,y,w,h,locked=False):return dict(id=name,rect=[x,y,w,h],door=[x+w//2-48,y+h-24,96,24],locked=locked)
def enemy(name,kind,x,y):return dict(id=name,type=kind,position=[x,y])
def box(name,x,y,loot):return dict(id=name,position=[x,y],loot=[dict(definition_id=k,quantity=v) for k,v in loot],search_seconds=.6)
def common(id,title,size,spawn):
 w,h=size
 return dict(id=id,title=title,size=size,initial_spawn=spawn,points={},rooms=[],roads=[],barriers=[],trees=[],enemies=[],night_enemies=[],containers=[],doors={},objectives=[],events=[])
s=common('suburbs','城郊：断联公路',[2400,1920],'south')
s['points']={'south':point('spawn',240,1700,label='南侧公路'), 'north_camp':point('spawn',2040,240,label='北侧营地'),'escape':point('extraction',100,1720,label='返回避难所'),'relay':point('travel',1200,1320,label='旧电站传送器'),'armory_road':point('exit',2260,1200,label='通往武器库',target_map='armory',target_point='entrance'),'city_road':point('exit',2260,320,label='通往废弃城区',target_map='city',target_point='west')}
s['rooms']=[room('supply',1440,240,480,384,True),room('cottage',480,1056,384,336),room('station',1056,768,432,336)]
s['roads']=[[144,1440,2112,144],[1872,144,144,1440],[1008,1152,1008,96],[1008,384,96,1152]]
s['barriers']=[[160,864,240,48],[1440,1440,240,48],[1560,1160,48,220]]
s['trees']=[[120+x*144,120+y*144] for x in range(5) for y in range(4) if (x+y)%3!=0]+[[100,1140],[240,1260],[840,560],[1720,1660],[2110,740]]
s['enemies']=[enemy('s_boss','boss',430,380),enemy('s_road1','basic',900,1450),enemy('s_road2','fast',1700,1520),enemy('s_home','basic',660,1220),enemy('s_station','ranged',1240,930),enemy('s_locker','armored',1650,420),enemy('s_cross','basic',2010,1020),enemy('s_north','fast',2000,580)]
s['night_enemies']=[enemy('s_night1','fast',1450,1550),enemy('s_night2','ranged',2100,1000),enemy('s_night3','basic',1000,700)]
s['containers']=[box('starter_cache',350,1590,[('scrap',6),('medical_needle',2)]),box('road_parts',1360,1510,[('scrap',8)]),box('cottage_box',600,1160,[('scrap',5),('battery_basic',1)]),box('key_cache',1320,1190,[('suburbs_key',1)]),box('supply_vault',1650,350,[('scrap',18),('battery_basic',2),('medical_needle',5)]),box('station_parts',1160,870,[('scrap',10)])]
s['containers'][3]['loot'][0]['door_key']='suburbs:supply'
s['doors']={'supply':'suburbs_key'};s['objectives']=[dict(id='suburbs_contact',position=[1360,860],label='调查中继记录',quest_target='map_1_relay')];s['events']=[dict(id='distress',position=[2110,980],label='异常求救广播')]
a=common('armory','支线：封锁武器库',[1920,1920],'entrance')
a['points']={'entrance':point('spawn',220,1660,label='货运入口'),'roof_camp':point('spawn',1700,1540,label='东侧维修坪'),'escape':point('extraction',100,1720,label='武器库撤离'),'relay':point('travel',980,1550,label='后勤传送器'),'road':point('exit',110,1500,label='返回城郊',target_map='suburbs',target_point='armory_road')}
a['rooms']=[room('barracks',240,240,480,576),room('vault',1152,192,528,528,True),room('workshop',720,864,672,384)]
a['roads']=[[144,1392,1632,144],[816,144,144,1344]];a['barriers']=[[240,1030,240,48],[1450,980,48,350],[1080,360,48,240],[280,1350,288,24]]
a['enemies']=[enemy('a_guard','armored',900,720),enemy('a_guard2','ranged',960,1120),enemy('a_fast','fast',1420,1420),enemy('a_barracks','basic',420,480),enemy('a_vault','armored',1410,380),enemy('a_watch','ranged',1640,930),enemy('a_fast2','fast',500,1240)]
a['night_enemies']=[enemy('a_night1','armored',1060,1400),enemy('a_night2','ranged',1760,580)]
a['containers']=[box('rack',400,380,[('rifle_basic',1),('battery_basic',1)]),box('workbench',900,1040,[('scrap',8),('scatter_basic',1)]),box('locker_key',1080,1330,[('armory_key',1)]),box('sealed_rack',1450,300,[('sniper_basic',1),('energy_blade',1),('battery_basic',2)]),box('loading_crate',1500,1560,[('scrap',12)])]
a['containers'][2]['loot'][0]['door_key']='armory:vault';a['doors']={'vault':'armory_key'}
c=common('city','废弃城区：最后信号',[2880,2400],'west')
c['points']={'west':point('spawn',180,2100,label='西侧街口'),'east':point('spawn',2580,2000,label='东侧广场'),'escape':point('extraction',100,2240,label='城区撤离'),'relay':point('travel',1600,1920,label='市政传送器'),'road':point('exit',100,1940,label='返回城郊',target_map='suburbs',target_point='city_road')}
c['rooms']=[room('clinic',288,288,576,480),room('market',1152,384,576,528),room('radio',2160,144,528,528,True),room('apartments',480,1344,624,480),room('garage',1824,1248,576,480)]
c['roads']=[[144,1920,2592,144],[912,144,144,1920],[144,1008,2592,192],[1872,144,144,1872]];c['barriers']=[[1200,1720,400,32],[1100,1100,300,48],[2100,1930,240,48],[220,940,240,48]]
c['enemies']=[enemy('c_'+str(i),kind,*p) for i,(kind,p) in enumerate([('basic',(700,2020)),('fast',(1300,2120)),('ranged',(1700,1050)),('armored',(1980,800)),('basic',(600,550)),('ranged',(1450,650)),('fast',(780,1530)),('armored',(2130,1460)),('ranged',(2460,400)),('fast',(2540,1700)),('basic',(1200,1250))])]
c['night_enemies']=[enemy('c_night1','ranged',2700,1120),enemy('c_night2','armored',1600,2080),enemy('c_night3','fast',1100,840),enemy('c_night4','basic',430,1060)]
c['containers']=[box('clinic_supplies',550,430,[('medical_needle',5),('battery_basic',1)]),box('market_stock',1400,530,[('scrap',15)]),box('apartment_key',700,1500,[('city_key',1)]),box('garage_stock',2060,1400,[('scrap',12),('battery_basic',2)]),box('radio_vault',2360,350,[('scrap',25),('battery_basic',3)])]
c['containers'][2]['loot'][0]['door_key']='city:radio';c['doors']={'radio':'city_key'};c['objectives']=[dict(id='city_contact',position=[2530,330],label='恢复外界通信',quest_target='map_2_transmitter')]
s['containers'].extend([box('garden_seeds',820,1120,[('seed_catalyst',3),('seed_material',3)]),box('farm_shed',1800,1680,[('seed_material',2),('scrap',5)])])
c['containers'].extend([box('botanical_lab',360,600,[('seed_catalyst',4),('catalyst',2)]),box('market_seeds',1550,780,[('seed_material',4)])])
for m in [s,a,c]:
 for r in m['rooms']:
  x,y,w,h=r['rect']
  m['barriers'].append([x+36,y+48,96,24])
 root.joinpath(m['id']+'.json').write_text(json.dumps(m,ensure_ascii=False,indent=2),encoding='utf8')
