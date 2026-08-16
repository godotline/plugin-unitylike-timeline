@tool
extends EditorInspectorPlugin

## Adds action buttons to the inspector for Timeline resources:
## "添加 Clip" on a TimelineTrack (uses the track's own clip class) and
## "新建轨道" on a TimelineAsset.

const TimelineAssetClass := preload("res://addons/timeline/core/timeline_asset.gd")
const TimelineTrackClass := preload("res://addons/timeline/core/timeline_track.gd")
const TimelineClipClass := preload("res://addons/timeline/core/timeline_clip.gd")
const TimelineMarkerClass := preload("res://addons/timeline/core/timeline_marker.gd")
const TimelineSignalEmitterClass := preload("res://addons/timeline/core/timeline_signal_emitter.gd")
const TimelineSignalAssetClass := preload("res://addons/timeline/core/timeline_signal_asset.gd")


func _can_handle(obj: Object) -> bool:
	return obj is TimelineAsset or obj is TimelineTrack or obj is TimelineClip


func _parse_begin(obj: Object) -> void:
	if obj is TimelineTrack:
		var b: Button = Button.new()
		b.text = "添加 Clip"
		b.pressed.connect(_on_add_clip.bind(obj))
		add_custom_control(b)
	elif obj is TimelineAsset:
		var b2: Button = Button.new()
		b2.text = "新建轨道"
		b2.pressed.connect(_on_new_track.bind(obj))
		add_custom_control(b2)
		var b3: Button = Button.new()
		b3.text = "添加 Marker"
		b3.pressed.connect(_on_add_marker.bind(obj))
		add_custom_control(b3)
		var b4: Button = Button.new()
		b4.text = "添加 Signal Emitter"
		b4.pressed.connect(_on_add_signal_emitter.bind(obj))
		add_custom_control(b4)


func _on_add_clip(track: TimelineTrack) -> void:
	var clip: TimelineClip = track.get_clip_class().new()
	var old: Array = track.clips.duplicate()
	track.clips.append(clip)
	_undo_prop_array(track, "clips", track.clips, old, "添加 Clip")


func _on_new_track(asset: TimelineAsset) -> void:
	var track: TimelineTrack = TimelineTrackClass.new()
	var old: Array = asset.tracks.duplicate()
	asset.tracks.append(track)
	_undo_prop_array(asset, "tracks", asset.tracks, old, "新建轨道")


func _on_add_marker(asset: TimelineAsset) -> void:
	var marker: TimelineMarker = TimelineMarkerClass.new()
	marker.marker_name = "Marker %d" % (asset.markers.size() + 1)
	var old: Array = asset.markers.duplicate()
	asset.markers.append(marker)
	_undo_prop_array(asset, "markers", asset.markers, old, "添加 Marker")


func _on_add_signal_emitter(asset: TimelineAsset) -> void:
	var emitter: TimelineSignalEmitter = TimelineSignalEmitterClass.new()
	var signal_asset: TimelineSignalAsset = TimelineSignalAssetClass.new()
	signal_asset.signal_name = StringName("Signal %d" % (asset.markers.size() + 1))
	emitter.signal_asset = signal_asset
	emitter.marker_name = signal_asset.get_display_name()
	var old: Array = asset.markers.duplicate()
	asset.markers.append(emitter)
	_undo_prop_array(asset, "markers", asset.markers, old, "添加 Signal Emitter")


func _undo_prop_array(obj: Object, prop: StringName, new_val: Variant, old_val: Variant, action_name: String) -> void:
	var ur: EditorUndoRedoManager = EditorInterface.get_editor_undo_redo()
	ur.create_action(action_name)
	ur.add_do_property(obj, prop, new_val)
	ur.add_undo_property(obj, prop, old_val)
	ur.commit_action()
	obj.notify_property_list_changed()
