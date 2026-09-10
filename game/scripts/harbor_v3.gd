extends "res://scripts/harbor.gd"

const Fighter = preload("res://scripts/harbor_fighter.gd")
var fighters: Array = []
var health := 100
var guarding := false
var swing := 0.0
var swing_hit := false
var left_hand := false
var hands: TextureRect
var hand_atlas: AtlasTexture
var flash: ColorRect
var health_bar: ColorRect
var hit_flash := 0.0
var door_pivot: Node3D
var route_testing := false
var fight_capture := false
var wet_stone: ShaderMaterial
var water_paint: ShaderMaterial
var touch_mode := false
var touch_testing := false
var touch_controls: Control

func _ready() -> void:
	view_id="arrival"
	touch_mode=OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()
	if OS.has_feature("web"):
		touch_mode=touch_mode or bool(JavaScriptBridge.eval("new URLSearchParams(location.search).get('touch') === '1' || navigator.maxTouchPoints > 0"))
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):capture_path=arg.trim_prefix("--capture=")
		if arg.begins_with("--view="):view_id=arg.trim_prefix("--view=")
		if arg=="--v3-test":testing=true
		if arg=="--render-test":render_test=true
		if arg=="--touch-test":touch_testing=true;touch_mode=true
		if arg=="--touch":touch_mode=true
	if touch_mode:Input.emulate_mouse_from_touch=false
	setup_inputs()
	build_environment()
	var model: Node3D=load("res://assets/harbor-v3/harbor.glb").instantiate()
	add_child(model)
	configure_meshes(model)
	build_slope()
	build_door()
	build_water()
	build_distant_shore()
	build_quay_lamps()
	if touch_mode:
		for child in get_children():
			if child is OmniLight3D:child.shadow_enabled=false
	player=Player.new()
	add_child(player)
	player.collision_mask=3
	player.floor_snap_length=.45
	set_view(view_id)
	var people={"courier":Vector3(-.4,.62,-1.8),"porter":Vector3(-1,.62,-13),"electrician":Vector3(-5.7,3.22,-1),"boatman":Vector3(-.1,.62,-22),"watchman":Vector3(-5.7,3.22,-15),"cargo_worker":Vector3(-11.5,3.22,-10)}
	for id in people:
		var person=Fighter.new()
		person.identity=id;person.world=self;person.position=people[id]
		add_child(person);fighters.append(person)
	build_ui()
	build_rain()
	if touch_mode:
		touch_controls=load("res://scripts/touch_controls.gd").new()
		touch_controls.world=self;ui.add_child(touch_controls)
	if touch_testing:
		run_touch_test.call_deferred()
	elif testing:
		player.headless_input=true
		run_test.call_deferred()
	elif not capture_path.is_empty():
		player.active=false
		if view_id=="fight":fighters[0].set_pose(2);guarding=true
		capture.call_deferred()
	elif render_test:
		player.active=false
		performance_run.call_deferred()
	elif not touch_mode and not OS.has_feature("web"):Input.mouse_mode=Input.MOUSE_MODE_CAPTURED

func mat(key: String) -> StandardMaterial3D:
	if key=="canvas":
		if not materials.has(key):
			var c:=StandardMaterial3D.new()
			c.albedo_color=Color(.9,.92,.92);c.roughness=.95
			c.albedo_texture=load("res://assets/harbor-v3/canvas.png");c.uv1_triplanar=true;c.uv1_world_triplanar=true;c.uv1_scale=Vector3.ONE*.3;c.cull_mode=BaseMaterial3D.CULL_DISABLED
			materials[key]=c
		return materials[key]
	var result:=super.mat(key)
	if key=="wood":
		result.albedo_texture=load("res://assets/harbor/wood.png")
		result.albedo_color=Color(.68,.57,.45)
		result.uv1_scale=Vector3(.35,.18,.35)
	if key=="stone":
		result.uv1_scale=Vector3.ONE*.40
		result.albedo_texture=load("res://assets/harbor-v3/stone.png")
		result.albedo_color=Color(.92,.92,.92)
	return result

func configure_meshes(node: Node) -> void:
	if wet_stone==null:
		wet_stone=ShaderMaterial.new()
		var shader:=Shader.new()
		shader.code="""shader_type spatial;
uniform sampler2D stone : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
varying vec3 world_p;varying vec3 world_n;
void vertex(){world_p=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;world_n=normalize((MODEL_MATRIX*vec4(NORMAL,0.)).xyz);}
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float n(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
void fragment(){
 vec3 w=pow(abs(world_n),vec3(8.));w/=w.x+w.y+w.z;
 vec3 c=texture(stone,world_p.zy*.4).rgb*w.x+texture(stone,world_p.xz*.4).rgb*w.y+texture(stone,world_p.xy*.4).rgb*w.z;
 float pools=smoothstep(.47,.64,n(world_p.xz*.75))*(1.-step(world_p.x,-4.));
 ALBEDO=c*mix(.95,.67,pools);ROUGHNESS=mix(.72,mix(.32,.08,pools),(1.-step(world_p.x,-4.))*w.y);METALLIC=.08;SPECULAR=.85;
}
"""
		wet_stone.shader=shader;wet_stone.set_shader_parameter("stone",load("res://assets/harbor-v3/stone.png"))
	if node is MeshInstance3D:
		for surface in node.mesh.get_surface_count():
			var original:Material=node.mesh.surface_get_material(surface)
			var key:String=original.resource_name.trim_prefix("harbor_")
			node.set_surface_override_material(surface,wet_stone if key=="stone" else mat(key))
		if str(node.name).begins_with("HarborSolid"):node.create_trimesh_collision()
	for child in node.get_children():configure_meshes(child)

func build_environment() -> void:
	var world:=WorldEnvironment.new()
	var env:=Environment.new()
	var sky:=Sky.new()
	var panorama:=PanoramaSkyMaterial.new()
	panorama.panorama=load("res://assets/harbor/sky.png")
	sky.sky_material=panorama;env.sky=sky
	env.background_mode=Environment.BG_SKY
	env.background_energy_multiplier=.6
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color=Color("8896ab");env.ambient_light_energy=.64
	env.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	env.fog_enabled=true;env.fog_light_color=Color("253443");env.fog_density=.0025
	env.fog_sky_affect=0
	if RenderingServer.get_current_rendering_method()=="forward_plus":
		env.ssr_enabled=true;env.ssao_enabled=true;env.ssao_radius=1.5;env.ssao_intensity=1.5
		env.glow_enabled=true;env.glow_intensity=.35
	world.environment=env;add_child(world)
	var moon:=DirectionalLight3D.new()
	moon.rotation_degrees=Vector3(-48,-25,0)
	moon.light_color=Color("a8bbd1");moon.light_energy=.72
	moon.shadow_enabled=true;add_child(moon)
	for z in [-20.,-11.,-2.,4.]:lamp(Vector3(-6.8,5.1,z+.65),1.6,5)
	for z in [-4.1,1.5]:lamp(Vector3(-9.5,5.2,z),2.3,4.5)
	for z in [-10.,-4.]:lamp(Vector3(2.8,1.8,z),1.3,4.5)
	lamp(Vector3(-12,5.5,-9),2.6,7)
	lamp(Vector3(-3,3.2,-4),2.2,7)
	lamp(Vector3(-3,2,-12),1.0,8)
	lamp(Vector3(8.8,2,-23.5),2.0,6)
	lamp(Vector3(2,3,-17),1.3,6)
	var reflection:=ReflectionProbe.new()
	reflection.position=Vector3(1,4,-9)
	reflection.size=Vector3(70,34,90)
	reflection.cull_mask=1
	reflection.intensity=.8;reflection.box_projection=true
	add_child(reflection)

func build_slope() -> void:
	var body:=StaticBody3D.new()
	var shape:=ConvexPolygonShape3D.new()
	shape.points=PackedVector3Array([Vector3(-4,.62,0),Vector3(.2,.62,0),Vector3(-4,3.24,4.65),Vector3(.2,3.24,4.65),Vector3(-4,3.24,5.5),Vector3(.2,3.24,5.5),Vector3(-4,-1,0),Vector3(.2,-1,0),Vector3(-4,-1,5),Vector3(.2,-1,5)])
	var collider:=CollisionShape3D.new();collider.shape=shape;body.add_child(collider);add_child(body)
	var return_body:=StaticBody3D.new();var return_shape:=ConvexPolygonShape3D.new()
	return_shape.points=PackedVector3Array([Vector3(-4.5,3.24,-18),Vector3(-4.5,3.24,-15),Vector3(-3.65,3.24,-18),Vector3(-3.65,3.24,-15),Vector3(-.35,.62,-18),Vector3(-.35,.62,-15),Vector3(-4.5,-1,-18),Vector3(-4.5,-1,-15),Vector3(-.35,-1,-18),Vector3(-.35,-1,-15)])
	var return_col:=CollisionShape3D.new();return_col.shape=return_shape;return_body.add_child(return_col);add_child(return_body)

	# Thin collision follows the visible rope boundary; this slice has no swimming.
	for item in [[Vector3(1.35,1.5,-15.6),Vector3(.1,2,24.8)],[Vector3(1.35,1.5,-.7),Vector3(.1,2,2.6)],[Vector3(.5,4.5,7.5),Vector3(.15,3,5)],[Vector3(-1,4,10),Vector3(15,8,.15)],[Vector3(-1,4,-28),Vector3(15,8,.15)]]:
		var rail:=StaticBody3D.new();var col:=CollisionShape3D.new();var box:=BoxShape3D.new()
		box.size=item[1];col.shape=box;rail.position=item[0];rail.add_child(col);add_child(rail)

	var boat_bounds=[[Vector3(3.8,.37,-8),Vector3(3,.1,12.8)],[Vector3(3.8,1.4,-12.5),Vector3(2.7,1.8,2.7)],[Vector3(5.380000000000001,1.1,-8),Vector3(.1,1.8,12.8)],[Vector3(3.8,1.1,-.4),Vector3(3.2,1.8,.1)],[Vector3(3.8,1.1,-15),Vector3(3.2,1.8,.1)],[Vector3(2.2,1.1,-9),Vector3(.1,1.8,11)],[Vector3(2.2,1.1,-1),Vector3(.1,1.8,1.9)]]
	for pair in boat_bounds:
		var hull:=StaticBody3D.new();var col2:=CollisionShape3D.new();var box2:=BoxShape3D.new()
		box2.size=pair[1];col2.shape=box2;hull.position=pair[0];hull.add_child(col2);add_child(hull)

func build_door() -> void:
	door_pivot=Node3D.new();door_pivot.position=Vector3(-8,3.2,-10.25);add_child(door_pivot)
	cube(Vector3(0,1.5,1.25),Vector3(.14,3,2.5),mat("wood"),false,door_pivot)
	for y in [.2,1.5,2.8]:cube(Vector3(.1,y,1.25),Vector3(.1,.1,2.5),mat("metal"),false,door_pivot)
	cube(Vector3(.15,1.3,2.1),Vector3(.18,.2,.08),mat("metal"),false,door_pivot)
	var body:=StaticBody3D.new();door_shape=CollisionShape3D.new();var box:=BoxShape3D.new()
	box.size=Vector3(.14,3,2.5);door_shape.shape=box;door_shape.position=Vector3(0,1.5,1.25)
	body.add_child(door_shape);door_pivot.add_child(body)
	door_open=true;door_pivot.rotation.y=-PI/2

func build_water() -> void:
	var mesh:=MeshInstance3D.new();var plane:=PlaneMesh.new();plane.size=Vector2(420,360)
	mesh.mesh=plane;mesh.position=Vector3(211,-.15,-25);mesh.layers=2
	var shader:=Shader.new()
	shader.code="""shader_type spatial;
uniform vec3 water_tint : source_color=vec3(.09,.14,.18);
uniform vec3 reflection_lights[8];
varying vec3 world_p;
void vertex(){world_p=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;}
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
float waves(vec2 p){return noise(p)*.55+noise(p*2.17+7.)*.3+noise(p*4.31-11.)*.15;}
void fragment(){
 vec2 p=UV*vec2(420.,360.);vec2 q=p*vec2(1.3,3.7)+vec2(TIME*.2,TIME*.13);
 float a=waves(q);float b=waves(q+vec2(12.3,6.7));
 float f=1.-smoothstep(.18,1.2,max(length(dFdx(p)),length(dFdy(p))));
 NORMAL_MAP=vec3(.5+(a-.5)*.55*f,.5+(b-.5)*.4*f,1.);
 ALBEDO=water_tint*(.8+a*.35);EMISSION=vec3(.010,.016,.024)*(1.+a*.1);METALLIC=.78;ROUGHNESS=.14;SPECULAR=.85;
 vec3 wave_n=normalize(vec3((a-.5)*.07,1.,(b-.5)*.13));
 vec3 ray=reflect(-normalize(CAMERA_POSITION_WORLD-world_p),wave_n);
 // Stylized emissive-lamp reflection: follows actual world lights, view and animated waves.
 for(int i=0;i<8;i++){vec3 toward=normalize(reflection_lights[i]-world_p);float glint=pow(max(dot(ray,toward),0.),2500.)*smoothstep(.35,.65,waves(q*2.3+float(i)));EMISSION+=vec3(1.,.47,.12)*glint*1.2;}

}
"""
	water_paint=ShaderMaterial.new();water_paint.shader=shader;mesh.material_override=water_paint;add_child(mesh)

func build_distant_shore() -> void:
	var rng:=RandomNumberGenerator.new();rng.seed=831
	for i in range(30):
		var x:float=5+i*7
		var z:float=-105+rng.randf_range(-10,10)
		var height:=rng.randf_range(3,10)
		var width:=rng.randf_range(4.5,6.5)
		var far_paint:=StandardMaterial3D.new()
		far_paint.albedo_color=Color("16222d")
		cube(Vector3(x,height/2,z),Vector3(width,height,8),far_paint)
		var roof:=MeshInstance3D.new();var gable:=PrismMesh.new();gable.size=Vector3(width+.5,1.8,8.5)
		roof.mesh=gable;roof.position=Vector3(x,height+.9,z);roof.material_override=far_paint;add_child(roof)
		if i%5==0:cube(Vector3(x,height+3,z),Vector3(.6,6,.6),far_paint)
		for yy in range(2,int(height),3):
			for zz in [-2.,0.,2.]:
				if rng.randf()>.32:cube(Vector3(x+zz,yy,z+4.04),Vector3(.36,.55,.08),mat("glass"))
	for pos in [Vector3(24,0,-38),Vector3(47,0,-57),Vector3(68,0,-15)]:
		cube(pos,Vector3(4,1,12),mat("ink"))
		cube(pos+Vector3(0,1.3,-1),Vector3(2,1.6,4),mat("distant"))
		cube(pos+Vector3(0,3,-3),Vector3(.4,3,.5),mat("metal"))
		for z in [-2.,0.]:cube(pos+Vector3(-1.02,1.6,z),Vector3(.05,.5,.5),mat("glass"))

func build_quay_lamps() -> void:
	var sources:=PackedVector3Array([Vector3(.8,3.8,-5),Vector3(.8,3.8,-13),Vector3(2.8,1.8,-4),Vector3(8.8,2,-23.5),Vector3(20,2,-99),Vector3(45,2,-96),Vector3(80,2,-100),Vector3(115,2,-98)])
	for i in range(2):
		var p:=sources[i]
		cube(Vector3(1.1,2.2,p.z),Vector3(.08,3.2,.08),mat("metal"))
		cube(Vector3(.9,3.97,p.z),Vector3(.55,.06,.06),mat("metal"))
		cube(p,Vector3(.16,.26,.16),mat("glass"))
		for y in [-.16,.16]:cube(p+Vector3(0,y,0),Vector3(.25,.06,.25),mat("metal"))
		lamp(p,2.8,7)
	for i in range(4,8):
		cube(sources[i],Vector3(.4,.4,.15),mat("glass"))
	water_paint.set_shader_parameter("reflection_lights",sources)

func set_view(id: String) -> void:
	var views={"arrival":[Vector3(-2.3,4.85,5.8),Vector3(1,3,-10)],"lower":[Vector3(.3,2.25,-5),Vector3(-6,5,-10)],"inside":[Vector3(-8.8,4.85,-5.5),Vector3(-12,4.2,-10)],"fight":[Vector3(-.4,2.25,.2),Vector3(-.4,1.7,-1.8)]}
	var v:Array=views.get(id,views.arrival)
	player.position=v[0]-Vector3(0,1.65,0)
	player.rotation=Vector3.ZERO;player.camera.rotation=Vector3.ZERO
	player.camera.look_at(v[1]);player.rotation.y=player.camera.rotation.y;player.camera.rotation.y=0
	player.camera.fov=68

func build_ui() -> void:
	ui=CanvasLayer.new();add_child(ui)
	var layer:=Control.new();layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);layer.mouse_filter=Control.MOUSE_FILTER_IGNORE;ui.add_child(layer)
	hands=TextureRect.new();hands.mouse_filter=Control.MOUSE_FILTER_IGNORE
	hands.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	hands.offset_left=-380;hands.offset_right=380;hands.offset_top=-760;hands.offset_bottom=32
	hands.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	hand_atlas=AtlasTexture.new();hand_atlas.atlas=load("res://assets/harbor-v3/hands.png")
	hand_atlas.region=Rect2(0,0,512,512);hand_atlas.filter_clip=true;hands.texture=hand_atlas
	var shader:=Shader.new();shader.code="""shader_type canvas_item;
void fragment(){vec4 c=texture(TEXTURE,UV);if(c.r-c.g>.08 && c.b-c.g>.08){discard;}COLOR=vec4(c.rgb*.8,c.a);}"""
	var paint:=ShaderMaterial.new();paint.shader=shader;hands.material=paint;layer.add_child(hands)
	flash=ColorRect.new();flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);flash.mouse_filter=Control.MOUSE_FILTER_IGNORE;flash.color=Color(1,.68,.3,0);layer.add_child(flash)
	for size in [Vector2(8,2),Vector2(2,8)]:
		var dot:=ColorRect.new();dot.color=Color(1,.94,.8,.65);dot.mouse_filter=Control.MOUSE_FILTER_IGNORE
		dot.set_anchors_and_offsets_preset(Control.PRESET_CENTER);dot.position=-size/2;dot.size=size;layer.add_child(dot)
	var backing:=ColorRect.new();backing.color=Color(.02,.025,.03,.7);backing.position=Vector2(30,30);backing.size=Vector2(104,7);layer.add_child(backing)
	health_bar=ColorRect.new();health_bar.color=Color("bca780");health_bar.position=Vector2(32,32);health_bar.size=Vector2(100,3);layer.add_child(health_bar)
	get_viewport().size_changed.connect(resize_hud)
	resize_hud()

func resize_hud() -> void:
	var viewport_size:=get_viewport().get_visible_rect().size
	var extent:=minf(760,minf(viewport_size.x*.9,viewport_size.y*(.70 if touch_mode else .85)))
	hands.offset_left=-extent/2;hands.offset_right=extent/2;hands.offset_top=-extent;hands.offset_bottom=32

func build_rain() -> void:
	var rain:=GPUParticles3D.new();rain.amount=650;rain.lifetime=1.2;rain.visibility_aabb=AABB(Vector3(-25,-10,-35),Vector3(50,40,60))
	var drops:=ParticleProcessMaterial.new();drops.emission_shape=ParticleProcessMaterial.EMISSION_SHAPE_BOX;drops.emission_box_extents=Vector3(12,0,23)
	drops.direction=Vector3(-.1,-1,.1);drops.spread=2;drops.initial_velocity_min=15;drops.initial_velocity_max=20;drops.gravity=Vector3(0,-2,0)
	rain.process_material=drops;rain.position=Vector3(8,18,-8)
	var streak:=BoxMesh.new();streak.size=Vector3(.005,.13,.005)
	var p:=StandardMaterial3D.new();p.albedo_color=Color(.52,.61,.7,.2);p.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;p.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	streak.material=p;rain.draw_pass_1=streak
	if OS.has_feature("web"):
		var cpu:=CPUParticles3D.new();cpu.convert_from_particles(rain);cpu.amount=180 if touch_mode else 350
		add_child(cpu);rain.free()
	else:add_child(rain)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):reset_scene()
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:Input.mouse_mode=Input.MOUSE_MODE_VISIBLE;guarding=false
	if event is InputEventMouseButton:
		if touch_mode:return
		if event.pressed and Input.mouse_mode!=Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode=Input.MOUSE_MODE_CAPTURED;return
		if event.button_index==MOUSE_BUTTON_LEFT and event.pressed:start_punch()
		if event.button_index==MOUSE_BUTTON_RIGHT:guarding=event.pressed
	if event.is_action_pressed("interact"):interact()

func interact() -> void:
	if health<=0:return
	if player.position.distance_to(Vector3(-8,3.2,-9))<2.8:toggle_door()
	else:
		var target=target_in_reach(2.7)
		if target:target.challenge()

func toggle_door() -> void:
	door_open=not door_open
	create_tween().tween_property(door_pivot,"rotation:y",-PI/2 if door_open else 0.,.25)

func clear_path(source: Node3D, target: Node3D) -> bool:
	var query:=PhysicsRayQueryParameters3D.create(source.global_position+Vector3(0,1.1,0),target.global_position+Vector3(0,1.1,0),3,[source.get_rid()])
	var hit:=get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or hit.collider==target

func target_in_reach(reach: float):
	var best=null
	var nearest:=reach
	for enemy in fighters:
		if enemy.health<=0:continue
		var diff:Vector3=enemy.global_position+Vector3(0,1.1,0)-player.camera.global_position
		var distance:float=Vector2(diff.x,diff.z).length()
		if distance<=nearest and absf(enemy.position.y-player.position.y)<1 and (-player.camera.global_basis.z).dot(diff.normalized())>.65 and clear_path(player,enemy):best=enemy;nearest=distance
	return best

func start_punch() -> void:
	if health<=0 or swing>0:return
	guarding=false;swing=.42;swing_hit=false;left_hand=not left_hand

func take_hit(amount: int, enemy: Node3D) -> void:
	if health<=0:return
	var direction:Vector3=(enemy.global_position-player.global_position).normalized()
	var blocked:=guarding and (-player.global_basis.z).dot(direction)>.35
	health=maxi(0,health-(2 if blocked else amount))
	hit_flash=.05 if blocked else .16
	play_impact(blocked)
	if health==0:player.active=false;guarding=false

func play_impact(blocked: bool) -> void:
	var sound:=AudioStreamPlayer.new();var wav:=AudioStreamWAV.new()
	wav.format=AudioStreamWAV.FORMAT_16_BITS;wav.mix_rate=22050
	var bytes:=PackedByteArray();bytes.resize(4400)
	for i in 2200:
		var t:=float(i)/22050.;var value:=sin(t*TAU*(130 if blocked else 72))*exp(-t*45)*.35
		bytes.encode_s16(i*2,int(value*32767))
	wav.data=bytes;sound.stream=wav;add_child(sound);sound.finished.connect(sound.queue_free);sound.play()

func _process(delta: float) -> void:
	elapsed+=delta
	if swing>0:
		swing-=delta
		if swing<.27 and not swing_hit:
			swing_hit=true
			var enemy=target_in_reach(2.05)
			if enemy:
				enemy.receive_hit(20,(enemy.position-player.position).normalized());play_impact(false)
	var frame:=3 if guarding else 0
	if swing>.08:frame=1 if left_hand else 2
	if hit_flash>.08:frame=4
	var cell:=Vector2(hand_atlas.atlas.get_width()/3.,hand_atlas.atlas.get_height()/2.)
	hand_atlas.region=Rect2(Vector2(frame%3,frame/3)*cell,cell)
	hit_flash=maxf(0,hit_flash-delta)
	flash.color.a=hit_flash
	health_bar.size.x=health
	hands.modulate.a=1 if health>0 else .3
	if health==0:flash.color=Color(.02,.025,.03,.72)
	if player.position.y < -3:reset_scene()

func reset_scene() -> void:
	if is_instance_valid(touch_controls):touch_controls.clear()
	health=100;guarding=false;swing=0.;hit_flash=0.;player.active=true;player.velocity=Vector3.ZERO
	flash.color=Color(1,.68,.3,0)
	set_view("arrival")
	for person in fighters:person.reset()

func run_touch_test() -> void:
	await get_tree().create_timer(.3).timeout
	var press:=InputEventScreenTouch.new();press.index=1;press.pressed=true;press.position=touch_controls.joystick_center()
	touch_controls._input(press)
	var drag:=InputEventScreenDrag.new();drag.index=1;drag.position=press.position+Vector2(0,-touch_controls.radius())
	touch_controls._input(drag)
	assert(player.touch_axes.y<-.9,"left joystick moves forward")
	var start:=player.position
	await get_tree().create_timer(.3).timeout
	assert(player.position.distance_to(start)>.2,"touch moves the actual player")
	var look_touch:=InputEventScreenTouch.new();look_touch.index=2;look_touch.pressed=true;look_touch.position=Vector2(touch_controls.size.x*.65,touch_controls.size.y*.4)
	touch_controls._input(look_touch)
	var yaw:=player.rotation.y
	var look_drag:=InputEventScreenDrag.new();look_drag.index=2;look_drag.relative=Vector2(80,0)
	touch_controls._input(look_drag)
	assert(player.rotation.y!=yaw and player.touch_axes.y<-.9,"simultaneous move and look")
	press.pressed=false;touch_controls._input(press)
	assert(player.touch_axes==Vector2.ZERO,"release stops joystick")
	for label in ["HIT","GUARD","USE","RESET"]:
		press.index=3;press.pressed=true;press.position=touch_controls.buttons()[label]
		if label=="USE":player.position=Vector3(-7,3.2,-9)
		var was_open:=door_open
		touch_controls._input(press)
		if label=="HIT":assert(swing>0,"touch punch")
		if label=="GUARD":assert(guarding,"touch guard")
		if label=="USE":assert(door_open!=was_open,"touch interaction")
		if label=="RESET":assert(health==100 and player.touch_axes==Vector2.ZERO,"touch reset")
		press.pressed=false;touch_controls._input(press)
		assert(not guarding,"guard release")
	touch_controls.clear()
	assert(touch_controls.look_finger==-1 and touch_controls.move_finger==-1,"focus reset")
	print("TOUCH_TEST_PASS move look multitouch punch guard interact restart release")
	get_tree().quit()

func capture() -> void:
	await get_tree().create_timer(3).timeout
	await RenderingServer.frame_post_draw
	var picture:=get_viewport().get_texture().get_image()
	var result:=picture.save_png(capture_path)
	print("V3_CAPTURE ",view_id," ",result," ",capture_path)
	get_tree().quit(0 if result==OK else 1)

func performance_run() -> void:
	await get_tree().create_timer(2).timeout
	var times:Array[float]=[]
	var previous:=Time.get_ticks_usec()
	for i in 240:
		await get_tree().process_frame
		var current:=Time.get_ticks_usec()
		times.append(1000000./maxf(current-previous,1))
		previous=current
	times.sort()
	print("V3_FPS median=",times[120]," p10=",times[24])
	get_tree().quit()

func run_test() -> void:
	await get_tree().create_timer(.6).timeout
	var enemy=fighters[0]
	set_view("fight")
	player.active=false
	assert(target_in_reach(2.05)==enemy,"near target selected")
	start_punch();await get_tree().create_timer(.22).timeout
	assert(enemy.health==60 and enemy.hostile,"punch impact and aggression")
	assert(enemy.pose==4,"hurt pose")
	await get_tree().create_timer(1.8).timeout
	assert(health<100,"enemy retaliation")
	var old_health:=health;guarding=true;take_hit(12,enemy)
	assert(health==old_health-2,"facing guard")
	player.rotation.y+=PI;old_health=health;take_hit(12,enemy)
	assert(health==old_health-12,"rear hit bypasses guard")
	set_view("arrival");assert(target_in_reach(2.05)==null,"out of range")
	# Closed solid warehouse wall blocks actual physics ray.
	player.position=Vector3(-9,3.22,-1);enemy.position=Vector3(-7,3.22,-1)
	await get_tree().physics_frame
	assert(not clear_path(player,enemy),"wall occlusion")
	for i in 3:enemy.receive_hit(20,Vector3.ZERO)
	assert(enemy.health==0 and enemy.pose==5,"knockout pose")
	old_health=health;await get_tree().create_timer(1.5).timeout
	assert(health==old_health,"knocked out actor cannot attack")
	reset_scene();await get_tree().physics_frame
	assert(health==100 and enemy.health==80 and not enemy.hostile,"restart")
	# Walk down and back up with the shared first-person controller.
	player.position=Vector3(-1.8,3.23,6);player.rotation=Vector3.ZERO;player.camera.rotation=Vector3.ZERO
	Input.action_press("forward");await get_tree().create_timer(2.5).timeout;Input.action_release("forward")
	assert(player.position.y<.8 and player.position.z<0,"stair descent")
	Input.action_press("back");await get_tree().create_timer(3.5).timeout;Input.action_release("back")
	print("STAIR_ASCENT ",player.position)
	assert(player.position.y>3 and player.position.z>5,"stair ascent")
	# Open door, walk into room; then closed door stops the same movement.
	player.position=Vector3(-6.5,3.23,-9);player.rotation.y=PI/2;player.velocity=Vector3.ZERO
	Input.action_press("forward");await get_tree().create_timer(1.2).timeout;Input.action_release("forward")
	assert(player.position.x<-8.5,"open doorway traversal")
	player.position=Vector3(-6.5,3.23,-9);player.velocity=Vector3.ZERO
	toggle_door();await get_tree().create_timer(.4).timeout
	Input.action_press("forward");await get_tree().create_timer(1.2).timeout;Input.action_release("forward")
	assert(player.position.x>-8,"closed door blocks")
	player.position=Vector3(.5,.65,-16.5);player.rotation.y=PI/2;player.velocity=Vector3.ZERO
	Input.action_press("forward");await get_tree().create_timer(3).timeout;Input.action_release("forward")
	assert(player.position.x<-4.2 and player.position.y>3,"return stair ascent")
	player.position=Vector3(.2,.65,-2.6);player.rotation.y=-PI/2;player.velocity=Vector3.ZERO
	Input.action_press("forward");await get_tree().create_timer(1.2).timeout;Input.action_release("forward")
	assert(player.position.x>2.5 and player.position.y>.3,"gangboard boarding")
	print("BOARDING_POSITION ",player.position)
	print("V3_TEST_PASS combat_range wall_occlusion retaliate guard knockout reset stair_descent stair_ascent doorway")
	get_tree().quit()
