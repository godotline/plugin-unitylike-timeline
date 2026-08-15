@tool
class_name TimelineMarker
extends Resource

## Unity Marker analog. Markers are point-in-time resources owned by a
## TimelineAsset and are evaluated independently of clip lanes.

@export var marker_name: String = "Marker"
@export var time: float = 0.0
@export var enabled: bool = true
@export var color: Color = Color(0.9, 0.3, 0.3)
@export var trigger_once: bool = false
@export var template: TimelineBehaviour = null


func get_display_name() -> String:
	return marker_name


## Sorts markers in-place by time (stable for equal times).
static func sort_markers(markers: Array[TimelineMarker]) -> void:
	markers.sort_custom(func(a: TimelineMarker, b: TimelineMarker) -> bool: return a.time < b.time)


func on_marker(bound: Object) -> void:
	if template != null:
		template.on_clip_start(bound)
