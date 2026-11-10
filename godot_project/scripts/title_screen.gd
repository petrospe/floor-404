extends Control
## New Game starts on Floor 4. Continue returns to the last repaired panel's floor.


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.05, 0.05, 0.06)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var title := Label.new()
	title.text = "Floor 404"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(0.93, 0.9, 0.84))
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.offset_left = -240
	title.offset_right = 240
	title.offset_top = 150
	title.offset_bottom = 220
	add_child(title)
	var line := Label.new()
	line.text = "The Null Pointer"
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	line.add_theme_font_size_override("font_size", 18)
	line.add_theme_color_override("font_color", Color(0.7, 0.68, 0.62))
	line.set_anchors_preset(Control.PRESET_CENTER_TOP)
	line.offset_left = -240
	line.offset_right = 240
	line.offset_top = 214
	line.offset_bottom = 246
	add_child(line)
	_button("New Game", 300, _new_game)
	var continue_button := _button("Continue", 360, _continue)
	continue_button.disabled = not SaveManager.has_save()


func _button(text: String, top: float, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", 20)
	button.set_anchors_preset(Control.PRESET_CENTER_TOP)
	button.offset_left = -110
	button.offset_right = 110
	button.offset_top = top
	button.offset_bottom = top + 46
	button.pressed.connect(callback)
	add_child(button)
	return button


func _new_game() -> void:
	GameState.reset()
	SaveManager.erase()
	FloorTransition.arriving = false
	FloorTransition.pending_marker = ""
	get_tree().change_scene_to_file("res://scenes/office_level.tscn")


func _continue() -> void:
	if not SaveManager.load_save():
		return
	var floor_id := GameState.last_activation_floor
	if FloorRegistry.scene_path(floor_id) == "":
		floor_id = "F04"
	FloorTransition.go_to(floor_id, "ContinueSpawn")
