class_name DoorKnob
extends RefCounted
## Blendkit "Spherical handle door" (Felipe de Melo). The rose sits on the
## origin and the knob sticks out along local +Z. Native width is the imported
## face size, so a caller can match an existing handle without stretching it.

const MODEL := preload("res://models/blendkit/spherical_handle.glb")
const NATIVE_WIDTH := 0.081127


static func attach(parent: Node3D, mount: Vector3, outward_negative_z: bool, diameter: float) -> Node3D:
	var knob := MODEL.instantiate() as Node3D
	knob.name = "DoorKnob"
	var fitted := diameter / NATIVE_WIDTH
	knob.scale = Vector3(fitted, fitted, fitted)
	knob.position = mount
	if outward_negative_z:
		knob.rotation.y = PI
	parent.add_child(knob)
	return knob
