@tool
extends Control

## Timeline playhead: the vertical continuation of the ruler's red handle.

var _time: float = 0.0
var _pps: float = 60.0
var _duration: float = 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_time(v: float) -> void:
	_time = v
	queue_redraw()


func set_pps(v: float) -> void:
	_pps = v
	queue_redraw()


func set_duration(v: float) -> void:
	_duration = v
	queue_redraw()


func _draw() -> void:
	var x: float = _time * _pps
	draw_line(Vector2(x, 0), Vector2(x, size.y), Color(1, 0.2, 0.2, 0.9), 1.5)
