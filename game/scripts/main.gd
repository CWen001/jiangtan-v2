extends Node3D

const Player = preload("res://scripts/player.gd")
const INK := Color("111b26")
const PAPER := Color("ecd6ac")
const AMBER := Color("e5a350")
const TEAL := Color("408b94")
var player: CharacterBody3D
var door: Node3D
var door_shape: CollisionShape3D
var npc: Sprite3D
var objective: Label
var prompt: Label
var dialogue: Label
var chapter: Label
var veil: ColorRect
var target: String = ""
var has_letter: bool = false
var door_open: bool = false
var completed: bool = false
var dialogue_timer: float = 0.0
var elapsed: float = 0.0
var capture_path: String = ""
var capture_view: String = "alley"
var smoke_test: bool = false
var playtest: bool = false
var capture_dir: String = ""
var material_cache: Dictionary = {}
var loaded_assets: Array[String] = []

func _ready() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			capture_path = arg.trim_prefix("--capture=")
		if arg.begins_with("--view="):
			capture_view = arg.trim_prefix("--view=")
		if arg == "--smoke-test":
			smoke_test = true
		if arg == "--playtest":
			playtest = true
		if arg.begins_with("--capture-dir="):
			capture_dir = arg.trim_prefix("--capture-dir=")
	setup_inputs()
	build_world()
	build_player()
	build_hud()
	if playtest:
		player.headless_input = DisplayServer.get_name() == "headless"
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		run_playtest.call_deferred()
	elif smoke_test:
		player.active = false
		run_smoke.call_deferred()
	elif not capture_path.is_empty():
		player.active = false
		if capture_view == "interior":
			player.position = Vector3(1.8, 0.05, -12.1)
			player.rotation.y = 0.30
			player.camera.rotation.x = -0.025
			set_door(true)
		capture_frame.call_deferred()
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func setup_inputs() -> void:
	var keys: Dictionary = {"forward": KEY_W, "back": KEY_S, "left": KEY_A, "right": KEY_D, "sprint": KEY_SHIFT, "interact": KEY_E, "restart": KEY_R}
	for action: String in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var key := InputEventKey.new()
		key.physical_keycode = keys[action]
		InputMap.action_add_event(action, key)

func texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var result: Texture2D = load(path) as Texture2D
		if result != null and not loaded_assets.has(path):
			loaded_assets.append(path)
		return result
	return null

func material(color: Color, tex_name: String = "", uv_scale: float = 1.0, emission: float = 0.0) -> StandardMaterial3D:
	var key: String = str(color) + tex_name + str(uv_scale) + str(emission)
	if material_cache.has(key):
		return material_cache[key] as StandardMaterial3D
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.86
	if tex_name != "":
		mat.albedo_texture = texture("res://assets/generated/" + tex_name + ".png")
		mat.uv1_triplanar = true
		mat.uv1_scale = Vector3.ONE * uv_scale
	if emission > 0:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = emission
	material_cache[key] = mat
	return mat

func box(at: Vector3, size: Vector3, mat: Material, solid: bool = true, owner_node: Node3D = self) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var cube := BoxMesh.new()
	cube.size = size
	mesh.mesh = cube
	mesh.material_override = mat
	mesh.position = at
	owner_node.add_child(mesh)
	if solid:
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var cube_shape := BoxShape3D.new()
		cube_shape.size = size
		shape.shape = cube_shape
		body.add_child(shape)
		mesh.add_child(body)
	return mesh

func light(at: Vector3, color: Color, energy: float, radius: float) -> OmniLight3D:
	var lamp := OmniLight3D.new()
	lamp.position = at
	lamp.light_color = color
	lamp.light_energy = energy
	lamp.omni_range = radius
	lamp.omni_attenuation = 1.3
	add_child(lamp)
	return lamp

func text3d(words: String, at: Vector3, font_size: int, color: Color, scale_factor: float = 0.005) -> Label3D:
	var sign := Label3D.new()
	sign.text = words
	sign.font_size = font_size
	sign.pixel_size = scale_factor
	sign.modulate = color
	sign.outline_modulate = Color("101b23")
	sign.outline_size = 8
	sign.position = at
	sign.no_depth_test = false
	add_child(sign)
	return sign

func build_world() -> void:
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("0d1726")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("7b9aa6")
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment = env
	add_child(environment)
	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-48, -32, 0)
	moon.light_color = Color("91b4c7")
	moon.light_energy = 0.6
	moon.shadow_enabled = true
	add_child(moon)
	var brick: Material = material(Color("849094"), "brick", 0.43)
	var dark_brick: Material = material(Color("59696e"), "brick", 0.43)
	var plaster: Material = material(Color("aaa58e"), "brick", 0.26)
	var ground: Material = material(Color("889291"), "floor", 0.4)
	box(Vector3(0, -0.2, -2), Vector3(8, 0.4, 24), ground)
	box(Vector3(-4.2, 4, -2), Vector3(0.4, 8, 24), brick)
	box(Vector3(4.2, 4.6, -2), Vector3(0.4, 9.2, 24), dark_brick)
	box(Vector3(0, 3, 10), Vector3(8, 6, 0.4), dark_brick)
	# Raised sidewalks give the street a readable curb and channel.
	box(Vector3(-3.3, 0.045, -2), Vector3(1.35, 0.12, 24), material(Color("7c8380"), "floor", 0.4))
	box(Vector3(3.3, 0.045, -2), Vector3(1.35, 0.12, 24), material(Color("707a78"), "floor", 0.4))
	for z: float in [6.0, 1.0, -4.0, -9.0]:
		box(Vector3(-3.9, 0.8, z), Vector3(0.16, 0.1, 2.8), material(INK), false)
		for y: float in [3.4, 6.2]:
			build_window(Vector3(-3.94, y, z), PI / 2.0)
			build_window(Vector3(3.94, y + 0.3, z - 1.0), -PI / 2.0)
	# Horizontal floor bands and drainpipes break repetitive building planes.
	for side: float in [-1.0, 1.0]:
		for y: float in [2.45, 5.1, 7.8]:
			box(Vector3(side * 3.96, y, -2), Vector3(0.19, 0.13, 24), material(INK), false)
		for z: float in [8.3, -2.9, -9.2]:
			box(Vector3(side * 3.86, 3.4, z), Vector3(0.1, 6.8, 0.12), material(Color("314148")), false)
	# Distant shapes terminate the skyline.
	for i: int in range(7):
		box(Vector3(-11 + i * 3.2, 5.5 + i % 3, -24), Vector3(2.6, 11 + i % 3 * 2, 3), material(Color("243544")), false)
	# Back room: actual traversable door opening at x=0, z=-10.
	box(Vector3(-2.8, 2.1, -10), Vector3(2.4, 4.2, 0.35), plaster)
	box(Vector3(2.8, 2.1, -10), Vector3(2.4, 4.2, 0.35), plaster)
	box(Vector3(0, 3.55, -10), Vector3(3.2, 1.3, 0.35), plaster)
	box(Vector3(0, -0.18, -14), Vector3(8, 0.36, 8), material(Color("9d8e73"), "floor", 0.6))
	box(Vector3(-4.1, 2.1, -14), Vector3(0.2, 4.2, 8), plaster)
	box(Vector3(4.1, 2.1, -14), Vector3(0.2, 4.2, 8), plaster)
	box(Vector3(0, 2.1, -18), Vector3(8, 4.2, 0.3), dark_brick)
	box(Vector3(0, 4.25, -14), Vector3(8, 0.25, 8), material(INK))
	box(Vector3(0, 2.9, -9.7), Vector3(3.6, 0.13, 0.8), material(INK), false)
	box(Vector3(-1.55, 1.4, -9.77), Vector3(0.14, 2.8, 0.12), material(INK), false)
	box(Vector3(1.55, 1.4, -9.77), Vector3(0.14, 2.8, 0.12), material(INK), false)
	build_door()
	box(Vector3(0, 3.65, -9.72), Vector3(4.7, 0.84, 0.15), material(Color("132b31")), false)
	text3d("THE NIGHTJAR", Vector3(0, 3.65, -9.6), 67, AMBER, 0.009)
	text3d("RECORDS  /  OPEN LATE", Vector3(0, 3.12, -9.55), 28, PAPER, 0.009)
	# Projecting sign, lamps and paper graphics.
	var side_sign: MeshInstance3D = box(Vector3(-3.4, 3.3, -3), Vector3(0.85, 1.9, 0.16), material(Color("233e45")), false)
	side_sign.rotation.y = 0.12
	text3d("J\nA\nZ\nZ", Vector3(-3.4, 3.32, -2.88), 57, AMBER, 0.006)
	light(Vector3(-3.0, 3.2, -2.5), AMBER, 2.2, 5.5)
	for z: float in [5.8, -5.8]:
		box(Vector3(3.72, 2.8, z), Vector3(0.45, 0.1, 0.24), material(INK), false)
		box(Vector3(3.5, 2.65, z), Vector3(0.18, 0.26, 0.18), material(AMBER, "", 1, 1.5), false)
		light(Vector3(3.25, 2.5, z), AMBER, 2.6, 7)
	light(Vector3(0, 2.6, -8.7), AMBER, 2.4, 5)
	light(Vector3(-2, 2.8, 4), TEAL, 1.8, 7)
	light(Vector3(0, 2.8, -13.8), Color("ffc47a"), 3.4, 8)
	build_poster(Vector3(-3.87, 1.65, 2.6), PI / 2)
	build_poster(Vector3(2.5, 1.55, -9.75), 0)
	build_poster(Vector3(-2.7, 1.8, -17.8), 0)
	# Puddles use painted color, staying compatible with the GL renderer.
	for i: int in range(9):
		var puddle := MeshInstance3D.new()
		var disc := CylinderMesh.new()
		disc.top_radius = 0.6
		disc.bottom_radius = 0.6
		disc.height = 0.005
		disc.radial_segments = 9
		puddle.mesh = disc
		puddle.position = Vector3(sin(i * 2.7) * 1.8, 0.012, 7 - i * 1.9)
		puddle.scale = Vector3(1.8, 1, 0.45)
		puddle.material_override = material(Color("303c40"))
		add_child(puddle)
	# Crossing wires are thin 3D geometry.
	for z: float in [3.0, -5.0]:
		for i: int in range(10):
			var x: float = -4.0 + i * 0.8
			box(Vector3(x, 6.3 - sin(float(i) / 9 * PI) * 0.9, z), Vector3(0.86, 0.023, 0.023), material(INK), false)
	build_props()
	build_npc()
	text3d("HARBOR EXIT  →", Vector3(0.4, 1.5, 9.72), 43, TEAL, 0.009).rotation.y = PI

func build_window(at: Vector3, angle: float) -> void:
	var holder := Node3D.new()
	holder.position = at
	holder.rotation.y = angle
	add_child(holder)
	box(Vector3.ZERO, Vector3(1.25, 1.6, 0.07), material(INK), false, holder)
	var glow: Color = Color("b9945e") if int(absf(at.z)) % 3 != 0 else Color("3d6572")
	box(Vector3(0, 0, 0.05), Vector3(1.04, 1.4, 0.04), material(glow, "", 1, 0.25), false, holder)
	box(Vector3(0, 0, 0.09), Vector3(0.055, 1.45, 0.04), material(INK), false, holder)
	box(Vector3(0, 0.12, 0.09), Vector3(1.1, 0.07, 0.04), material(INK), false, holder)
	for y: float in [-0.42, -0.31, -0.2, 0.38, 0.49, 0.60]:
		box(Vector3(0, y, 0.10), Vector3(1.1, 0.032, 0.03), material(Color("38464a")), false, holder)
	box(Vector3(0, -0.86, 0.1), Vector3(1.4, 0.10, 0.25), material(INK), false, holder)

func build_poster(at: Vector3, angle: float) -> void:
	var tex: Texture2D = texture("res://assets/generated/poster.png")
	if tex == null:
		return
	var poster := Sprite3D.new()
	poster.texture = tex
	poster.pixel_size = 1.25 / float(tex.get_height())
	poster.position = at
	poster.rotation.y = angle
	poster.shaded = true
	add_child(poster)

func build_door() -> void:
	door = Node3D.new()
	door.position = Vector3(-1.45, 0, -10)
	add_child(door)
	box(Vector3(1.45, 1.38, 0), Vector3(2.9, 2.76, 0.12), material(Color("31494b")), false, door)
	for x: float in [0.7, 2.15]:
		box(Vector3(x, 1.75, 0.07), Vector3(1.1, 1.4, 0.04), material(Color("789893")), false, door)
		box(Vector3(x, 0.48, 0.08), Vector3(1.1, 0.62, 0.04), material(INK), false, door)
	box(Vector3(2.62, 1.1, 0.13), Vector3(0.1, 0.3, 0.09), material(AMBER), false, door)
	var body := StaticBody3D.new()
	door_shape = CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.9, 2.76, 0.16)
	door_shape.shape = shape
	door_shape.position = Vector3(1.45, 1.38, 0)
	body.add_child(door_shape)
	door.add_child(body)

func build_props() -> void:
	var wood: Material = material(Color("b49d7c"), "wood", 0.45)
	for at: Vector3 in [Vector3(-3.0, 0.48, 5), Vector3(-2.9, 0.48, -6.5), Vector3(3.15, 0.48, -2.2)]:
		box(at, Vector3(1.05, 0.95, 0.85), wood)
		for y: float in [-0.3, 0.3]:
			box(at + Vector3(0, y, 0.44), Vector3(1.1, 0.08, 0.05), material(INK), false)
	box(Vector3(-2.5, 0.43, -6.7), Vector3(0.7, 0.85, 0.7), material(Color("3b5959")))
	box(Vector3(0, 0.87, -16.15), Vector3(4.7, 0.18, 0.85), wood)
	for x: float in [-2.05, 2.05]:
		box(Vector3(x, 0.43, -16.15), Vector3(0.16, 0.86, 0.7), material(INK))
	for x: float in [-3.4, 3.4]:
		box(Vector3(x, 1.25, -15.5), Vector3(0.5, 2.5, 3.0), material(INK))
		for y: float in [0.45, 1.1, 1.8, 2.4]:
			box(Vector3(x, y, -15.5), Vector3(0.7, 0.07, 3.0), wood, false)
			var records: Texture2D = texture("res://assets/generated/records.png")
			if records != null:
				var strip := Sprite3D.new()
				strip.texture = records
				strip.pixel_size = 2.8 / float(records.get_width())
				strip.scale.y = 0.56 / (2.8 * float(records.get_height()) / float(records.get_width()))
				strip.position = Vector3(x - signf(x) * 0.36, y + 0.33, -15.5)
				strip.rotation.y = PI / 2 if x < 0 else -PI / 2
				strip.shaded = true
				add_child(strip)
			else:
				for z: float in [-14.4, -15.3, -16.2]:
					box(Vector3(x, y + 0.26, z), Vector3(0.42, 0.45, 0.55), material(Color("6c807c")), false)
	var back_records: Texture2D = texture("res://assets/generated/records.png")
	if back_records != null:
		var back_strip := Sprite3D.new()
		back_strip.texture = back_records
		back_strip.pixel_size = 4.0 / float(back_records.get_width())
		back_strip.position = Vector3(0, 1.8, -17.79)
		back_strip.shaded = true
		add_child(back_strip)
	box(Vector3(-1.45, 1.04, -16.08), Vector3(0.5, 0.22, 0.32), material(INK))
	text3d("NO CREDIT. NO QUESTIONS.", Vector3(0, 2.95, -17.7), 44, PAPER, 0.008)
	var model_path: String = "res://assets/models/street_props.glb"
	if ResourceLoader.exists(model_path):
		var scene: PackedScene = load(model_path) as PackedScene
		if scene != null:
			for at: Vector3 in [Vector3(-3.08, 0.11, 0.0), Vector3(3.05, 0.11, -7.6)]:
				var instance: Node3D = scene.instantiate() as Node3D
				instance.position = at
				if at.x > 0:
					instance.rotation.y = PI
				add_child(instance)
				var prop_collider: MeshInstance3D = box(at + Vector3(0, 0.67, 0), Vector3(1.6, 1.34, 0.8), material(INK))
				prop_collider.visible = false
			loaded_assets.append(model_path)

func build_npc() -> void:
	npc = Sprite3D.new()
	var tex: Texture2D = texture("res://assets/generated/contact.png")
	if tex == null:
		# Explicit geometric stand-in, only until generated art is present.
		box(Vector3(0, 1.1, -15.2), Vector3(0.6, 1.6, 0.05), material(Color("ad9878")), false)
		box(Vector3(0, 1.9, -15.2), Vector3(0.35, 0.4, 0.05), material(PAPER), false)
	else:
		npc.texture = tex
		npc.pixel_size = 1.8 / float(tex.get_height())
		npc.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		npc.shaded = false
		npc.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		npc.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	npc.position = Vector3(0, 0.90, -15.15)
	add_child(npc)
	var body := StaticBody3D.new()
	var collider := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.4
	shape.height = 1.9
	collider.shape = shape
	body.position = Vector3(0, 0.95, -15.15)
	body.add_child(collider)
	add_child(body)

func build_player() -> void:
	player = Player.new()
	player.position = Vector3(0.5, 0.15, 6.8)
	player.rotation.y = 0.035
	add_child(player)

func label_ui(parent: Control, words: String, at: Vector2, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = words
	label.position = at
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color("0a121b"))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	parent.add_child(label)
	return label

func build_hud() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var ui := Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(ui)
	var top := ColorRect.new()
	top.color = Color(0.025, 0.04, 0.06, 0.78)
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_bottom = 112
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(top)
	label_ui(ui, "DEAD LETTER", Vector2(36, 21), 34, PAPER)
	label_ui(ui, "港口来信  /  A NOIR PLAYABLE SKETCH", Vector2(38, 66), 15, Color("8cacae"))
	chapter = label_ui(ui, "01   /   THE NIGHTJAR", Vector2(0, 29), 18, AMBER)
	chapter.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	chapter.offset_left = -355
	chapter.offset_top = 27
	objective = label_ui(ui, "找到唱片店内的接头人", Vector2.ZERO, 19, PAPER)
	objective.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	objective.offset_left = -355
	objective.offset_top = 62
	var cross := Label.new()
	cross.text = "·"
	cross.add_theme_font_size_override("font_size", 32)
	cross.add_theme_color_override("font_color", PAPER)
	cross.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	cross.offset_left = -5
	cross.offset_top = -22
	ui.add_child(cross)
	prompt = Label.new()
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 22)
	prompt.add_theme_color_override("font_color", PAPER)
	prompt.add_theme_color_override("font_shadow_color", INK)
	prompt.add_theme_constant_override("shadow_offset_x", 2)
	prompt.add_theme_constant_override("shadow_offset_y", 2)
	ui.add_child(prompt)
	prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	prompt.offset_left = -440
	prompt.offset_right = 440
	prompt.offset_top = -183
	prompt.offset_bottom = -140
	dialogue = Label.new()
	dialogue.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialogue.add_theme_font_size_override("font_size", 21)
	dialogue.add_theme_color_override("font_color", PAPER)
	dialogue.add_theme_color_override("font_shadow_color", INK)
	dialogue.add_theme_constant_override("shadow_offset_x", 3)
	dialogue.add_theme_constant_override("shadow_offset_y", 3)
	ui.add_child(dialogue)
	dialogue.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	dialogue.offset_left = -600
	dialogue.offset_right = 600
	dialogue.offset_top = -132
	dialogue.offset_bottom = -65
	var foot := ColorRect.new()
	foot.color = Color(0.025, 0.04, 0.06, 0.8)
	ui.add_child(foot)
	foot.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	foot.offset_top = -50
	var controls := label_ui(foot, "W A S D   移动      SHIFT   快走      E   互动      ESC   鼠标      R   重来", Vector2(36, 13), 15, Color("b3b8ad"))
	controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var stamp := label_ui(foot, "DOCKSIDE  ·  00:17", Vector2.ZERO, 14, TEAL)
	stamp.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	stamp.offset_left = -195
	stamp.offset_top = 14
	veil = ColorRect.new()
	veil.color = Color(0.025, 0.04, 0.06, 0.86)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(veil)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.visible = false
	var pause_label := label_ui(veil, "PAUSED\n\n点击继续 / Esc 返回\n\nWASD 移动 · 鼠标观察 · E 互动", Vector2.ZERO, 26, PAPER)
	pause_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	pause_label.offset_left = -250
	pause_label.offset_top = -80

func _process(delta: float) -> void:
	elapsed += delta
	if is_instance_valid(npc):
		npc.position.y = 0.90 + sin(elapsed * 1.7) * 0.008
	if dialogue_timer > 0:
		dialogue_timer -= delta
		if dialogue_timer <= 0:
			dialogue.text = ""
	if player == null or smoke_test:
		return
	target = interaction_target()
	match target:
		"door": prompt.text = "[ E ]  关门" if door_open else "[ E ]  推门进入唱片店"
		"contact": prompt.text = "[ E ]  接头人" if not has_letter else "[ E ]  再问一句"
		"exit": prompt.text = "[ E ]  带信封离开" if has_letter else "[ E ]  通往港口"
		_: prompt.text = ""
	if completed:
		prompt.text = "[ R ]  重新开始"

func interaction_target() -> String:
	var camera: Camera3D = player.camera
	var eye: Vector3 = camera.global_position
	var forward: Vector3 = -camera.global_basis.z
	var candidates: Array[Dictionary] = [
		{"name": "door", "at": Vector3(clampf(eye.x, -1.3, 1.3), clampf(eye.y, 0.3, 2.7), -9.9), "range": 3.2},
		{"name": "contact", "at": Vector3(0, 1.4, -15.15), "range": 3.2},
		{"name": "exit", "at": Vector3(0.4, 1.5, 9.6), "range": 3.5}
	]
	for item: Dictionary in candidates:
		var offset: Vector3 = (item["at"] as Vector3) - eye
		if offset.length() < float(item["range"]) and forward.dot(offset.normalized()) > 0.67:
			var ray := PhysicsRayQueryParameters3D.create(eye, item["at"])
			ray.exclude = [player.get_rid()]
			var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(ray)
			if item["name"] == "contact" and not hit.is_empty():
				var hit_position: Vector3 = hit["position"]
				if hit_position.distance_to(item["at"]) > 0.65:
					continue
			return str(item["name"])
	return ""

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			veil.visible = true
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			veil.visible = false
	if event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		veil.visible = false
	if event.is_action_pressed("restart"):
		get_tree().reload_current_scene()
	if event.is_action_pressed("interact") and (Input.mouse_mode == Input.MOUSE_MODE_CAPTURED or (playtest and DisplayServer.get_name() == "headless")) and not completed:
		interact(target)

func set_door(value: bool) -> void:
	door_open = value
	door_shape.set_deferred("disabled", value)
	var tween: Tween = create_tween()
	tween.tween_property(door, "rotation:y", -1.5 if value else 0.0, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func interact(which: String) -> void:
	match which:
		"door":
			set_door(not door_open)
		"contact":
			if not has_letter:
				has_letter = true
				objective.text = "拿到信封，原路返回港口出口"
				chapter.text = "02   /   ONE LAST DELIVERY"
				say("接头人：「别拆开。沿原路走，港口有人等你。」\n你拿到了一个没有署名的信封。", 7.0)
			else:
				say("接头人：「唱片还在转。你该走了。」", 4.0)
		"exit":
			if has_letter:
				completed = true
				objective.text = "送达前夜 · 小样完成"
				chapter.text = "03   /   TO BE CONTINUED"
				say("信封藏进大衣。夜色吞没了你的脚步。\nDEAD LETTER  /  END OF SLICE", 999.0)
			else:
				say("还不能走。唱片店的接头人正在等你。", 4.0)

func say(words: String, duration: float) -> void:
	dialogue.text = words
	dialogue_timer = duration

func capture_frame() -> void:
	await get_tree().create_timer(1.5).timeout
	await RenderingServer.frame_post_draw
	var screenshot: Image = get_viewport().get_texture().get_image()
	var error: Error = screenshot.save_png(capture_path)
	print("CAPTURE ", capture_path, " error=", error)
	get_tree().quit(0 if error == OK else 1)

func run_smoke() -> void:
	await get_tree().physics_frame
	assert(player != null and player.camera != null, "Player/camera missing")
	assert(not has_letter and not completed and not door_open, "Invalid initial mission")
	get_tree().create_timer(8.0).timeout.connect(func() -> void:
		push_error("SMOKE FAIL: verification timed out")
		get_tree().quit(1)
	)
	player.position = Vector3(0, 0.05, -7)
	var blocked: KinematicCollision3D = player.move_and_collide(Vector3(0, 0, -6))
	assert(blocked != null and player.position.z > -10, "Closed door allowed passage")
	interact("exit")
	assert(not completed, "Exit must be locked before contact")
	interact("door")
	await get_tree().physics_frame
	assert(door_open and door_shape.disabled, "Door did not open")
	var pass_through: KinematicCollision3D = player.move_and_collide(Vector3(0, 0, -3.2))
	assert(pass_through == null and player.position.z < -12, "Open doorway is not traversable")
	player.position = Vector3(0, 0.05, -12.7)
	player.rotation.y = 0
	await get_tree().physics_frame
	assert(interaction_target() == "contact", "Contact cannot be targeted from room")
	interact(interaction_target())
	assert(has_letter, "Contact did not give letter")
	interact("contact")
	assert(has_letter and not completed, "Repeated contact corrupted state")
	interact("door")
	await get_tree().physics_frame
	assert(not door_open and not door_shape.disabled, "Door did not close")
	player.position = Vector3(0.4, 0.05, 7.2)
	player.rotation.y = PI
	await get_tree().physics_frame
	assert(interaction_target() == "exit", "Exit cannot be targeted")
	interact(interaction_target())
	assert(completed, "Mission did not complete")
	print("SMOKE PASS: player, closed-door collision, open-door passage, contact ray targeting, letter, gated exit, completion")
	print("ASSETS: ", loaded_assets)
	get_tree().quit()


# Exercise the public input path and normal CharacterBody3D physics at runtime.
# Camera turns are deterministic; movement and E use the same input as the player.
func playtest_check(condition: bool, message: String) -> bool:
	if condition:
		print("PLAYTEST CHECK: ", message)
		return true
	push_error("PLAYTEST FAIL: " + message)
	Input.action_release("forward")
	get_tree().quit(1)
	return false

func playtest_press_e() -> void:
	var event := InputEventKey.new()
	event.physical_keycode = KEY_E
	event.keycode = KEY_E
	event.pressed = true
	Input.parse_input_event(event)
	await get_tree().process_frame
	await get_tree().physics_frame
	var release := InputEventKey.new()
	release.physical_keycode = KEY_E
	release.keycode = KEY_E
	release.pressed = false
	Input.parse_input_event(release)
	await get_tree().process_frame

func playtest_walk_to(z: float, direction: float) -> bool:
	Input.action_press("forward")
	for frame: int in range(1200):
		await get_tree().physics_frame
		if (direction < 0 and player.position.z <= z) or (direction > 0 and player.position.z >= z):
			Input.action_release("forward")
			for settle: int in range(12):
				await get_tree().physics_frame
			return true
	Input.action_release("forward")
	return playtest_check(false, "Movement timed out at " + str(player.position))

func playtest_capture(filename: String) -> void:
	if capture_dir.is_empty() or DisplayServer.get_name() == "headless":
		return
	DirAccess.make_dir_recursive_absolute(capture_dir)
	await RenderingServer.frame_post_draw
	var image: Image = get_viewport().get_texture().get_image()
	var output: String = capture_dir.path_join(filename + ".png")
	var error: Error = image.save_png(output)
	playtest_check(error == OK, "Screenshot " + output)

func run_playtest() -> void:
	# Overall watchdog makes any failed test terminate instead of hanging the app.
	get_tree().create_timer(60.0).timeout.connect(func() -> void:
		push_error("PLAYTEST FAIL: overall timeout")
		get_tree().quit(1)
	)
	await get_tree().physics_frame
	player.rotation.y = 0.0
	player.camera.rotation.x = 0.0
	if not playtest_check(not has_letter and not completed and not door_open, "Initial mission state"):
		return
	if not await playtest_walk_to(-9.4, -1.0):
		return
	# Continue pressing forward against the closed door, proving collision in normal physics.
	Input.action_press("forward")
	for frame: int in range(40):
		await get_tree().physics_frame
	Input.action_release("forward")
	if not playtest_check(player.position.z > -10 and player.position.z < -9.4, "Closed door blocks walking"):
		return
	await get_tree().process_frame
	if not playtest_check(target == "door", "Door selected by normal proximity/view targeting"):
		return
	await playtest_capture("01-door")
	await playtest_press_e()
	await get_tree().physics_frame
	if not playtest_check(door_open and door_shape.disabled, "E opens the door"):
		return
	await get_tree().create_timer(0.5).timeout
	if not await playtest_walk_to(-13.1, -1.0):
		return
	await get_tree().process_frame
	if not playtest_check(player.position.z < -12 and target == "contact", "Walk through doorway and target contact"):
		return
	await playtest_capture("02-contact")
	await playtest_press_e()
	if not playtest_check(has_letter and not completed, "E obtains the envelope"):
		return
	await playtest_capture("03-envelope")
	player.rotation.y = PI
	if not await playtest_walk_to(7.2, 1.0):
		return
	await get_tree().process_frame
	if not playtest_check(target == "exit", "Walk back through doorway to harbor exit"):
		return
	await playtest_press_e()
	if not playtest_check(completed, "E completes the delivery slice"):
		return
	await playtest_capture("04-completed")
	print("PLAYTEST PASS: real movement input, closed-door collision, E door, interior traversal, E contact, return walk, E exit")
	get_tree().quit(0)
