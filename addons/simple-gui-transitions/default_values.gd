extends RefCounted


# Constants
const SETTING_BASE := "gui_transitions/config/default/"
const SETTING_AUTO_START := SETTING_BASE + "auto_start"
const SETTING_FADE_LAYOUT := SETTING_BASE + "fade_layout"
const SETTING_CENTER_PIVOT := SETTING_BASE + "center_pivot"
const SETTING_DURATION := SETTING_BASE + "duration"
const SETTING_DELAY := SETTING_BASE + "delay"
const SETTING_TRANSITION_ENTER := SETTING_BASE + "transition_enter"
const SETTING_TRANSITION_LEAVE := SETTING_BASE + "transition_leave"
const SETTING_EASE_ENTER := SETTING_BASE + "ease_enter"
const SETTING_EASE_LEAVE := SETTING_BASE + "ease_leave"
const SETTING_ANIMATION_ENTER := SETTING_BASE + "animation_enter"
const SETTING_ANIMATION_LEAVE := SETTING_BASE + "animation_leave"

# Default values
const HINT_TRANSITION := "LINEAR,SINE,QUINT,QUART,QUAD,EXPO,ELASTIC,CUBIC,CIRC,BOUNCE,BACK"
const HINT_EASE := "IN,OUT,IN_OUT,OUT_IN"
const HINT_ANIMATION := "SLIDE_LEFT,SLIDE_RIGHT,SLIDE_UP,SLIDE_DOWN,FADE,SCALE,SCALE_VERTICAL,SCALE_HORIZONTAL"
const DEFAULT_DURATION := 0.5
const DEFAULT_DELAY := 0.5
const DEFAULT_CENTER_PIVOT := true
const DEFAULT_AUTO_START := true
const DEFAULT_FADE_LAYOUT := true
const DEFAULT_TRANSITION_TYPE := "QUAD"
const DEFAULT_EASE_TYPE := "IN_OUT"
const DEFAULT_ANIMATION_TYPE := 4

const DEFAULT_SETTINGS := [
	{
		"name": SETTING_AUTO_START,
		"type": TYPE_BOOL,
		"value": true,
	},
	{
		"name": SETTING_FADE_LAYOUT,
		"type": TYPE_BOOL,
		"value": true,
	},
	{
		"name": SETTING_CENTER_PIVOT,
		"type": TYPE_BOOL,
		"value": true,
	},
	{
		"name": SETTING_DURATION,
		"type": TYPE_FLOAT,
		"value": 0.5,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0.1,2.0,0.01",
	},
	{
		"name": SETTING_DELAY,
		"type": TYPE_FLOAT,
		"value": 0.5,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0.0,1.0,0.01",
	},
	{
		"name": SETTING_TRANSITION_ENTER,
		"type": TYPE_STRING,
		"value": DEFAULT_TRANSITION_TYPE,
		"hint": PROPERTY_HINT_ENUM_SUGGESTION,
		"hint_string": HINT_TRANSITION,
	},
	{
		"name": SETTING_TRANSITION_LEAVE,
		"type": TYPE_STRING,
		"value": DEFAULT_TRANSITION_TYPE,
		"hint": PROPERTY_HINT_ENUM_SUGGESTION,
		"hint_string": HINT_TRANSITION,
	},
	{
		"name": SETTING_EASE_ENTER,
		"type": TYPE_STRING,
		"value": DEFAULT_EASE_TYPE,
		"hint": PROPERTY_HINT_ENUM_SUGGESTION,
		"hint_string": HINT_EASE,
	},
	{
		"name": SETTING_EASE_LEAVE,
		"type": TYPE_STRING,
		"value": DEFAULT_EASE_TYPE,
		"hint": PROPERTY_HINT_ENUM_SUGGESTION,
		"hint_string": HINT_EASE,
	},
	{
		"name": SETTING_ANIMATION_ENTER,
		"type": TYPE_INT,
		"value": DEFAULT_ANIMATION_TYPE,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": HINT_ANIMATION,
	},
	{
		"name": SETTING_ANIMATION_LEAVE,
		"type": TYPE_INT,
		"value": DEFAULT_ANIMATION_TYPE,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": HINT_ANIMATION,
	},
]
