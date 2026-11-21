class_name Floor04Story
extends RefCounted
## Hand placements for the Floor 4 pilot. The office builder is not rearranged.
## Local +Z on every StoryReadable points at the place a person would stand to read it.

const DESK := Vector3(2.1, 0.0, 43.5)


static func install(level: Node3D) -> void:
	if level.get_node_or_null(^"StoryEntries") != null:
		return
	var host := Node3D.new()
	host.name = "StoryEntries"
	level.add_child(host)
	_workstation(level, host)
	_world(host)
	var prompt := StoryPrompt.new()
	prompt.name = "ReadPrompt"
	level.add_child(prompt)


static func _workstation(level: Node3D, host: Node3D) -> void:
	var cubicle := _find_cubicle(level)
	var parent: Node3D = cubicle if cubicle != null else host
	if cubicle == null:
		push_error("Floor 404 could not find the front cubicle for A. Ellis")
	# The nameplate faces the south approach. The terminal sits on the CRT glass, which faces the chair.
	var desk_crt := _nearest(level, Vector2(2.1, 43.96), "Large CRT Monitor")
	if desk_crt != null:
		_on_glass(desk_crt, "f04_ellis_terminal", "BUILD 2003.04\nFAILED", true)
	else:
		push_error("Floor 404 could not find A. Ellis's monitor")
		_readable(parent, "f04_ellis_terminal", "screen", "BUILD 2003.04\nFAILED", Vector3(0.42, 0.24, 0.016), Vector3(0.0, 1.16, 0.84), 0.0, true)
	_readable(parent, "f04_ellis_note", "sticky", "Back by 18:10.\nDon't wait on the review.\n— A. Ellis", Vector3(0.18, 0.14, 0.008), Vector3(0.5, 1.02, 0.98), 0.0, false)
	var plate := Label3D.new()
	plate.name = "EllisNameplate"
	plate.text = "A. ELLIS\nDESK 4-12"
	plate.position = Vector3(0.0, 1.28, -0.1)
	plate.rotation.y = PI
	plate.pixel_size = 0.0022
	plate.font_size = 42
	plate.modulate = Color(0.9, 0.88, 0.8)
	plate.outline_size = 6
	plate.outline_modulate = Color(0.05, 0.04, 0.03, 0.85)
	plate.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plate.scale = Vector3.ONE
	parent.add_child(plate)
	if parent == host:
		plate.position = DESK + Vector3(0.0, 1.28, -0.1)


static func _world(host: Node3D) -> void:
	# North edge of the south break-room counter. The reader stands in the room, looking south.
	_readable(host, "f04_break_coffee", "sheet", "Thursday\nEllis — in\nOkonkwo —\nPatel —", Vector3(0.2, 0.16, 0.008), Vector3(13.05, 1.02, 24.8), 0.0, false)
	# Center security CRT. Chairs sit to the north and face this glass.
	var security := _nearest(host.get_parent(), Vector2(-14.2, 64.4), "Large CRT Monitor")
	if security != null:
		_on_glass(security, "f04_security_badges", "BADGE LOG\n18:02  ALL OUT", true)
	else:
		push_error("Floor 404 could not find the security monitor")
		_readable(host, "f04_security_badges", "screen", "BADGE LOG\n18:02  ALL OUT", Vector3(0.36, 0.22, 0.016), Vector3(-14.2, 1.18, 64.7), 0.0, true)
	# West wall of the down-panel closet, clear of the cabinet on the east wall.
	_readable(host, "f04_down_panel_tag", "sheet", "Cabinet tagged for service.\nLeave the conductors as found.", Vector3(0.24, 0.16, 0.012), Vector3(-3.82, 1.48, 20.75), PI * 0.5, false)
	# West wall of the south stair, beside the flight, not on the red door.
	_readable(host, "f04_stair_wall", "wall", "The stairs only go back.", Vector3(1.7, 0.26, 0.02), Vector3(0.18, 1.62, 71.0), PI * 0.5, false)
	# Open floor of the up-panel room. The east wall is a shelf and the south wall is the cabinet.
	_readable(host, "f04_up_panel_sticky", "sticky", "Do not block\nthe cabinet.", Vector3(0.16, 0.12, 0.008), Vector3(26.0, 1.15, 90.0), 0.0, false)
	# Front face of the east server rack in the aisle at z ≈ 102. The face is the rack's local +Z.
	var rack := _nearest(host.get_parent(), Vector2(-18.563, 102.665), "Industrial Servers")
	if rack != null:
		_on_face(rack, "f04_server_log", "SESSIONS\n18:02:01\nCOUNT 0", Vector3(0.34, 0.2, 0.006), Vector3(0.0, 1.42, 0.362), 0.0, true)
	else:
		push_error("Floor 404 could not find the server rack display")
		_readable(host, "f04_server_log", "screen", "SESSIONS\n18:02:01\nCOUNT 0", Vector3(0.34, 0.24, 0.016), Vector3(-16.22, 1.42, 102.0), -PI * 0.5, true)
	# Just in front of the meeting-room glass board, which faces south.
	_readable(host, "f04_meeting_agenda", "wall", "status\nstaffing\n—", Vector3(0.7, 0.42, 0.02), Vector3(12.0, 1.6, 139.7), PI, false)
	# West wall of the north corridor at cell z = 28.
	_readable(host, "f04_north_watchers", "wall", "They are watching us.", Vector3(2.15, 0.26, 0.02), Vector3(0.18, 1.52, 114.0), PI * 0.5, false)


# The Blendkit CRT picture faces the model's +Z. The glass is x ±0.195, y 0.134–0.429.
# The plate covers that rectangle and the desktop emission is switched off, so the tube reads as black.
static func _on_glass(crt: Node3D, entry_id: String, text: String, hum: bool) -> void:
	_blank_tube(crt)
	_on_face(crt, entry_id, text, Vector3(0.40, 0.304, 0.004), Vector3(0.0, 0.281, 0.266), 0.0, hum)


static func _blank_tube(host: Node3D) -> void:
	var pending: Array[Node] = [host]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
			var mesh_node := node as MeshInstance3D
			for surface in mesh_node.mesh.get_surface_count():
				var source := mesh_node.get_active_material(surface)
				if source is StandardMaterial3D and (source as StandardMaterial3D).emission_enabled:
					var blank := (source as StandardMaterial3D).duplicate() as StandardMaterial3D
					blank.emission_enabled = false
					blank.emission_texture = null
					mesh_node.set_surface_override_material(surface, blank)
		for child in node.get_children():
			pending.append(child)


static func _on_face(host: Node3D, entry_id: String, text: String, plate: Vector3, at: Vector3, yaw: float, hum: bool) -> void:
	var node := StoryReadable.new()
	node.name = entry_id
	node.entry_id = entry_id
	node.kind = "screen"
	node.world_text = text
	node.plate_size = plate
	node.hum = hum
	node.position = at
	node.rotation.y = yaw
	node.scale = Vector3.ONE
	host.add_child(node)


static func _nearest(root: Node, world_xz: Vector2, name_prefix: String) -> Node3D:
	var best: Node3D = null
	var best_d := 0.45
	var pending: Array[Node] = [root]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		if node is Node3D and String(node.name).begins_with(name_prefix):
			var at := (node as Node3D).global_position
			var flat := Vector2(at.x, at.z).distance_to(world_xz)
			if flat < best_d:
				best_d = flat
				best = node as Node3D
		for child in node.get_children():
			pending.append(child)
	return best


static func _readable(parent: Node3D, entry_id: String, kind: String, glass: String, plate: Vector3, at: Vector3, yaw: float, hum: bool) -> void:
	var node := StoryReadable.new()
	node.name = entry_id
	node.entry_id = entry_id
	node.kind = kind
	node.world_text = glass
	node.plate_size = plate
	node.hum = hum
	node.position = at
	node.rotation.y = yaw
	node.scale = Vector3.ONE
	parent.add_child(node)


static func _find_cubicle(level: Node3D) -> Node3D:
	var geometry := level.get_node_or_null(^"Geometry")
	if geometry == null:
		return null
	for child in geometry.get_children():
		if child is Node3D and (child as Node3D).position.distance_to(DESK) < 0.05:
			return child as Node3D
	return null
