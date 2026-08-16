# Unity: MotionBlurMixerBehaviour.cs
@tool
class_name MotionBlurMixer
extends TimelineMixer

## Godot 4 note: built-in Motion Blur was REMOVED in Godot 4.x (no Environment
## property, no project setting). This is a deliberate NO-OP port: the
## track/clip/behaviour data is preserved so the extension API is exercised and
## serialized data survives, but process_frame applies nothing.
## To get motion blur in Godot 4 you need a CompositorEffect / third-party addon.

func on_first_frame() -> void:
	pass


func process_frame(inputs: Array, time: float, delta: float) -> void:
	pass


func on_playable_destroy() -> void:
	pass
