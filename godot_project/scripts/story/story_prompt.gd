class_name StoryPrompt
extends CanvasLayer
## Shows only while the interaction ray is on a readable.

func _ready() -> void:
	layer = 15
	var label := Label.new()
	label.name = "Caption"
	label.text = "E — Read"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	label.offset_left = -120
	label.offset_right = 120
	label.offset_top = -96
	label.offset_bottom = -52
	label.add_theme_font_size_override(&"font_size", 20)
	label.add_theme_color_override(&"font_color", Color(0.94, 0.92, 0.86))
	label.add_theme_color_override(&"font_shadow_color", Color(0, 0, 0, 0.65))
	label.add_theme_constant_override(&"shadow_offset_x", 1)
	label.add_theme_constant_override(&"shadow_offset_y", 1)
	add_child(label)
	visible = false


func _process(_delta: float) -> void:
	visible = _looking_at_readable()


func _looking_at_readable() -> bool:
	if StoryReader.is_open():
		return false
	var player := get_tree().get_first_node_in_group(&"player")
	if player == null:
		return false
	if player.has_method(&"is_input_suspended") and bool(player.call(&"is_input_suspended")):
		return false
	var camera := player.get_node_or_null(^"Camera3D") as Camera3D
	if camera == null:
		return false
	var ray := camera.get_node_or_null(^"InteractionRay") as RayCast3D
	if ray == null:
		return false
	ray.force_raycast_update()
	if not ray.is_colliding():
		return false
	var current := ray.get_collider() as Node
	while current != null:
		if current.is_in_group(&"story_readable"):
			return true
		current = current.get_parent()
	return false
