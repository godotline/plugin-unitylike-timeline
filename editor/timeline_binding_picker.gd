@tool
class_name TimelineBindingPicker
extends PopupMenu

## Unity-style track binding picker. Lists every node in the edited scene,
## computes NodePaths relative to the TimelineDirector and only allows nodes
## accepted by the track's validate_binding().

signal binding_chosen(track: TimelineTrack, node_path: NodePath)

var _track: TimelineTrack = null
var _director: Node = null
var _paths: Array[NodePath] = []
var _ready_once: bool = false


func _ready() -> void:
	if not _ready_once:
		id_pressed.connect(_on_id_pressed)
		_ready_once = true


func open_at(global_pos: Vector2, track: TimelineTrack, director: Node) -> void:
	_track = track
	_director = director
	_rebuild()
	if visible:
		hide()
	position = global_pos
	popup()


func _rebuild() -> void:
	clear()
	_paths.clear()
	if _track == null:
		return
	var root: Node = _get_scene_root()
	if root == null:
		add_item("（无场景根节点）", -1)
		return
	add_item("清除绑定", 0)
	_paths.append(NodePath())
	_add_node_recursive(root, 0)


func _get_scene_root() -> Node:
	if _director != null and is_instance_valid(_director):
		if _director.is_inside_tree():
			var edited: Node = _director.get_tree().edited_scene_root
			if edited != null:
				return edited
		var node: Node = _director
		while node.get_parent() != null:
			node = node.get_parent()
		return node
	return null


func _add_node_recursive(node: Node, depth: int) -> void:
	if node == null:
		return
	var id: int = _paths.size()
	var path: NodePath = _director.get_path_to(node) if _director != null and is_instance_valid(_director) else NodePath(String(node.get_path()))
	_paths.append(path)
	var valid: bool = _track.validate_binding(node)
	var indent: String = "  ".repeat(depth)
	add_item("%s%s  [%s]" % [indent, node.name, node.get_class()], id)
	var item_index: int = _get_item_index(id)
	if item_index >= 0:
		set_item_disabled(item_index, not valid)
		set_item_tooltip(item_index, "类型 %s" % node.get_class() if not valid else "绑定到 %s" % path)
	for child: Node in node.get_children():
		_add_node_recursive(child, depth + 1)


func _get_item_index(id: int) -> int:
	for index: int in item_count:
		if get_item_id(index) == id:
			return index
	return -1


func _on_id_pressed(id: int) -> void:
	if _track == null:
		return
	if id >= 0 and id < _paths.size():
		binding_chosen.emit(_track, _paths[id])
