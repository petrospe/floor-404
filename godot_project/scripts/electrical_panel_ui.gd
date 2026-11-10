class_name ElectricalPanelUI
extends CanvasLayer

const BEEP := preload("res://scripts/feedback_beep.gd")
## Focused eight-wire puzzle. Closing it before the end discards every match.

const WIRE_COUNT := 8

var _panel: Node
var _solution: Array[int] = []
var _matched: Array[int] = []
var _step := 0
var _socket_buttons: Array[Button] = []
var _wire_labels: Array[Label] = []
var _status: Label


static func open(panel: Node) -> void:
	var tree := panel.get_tree()
	if tree == null:
		return
	var script := load("res://scripts/electrical_panel_ui.gd")
	for node in tree.root.get_children():
		if node.get_script() == script:
			return
	var ui := script.new() as CanvasLayer
	ui.set("_panel", panel)
	ui.layer = 20
	tree.root.add_child(ui)


func _ready() -> void:
	_solution = _solution_for(str(_panel.get("panel_id")))
	process_mode = Node.PROCESS_MODE_ALWAYS
	var player := get_tree().get_first_node_in_group(&"player")
	if player != null and player.has_method(&"set_input_suspended"):
		player.call(&"set_input_suspended", true)
	_build()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		_close_incomplete()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var key := event as InputEventKey
		var socket := -1
		if key.keycode >= KEY_1 and key.keycode <= KEY_8:
			socket = key.keycode - KEY_1
		if socket >= 0:
			_try_socket(socket)
			get_viewport().set_input_as_handled()


func _solution_for(panel_id: String) -> Array[int]:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(panel_id)
	var order: Array[int] = []
	for i in WIRE_COUNT:
		order.append(i)
	for i in range(WIRE_COUNT - 1, 0, -1):
		var swap := rng.randi_range(0, i)
		var hold: int = order[i]
		order[i] = order[swap]
		order[swap] = hold
	return order


func _try_socket(socket: int) -> void:
	if _step >= WIRE_COUNT or _matched.has(socket):
		return
	if socket != _solution[_step]:
		_status.text = "That socket does not match this wire."
		BEEP.play(self)
		return
	_matched.append(socket)
	_step += 1
	_paint()
	if _step < WIRE_COUNT:
		_status.text = "Wire %d is next." % (_step + 1)
		return
	_status.text = "Panel repaired."
	if _panel != null:
		GameState.complete_panel(str(_panel.get("panel_id")))
		_panel.call("mark_repaired")
	_release_player()
	queue_free()


func _close_incomplete() -> void:
	_release_player()
	queue_free()


func _release_player() -> void:
	var player := get_tree().get_first_node_in_group(&"player")
	if player != null and player.has_method(&"set_input_suspended"):
		player.call(&"set_input_suspended", false)


func _paint() -> void:
	for i in WIRE_COUNT:
		var wire: Label = _wire_labels[i]
		if i < _step:
			wire.text = "Wire %d  connected" % (i + 1)
			wire.modulate = Color(0.65, 0.9, 0.7)
		elif i == _step:
			wire.text = "Wire %d  active" % (i + 1)
			wire.modulate = Color(1.0, 0.82, 0.45)
		else:
			wire.text = "Wire %d" % (i + 1)
			wire.modulate = Color(0.75, 0.75, 0.72)
		var button: Button = _socket_buttons[i]
		button.disabled = _matched.has(i)
		if _matched.has(i):
			button.text = "Socket %d  used" % (i + 1)
		else:
			button.text = "Socket %d" % (i + 1)


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var root := PanelContainer.new()
	root.set_anchors_preset(Control.PRESET_CENTER)
	root.offset_left = -360
	root.offset_top = -280
	root.offset_right = 360
	root.offset_bottom = 280
	add_child(root)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	root.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	var title := Label.new()
	title.text = "Electrical panel"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 22)
	header.add_child(title)
	var close := Button.new()
	close.text = "Close"
	close.pressed.connect(_close_incomplete)
	header.add_child(close)
	_status = Label.new()
	_status.text = "Connect the active wire. Closing the panel starts it over."
	column.add_child(_status)
	var rows := HBoxContainer.new()
	rows.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", 28)
	column.add_child(rows)
	var wires := VBoxContainer.new()
	wires.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wires.add_theme_constant_override("separation", 6)
	rows.add_child(wires)
	var sockets := VBoxContainer.new()
	sockets.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sockets.add_theme_constant_override("separation", 6)
	rows.add_child(sockets)
	for i in WIRE_COUNT:
		var wire := Label.new()
		wire.add_theme_font_size_override("font_size", 18)
		wires.add_child(wire)
		_wire_labels.append(wire)
		var button := Button.new()
		button.add_theme_font_size_override("font_size", 18)
		var socket := i
		button.pressed.connect(func() -> void: _try_socket(socket))
		sockets.add_child(button)
		_socket_buttons.append(button)
	_paint()
