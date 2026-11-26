"""Original rigged HD-2D character kit. blender -b -P tools/art/build_actors.py"""
import math
from pathlib import Path
import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
for folder in ('assets/source/actors_hd','assets/runtime/actors_hd'):
    (ROOT/folder).mkdir(parents=True,exist_ok=True)
(ROOT/'assets/source/actors_hd/.gdignore').touch()
PALETTE = {
    'skin':'ad8164', 'shadow':'775442', 'hair':'302f2b', 'coat':'556451',
    'trim':'a59872','leather':'544639','pants':'404c55','boot':'393936',
    'metal':'53616a','gun':'313d43','light':'85ccbd','knife':'a4b3aa',
    'basic':'857653','fast':'854c42','armored':'50636a','ranged':'70485d',
    'boss':'634841','sick':'919376','wound':'85483c','bone':'bfa988',
    'yellow':'c09b54','mask':'aaa791'
}
def linear(v):
    v=int(v,16)/255
    return ((v+.055)/1.055)**2.4 if v>.04045 else v/12.92

def build(kind):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.preferences.filepaths.save_version=0
    mats={}
    for key,val in PALETTE.items():
        mat=bpy.data.materials.new(key)
        mat.diffuse_color=(*[linear(val[i:i+2]) for i in (0,2,4)],1)
        mat.use_nodes=True
        shader=mat.node_tree.nodes.get('Principled BSDF')
        shader.inputs['Base Color'].default_value=mat.diffuse_color
        shader.inputs['Roughness'].default_value=.73
        mats[key]=mat
    hero=kind=='survivor'
    heavy=kind in ('armored','boss')
    broad=1.42 if heavy else .86 if kind=='fast' else 1.0
    lean=0 if hero else -.16 if kind in ('fast','boss') else -.075
    armature=bpy.data.armatures.new('Biped')
    rig=bpy.data.objects.new('Rig',armature)
    bpy.context.collection.objects.link(rig)
    bpy.context.view_layer.objects.active=rig
    rig.select_set(True)
    bpy.ops.object.mode_set(mode='EDIT')
    def bone(name,head,tail,parent=None):
        b=armature.edit_bones.new(name)
        b.head,b.tail=head,tail
        if parent:b.parent=armature.edit_bones[parent]
    bone('Root',(0,0,0),(0,0,.25))
    bone('Torso',(0,0,.84),(0,lean,1.45),'Root')
    bone('Head',(0,lean,1.43),(0,lean,1.78),'Torso')
    for s,tag in [(-1,'L'),(1,'R')]:
        x=s*.14*broad
        bone('Leg'+tag,(x,0,.86),(x,.01,.46),'Root')
        bone('Shin'+tag,(x,.01,.46),(x,0,.12),'Leg'+tag)
        bone('Arm'+tag,(s*.26*broad,lean,1.42),(s*.30*broad,lean-.10,1.10),'Torso')
    bpy.ops.object.mode_set(mode='OBJECT')
    parts=[]
    def obj(name,vs,faces,mat,joint):
        mesh=bpy.data.meshes.new(name)
        mesh.from_pydata(vs,[],faces);mesh.update()
        o=bpy.data.objects.new(name,mesh)
        bpy.context.collection.objects.link(o)
        mesh.materials.append(mats[mat])
        if joint:
            g=o.vertex_groups.new(name=joint)
            g.add(list(range(len(vs))),1,'REPLACE')
            parts.append(o)
        return o
    def rings(name,rows,mat,joint,n=9):
        vs=[]
        for x,y,z,rx,ry in rows:
            for i in range(n):
                a=(i+.5)*math.tau/n
                vs.append((x+rx*math.cos(a),y+ry*math.sin(a),z))
        faces=[tuple(reversed(range(n)))]
        for k in range(len(rows)-1):
            for i in range(n):
                j=(i+1)%n
                faces.append((k*n+i,k*n+j,(k+1)*n+j,(k+1)*n+i))
        faces.append(tuple(range(len(vs)-n,len(vs))))
        return obj(name,vs,faces,mat,joint)
    def box(name,pos,size,mat,joint):
        x,y,z=pos
        a,b,c=[v/2 for v in size]
        return obj(name,[(x+sx*a,y+sy*b,z+sz*c) for sx,sy,sz in
              [(-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),(-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1)]],
              [(3,2,1,0),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],mat,joint)
    coat='coat' if hero else kind
    skin='skin' if hero else 'sick'
    for s,tag in [(-1,'L'),(1,'R')]:
        x=s*.142*broad
        rings('Thigh',[(x,.02,.42,.10,.11),(x,0,.7,.128,.15),(x,0,.90,.14,.15)],'pants','Leg'+tag)
        rings('Greave',[(x,0,.11,.09,.10),(x,.019,.27,.103,.12),(x,.01,.46,.104,.115)],'leather' if heavy else 'pants','Shin'+tag)
        rings('Boot',[(x,-.053,.015,.117,.195),(x,-.064,.09,.119,.18),(x,.005,.19,.105,.105)],'boot','Shin'+tag)
        box('Kneecap',(x,-.091,.45),(.148,.062,.15),'metal' if heavy else 'leather','Shin'+tag)
    rings('Jacket',[(0,.012,.80,.268*broad,.18),(0,0,.95,.236*broad,.158),(0,lean,1.31,.313*broad,.196),(0,lean,1.45,.279*broad,.16),(0,lean,1.49,.146,.122)],coat,'Torso')
    rings('Belt',[(0,0,.88,.266*broad,.182),(0,0,.948,.257*broad,.177)],'leather','Torso')
    for x in [-.16,0,.16]:
        box('Pouch',(x*broad,-.156,.93),(.108,.082,.115),'trim' if hero else 'leather','Torso')
    rings('Face',[(0,lean-.018,1.43,.111,.113),(0,lean-.05,1.54,.159,.147),(0,lean-.028,1.71,.173,.159),(0,lean,1.80,.135,.118)],skin,'Head')
    for s in [-1,1]:
        box('Brow',(s*.072,lean-.177,1.647),(.083,.023,.026),'hair','Head')
    box('Nose',(0,lean-.187,1.599),(.051,.052,.066),skin,'Head')
    if hero or kind in ('armored','basic'):
        rings('Cap',[(0,lean,1.67,.180,.167),(0,lean,1.79,.183,.16),(0,lean+.018,1.844,.132,.117)],'hair' if hero else coat,'Head')
    if hero:
        box('Brim',(0,lean-.145,1.71),(.32,.20,.040),'coat','Head')
        rings('Scarf',[(0,lean,1.41,.166,.14),(0,lean-.035,1.514,.151,.155)],'trim','Torso')
        box('Rucksack',(0,.191,1.15),(.398,.192,.47),'leather','Torso')
        for s in [-1,1]:
            box('Webbing',(s*.145,-.153,1.25),(.055,.049,.31),'leather','Torso')
    if heavy:
        box('Breastplate',(0,lean-.136,1.245),(.49,.13,.34),'metal' if kind=='armored' else 'wound','Torso')
        for s in [-1,1]:
            rings('Pauldron',[(s*.29*broad,lean,1.30,.144,.165),(s*.28*broad,lean,1.48,.165,.178),(s*.27*broad,lean,1.56,.101,.135)],'metal' if kind=='armored' else 'bone','Arm'+('R' if s>0 else 'L'))
    if kind=='ranged':
        rings('Throat sac',[(0,lean-.135,1.22,.13,.13),(0,lean-.18,1.38,.19,.17),(0,lean-.15,1.52,.115,.10)],'ranged','Torso')
    if kind=='boss':
        for i in range(5):
            x=(i-2)*.12
            rings('Dorsal spur',[(x,.105,1.38,.11,.12),(x,.16,1.57,.077,.08),(x,.27,1.85-abs(x)*.55,.012,.012)],'bone','Torso',6)
    for s,tag in [(-1,'L'),(1,'R')]:
        x=s*.27*broad
        joint='Arm'+tag
        rings('Sleeve',[(x*1.13,lean-.095,1.10,.095,.10),(x*1.1,lean-.035,1.29,.117,.124),(x,lean,1.448,.133,.13)],coat,joint)
        hand_y=(-.39 if s<0 else -.24) if hero else lean-.18
        hand_x=.068 if hero else x*1.12
        wrist_z=1.19 if hero else .84 if kind=='fast' else .92
        rings('Forearm',[(x*1.13,lean-.098,1.08,.093,.09),((x*1.13+hand_x)/2,(lean-.098+hand_y)/2,(1.08+wrist_z)/2,.082,.09),(hand_x,hand_y,wrist_z,.076,.081)],skin,joint)
        box('Glove',(hand_x,hand_y,wrist_z),(.14,.14,.13),'leather' if hero else skin,joint)
    bpy.ops.object.select_all(action='DESELECT')
    for o in parts:o.select_set(True)
    bpy.context.view_layer.objects.active=parts[0]
    bpy.ops.object.join()
    body=bpy.context.object;body.name='Body';body.parent=rig
    mod=body.modifiers.new('Skin','ARMATURE');mod.object=rig
    def attached(o):
        matrix=o.matrix_world.copy()
        o.parent=rig;o.parent_type='BONE';o.parent_bone='Torso'
        bpy.context.view_layer.update()
        o.matrix_world=matrix
    if hero:
        for idx,length in enumerate([.78,.61,1.04,.46]):
            prefix='Gear'+str(idx)
            def piece(suffix,pos,size,mat):attached(box(prefix+suffix,pos,size,mat,None))
            if idx==3:
                piece('Blade',(.07,-.49,1.22),(.046,.45,.088),'knife')
            else:
                piece('Receiver',(.07,-.31,1.235),(.137,.43,.142),'gun')
                piece('Stock',(.07,-.07,1.22),(.125,.21,.105),'leather')
                piece('Barrel',(.07,-(.45+length)/2,1.261),(.072,length-.45,.072),'metal')
                piece('Cell',(.07,-.348,1.14),(.098,.13,.152),'light')
                if idx==2:piece('Scope',(.07,-.32,1.35),(.071,.22,.072),'gun')
        attached(box('Battery',(-.16,-.35,1.13),(.11,.13,.21),'light',None))
        attached(box('Module',(.13,-.39,1.245),(.062,.17,.083),'metal',None))
        for i,length in enumerate([.78,.61,1.04,.72]):
            o=bpy.data.objects.new('Muzzle'+str(i),None);bpy.context.collection.objects.link(o)
            o.location=(.07,-length,1.261)
            bpy.context.view_layer.update();attached(o)
    source=ROOT/'assets/source/actors_hd'/f'{kind}.blend'
    # Editable pose cycles for offline art review. Godot drives the same joints
    # continuously so a strafe or a charge can blend with arbitrary aim angles.
    clips=['Idle','Walk','Run','Fire','Charge','Dodge','Melee'] if hero else ['Idle','Walk','Windup','Strike','Fall']
    for clip in clips:
        action=bpy.data.actions.new(clip)
        action.use_fake_user=True
        rig.animation_data_create().action=action
        for frame in (1,7,13,19,25):
            t=(frame-1)/24
            step=math.sin(t*math.tau)
            arc=math.sin(t*math.pi)
            for joint in rig.pose.bones:
                joint.rotation_mode='XYZ'
                a=0
                if clip in ('Walk','Run') and joint.name.startswith(('Leg','Shin')):
                    a=(1 if joint.name.endswith('L') else -1)*step*(.65 if clip=='Run' else .42)
                    if joint.name.startswith('Shin'):a=max(0,-a)
                elif joint.name=='Torso':
                    a={'Idle':step*.017,'Fire':arc*.10,'Dodge':arc*1.05,'Windup':arc*.28,'Strike':-arc*.32}.get(clip,0)
                elif joint.name.startswith('Arm'):
                    a={'Charge':arc*.65,'Fire':arc*.16,'Melee':arc*.77,'Strike':arc*.89}.get(clip,0)
                elif clip=='Fall' and joint.name=='Root':a=t*1.49
                joint.rotation_euler=(a,0,0)
                joint.keyframe_insert(data_path='rotation_euler',frame=frame,group=joint.name)
        rig.animation_data.action=None
    for joint in rig.pose.bones:joint.rotation_euler=(0,0,0)
    bpy.context.scene.frame_set(1)
    bpy.ops.wm.save_as_mainfile(filepath=str(source))
    # Store each rigid colour as one palette texel; the crowd body draws in one surface.
    palette=list(mats)
    image=bpy.data.images.new('actor_palette',width=len(palette),height=1)
    pixels=[]
    for key in palette:
        val=PALETTE[key]
        pixels.extend([int(val[i:i+2],16)/255 for i in (0,2,4)]+[1.])
    image.pixels.foreach_set(pixels)
    image.pack()
    skinmat=bpy.data.materials.new('Outfit')
    skinmat.use_nodes=True
    tex=skinmat.node_tree.nodes.new('ShaderNodeTexImage')
    tex.image=image
    tex.interpolation='Closest'
    shader=skinmat.node_tree.nodes['Principled BSDF']
    skinmat.node_tree.links.new(tex.outputs['Color'],shader.inputs['Base Color'])
    uv=body.data.uv_layers.new(name='Palette')
    for face in body.data.polygons:
        column=palette.index(body.data.materials[face.material_index].name)
        for loop in face.loop_indices:uv.data[loop].uv=((column+.5)/len(palette),.5)
    body.data.materials.clear()
    body.data.materials.append(skinmat)
    bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/runtime/actors_hd'/f'{kind}.glb'),export_format='GLB',export_animations=False)
for kind in ['survivor','basic','fast','armored','ranged','boss']:build(kind)
