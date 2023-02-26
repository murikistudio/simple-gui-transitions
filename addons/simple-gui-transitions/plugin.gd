tool
extends EditorPlugin


const SINGLETON_NAME := "GuiTransitions"
const SINGLETON_PATH := "res://addons/simple-gui-transitions/singleton.gd"


func enable_plugin() -> void:
	add_autoload_singleton(SINGLETON_NAME, SINGLETON_PATH)


func disable_plugin() -> void:
	remove_autoload_singleton(SINGLETON_NAME)

