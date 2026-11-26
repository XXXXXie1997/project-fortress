"""Build original modular suburbs assets. Run with Blender -b -P this_file."""
import json
import math
import random
from pathlib import Path

import bpy
import numpy as np
from mathutils import Euler, Vector

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets/runtime/suburbs_hd"
SOURCE = ROOT / "assets/source/suburbs_hd"
for folder in (SOURCE,OUT):folder.mkdir(parents=True,exist_ok=True)
(SOURCE/'.gdignore').touch()
DATA = json.loads((ROOT / "data/maps/content/suburbs.json").read_text(encoding="utf8"))
rng = random.Random(917)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.context.preferences.filepaths.save_version = 0
materials = {}
groups = {}


def material(name, rgb, grain=.12, stripe=False):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    seed = np.random.default_rng(len(materials) + 41)
    noise = np.ones((64,64))
    noise += seed.uniform(-.009, .009, (4, 4)).repeat(16, 0).repeat(16, 1)
    if stripe:
        noise *= seed.uniform(.991, 1.009, (8, 1)).repeat(8, 0)
    if name in ('soil','road'):
        y,x=np.mgrid[0:64,0:64]*math.tau/64
        noise += (.055 if name=='road' else .105)*(np.sin(x+.7*np.sin(y))+np.cos(y-x)*.43)
    pixels = np.ones((64, 64, 4), dtype=np.float32)
    pixels[:, :, :3] = np.clip(noise[:, :, None] * (np.array(rgb) / 255), 0, 1)
    image = bpy.data.images.new(name, width=64, height=64)
    image.pixels.foreach_set(pixels.ravel())
    image.pack()
    node = mat.node_tree.nodes.new('ShaderNodeTexImage')
    node.image, node.interpolation = image, 'Closest'
    mat.node_tree.links.new(node.outputs['Color'], mat.node_tree.nodes['Principled BSDF'].inputs['Base Color'])
    materials[name] = mat


for name, color in {'chalk':(175,166,140),'plank':(122,113,88),'beam':(67,54,43),'rust':(123,70,42),'tile':(145,80,52),'tile2':(110,65,46),'tile3':(157,96,65),'steel':(111,124,119),'dark':(45,50,46),'glass':(47,68,70),'brick':(139,100,76),'cement':(140,136,121),'pine':(57,75,52),'needles':(72,87,56),'tips':(97,100,63),'dry':(144,120,74),'road':(79,78,73),'soil':(103,103,76),'line':(171,147,90),'dust':(126,117,91)}.items():
    material(name, color, .095 if name=='road' else .15, name in ('plank','beam','chalk'))


def mesh(part, verts, faces, mat):
    vs, fs, ms = groups.setdefault(part, ([], [], []))
    offset = len(vs)
    vs.extend(verts)
    for face in faces:
        fs.append(tuple(offset + v for v in face))
        ms.append(mat)


def box(part, pos, size, mat, rot=(0,0,0)):
    a,b,c = (s/2 for s in size)
    matrix = Euler(rot).to_matrix()
    vs = [tuple(matrix @ Vector((x,y,z))+Vector(pos)) for x,y,z in
          [(-a,-b,-c),(a,-b,-c),(a,b,-c),(-a,b,-c),(-a,-b,c),(a,-b,c),(a,b,c),(-a,b,c)]]
    mesh(part, vs, [(3,2,1,0),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)], mat)


def save(name):
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    for part,(vs,fs,ms) in groups.items():
        geo = bpy.data.meshes.new(part)
        geo.from_pydata(vs, [], fs)
        geo.update()
        obj = bpy.data.objects.new(part, geo)
        bpy.context.collection.objects.link(obj)
        names = list(dict.fromkeys(ms))
        for m in names: geo.materials.append(materials[m])
        uv = geo.uv_layers.new()
        for face, m in zip(geo.polygons,ms):
            face.material_index = names.index(m)
            n = face.normal
            for i in face.loop_indices:
                x,y,z = vs[geo.loops[i].vertex_index]
                scale=.19 if m in ('soil','road') else 1.
                uv.data[i].uv = ((x if abs(n.x)<.7 else y)*scale, (y if abs(n.z)>.7 else z)*scale)
    bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE/(name+'.blend')))
    bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')), export_format='GLB')
    groups.clear()


def building(room):
    # Blender X and -Y correspond to logical map X and Y, in 48-unit cells.
    name = room['id']
    w,d = [v/48 for v in room['rect'][2:]]
    front, side = -d/2, w/2
    h = 2.35 if name=='cottage' else 2.65
    wood = name=='cottage'
    box('Floor',(0,0,.035),(w,d,.07),'plank' if wood else 'cement')
    for j in range(int(d*1.5)):
        box('Floor',(0,front+j/1.5,.084),(w,.021,.008),'plank')
    # Each facade is built around actual door/window openings.
    def facade(label, length, front_face, sign, spans):
        def board(u,z,width,height,depth,mat,shift=0):
            pos=(u,sign*(d/2+shift),z) if front_face else (sign*(w/2+shift),u,z)
            size=(width,depth,height) if front_face else (depth,width,height)
            box(label,pos,size,mat)
        n=14
        for row in range(n):
            z=(row+.5)*h/n
            cuts=[(-length/2,length/2)]
            for mid,width,bottom,top in spans:
                if bottom<=z<top:
                    cuts=[(a,b) for l,r in cuts for a,b in ((l,min(r,mid-width/2)),(max(l,mid+width/2),r)) if b>a]
            for l,r in cuts:
                board((l+r)/2,z,r-l,h/n-.002,.16,'chalk' if wood else ('brick' if row<3 else 'cement'))
        for mid,width,bottom,top in spans:
            for edge in (-1,1):board(mid+edge*width/2,(bottom+top)/2,.09,top-bottom,.23,'beam')
            board(mid,top,width+.2,.12,.25,'chalk')
            if bottom:
                board(mid,(top+bottom)/2,width,top-bottom,.06,'glass')
                board(mid,bottom,width+.25,.13,.32,'plank')
                board(mid,(top+bottom)/2,.065,top-bottom,.20,'beam')
                board(mid,(top+bottom)/2,width,.055,.20,'beam')
        for u in [-length/2+.09,length/2-.09]:board(u,h/2,.18,h,.23,'beam')
    center=(room['door'][0]+room['door'][2]/2-room['rect'][0])/48-w/2
    facade('Front',w,True,-1,[(center,2,0,2.06),(-w*.33,1.15,.85,1.85),(w*.33,1.15,.85,1.85)])
    facade('NearSide',d,False,1,[(0,1.5,.85,1.85)])
    facade('Back',w,True,1,[])
    facade('FarSide',d,False,-1,[])
    # Concentrate age at openings and fittings. Leave the broad wall plane quiet.
    for u in [-w*.33,w*.33]:
        box('Front',(u,front-.13,1.91),(1.44,.31,.09),'beam')
        if wood:
            for sign in [-1,1]:
                box('Front',(u+sign*.77,front-.115,1.35),(.26,.09,.92),'plank')
                for row in range(4):
                    box('Front',(u+sign*.77,front-.17,1.05+row*.18),(.23,.035,.045),'beam')
    box('Front',(center,front-.22,2.12),(2.25,.52,.085),'beam')
    box('Front',(-w*.5+.26,front-.14,h*.48),(.083,.083,h*.94),'rust')
    box('NearSide',(side+.12,-d*.18,1.03),(.22,.43,.50),'steel')
    box('NearSide',(side+.14,-d*.18,.43),(.064,.064,.70),'beam')
    if not wood:
        for bar in range(5):
            box('NearSide',(side+.16,d*.31,1.6+bar*.085),(.09,.76,.049),'dark')
    box('Step',(center,front-.26,.055),(2.1,.56,.11),'cement')
    if room['locked']:
        box('Gate',(center,front,1.02),(1.94,.15,2.04),'steel')
        box('Gate',(center,front-.09,1.16),(1.83,.04,.12),'rust')
    else:
        box('Front',(center+1,front+.56,1.0),(.13,1.16,2),'plank')
    for j in range(3):
        box('Interior',(-w*.31+j*.63,d*.30,.31),(.60,.63,.62),'plank')
        box('Interior',(-w*.31+j*.63,d*.30,.56),(.64,.66,.075),'beam')
    box('Interior',(w*.30,d*.32,.75),(1.55,.7,.12),'plank')
    for x in [-.65,.65]:
        for y in [-.25,.25]:box('Interior',(w*.30+x,d*.32+y,.38),(.09,.09,.75),'beam')
    pitch=.37 if wood else .20
    half=d/2+.24
    for sign in (-1,1):
        angle=-sign*math.atan(pitch)
        box('Roof',(0,sign*half/2,h+half*pitch/2),(w+.5,half*math.sqrt(1+pitch*pitch),.15),'tile2' if wood else 'steel',(angle,0,0))
        rows=math.ceil(half/.28)
        for row in range(rows):
            y=half*(row+.5)/rows
            cols=math.ceil((w+.48)/(.43 if wood else .68))
            for col in range(cols):
                width=(w+.48)/cols
                x=-(w+.48)/2+(col+.5)*width
                mat=rng.choice(['tile','tile','tile2','tile3']) if wood else rng.choice(['dark','steel','steel']) if name=='supply' else rng.choice(['tile2','rust','tile2'])
                box('Roof',(x,sign*y,h+(half-y)*pitch+.105),(width-.004,half/rows*math.sqrt(1+pitch*pitch)-.003,.07),mat,(angle,0,0))
    box('Roof',(0,0,h+half*pitch+.13),(w+.55,.16,.15),'rust')
    for end in [-1,1]:
        x=end*side
        mesh('Roof',[(x,front,h),(x,-front,h),(x,0,h+half*pitch)],[(0,1,2) if end>0 else (2,1,0)],'plank')
    box('Roof',(-w*.32,.65,h+half*pitch+.12),(.54,.55,1.5),'brick')
    box('Roof',(-w*.32,.65,h+half*pitch+.89),(.66,.67,.12),'cement')
    box('Roof',(-w*.32,.65,h+half*pitch+.96),(.38,.38,.025),'dark')
    if name=='station':
        top=h+half*pitch
        box('Roof',(w*.29,-.3,top+.85),(.065,.065,1.65),'steel')
        for j in range(4):
            box('Roof',(w*.29,-.30,top+1.12+j*.15),(.74-j*.12,.045,.035),'steel')
    if name=='supply':
        for x in [-w*.15,w*.18]:
            box('Roof',(x,.71,h+half*pitch+.20),(1.19,.81,.43),'steel')
            for j in range(5):box('Roof',(x-.43+j*.21,.71,h+half*pitch+.43),(.09,.62,.033),'dark')
    save(name)


for room in DATA['rooms']: building(room)

# irregular layered branch fans with distinct drooping tips
box('Trunk',(0,0,1.7),(.24,.24,3.4),'beam')
for j in range(11):
    z=1+j*.30
    rad=1.32*(1-j/12)
    for k in range(13):
        angle=(k+rng.random()*.55)*math.tau/13
        tip=rad*rng.uniform(.8,1.22)
        def branch(r,a,h):return (r*math.cos(a),r*math.sin(a),h)
        mesh('Crown',[(0,0,z+.7),branch(tip*.7,angle-.27,z+.12),branch(tip,angle,z-.16),branch(tip*.72,angle+.27,z+.12)],
             [(0,1,2),(0,2,3)],rng.choice(['pine','pine','needles','tips']))
save('spruce')

for i in range(36):
    x,y=rng.uniform(-.44,.44),rng.uniform(-.32,.32)
    h=rng.uniform(.12,.39)
    mesh('Blades',[(x-.027,y,0),(x+.027,y,0),(x+.08,y+.04,h)],[(0,1,2)],rng.choice(['dry','tips','needles']))
save('grass')

# One terrain mesh in the same cell units as the houses, centered on the map.
mw,md=[v/48 for v in DATA['size']]
def terr(x,y,z):return (x-mw/2,md/2-y,z)
def flat_rect(x,y,w,d,z,mat):
    mesh('Terrain',[terr(x,y,z),terr(x,y+d,z),terr(x+w,y+d,z),terr(x+w,y,z)],[(0,1,2,3)],mat)
flat_rect(-3,-3,mw+6,md+6,0,'soil')
roads=[[v/48 for v in r] for r in DATA['roads']]
rooms=[[v/48 for v in r['rect']] for r in DATA['rooms']]
def within(x,y,areas,pad=0):
    return any(a-pad<x<a+w+pad and b-pad<y<b+d+pad for a,b,w,d in areas)
for i in range(210):
    x,y=rng.uniform(-2,mw+2),rng.uniform(-2,md+2)
    s=rng.uniform(.025,.18)
    mesh('Litter',[terr(x,y,.007),terr(x-s*.5,y+s*.35,.007),terr(x+s,y+s*.8,.007)],[(0,1,2)],rng.choice(['dust','dry','needles','soil']))
for ix,(x,y,w,d) in enumerate(roads):
    flat_rect(x-.14,y-.14,w+.28,d+.28,.012,'dust')
    flat_rect(x,y,w,d,.018+ix*.001,'road')
    horiz=w>d
    length=w if horiz else d
    for i in range(int(length/1.35)):
        for ofs in [-.043,.043]:
            a,b=(x+i*1.35,y+d/2+ofs) if horiz else (x+w/2+ofs,y+i*1.35)
            flat_rect(a,b,.78 if horiz else .045,.045 if horiz else .78,.03,'line')
    for i in range(int(w*d*.12)):
        a,b=rng.uniform(x,x+w),rng.uniform(y,y+d)
        for j in range(rng.randrange(2,7)):
            dx,dy=rng.uniform(-.18,.23),rng.uniform(.02,.20)
            if not within(a+dx,b+dy,roads):break
            mesh('Cracks',[terr(a,b,.032),terr(a+.017,b,.032),terr(a+dx+.009,b+dy,.032),terr(a+dx,b+dy,.032)],[(3,2,1,0)],'dark')
            a+=dx;b+=dy
for room in DATA['rooms']:
    x,y,w,d=[v/48 for v in room['rect']]
    for j in range(5):
        for k in range(3):
            flat_rect(x+w/2-.88+k*.58,y+d+j*.28,.55,.26,.043,'cement')
for b in DATA['barriers']:
    x,y,w,d=[v/48 for v in b]
    inside=within(x+w/2,y+d/2,rooms)
    if inside:continue
    horizontal=w>d
    for k in range(math.ceil(max(w,d))):
        pos=terr(x+(.3+k if horizontal else w/2),y+(d/2 if horizontal else .3+k),.29)
        box('Rail',pos,(.09,.09,.58),'rust')
    box('Rail',terr(x+w/2,y+d/2,.48),(w if horizontal else .09,.09 if horizontal else d,.20),'steel')
for i in range(720):
    x,y=rng.uniform(-1,mw+1),rng.uniform(-1,md+1)
    if within(x,y,roads,.15) or within(x,y,rooms,.4):continue
    for j in range(8):
        a,b=x+rng.uniform(-.19,.19),y+rng.uniform(-.15,.15)
        mesh('Grass',[terr(a-.023,b,.018),terr(a+.023,b,.018),terr(a+.055,b+.03,rng.uniform(.12,.29))],[(0,1,2)],rng.choice(['dry','tips','needles']))
save('terrain')



for kind in ('crate','satchel','cache','relay','sign','evac','camp','radio','beacon'):
    def p(x,y,z,w,d,h,m):box('Housing',(x,y,z),(w,d,h),m)
    if kind in ('crate','cache'):
        p(0,0,.23,.96,.66,.44,'plank' if kind=='crate' else 'steel')
        p(0,0,.478,1.0,.7,.082,'plank' if kind=='crate' else 'dark')
        for x in [-.33,.33]:
            p(x,0,.526,.073,.71,.024,'steel')
            for s in [-1,1]:p(x,s*.334,.244,.073,.032,.43,'steel')
        p(0,-.354,.413,.105,.04,.12,'rust')
        if kind=='crate':
            for j in range(3):p(0,-.336,.13+j*.101,.94,.022,.011,'beam')
    elif kind=='satchel':
        p(0,0,.16,.62,.43,.31,'plank')
        p(0,-.17,.24,.65,.15,.15,'beam')
        for x in [-.21,.21]:p(x,0,.32,.055,.43,.035,'rust')
    elif kind in ('relay','radio','beacon'):
        p(0,0,.10,.78,.61,.20,'cement')
        p(0,0,.58,.57,.44,.84,'steel')
        p(0,-.225,.71,.37,.035,.22,'glass')
        for x in [-.11,.04,.16]:p(x,-.246,.50,.064,.034,.068,'dry')
        p(.18,0,1.36,.045,.045,.78,'dark')
        p(.18,0,1.74,.09,.09,.09,'rust')
    else:
        p(0,0,.63,.11,.14,1.26,'beam')
        p(0,0,1.17,.84,.12,.32,'steel' if kind=='sign' else 'plank')
        p(-.09,-.068,1.17,.40,.023,.059,'chalk')
        if kind=='camp':p(0,0,.27,.5,.4,.54,'plank')
    save(kind)

# Roadside salvage vehicle occupying an existing rectangular roadblock.
def truck(pos,size,mat,rot=(0,0,0)):box('Wreck',pos,size,mat,rot)
truck((0,0,.40),(3.2,1.16,.24),'dark')
truck((.78,0,.67),(1.48,1.20,.40),'steel')
truck((-.88,0,.56),(1.76,1.13,.12),'plank')
for s in [-1,1]:
    truck((-.90,s*.55,.79),(1.78,.095,.43),'steel')
    truck((.55,s*.57,1.00),(.84,.06,.30),'steel')
    truck((.5,s*.57,1.28),(.66,.056,.33),'glass')
    for x in [.08,.86]:truck((x,s*.56,1.31),(.067,.067,.43),'steel')
    for x in [-1.05,.98]:
        # Wheel axis runs across the vehicle.
        vs=[]
        for y in [s*.52,s*.68]:
            for j in range(12):
                a=j*math.tau/12
                vs.append((x+.32*math.cos(a),y,.35+.32*math.sin(a)))
        fs=[tuple(range(12)),tuple(range(12,24))]
        fs.extend((i,(i+1)%12,12+(i+1)%12,12+i) for i in range(12))
        mesh('Wreck',vs,fs,'dark')
        truck((x,s*.685,.35),(.24,.04,.24),'rust')
truck((.48,0,1.53),(.94,1.23,.075),'chalk')
truck((.88,0,1.28),(.055,1.055,.39),'glass',(0,-.17,0))
truck((1.54,0,.65),(.075,1.19,.13),'beam')
for y in [-.41,.41]:truck((1.55,y,.82),(.09,.25,.13),'chalk')
truck((-1.78,0,.76),(.086,1.15,.4),'steel')
save('utility_truck')
