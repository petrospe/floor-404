class_name ElevatorPanel
extends StaticBody3D
## Wall plate inside the car. Sends the player to the other elevator.

var partner_marker: Node3D
var partner_doors: Node
var _busy := false


func interact(interactor: Node = null) -> void:
	if _busy or interactor is not Player or partner_marker == null:
		return
	_busy = true
	var player := interactor as Player
	var overlay := FadeOverlay.find_or_create(get_tree())
	if overlay != null:
		await overlay.fade_to(1.0, 0.28)
	if partner_doors != null and partner_doors.has_method(&"force_open"):
		partner_doors.call(&"force_open")
	player.travel_to(partner_marker.global_transform)
	if overlay != null:
		await overlay.fade_to(0.0, 0.4)
	_busy = false
