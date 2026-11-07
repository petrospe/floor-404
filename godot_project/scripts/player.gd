class_name Player
extends CharacterBody3D
## First-person controller for Floor 404 — The Null Pointer.
## WASD with acceleration, clamped mouse look, head bob, E-to-interact, and footsteps.
## No jump, no crouch, and no visible body mesh.

signal interact_triggered(target: Node)
signal footstep_triggered(surface_name: StringName)
signal player_died

var last_safe_transform := Transform3D.IDENTITY:
	set(value):
		last_safe_transform = value
		_capture_safe_pitch()

const PITCH_LIMIT_DEGREES := 89.0
const EYE_HEIGHT := 1.62
const BODY_RADIUS := 0.3
const BODY_HEIGHT := 1.75

@export_group("Movement")
@export_range(0.5, 12.0, 0.1, "suffix:m/s") var move_speed: float = 3.0
@export_range(1.0, 40.0, 0.1, "suffix:m/s²") var acceleration: float = 10.0
@export_range(1.0, 40.0, 0.1, "suffix:m/s²") var friction: float = 14.0

@export_group("Look")
@export_range(0.0005, 0.02, 0.0001) var mouse_sensitivity: float = 0.002

@export_group("Interaction")
@export_range(0.5, 8.0, 0.1, "or_greater", "suffix:m") var interaction_distance: float = 2.5:
	set(value):
		interaction_distance = maxf(value, 0.1)
		_apply_interaction_distance()

@export_group("Head Bob")
@export var bob_frequency: float = 1.8
@export var bob_amplitude: float = 0.035
@export var bob_sway: float = 0.018

@export_group("Footsteps")
@export_range(0.2, 1.2, 0.01, "suffix:s") var footstep_interval: float = 0.52
@export var footstep_min_speed: float = 0.4

var _camera: Camera3D
var _interaction_ray: RayCast3D
var _floor_ray: RayCast3D
var _camera_rest := Vector3(0.0, EYE_HEIGHT, 0.0)
var _bob_time: float = 0.0
var _footstep_timer: float = 0.0
var _use_move_actions: bool = false
var _use_interact_action: bool = false
var _gravity: float = 9.8
var _respawning: bool = false
var _last_safe_camera_pitch: float = 0.0

const _SURFACE_GROUPS: Array[StringName] = [
	&"carpet", &"tile", &"marble", &"concrete", &"water", &"metal",
]


func _ready() -> void:
	_gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))
	_use_move_actions = (
		InputMap.has_action(&"move_forward")
		and InputMap.has_action(&"move_back")
		and InputMap.has_action(&"move_left")
		and InputMap.has_action(&"move_right")
	)
	_use_interact_action = InputMap.has_action(&"interact")
	floor_snap_length = 0.3
	floor_max_angle = deg_to_rad(50.0)
	_ensure_body()
	_ensure_camera()
	_ensure_interaction_ray()
	_ensure_floor_ray()
	_apply_interaction_distance()
	last_safe_transform = global_transform
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func is_respawning() -> bool:
	return _respawning


## Move the body to another floor plate, such as the far side of an elevator ride.
func travel_to(target: Transform3D) -> void:
	velocity = Vector3.ZERO
	global_transform = target
	last_safe_transform = target
	_sync_physics_state(target)
	reset_physics_interpolation()


## Freeze, fade out, place the body on last_safe_transform, then fade in.
func respawn(fade_out_seconds: float = 0.1, fade_in_seconds: float = 0.15) -> void:
	if _respawning:
		return
	_respawning = true
	_halt_motion()
	set_physics_process(false)
	player_died.emit()

	var overlay := FadeOverlay.find_or_create(get_tree())
	if overlay != null:
		await overlay.fade_to(1.0, fade_out_seconds)
	if not is_inside_tree():
		return

	_apply_safe_pose()
	_halt_motion()
	if overlay != null:
		await overlay.fade_to(0.0, fade_in_seconds)
	if not is_inside_tree():
		return

	set_physics_process(true)
	_respawning = false


func _unhandled_input(event: InputEvent) -> void:
	if _respawning:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_look(event as InputEventMouseMotion)
		return

	if event.is_action_pressed(&"ui_cancel"):
		Input.mouse_mode = (
			Input.MOUSE_MODE_VISIBLE
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
			else Input.MOUSE_MODE_CAPTURED
		)
		return

	if _is_interact_pressed(event):
		_try_interact()


func _physics_process(delta: float) -> void:
	if _respawning:
		_halt_motion()
		return

	var wish_direction := _wish_direction()
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	var rate := acceleration if wish_direction != Vector3.ZERO else friction
	var target := wish_direction * move_speed
	horizontal = horizontal.move_toward(target, rate * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z

	if not is_on_floor():
		velocity.y -= _gravity * delta

	move_and_slide()

	var planar_speed := Vector2(velocity.x, velocity.z).length()
	_update_footsteps(delta, planar_speed)
	_update_head_bob(delta, planar_speed)


func _look(event: InputEventMouseMotion) -> void:
	rotate_y(-event.relative.x * mouse_sensitivity)
	_camera.rotate_x(-event.relative.y * mouse_sensitivity)
	var limit := deg_to_rad(PITCH_LIMIT_DEGREES)
	_camera.rotation.x = clampf(_camera.rotation.x, -limit, limit)


func _wish_direction() -> Vector3:
	var input_vector := _read_move_vector()
	if input_vector == Vector2.ZERO:
		return Vector3.ZERO
	return (global_basis * Vector3(input_vector.x, 0.0, input_vector.y)).normalized()


func _read_move_vector() -> Vector2:
	if _use_move_actions:
		return Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")

	var x := float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A))
	var y := float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
	return Vector2(x, y).limit_length(1.0)


func _is_interact_pressed(event: InputEvent) -> bool:
	if _use_interact_action and event.is_action_pressed(&"interact"):
		return true
	return event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E


func _try_interact() -> void:
	_interaction_ray.force_raycast_update()
	if not _interaction_ray.is_colliding():
		return

	var target := _find_interactable(_interaction_ray.get_collider())
	if target == null:
		return
	if target.get_method_argument_count(&"interact") > 0:
		target.interact(self)
	else:
		target.interact()
	interact_triggered.emit(target)


func _find_interactable(collider: Object) -> Node:
	var current := collider as Node
	while current != null and current != self:
		if current.has_method(&"interact"):
			return current
		current = current.get_parent()
	return null


func _update_head_bob(delta: float, planar_speed: float) -> void:
	var grounded := _floor_ray.is_colliding() or is_on_floor()
	var moving := grounded and planar_speed > footstep_min_speed
	if moving:
		var speed_scale := planar_speed / maxf(move_speed, 0.01)
		_bob_time += delta * bob_frequency * speed_scale
		var cycle := _bob_time * TAU
		var offset := Vector3(
			cos(cycle * 0.5) * bob_sway,
			sin(cycle) * bob_amplitude,
			0.0
		)
		_camera.position = _camera_rest + offset
		return

	_bob_time = 0.0
	_camera.position = _camera.position.lerp(_camera_rest, clampf(delta * 10.0, 0.0, 1.0))


func _update_footsteps(delta: float, planar_speed: float) -> void:
	_floor_ray.force_raycast_update()
	if planar_speed < footstep_min_speed or not _floor_ray.is_colliding():
		_footstep_timer = 0.0
		return

	# Faster movement shortens the gap between steps.
	var interval := footstep_interval * (move_speed / maxf(planar_speed, 0.01))
	_footstep_timer += delta
	if _footstep_timer < interval:
		return

	_footstep_timer = fmod(_footstep_timer, interval)
	footstep_triggered.emit(_surface_name(_floor_ray.get_collider()))


func _surface_name(collider: Object) -> StringName:
	if collider is CollisionObject3D:
		var body := collider as CollisionObject3D
		if body.has_meta(&"floor_surface"):
			return StringName(str(body.get_meta(&"floor_surface")))
		for group: StringName in _SURFACE_GROUPS:
			if body.is_in_group(group):
				return group
	return &"default"


func _capture_safe_pitch() -> void:
	if _camera == null:
		return
	_last_safe_camera_pitch = _camera.rotation.x


func _apply_safe_pose() -> void:
	global_transform = last_safe_transform
	if _camera != null:
		_camera.rotation.x = _last_safe_camera_pitch
		_camera.position = _camera_rest
	_sync_physics_state(last_safe_transform)
	reset_physics_interpolation()


func _halt_motion() -> void:
	velocity = Vector3.ZERO
	_bob_time = 0.0
	_footstep_timer = 0.0
	if is_inside_tree():
		_zero_server_velocity.call_deferred()


func _zero_server_velocity() -> void:
	if not is_inside_tree():
		return
	var rid := get_rid()
	PhysicsServer3D.body_set_state(rid, PhysicsServer3D.BODY_STATE_LINEAR_VELOCITY, Vector3.ZERO)
	PhysicsServer3D.body_set_state(rid, PhysicsServer3D.BODY_STATE_ANGULAR_VELOCITY, Vector3.ZERO)


func _sync_physics_state(body_transform: Transform3D) -> void:
	if not is_inside_tree():
		return
	var rid := get_rid()
	PhysicsServer3D.body_set_state(rid, PhysicsServer3D.BODY_STATE_TRANSFORM, body_transform)
	PhysicsServer3D.body_set_state(rid, PhysicsServer3D.BODY_STATE_LINEAR_VELOCITY, Vector3.ZERO)
	PhysicsServer3D.body_set_state(rid, PhysicsServer3D.BODY_STATE_ANGULAR_VELOCITY, Vector3.ZERO)


func _apply_interaction_distance() -> void:
	if _interaction_ray == null:
		return
	_interaction_ray.target_position = Vector3(0.0, 0.0, -interaction_distance)


func _ensure_body() -> void:
	if get_node_or_null(^"CollisionShape3D") != null:
		return
	var shape_node := CollisionShape3D.new()
	shape_node.name = "CollisionShape3D"
	var capsule := CapsuleShape3D.new()
	capsule.radius = BODY_RADIUS
	capsule.height = BODY_HEIGHT
	shape_node.shape = capsule
	shape_node.position.y = BODY_HEIGHT * 0.5
	add_child(shape_node)


func _ensure_camera() -> void:
	_camera = get_node_or_null(^"Camera3D") as Camera3D
	if _camera == null:
		_camera = Camera3D.new()
		_camera.name = "Camera3D"
		_camera.position = Vector3(0.0, EYE_HEIGHT, 0.0)
		add_child(_camera)
	_camera.current = true
	_camera_rest = _camera.position


func _ensure_interaction_ray() -> void:
	_interaction_ray = _camera.get_node_or_null(^"InteractionRay") as RayCast3D
	if _interaction_ray == null:
		_interaction_ray = RayCast3D.new()
		_interaction_ray.name = "InteractionRay"
		_camera.add_child(_interaction_ray)
	_interaction_ray.enabled = true
	_interaction_ray.exclude_parent = true
	_interaction_ray.collide_with_areas = false
	_interaction_ray.collide_with_bodies = true
	_interaction_ray.add_exception(self)


func _ensure_floor_ray() -> void:
	_floor_ray = get_node_or_null(^"FloorRay") as RayCast3D
	if _floor_ray == null:
		_floor_ray = RayCast3D.new()
		_floor_ray.name = "FloorRay"
		add_child(_floor_ray)
	_floor_ray.enabled = true
	_floor_ray.exclude_parent = true
	_floor_ray.collide_with_areas = false
	_floor_ray.collide_with_bodies = true
	_floor_ray.position = Vector3(0.0, 0.15, 0.0)
	_floor_ray.target_position = Vector3(0.0, -0.45, 0.0)
	_floor_ray.add_exception(self)
