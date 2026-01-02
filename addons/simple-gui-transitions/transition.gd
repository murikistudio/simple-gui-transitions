@icon("res://addons/simple-gui-transitions/icon.png")
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
const MaterialTransform := preload("res://addons/simple-gui-transitions/materials/transform.tres")
const DefaultValues := preload("res://addons/simple-gui-transitions/default_values.gd")


# Inner classes
class NodeInfo extends RefCounted:
	var node: Control
	var name: String
	var initial_position: Vector2
	var initial_scale: Vector2
	var initial_mouse_filter: int
	var initial_anchor_h: Vector2
	var initial_anchor_v: Vector2
	var delay: float
	var duration: float
	var center_pivot: bool
	var tween: Tween
	var layout_only: bool

	func _init(
		_node: Control,
		_delay: float,
		_duration: float,
		_animation_enter: int,
		_animation_leave: int,
		_auto_start: bool,
		_center_pivot: bool,
		_layout_only: bool
	) -> void:
		node = _node
		name = node.name
		initial_position = Vector2.ZERO
		initial_scale = Vector2(node.scale)
		initial_mouse_filter = node.mouse_filter
		delay = _delay
		duration = _duration
		center_pivot = _center_pivot
		layout_only = _layout_only

		initial_anchor_h = Vector2(node.anchor_left, node.anchor_right)
		initial_anchor_v = Vector2(node.anchor_top, node.anchor_bottom)

		var shader_animations := [
			Anim.SLIDE_LEFT,
			Anim.SLIDE_RIGHT,
			Anim.SLIDE_UP,
			Anim.SLIDE_DOWN
		]

		if not _layout_only and (_animation_enter in shader_animations or _animation_leave in shader_animations):
			node.material = MaterialTransform.duplicate()

		if _auto_start:
			node.modulate.a = 0.0

		set_pivot_to_center()

	# Invalidates existing tween and creates a new one.
	func init_tween() -> void:
		if not is_instance_valid(node):
			return

		if tween and tween.is_valid():
			tween.kill()

		tween = node.create_tween()

	# Set node to unclickable while in transition.
	func unset_clickable():
		if not is_instance_valid(node):
			return
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Revert initial node clickable value after transition.
	func revert_clickable():
		if not is_instance_valid(node):
			return
		node.mouse_filter = initial_mouse_filter

	# Get the zero scale of node according to the animation type.
	func get_target_scale(animation: int) -> Vector2:
		var target_scale := Vector2.ZERO

		if animation == Anim.SCALE_HORIZONTAL:
			target_scale.y = initial_scale.y

		elif animation == Anim.SCALE_VERTICAL:
			target_scale.x = initial_scale.x

		return target_scale

	# Get the out-of-screen position of node according to the animation type.
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

	# Reset node scale to initial values.
	func reset_scale() -> void:
		if not is_instance_valid(node):
			return
		node.scale = initial_scale

	# Reset node anchors to initial values.
	func reset_anchors(direction: String) -> void:
		if not is_instance_valid(node):
			return
		if direction in ["both", "h"]:
			node.anchor_left = initial_anchor_h.x
			node.anchor_right = initial_anchor_h.y
		if direction in ["both", "v"]:
			node.anchor_top = initial_anchor_v.x
			node.anchor_bottom = initial_anchor_v.y

	# Get the out-of-screen anchor factor of node according to the animation type.
	func get_target_anchor(animation: int) -> Vector2:
		var offset := Vector2.ZERO

		match animation:
			Anim.SLIDE_LEFT:
				offset = Vector2(initial_anchor_h.x - 1.0, initial_anchor_h.y - 1.0)
			Anim.SLIDE_RIGHT:
				offset = Vector2(initial_anchor_h.x + 1.0, initial_anchor_h.y + 1.0)
			Anim.SLIDE_UP:
				offset = Vector2(initial_anchor_v.x - 1.0, initial_anchor_v.y - 1.0)
			Anim.SLIDE_DOWN:
				offset = Vector2(initial_anchor_v.x + 1.0, initial_anchor_v.y + 1.0)

		return offset

	func set_pivot_to_center() -> void:
		if not is_instance_valid(node):
			return
		if center_pivot:
			node.pivot_offset = node.size / 2

	func set_position(position: Vector2) -> void:
		if not is_instance_valid(node):
			return
		var _shader := node.material as ShaderMaterial

		if _shader:
			_shader.set_shader_parameter("slide", position)


# Constants
const DEBUG := false


# Variables
# Public variables
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

## Delay ratio between transitions for each node contained
## in [code]Group[/code] or [code]Controls[/code].
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

## Transition curve of the animations. Same as [code]Tween.TransitionType[/code].
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
) var transition_type := "Default"

## Ease curve of the animations. Same as [code]Tween.EaseType[/code].
@export_enum(
	"Default",
	"IN",
	"OUT",
	"IN_OUT",
	"OUT_IN"
) var ease_type := "Default"

@export_group("Target")

## The main layout node. It will be hidden and shown accordingly.
## Should be the topmost node of the current layout.
## If your don't set [code]Controls[/code] or [code]Group[/code],
## the [code]Layout[/code] itself will be animated.
## [b][color=red]Required![/color][/b]
@export var layout: NodePath

## Optional ID of layout to trigger changes on the singleton
## [code]GuiTransitions[/code] (at method parameters named [code]id[/code]).
## If empty, will be assumed as the [code]Layout[/code] node name.
@export var layout_id := ""

## Array of individual nodes to be animated.
## The order will be taken in account to apply the animation [code]Delay[/code].
## [b]If empty, a [code]Group[/code] must be set[/b].
@export var controls: Array[NodePath] = []

## A node with children controls to be animated in sequence.
## The order will be taken in account to apply the animation [code]Delay[/code].
## Example: a [code]HBoxContainer[/code] or [code]VBoxContainer[/code] with
## several buttons as children will allow to animate all buttons one by one.
## [b]If not set, [code]Controls[/code] must be selected.[/b]
@export var group: NodePath

## When [code]Animation[/code] Enter or [code]Animation Leave[/code]
## is one of the scale animations, it will center the control's
## [code]pivot_offset[/code] property.
@export var center_pivot: ExportBool = ExportBool.DEFAULT

# Private variables
## Parsed transition enum value.
var _transition := Tween.TRANS_QUAD

## Parsed ease enum value.
var _ease := Tween.EASE_IN_OUT

## Array of NodeInfo of all controls affected by transition.
var _node_infos: Array[NodeInfo] = []

## Array of all controls affected by transition.
var _controls: Array[Control] = []

## If current transition layout is being shown.
var _is_shown := false

## Parsed transition status enum value.
var _status: int = Status.OK

## If apply transitions only to layout (no group or controls set).
var _layout_only := false

## Main control affected by this transition.
@onready var _layout: Control = get_node(layout) if layout else null

## Control containing child controls affected by this transition.
@onready var _group: Control = get_node(group) if group else null

## Tweener used by this transition to perform animations.
@onready var _tween: Tween


# Built-in overrides
func _ready() -> void:
	if Engine.is_editor_hint():
		return

	_get_custom_settings()
	var temp_tween := create_tween()
	temp_tween.tween_interval(0.1)
	_transition = temp_tween.get("TRANS_" + transition_type)
	_ease = temp_tween.get("EASE_" + ease_type)

	if _transition_valid():
		if not layout_id:
			layout_id = _layout.name

		if not GuiTransitions._layouts.has(layout_id):
			GuiTransitions._layouts[layout_id] = []

		GuiTransitions._layouts[layout_id].push_back(self)

		_get_node_infos()

		if fade_layout:
			_layout.modulate.a = 0.0

		if _layout.visible and auto_start:
			await get_tree().process_frame
			_show()

	else:
		push_error("Invalid GuiTransition configuration: %s" % self.get_path())
		queue_free()


# Invalidates existing tween and creates a new one.
func _init_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()

	_tween = create_tween()


# Remove reference from singleton.
func _exit_tree() -> void:
	var layouts: Array = GuiTransitions._layouts.get(layout_id, [])

	if not layouts:
		return

	var index := layouts.find(self)

	if index < 0:
		return

	layouts.remove_at(index)

	if not layouts.size():
		GuiTransitions._layouts.erase(layout_id)


# Private methods
## Get custom settings from project settings and apply to current instance.
func _get_custom_settings() -> void:
	var exported_bools := ["auto_start", "fade_layout", "center_pivot"]
	var exported_strings := ["transition_type", "ease_type"]
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
		_layout.visible = true
		_status = Status.SHOWING

		_init_tween()
		_fade_in_layout()

		for _node_info in _node_infos:
			var node_info: NodeInfo = _node_info

			if animation_enter == Anim.FADE:
				_fade_in(node_info)
			elif animation_enter in [Anim.SCALE, Anim.SCALE_HORIZONTAL, Anim.SCALE_VERTICAL]:
				_scale_in(node_info)
			else:
				_slide_in(node_info)

		GuiTransitions.transition_started.emit()
		GuiTransitions.show_started.emit()

		if _tween and _tween.is_valid():
			await _tween.finished

		_is_shown = true
		_status = Status.OK

		if GuiTransitions.is_shown(layout_id):
			GuiTransitions.transition_completed.emit()
			GuiTransitions.show_completed.emit()


## Handles the singleton hide calls.
func _hide(id := "", function = null):
	if _transition_valid() and _layout.visible and (not id or id == layout_id) and _status == Status.OK:
		_status = Status.HIDING

		_init_tween()
		_fade_out_layout()

		for node_info in _node_infos:
			if animation_leave == Anim.FADE:
				_fade_out(node_info)
			elif animation_leave in [Anim.SCALE, Anim.SCALE_HORIZONTAL, Anim.SCALE_VERTICAL]:
				_scale_out(node_info)
			else:
				_slide_out(node_info)

		GuiTransitions.transition_started.emit()
		GuiTransitions.hide_started.emit()

		if _tween and _tween.is_valid():
			await _tween.finished

		if typeof(function) == TYPE_CALLABLE:
			(function as Callable).call()

		_layout.visible = false
		_is_shown = false
		_status = Status.OK

		if GuiTransitions.is_hidden(layout_id):
			GuiTransitions.transition_completed.emit()
			GuiTransitions.hide_completed.emit()


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

	if node_info.delay:
		node_info.tween.tween_interval(node_info.delay)

	if _layout_only:
		var anchor_x := "anchor_left" if animation_enter in [Anim.SLIDE_LEFT, Anim.SLIDE_RIGHT] else "anchor_top"
		var anchor_y := "anchor_right" if animation_enter in [Anim.SLIDE_LEFT, Anim.SLIDE_RIGHT] else "anchor_bottom"
		var target_anchor := node_info.get_target_anchor(animation_enter)
		node_info.node.set(anchor_x, target_anchor.x)
		node_info.node.set(anchor_y, target_anchor.y)
		node_info.reset_anchors("v" if animation_enter in [Anim.SLIDE_LEFT, Anim.SLIDE_RIGHT] else "h")

		node_info.tween\
			.set_trans(_transition)\
			.set_ease(_ease)\
			.tween_property(
				node_info.node,
				anchor_x, 0.0,
				node_info.duration
			)
		node_info.tween\
			.parallel()\
			.set_trans(_transition)\
			.set_ease(_ease)\
			.tween_property(
				node_info.node,
				anchor_y, 1.0,
				node_info.duration
			)
	else:
		node_info.tween\
			.set_trans(_transition)\
			.set_ease(_ease)\
			.tween_method(
				node_info.set_position,
				node_info.get_target_position(animation_enter),
				node_info.initial_position,
				node_info.duration
			)

	node_info.unset_clickable()
	if node_info.tween and node_info.tween.is_valid():
		await node_info.tween.finished
	node_info.revert_clickable()


## Performs the slide out transition.
func _slide_out(node_info: NodeInfo):
	node_info.init_tween()
	if not node_info.tween or not node_info.tween.is_valid():
		return
	node_info.reset_scale()
	node_info.node.custom_minimum_size = Vector2(1, 1)
	node_info.node.custom_minimum_size = Vector2.ZERO

	if node_info.delay:
		node_info.tween.tween_interval(node_info.delay)

	if _layout_only:
		var anchor_x := "anchor_left" if animation_leave in [Anim.SLIDE_LEFT, Anim.SLIDE_RIGHT] else "anchor_top"
		var anchor_y := "anchor_right" if animation_leave in [Anim.SLIDE_LEFT, Anim.SLIDE_RIGHT] else "anchor_bottom"
		var target_anchor := node_info.get_target_anchor(animation_leave)
		node_info.reset_anchors("both")

		node_info.tween\
			.set_trans(_transition)\
			.set_ease(_ease)\
			.tween_property(
				node_info.node,
				anchor_x, target_anchor.x,
				node_info.duration
			)
		node_info.tween\
			.parallel()\
			.set_trans(_transition)\
			.set_ease(_ease)\
				.tween_property(
				node_info.node,
				anchor_y, target_anchor.y,
				node_info.duration
			)
	else:
		node_info.tween\
			.set_trans(_transition)\
			.set_ease(_ease)\
			.tween_method(
				node_info.set_position,
				node_info.initial_position,
				node_info.get_target_position(animation_leave),
				node_info.duration
			)

	node_info.unset_clickable()
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
	node_info.reset_anchors("both")
	node_info.reset_scale()
	node_info.node.modulate.a = 0.0

	if node_info.delay:
		node_info.tween.tween_interval(node_info.delay)

	node_info.tween\
		.set_trans(_transition)\
		.set_ease(_ease)\
		.tween_property(node_info.node, "modulate:a", 1.0, node_info.duration)

	node_info.unset_clickable()
	if node_info.tween and node_info.tween.is_valid():
		await node_info.tween.finished
	node_info.revert_clickable()


## Performs the fade out transition.
func _fade_out(node_info: NodeInfo):
	node_info.init_tween()
	if not node_info.tween or not node_info.tween.is_valid():
		return
	node_info.reset_anchors("both")
	node_info.reset_scale()

	if node_info.delay:
		node_info.tween.tween_interval(node_info.delay)

	node_info.tween\
		.set_trans(_transition)\
		.set_ease(_ease)\
		.tween_property(node_info.node, "modulate:a", 0.0, node_info.duration)

	node_info.unset_clickable()


## Performs the scale in transition.
func _scale_in(node_info: NodeInfo):
	node_info.init_tween()
	if not node_info.tween or not node_info.tween.is_valid():
		return
	node_info.set_position(Vector2.ZERO)
	node_info.reset_anchors("both")

	node_info.node.modulate.a = 0.0
	_fade_in_node(node_info)

	node_info.tween.tween_callback(node_info.set_pivot_to_center)
	node_info.tween.tween_callback(node_info.node.set.bind("scale", node_info.get_target_scale(animation_enter)))

	if node_info.delay:
		node_info.tween.tween_interval(node_info.delay)

	node_info.tween\
		.set_trans(_transition)\
		.set_ease(_ease)\
		.tween_property(node_info.node, "scale", node_info.initial_scale, node_info.duration)

	node_info.unset_clickable()

	if node_info.tween and node_info.tween.is_valid():
		await node_info.tween.finished
	node_info.revert_clickable()


## Performs the scale out transition.
func _scale_out(node_info: NodeInfo):
	node_info.init_tween()
	if not node_info.tween or not node_info.tween.is_valid():
		return
	node_info.reset_anchors("both")
	node_info.reset_scale()

	node_info.tween.tween_callback(node_info.set_pivot_to_center)
	node_info.tween.tween_callback(node_info.node.set.bind("scale", node_info.initial_scale))

	if node_info.delay:
		node_info.tween.tween_interval(node_info.delay)

	node_info.tween\
		.set_trans(_transition)\
		.set_ease(_ease)\
		.tween_property(node_info.node, "scale", node_info.get_target_scale(animation_leave), node_info.duration)

	node_info.unset_clickable()
	if node_info.tween and node_info.tween.is_valid():
		await node_info.tween.finished
	if is_instance_valid(node_info.node):
		node_info.node.modulate.a = 0.0


## Gradually fade in the whole layout along with individual transitions.
func _fade_in_layout() -> void:
	if not fade_layout or _layout_only and animation_enter == Anim.FADE:
		_tween.tween_interval(duration)
		return

	_tween.tween_property(_layout, "modulate:a", 1.0, duration)


## Gradually fade out the whole layout along with individual transitions.
func _fade_out_layout() -> void:
	if not fade_layout or _layout_only and animation_leave == Anim.FADE:
		_tween.tween_interval(duration)
		return

	_tween.tween_property(_layout, "modulate:a", 0.0, duration)


## Fix of node pop-in in some cases.
func _fade_in_node(node_info: NodeInfo) -> void:
	var node_duration := max(node_info.duration / 3.0, 0.09)
	var tween := node_info.node.create_tween()

	if node_info.delay:
		tween.tween_interval(node_info.delay)

	tween.tween_property(node_info.node, "modulate:a", 1.0, node_duration)


## Get nodes from group or array of node paths set by the user.
func _get_nodes_from_containers() -> Array[Control]:
	_controls.clear()

	for node_path in controls:
		var node: Node = get_node(node_path) if node_path else null

		if node:
			_controls.push_back(node)

	var nodes: Array = _controls if _controls.size() \
		else _group.get_children() if _group \
		else [_layout]
	_layout_only = _layout and not _controls.size() and not _group
	var filtered_nodes: Array[Control] = []

	for n in nodes:
		var node: Node = n

		if node and node.is_class("Control") and (not node.get_class() == "Control" or _layout_only):
			filtered_nodes.push_back(node)

	return filtered_nodes


## Get children nodes from group children or controls array.
func _get_node_infos() -> void:
	var filtered_nodes := _get_nodes_from_containers()

	if not filtered_nodes.size():
		push_warning("No valid group children or controls set on GuiTransition: %s" % self.get_path())

	var base_duration := duration / filtered_nodes.size()
	var inv_delay := 1.0 - delay

	_node_infos.clear()

	for _i in filtered_nodes.size():
		var i: int = _i
		var current_delay := i * delay * base_duration
		var current_duration := base_duration + base_duration * inv_delay * 3

		if filtered_nodes.size() == 1:
			current_duration = duration

		if DEBUG: prints(JSON.stringify({
			"duration": duration,
			"inv_delay": inv_delay,
			"base_duration": base_duration,
			"current_delay": current_delay,
			"current_duration": current_duration,
			"sum": current_delay + current_duration,
		}))

		_node_infos.push_back(NodeInfo.new(
			filtered_nodes[i],
			current_delay,
			current_duration,
			animation_enter,
			animation_leave,
			auto_start,
			center_pivot,
			_layout_only
		))


# Helper methods
## Round float value by the step of 0.01.
func _round_if_float(value):
	if typeof(value) == TYPE_FLOAT:
		return snapped(value, 0.01)

	return value
