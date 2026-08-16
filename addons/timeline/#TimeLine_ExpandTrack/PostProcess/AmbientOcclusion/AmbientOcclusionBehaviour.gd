# Unity: AmbientOcclusionBehaviour.cs
@tool
class_name AmbientOcclusionBehaviour
extends TimelineBehaviour

## Unity: public AmbientOcclusionBehaviour — serialized clip data. Ranges from
## Unity: intensity 0~4, radius 0.1~10. darkness/blurQuality removed in 3.5.1.

@export var enableAmbientOcclusion: bool = true

@export_range(0.0, 4.0, 0.01) var intensity: float = 1.0
@export_range(0.1, 10.0, 0.01) var radius: float = 0.3
