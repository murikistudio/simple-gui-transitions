tool
extends EditorPlugin


const SINGLETON_NAME := "GuiTransitions"
const SINGLETON_PATH := "res://addons/simple-gui-transitions/singleton.gd"


func _enter_tree() -> void:
	add_autoload_singleton(SINGLETON_NAME, SINGLETON_PATH)


func _exit_tree() -> void:
	remove_autoload_singleton(SINGLETON_NAME)
