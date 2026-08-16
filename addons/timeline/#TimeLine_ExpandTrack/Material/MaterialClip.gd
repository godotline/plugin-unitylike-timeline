@tool
class_name MaterialClip
extends TimelineClip

## Unity: MaterialClip.cs
## PlayableAsset analog. clipCaps = ClipCaps.Blending is inherent to the mixer path
## (blend_in/blend_out weights computed by TimelineDirector._clip_weight).

const MaterialBehaviourScript: Script = preload("res://addons/timeline/#TimeLine_ExpandTrack/Material/MaterialBehaviour.gd")


func _init() -> void:
	template = MaterialBehaviourScript.new()
