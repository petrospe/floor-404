class_name ElectricalPanelUI
extends CanvasLayer

const BEEP := preload("res://scripts/feedback_beep.gd")
## Eight-wire cabinet interior. Correct seats stay. Closing early drops them all.
## The pairing is the existing per-panel shuffle. Nothing here is written to the save
## until every conductor is seated.

const SCENE_PATH := "res://scenes/ui/electrical_panel_ui.tscn"
const WIRE_COUNT := 8
const DESIGN := Vector2(1180, 740)
const WIRE_X := 268.0
const TERM_X := 930.0
const ROW_Y := 156.0
const ROW_GAP := 62.0
const WIRE_COLORS: Array[Color] = [
	Color(0.72, 0.18, 0.14),
	Color(0.16, 0.32, 0.68),
	Color(0.78, 0.64, 0.16),
	Color(0.18, 0.46, 0.28),
	Color(0.8, 0.4, 0.14),
	Color(0.74, 0.72, 0.66),
	Color(0.42, 0.26, 0.16),
	Color(0.32, 0.32, 0.34),
]

var _panel: Node
var _solution: Array[int] = []
var _matched: Array[int] = []
var _step := 0
var _readonly := false
var _finishing := false
var _released := false
var _selected := -1
var _dragging := false
var _press_point := Vector2.ZERO
var _drag_point := Vector2.ZERO
var _reject_terminal := -1
var _reject_time := 0.0

var _dim: ColorRect
var _host: Control
var _stage: Control
var _layer: WireConnectionLayer
var _wires: Array[WireConnector] = []
var _terms: Array[TerminalConnector] = []
var _led: PanelPowerLamp
var _status: Label
var _power: ColorRect

static var _relay: AudioStreamWAV


static func open(panel: Node) -> void:
	var tree := panel.get_tree()
	if tree == null:
		return
	var script := load("res://scripts/electrical_panel_ui.gd")
	for node in tree.root.get_children():
		if node.get_script() == script:
			return
	var ui: ElectricalPanelUI
	var packed := load(SCENE_PATH) as PackedScene
	if packed != null:
		ui = packed.instantiate() as ElectricalPanelUI
	if ui == null:
		ui = (script as GDScript).new() as ElectricalPanelUI
	ui.bind(panel)
	ui.layer = 20
	tree.root.add_child(ui)


func bind(panel: Node) -> void:
	_panel = panel


func _ready() -> void:
	if _panel == null:
		queue_free()
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	var panel_id := str(_panel.get("panel_id"))
	_solution = _solution_for(panel_id)
	_readonly = GameState.is_panel_complete(panel_id)
	if _readonly:
		for i in WIRE_COUNT:
			_matched.append(_solution[i])
		_step = WIRE_COUNT
	var player := get_tree().get_first_node_in_group(&"player")
	if player != null and player.has_method(&"set_input_suspended"):
		player.call(&"set_input_suspended", true)
	_build()
	_sync_all()
	call_deferred("_present")


func _exit_tree() -> void:
	_release_player()


func _process(delta: float) -> void:
	if _wires.is_empty():
		return
	if _reject_terminal >= 0:
		_reject_time -= delta
		if _reject_time <= 0.0:
			var index := _reject_terminal
			_reject_terminal = -1
			_reject_time = 0.0
			if index < _terms.size():
				_terms[index].set_reject(0.0)
		else:
			_terms[_reject_terminal].set_reject(_reject_time / 0.28)
	if _step < WIRE_COUNT and not _readonly and not _finishing:
		var pulse := 0.84 + 0.16 * sin(float(Time.get_ticks_msec()) * 0.007)
		_wires[_step].set_pulse(pulse)


func _input(event: InputEvent) -> void:
	if not _dragging:
		return
	if event is InputEventMouseMotion:
		_drag_point = _to_plate(event.position)
		_sync_drag()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var at := _to_plate(event.position)
		var moved := _press_point.distance_to(at) > 12.0
		_dragging = false
		if moved:
			var terminal := _terminal_at(at)
			if terminal >= 0:
				_try_socket(terminal)
		_sync_drag()
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		_close_incomplete()
		get_viewport().set_input_as_handled()
		return
	if _readonly or _finishing:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var key := event as InputEventKey
		if key.keycode >= KEY_1 and key.keycode <= KEY_8:
			_try_socket(key.keycode - KEY_1)
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


func _on_pressed(at: Vector2) -> void:
	if _readonly or _finishing or _step >= WIRE_COUNT:
		return
	var wire := _wire_at(at)
	if wire == _step:
		_selected = _step
		_dragging = true
		_press_point = at
		_drag_point = at
		_sync_drag()
		return
	if wire >= 0:
		_set_status("That conductor is dead.", "neutral")
		return
	var terminal := _terminal_at(at)
	if terminal >= 0:
		_try_socket(terminal)


func _try_socket(socket: int) -> void:
	_dragging = false
	if _readonly or _finishing or _step >= WIRE_COUNT or socket < 0 or socket >= WIRE_COUNT:
		_sync_drag()
		return
	if _matched.has(socket):
		_set_status("Terminal occupied.", "neutral")
		_sync_drag()
		return
	if socket != _solution[_step]:
		_reject(socket)
		_selected = _step
		return
	_matched.append(socket)
	_step += 1
	_selected = _step if _step < WIRE_COUNT else -1
	if _step < WIRE_COUNT:
		_set_status("Conductor seated.", "good")
		_sync_all()
		return
	_sync_all()
	_finish()


func _reject(socket: int) -> void:
	if _reject_terminal >= 0 and _reject_terminal < _terms.size():
		_terms[_reject_terminal].set_reject(0.0)
	_reject_terminal = socket
	_reject_time = 0.28
	_set_status("No continuity.", "bad")
	BEEP.play(self)
	_sync_all()


func _finish() -> void:
	if _finishing:
		return
	_finishing = true
	_dragging = false
	_play_relay()
	_pulse_power()
	if _panel != null:
		GameState.complete_panel(str(_panel.get("panel_id")))
		if _panel.has_method(&"mark_repaired"):
			_panel.call(&"mark_repaired")
	_set_status("Power restored.", "good")
	var flicker := create_tween()
	flicker.tween_callback(func() -> void: _led.set_lit(false))
	flicker.tween_interval(0.06)
	flicker.tween_callback(func() -> void: _led.set_lit(true))
	flicker.tween_interval(0.08)
	flicker.tween_callback(func() -> void: _led.set_lit(false))
	flicker.tween_interval(0.05)
	flicker.tween_callback(func() -> void: _led.set_lit(true))
	var hold := create_tween()
	hold.tween_interval(1.05)
	hold.tween_callback(_dismiss)


func _pulse_power() -> void:
	if _power == null:
		return
	var tween := create_tween()
	tween.tween_property(_power, "color:a", 0.26, 0.05)
	tween.tween_property(_power, "color:a", 0.02, 0.07)
	tween.tween_property(_power, "color:a", 0.2, 0.05)
	tween.tween_property(_power, "color:a", 0.0, 0.4)


func _play_relay() -> void:
	var host := AudioStreamPlayer.new()
	host.stream = _relay_stream()
	host.volume_db = -4.0
	add_child(host)
	host.finished.connect(host.queue_free)
	host.play()


func _close_incomplete() -> void:
	# An unfinished board lives only in this node. Freeing it drops every seat.
	# A finished board is already stored on GameState, so closing only hides it.
	_dismiss()


func _dismiss() -> void:
	if not is_inside_tree():
		return
	_release_player()
	queue_free()


func _release_player() -> void:
	if _released:
		return
	_released = true
	var tree := get_tree()
	if tree == null:
		return
	var player := tree.get_first_node_in_group(&"player")
	if player != null and player.has_method(&"set_input_suspended"):
		player.call(&"set_input_suspended", false)


func _present() -> void:
	if not is_inside_tree():
		return
	_fit()
	if _host.size.x < 8.0:
		await get_tree().process_frame
		if not is_inside_tree():
			return
		_fit()
	_play_open()


func _play_open() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_dim, "color:a", 0.64, 0.18)
	tween.tween_property(_stage, "modulate:a", 1.0, 0.2)


func _build() -> void:
	_dim = ColorRect.new()
	_dim.name = "Dim"
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.color = Color(0.01, 0.012, 0.014, 0.0)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_dim)

	_host = Control.new()
	_host.name = "Host"
	_host.set_anchors_preset(Control.PRESET_FULL_RECT)
	_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_host)
	_host.resized.connect(_fit)

	_stage = Control.new()
	_stage.name = "Stage"
	_stage.size = DESIGN
	_stage.custom_minimum_size = DESIGN
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.clip_contents = true
	_stage.modulate = Color(1, 1, 1, 0)
	_host.add_child(_stage)

	var plate := CabinetPlate.new()
	plate.name = "Plate"
	plate.size = DESIGN
	_stage.add_child(plate)

	_layer = WireConnectionLayer.new()
	_layer.name = "Cables"
	_layer.size = DESIGN
	_layer.pressed.connect(_on_pressed)
	_stage.add_child(_layer)

	for i in WIRE_COUNT:
		var wire := WireConnector.new()
		wire.name = "Wire%d" % (i + 1)
		wire.wire_color = WIRE_COLORS[i]
		wire.position = _wire_anchor(i) - WireConnector.LUG
		_stage.add_child(wire)
		_wires.append(wire)
		var terminal := TerminalConnector.new()
		terminal.name = "Terminal%d" % (i + 1)
		terminal.number = i + 1
		terminal.position = _terminal_anchor(i) - TerminalConnector.SCREW
		_stage.add_child(terminal)
		_terms.append(terminal)

	_power = ColorRect.new()
	_power.name = "PowerFlash"
	_power.color = Color(0.9, 0.95, 0.86, 0.0)
	_power.size = DESIGN
	_power.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(_power)

	_status = Label.new()
	_status.name = "Status"
	_status.position = Vector2(48, 692)
	_status.size = Vector2(820, 28)
	_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status.add_theme_font_size_override("font_size", 16)
	_stage.add_child(_status)

	var hint := Label.new()
	hint.name = "CloseHint"
	hint.text = "ESC"
	hint.position = Vector2(DESIGN.x - 88, 692)
	hint.size = Vector2(48, 28)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.5, 0.49, 0.45))
	_stage.add_child(hint)

	var power_label := Label.new()
	power_label.name = "PowerLabel"
	power_label.text = "PWR"
	power_label.position = Vector2(1028, 36)
	power_label.size = Vector2(64, 24)
	power_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	power_label.add_theme_font_size_override("font_size", 13)
	power_label.add_theme_color_override("font_color", Color(0.55, 0.54, 0.5))
	_stage.add_child(power_label)

	_led = PanelPowerLamp.new()
	_led.name = "PowerLamp"
	_led.position = Vector2(1096, 32)
	_stage.add_child(_led)

	if _readonly:
		_set_status("Circuit closed.", "good")
	else:
		_set_status("Seat the live conductor.", "neutral")


func _fit() -> void:
	if _host == null or _stage == null:
		return
	var view := _host.size
	if view.x < 8.0 or view.y < 8.0:
		return
	# One positive scale keeps every lug, screw, and label on the same grid.
	var fitted := minf(view.x / DESIGN.x, view.y / DESIGN.y) * 0.94
	fitted = maxf(fitted, 0.01)
	_stage.scale = Vector2(fitted, fitted)
	_stage.position = (view - DESIGN * fitted) * 0.5


func _wire_anchor(index: int) -> Vector2:
	return Vector2(WIRE_X, ROW_Y + float(index) * ROW_GAP)


func _terminal_anchor(index: int) -> Vector2:
	return Vector2(TERM_X, ROW_Y + float(index) * ROW_GAP)


func _wire_at(point: Vector2) -> int:
	for i in WIRE_COUNT:
		if point.distance_to(_wire_anchor(i)) <= 22.0:
			return i
	return -1


func _terminal_at(point: Vector2) -> int:
	for i in WIRE_COUNT:
		var origin := _terminal_anchor(i) - TerminalConnector.SCREW
		if Rect2(origin, TerminalConnector.BODY).grow(6.0).has_point(point):
			return i
	return -1


func _to_plate(screen_position: Vector2) -> Vector2:
	return _layer.get_global_transform_with_canvas().affine_inverse() * screen_position


func _sync_all() -> void:
	var seated: Array[Dictionary] = []
	for i in _matched.size():
		seated.append({
			"from": _wire_plug(i),
			"to": _terminal_plug(_matched[i]),
			"color": WIRE_COLORS[i],
		})
	_layer.set_cables(seated)
	_sync_drag()
	for i in WIRE_COUNT:
		var phase := 0
		if i < _step:
			phase = 2
		elif i == _step and not _readonly and not _finishing:
			phase = 1
		_wires[i].set_phase(phase)
		_terms[i].set_occupied(_matched.has(i))
		if i == _reject_terminal:
			_terms[i].set_reject(1.0)
	if _readonly:
		_led.set_lit(true)
	elif not _finishing:
		_led.set_lit(false)


func _sync_drag() -> void:
	if _dragging and _step < WIRE_COUNT:
		_layer.set_drag(true, _wire_plug(_step), _drag_end(), WIRE_COLORS[_step])
	else:
		_layer.set_drag(false, Vector2.ZERO, Vector2.ZERO, Color.WHITE)


func _drag_end() -> Vector2:
	var terminal := _terminal_at(_drag_point)
	if terminal >= 0 and not _matched.has(terminal):
		return _terminal_plug(terminal)
	return _drag_point


func _wire_plug(index: int) -> Vector2:
	return _wire_anchor(index) + Vector2(8.0, 0.0)


func _terminal_plug(index: int) -> Vector2:
	return _terminal_anchor(index) - Vector2(TerminalConnector.SCREW.x, 0.0)


func _set_status(text: String, tone: String) -> void:
	if _status == null:
		return
	_status.text = text
	var color := Color(0.58, 0.56, 0.5)
	if tone == "bad":
		color = Color(0.72, 0.45, 0.32)
	elif tone == "good":
		color = Color(0.55, 0.68, 0.52)
	_status.add_theme_color_override("font_color", color)


static func _relay_stream() -> AudioStreamWAV:
	if _relay != null:
		return _relay
	var mix := 22050
	var count := 5000
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 404
	for i in count:
		var time := float(i) / float(mix)
		var burst := 0.0
		var local := -1.0
		if time < 0.035:
			local = time
		elif time > 0.07 and time < 0.115:
			local = time - 0.07
		if local >= 0.0:
			burst = sin(local * TAU * 160.0) * exp(-local * 55.0)
			burst += sin(local * TAU * 1900.0) * exp(-local * 80.0) * 0.4
			burst += (rng.randf() * 2.0 - 1.0) * exp(-local * 50.0) * 0.22
		bytes.encode_s16(i * 2, int(clampf(burst, -1.0, 1.0) * 16000.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = mix
	stream.stereo = false
	stream.data = bytes
	_relay = stream
	return stream
