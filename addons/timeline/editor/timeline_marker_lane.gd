@tool
class_name TimelineMarkerLane
extends Control

## Marker lane rendered above the clip rows. Draws Unity-style diamonds for
## every TimelineMarker in the asset, supports click/drag selection and a
## right-click menu for adding/renaming/duplicating/deleting markers.

signal marker_selected(marker: TimelineMarker)
signal marker_move_requested(marker: TimelineMarker, new_time: float)
signal marker_action(marker: TimelineMarker, action: StringName, time: float, global_pos: Vector2)

const _HIT_RADIUS: float = 8.0

var _asset: TimelineAsset = null
var _pps: float = 60.0
var _snap: bool = true
var _fps: int = 60
var _selected_marker: TimelineMarker = null
var _dragging: bool = false
var _drag_time: float = 0.0
var _context_menu: PopupMenu = null


func _init() -> void:
	custom_minimum_size = Vector2(1200.0, 28.0)


func setup(asset: TimelineAsset, pps: float) -> void:
	_asset = asset
	_pps = pps
	_build_context_menu()
	queue_redraw()


func _build_context_menu() -> void:
	if _context_menu != null:
		return
	_context_menu = PopupMenu.new()
	_context_menu.id_pressed.connect(_on_context_id_pressed)
	add_child(_context_menu)


func set_pps(v: float) -> void:
	_pps = v
	queue_redraw()


func set_snap(v: bool) -> void:
	_snap = v


func set_fps(v: int) -> void:
	_fps = maxi(1, v)


func refresh() -> void:
	queue_redraw()


func _snap_value(v: float) -> float:
	if not _snap:
		return maxf(0.0, v)
	var step: float = 1.0 / float(_fps)
	return maxf(0.0, roundf(v / step) * step)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.15))
	if _asset == null:
		return
	for marker: TimelineMarker in _asset.markers:
		if marker == null:
			continue
		var x: float = marker.time * _pps
		var color: Color = marker.color
		draw_colored_polygon(PackedVector2Array([
			Vector2(x, 3),
			Vector2(x + 7, 14),
			Vector2(x, 25),
			Vector2(x - 7, 14),
		]), color)
		if marker == _selected_marker:
			draw_arc(Vector2(x, 14), 11.0, 0.0, TAU, 24, Color(1, 1, 0.8), 1.5)
		draw_string(ThemeDB.fallback_font, Vector2(x + 9, 16), marker.get_display_name(), HORIZONTAL_ALIGNMENT_LEFT, 160.0, 11, Color(1, 1, 1, 0.85))


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				var hit: TimelineMarker = _marker_at(mb.position.x)
				_selected_marker = hit
				marker_selected.emit(hit)
				_dragging = hit != null
				if hit != null:
					_drag_time = hit.time
				queue_redraw()
			else:
				if _dragging and _selected_marker != null and not is_equal_approx(_drag_time, _selected_marker.time):
					marker_move_requested.emit(_selected_marker, _snap_value(_drag_time))
				_dragging = false
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			var marker: TimelineMarker = _marker_at(mb.position.x)
			var time: float = _snap_value(mb.position.x / _pps)
			_show_context_menu(marker, time, get_global_mouse_position())
	elif event is InputEventMouseMotion:
		var mm: InputEventMouseMotion = event as InputEventMouseMotion
		if _dragging and _selected_marker != null:
			_drag_time = maxf(0.0, _drag_time + mm.relative.x / _pps)
			queue_redraw()


func _marker_at(x: float) -> TimelineMarker:
	if _asset == null:
		return null
	var best: TimelineMarker = null
	var best_dist: float = _HIT_RADIUS
	for marker: TimelineMarker in _asset.markers:
		if marker == null:
			continue
		var dist: float = absf(marker.time * _pps - x)
		if dist <= best_dist:
			best_dist = dist
			best = marker
	return best


func _show_context_menu(marker: TimelineMarker, time: float, global_pos: Vector2) -> void:
	_context_menu.clear()
	_context_menu.set_meta("time", time)
	_context_menu.set_meta("marker", marker)
	if marker == null:
		_context_menu.add_item("添加 Marker", 0)
		_context_menu.add_item("添加 Signal Emitter", 1)
	else:
		_context_menu.add_item("重命名", 2)
		_context_menu.add_item("复制", 3)
		_context_menu.add_item("删除", 4)
	_context_menu.position = global_pos
	_context_menu.popup()


func _on_context_id_pressed(id: int) -> void:
	var time: float = float(_context_menu.get_meta("time", 0.0))
	var marker: TimelineMarker = _context_menu.get_meta("marker", null) as TimelineMarker
	var action: StringName = &""
	match id:
		0:
			action = &"add_marker"
		1:
			action = &"add_signal_emitter"
		2:
			action = &"rename"
		3:
			action = &"duplicate"
		4:
			action = &"delete"
	marker_action.emit(marker, action, time, _context_menu.position)
