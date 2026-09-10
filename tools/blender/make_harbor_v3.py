"""Build the harbor's editable geometry in a separate Blender scene through MCP.
Coordinates in helpers are Godot X/Y/Z, converted for Blender's Z-up export.
"""
import bpy, math, random
from pathlib import Path
from mathutils import Vector

ROOT = Path('__PROJECT_ROOT__')
old=bpy.data.scenes.get('HarborV3')
if old:
    for o in list(old.objects):bpy.data.objects.remove(o,do_unlink=True)
    bpy.data.scenes.remove(old)
scene = bpy.data.scenes.new('HarborV3')
bpy.context.window.scene = scene
rng = random.Random(81)
groups = {'Solid': [], 'Decor': [], 'Steps': [], 'Boat': []}
materials = {}
for name, color in {
    'stone': (.26,.30,.33,1), 'wood': (.29,.19,.11,1),
    'plaster': (.44,.40,.32,1), 'metal': (.065,.08,.09,1),
    'ink': (.018,.023,.027,1), 'glass': (.78,.44,.15,1),
    'canvas': (.22,.24,.23,1), 'mint': (.25,.62,.51,1), 'distant': (.14,.20,.25,1)
}.items():
    mat=bpy.data.materials.get('harbor_'+name) or bpy.data.materials.new('harbor_'+name)
    mat.diffuse_color=color
    mat.use_nodes=True
    mat.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value=color
    mat.node_tree.nodes.get('Principled BSDF').inputs['Roughness'].default_value=.72
    materials[name]=mat

def xyz(v): return (v[0],-v[2],v[1])
def finish(obj, mat, group='Decor'):
    obj.data.materials.append(materials[mat]); groups.setdefault(group, []).append(obj)
    return obj
def box(name, p, size, mat, group='Solid', bevel=0):
    bpy.ops.mesh.primitive_cube_add(size=1, location=xyz(p))
    o=bpy.context.object; o.name=name; o.scale=(size[0],size[2],size[1])
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    if bevel:
        m=o.modifiers.new('soft chipped edges','BEVEL');m.width=bevel;m.segments=2
        bpy.ops.object.modifier_apply(modifier=m.name)
    return finish(o,mat,group)
def beam(name,a,b,r,mat='wood',group='Decor',vertices=8):
    a,b=Vector(xyz(a)),Vector(xyz(b)); d=b-a
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices,radius=r,depth=d.length,location=(a+b)/2)
    o=bpy.context.object;o.name=name;o.rotation_mode='QUATERNION';o.rotation_quaternion=d.to_track_quat('Z','Y')
    return finish(o,mat,group)
def curve(name,points,r,mat='metal',group='Decor'):
    data=bpy.data.curves.new(name,'CURVE');data.dimensions='3D';data.bevel_depth=r;data.bevel_resolution=2
    spline=data.splines.new('BEZIER');spline.bezier_points.add(len(points)-1)
    for p,co in zip(spline.bezier_points,points):
        p.co=xyz(co);p.handle_left_type='AUTO' if name in ('rope coil','canopy rib','rope loop') else 'VECTOR';p.handle_right_type=p.handle_left_type
    o=bpy.data.objects.new(name,data);scene.collection.objects.link(o)
    bpy.context.view_layer.objects.active=o;o.select_set(True)
    bpy.ops.object.convert(target='MESH');o=bpy.context.object
    return finish(o,mat,group)
def crate(p,s=1):
    x,y,z=p
    box('crate',p,(s,s,s),'wood',bevel=.025)
    for dz in [-s*.51,s*.51]:
        for dy in [-s*.38,s*.38]:box('crate trim',(x,y+dy,z+dz),(s*1.03,.065,.06),'wood','Decor')
        beam('crate diagonal',(x-s*.42,y-s*.37,z+dz),(x+s*.42,y+s*.37,z+dz),.045,'wood')
    for dx in [-s*.51,s*.51]:
        for dy in [-s*.38,s*.38]:box('crate side',(x+dx,y+dy,z),(.06,.065,s),'wood','Decor')
def barrel(p):
    x,y,z=p
    beam('wooden barrel',(x,y,z),(x,y+1,z),.37,'wood','Solid',12)
    for h in [.12,.82]:beam('barrel hoop',(x,y+h,z),(x,y+h+.055,z),.385,'metal',vertices=12)
def lamp(x,y,z):
    # Wall facing +X; a hanging shade, cage and luminous inner glass.
    beam('lamp arm',(x-.4,y+.4,z),(x+.15,y+.4,z),.045,'metal')
    beam('lamp stem',(x+.15,y+.4,z),(x+.15,y+.15,z),.045,'metal')
    beam('lamp glass',(x+.15,y-.13,z),(x+.15,y+.15,z),.12,'glass',vertices=12)
    for dy in [-.15,.16]:beam('lamp cap',(x+.15,y+dy,z),(x+.15,y+dy+.05,z),.19,'metal',vertices=12)
    for a in [0,math.pi/2,math.pi,math.pi*1.5]:
        dx,dz=math.cos(a)*.16,math.sin(a)*.16
        beam('lamp cage',(x+.15+dx,y-.15,z+dz),(x+.15+dx,y+.19,z+dz),.012,'metal')

# Two genuinely distinct quay levels, with the stair cut out of the upper mass.
box('upper arcade',(-6,1.2,-8),(4,4,36),'stone')
box('upper south apron',(-1.9,1.2,7.5),(4.2,4,5),'stone')
box('lower landing',(-1.4,-.3,-13.7),(5.2,1.8,28.6),'stone')
for i in range(12):
    h=.6+(i+1)*2.6/12
    box('descending stair',(-1.9,h-.15,(i+.5)*5/12),(4.2,.3,5/12+.02),'stone','Steps',.015)
# A proper retaining wall carries the upper workfront.
for z in range(-26,1,2):
    if -19<z<-14:continue
    box('quay coping',(-3.96,3.29,z),(.48,.18,1.95),'stone','Decor',.03)
    box('quay buttress',(-3.84,1.5,z),(.32,3,.34),'stone','Decor')
for i in range(12):
    h=.6+(i+1)*2.6/12
    box('outer stair parapet',(.36,h+.28,(i+.5)*5/12),(.34,.65,.43),'stone','Decor',.02)
# Side stair creates a second connection and makes the lower route bend around it.
for i in range(12):
    h=3.2-i*2.6/12
    box('return stair',(-4+(i+.5)*.3,h-.14,-16.5),(.32,.28,3),'stone','Steps',.012)
for z in [-18.12,-14.88]:
    for i in range(12):
        h=3.2-i*2.6/12
        box('return stair cheek',(-4+(i+.5)*.3,h+.22,z),(.32,.5,.22),'stone','Decor',.02)
# Warehouse walls: an actual opening connects the arcade to the room.
box('interior floor',(-11.5,3.08,-9),(7,.24,10),'wood')
for center,length in [(3.85,2.3),(-.95,2.3),(-6.85,1.7)]:box('front south',(-8.14,6.5,center),(.28,6.6,length),'plaster')
box('loading lintel',(-8.14,8,-1.35),(.28,3.6,12.7),'plaster')
for z in [1.5,-4.1]:
    box('recess floor',(-9.6,3.08,z),(3.2,.24,2.8),'wood')
    box('recess back',(-11.2,4.7,z),(.22,3,2.8),'ink')
    box('recess cargo',(-10,3.85,z),(1.3,1.3,1.1),'wood')
    box('recess upper cargo',(-10.2,5,z),(1,1,1.1),'wood')
box('front north',(-8.14,6.5,-16.15),(.28,6.6,11.7),'plaster')
box('door lintel',(-8.14,8,-9),(.28,3.6,2.6),'plaster')
box('back wall',(-15,5.4,-9),(.3,4.4,10),'plaster')
for z in [-14,-4]:box('room side',(-11.5,5.4,z),(7,4.4,.3),'plaster')
box('room ceiling',(-11.5,7.5,-9),(7,.22,10),'wood')
for z in range(-22,6,3):
    box('facade stud',(-7.91,6.5,z),(.23,6.6,.20),'wood','Decor')
    box('arcade post',(-5.15,4.9,z),(.19,3.4,.19),'wood','Solid')
    box('post plinth',(-5.15,3.38,z),(.33,.35,.33),'stone','Decor')
    beam('bracket',(-5.15,5.3,z),(-6.3,6.4,z),.085)
    beam('roof joist',(-8,6.4,z),(-4.8,6.1,z),.09)
    lamp(-7.6,5.25,z+.65)
for y in [3.6,6.55,9.6]:box('timber band',(-7.85,y,-8.5),(.25,.23,27),'wood','Decor')
roof=box('arcade awning',(-6.5,6.45,-8.5),(3.7,.18,28),'wood','Decor')
roof.rotation_euler.y=math.radians(-5)
for z in range(-21,5,3):
    box('upper window',(-7.94,8.25,z),(.08,1.8,1.35),'ink','Decor')
    box('lit upper window',(-7.87,8.25,z),(.04,1.55,1.1),'glass','Decor')
    for dz in [-.64,0,.64]:box('window mullion',(-7.78,8.25,z+dz),(.1,1.9,.10),'wood','Decor')
    for y in [7.3,8.25,9.2]:box('window rail',(-7.78,y,z),(.1,.09,1.4),'wood','Decor')
    if z%2:box('half shutter',(-7.7,8.25,z+.45),(.12,1.8,.44),'wood','Decor')
for x,a in [(-9.8,-17),(-13.5,17)]:
    o=box('pitched roof',(x,10.15,-8.5),(4.1,.2,28.6),'metal','Decor');o.rotation_euler.y=math.radians(a)
for z in [-20,-11,1]:
    curve('rain pipe',[(-7.65,9.8,z),(-7.65,6.7,z),(-7.5,6.25,z),(-7.5,3.4,z)],.055)
# Rounded retroelectric equipment close enough to read from the approach.
box('electric case',(-7.58,4.55,1.4),(.45,1.35,.72),'metal','Decor',.10)
box('case lid',(-7.31,4.55,1.4),(.06,1.18,.59),'metal','Decor',.05)
beam('mint instrument',(-7.26,4.85,1.4),(-7.21,4.85,1.4),.12,'mint',vertices=20)
for offset in [-.18,.14]:
    curve('power trunk',[(-7.6,5.7,1.4+offset),(-7.1,3.7,1.4+offset),(-4.1,3.6,-2+offset),(-3.72,1.5,-24+offset),(.6,1.1,-26+offset),(1.05,.85,-12+offset),(2.4,.9,-10+offset)],.044)
    for h in [4.8,5,5.2]:beam('ceramic collar',(-7.58,h,2+offset),(-7.58,h+.07,2+offset),.09,'plaster')
# Cargo is grouped in the recesses, leaving the continuous walking route.
for p,s in [((-7,3.75,4),1.1),((-7,4.8,4),.95),((-3.1,1.1,-1.2),.9),((-3.1,2,-1.2),.85),((-2.1,1.05,-1.6),.8),((-3.1,1.1,-11),1),((-3.1,2.05,-11),.9),((.1,1.1,-25),1),((-13.8,3.8,-12.7),1.2),((-13.8,5,-12.7),1.1),((-11.9,3.75,-12.7),1.1)]:crate(p,s)
for p in [(-6.9,3.2,-18),(-3,.6,-19),(.2,.6,-10),(-13.7,3.2,-5.4)]:barrel(p)
# A simple sack has a softened irregular outline rather than another cube.
for i in range(8):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=10,ring_count=6,location=xyz((-6.9+(i%2)*.5,3.42+(i//2)*.32,1.6)))
    o=bpy.context.object;o.scale=(.48,.29,.22);finish(o,'plaster')
box('workbench',(-13.6,4.18,-8),(1.1,.18,3.2),'wood')
for z in [-9.3,-6.7]:box('bench legs',(-13.6,3.65,z),(.15,.9,.15),'wood')
for z in [-9,-8,-7]:beam('bottles',(-13.5,4.3,z),(-13.5,4.7,z),.09,'metal')
for z in [-13,-10,-7,-4]:box('interior ceiling joist',(-11.5,7.26,z),(7,.26,.18),'wood','Decor')
# A tall marker and receding roofs vary the far end silhouette.
for z,h,w in [(-26,11,8),(-35,15,6),(-44,9,9)]:
    box('back warehouse',(-8-w/2,h/2+3.2,z),(w,h,8),'plaster','Decor')
    box('roof cornice',(-8-w/2,h+3.25,z),(w+.5,.35,8.5),'stone','Decor')
    for yy in [5,8,11,14]:
        if yy>h+2:continue
        for zz in [-2.5,0,2.5]:
            box('deep window',(-7.96,yy,z+zz),(.08,1.5,1),'ink','Decor')
            if (int(yy+zz)%3):box('warm window',(-7.9,yy,z+zz),(.05,1.1,.64),'glass','Decor')
# Raised landmark visible above the receding roofs, blank dial has hands but no numerals.
box('quay tower',(-5.8,9.3,-26),(3.6,12.2,4),'plaster','Decor')
for y in [3.5,8.3,11.2,15.3]:box('tower cornice',(-5.8,y,-26),(4.1,.28,4.4),'stone','Decor')
for x in [-7.45,-4.15]:box('tower pilaster',(x,9.3,-23.92),(.22,12,.18),'stone','Decor')
beam('tower face',(-5.8,13.3,-23.92),(-5.8,13.3,-23.8),.84,'glass',vertices=32)
beam('tower hour',(-5.8,13.3,-23.73),(-5.3,13.06,-23.73),.035,'metal')
beam('tower minute',(-5.8,13.3,-23.73),(-5.8,13.98,-23.73),.035,'metal')
for x,a in [(-6.9,-25),(-4.7,25)]:
    o=box('tower pitched cap',(x,16.0,-26),(2.6,.22,4.7),'metal','Decor');o.rotation_euler.y=math.radians(a)
beam('tower finial',(-5.8,16.4,-26),(-5.8,17.3,-26),.06,'metal')
# Dial without numerals; invented light-disc landmark.
beam('tower dial',(-7.8,15,-35),(-7.65,15,-35),.8,'glass',vertices=32)
beam('tower hand',(-7.6,15,-35),(-7.6,15.55,-35),.035,'metal')
beam('tower hand',(-7.6,15,-35),(-7.6,15,-34.6),.035,'metal')
for a,b in [((-3.6,3.2,-22),(-3.6,10,-22)),((-3.6,8,-22),(5.5,11,-23)),((-3.6,4,-22),(5.5,11,-23))]:beam('crane truss',a,b,.15,'metal')
beam('cargo cable',(5.5,11,-23),(5.5,6,-23),.035,'metal');crate((5.5,5.35,-23),1.25)
# Long shallow boat; shelter offset toward its stern, open bow deck facing the viewer.
cx,cz=3.8,-8
outline=[(-1.65,-6.2),(-1,-7.5),(1,-7.5),(1.65,-6.2),(1.65,5.9),(.55,7.5),(-.55,7.5),(-1.65,5.9)]
verts=[xyz((cx+x*(.7 if y<0 else 1),y,cz+z)) for y in [-.65,.35] for x,z in outline]
n=8;faces=[tuple(range(7,-1,-1)),tuple(range(8,16))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
m=bpy.data.meshes.new('hull');m.from_pydata(verts,[],faces);m.update();o=bpy.data.objects.new('barge hull',m);scene.collection.objects.link(o);finish(o,'metal','Boat')
box('deck',(cx,.41,cz),(3,.14,12.8),'wood','Boat')
for x in [-1.58,1.58]:box('gunwale',(cx+x,.66,cz),(.16,.38,12.2),'wood','Boat')
box('stern cabin',(cx,1.4,cz-4.5),(2.7,1.8,2.7),'wood','Boat')
box('cabin roof',(cx,2.4,cz-4.5),(3.1,.2,3.1),'metal','Boat',.06)
for z in [-5.2,-3.7]:
    box('cabin window',(cx-1.37,1.6,cz+z),(.035,.86,.88),'glass','Boat')
    for dz in [-.45,0,.45]:box('window trim',(cx-1.41,1.6,cz+z+dz),(.06,.96,.07),'wood','Boat')
# Curved tarpaulin ribs and a real open side expose the warm cargo interior.
for z in [-10,-8,-6,-4]:
    curve('canopy rib',[(cx-1.45,.5,z),(cx-1.45,2,z),(cx,2.55,z),(cx+1.45,2,z),(cx+1.45,.5,z)],.045,'metal','Boat')
# Uneven cloth profile: flattened ridge, subtle longitudinal sag and hanging scallops.
verts=[];faces=[]
for row in range(19):
    z=-10.2+row*6.4/18
    sag=.05*math.cos(row*math.pi/3)
    for col in range(13):
        t=col/12
        x=cx+(t-.5)*3.16
        y=2.24+.44*math.sin(math.pi*t)+sag+.015*math.cos(col*2+row)
        verts.append(xyz((x,y,z)))
for row in range(18):
    for col in range(12):
        q=row*13+col;faces.append((q,q+1,q+14,q+13))
m=bpy.data.meshes.new('cloth');m.from_pydata(verts,[],faces);m.update()
o=bpy.data.objects.new('sagging tarpaulin',m);scene.collection.objects.link(o);finish(o,'canvas','Boat')
for side in [-1,1]:
    for i in range(12):
        z=-9.94+i*.53
        flap=box('canvas scallop',(cx+side*1.59,2.12+.035*math.cos(i),z),(.025,.3,.53),'canvas','Boat')
        flap.rotation_euler.y=side*.06
for z in [-10,-8,-6,-4]:
    curve('roof tie',[(cx-1.65,.8,z),(cx-1.65,2.1,z),(cx,2.58,z),(cx+1.65,2.1,z),(cx+1.65,.8,z)],.015,'wood','Boat')
for z in [-13,-11,-9,-7,-5,-3,-1]:
    for side in [-1,1]:box('hull rib',(cx+side*1.58,.13,z),(.15,.65,.13),'wood','Boat')
for z in [-13,-12,-11]:box('deck step',(cx,.6+(z+13)*.035,z),(2.8,.17,.3),'wood','Boat')
for i in range(5):
    curve('deck rope',[(cx-.45+math.cos(a)*(.32+i*.04),.52+i*.015,-1.1+math.sin(a)*(.32+i*.04)) for a in [k*math.tau/16 for k in range(17)]],.026,'wood','Boat')
beam('stack',(cx+.5,2.4,-12.5),(cx+.5,3.8,-12.5),.16,'metal','Boat',16)
beam('stack rim',(cx+.5,3.7,-12.5),(cx+.5,3.85,-12.5),.2,'metal','Boat',16)
box('far canvas side',(cx+1.46,1.3,-7),(.05,1.55,6.3),'canvas','Boat')
for z in [-9.7,-4.3]:
    lamp(cx-1.2,1.7,z)
    box('boat crate',(cx,.85,z),(1,.8,1),'wood','Boat')
beam('winch drum',(cx-.45,.9,-1.8),(cx+.45,.9,-1.8),.38,'metal','Boat',16)
for x in [cx-.53,cx+.53]:beam('winch end',(x,.9,-1.8),(x+.08,.9,-1.8),.44,'metal','Boat',16)
beam('mast',(cx+1.1,.5,-3),(cx+1.1,3.7,-3),.065,'wood','Boat')
curve('mast stay',[(cx-1.4,.6,-.8),(cx+1.1,3.7,-3),(cx+1.4,.6,-12)],.019,'metal','Boat')
for z in [-24,-18,-12,-6,0]:
    beam('bollard',(1,.6,z),(1,1.4,z),.15,'wood','Solid',12)
    for h in [.85,.92,1]:curve('rope coil',[(1+math.cos(a)*.22,h,z+math.sin(a)*.22) for a in [i*math.tau/12 for i in range(13)]],.035,'wood')
    if z in [-12,-6]:curve('mooring line',[(1,1,z),(1.7,.75,z+.7),(2.3,.7,z+1)],.04,'wood')
# Visible railing also communicates the river boundary.
beam('edge rope',(1.2,1.15,-28),(1.2,1.15,-3.2),.025,'wood')
beam('edge rope',(1.2,1.15,-2),(1.2,1.15,0),.025,'wood')
for z in [-28,10]:
    for x in [-7,-5,-3,-1,1,3,5]:beam('end post',(x,.6 if z<0 else 3.2,z),(x,1.6 if z<0 else 4.2,z),.06,'metal')
    beam('end rail',(-8,1.6 if z<0 else 4.2,z),(5 if z<0 else .2,1.6 if z<0 else 4.2,z),.055,'metal')
# A second boat with a different silhouette closes the midground gap.
ox,oz=10,-24
outline2=[(-1.7,-4),(-1,-5.5),(1,-5.5),(1.7,-4),(1.7,4),(.7,5.3),(-.7,5.3),(-1.7,4)]
verts=[xyz((ox+x*(.65 if y<0 else 1),y,oz+z)) for y in [-.6,.65] for x,z in outline2]
m=bpy.data.meshes.new('tug hull');m.from_pydata(verts,[],[tuple(range(7,-1,-1)),tuple(range(8,16))]+[(i,(i+1)%8,(i+1)%8+8,i+8) for i in range(8)]);m.update()
o=bpy.data.objects.new('tug hull',m);scene.collection.objects.link(o);finish(o,'metal','Boat')
box('tug deck',(ox,.7,oz),(3.1,.16,8),'wood','Boat')
box('tug house',(ox,1.55,oz-1),(2.2,1.7,2.5),'wood','Boat')
box('tug roof',(ox,2.48,oz-1),(2.7,.18,3),'metal','Boat')
for z in [-1.8,-.3]:box('tug window',(ox-1.12,1.9,oz+z),(.03,.65,.7),'glass','Boat')
for x in [-.65,.65]:box('front tug window',(ox+x,1.9,oz+.28),(.6,.65,.03),'glass','Boat')
beam('tug funnel',(ox+.2,.7,oz-2.9),(ox+.2,4.2,oz-2.9),.27,'metal','Boat',16)
beam('funnel band',(ox+.2,3.4,oz-2.9),(ox+.2,3.65,oz-2.9),.28,'wood','Boat',16)
for x in [-1.6,1.6]:beam('tug rail',(ox+x,1.1,oz-3.5),(ox+x,1.1,oz+3.5),.04,'metal','Boat')
for z in [-2,0,2]:
    beam('tug stanchion',(ox-1.6,.7,oz+z),(ox-1.6,1.1,oz+z),.04,'metal','Boat')
    bpy.ops.mesh.primitive_torus_add(major_radius=.30,minor_radius=.10,major_segments=16,minor_segments=6,location=xyz((ox-1.74,.38,oz+z)),rotation=(0,math.pi/2,0))
    finish(bpy.context.object,'ink','Boat')
# Short diagonal landing and gangboard clearly connect quay and open boat deck.
box('boarding ledge',(1.35,.48,-2.6),(1.1,.24,2.2),'wood','Solid')
box('gangboard',(1.95,.49,-2.6),(1.7,.1,1.1),'wood','Solid')
for x in [1.2,1.6,2,2.4]:box('gangboard batten',(x,.56,-2.6),(.08,.055,1.1),'wood','Decor')
# Regional batches retain light locality in Compatibility rendering.
from collections import defaultdict
batches=defaultdict(list)
for group,objects in groups.items():
    for o in objects:
        loc=o.location
        batches[(group,round(loc.x/8),round(loc.y/10))].append(o)
for (group,x,z),objects in batches.items():
    bpy.ops.object.select_all(action='DESELECT')
    for o in objects:o.select_set(True)
    bpy.context.view_layer.objects.active=objects[0];bpy.ops.object.join()
    o=bpy.context.object;o.name=f'Harbor{group}_{x}_{z}'
    bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art/harbor-v3/harbor.blend'))
bpy.ops.export_scene.gltf(filepath=str(ROOT/'game/assets/harbor-v3/harbor.glb'),export_format='GLB',use_active_scene=True,export_yup=True)
print('HARBOR_V3_EXPORTED',len(scene.objects))
