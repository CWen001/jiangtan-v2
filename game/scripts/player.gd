extends CharacterBody3D

var camera: Camera3D
var active: bool = true
var bob_time: float = 0.0
var headless_input: bool = false
var touch_axes := Vector2.ZERO

func _ready() -> void:
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.28
	capsule.height = 1.75
	var collider := CollisionShape3D.new()
	collider.shape = capsule
	collider.position.y = 0.9
	add_child(collider)
	camera = Camera3D.new()
	camera.position.y = 1.65
	camera.fov = 78.0
	camera.near = 0.06
	camera.current = true
	add_child(camera)
	floor_snap_length = 0.2

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and active:
		look(event.relative)

func look(relative: Vector2) -> void:
	if not active:return
	rotate_y(-relative.x * 0.0023)
	camera.rotation.x = clampf(camera.rotation.x - relative.y * 0.0023, -1.35, 1.35)

func _physics_process(delta: float) -> void:
	if not active:
		return
	var axes := touch_axes
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED or headless_input:
		axes = (axes + Input.get_vector("left", "right", "forward", "back")).limit_length()
	var direction: Vector3 = transform.basis * Vector3(axes.x, 0, axes.y)
	var speed: float = 4.4 if Input.is_action_pressed("sprint") else 2.9
	velocity.x = move_toward(velocity.x, direction.x * speed, delta * 18.0)
	velocity.z = move_toward(velocity.z, direction.z * speed, delta * 18.0)
	if not is_on_floor():
		velocity.y -= 18.0 * delta
	else:
		velocity.y = -0.1
	move_and_slide()
	bob_time += delta * Vector2(velocity.x, velocity.z).length() * 2.8
	camera.position.y = 1.65 + sin(bob_time) * 0.018 * minf(axes.length(), 1.0)
