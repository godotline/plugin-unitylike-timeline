class_name TimelineRegistry
extends RefCounted

## Static registry of TimelineTrack subclasses available to the editor dock's
## Add Track menu. Populated via discover_editor() by walking the EditorFileSystem.

static var _track_types: Dictionary = {}  # Script -> {script, display_name, category}
static var _class_name_to_script: Dictionary = {}  # StringName -> Script


## Registers a track script. Skips core base scripts (path-based skip-list) and
## non-instantiable/abstract scripts. Falls back to class_name / file name for
## display name and parent directory name for category.
static func register_track(track_script: Script, display_name: String = "", category: String = "") -> void:
	if track_script == null:
		return
	if not track_script.can_instantiate():
		return
	var core_paths: Array[String] = [
		"res://addons/timeline/core/timeline_asset.gd",
		"res://addons/timeline/core/timeline_track.gd",
		"res://addons/timeline/core/timeline_clip.gd",
		"res://addons/timeline/core/timeline_behaviour.gd",
		"res://addons/timeline/core/timeline_mixer.gd",
		"res://addons/timeline/core/timeline_registry.gd",
	]
	if core_paths.has(track_script.resource_path):
		return
	var entry_display: String = display_name
	if entry_display == "":
		var gname: StringName = track_script.get_global_name()
		if gname != &"":
			entry_display = String(gname)
		else:
			entry_display = track_script.resource_path.get_file().get_basename()
	var entry_category: String = category
	if entry_category == "":
		entry_category = track_script.resource_path.get_base_dir().get_file()
	_track_types[track_script] = {
		"script": track_script,
		"display_name": entry_display,
		"category": entry_category,
	}


## Returns all registered track entries sorted by category then display name.
static func get_registered_tracks() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for value: Variant in _track_types.values():
		entries.append(value as Dictionary)
	entries.sort_custom(_compare_entries)
	return entries


## Sort comparator: category first, then display name (String comparison).
static func _compare_entries(a: Dictionary, b: Dictionary) -> bool:
	var a_category: String = String(a.get("category", ""))
	var b_category: String = String(b.get("category", ""))
	if a_category != b_category:
		return a_category < b_category
	var a_display: String = String(a.get("display_name", ""))
	var b_display: String = String(b.get("display_name", ""))
	return a_display < b_display


## Recursively scans the editor filesystem and registers every TimelineTrack subclass.
static func discover_editor(filesystem: EditorFileSystem) -> void:
	if not Engine.is_editor_hint():
		return
	if filesystem == null:
		return
	_class_name_to_script.clear()
	_scan_editor_directory(filesystem.get_filesystem())


## Recursive per-directory scan of .gd files.
static func _scan_editor_directory(dir: EditorFileSystemDirectory) -> void:
	for i: int in dir.get_file_count():
		if not dir.get_file(i).ends_with(".gd"):
			continue
		var full_path: String = dir.get_path().path_join(dir.get_file(i))
		var script: Script = ResourceLoader.load(full_path) as Script
		if script == null:
			continue
		var gname: StringName = script.get_global_name()
		if gname != &"":
			_class_name_to_script[gname] = script
		if not script.can_instantiate():
			continue
		# Only instantiate RefCounted-based scripts: track scripts extend Resource,
		# and a Node script would leak (no owner) if created here.
		var base_type: StringName = script.get_instance_base_type()
		if base_type != &"Resource" and base_type != &"RefCounted":
			continue
		var inst: Object = script.new()
		if inst is TimelineTrack:
			register_track(script)
	for i: int in dir.get_subdir_count():
		_scan_editor_directory(dir.get_subdir(i))


## ClassDB lookup fallback: registers a track by its global class_name StringName.
static func register_track_class(class_name_str: StringName) -> void:
	if not ClassDB.class_exists(class_name_str):
		return
	var script: Script = _class_name_to_script.get(class_name_str) as Script
	if script != null:
		register_track(script)
