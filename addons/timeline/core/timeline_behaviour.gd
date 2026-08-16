class_name TimelineBehaviour
extends Resource

## Unity PlayableBehaviour analog. Base class for clip data; subclasses add @export
## fields. Lifecycle hooks are optional.

## Optional lifecycle hook: called when the playhead enters the clip.
func on_clip_start(bound: Object) -> void:
	pass


## Optional lifecycle hook: called when the playhead leaves the clip.
func on_clip_end(bound: Object) -> void:
	pass
