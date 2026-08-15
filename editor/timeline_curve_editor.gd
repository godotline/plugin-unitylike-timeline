@tool
class_name TimelineCurveEditor
extends VBoxContainer

## Minimal Unity-style inline curve editor for TransformBehaviour keyframes.
## Channels: position/rotation/scale x/y/z. Dragging a keyframe edits both its
## normalized time and the selected channel value; empty-click adds a keyframe,
## Delete/right-click removes the nearest one.

signal keyframes_changed(keyframes: Array)
signal editing_ended

const _CHANNEL_NAMES: Array[String] = [
	"位置 X", "位置 Y", "位置 Z",
	"旋转 X", "旋转 Y", "旋转 Z",
	"缩放 X", "缩放 Y", "缩放 Z",
]

class PlotView extends Control:
	var host: TimelineCurveEditor = null

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _gui_input(event: InputEvent) -> void:
		if host != null:
			host._on_plot_input(event)

	func _notification(what: int) -> void:
		if what == NOTIFICATION_DRAW and host != null:
			host._draw_plot(self)

var _behaviour: TransformBehaviour = null
var _keyframes: Array[Dictionary] = []
var _channel: int = 0
var _plot: Control = null
var _channel_option: OptionButton = null
var _drag_index: int = -1
var _drag_origin: Vector2 = Vector2.ZERO
var _pending_time: float = -1.0
var _pending_value: float = 0.0
var _mouse_down: bool = false


func _init() -> void:
	custom_minimum_size = Vector2(0.0, 190.0)
	add_theme_constant_override("separation", 4)


func _ready() -> void:
	var toolbar: HBoxContainer = HBoxContainer.new()
	_channel_option = OptionButton.new()
	for index: int in _CHANNEL_NAMES.size():
		_channel_option.add_item(_CHANNEL_NAMES[index], index)
	_channel_option.selected = _channel
	_channel_option.item_selected.connect(_on_channel_changed)
	var add_btn: Button = Button.new()
	add_btn.text = "添加点"
	add_btn.tooltip_text = "点击图表空白处也可添加关键帧"
	add_btn.pressed.connect(_on_add_clicked)
	var clear_btn: Button = Button.new()
	clear_btn.text = "清空关键帧"
	clear_btn.pressed.connect(_on_clear_clicked)
	toolbar.add_child(_channel_option)
	toolbar.add_child(add_btn)
	toolbar.add_child(clear_btn)
	add_child(toolbar)
	_plot = PlotView.new()
	_plot.custom_minimum_size = Vector2(0.0, 150.0)
	_plot.size_flags_vertical = Control.SIZE_EXPAND_FILL
	(_plot as PlotView).host = self
	_plot.resized.connect(_plot.queue_redraw)
	add_child(_plot)


func set_clip(clip: TimelineClip) -> void:
	_behaviour = null
	_keyframes.clear()
	_drag_index = -1
	if clip != null and clip.template is TransformBehaviour:
		_behaviour = clip.template as TransformBehaviour
		for entry: Dictionary in _behaviour.keyframes:
			_keyframes.append(entry.duplicate(true))
	visible = _behaviour != null
	if _plot != null:
		_plot.queue_redraw()


func clear() -> void:
	_behaviour = null
	_keyframes.clear()
	visible = false
	if _plot != null:
		_plot.queue_redraw()


func _on_channel_changed(index: int) -> void:
	_channel = index
	_plot.queue_redraw()


func _on_add_clicked() -> void:
	if _keyframes.size() < 2:
		return
	var time_value: float = 0.5
	var value: float = _sample_channel(time_value)
	_add_keyframe(time_value, value)


func _on_clear_clicked() -> void:
	if _keyframes.is_empty():
		return
	_keyframes.clear()
	keyframes_changed.emit(_keyframes.duplicate(true))
	_plot.queue_redraw()


func _on_plot_input(event: InputEvent) -> void:
	if not (event is InputEventMouse):
		return
	var mouse: InputEventMouse = event as InputEventMouse
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_mouse_down = true
				_pending_time = -1.0
				_drag_index = _find_keyframe_at(mb.position)
				_drag_origin = mb.position
				if _drag_index < 0:
					var point: Vector2 = _to_plot(mb.position)
					_pending_time = clampf(point.x, 0.0, 1.0)
					_pending_value = _sample_channel(_pending_time)
			else:
				_mouse_down = false
				if _drag_index >= 0:
					_commit()
					_drag_index = -1
				elif _pending_time >= 0.0:
					_add_keyframe(_pending_time, _pending_value)
					_pending_time = -1.0
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			var index: int = _find_keyframe_at(mb.position)
			if index >= 0:
				_keyframes.remove_at(index)
				keyframes_changed.emit(_keyframes.duplicate(true))
				_plot.queue_redraw()
	elif event is InputEventMouseMotion:
		var motion: InputEventMouseMotion = event as InputEventMouseMotion
		if not _mouse_down:
			return
		if _drag_index >= 0:
			_update_drag(motion.position)
		elif _pending_time >= 0.0:
			_update_pending(motion.position)


func _update_drag(mouse_pos: Vector2) -> void:
	if _drag_index < 0 or _drag_index >= _keyframes.size():
		return
	var point: Vector2 = _to_plot(mouse_pos)
	var time_value: float = clampf(point.x, 0.0, 1.0)
	var entry: Dictionary = _keyframes[_drag_index]
	if absf(time_value - float(entry.get("time", 0.0))) > 0.002:
		entry["time"] = time_value
	entry[_channel_key()] = _value_for_plot_y(point.y)
	_plot.queue_redraw()


func _update_pending(mouse_pos: Vector2) -> void:
	var point: Vector2 = _to_plot(mouse_pos)
	_pending_time = clampf(point.x, 0.0, 1.0)
	_pending_value = _value_for_plot_y(point.y)
	_plot.queue_redraw()


func _to_plot(mouse_pos: Vector2) -> Vector2:
	var size: Vector2 = _plot.size
	var x: float = mouse_pos.x / maxf(size.x, 1.0)
	var y: float = mouse_pos.y / maxf(size.y, 1.0)
	return Vector2(x, y)


func _channel_key() -> String:
	match _channel:
		0, 1, 2:
			return "pos"
		3, 4, 5:
			return "rot"
		_:
			return "scale"


func _channel_component(entry: Dictionary) -> float:
	var value: Vector3 = entry.get(_channel_key(), Vector3.ZERO) as Vector3
	return value[_channel % 3]


func _set_channel_component(entry: Dictionary, component: float) -> void:
	var value: Vector3 = entry.get(_channel_key(), Vector3.ZERO) as Vector3
	match _channel % 3:
		0:
			value.x = component
		1:
			value.y = component
		_:
			value.z = component
	entry[_channel_key()] = value


func _find_keyframe_at(mouse_pos: Vector2) -> int:
	var point: Vector2 = _to_plot(mouse_pos)
	var best: int = -1
	var best_distance: float = 0.02
	for index: int in _keyframes.size():
		var entry: Dictionary = _keyframes[index]
		var plot_pos: Vector2 = _to_plot_position(float(entry.get("time", 0.0)), _channel_component(entry))
		var distance: float = point.distance_to(plot_pos)
		if distance < best_distance:
			best_distance = distance
			best = index
	return best


func _add_keyframe(time_value: float, value: float) -> void:
	var entry: Dictionary = {
		"time": clampf(time_value, 0.0, 1.0),
		"pos": _interpolate_key("pos", time_value),
		"rot": _interpolate_key("rot", time_value),
		"scale": _interpolate_key("scale", time_value),
	}
	_set_channel_component(entry, value)
	_keyframes.append(entry)
	_keyframes.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.get("time", 0.0)) < float(b.get("time", 0.0)))
	keyframes_changed.emit(_keyframes.duplicate(true))
	_plot.queue_redraw()


func _interpolate_key(key: String, time_value: float) -> Vector3:
	if _keyframes.is_empty():
		return Vector3.ZERO if key != "scale" else Vector3.ONE
	if _keyframes.size() == 1:
		return _keyframes[0].get(key, Vector3.ZERO) as Vector3
	var prev: Dictionary = _keyframes[0]
	var next: Dictionary = _keyframes[_keyframes.size() - 1]
	for i: int in range(1, _keyframes.size()):
		var current: Dictionary = _keyframes[i]
		if time_value <= float(current.get("time", 1.0)):
			next = current
			break
		prev = current
	var t0: float = float(prev.get("time", 0.0))
	var t1: float = float(next.get("time", 1.0))
	var u: float = clampf((time_value - t0) / maxf(t1 - t0, 0.0001), 0.0, 1.0)
	return (prev.get(key, Vector3.ZERO) as Vector3).lerp(next.get(key, Vector3.ZERO) as Vector3, u)


func _sample_channel(time_value: float) -> float:
	var value: Vector3 = _interpolate_key(_channel_key(), time_value)
	return value[_channel % 3]


func _commit() -> void:
	_keyframes.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.get("time", 0.0)) < float(b.get("time", 0.0)))
	keyframes_changed.emit(_keyframes.duplicate(true))
	editing_ended.emit()
	_plot.queue_redraw()


func _draw_plot(plot: Control) -> void:
	if plot == null:
		return
	var size: Vector2 = plot.size
	var draw: CanvasItem = plot
	draw.draw_rect(Rect2(Vector2.ZERO, size), Color(0.12, 0.12, 0.14), true)
	var value_min: float = 0.0
	var value_max: float = 1.0
	if not _keyframes.is_empty():
		value_min = INF
		value_max = -INF
		for entry: Dictionary in _keyframes:
			var v: float = _channel_component(entry)
			value_min = minf(value_min, v)
			value_max = maxf(value_max, v)
	if absf(value_max - value_min) < 0.001:
		value_max += 1.0
		value_min -= 1.0
	else:
		var pad: float = (value_max - value_min) * 0.12
		value_min -= pad
		value_max += pad
	for i: int in range(1, 8):
		var x: float = size.x * float(i) / 8.0
		draw.draw_line(Vector2(x, 0.0), Vector2(x, size.y), Color(1, 1, 1, 0.08), 1.0)
	for i: int in range(1, 5):
		var y: float = size.y * float(i) / 5.0
		draw.draw_line(Vector2(0.0, y), Vector2(size.x, y), Color(1, 1, 1, 0.08), 1.0)
	if _keyframes.size() >= 2:
		var previous: Vector2 = Vector2.ZERO
		for index: int in _keyframes.size():
			var entry: Dictionary = _keyframes[index]
			var point: Vector2 = _to_plot_position(float(entry.get("time", 0.0)), _channel_component(entry))
			if index > 0:
				draw.draw_line(previous, point, Color(0.4, 0.8, 1.0, 0.9), 2.0)
			previous = point
	for index: int in _keyframes.size():
		var entry: Dictionary = _keyframes[index]
		var point: Vector2 = _to_plot_position(float(entry.get("time", 0.0)), _channel_component(entry))
		var color: Color = Color(1.0, 0.85, 0.25) if index == _drag_index else Color(0.95, 0.55, 0.2)
		draw.draw_circle(point, 4.0, color)
		draw.draw_circle(point, 4.0, Color(0, 0, 0, 0.35), false, 1.0)
	if _pending_time >= 0.0:
		var pending: Vector2 = _to_plot_position(_pending_time, _pending_value)
		draw.draw_circle(pending, 3.0, Color(0.6, 1.0, 0.6))


func _to_plot_position(time_value: float, value: float) -> Vector2:
	var size: Vector2 = _plot.size
	var value_min: float = 0.0
	var value_max: float = 1.0
	if not _keyframes.is_empty():
		value_min = INF
		value_max = -INF
		for entry: Dictionary in _keyframes:
			var v: float = _channel_component(entry)
			value_min = minf(value_min, v)
			value_max = maxf(value_max, v)
	if absf(value_max - value_min) < 0.001:
		value_max += 1.0
		value_min -= 1.0
	else:
		var pad: float = (value_max - value_min) * 0.12
		value_min -= pad
		value_max += pad
	var x: float = clampf(time_value, 0.0, 1.0) * size.x
	var y: float = size.y - (clampf((value - value_min) / (value_max - value_min), 0.0, 1.0) * size.y)
	return Vector2(x, y)


func _value_for_plot_y(y: float) -> float:
	var value_min: float = 0.0
	var value_max: float = 1.0
	if not _keyframes.is_empty():
		value_min = INF
		value_max = -INF
		for entry: Dictionary in _keyframes:
			var v: float = _channel_component(entry)
			value_min = minf(value_min, v)
			value_max = maxf(value_max, v)
	if absf(value_max - value_min) < 0.001:
		value_max += 1.0
		value_min -= 1.0
	else:
		var pad: float = (value_max - value_min) * 0.12
		value_min -= pad
		value_max += pad
	var size: Vector2 = _plot.size
	return value_min + (1.0 - clampf(y, 0.0, 1.0)) * (value_max - value_min)
