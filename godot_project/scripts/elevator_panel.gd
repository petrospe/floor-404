class_name ElevatorPanel
extends StaticBody3D

const BEEP := preload("res://scripts/feedback_beep.gd")
## Call plate inside the car.
## An empty elevator_id keeps the legacy same-floor ride. A set id travels only
## after that elevator's panel is repaired, and only to its registered floor.

var partner_marker: Node3D
var partner_doors: Node
var home_doors: Node
var elevator_id := ""
var lamp_material: StandardMaterial3D
var _busy := false
var _listening := false


func configure(id: String, material: StandardMaterial3D) -> void:
	elevator_id = id
	lamp_material = material
	_paint(GameState.is_elevator_active(elevator_id))
	if not _listening:
		_listening = true
		GameState.elevator_activated.connect(_on_elevator_activated)


func interact(interactor: Node = null) -> void:
	if elevator_id != "":
		await _travel(interactor)
		return
	await _legacy_ride(interactor)


func _travel(interactor: Node) -> void:
	if _busy or interactor is not Player:
		return
	if not GameState.is_elevator_active(elevator_id):
		_paint(false)
		BEEP.play(self)
		return
	var info := FloorRegistry.elevator(elevator_id)
	if info.is_empty() or FloorRegistry.scene_path(str(info["destination"])) == "":
		push_error("Floor 404 elevator %s has no destination scene" % elevator_id)
		BEEP.play(self)
		return
	_busy = true
	if home_doors != null and home_doors.has_method(&"close_doors"):
		home_doors.call(&"close_doors")
	await FloorTransition.go_to(str(info["destination"]), str(info["arrival"]))
	_busy = false


func _on_elevator_activated(id: String) -> void:
	if id == elevator_id:
		_paint(true)


func _paint(active: bool) -> void:
	if lamp_material == null:
		return
	lamp_material.emission_enabled = true
	if active:
		lamp_material.albedo_color = Color(0.15, 0.45, 0.28)
		lamp_material.emission = Color(0.2, 0.9, 0.4)
		lamp_material.emission_energy_multiplier = 1.8
	else:
		lamp_material.albedo_color = Color(0.35, 0.06, 0.05)
		lamp_material.emission = Color(0.85, 0.08, 0.05)
		lamp_material.emission_energy_multiplier = 1.4


func _legacy_ride(interactor: Node) -> void:
	if _busy or interactor is not Player or partner_marker == null:
		return
	_busy = true
	var player := interactor as Player
	var overlay := FadeOverlay.find_or_create(get_tree())
	if overlay != null:
		await overlay.fade_to(1.0, 0.28)
	if home_doors != null and home_doors.has_method(&"set_car_here"):
		home_doors.call(&"set_car_here", false)
	if partner_doors != null and partner_doors.has_method(&"set_car_here"):
		partner_doors.call(&"set_car_here", true)
	if partner_doors != null and partner_doors.has_method(&"force_open"):
		partner_doors.call(&"force_open")
	player.travel_to(partner_marker.global_transform)
	if overlay != null:
		await overlay.fade_to(0.0, 0.4)
	_busy = false
