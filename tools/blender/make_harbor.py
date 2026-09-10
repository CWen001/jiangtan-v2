"""Build the harbor's editable geometry in a separate Blender scene through MCP.
Coordinates in helpers are Godot X/Y/Z, converted for Blender's Z-up export.
"""
import bpy, math, random
from pathlib import Path
from mathutils import Vector

ROOT = Path('__PROJECT_ROOT__')
scene = bpy.data.scenes.new('HarborLanding')
bpy.context.window.scene = scene
rng = random.Random(81)
groups = {'Solid': [], 'Decor': [], 'Steps': [], 'Boat': []}
materials = {}
for name, color in {
    'stone': (.26,.30,.33,1), 'wood': (.29,.19,.11,1),
    'plaster': (.44,.40,.32,1), 'metal': (.065,.08,.09,1),
    'ink': (.018,.023,.027,1), 'glass': (.78,.44,.15,1),
    'mint': (.25,.62,.51,1), 'distant': (.14,.20,.25,1)
}.items():
    mat=bpy.data.materials.get('harbor_'+name) or bpy.data.materials.new('harbor_'+name)
    mat.diffuse_color=color
    mat.use_nodes=True
    mat.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value=color
    mat.node_tree.nodes.get('Principled BSDF').inputs['Roughness'].default_value=.72
    materials[name]=mat

def xyz(v): return (v[0],-v[2],v[1])
def finish(obj, mat, group='Decor'):
    obj.data.materials.append(materials[mat]); groups[group].append(obj)
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
        p.co=xyz(co);p.handle_left_type='AUTO';p.handle_right_type='AUTO'
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

# Main platforms and the building room. Door opening is z -5.2..-2.8.
box('upper quay',(1,0,-1.5),(8,2.4,25),'stone')
box('lower quay',(8.7,-.4,-1.5),(2.6,.8,25),'stone')
for i in range(6):
    top=1.2-i*.2
    box('stone stair',(5.2+i*.4,top-.15,-1.5),(.4,.3,25),'stone','Steps',.018)
box('room floor',(-7,1.05,-4),(8,.3,8),'wood')
box('front south',(-3.15,4.4,-.25),(.3,6.4,5.1),'plaster')
box('building foundation',(-7,-.25,-6),(8,2.5,18),'stone')
box('front north',(-3.15,4.4,-10),(.3,6.4,9.6),'plaster')
box('door lintel',(-3.15,5.7,-4),(.3,3.8,2.4),'plaster')
box('back wall',(-11,4.4,-4),(.35,6.4,8),'plaster')
for z in [-8,0]:box('side wall',(-7,4.4,z),(8,6.4,.3),'plaster')
box('ceiling',(-7,5.2,-4),(8,.16,8),'wood')
for z in [-14,-10,-8,-5.32,-2.68,0,2]:
    box('front timber',(-2.91,4.5,z),(.25,6.6,.24),'wood')
    box('pillar foot',(-2.85,1.35,z),(.40,.3,.4),'stone')
for y in [4.4,7.2]:box('long timber band',(-2.92,y,-6),(.24,.22,17),'wood')
for center,length in [(-9.8,9.2),(-.2,5.2)]:box('low timber band',(-2.92,1.6,center),(.24,.22,length),'wood')
for x,angle in [(-4.9,-13),(-9.0,13)]:
    r=box('pitched warehouse roof',(x,7.6,-6),(4.8,.22,18.4),'metal','Decor')
    r.rotation_euler.y=math.radians(angle)
for z in [-7,-4,-1]:box('ceiling beam',(-7,4.96,z),(8,.26,.22),'wood','Decor')
for z in [-12,-8,-4,0]:
    box('window inset',(-2.96,5.9,z),(.1,1.6,1.3),'ink','Decor')
    box('window warm',(-2.88,5.9,z),(.06,1.42,1.1),'glass','Decor')
    for dz in [-.6,0,.6]:box('window mullion',(-2.8,5.9,z+dz),(.08,1.6,.07),'wood','Decor')
    for dy in [-.8,0,.8]:box('window rail',(-2.8,5.9+dy,z),(.08,.075,1.3),'wood','Decor')
    for dy in [-.4,-.3,-.2,.4,.5]:box('window slat',(-2.77,5.9+dy,z),(.06,.07,1.2),'wood','Decor')
for z in [-7.8,-.2]:
    beam('awning brace',(-2.8,3.3,z),(-1.5,4.2,z),.07)
roof=box('door awning',(-2.0,4.34,-4),(2.2,.18,8.3),'wood','Decor')
roof.rotation_euler.y=math.radians(-8)
box('eaves shadow',(-2.75,7.5,-6),(1,.28,18),'wood','Decor')
for z in [-11,-6.1,-1.8,1]:lamp(-2.65,3.45,z)
for z in [-12,-7,0]:
    curve('rain downpipe',[(-2.65,7.5,z),(-2.65,6.8,z),(-2.75,6.5,z),(-2.75,1.6,z)],.045)
for z in [-12,-8,-4,0]:
    curve('slack utility wire',[(-2.78,6.9,z-1.4),(-2.72,6.7,z),(-2.78,6.9,z+1.4)],.016)
# A small rounded electrical cabinet, pipe runs and ceramic separators.
box('power cabinet',(-2.63,2.56,-6.15),(.3,.95,.6),'metal','Decor',.09)
box('cabinet front',(-2.43,2.56,-6.15),(.06,.78,.46),'metal','Decor',.035)
box('cabinet handle',(-2.36,2.38,-5.99),(.08,.2,.055),'metal','Decor',.02)
beam('indicator',(-2.39,2.74,-6.15),(-2.33,2.74,-6.15),.085,'mint',vertices=16)
for dz in [-.11,.09]:
    curve('power cable',[(-2.7,3.5,-6.5+dz),(-2.65,1.85,-6.5+dz),(-2.15,1.6,-6.5+dz),(2,1.48,-8+dz),(6,1.3,-8+dz)],.027)
    for yy in [2.3,2.5,2.7]:beam('ceramic collar',(-2.7,yy-.045,-6.5+dz),(-2.7,yy+.045,-6.5+dz),.055,'plaster',vertices=12)
# Room furniture and quay clutter leave the door and central path clear.
for pos,size in [((-9,1.8,-7),1.2),((-9,3,-7),1.1),((-8,1.7,-1),1),((-5,1.7,-7),1),((-1.5,1.75,1.5),1.1),((-1.4,2.8,1.5),.9),((8.6,.55,-9),1.1)]:crate(pos,size)
for pos in [(-9,1.2,-2),(-1.7,1.2,-10),(8.4,0,7)]:barrel(pos)
box('workbench',(-9,2.15,-4),(1.2,.16,2.2),'wood')
for z in [-4.8,-3.2]:box('table legs',(-9,1.6,z),(.14,.9,.14),'wood')
for z in [-10,-4,3,9]:
    beam('bollard',(9.4,0,z),(9.4,.85,z),.17,'wood','Solid',12)
    for h in [.25,.32,.39]:
        pts=[(9.4+math.cos(a)*.21,h,z+math.sin(a)*.21) for a in [i*math.tau/16 for i in range(17)]]
        curve('rope loop',pts,.035,'wood')
# Distant continuation warehouses and crane create depth without extra rooms.
for z,h in [(-19,8),(-29,10),(-40,7)]:
    box('distant warehouse',(-7,h/2+1.2,z),(9,h,8),'plaster','Decor')
    for yy in [3,5.8,8.3]:
        if yy>h:continue
        for zz in [-2,0,2]:
            box('distant inset',(-2.43,yy,z+zz),(.06,1.3,.8),'ink','Decor')
            box('distant lit window',(-2.38,yy,z+zz),(.04,1.1,.65),'glass','Decor')
    for yy in [2,4.8,7.5]:box('distant band',(-2.4,yy,z),(.15,.14,8),'wood','Decor')
beam('crane upright',(2,1.2,-12),(2,6.5,-12),.18,'metal')
beam('crane boom',(2,5,-12),(8,7,-14),.15,'wood')
beam('crane brace',(2,2,-12),(7.6,6.8,-14),.08,'metal')
beam('hanging cable',(8,7,-14),(8,3.6,-14),.025,'metal')
crate((8,3.15,-14),.9)
# Barge hull, perimeter edges and warm glazed cabin. Not a traversable vehicle.
cx,cz=12,-3
outline=[(-1.35,-4.5),(-.7,-5.6),(.7,-5.6),(1.35,-4.5),(1.35,4.5),(.7,5.2),(-.7,5.2),(-1.35,4.5)]
verts=[xyz((cx+x*(.72 if y<0 else 1),y,cz+z)) for y in [-.65,.32] for x,z in outline]
n=len(outline);faces=[tuple(range(n-1,-1,-1)),tuple(range(n,2*n))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
mesh=bpy.data.meshes.new('hull');mesh.from_pydata(verts,[],faces);mesh.update()
o=bpy.data.objects.new('barge hull',mesh);scene.collection.objects.link(o);finish(o,'metal','Boat')
box('deck',(cx,.36,cz),(2.4,.12,8.7),'wood','Boat')
for x in [-1.3,1.3]:box('gunwale',(cx+x,.65,cz),(.13,.35,8.8),'wood','Boat')
box('cabin body',(cx,1.4,cz-1),(2.25,1.95,3.4),'wood','Boat')
box('cabin roof',(cx,2.48,cz-1),(2.6,.18,3.8),'metal','Boat',.08)
for z in [-2,0]:
    box('boat window',(cx-1.14,1.6,cz+z),(.03,.85,.85),'glass','Boat')
    for dz in [-.46,.46]:box('boat frame',(cx-1.19,1.6,cz+z+dz),(.06,1.0,.08),'wood','Boat')
    for dy in [-.46,.46,0]:box('boat frame',(cx-1.19,1.6+dy,cz+z),(.06,.075,1),'wood','Boat')
beam('boat chimney',(cx+.4,2.5,cz-1),(cx+.4,3.5,cz-1),.11,'metal','Boat',12)
for z in [-6,3]:curve('mooring rope',[(9.4,.5,z),(10.6,.3,z-.5),(11,.68,z-1)],.03,'wood')
# Visible limits on traversable platforms; no invisible river wall.
for z in [-13.6,10.8]:
    for x in [0,2,4,8,10]:beam('end railing post',(x,0 if x>7 else 1.2,z),(x,1.0 if x>7 else 2.2,z),.05,'metal','Solid')
    beam('end railing',( -2,2.2,z),(5,2.2,z),.04,'metal','Solid')
    beam('lower end railing',(7.4,1,z),(10,1,z),.04,'metal','Solid')
# Join by collision/representation domain to keep runtime draw overhead bounded.
for name,objects in groups.items():
    bpy.ops.object.select_all(action='DESELECT')
    for o in objects:o.select_set(True)
    bpy.context.view_layer.objects.active=objects[0]
    bpy.ops.object.join();o=bpy.context.object;o.name='Harbor'+name
    bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art/harbor/harbor.blend'))
bpy.ops.export_scene.gltf(filepath=str(ROOT/'game/assets/harbor/harbor.glb'),export_format='GLB',use_active_scene=True,export_yup=True)
print('HARBOR_EXPORTED', len(scene.objects))
