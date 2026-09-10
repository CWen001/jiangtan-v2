extends Node3D

const Player = preload("res://scripts/player.gd")
var player: CharacterBody3D
var npc: Sprite3D
var door: Node3D
var door_shape: CollisionShape3D
var door_open := true
var interacted := false
var capture_path := ""
var view_id := "hero"
var testing := false
var render_test := false
var materials: Dictionary = {}
var elapsed := 0.0
var status_dot: ColorRect
var ui: CanvasLayer
var fps_samples: Array[float] = []

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="): capture_path = arg.trim_prefix("--capture=")
		if arg.begins_with("--view="): view_id = arg.trim_prefix("--view=")
		if arg == "--harbor-test": testing = true
		if arg == "--render-test": render_test = true
	setup_inputs()
	build_environment()
	var model: Node3D = load("res://assets/harbor/harbor.glb").instantiate()
	add_child(model)
	configure_meshes(model)
	build_slope()
	build_door()
	build_water()
	build_wet_glints()
	build_distant_shore()
	build_npc()
	player = Player.new()
	add_child(player)
	player.floor_snap_length = 0.4
	set_view(view_id)
	build_ui()
	if testing:
		player.headless_input = true
		run_test.call_deferred()
	elif not capture_path.is_empty():
		player.active = false
		ui.visible = false
		capture.call_deferred()
	elif render_test:
		player.active = false
		performance_run.call_deferred()
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func setup_inputs() -> void:
	for action in {"forward":KEY_W,"back":KEY_S,"left":KEY_A,"right":KEY_D,"sprint":KEY_SHIFT,"interact":KEY_E,"restart":KEY_R}:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			var key := InputEventKey.new()
			key.physical_keycode = {"forward":KEY_W,"back":KEY_S,"left":KEY_A,"right":KEY_D,"sprint":KEY_SHIFT,"interact":KEY_E,"restart":KEY_R}[action]
			InputMap.action_add_event(action,key)

func mat(key: String) -> StandardMaterial3D:
	if materials.has(key): return materials[key]
	var m := StandardMaterial3D.new()
	m.roughness = 0.72
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	var texture_path := "res://assets/harbor/" + key + ".png"
	if key == "wood": texture_path = "res://assets/generated/wood.png"
	if key in ["stone","wood","plaster","metal"]:
		m.albedo_texture = load(texture_path)
		m.uv1_triplanar = true
		m.uv1_world_triplanar = true
		m.uv1_scale = Vector3.ONE * (0.27 if key == "stone" else 0.24)
		m.albedo_color = Color(0.72,0.72,0.72)
		if key == "wood": m.albedo_color = Color(0.65,0.55,0.43)
		if key == "stone":
			m.roughness = .29
			m.metallic = .14
		if key == "plaster": m.albedo_color = Color(.63,.59,.54)
		if key == "metal": m.roughness = 0.38
	elif key in ["glass","mint"]:
		m.albedo_color = Color("c9863f") if key == "glass" else Color("90d6c0")
		m.emission_enabled = true
		m.emission = m.albedo_color
		m.emission_energy_multiplier = 0.8
	else: m.albedo_color = Color("131d27") if key == "ink" else Color("253745")
	if key in ["wood","metal"]:
		var outline := ShaderMaterial.new()
		var shader := Shader.new()
		shader.code = "shader_type spatial; render_mode unshaded, cull_front; void vertex(){VERTEX+=NORMAL*0.009;} void fragment(){ALBEDO=vec3(.016,.019,.021);}"
		outline.shader = shader
		m.next_pass = outline
	materials[key] = m
	return m

func configure_meshes(node: Node) -> void:
	if node is MeshInstance3D:
		for s in node.mesh.get_surface_count():
			var original: Material = node.mesh.surface_get_material(s)
			var key: String = original.resource_name.trim_prefix("harbor_")
			node.set_surface_override_material(s,mat(key))
		if str(node.name).begins_with("HarborSolid"): node.create_trimesh_collision()
	for child in node.get_children(): configure_meshes(child)

func cube(at: Vector3, size: Vector3, material: Material, solid := false, parent: Node3D = self) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.material_override = material
	mesh.position = at
	parent.add_child(mesh)
	if solid: mesh.create_trimesh_collision()
	return mesh

func lamp(at: Vector3, power: float, radius: float) -> void:
	var light := OmniLight3D.new()
	light.position = at
	light.light_color = Color("ffb768")
	light.light_energy = power
	light.omni_range = radius
	light.omni_attenuation = 1.4
	light.shadow_enabled = true
	light.shadow_bias = .12
	light.shadow_normal_bias = 1.5
	add_child(light)

func build_environment() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	var sky := Sky.new()
	var sky_mat := PanoramaSkyMaterial.new()
	sky_mat.panorama = load("res://assets/harbor/sky.png")
	sky.sky_material = sky_mat
	env.sky = sky
	env.background_mode = Environment.BG_SKY
	env.background_energy_multiplier = 0.55
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("8b9cad")
	env.ambient_light_energy = 0.42
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color("172331")
	env.fog_density = 0.0012
	env.fog_sky_affect = 0.0
	world.environment = env
	add_child(world)
	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-40,-38,0)
	moon.light_color = Color("9eafc5")
	moon.light_energy = 0.55
	moon.shadow_enabled = true
	moon.shadow_bias = .12
	moon.shadow_normal_bias = 1.5
	add_child(moon)
	for z in [-11.0,-6.1,-1.8,1.0]: lamp(Vector3(-2.2,3.3,z),1.3,5.5)
	lamp(Vector3(-7,3.9,-4),2.4,7)
	lamp(Vector3(10.4,1.9,-4),1.6,4.5)

func build_slope() -> void:
	# ponytail: stair collision uses a slope; add step climbing for discrete footfalls.
	# A continuous collision wedge lets the shared walking controller climb the
	# visual six-step stair without requiring a jump or changing the old slice.
	var body := StaticBody3D.new()
	var collider := CollisionShape3D.new()
	var shape := ConvexPolygonShape3D.new()
	shape.points = PackedVector3Array([
		Vector3(5,1.21,-14),Vector3(5,1.21,11),Vector3(7.4,0.01,-14),Vector3(7.4,0.01,11),
		Vector3(5,-0.5,-14),Vector3(5,-0.5,11),Vector3(7.4,-0.5,-14),Vector3(7.4,-0.5,11)])
	collider.shape = shape
	body.add_child(collider)
	add_child(body)
	# Low visible rope-edge posts define the water boundary; collision prevents
	# falling into this non-swimming first slice.
	var edge := cube(Vector3(10.05,0.42,-1.5),Vector3(0.08,0.06,25),mat("metal"),true)
	var rail := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.12,1.1,25)
	col.shape = box
	col.position = edge.position
	rail.add_child(col)
	add_child(rail)

func build_door() -> void:
	door = Node3D.new()
	door.position = Vector3(-3,1.2,-5.2)
	add_child(door)
	cube(Vector3(0,1.4,1.2),Vector3(.16,2.8,2.35),mat("wood"),false,door)
	for y in [.25,2.55]: cube(Vector3(.1,y,1.2),Vector3(.06,.13,2.35),mat("metal"),false,door)
	cube(Vector3(.14,1.25,2.15),Vector3(.15,.22,.055),mat("metal"),false,door)
	var body := StaticBody3D.new()
	door_shape = CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(.18,2.8,2.35)
	door_shape.shape = shape
	door_shape.position = Vector3(0,1.4,1.2)
	body.add_child(door_shape)
	door.add_child(body)
	door.rotation.y = -PI/2
	door_shape.disabled = true

func build_npc() -> void:
	# ponytail: one tinted billboard; directional frames needed for character animation.
	npc = Sprite3D.new()
	npc.texture = load("res://assets/harbor/courier.png")
	npc.pixel_size = 1.9 / float(npc.texture.get_height())
	npc.position = Vector3(-1.3,2.14,-6)
	npc.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	npc.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	npc.alpha_scissor_threshold = .7
	npc.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	npc.shaded = false
	npc.modulate = Color(.72,.65,.57)
	add_child(npc)
	var blocker := cube(Vector3(-1.3,2.1,-6),Vector3(.46,1.8,.3),mat("ink"),true)
	blocker.visible = false
	var shadow := MeshInstance3D.new()
	var disk := CylinderMesh.new()
	disk.top_radius = .34
	disk.bottom_radius = .34
	disk.height = .004
	shadow.mesh = disk
	shadow.position = Vector3(-1.3,1.212,-6)
	shadow.scale.z = .55
	shadow.material_override = mat("ink")
	add_child(shadow)

func build_water() -> void:
	# ponytail: sky and point-light approximation; does not reflect scene geometry.
	var shader := Shader.new()
	shader.code = """shader_type spatial;
render_mode cull_disabled, unshaded;
uniform sampler2D cloud : source_color, repeat_enable;
varying vec3 world;
void vertex(){world=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;}
void fragment(){
 vec2 p=world.xz;
 float a=sin(p.x*3.1+p.y*.6+TIME*.4);
 float b=sin(p.x*8.3-p.y*1.9-TIME*.55);
 vec3 n=normalize(vec3(a*.046+b*.028,1.,sin(p.y*4.+p.x*.6+TIME*.6)*.018));
 vec3 eye=normalize(CAMERA_POSITION_WORLD-world);
 vec3 ray=reflect(-eye,n);
 vec2 suv=vec2(atan(ray.z,ray.x)/6.283185+.5,acos(clamp(ray.y,-1.,1.))/3.14159);
 vec3 sky=texture(cloud,suv).rgb;
 float light=0.;
 for(int i=0;i<45;i++){
   vec3 source=vec3(95.,4.5,-550.+float(i)*17.);
   vec3 direction=normalize(source-world);
   light+=pow(max(dot(ray,direction),0.),22000.)*.3;
 }
 vec3 near_light=normalize(vec3(11.,1.7,-4.)-world);
 light+=pow(max(dot(ray,near_light),0.),4000.)*.45;
 float wave=pow(max(sin(p.x*2.5+p.y*.1+TIME*.22),0.),14.);
 ALBEDO=sky*.65+vec3(.014,.021,.026)+wave*vec3(.012,.02,.028)+min(light,.55)*vec3(.73,.36,.105);
}
"""
	var water := ShaderMaterial.new()
	water.shader = shader
	water.set_shader_parameter("cloud",load("res://assets/harbor/sky.png"))
	var mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(400,400)
	mesh.mesh = plane
	mesh.material_override = water
	mesh.position = Vector3(200,-.24,-20)
	add_child(mesh)

func build_wet_glints() -> void:
	# Stylized wet-surface highlights follow the same world coordinates from all
	# views; these are painted reflection cues, not screen-space overlays.
	var shader := Shader.new()
	shader.code = """shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
uniform sampler2D stone : source_color, repeat_enable;
varying vec3 world;
void vertex(){world=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;}
void fragment(){
 vec3 tex=texture(stone,world.xz*.27).rgb;
 float mask=smoothstep(.075,.17,dot(tex,vec3(.333)));
 float ripple=sin(world.x*10.+sin(world.z*8.)*.6)+sin(world.z*16.+world.x*5.)*.4;
 float broken=smoothstep(.05,.65,ripple);
 vec2 q=UV*2.-1.;
 float taper=pow(max(1.-q.y*q.y,0.),2.)*pow(max(1.-q.x*q.x,0.),1.6);
 float angle=pow(1.-abs(normalize(CAMERA_POSITION_WORLD-world).y),2.);
 ALBEDO=vec3(.92,.48,.13);
 ALPHA=mask*broken*taper*angle*.52;
}
"""
	var material := ShaderMaterial.new()
	material.shader=shader
	material.set_shader_parameter("stone",load("res://assets/harbor/stone.png"))
	for at in [Vector3(-.3,1.216,2),Vector3(.1,1.216,-2.5),Vector3(8.3,.018,-2)]:
		var plane := PlaneMesh.new()
		plane.size=Vector2(2.6,7)
		var mesh := MeshInstance3D.new()
		mesh.mesh=plane;mesh.material_override=material;mesh.position=at
		add_child(mesh)

func build_distant_shore() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 74
	for i in range(108):
		var at := Vector3(95+sin(i*.4)*5,0,-580+i*7)
		var h := rng.randf_range(4,11)
		cube(at+Vector3(0,h/2,0),Vector3(5,h,6),mat("distant"))
		var roof := MeshInstance3D.new()
		var prism := PrismMesh.new()
		prism.size=Vector3(5.4,2,6.2)
		roof.mesh=prism;roof.material_override=mat("ink");roof.position=at+Vector3(0,h+.9,0)
		add_child(roof)
		if i%3==0: cube(at+Vector3(1,h+1.8,1),Vector3(.5,3,.55),mat("distant"))
		for y in [2.0,4.5,7.0]:
			if y>h-.4:continue
			for z in [-2.0,0.0,2.0]:
				if rng.randf()<.65: cube(at+Vector3(-2.55,y,z),Vector3(.04,.55,.45),mat("glass"))

func set_view(which: String) -> void:
	var position := Vector3(4.3,1.24,8)
	var focus := Vector3(3,2.65,-6)
	if which == "inside":
		position = Vector3(-8,1.24,-4)
		focus = Vector3(8,2,-4)
	elif which == "lower":
		position = Vector3(8.5,.04,4)
		focus = Vector3(-2,3,-5)
	player.position = position
	player.velocity = Vector3.ZERO
	player.camera.fov = 75
	look_at_point(focus)

func look_at_point(point: Vector3) -> void:
	var direction: Vector3 = point-player.camera.global_position
	player.rotation.y = atan2(-direction.x,-direction.z)
	player.camera.rotation.x = atan2(direction.y,Vector2(direction.x,direction.z).length())

func build_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)
	status_dot = ColorRect.new()
	status_dot.color = Color(.8,.7,.5,.75)
	status_dot.position = get_viewport().get_visible_rect().size*.5-Vector2(2,2)
	status_dot.size = Vector2(4,4)
	status_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(status_dot)

func interaction_target() -> String:
	var eye: Vector3 = player.camera.global_position
	var forward: Vector3 = -player.camera.global_basis.z
	for item in [{"id":"door","at":Vector3(-2.9,2.5,-4)},{"id":"npc","at":Vector3(-1.3,2.5,-6)}]:
		var offset: Vector3 = item.at-eye
		if offset.length() < 3.0 and forward.dot(offset.normalized())>.7:
			var ray := PhysicsRayQueryParameters3D.create(eye,item.at)
			ray.exclude = [player.get_rid()]
			var hit := get_world_3d().direct_space_state.intersect_ray(ray)
			if not hit.is_empty() and (hit.position as Vector3).distance_to(item.at)>.5: continue
			return item.id
	return ""

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode==Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
	if event is InputEventMouseButton and event.pressed: Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
	if event.is_action_pressed("restart"): get_tree().reload_current_scene()
	if event.is_action_pressed("interact"):
		var target := interaction_target()
		if target == "door":
			door_open = not door_open
			door_shape.set_deferred("disabled",door_open)
			create_tween().tween_property(door,"rotation:y",-PI/2 if door_open else 0.0,.45)
		elif target == "npc":
			interacted = true
			var tween := create_tween()
			tween.tween_property(npc,"position:y",2.10,.16)
			tween.tween_property(npc,"position:y",2.14,.25)

func _process(delta: float) -> void:
	elapsed += delta
	if is_instance_valid(status_dot): status_dot.color=Color("ddbb70") if interaction_target()!="" else Color(.7,.7,.65,.5)
	if render_test and elapsed>2: fps_samples.append(1.0/maxf(delta,.0001))
	if is_instance_valid(player) and player.position.y < -3: set_view("hero")

func capture() -> void:
	await get_tree().create_timer(2.0).timeout
	await RenderingServer.frame_post_draw
	var error := get_viewport().get_texture().get_image().save_png(capture_path)
	print("HARBOR_CAPTURE ",view_id," ",capture_path," error=",error)
	get_tree().quit(0 if error==OK else 1)

func performance_run() -> void:
	await get_tree().create_timer(8).timeout
	fps_samples.sort()
	print("HARBOR_FPS median=",fps_samples[fps_samples.size()/2]," p10=",fps_samples[fps_samples.size()/10])
	get_tree().quit(0 if fps_samples[fps_samples.size()/10]>=30 else 1)

func check(ok: bool, message: String) -> bool:
	if ok: print("HARBOR_TEST PASS ",message); return true
	push_error("HARBOR_TEST FAIL "+message)
	get_tree().quit(1)
	return false

func walk_to(at: Vector3) -> bool:
	for i in range(900):
		var horizontal := Vector2(player.position.x-at.x,player.position.z-at.z)
		if horizontal.length()<.16:
			Input.action_release("forward")
			for j in range(8): await get_tree().physics_frame
			return true
		look_at_point(Vector3(at.x,player.camera.global_position.y,at.z))
		Input.action_press("forward")
		await get_tree().physics_frame
	Input.action_release("forward")
	return check(false,"walk timeout at "+str(player.position))

func press_e() -> void:
	var key := InputEventKey.new()
	key.physical_keycode=KEY_E;key.keycode=KEY_E;key.pressed=true
	Input.parse_input_event(key)
	await get_tree().process_frame
	key=InputEventKey.new();key.physical_keycode=KEY_E;key.keycode=KEY_E;key.pressed=false
	Input.parse_input_event(key)
	await get_tree().create_timer(.6).timeout

func run_test() -> void:
	get_tree().create_timer(75).timeout.connect(func(): push_error("HARBOR_TEST timeout");get_tree().quit(1))
	for j in range(12): await get_tree().physics_frame
	if not await walk_to(Vector3(0,1.2,-4)): return
	look_at_point(Vector3(-3,2.5,-4))
	await press_e()
	if not check(not door_open,"E closes door"):return
	var before := player.position
	Input.action_press("forward")
	await get_tree().create_timer(1.3).timeout
	Input.action_release("forward")
	if not check(player.position.x>-3,"closed door blocks crossing"):return
	look_at_point(Vector3(-3,2.5,-4))
	await press_e()
	if not check(door_open,"E opens door"):return
	if not await walk_to(Vector3(-6,1.2,-4)):return
	if not check(player.position.x<-4,"enter warehouse through doorway"):return
	if not await walk_to(Vector3(0,1.2,-4)):return
	look_at_point(Vector3(-1.3,2.5,-6))
	await press_e()
	if not check(interacted,"E interacts with 2D character"):return
	if not await walk_to(Vector3(4,1.2,-3)):return
	if not await walk_to(Vector3(8.5,0,-3)):return
	if not check(player.position.y<.2,"descend stairs by normal movement"):return
	if not await walk_to(Vector3(4,1.2,-3)):return
	if not check(player.position.y>1.1,"ascend stairs without jumping"):return
	print("HARBOR_TEST COMPLETE")
	get_tree().quit(0)
