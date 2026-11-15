@tool
extends EditorPlugin
const Workspace = preload("res://addons/level_editor/workspace.gd")
var workspace: Control

func _enter_tree() -> void:
	workspace = Workspace.new()
	EditorInterface.get_editor_main_screen().add_child(workspace)
	workspace.hide()

func _exit_tree() -> void:
	workspace.queue_free()

func _has_main_screen() -> bool:
	return true

func _make_visible(visible: bool) -> void:
	if workspace != null:
		workspace.visible = visible

func _get_plugin_name() -> String:
	return "Level Editor"
