tool
extends EditorPlugin


# Constants
const ANIMATION_TYPES := "SLIDE_LEFT,SLIDE_RIGHT,SLIDE_UP,SLIDE_DOWN,FADE,SCALE,SCALE_VERTICAL,SCALE_HORIZONTAL"
const SINGLETON_NAME := "GuiTransitions"
const SINGLETON_PATH := "res://addons/simple-gui-transitions/singleton.gd"
const SETTINGS_BASE := "gui_transitions/config/default/"
const DEFAULT_SETTINGS := [
	{
		"name": SETTINGS_BASE + "auto_start",
		"type": TYPE_BOOL,
		"value": true,
	},
	{
		"name": SETTINGS_BASE + "fade_layout",
		"type": TYPE_BOOL,
		"value": true,
	},
	{
		"name": SETTINGS_BASE + "center_pivot",
		"type": TYPE_BOOL,
		"value": true,
	},
	{
		"name": SETTINGS_BASE + "duration",
		"type": TYPE_REAL,
		"value": 0.5,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0.1,2.0,0.01",
	},
	{
		"name": SETTINGS_BASE + "delay",
		"type": TYPE_REAL,
		"value": 0.5,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0.0,1.0,0.01",
	},
	{
		"name": SETTINGS_BASE + "transition_type",
		"type": TYPE_STRING,
		"value": "QUAD",
		"hint": PROPERTY_HINT_ENUM_SUGGESTION,
		"hint_string": "LINEAR,SINE,QUINT,QUART,QUAD,EXPO,ELASTIC,CUBIC,CIRC,BOUNCE,BACK",
	},
	{
		"name": SETTINGS_BASE + "ease_type",
		"type": TYPE_STRING,
		"value": "IN_OUT",
		"hint": PROPERTY_HINT_ENUM_SUGGESTION,
		"hint_string": "IN,OUT,IN_OUT,OUT_IN",
	},
	{
		"name": SETTINGS_BASE + "animation_enter",
		"type": TYPE_INT,
		"value": 4,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": ANIMATION_TYPES,
	},
	{
		"name": SETTINGS_BASE + "animation_leave",
		"type": TYPE_INT,
		"value": 4,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": ANIMATION_TYPES,
	},
]


# Built-in overrides
func enable_plugin() -> void:
	add_autoload_singleton(SINGLETON_NAME, SINGLETON_PATH)


func disable_plugin() -> void:
	remove_autoload_singleton(SINGLETON_NAME)


# Private methods
func _has_settings() -> bool:
	for setting in DEFAULT_SETTINGS:
		if not ProjectSettings.has_setting(setting["name"]):
			return false

	return true


func _add_default_settings():
	for _setting in DEFAULT_SETTINGS:
		var setting: Dictionary = _setting

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


func _remove_default_settings():
	for _setting in DEFAULT_SETTINGS:
		var setting: Dictionary = _setting

		if ProjectSettings.has_setting(setting["name"]):
			ProjectSettings.set_setting(setting["name"], null)
