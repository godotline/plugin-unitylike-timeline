@tool
class_name TimelineSignalAsset
extends Resource

## Unity SignalAsset analog: a named, reusable signal that SignalEmitters fire
## and TimelineReceivers route to methods.

@export var signal_name: StringName = &"Signal"


func get_display_name() -> String:
	return String(signal_name) if not String(signal_name).is_empty() else "Signal"
