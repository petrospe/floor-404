class_name LockedExit
extends StaticBody3D

const BEEP := preload("res://scripts/feedback_beep.gd")
## Red EXIT that never opens. The handle only answers with a click.


func _ready() -> void:
	var paint := StandardMaterial3D.new()
	paint.albedo_color = Color(0.55, 0.08, 0.06)
	paint.roughness = 0.55
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.15, 2.15, 0.08)
	mesh.mesh = box
	mesh.position = Vector3(0.0, 1.15, 0.0)
	mesh.material_override = paint
	add_child(mesh)
	var sign := Label3D.new()
	sign.text = "EXIT"
	sign.position = Vector3(0.0, 1.55, -0.05)
	sign.pixel_size = 0.004
	sign.font_size = 72
	sign.modulate = Color(1.0, 0.86, 0.82)
	sign.outline_size = 0
	add_child(sign)
	var shape := CollisionShape3D.new()
	var body := BoxShape3D.new()
	body.size = Vector3(1.2, 2.2, 0.12)
	shape.shape = body
	shape.position = Vector3(0.0, 1.1, 0.0)
	add_child(shape)


func interact(_interactor: Node = null) -> void:
	BEEP.play(self)
