# Unity: DepthOfFieldBehaviour.cs
@tool
class_name DepthOfFieldBehaviour
extends TimelineBehaviour

## Unity: public DepthOfFieldBehaviour — serialized clip data. Ranges from Unity:
## focusDistance 0~100, aperture 0.1~32, focalLength 12~400.
## maxBlurSize was removed in PP 3.5.1.

@export var enableDepthOfField: bool = true

@export_range(0.0, 100.0, 0.1) var focusDistance: float = 10.0
@export_range(0.1, 32.0, 0.1) var aperture: float = 5.6
@export_range(12.0, 400.0, 1.0) var focalLength: float = 50.0
