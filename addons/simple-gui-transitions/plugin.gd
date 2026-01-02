@tool
extends EditorPlugin


# Constants
const DEBUG := false
const BASE_PATH := "res://addons/simple-gui-transitions/"
const SINGLETON_NAME := "GuiTransitions"


# Preloads
const DefaultValues := preload(BASE_PATH + "default_values.gd")
const TransitionNode := preload(BASE_PATH + "transition.gd")
const TransitionIcon = preload(BASE_PATH + "icon.png")


# Built-in overrides
# Add the addon singleton and default settings to project settings.
func _enable_plugin() -> void:
	add_autoload_singleton(SINGLETON_NAME, BASE_PATH + "singleton.gd")
	_add_default_settings()


# Remove the addon singleton and all its settings from project settings.
func _disable_plugin() -> void:
	remove_autoload_singleton(SINGLETON_NAME)
	_remove_default_settings()


# Automatically non-existing settings to project settings.
func _enter_tree() -> void:
	var replace_existing := DEBUG
	add_custom_type("GuiTransition", "Node", TransitionNode, TransitionIcon)
	_add_default_settings(replace_existing)


# For debug only.
func _exit_tree() -> void:
	remove_custom_type("GuiTransition")
	if DEBUG:
		_remove_default_settings()


# Private methods
# Add addon settings to project settings. Optionally can replace existing ones.
func _add_default_settings(replace := false):
	for _setting in DefaultValues.DEFAULT_SETTINGS:
		var setting: Dictionary = _setting
		var has_setting := ProjectSettings.has_setting(setting["name"])

		if not has_setting or replace:
			ProjectSettings.set(setting["name"], setting["value"])

		var property_info := {
			"name": setting["name"],
			"type": setting["type"],
		}

		if setting.has("hint"):
			property_info["hint"] = setting["hint"]

		if setting.has("hint_string"):
			property_info["hint_string"] = setting["hint_string"]

		ProjectSettings.add_property_info(property_info)


# Remove addon settings from project settings.
func _remove_default_settings():
	for _setting in DefaultValues.DEFAULT_SETTINGS:
		var setting: Dictionary = _setting

		if ProjectSettings.has_setting(setting["name"]):
			ProjectSettings.set_setting(setting["name"], null)
