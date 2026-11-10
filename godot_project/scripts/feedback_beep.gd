class_name FeedbackBeep
extends RefCounted
## Short locked-handle tone. No imported audio file is required.

static var _stream: AudioStreamWAV


static func play(from: Node) -> void:
	if from == null or not from.is_inside_tree():
		return
	var host := AudioStreamPlayer.new()
	host.stream = _tone()
	from.add_child(host)
	host.finished.connect(host.queue_free)
	host.play()


static func _tone() -> AudioStreamWAV:
	if _stream != null:
		return _stream
	var mix := 22050
	var count := 1800
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	for i in count:
		var time := float(i) / float(mix)
		var amp := sin(time * TAU * 196.0) * exp(-time * 10.0)
		bytes.encode_s16(i * 2, int(clampf(amp, -1.0, 1.0) * 18000.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = mix
	stream.stereo = false
	stream.data = bytes
	_stream = stream
	return stream
