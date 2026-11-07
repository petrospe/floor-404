class_name Door
extends Interactable
## Hinged or sliding door. Origin should sit on the hinge when using HINGE motion.
## Assign open/close/locked streams on the exported AudioStreamPlayer3D.

enum Motion { HINGE, SLIDE }

signal door_state_changed(is_open: bool)
signal locked_attempted(interactor: Node)

@export_group("Motion")
@export var motion: Motion = Motion.HINGE
@export var pivot_path: NodePath
@export_range(0.05, 3.0, 0.01, "suffix:s") var duration: float = 0.55
@export var starts_open: bool = false
@export_range(-180.0, 180.0, 0.5, "suffix:°") var open_angle_degrees: float = 95.0
@export var hinge_axis: Vector3 = Vector3.UP
@export var slide_offset: Vector3 = Vector3(1.1, 0.0, 0.0)

@export_group("Lock")
@export var locked: bool = false
## Empty key means the door stays shut until unlock() is called.
@export var required_key: StringName = &""
@export var consume_key: bool = false

@export_group("Audio")
@export var audio_player_path: NodePath
@export var open_sound: AudioStream
@export var close_sound: AudioStream
@export var locked_sound: AudioStream

var _pivot: Node3D
var _audio: AudioStreamPlayer3D
var _tween: Tween
var _closed_basis: Basis
var _closed_position: Vector3
var _open_amount: float = 0.0
var _target_open: bool = false


func _ready() -> void:
	_pivot = _resolve_pivot()
	_audio = _resolve_audio()
	_closed_basis = _pivot.basis
	_closed_position = _pivot.position
	_enable_physics_sync(_pivot)
	_target_open = starts_open
	_open_amount = 1.0 if starts_open else 0.0
	_apply_open_amount(_open_amount)


func is_open() -> bool:
	return _target_open


func unlock() -> void:
	locked = false


func lock() -> void:
	locked = true


func can_interact(interactor: Node = null) -> bool:
	if not super.can_interact(interactor):
		return false
	if not locked:
		return true
	return _interactor_has_key(interactor)


func _on_interact(interactor: Node = null) -> void:
	if locked:
		locked = false
		if consume_key:
			_consume_key(interactor)
	_set_open(not _target_open)


func _on_interact_rejected(interactor: Node = null) -> void:
	if not locked or not interaction_enabled:
		return
	_play(locked_sound)
	locked_attempted.emit(interactor)


func _set_open(open: bool) -> void:
	if _target_open == open and is_equal_approx(_open_amount, 1.0 if open else 0.0):
		return
	_target_open = open
	_play(open_sound if open else close_sound)
	door_state_changed.emit(open)
	_animate(1.0 if open else 0.0)


func _animate(target_amount: float) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()

	var span := absf(target_amount - _open_amount)
	if span <= 0.001:
		_apply_open_amount(target_amount)
		return

	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_QUAD)
	_tween.set_ease(Tween.EASE_IN_OUT)
	_tween.tween_method(_apply_open_amount, _open_amount, target_amount, duration * span)


func _apply_open_amount(amount: float) -> void:
	_open_amount = clampf(amount, 0.0, 1.0)
	if motion == Motion.SLIDE:
		_pivot.position = _closed_position + slide_offset * _open_amount
		return

	var axis := hinge_axis
	if axis.length_squared() < 0.0001:
		axis = Vector3.UP
	var swing := Basis(axis.normalized(), deg_to_rad(open_angle_degrees) * _open_amount)
	_pivot.basis = swing * _closed_basis


func _play(stream: AudioStream) -> void:
	if stream == null or _audio == null:
		return
	_audio.stream = stream
	_audio.play()


func _interactor_has_key(interactor: Node) -> bool:
	if interactor == null or required_key == &"":
		return false
	if interactor.has_method(&"has_key"):
		return bool(interactor.call(&"has_key", required_key))
	if interactor.has_meta(&"keys"):
		var keys: Variant = interactor.get_meta(&"keys")
		return keys is Array and required_key in keys
	return false


func _consume_key(interactor: Node) -> void:
	if interactor == null or required_key == &"":
		return
	if interactor.has_method(&"consume_key"):
		interactor.call(&"consume_key", required_key)
		return
	if not interactor.has_meta(&"keys"):
		return
	var keys: Variant = interactor.get_meta(&"keys")
	if keys is Array:
		keys.erase(required_key)
		interactor.set_meta(&"keys", keys)


func _resolve_pivot() -> Node3D:
	if not pivot_path.is_empty():
		var pointed := get_node_or_null(pivot_path)
		if pointed is Node3D:
			return pointed
	var named := get_node_or_null(^"Pivot") as Node3D
	if named != null:
		return named
	return self


func _resolve_audio() -> AudioStreamPlayer3D:
	if not audio_player_path.is_empty():
		var pointed := get_node_or_null(audio_player_path)
		if pointed is AudioStreamPlayer3D:
			return pointed
	var existing := get_node_or_null(^"AudioStreamPlayer3D") as AudioStreamPlayer3D
	if existing != null:
		return existing
	var created := AudioStreamPlayer3D.new()
	created.name = "AudioStreamPlayer3D"
	add_child(created)
	return created


func _enable_physics_sync(node: Node) -> void:
	if node is AnimatableBody3D:
		(node as AnimatableBody3D).sync_to_physics = true
