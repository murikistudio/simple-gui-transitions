@tool
@icon("res://addons/simple-gui-transitions/icon.png")
class_name GuiTransition
extends Node
## This node is responsible for transitioning a specific layout.
##
## The default transition settings can be set on
## [code]Project Settings > GUI Transitions > Config[/code].
## Those settings will be applied on top of any default
## property on the node [code]GuiTransition[/code].
## This is useful to increase or decrease the speed of transitions
## on the whole project, for example. See each property description below.


# Enums
## Available animations for enter and leave transitions.
enum Anim {
	DEFAULT = -1,  ## Default animation set on Project Settings.
	SLIDE_LEFT = 0,  ## Slide controls to the left of screen.
	SLIDE_RIGHT = 1,  ## Slide controls to the right of screen.
	SLIDE_UP = 2,  ## Slide controls to the top of screen.
	SLIDE_DOWN = 3,  ## Slide controls to the bottom of screen.
	FADE = 4,  ## Fade controls in place.
	SCALE = 5,  ## Scale controls based on pivot center.
	SCALE_VERTICAL = 6,  ## Scale controls horizontally based on pivot center.
	SCALE_HORIZONTAL = 7,  ## Scale controls vertically based on pivot center.
	ROTATE_ZOOM_IN = 8,  ## Rotate and scale controls in, based on pivot center.
	ROTATE_ZOOM_OUT = 9,  ## Rotate and scale controls out, based on pivot center.
}

## Current transition status.
enum Status {
	OK = 0,  ## No transition being performed.
	SHOWING = 1,  ## Performing enter transition.
	HIDING = 2,  ## Performing leave transition.
}

## Boolean value used by transition properties.
enum ExportBool {
	DEFAULT = -1,  ## Default value set on Project Settings.
	TRUE = 1,  ## Enable property.
	FALSE = 0,  ## Disable property.
}


# Preloads
const DefaultValues := preload("res://addons/simple-gui-transitions/default_values.gd")


# Inner classes
class NodeInfo extends RefCounted:
	const NEAR_ZERO := Vector2.ONE * 0.001

	var node: Control
	var name: StringName
	var delay: float
	var duration: float
	var center_pivot: bool
	var tween: Tween

	func _init(
		_node: Control,
		_delay: float,
		_duration: float,
		_center_pivot: bool,
	) -> void:
		node = _node
		name = node.name
		delay = _delay
		duration = _duration
		center_pivot = _center_pivot

		set_pivot_to_center()
		node.offset_transform_visual_only = false

		reset_scale()
		reset_rotation()
		set_position(Vector2.ZERO)

	# Invalidates existing tween and creates a new one.
	func init_tween() -> void:
		if not is_instance_valid(node):
			return

		if tween and tween.is_valid():
			tween.kill()

		tween = node.create_tween()

	# Get the zero scale of node according to the animation type.
	func get_target_scale(animation: int) -> Vector2:
		match animation:
			Anim.SCALE_HORIZONTAL:
				return Vector2(0.001, 1.0)
			Anim.SCALE_VERTICAL:
				return Vector2(1.0, 0.001)
			Anim.ROTATE_ZOOM_IN:
				return NEAR_ZERO
			Anim.ROTATE_ZOOM_OUT:
				return Vector2(4.0, 4.0)

		return NEAR_ZERO

	# Get the target rotation of node according to the animation type.
	func get_target_rotation(animation: int) -> float:
		match animation:
			Anim.ROTATE_ZOOM_IN, Anim.ROTATE_ZOOM_OUT:
				return deg_to_rad(-180)

		return 0.0

	# Get the out-of-screen offset of node according to the animation type.
	func get_target_position(animation: int) -> Vector2:
		var view_size := node.get_viewport().get_visible_rect().size
		var offset := Vector2.ZERO

		match animation:
			Anim.SLIDE_LEFT:
				offset.x = -view_size.x * 2.0
			Anim.SLIDE_RIGHT:
				offset.x = view_size.x * 2.0
			Anim.SLIDE_UP:
				offset.y = -view_size.y * 2.0
			Anim.SLIDE_DOWN:
				offset.y = view_size.y * 2.0

		return offset

	# Reset offset scale to its neutral value.
	func reset_scale() -> void:
		if not is_instance_valid(node):
			return
		node.offset_transform_scale = Vector2.ONE

	# Reset offset rotation to its neutral value.
	func reset_rotation() -> void:
		if not is_instance_valid(node):
			return
		node.offset_transform_rotation = 0.0

	# Pivot is relative to the control size, so it doesn't need
	# to be recalculated when the control is resized.
	func set_pivot_to_center() -> void:
		if not is_instance_valid(node):
			return
		if center_pivot:
			node.offset_transform_pivot = Vector2.ZERO
			node.offset_transform_pivot_ratio = Vector2(0.5, 0.5)

	# Set the visual offset of the node.
	func set_position(position: Vector2) -> void:
		if not is_instance_valid(node):
			return
		node.offset_transform_position = position


# Constants
const DEBUG := false


# Variables
# Public variables
## Click to preview the enter animation with the current settings.
@export_tool_button("Preview Enter", "ArrowRight") var preview_enter_action: Callable = _editor_preview_enter

## Click to preview the leave animation with the current settings.
@export_tool_button("Preview Leave", "ArrowLeft") var preview_leave_action: Callable = _editor_preview_leave

@export_group("Transition")

## If the current layout will trigger its transition
## at startup automatically. Enabled by default.
@export var auto_start: ExportBool = ExportBool.DEFAULT

## If enabled, will fade the whole layout along with the selected animation of individual controls.
## The fade duration is based on the [code]Duration[/code] property. Enabled by default.
@export var fade_layout: ExportBool = ExportBool.DEFAULT

## The animation type of the controls when entering the screen.
@export var animation_enter := Anim.DEFAULT

## The animation type of the controls when leaving the screen.
@export var animation_leave := Anim.DEFAULT

## The total animation duration in seconds.
## A negative value such as the default [code]-0.01[/code] will make the
## transition use the default value set in Project Settings.
@export_range(-0.01, 2.0, 0.01) var duration := -0.01

## Delay ratio between transitions for each node contained in [code]Controls[/code].
## The default value is [code]0.5[/code].[br][br]
##
## - A negative value such as the default [code]-0.01[/code] will make the
## transition use the default value set in Project Settings.[br]
##
## - A delay of [code]0.0[/code] means no delay, that is, all controls
## will start and finish their animations at the same time.[br]
##
## - A delay of [code]1.0[/code] will make each control wait for the
## previous one to finish its animation to start its own.[br]
##
## - A delay between [code]0.0[/code] and [code]1.0[/code] will make
## controls intertwine animations, giving a smoother effect.
@export_range(-0.01, 1.0, 0.01) var delay := -0.01

## Transition curve of enter animations. Same as [code]Tween.TransitionType[/code].
@export_enum(
	"Default",
	"LINEAR",
	"SINE",
	"QUINT",
	"QUART",
	"QUAD",
	"EXPO",
	"ELASTIC",
	"CUBIC",
	"CIRC",
	"BOUNCE",
	"BACK"
) var transition_enter := "Default"

## Transition curve of leave animations. Same as [code]Tween.TransitionType[/code].
@export_enum(
	"Default",
	"LINEAR",
	"SINE",
	"QUINT",
	"QUART",
	"QUAD",
	"EXPO",
	"ELASTIC",
	"CUBIC",
	"CIRC",
	"BOUNCE",
	"BACK"
) var transition_leave := "Default"

## Ease curve of enter animations. Same as [code]Tween.EaseType[/code].
@export_enum(
	"Default",
	"IN",
	"OUT",
	"IN_OUT",
	"OUT_IN"
) var ease_enter := "Default"

## Ease curve of leave animations. Same as [code]Tween.EaseType[/code].
@export_enum(
	"Default",
	"IN",
	"OUT",
	"IN_OUT",
	"OUT_IN"
) var ease_leave := "Default"

@export_group("Target")

## The main layout node. It will be hidden and shown accordingly.
## Should be the topmost node of the current layout.
## If your don't set [code]Controls[/code],
## the [code]Layout[/code] itself will be animated.
## [b][color=red]Required![/color][/b]
@export_node_path("Control") var layout: NodePath:
	set(value):
		layout = value
		_layout = _get_layout()
		update_configuration_warnings()

## Optional ID of layout to trigger changes on the singleton
## [code]GuiTransitions[/code] (at method parameters named [code]id[/code]).
## If empty, will be assumed as the [code]Layout[/code] node name.
@export var layout_id := &""

## Array of individual nodes to be animated.
## The order will be taken in account to apply the animation [code]Delay[/code].
## [b]If empty, the [code]Layout[/code] itself will be animated[/b].
@export var controls: Array[NodePath] = []

## When enabled, scale animations pivot around the control's center
## (sets [code]offset_transform_pivot_ratio[/code] to [code](0.5, 0.5)[/code]).
## When disabled, the control's own [code]offset_transform_pivot[/code]
## and [code]offset_transform_pivot_ratio[/code] are respected.
@export var center_pivot: ExportBool = ExportBool.DEFAULT

# Private variables
## Parsed enter transition enum value.
var _transition_enter := Tween.TRANS_QUAD

## Parsed leave transition enum value.
var _transition_leave := Tween.TRANS_QUAD

## Parsed enter ease enum value.
var _ease_enter := Tween.EASE_IN_OUT

## Parsed leave ease enum value.
var _ease_leave := Tween.EASE_IN_OUT

## Array of NodeInfo of all controls affected by transition.
var _node_infos: Array[NodeInfo] = []

## Array of all controls affected by transition.
var _controls: Array[Control] = []

## If current transition layout is being shown.
var _is_shown := false

## Parsed transition status enum value.
var _status: int = Status.OK

## If apply transitions only to layout (no controls set).
var _layout_only := false

## True while an editor preview animation is running. Prevents simultaneous clicks on both buttons.
var _editor_preview_running := false

## Main control affected by this transition.
@onready var _layout := _get_layout()

## Cache initial layout mouse behavior recursive.
@onready var _initial_mouse_behavior_recursive: Control.MouseBehaviorRecursive = _layout.mouse_behavior_recursive \
	if _layout else Control.MouseBehaviorRecursive.MOUSE_BEHAVIOR_INHERITED

## Tweener used by this transition to perform animations.
@onready var _tween: Tween


# Built-in overrides
func _ready() -> void:
	if Engine.is_editor_hint():
		return

	_get_custom_settings()
	var temp_tween := create_tween()
	temp_tween.tween_interval(0.1)
	_transition_enter = temp_tween.get("TRANS_" + transition_enter)
	_transition_leave = temp_tween.get("TRANS_" + transition_leave)
	_ease_enter = temp_tween.get("EASE_" + ease_enter)
	_ease_leave = temp_tween.get("EASE_" + ease_leave)

	if _transition_valid():
		if not layout_id:
			layout_id = _layout.name

		if not GuiTransitions._layouts.has(layout_id):
			GuiTransitions._layouts[layout_id] = []

		GuiTransitions._layouts[layout_id].push_back(self)

		_get_node_infos()

		if auto_start:
			_apply_auto_start_hidden_state()

		if fade_layout:
			_layout.modulate.a = 0.0

		if _layout.visible and auto_start:
			await get_tree().process_frame
			_show()

	else:
		push_error("Invalid GuiTransition configuration: %s" % self.get_path())
		queue_free()


func _exit_tree() -> void:
	if Engine.is_editor_hint():
		return

	var layouts: Array = GuiTransitions._layouts.get(layout_id, [])

	if not layouts:
		return

	var index := layouts.find(self)

	if index < 0:
		return

	layouts.remove_at(index)

	if not layouts.size():
		GuiTransitions._layouts.erase(layout_id)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()

	if not layout:
		warnings.push_back("The property Layout must be set.")
	elif not get_node_or_null(layout):
		warnings.push_back("The node path set on Layout is not valid.")
	elif not get_node(layout).is_class("Control"):
		warnings.push_back("The node set on Layout must be (or derived from) a Control.")

	return warnings


# Private methods
func _get_layout() -> Control:
	if not layout or not is_node_ready():
		return null

	return get_node_or_null(layout)


# Invalidates existing tween and creates a new one.
func _init_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()

	_tween = create_tween()


## Get custom settings from project settings and apply to current instance.
func _get_custom_settings() -> void:
	var exported_bools := ["auto_start", "fade_layout", "center_pivot"]
	var exported_strings := ["transition_enter", "transition_leave", "ease_enter", "ease_leave"]
	var exported_anims := ["animation_enter", "animation_leave"]
	var exported_floats := ["duration", "delay"]

	for setting in DefaultValues.DEFAULT_SETTINGS:
		if not ProjectSettings.has_setting(setting["name"]):
			push_warning("GUI Transition setting not found on Project Settings: " + setting["name"])
			push_warning("Try disabling and re-enabling the addon to re-add missing settings")

		var prop_name: String = Array(setting["name"].split("/")).back()
		var default_value = _round_if_float(setting["value"])
		var settings_value = _round_if_float(ProjectSettings.get_setting(setting["name"]))
		var current_value = _round_if_float(self.get(prop_name))
		var result := {}

		if prop_name in exported_bools:
			result = _process_bool_value(current_value, settings_value, default_value)
			current_value = result.get("value")

		elif prop_name in exported_strings:
			result = _process_string_value(current_value, settings_value, default_value)
			current_value = result.get("value")

		elif prop_name in exported_anims:
			result = _process_anim_value(current_value, settings_value, default_value)
			current_value = result.get("value")

		elif prop_name in exported_floats:
			result = _process_float_value(current_value, settings_value, default_value)
			current_value = result.get("value")

		if result.get("use_default"):
			self.set(prop_name, settings_value if settings_value != null else default_value)
			if DEBUG: prints("GuiTransition", prop_name, "set to", settings_value, "from project settings:", self)


## Process ExportBool enum value (default, true and false).
func _process_bool_value(value: int, settings_value: bool, default_value: bool) -> Dictionary:
	var fallback_value = settings_value if settings_value != null else default_value

	if value == ExportBool.DEFAULT:
		return _get_result_dict(fallback_value, true)

	return _get_result_dict(value == ExportBool.TRUE, false)


## Process value from string dropdown (default or other).
func _process_string_value(value: String, settings_value: String, default_value: String) -> Dictionary:
	var fallback_value = settings_value if settings_value != null else default_value

	if value.to_lower() == "default":
		return _get_result_dict(fallback_value, true)

	return _get_result_dict(value if value else fallback_value, false)


## Process value from float range.
func _process_float_value(value: float, settings_value: float, default_value: float) -> Dictionary:
	var fallback_value = settings_value \
		if settings_value != null and settings_value >= 0.0 \
		else default_value

	if value < 0.0:
		return _get_result_dict(fallback_value, true)

	return _get_result_dict(value, false)


## Process Anim enum value (default or animation names).
func _process_anim_value(value: int, settings_value: int, default_value: int) -> Dictionary:
	var fallback_value = settings_value if settings_value != null else default_value

	if value == Anim.DEFAULT:
		return _get_result_dict(fallback_value, true)

	return _get_result_dict(value, false)


## Get result dict of parsed setting value.
func _get_result_dict(value, use_default: bool) -> Dictionary:
	return {
		"use_default": use_default,
		"value": value,
	}


## Handles the singleton go_to calls.
func _go_to(id := "", function = null):
	if not id:
		return

	if _transition_valid() and _layout.visible:
		if id != layout_id:
			_hide("", function)
			if _tween and _tween.is_valid():
				await _tween.finished
			GuiTransitions._for_each_layout("_show", [id])
		else:
			GuiTransitions._for_each_layout("_show", [id])


## Handles the singleton update calls.
func _update(function = null):
	if _transition_valid() and _layout.visible:

		_hide(layout_id, function)
		if _tween and _tween.is_valid():
			await _tween.finished
		_show(layout_id)


## Handles the singleton show calls.
func _show(id := ""):
	if _transition_valid() and (not id or id == layout_id) and _status == Status.OK:
		_get_node_infos()

		_layout.visible = true
		_layout.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
		_status = Status.SHOWING

		_init_tween()
		_fade_in_layout()

		for node_info in _node_infos:
			if animation_enter == Anim.FADE:
				_fade_in(node_info)
			elif animation_enter in [Anim.SCALE, Anim.SCALE_HORIZONTAL, Anim.SCALE_VERTICAL]:
				_scale_in(node_info)
			elif animation_enter in [Anim.ROTATE_ZOOM_IN, Anim.ROTATE_ZOOM_OUT]:
				_rotate_zoom_in(node_info)
			else:
				_slide_in(node_info)

		GuiTransitions.transition_started.emit(layout_id)
		GuiTransitions.show_started.emit(layout_id)

		if _tween and _tween.is_valid():
			await _tween.finished

		_layout.mouse_behavior_recursive = _initial_mouse_behavior_recursive

		_is_shown = true
		_status = Status.OK

		if GuiTransitions.is_shown(layout_id):
			GuiTransitions.transition_completed.emit(layout_id)
			GuiTransitions.show_completed.emit(layout_id)


## Handles the singleton hide calls.
func _hide(id := "", function = null):
	if _transition_valid() and _layout.visible and (not id or id == layout_id) and _status == Status.OK:
		_get_node_infos()

		_status = Status.HIDING
		_layout.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED

		_init_tween()
		_fade_out_layout()

		for node_info in _node_infos:
			if animation_leave == Anim.FADE:
				_fade_out(node_info)
			elif animation_leave in [Anim.SCALE, Anim.SCALE_HORIZONTAL, Anim.SCALE_VERTICAL]:
				_scale_out(node_info)
			elif animation_leave in [Anim.ROTATE_ZOOM_IN, Anim.ROTATE_ZOOM_OUT]:
				_rotate_zoom_out(node_info)
			else:
				_slide_out(node_info)

		GuiTransitions.transition_started.emit(layout_id)
		GuiTransitions.hide_started.emit(layout_id)

		if _tween and _tween.is_valid():
			await _tween.finished

		_layout.mouse_behavior_recursive = _initial_mouse_behavior_recursive

		if typeof(function) == TYPE_CALLABLE:
			(function as Callable).call()

		_layout.visible = false
		_is_shown = false
		_status = Status.OK

		if GuiTransitions.is_hidden(layout_id):
			GuiTransitions.transition_completed.emit(layout_id)
			GuiTransitions.hide_completed.emit(layout_id)


# Abstraction methods
## Returns if it's possible to perform transition.
func _transition_valid() -> bool:
	if not _layout:
		push_warning("A valid layout must be set on GuiTransition: %s" % get_path())
		return false

	return true


## Performs the slide in transition.
func _slide_in(node_info: NodeInfo):
	node_info.init_tween()
	if not node_info.tween or not node_info.tween.is_valid():
		return
	node_info.reset_scale()
	node_info.node.modulate.a = 0.0
	_fade_in_node(node_info)

	var start_position := node_info.get_target_position(animation_enter)
	node_info.set_position(start_position)

	if node_info.delay:
		node_info.tween.tween_interval(node_info.delay)

	node_info.tween\
		.set_trans(_transition_enter)\
		.set_ease(_ease_enter)\
		.tween_property(
			node_info.node,
			^"offset_transform_position",
			Vector2.ZERO,
			node_info.duration
		)\
		.from(start_position)


## Performs the slide out transition.
func _slide_out(node_info: NodeInfo):
	node_info.init_tween()
	if not node_info.tween or not node_info.tween.is_valid():
		return
	node_info.reset_scale()
	node_info.set_position(Vector2.ZERO)

	if node_info.delay:
		node_info.tween.tween_interval(node_info.delay)

	node_info.tween\
		.set_trans(_transition_leave)\
		.set_ease(_ease_leave)\
		.tween_property(
			node_info.node,
			^"offset_transform_position",
			node_info.get_target_position(animation_leave),
			node_info.duration
		)

	if node_info.tween and node_info.tween.is_valid():
		await node_info.tween.finished
	if is_instance_valid(node_info.node):
		node_info.node.modulate.a = 0.0


## Performs the fade in transition.
func _fade_in(node_info: NodeInfo):
	node_info.init_tween()
	if not node_info.tween or not node_info.tween.is_valid():
		return
	node_info.set_position(Vector2.ZERO)
	node_info.reset_scale()
	node_info.node.modulate.a = 0.0

	if node_info.delay:
		node_info.tween.tween_interval(node_info.delay)

	node_info.tween\
		.set_trans(_transition_enter)\
		.set_ease(_ease_enter)\
		.tween_property(node_info.node, ^"modulate:a", 1.0, node_info.duration)


## Performs the fade out transition.
func _fade_out(node_info: NodeInfo):
	node_info.init_tween()
	if not node_info.tween or not node_info.tween.is_valid():
		return
	node_info.reset_scale()

	if node_info.delay:
		node_info.tween.tween_interval(node_info.delay)

	node_info.tween\
		.set_trans(_transition_leave)\
		.set_ease(_ease_leave)\
		.tween_property(node_info.node, ^"modulate:a", 0.0, node_info.duration)


## Performs the scale in transition.
func _scale_in(node_info: NodeInfo):
	node_info.init_tween()
	if not node_info.tween or not node_info.tween.is_valid():
		return
	node_info.set_position(Vector2.ZERO)

	node_info.node.modulate.a = 0.0
	_fade_in_node(node_info)

	node_info.node.offset_transform_scale = node_info.get_target_scale(animation_enter)

	if node_info.delay:
		node_info.tween.tween_interval(node_info.delay)

	node_info.tween\
		.set_trans(_transition_enter)\
		.set_ease(_ease_enter)\
		.tween_property(node_info.node, ^"offset_transform_scale", Vector2.ONE, node_info.duration)


## Performs the scale out transition.
func _scale_out(node_info: NodeInfo):
	node_info.init_tween()
	if not node_info.tween or not node_info.tween.is_valid():
		return
	node_info.set_position(Vector2.ZERO)
	node_info.reset_scale()

	if node_info.delay:
		node_info.tween.tween_interval(node_info.delay)

	node_info.tween\
		.set_trans(_transition_leave)\
		.set_ease(_ease_leave)\
		.tween_property(
			node_info.node,
			^"offset_transform_scale",
			node_info.get_target_scale(animation_leave),
			node_info.duration
		)

	if node_info.tween and node_info.tween.is_valid():
		await node_info.tween.finished
	if is_instance_valid(node_info.node):
		node_info.node.modulate.a = 0.0


## Performs the rotate + zoom in transition.
func _rotate_zoom_in(node_info: NodeInfo):
	node_info.init_tween()
	if not node_info.tween or not node_info.tween.is_valid():
		return
	node_info.set_position(Vector2.ZERO)

	node_info.node.modulate.a = 0.0
	_fade_in_node(node_info)

	node_info.node.offset_transform_scale = node_info.get_target_scale(animation_enter)
	node_info.node.offset_transform_rotation = node_info.get_target_rotation(animation_enter)

	if node_info.delay:
		node_info.tween.tween_interval(node_info.delay)

	node_info.tween\
		.set_trans(_transition_enter)\
		.set_ease(_ease_enter)\
		.tween_property(node_info.node, ^"offset_transform_scale", Vector2.ONE, node_info.duration)

	node_info.tween\
		.set_trans(_transition_enter)\
		.set_ease(_ease_enter)\
		.set_parallel(true)\
		.tween_property(node_info.node, ^"offset_transform_rotation", 0.0, node_info.duration)


## Performs the rotate + zoom out transition.
func _rotate_zoom_out(node_info: NodeInfo):
	node_info.init_tween()
	if not node_info.tween or not node_info.tween.is_valid():
		return
	node_info.set_position(Vector2.ZERO)
	node_info.reset_scale()
	node_info.reset_rotation()
	_fade_out_node(node_info)

	if node_info.delay:
		node_info.tween.tween_interval(node_info.delay)

	node_info.tween\
		.set_trans(_transition_leave)\
		.set_ease(_ease_leave)\
		.tween_property(
			node_info.node,
			^"offset_transform_scale",
			node_info.get_target_scale(animation_leave),
			node_info.duration
		)

	node_info.tween\
		.set_trans(_transition_leave)\
		.set_ease(_ease_leave)\
		.set_parallel(true)\
		.tween_property(
			node_info.node,
			^"offset_transform_rotation",
			node_info.get_target_rotation(animation_leave),
			node_info.duration
		)

	if node_info.tween and node_info.tween.is_valid():
		await node_info.tween.finished
	if is_instance_valid(node_info.node) and not fade_layout:
		node_info.node.modulate.a = 0.0


## Gradually fade in the whole layout along with individual transitions.
func _fade_in_layout() -> void:
	if not fade_layout or _layout_only and animation_enter == Anim.FADE:
		_tween.tween_interval(duration)
		return

	_tween.tween_property(_layout, ^"modulate:a", 1.0, duration)


## Gradually fade out the whole layout along with individual transitions.
func _fade_out_layout() -> void:
	if not fade_layout or _layout_only and animation_leave == Anim.FADE:
		_tween.tween_interval(duration)
		return

	_tween.tween_property(_layout, ^"modulate:a", 0.0, duration)


## Fix of node pop-in in some cases.
## When [member fade_layout] is enabled, fades over the node's own full
## duration (and delay) instead of just a quick correction, so the node's
## opacity transition stays in sync with its own transform animation.
func _fade_in_node(node_info: NodeInfo) -> void:
	var node_duration := node_info.duration if fade_layout \
		else max(node_info.duration / 3.0, 0.09)
	var tween := node_info.node.create_tween()

	if node_info.delay:
		tween.tween_interval(node_info.delay)

	tween\
		.set_trans(_transition_enter)\
		.set_ease(_ease_enter)\
		.tween_property(node_info.node, ^"modulate:a", 1.0, node_duration)


## Fades the node out over its own full duration (and delay).
func _fade_out_node(node_info: NodeInfo) -> void:
	if not fade_layout:
		return

	var tween := node_info.node.create_tween()

	if node_info.delay:
		tween.tween_interval(node_info.delay)

	tween\
		.set_trans(_transition_leave)\
		.set_ease(_ease_leave)\
		.tween_property(node_info.node, ^"modulate:a", 0.0, node_info.duration)


## Get nodes from array of node paths set by the user.
func _get_nodes_from_containers() -> Array[Control]:
	_controls.clear()

	for node_path in controls:
		var node: Node = get_node(node_path) if node_path else null

		if node:
			_controls.push_back(node)

	var nodes: Array = _controls if _controls.size() else [_layout]
	_layout_only = _layout and not _controls.size()
	var filtered_nodes: Array[Control] = []

	for n in nodes:
		var node: Node = n

		if node and node.is_class("Control") and (not node.get_class() == "Control" or _layout_only):
			filtered_nodes.push_back(node)

	return filtered_nodes


## Get children nodes from controls array.
func _get_node_infos() -> void:
	var filtered_nodes := _get_nodes_from_containers()

	if not filtered_nodes.size():
		push_warning("No valid controls set on GuiTransition: %s" % self.get_path())

	var base_duration := duration / filtered_nodes.size()
	var inv_delay := 1.0 - delay

	_node_infos.clear()

	for _i in filtered_nodes.size():
		var i: int = _i
		var node := filtered_nodes[i]
		var current_delay := i * delay * base_duration
		var current_duration := base_duration + base_duration * inv_delay * 3

		if filtered_nodes.size() == 1:
			current_duration = duration

		if animation_enter != Anim.FADE or animation_leave != Anim.FADE:
			node.offset_transform_enabled = true

		if DEBUG: prints(JSON.stringify({
			"duration": duration,
			"inv_delay": inv_delay,
			"base_duration": base_duration,
			"current_delay": current_delay,
			"current_duration": current_duration,
			"sum": current_delay + current_duration,
		}))

		_node_infos.push_back(NodeInfo.new(
			node,
			current_delay,
			current_duration,
			center_pivot
		))


## Applies the invisible initial state to the controls when auto_start is active.
func _apply_auto_start_hidden_state() -> void:
	for _node_info in _node_infos:
		var node_info: NodeInfo = _node_info

		if is_instance_valid(node_info.node):
			node_info.node.modulate.a = 0.0


## Tool button callback. Preview enter animation.
func _editor_preview_enter() -> void:
	_editor_run_preview(true)


## Tool button callback. Preview leave animation.
func _editor_preview_leave() -> void:
	_editor_run_preview(false)


## Runs an enter or leave preview within the editor and restores initial state afterwards.
func _editor_run_preview(entering: bool) -> void:
	if not Engine.is_editor_hint():
		return
	if _editor_preview_running:
		return
	if not _transition_valid():
		return

	_editor_preview_running = true

	var snapshot := {
		"auto_start": auto_start,
		"fade_layout": fade_layout,
		"center_pivot": center_pivot,
		"transition_enter": transition_enter,
		"transition_leave": transition_leave,
		"ease_enter": ease_enter,
		"ease_leave": ease_leave,
		"duration": duration,
		"delay": delay,
	}

	var layout_snapshot := {
		"visible": _layout.visible,
		"modulate_a": _layout.modulate.a,
		"mouse_behavior_recursive": _layout.mouse_behavior_recursive,
	}

	var node_snapshots: Array[Dictionary] = []

	for node in _get_nodes_from_containers():
		if not is_instance_valid(node):
			continue

		node_snapshots.append({
			"node": node,
			"visible": node.visible,
			"modulate_a": node.modulate.a,
			"offset_transform_enabled": node.offset_transform_enabled,
			"offset_transform_visual_only": node.offset_transform_visual_only,
			"offset_transform_pivot": node.offset_transform_pivot,
			"offset_transform_pivot_ratio": node.offset_transform_pivot_ratio,
			"offset_transform_position": node.offset_transform_position,
			"offset_transform_scale": node.offset_transform_scale,
			"offset_transform_rotation": node.offset_transform_rotation,
		})

	_get_custom_settings()

	var temp_tween := create_tween()
	temp_tween.tween_interval(0.01)
	_transition_enter = temp_tween.get("TRANS_" + transition_enter)
	_transition_leave = temp_tween.get("TRANS_" + transition_leave)
	_ease_enter = temp_tween.get("EASE_" + ease_enter)
	_ease_leave = temp_tween.get("EASE_" + ease_leave)
	temp_tween.kill()

	_get_node_infos()

	_layout.visible = true
	_layout.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
	_status = Status.SHOWING if entering else Status.HIDING

	_init_tween()

	if entering:
		_fade_in_layout()
	else:
		_fade_out_layout()

	for node_info in _node_infos:
		var animation := animation_enter if entering else animation_leave

		if entering:
			if animation == Anim.FADE:
				_fade_in(node_info)
			elif animation in [Anim.SCALE, Anim.SCALE_HORIZONTAL, Anim.SCALE_VERTICAL]:
				_scale_in(node_info)
			elif animation in [Anim.ROTATE_ZOOM_IN, Anim.ROTATE_ZOOM_OUT]:
				_rotate_zoom_in(node_info)
			else:
				_slide_in(node_info)
		else:
			if animation == Anim.FADE:
				_fade_out(node_info)
			elif animation in [Anim.SCALE, Anim.SCALE_HORIZONTAL, Anim.SCALE_VERTICAL]:
				_scale_out(node_info)
			elif animation in [Anim.ROTATE_ZOOM_IN, Anim.ROTATE_ZOOM_OUT]:
				_rotate_zoom_out(node_info)
			else:
				_slide_out(node_info)

	if _tween and _tween.is_valid():
		await _tween.finished

	_editor_reset_preview_state(node_snapshots, layout_snapshot)

	for key in snapshot:
		self.set(key, snapshot[key])

	_status = Status.OK
	_editor_preview_running = false


## Resets the layout and controls back to their initial, fully visible state.
func _editor_reset_preview_state(node_snapshots: Array[Dictionary], layout_snapshot: Dictionary) -> void:
	if is_instance_valid(_layout):
		_layout.visible = layout_snapshot.get("visible", true)
		_layout.modulate.a = layout_snapshot.get("modulate_a", 1.0)
		_layout.mouse_behavior_recursive = layout_snapshot.get(
			"mouse_behavior_recursive", _initial_mouse_behavior_recursive
		)

	for node_info in _node_infos:
		if node_info.tween and node_info.tween.is_valid():
			node_info.tween.kill()

	for snap in node_snapshots:
		var node: Control = snap.get("node")

		if not is_instance_valid(node):
			continue

		node.visible = snap.get("visible", true)
		node.modulate.a = snap.get("modulate_a", 1.0)
		node.offset_transform_enabled = snap.get("offset_transform_enabled", false)
		node.offset_transform_visual_only = snap.get("offset_transform_visual_only", false)
		node.offset_transform_pivot = snap.get("offset_transform_pivot", Vector2.ZERO)
		node.offset_transform_pivot_ratio = snap.get("offset_transform_pivot_ratio", Vector2.ZERO)
		node.offset_transform_position = snap.get("offset_transform_position", Vector2.ZERO)
		node.offset_transform_scale = snap.get("offset_transform_scale", Vector2.ONE)
		node.offset_transform_rotation = snap.get("offset_transform_rotation", 0.0)


# Helper methods
## Round float value by the step of 0.01.
func _round_if_float(value):
	if typeof(value) == TYPE_FLOAT:
		return snapped(value, 0.01)

	return value
