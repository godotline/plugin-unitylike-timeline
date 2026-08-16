# Unity: BloomClip.cs
@tool
class_name BloomClip
extends TimelineClip

## Unity: public BloomBehaviour template = new(); ClipCaps.Blending.
const BloomBehaviourScript: Script = preload("res://addons/timeline/#TimeLine_ExpandTrack/PostProcess/Bloom/BloomBehaviour.gd")


func _init() -> void:
	template = BloomBehaviourScript.new()
