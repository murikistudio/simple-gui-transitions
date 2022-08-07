class_name GuiTransition, "res://addons/simple-gui-transitions/icon.png"
extends Node


enum Anim {
	SLIDE_LEFT,
	SLIDE_RIGHT,
	SLIDE_UP,
	SLIDE_DOWN,
	FADE,
}

const DEFAULT_GROUP := "gui_transition"

var _transition := Tween.TRANS_QUAD
var _ease := Tween.EASE_IN_OUT
var nodes := []
var alpha_delay := 0.09

export var auto_start := true
export var layout_id := ""
export(Anim) var animation := Anim.SLIDE_LEFT
export(float, 0.1, 2.0, 0.01) var duration := 0.3
export(NodePath) var _layout: NodePath
export(NodePath) var _group: NodePath
export(float, 0.0, 1.0, 0.01) var delay := 0.05
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
export(
	String,
	"IN",
	"OUT",
	"IN_OUT",
	"OUT_IN"
	) var ease_type := "IN_OUT"

onready var layout: Control = get_node(_layout) if _layout else null
onready var group: Control = get_node(_group) if _group else null
onready var tween: Tween = Tween.new()


func _ready() -> void:
	_transition = tween.get("TRANS_" + transition_type)
	_ease = tween.get("EASE_" + ease_type)

	add_child(tween)
	add_to_group(DEFAULT_GROUP)

	if _transition_valid():
		if not layout_id:
			layout_id = layout.name

		_get_group_nodes()
		_init_children()

		if layout.visible and auto_start:
			_show()


# Private methods
func _go_to(id := "", function: FuncRef = null, args := []):
	if not id:
		return

	if _transition_valid() and layout.visible:
		if id != layout_id:
			_hide("", function, args)
			yield(tween, "tween_all_completed")
			get_tree().call_group(DEFAULT_GROUP, "_show", id)
		else:
			get_tree().call_group(DEFAULT_GROUP, "_show", id)


func _update(function: FuncRef = null, args := []):
	if _transition_valid() and layout.visible:

		_hide(layout_id, function, args)
		yield(tween, "tween_all_completed")
		_show(layout_id)


func _show(id := ""):
	if _transition_valid() and (not id or id == layout_id):
		for node_info in nodes:
			if animation == Anim.FADE:
				_fade_in(node_info)
			else:
				_slide_in(node_info)
		tween.start()
		yield(tween, "tween_all_completed")
		GuiTransitions.emit_signal("show_completed")


func _hide(id := "", function: FuncRef = null, args := []):
	if _transition_valid() and layout.visible and (not id or id == layout_id):
		for node_info in nodes:
			if animation == Anim.FADE:
				_fade_out(node_info)
			else:
				_slide_out(node_info)

		tween.start()
		yield(tween, "tween_all_completed")

		if function:
			function.call_funcv(args)

		GuiTransitions.emit_signal("hide_completed")
		layout.visible = false


# Abstraction methods
func _transition_valid() -> bool:
	return group and layout


func _slide_in(node_info: Dictionary):
	var node: Control = node_info.node

	layout.visible = true

	# Bring alpha up
	tween.interpolate_property(
		node, "modulate:a",
		0.0, 1.0,
		alpha_delay,
		Tween.TRANS_QUAD,
		Tween.EASE_IN_OUT,
		node_info.delay
	)

	yield(get_tree(), "idle_frame")

	var initial_position := node.rect_position as Vector2
	var target_position := _get_target_position(node.rect_position)

	tween.interpolate_property(
		node, "rect_position",
		target_position, initial_position,
		duration,
		_transition,
		_ease,
		node_info.delay
	)
	_unset_clickable(node_info)
	yield(tween, "tween_all_completed")
	_revert_clickable(node_info)


func _slide_out(node_info: Dictionary):
	var node: Control = node_info.node

	node.rect_min_size = Vector2(1, 1)
	node.rect_min_size = Vector2.ZERO

	var initial_position := node.rect_position as Vector2
	var target_position := _get_target_position(node.rect_position)

	tween.interpolate_property(
		node, "rect_position",
		initial_position, target_position,
		duration,
		_transition,
		_ease,
		node_info.delay
	)
	_unset_clickable(node_info)
	yield(tween, "tween_all_completed")
	node.modulate.a = 0.0
	layout.visible = false


func _fade_in(node_info: Dictionary):
	layout.visible = true

	tween.interpolate_property(
		node_info.node, "modulate:a",
		0.0, 1.0,
		duration,
		_transition,
		_ease,
		node_info.delay
	)
	_unset_clickable(node_info)
	yield(tween, "tween_all_completed")
	_revert_clickable(node_info)


func _fade_out(node_info: Dictionary):
	tween.interpolate_property(
		node_info.node, "modulate:a",
		1.0, 0.0,
		duration,
		_transition,
		_ease,
		node_info.delay
	)
	_unset_clickable(node_info)


# Helpers
func _get_group_nodes():
	nodes.clear()
	var i := 0

	for child in group.get_children():
		if child.is_class("Control") and not child.get_class() == "Control":
			var node_info := _get_node_info(child, i)
			nodes.push_back(node_info)
			i += 1


func _get_node_info(node: Control, index := 0) -> Dictionary:
	return {
		"node": node,
		"name": node.name,
		"initial_position": Vector2(node.rect_position),
		"initial_mouse_filter": node.mouse_filter,
		"delay": index * delay,
	}


func _get_target_position(initial_position: Vector2) -> Vector2:
	var view_size := get_viewport().size
	var offset := Vector2.ZERO

	match animation:
		Anim.SLIDE_LEFT:
			offset.x = initial_position.x - view_size.x
		Anim.SLIDE_RIGHT:
			offset.x = initial_position.x + view_size.x
		Anim.SLIDE_UP:
			offset.y = -view_size.y
		Anim.SLIDE_DOWN:
			offset.y = view_size.y + initial_position.y

	return initial_position + offset


func _unset_clickable(node_info: Dictionary):
	node_info.node.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _revert_clickable(node_info: Dictionary):
	node_info.node.mouse_filter = node_info.initial_mouse_filter


func _init_children():
	if auto_start:
		for node_info in nodes:
			node_info.node.modulate.a = 0.0
