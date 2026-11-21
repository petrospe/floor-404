class_name StoryReader
extends CanvasLayer
## Full text for one catalog entry. Esc closes it. The puzzle board is left alone.

static var _open := false


static func is_open() -> bool:
	return _open


static func open(entry_id: String) -> void:
	if _open or entry_id == "":
		return
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	for node in tree.root.get_children():
		if node is ElectricalPanelUI:
			return
	if not StoryCatalog.has_entry(entry_id):
		push_warning("Floor 404 unknown story entry %s" % entry_id)
		return
	var reader := StoryReader.new()
	reader._entry_id = entry_id
	reader.layer = 30
	tree.root.add_child(reader)


var _entry_id := ""
var _born := 0
var _released := false


func _ready() -> void:
	_open = true
	_born = Engine.get_process_frames()
	process_mode = Node.PROCESS_MODE_ALWAYS
	var info := StoryCatalog.entry(_entry_id)
	_suspend(true)
	_build(str(info.get("title", "Note")), str(info.get("body", "")))
	GameState.note_discovery(_entry_id)


func _exit_tree() -> void:
	if _open:
		_open = false
	_suspend(false)


func _input(event: InputEvent) -> void:
	if Engine.get_process_frames() == _born:
		return
	if event.is_action_pressed(&"ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_close()
		get_viewport().set_input_as_handled()


func _close() -> void:
	if not is_inside_tree():
		return
	_open = false
	_suspend(false)
	queue_free()


func _suspend(suspended: bool) -> void:
	if not suspended and _released:
		return
	if not suspended:
		_released = true
	var tree := get_tree()
	if tree == null:
		return
	var player := tree.get_first_node_in_group(&"player")
	if player != null and player.has_method(&"set_input_suspended"):
		player.call(&"set_input_suspended", suspended)


func _build(title: String, body: String) -> void:
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.018, 0.016, 0.72)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var sheet := Panel.new()
	sheet.set_anchors_preset(Control.PRESET_CENTER)
	sheet.offset_left = -360
	sheet.offset_right = 360
	sheet.offset_top = -240
	sheet.offset_bottom = 240
	sheet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.065, 0.06)
	style.border_color = Color(0.38, 0.34, 0.28)
	style.set_border_width_all(1)
	sheet.add_theme_stylebox_override(&"panel", style)
	add_child(sheet)

	var heading := Label.new()
	heading.text = title
	heading.position = Vector2(36, 28)
	heading.size = Vector2(648, 40)
	heading.add_theme_font_size_override(&"font_size", 26)
	heading.add_theme_color_override(&"font_color", Color(0.93, 0.9, 0.82))
	sheet.add_child(heading)

	var copy := RichTextLabel.new()
	copy.position = Vector2(36, 80)
	copy.size = Vector2(648, 320)
	copy.bbcode_enabled = false
	copy.text = body
	copy.scroll_active = true
	copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_theme_font_size_override(&"normal_font_size", 22)
	copy.add_theme_color_override(&"default_color", Color(0.86, 0.84, 0.76))
	sheet.add_child(copy)

	var hint := Label.new()
	hint.text = "ESC"
	hint.position = Vector2(600, 420)
	hint.size = Vector2(80, 28)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.add_theme_font_size_override(&"font_size", 14)
	hint.add_theme_color_override(&"font_color", Color(0.55, 0.52, 0.46))
	sheet.add_child(hint)
