class_name GuiTransition, "res://addons/simple-gui-transitions/icon.png"
extends Node


# Enums
enum Anim {
	SLIDE_LEFT,
	SLIDE_RIGHT,
	SLIDE_UP,
	SLIDE_DOWN,
	FADE,
	SCALE,
	SCALE_VERTICAL,
	SCALE_HORIZONTAL,
}


# Inner classes
class NodeInfo extends Reference:
	var node: Control
	var name: String
	var initial_position: Vector2
	var initial_scale: Vector2
	var initial_mouse_filter: int
	var delay: float
	var center_pivot: bool

	func _init(
		_node: Control,
		_delay: float,
		_animation_enter: int,
		_animation_leave: int,
		_auto_start: bool,
		_center_pivot: bool
	) -> void:
		node = _node
		name = node.name
		initial_position = Vector2.ZERO
		initial_scale = Vector2(node.rect_scale)
		initial_mouse_filter = node.mouse_filter
		delay = _delay
		center_pivot = _center_pivot

		var shader_animations := [
			Anim.SLIDE_LEFT,
			Anim.SLIDE_RIGHT,
			Anim.SLIDE_UP,
			Anim.SLIDE_DOWN
		]

		if _animation_enter in shader_animations or _animation_leave in shader_animations:
			node.material = MaterialTransform.duplicate()

		if _auto_start:
			node.modulate.a = 0.0

	# Set node to unclickable while in transition.
	func unset_clickable():
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Revert initial node clickable value after transition.
	func revert_clickable():
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
		var view_size := node.get_viewport().size
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

	func set_pivot_to_center() -> void:
		if center_pivot:
			node.rect_pivot_offset = node.rect_size / 2

	func set_position(value) -> void:
		var _shader := node.material as ShaderMaterial

		if _shader:
			_shader.set_shader_param("slide", value)


# Constants
const MaterialTransform := preload("res://addons/simple-gui-transitions/materials/transform.tres")
const DEFAULT_GROUP := "gui_transition"


# Variables
# Public variables
export var auto_start := true
export(Anim) var animation_enter := Anim.FADE
export(Anim) var animation_leave := Anim.FADE
export(float, 0.1, 2.0, 0.01) var duration := 0.3
export(float, 0.0, 1.0, 0.01) var delay := 0.05
export var layout_id := ""
export(NodePath) var layout: NodePath
export(Array, NodePath) var controls := []
export(NodePath) var group: NodePath
export var center_pivot := false
export(String, "IN", "OUT", "IN_OUT", "OUT_IN") var ease_type := "IN_OUT"
export(
	String,
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
) var transition_type := "QUAD"

# Private variables
var _transition := Tween.TRANS_QUAD
var _ease := Tween.EASE_IN_OUT
var _node_infos := []
var _alpha_delay := 0.09

onready var _layout: Control = get_node(layout) if layout else null
onready var _group: Control = get_node(group) if group else null
onready var _tween: Tween = Tween.new()


# Built-in overrides
func _ready() -> void:
	if Engine.editor_hint:
		return

	_transition = _tween.get("TRANS_" + transition_type)
	_ease = _tween.get("EASE_" + ease_type)

	add_child(_tween)
	add_to_group(DEFAULT_GROUP)

	if _transition_valid():
		if not layout_id:
			layout_id = _layout.name

		_get_node_infos()

		if _layout.visible and auto_start:
			_show()


# Private methods
# Handles the singleton go_to calls.
func _go_to(id := "", function: FuncRef = null, args := []):
	if not id:
		return

	if _transition_valid() and _layout.visible:
		if id != layout_id:
			_hide("", function, args)
			yield(_tween, "tween_all_completed")
			get_tree().call_group(DEFAULT_GROUP, "_show", id)
		else:
			get_tree().call_group(DEFAULT_GROUP, "_show", id)


# Handles the singleton update calls.
func _update(function: FuncRef = null, args := []):
	if _transition_valid() and _layout.visible:

		_hide(layout_id, function, args)
		yield(_tween, "tween_all_completed")
		_show(layout_id)


# Handles the singleton show calls.
func _show(id := ""):
	if _transition_valid() and (not id or id == layout_id):
		for _node_info in _node_infos:
			var node_info: NodeInfo = _node_info

			if animation_enter == Anim.FADE:
				_fade_in(node_info)
			elif animation_enter in [Anim.SCALE, Anim.SCALE_HORIZONTAL, Anim.SCALE_VERTICAL]:
				_scale_in(node_info)
			else:
				_slide_in(node_info)

		_tween.start()
		yield(_tween, "tween_all_completed")
		GuiTransitions.emit_signal("show_completed")


# Handles the singleton hide calls.
func _hide(id := "", function: FuncRef = null, args := []):
	if _transition_valid() and _layout.visible and (not id or id == layout_id):
		for node_info in _node_infos:
			if animation_leave == Anim.FADE:
				_fade_out(node_info)
			elif animation_leave in [Anim.SCALE, Anim.SCALE_HORIZONTAL, Anim.SCALE_VERTICAL]:
				_scale_out(node_info)
			else:
				_slide_out(node_info)

		_tween.start()
		yield(_tween, "tween_all_completed")

		if function:
			function.call_funcv(args)

		GuiTransitions.emit_signal("hide_completed")
		_layout.visible = false


# Abstraction methods
# Returns if it's possible to perform transition.
func _transition_valid() -> bool:
	return (controls.size() or _group) and layout


# Performs the slide in transition.
func _slide_in(node_info: NodeInfo):
	_layout.visible = true

	# Bring alpha up
	_tween.interpolate_property(
		node_info.node, "modulate:a",
		0.0, 1.0,
		_alpha_delay,
		Tween.TRANS_QUAD,
		Tween.EASE_IN_OUT,
		node_info.delay
	)

	_tween.interpolate_method(
		node_info, "set_position",
		node_info.get_target_position(animation_enter), node_info.initial_position,
		duration,
		_transition,
		_ease,
		node_info.delay
	)

	node_info.unset_clickable()
	yield(_tween, "tween_all_completed")
	node_info.revert_clickable()


# Performs the slide out transition.
func _slide_out(node_info: NodeInfo):
	node_info.node.rect_min_size = Vector2(1, 1)
	node_info.node.rect_min_size = Vector2.ZERO

	_tween.interpolate_method(
		node_info, "set_position",
		node_info.initial_position, node_info.get_target_position(animation_leave),
		duration,
		_transition,
		_ease,
		node_info.delay
	)

	node_info.unset_clickable()
	yield(_tween, "tween_all_completed")
	node_info.node.modulate.a = 0.0
	_layout.visible = false


# Performs the fade in transition.
func _fade_in(node_info: NodeInfo):
	_layout.visible = true

	_tween.interpolate_property(
		node_info.node, "modulate:a",
		0.0, 1.0,
		duration,
		_transition,
		_ease,
		node_info.delay
	)
	node_info.unset_clickable()
	yield(_tween, "tween_all_completed")
	node_info.revert_clickable()


# Performs the fade out transition.
func _fade_out(node_info: NodeInfo):
	_tween.interpolate_property(
		node_info.node, "modulate:a",
		1.0, 0.0,
		duration,
		_transition,
		_ease,
		node_info.delay
	)
	node_info.unset_clickable()


# Performs the scale in transition.
func _scale_in(node_info: NodeInfo):
	_layout.visible = true

	# Bring alpha up
	_tween.interpolate_property(
		node_info.node, "modulate:a",
		0.0, 1.0,
		_alpha_delay,
		Tween.TRANS_QUAD,
		Tween.EASE_IN_OUT,
		node_info.delay
	)

	node_info.set_pivot_to_center()

	_tween.interpolate_property(
		node_info.node, "rect_scale",
		node_info.get_target_scale(animation_enter), node_info.initial_scale,
		duration,
		_transition,
		_ease,
		node_info.delay
	)
	node_info.unset_clickable()
	yield(_tween, "tween_all_completed")
	node_info.revert_clickable()


# Performs the scale out transition.
func _scale_out(node_info: NodeInfo):
	var initial_scale := node_info.node.rect_scale as Vector2

	node_info.set_pivot_to_center()

	_tween.interpolate_property(
		node_info.node, "rect_scale",
		initial_scale, node_info.get_target_scale(animation_leave),
		duration,
		_transition,
		_ease,
		node_info.delay
	)

	node_info.unset_clickable()
	yield(_tween, "tween_all_completed")
	node_info.node.modulate.a = 0.0
	_layout.visible = false


# Get children nodes from transition group.
func _get_node_infos():
	for i in range(controls.size()):
		controls[i] = get_node(controls[i]) if controls[i] else null

	var i := 0
	var _nodes := controls if controls.size() else _group.get_children()

	_node_infos.clear()

	for _node in _nodes:
		if _node and _node.is_class("Control") and not _node.get_class() == "Control":
			var node_info := NodeInfo.new(
				_node,
				i * delay,
				animation_enter,
				animation_leave,
				auto_start,
				center_pivot
			)
			_node_infos.push_back(node_info)
			i += 1
