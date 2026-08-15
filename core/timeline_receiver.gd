class_name TimelineReceiver
extends Node

## Unity SignalReceiver analog. Maps signal names to method names and dispatches
## signals emitted by TimelineSignalEmitter markers.

signal timeline_signal_received(signal_name: StringName, arg: Variant)

## signal_name -> method_name. Methods receive the emitter's optional arg.
@export var signal_handlers: Dictionary = {}


func emit_timeline_signal(signal_name: StringName, arg: Variant = null) -> bool:
	var method_name: Variant = signal_handlers.get(signal_name, &"")
	if method_name == null or StringName(method_name) == &"":
		push_warning("TimelineReceiver[%s]: 没有注册信号 %s" % [name, signal_name])
		return false
	var method_str: StringName = StringName(method_name)
	if not has_method(method_str):
		push_warning("TimelineReceiver[%s]: 信号 %s 指向的方法 %s 不存在" % [name, signal_name, method_str])
		return false
	call(method_str, arg)
	timeline_signal_received.emit(signal_name, arg)
	return true
