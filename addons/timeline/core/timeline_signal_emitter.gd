@tool
class_name TimelineSignalEmitter
extends TimelineMarker

## Unity SignalEmitter analog: a marker that fires a TimelineSignalAsset at a
## point in time. The director routes it to a TimelineReceiver.

@export var signal_asset: TimelineSignalAsset = null
@export var receiver_path: NodePath = NodePath()
@export var arg: Variant = null


func _init() -> void:
	marker_name = "Signal"
	color = Color(0.95, 0.8, 0.25)


func get_display_name() -> String:
	if signal_asset != null:
		return signal_asset.get_display_name()
	return marker_name
