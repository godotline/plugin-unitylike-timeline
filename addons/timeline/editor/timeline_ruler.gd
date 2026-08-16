@tool
extends Control

## Unity-style frame ruler. The playhead handle lives here, while its line is
## continued through TimelinePlayhead in the track-content viewport.

signal seek_requested(time: float)
signal marker_selected(marker: TimelineMarker)
signal marker_moved(marker: TimelineMarker, time: float)
signal marker_add_requested(time: float)
signal marker_move_committed(marker: TimelineMarker, time: float, old_time: float)

const _FRAME_RATE: int = 60
const _PLAYHEAD_COLOR: Color = Color(1.0, 0.2, 0.2, 0.95)
const _MARKER_COLOR: Color = Color(1.0, 0.8, 0.2, 0.95)

var _time: float = 0.0
var _pps: float = 60.0
var _duration: float = 0.0
var _fps: int = 60
var _play_range_enabled: bool = false
var _play_range_start: float = 0.0
var _play_range_end: float = 0.0
var _dragging: bool = false
var _markers: Array[TimelineMarker] = []
var _dragging_marker: TimelineMarker = null
var _drag_marker_start_time: float = 0.0


func _init() -> void:
	custom_minimum_size = Vector2(0, 24)
	mouse_default_cursor_shape = Control.CURSOR_HSIZE


func set_pps(v: float) -> void:
	_pps = v
	queue_redraw()


func set_time(v: float) -> void:
	_time = v
	queue_redraw()


func set_duration(v: float) -> void:
	_duration = v
	queue_redraw()


func set_fps(v: int) -> void:
	_fps = maxi(1, v)
	queue_redraw()


func set_play_range(enabled: bool, start: float, end: float) -> void:
	_play_range_enabled = enabled
	_play_range_start = start
	_play_range_end = end
	queue_redraw()


func set_markers(markers: Array[TimelineMarker]) -> void:
	_markers = markers
	queue_redraw()


func _draw() -> void:
	draw_line(Vector2(0, size.y - 1.0), Vector2(size.x, size.y - 1.0), Color(1, 1, 1, 0.3), 1.0)
	if _play_range_enabled and _play_range_end > _play_range_start:
		var rx0: float = _play_range_start * _pps
		var rx1: float = _play_range_end * _pps
		draw_rect(Rect2(rx0, 0, rx1 - rx0, size.y), Color(0.4, 0.8, 1.0, 0.12))
		draw_line(Vector2(rx0, 0), Vector2(rx0, size.y), Color(0.4, 0.8, 1.0, 0.5), 1.0)
		draw_line(Vector2(rx1, 0), Vector2(rx1, size.y), Color(0.4, 0.8, 1.0, 0.5), 1.0)
	var end: float = maxf(_duration, size.x / _pps)
	var minor_frame_step: int = _get_minor_frame_step()
	var last_frame: int = int(ceilf(end * float(_fps)))
	for frame: int in range(0, last_frame + 1, minor_frame_step):
		var x: float = (float(frame) / float(_fps)) * _pps
		var is_second: bool = frame % _fps == 0
		var tick_height: float = 9.0 if is_second else 4.0
		var tick_color: Color = Color(1, 1, 1, 0.55 if is_second else 0.28)
		draw_line(Vector2(x, size.y - tick_height), Vector2(x, size.y), tick_color, 1.0)
		if is_second:
			var seconds: int = frame / _fps
			var minutes: int = seconds / 60
			draw_string(ThemeDB.fallback_font, Vector2(x + 3.0, 13.0), "%d:%02d" % [minutes, seconds % 60], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 1, 1, 0.82))
	var playhead_x: float = _time * _pps
	draw_line(Vector2(playhead_x, 0), Vector2(playhead_x, size.y), _PLAYHEAD_COLOR, 1.5)
	draw_colored_polygon(PackedVector2Array([
		Vector2(playhead_x - 6.0, 0),
		Vector2(playhead_x + 6.0, 0),
		Vector2(playhead_x, 8.0)
	]), _PLAYHEAD_COLOR)
	for marker: TimelineMarker in _markers:
		if marker == null:
			continue
		var marker_x: float = marker.time * _pps
		draw_colored_polygon(PackedVector2Array([
			Vector2(marker_x, size.y - 16.0),
			Vector2(marker_x + 6.0, size.y - 11.0),
			Vector2(marker_x, size.y - 6.0),
			Vector2(marker_x - 6.0, size.y - 11.0)
		]), _MARKER_COLOR)
		if not marker.marker_name.is_empty():
			draw_string(ThemeDB.fallback_font, Vector2(marker_x + 8.0, size.y - 8.0), marker.marker_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, _MARKER_COLOR)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				var marker: TimelineMarker = _marker_at(mb.position.x)
				if marker != null:
					_dragging_marker = marker
					_drag_marker_start_time = marker.time
					marker_selected.emit(marker)
				else:
					_dragging = true
					seek_requested.emit(_time_at_x(mb.position.x))
				if mb.double_click and marker == null:
					marker_add_requested.emit(_time_at_x(mb.position.x))
			else:
				_dragging = false
				if _dragging_marker != null:
					marker_move_committed.emit(_dragging_marker, _dragging_marker.time, _drag_marker_start_time)
				_dragging_marker = null
			accept_event()
	elif event is InputEventMouseMotion:
		var mm: InputEventMouseMotion = event as InputEventMouseMotion
		if _dragging_marker != null:
			marker_moved.emit(_dragging_marker, maxf(0.0, _time_at_x(mm.position.x)))
			accept_event()
		elif _dragging:
			seek_requested.emit(_time_at_x(mm.position.x))
			accept_event()


func _time_at_x(x: float) -> float:
	return maxf(0.0, x / _pps)


func _marker_at(x: float) -> TimelineMarker:
	for marker: TimelineMarker in _markers:
		if marker == null:
			continue
		if absf(marker.time * _pps - x) <= 8.0:
			return marker
	return null


func _get_minor_frame_step() -> int:
	if _pps >= 200.0:
		return 2
	if _pps >= 80.0:
		return 3
	if _pps >= 40.0:
		return 6
	if _pps >= 20.0:
		return 12
	return 30
