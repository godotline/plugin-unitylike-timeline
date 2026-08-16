@tool
extends Control

## A single timeline track row: hosts TimelineClipView instances for one track.
## The track label column is managed separately by the dock (fixed width) so the
## clip area starts exactly at the timeline's 0 mark.

signal clip_selected(clip: TimelineClip, track: TimelineTrack)
signal track_selected(track: TimelineTrack)
signal selection_changed(clips: Array[TimelineClip], track: TimelineTrack)
signal clip_move_requested(clip: TimelineClip, new_start: float)
signal clip_resize_requested(clip: TimelineClip, new_start: float, new_duration: float)
signal multi_move_requested(clips: Array[TimelineClip], delta_start: float)
signal multi_resize_requested(clips: Array[TimelineClip], anchor_start: float, new_start: float, new_duration: float)
signal clip_action_requested(action: StringName, clip: TimelineClip, track: TimelineTrack)

const ClipViewClass := preload("res://addons/timeline/editor/timeline_clip_view.gd")

var _track: TimelineTrack = null
var _pps: float = 60.0
var _snap: bool = true
var _clip_area: Control = null
var _clip_width: float = 1200.0
var _row_height: float = 40.0
var _locked: bool = false
var _selected_clips: Array[TimelineClip] = []
var _last_selected: TimelineClip = null


func setup(track: TimelineTrack, pps: float) -> void:
	_track = track
	_pps = pps
	_build_ui()
	refresh()


func _build_ui() -> void:
	custom_minimum_size = Vector2(0, _row_height)
	_clip_area = Control.new()
	_clip_area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_clip_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_clip_area.custom_minimum_size = Vector2(_clip_width, _row_height)
	_clip_area.gui_input.connect(_on_clip_area_input)
	add_child(_clip_area)


func _on_clip_area_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed and mb.position.y >= 0.0:
			_clear_selection()


func set_clip_width(width: float) -> void:
	_clip_width = maxf(1200.0, width)
	custom_minimum_size = Vector2(_clip_width, _row_height)
	if _clip_area != null:
		_clip_area.custom_minimum_size = Vector2(_clip_width, _row_height)


func set_row_height(height: float) -> void:
	_row_height = maxf(40.0, height)
	custom_minimum_size = Vector2(_clip_width, _row_height)
	if _clip_area == null:
		return
	_clip_area.custom_minimum_size = Vector2(_clip_width, _row_height)
	for child: Node in _clip_area.get_children():
		if child is Control:
			(child as Control).size.y = maxf(4.0, _row_height - 4.0)


func refresh() -> void:
	if _clip_area == null:
		return
	for child: Node in _clip_area.get_children():
		child.queue_free()
	if _track == null:
		return
	for clip: TimelineClip in _track.clips:
		var view: Control = ClipViewClass.new()
		view.call("setup", clip, _track, _pps)
		view.call("set_snap", _snap)
		view.call("set_locked", _locked)
		view.call("set_selected", _selected_clips.has(clip))
		view.connect("selected", Callable(self, "_on_view_selected").bind(_track))
		view.connect("move_requested", Callable(self, "_on_view_move"))
		view.connect("resize_requested", Callable(self, "_on_view_resize"))
		view.connect("action_requested", Callable(self, "_on_view_action").bind(_track))
		_clip_area.add_child(view)
		view.position = Vector2(clip.start * _pps, 0)
		view.size = Vector2(maxf(4.0, clip.duration * _pps), maxf(4.0, _row_height - 4.0))


func set_pps(v: float) -> void:
	_pps = v
	refresh()


func set_snap(v: bool) -> void:
	_snap = v


func set_locked(v: bool) -> void:
	_locked = v


func get_selected_clips() -> Array[TimelineClip]:
	return _selected_clips.duplicate()


func set_selected_clips(clips: Array[TimelineClip]) -> void:
	_selected_clips.clear()
	for clip: TimelineClip in clips:
		if clip != null and not _selected_clips.has(clip):
			_selected_clips.append(clip)
	_last_selected = _selected_clips.back() if not _selected_clips.is_empty() else null
	_refresh_selection_state()


func _clear_selection() -> void:
	_selected_clips.clear()
	_last_selected = null
	_refresh_selection_state()
	selection_changed.emit(_selected_clips.duplicate(), _track)


func _refresh_selection_state() -> void:
	if _clip_area == null:
		return
	for child: Node in _clip_area.get_children():
		if child.has_method("set_selected"):
			child.call("set_selected", _selected_clips.has((child as Control).get("_clip")))


func _on_view_selected(clip: TimelineClip, add_to_selection: bool, range_select: bool, track: TimelineTrack) -> void:
	if add_to_selection:
		if _selected_clips.has(clip):
			_selected_clips.erase(clip)
		else:
			_selected_clips.append(clip)
		_last_selected = clip
	elif range_select and _last_selected != null:
		_selected_clips.clear()
		var anchor: TimelineClip = _last_selected
		var order: Array[TimelineClip] = []
		for candidate: TimelineClip in track.clips:
			if candidate != null:
				order.append(candidate)
		order.sort_custom(func(a: TimelineClip, b: TimelineClip) -> bool: return a.start < b.start)
		var i0: int = order.find(anchor)
		var i1: int = order.find(clip)
		if i0 >= 0 and i1 >= 0:
			var lo: int = mini(i0, i1)
			var hi: int = maxi(i0, i1)
			for index: int in range(lo, hi + 1):
				_selected_clips.append(order[index])
		else:
			_selected_clips.append(clip)
		_last_selected = clip
	else:
		_selected_clips.clear()
		_selected_clips.append(clip)
		_last_selected = clip
	_refresh_selection_state()
	clip_selected.emit(clip, track)
	track_selected.emit(track)
	selection_changed.emit(_selected_clips.duplicate(), track)


func _on_view_move(clip: TimelineClip, new_start: float) -> void:
	if _selected_clips.size() > 1 and _selected_clips.has(clip):
		var delta: float = new_start - clip.start
		multi_move_requested.emit(_selected_clips.duplicate(), delta)
	else:
		clip_move_requested.emit(clip, new_start)


func _on_view_resize(clip: TimelineClip, new_start: float, new_duration: float) -> void:
	clip_resize_requested.emit(clip, new_start, new_duration)


func _on_view_action(action: StringName, clip: TimelineClip, track: TimelineTrack) -> void:
	clip_action_requested.emit(action, clip, track)
