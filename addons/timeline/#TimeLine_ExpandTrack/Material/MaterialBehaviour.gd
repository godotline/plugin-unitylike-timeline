@tool
class_name MaterialBehaviour
extends TimelineBehaviour

## Unity: MaterialBehaviour.cs
## Serialized clip data for a material blend: target albedo color (Unity .color,
## [ColorUsage(false,false)]) and target HDR emission color (Unity _EmissionColor,
## [ColorUsage(false,true)]). Field names preserved from Unity.

@export var TargetColor: Color = Color.WHITE
@export var TargetHDRColor: Color = Color.WHITE
