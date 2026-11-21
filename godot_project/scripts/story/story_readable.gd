class_name StoryReadable
extends StaticBody3D
## One terminal, paper, or wall line. Local +Z is the face the player reads.
## Scale stays positive so Label3D is not mirrored.

@export var entry_id: String = ""
@export var kind: String = "sheet"
@export var world_text: String = ""
@export var plate_size: Vector3 = Vector3.ZERO
@export var hum: bool = false

var _plate: Vector3 = Vector3.ZERO


func _ready() -> void:
	add_to_group(&"story_readable")
	if name == "StaticBody3D":
		name = entry_id if entry_id != "" else "StoryReadable"
	_plate = plate_size if plate_size != Vector3.ZERO else _default_plate()
	_build_plate()
	_build_label()
	if hum:
		_build_hum()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(_plate.x, _plate.y, maxf(_plate.z, 0.03))
	shape.shape = box
	add_child(shape)


func interact(_interactor: Node = null) -> void:
	StoryReader.open(entry_id)


func _default_plate() -> Vector3:
	match kind:
		"screen":
			return Vector3(0.42, 0.26, 0.016)
		"sticky":
			return Vector3(0.16, 0.12, 0.008)
		"wall":
			return Vector3(1.4, 0.28, 0.02)
		_:
			return Vector3(0.22, 0.18, 0.008)


func _build_plate() -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = _plate
	mesh.mesh = box
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh.material_override = _plate_material()
	add_child(mesh)


func _plate_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.roughness = 0.82
	match kind:
		"screen":
			# Flat black glass. The phosphor text is the only thing on the tube.
			material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			material.albedo_color = Color(0.012, 0.014, 0.013)
		"sticky":
			material.albedo_color = Color(0.93, 0.84, 0.46)
		"wall":
			material.albedo_color = Color(0.8, 0.77, 0.7)
		_:
			material.albedo_color = Color(0.9, 0.88, 0.8)
	return material


func _build_label() -> void:
	var label := Label3D.new()
	label.name = "FaceText"
	label.text = world_text if world_text != "" else str(StoryCatalog.entry(entry_id).get("body", ""))
	label.font_size = 42 if kind == "screen" or kind == "wall" else 28
	var pixel := _pixel_size()
	if kind == "sheet" or kind == "sticky" or kind == "screen":
		pixel = _fit_block(label.text, label.font_size, pixel)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.pixel_size = pixel
	label.position = Vector3(0.0, 0.0, _plate.z * 0.5 + 0.001)
	# width is in pixels. Keep a margin so glyphs stay off the paper edge.
	label.width = _plate.x * 0.84 / pixel
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.outline_size = 0
	label.modulate = _ink()
	# The readable face of Label3D is +Z, the same axis as this body.
	label.rotation = Vector3.ZERO
	label.scale = Vector3.ONE
	add_child(label)


func _fit_block(text: String, font_size: int, pixel: float) -> float:
	var font := ThemeDB.fallback_font
	var inner_x := _plate.x * 0.84
	var inner_y := _plate.y * 0.78
	for _step in 8:
		var measured := font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, inner_x / pixel, font_size)
		if measured.x * pixel <= inner_x * 1.02 and measured.y * pixel <= inner_y:
			return pixel
		pixel *= 0.88
	return pixel


func _pixel_size() -> float:
	match kind:
		"screen":
			return 0.00115
		"wall":
			return 0.0031
		"sticky":
			return 0.00072
		_:
			return 0.00062


func _ink() -> Color:
	if kind == "screen":
		return Color(0.62, 0.93, 0.7)
	return Color(0.14, 0.11, 0.08)


func _build_hum() -> void:
	var player := AudioStreamPlayer3D.new()
	player.stream = _hum_stream()
	player.volume_db = -28.0
	player.max_distance = 2.6
	player.unit_size = 1.4
	player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	player.autoplay = true
	add_child(player)


static var _hum: AudioStreamWAV


static func _hum_stream() -> AudioStreamWAV:
	if _hum != null:
		return _hum
	var mix := 22050
	var count := mix
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2003
	for i in count:
		var time := float(i) / float(mix)
		var tone := sin(time * TAU * 90.0) * 0.22
		tone += sin(time * TAU * 180.0) * 0.06
		tone += (rng.randf() * 2.0 - 1.0) * 0.025
		bytes.encode_s16(i * 2, int(clampf(tone, -1.0, 1.0) * 8000.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = mix
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = count
	stream.data = bytes
	_hum = stream
	return stream
