@tool
class_name MaterialTrack
extends TimelineTrack

## Unity: MaterialTrack.cs
## Timeline track that binds a GeometryInstance3D (MeshInstance3D) and blends its
## material's albedo color + HDR emission via MaterialMixer. Unity
## [TrackBindingType(typeof(Material))] maps to GeometryInstance3D.material_override here.

func _init() -> void:
	track_color = Color(0.4386792, 0.7193396, 1.0)


func get_clip_class() -> Script:
	return preload("res://addons/timeline/#TimeLine_ExpandTrack/Material/MaterialClip.gd")


func has_mixer() -> bool:
	return true


func create_mixer() -> TimelineMixer:
	return preload("res://addons/timeline/#TimeLine_ExpandTrack/Material/MaterialMixer.gd").new()


func get_display_name() -> String:
	return "Material"


func validate_binding(bound: Object) -> bool:
	return bound is GeometryInstance3D
