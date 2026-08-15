@tool
extends Control

## A single clip rectangle in the timeline dock. Drag to move (snap-aware),
## drag the left/right 6px edges to resize, Ctrl/Shift-click for multi-select,
## and right-click for the Unity-style clip context menu.

signal selected(clip: TimelineClip, add_to_selection: bool, range_select: bool)
signal move_requested(clip: TimelineClip, new_start: float)
signal resize_requested(clip: TimelineClip, new_start: float, new_duration: float)
signal action_requested(action: StringName, clip: TimelineClip, track: TimelineTrack)

const _SNAP_RATE: float = 60.0
const _EDGE_WIDTH: float = 6.0

var _clip: TimelineClip = null
var _track: TimelineTrack = null
var _pps: float = 60.0
var _snap: bool = true
var _locked: bool = false
var _selected: bool = false
var _dragging: bool = false
var _resize_edge: int = 0
var _press_left: float = 0.0
var _press_right: float = 0.0
var _press_start: float = 0.0
var _press_duration: float = 0.0
var _context_menu: PopupMenu = null


func _init() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func setup(clip: TimelineClip, track: TimelineTrack, pps: float) -> void:
	_clip = clip
	_track = track
	_pps = pps
	_build_context_menu()
	queue_redraw()


func _build_context_menu() -> void:
	if _context_menu != null:
		return
	_context_menu = PopupMenu.new()
	_context_menu.add_item("复制", 0)
	_context_menu.add_item("粘贴", 1)
	_context_menu.add_item("重复", 2)
	_context_menu.add_item("重命名", 3)
	_context_menu.add_item("启用/禁用", 4)
	_context_menu.add_separator()
	_context_menu.add_item("删除", 5)
	_context_menu.add_item("清空关键帧", 6)
	_context_menu.id_pressed.connect(_on_context_id_pressed)
	add_child(_context_menu)


func _on_context_id_pressed(id: int) -> void:
	if _clip == null or _track == null:
		return
	var action: StringName = &""
	match id:
		0:
			action = &"copy"
		1:
			action = &"paste"
		2:
			action = &"duplicate"
		3:
			action = &"rename"
		4:
			action = &"toggle_enabled"
		5:
			action = &"delete"
		6:
			action = &"clear_keyframes"
	action_requested.emit(action, _clip, _track)


func set_snap(v: bool) -> void:
	_snap = v


func set_locked(v: bool) -> void:
	_locked = v
	queue_redraw()


func set_selected(v: bool) -> void:
	_selected = v
	queue_redraw()


func set_pps(v: float) -> void:
	_pps = v
	queue_redraw()


func get_clip() -> TimelineClip:
	return _clip


func _snap_value(v: float) -> float:
	if not _snap:
		return v
	var step: float = 1.0 / _SNAP_RATE
	return roundf(v / step) * step


func _draw() -> void:
	if _clip == null or _track == null:
		return
	var color: Color = _track.track_color
	if not _clip.enabled:
		color.a = 0.25
	if _track.muted:
		color.a *= 0.45
	draw_rect(Rect2(Vector2.ZERO, size), Color(color.r, color.g, color.b, color.a))
	draw_rect(Rect2(Vector2.ZERO, size), color, false, 1.5)
	var blend_color: Color = Color(1, 1, 1, 0.12)
	if _clip.blend_in > 0.0:
		var bx: float = _clip.blend_in * _pps
		draw_rect(Rect2(0, 0, bx, size.y), blend_color)
	if _clip.blend_out > 0.0:
		var bx2: float = size.x - _clip.blend_out * _pps
		draw_rect(Rect2(bx2, 0, size.x - bx2, size.y), blend_color)
	if _selected:
		draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 0.8, 0.95), false, 2.5)
	if not _clip.clip_name.is_empty():
		draw_string(ThemeDB.fallback_font, Vector2(4, size.y * 0.62), _clip.clip_name, HORIZONTAL_ALIGNMENT_LEFT, size.x - 46.0, 12, Color(1, 1, 1, 0.95))
	if not is_equal_approx(_clip.speed, 1.0):
		draw_string(ThemeDB.fallback_font, Vector2(size.x - 42.0, 12), "%.1fx" % _clip.speed, HORIZONTAL_ALIGNMENT_RIGHT, 38.0, 10, Color(1, 0.9, 0.4, 0.95))


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				var add: bool = Input.is_key_pressed(KEY_CTRL) or Input.is_key_pressed(KEY_META)
				var range: bool = Input.is_key_pressed(KEY_SHIFT)
				selected.emit(_clip, add, range)
				_dragging = not _locked
				_press_left = position.x
				_press_right = position.x + size.x
				_press_start = _clip.start
				_press_duration = _clip.duration
				if mb.position.x <= _EDGE_WIDTH:
					_resize_edge = -1
				elif mb.position.x >= size.x - _EDGE_WIDTH:
					_resize_edge = 1
				else:
					_resize_edge = 0
				queue_redraw()
			else:
				if _dragging and not _locked:
					if _resize_edge == 0:
						var new_start: float = _snap_value(_press_start + (position.x - _press_left) / _pps)
						if new_start < 0.0:
							new_start = 0.0
						move_requested.emit(_clip, new_start)
					elif _resize_edge == -1:
						var dx_left: float = position.x - _press_left
						var ns: float = _snap_value(_press_start + dx_left / _pps)
						var nd: float = _snap_value(_press_duration - dx_left / _pps)
						if nd < 0.05:
							nd = 0.05
						if ns < 0.0:
							ns = 0.0
						resize_requested.emit(_clip, ns, nd)
					elif _resize_edge == 1:
						var dx_right: float = position.x + size.x - _press_right
						var nd3: float = _snap_value(_press_duration + dx_right / _pps)
						if nd3 < 0.05:
							nd3 = 0.05
						resize_requested.emit(_clip, _clip.start, nd3)
				_dragging = false
				_resize_edge = 0
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			if _context_menu != null:
				_context_menu.position = get_global_mouse_position()
				_context_menu.popup()
	elif event is InputEventMouseMotion:
		var mm: InputEventMouseMotion = event as InputEventMouseMotion
		if _dragging:
			if _resize_edge == 0:
				position.x = maxf(0.0, position.x + mm.relative.x)
			elif _resize_edge == -1:
				position.x = maxf(0.0, position.x + mm.relative.x)
				size.x = maxf(4.0, _press_right - position.x)
			elif _resize_edge == 1:
				size.x = maxf(4.0, size.x + mm.relative.x)
			queue_redraw()
	accept_event()
