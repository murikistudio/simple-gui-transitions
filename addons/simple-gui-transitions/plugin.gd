tool
extends EditorPlugin


var _singleton_path := "res://addons/simple-gui-transitions/singleton.gd"


func _enter_tree() -> void:
	add_autoload_singleton("GuiTransitions", _singleton_path)


func _exit_tree() -> void:
	remove_autoload_singleton(_singleton_path)
