"""Executed INSIDE Blender via execute_blender_code, dimensions in metres."""
import bpy
import math
import json
from mathutils import Vector, Quaternion

ROOT = '__PROJECT_ROOT__'
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)

def material(name, color, metallic=0):
    m = bpy.data.materials.new(name)
    m.diffuse_color = (*color, 1)
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get('Principled BSDF')
    bsdf.inputs['Base Color'].default_value = (*color, 1)
    bsdf.inputs['Roughness'].default_value = .87
    bsdf.inputs['Metallic'].default_value = metallic
    return m

ink = material('Ink_charcoal', (.018,.023,.029))
steel = material('Petrol_blue_steel', (.12,.25,.27), .35)
edge = material('Steel_worn_edges', (.34,.45,.40), .4)
wood = material('Ochre_crate_wood', (.44,.26,.105))
woodlight = material('Wood_exposed_grain', (.68,.44,.20))
rust = material('Pipe_burnt_umber', (.28,.12,.065), .25)
paper = material('Discarded_cream_paper', (.65,.56,.40))

def finish(o, name, mat):
    o.name = name
    o.data.materials.append(mat)
    return o

def box(name, loc, dims, mat):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    o = bpy.context.object
    o.dimensions = dims
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return finish(o, name, mat)

def cylinder(name, loc, radius, depth, mat, vertices=16):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=loc)
    return finish(bpy.context.object, name, mat)

def rod(name, a, b, radius, mat):
    a,b = Vector(a),Vector(b)
    o = cylinder(name,(a+b)/2,radius,(b-a).length,mat,12)
    o.rotation_euler = (b-a).to_track_quat('Z','Y').to_euler()
    return o

# Squat ribbed dustbin, graphic dark seams and a dented tilted lid.
cx,cy = -.46, 0
cylinder('Bin_ink_shell',(cx,cy,.43),.295,.84,ink)
cylinder('Bin_blue_body',(cx,cy,.44),.282,.80,steel)
for z in (.065,.79):
    cylinder('Bin_black_rim',(cx,cy,z),.302,.045,ink)
    cylinder('Bin_rim_highlight',(cx,cy,z+.01),.306,.013,edge)
for i in range(14):
    angle = i*math.tau/14
    rod('Bin_pressed_vertical_rib',(cx+.282*math.cos(angle),cy+.282*math.sin(angle),.10),(cx+.282*math.cos(angle),cy+.282*math.sin(angle),.74),.012,edge)
lid=cylinder('Bin_lid_ink',(cx+.018,cy,.88),.326,.042,ink)
lid.rotation_euler[1]=-.08
cap=cylinder('Bin_lid_blue',(cx+.018,cy,.902),.310,.018,steel)
cap.rotation_euler[1]=-.08
box('Bin_lid_handle',(cx,cy,.947),(.14,.045,.038),ink)
for dx in (-.32,.32):
    box('Bin_side_handle',(cx+dx,cy,.65),(.05,.13,.035),ink)

# Crate with individual slats, nails and exaggerated ink gaps.
box('Crate_dark_interior',(.34,-.015,.25),(.63,.52,.5),ink)
for side in (-1,1):
    for i in range(4):
        z=.07+i*.12
        box('Crate_front_back_slat',(.34,side*.274,z),(.66,.045,.10),wood if i%2 else woodlight)
        box('Crate_side_slat',(.34+side*.345,0,z),(.043,.52,.10),wood)
        for x in (.07,.61):
            nail=cylinder('Crate_nail',(x,side*.3,z),.009,.005,ink,8)
            nail.rotation_euler[0]=math.pi/2
    box('Crate_vertical_strap',(.34+side*.265,-.306,.25),(.045,.026,.49),ink)
for i in range(5):
    box('Crate_top_slat',(.08+i*.13,0,.52),(.117,.56,.036),woodlight if i%2 else wood)
brace=box('Crate_diagonal_brace',(.34,-.331,.25),(.56,.035,.045),woodlight)
brace.rotation_euler[1]=-.58
for i in range(5):
    grain=box('Crate_drawn_grain',(.12+i*.093,-.299,.15+(i%3)*.12),(.065,.003,.005),ink)
    grain.rotation_euler[1]=.10 if i%2 else -.10

# Upright bent service pipe behind the crate, flanges and bolt silhouettes.
rod('Service_pipe_vertical',(.72,.23,.06),(.72,.23,1.30),.06,rust)
rod('Service_pipe_elbow',(.72,.23,1.30),(.48,.23,1.48),.065,rust)
rod('Service_pipe_top',(.48,.23,1.48),(.15,.23,1.48),.065,rust)
for z in (.14,.93):
    cylinder('Pipe_flange',(.72,.23,z),.102,.035,ink)
    cylinder('Pipe_flange_rust',(.72,.23,z+.018),.090,.015,rust)
    for i in range(6):
        angle=i*math.tau/6
        cylinder('Pipe_bolt',(.72+.073*math.cos(angle),.23+.073*math.sin(angle),z+.031),.012,.017,edge,6)
rod('Pipe_dark_opening',(.143,.23,1.48),(.14,.23,1.48),.045,ink)
for i in range(3):
    o=box('Loose_paper',(-.15+i*.22,-.36,.016+i*.001),(.18,.12,.006),paper)
    o.rotation_euler[2]=i*.6-.4

bpy.ops.object.select_all(action='SELECT')
for o in bpy.context.selected_objects:
    if o.type=='MESH':
        bpy.context.view_layer.objects.active=o
        bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
verts=[o.matrix_world@Vector(c) for o in bpy.context.scene.objects if o.type=='MESH' for c in o.bound_box]
bounds={'min':[min(v[i] for v in verts) for i in range(3)],'max':[max(v[i] for v in verts) for i in range(3)]}
mesh_count=sum(o.type=='MESH' for o in bpy.context.scene.objects)
bpy.context.scene.unit_settings.system='METRIC'
bpy.context.scene['asset_provenance']='Original procedural prop design; built through real Blender MCP execute_blender_code.'
for screen in bpy.data.screens:
    for area in screen.areas:
        if area.type=='VIEW_3D':
            area.spaces.active.shading.type='MATERIAL'
            area.spaces.active.region_3d.view_distance=3.6
            area.spaces.active.region_3d.view_location=Vector((0,0,.65))
            area.spaces.active.region_3d.view_rotation=Quaternion((.88,.35,.12,.28)).normalized()
bpy.ops.wm.save_as_mainfile(filepath=ROOT+'/art/blender/street_props.blend')
# Preserve editable objects in the blend source; merge runtime geometry so
# the GLB draws once per material rather than once per small bolt and slat.
bpy.context.view_layer.objects.active = bpy.context.selected_objects[0]
bpy.ops.object.join()
bpy.context.object.name = 'StreetProps'
bpy.context.scene.cursor.location = (0,0,0)
bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
bpy.ops.export_scene.gltf(filepath=ROOT+'/game/assets/models/street_props.glb',export_format='GLB',export_yup=True,use_selection=True,export_cameras=False,export_lights=False)
print(json.dumps({'mesh_count':mesh_count,'bounds_blender_z_up':bounds,'godot_y_up':True,'glb':'game/assets/models/street_props.glb'}))
