extends CharacterBody3D

var world: Node3D
var identity := "courier"
var home := Vector3.ZERO
var health := 80
var state := "idle"
var timer := 0.0
var hostile := false
var visual: MeshInstance3D
var paint: ShaderMaterial
var shape: CollisionShape3D
var pose := 0
var age := 0.0

func _ready() -> void:
	home = position
	collision_layer = 2
	collision_mask = 3
	floor_snap_length = .4
	shape = CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = .3
	capsule.height = 1.7
	shape.shape = capsule
	shape.position.y = .88
	add_child(shape)
	visual = MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(2,2)
	visual.mesh = quad
	visual.position.y = .94
	paint = ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = """shader_type spatial;
render_mode cull_disabled;
uniform sampler2D atlas : source_color, filter_linear;
uniform float pose = 0.0;
void fragment(){
 vec2 cell=vec2(mod(pose,3.0),floor(pose/3.0));
 vec4 c=texture(atlas,(clamp(UV,vec2(.004),vec2(.996))+cell)/vec2(3.,2.));
 if(c.r-c.g>.08 && c.b-c.g>.08){discard;}
 ALBEDO=c.rgb*.72; EMISSION=c.rgb*.06; ROUGHNESS=1.;
}"""
	paint.shader = shader
	paint.set_shader_parameter("atlas",load("res://assets/harbor-v3/"+identity+".png"))
	visual.material_override = paint
	add_child(visual)
	var shadow := MeshInstance3D.new()
	var disk := CylinderMesh.new()
	disk.top_radius=.31; disk.bottom_radius=.31; disk.height=.003
	shadow.mesh=disk
	var ink := StandardMaterial3D.new()
	ink.albedo_color=Color(.018,.023,.027,.36)
	ink.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	ink.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	shadow.material_override=ink
	shadow.position.y=.025
	add_child(shadow)

func set_pose(value: int) -> void:
	pose=value
	paint.set_shader_parameter("pose",float(value))

func challenge() -> void:
	if health<=0:return
	hostile=true
	state="guard"
	timer=.5
	set_pose(1)

func receive_hit(amount: int, direction: Vector3) -> void:
	if health<=0:return
	health=maxi(0,health-amount)
	hostile=true
	velocity+=direction*2.4
	if health==0:
		state="ko"
		set_pose(5)
		shape.set_deferred("disabled",true)
	else:
		state="hit"
		timer=.33
		set_pose(4)

func reset() -> void:
	position=home; velocity=Vector3.ZERO; health=80; hostile=false
	state="idle"; timer=0.; set_pose(0); shape.disabled=false

func _physics_process(delta: float) -> void:
	if world.player==null:return
	age+=delta
	var target: Vector3=world.player.global_position
	visual.look_at(Vector3(target.x,visual.global_position.y,target.z),Vector3.UP,true)
	if health<=0:return
	if not is_on_floor():velocity.y-=18*delta
	else:velocity.y=-.1
	velocity.x=move_toward(velocity.x,0,delta*10)
	velocity.z=move_toward(velocity.z,0,delta*10)
	timer-=delta
	if hostile and world.health>0:
		var offset:=target-global_position
		offset.y=0
		var distance:=offset.length()
		match state:
			"hit","recover":
				if timer<=0:state="guard";set_pose(1)
			"windup":
				if timer<=0:
					state="attack";timer=.18;set_pose(3)
					if distance<1.8 and absf(target.y-global_position.y)<1 and world.clear_path(self,world.player):world.take_hit(12,self)
			"attack":
				if timer<=0:state="recover";timer=.7;set_pose(1)
			_:
				if distance<1.65 and timer<=0 and world.clear_path(self,world.player):
					state="windup";timer=.48;set_pose(2)
				elif distance>1.35:
					# ponytail: local pursuit within one landing; use navigation for patrol routes later.
					if home.distance_to(global_position)<7 and absf(target.y-home.y)<1:
						velocity.x=offset.normalized().x*1.25
						velocity.z=offset.normalized().z*1.25
					set_pose(1)
	else:
		visual.position.y=.94+sin(age*1.5)*.006
	move_and_slide()
