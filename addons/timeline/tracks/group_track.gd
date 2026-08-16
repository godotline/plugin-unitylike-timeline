@tool
class_name GroupTrack
extends TimelineTrack

## Unity GroupTrack analog: a container track that owns child tracks. It is not
## evaluated by the director; it only organizes the track hierarchy in the dock.


func _init() -> void:
	track_color = Color(0.5, 0.5, 0.5)
	track_name = "Group"
	is_group = true


func get_display_name() -> String:
	return "Group"
