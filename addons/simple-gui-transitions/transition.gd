class_name GuiTransition, "res://addons/simple-gui-transitions/icon.png"
extends Tween


enum Anim {
	SLIDE_LEFT,
	SLIDE_RIGHT,
	SLIDE_UP,
	SLIDE_DOWN,
	FADE,
}

const DEFAULT_TRANS := Tween.TRANS_QUAD
const DEFAULT_EASE := Tween.EASE_IN_OUT

var nodes := []

export var layout_id := ""
export(Anim) var animation := Anim.SLIDE_LEFT
export(NodePath) var _layout: NodePath
export(NodePath) var _group: NodePath
export(float, 0.0, 1.0, 0.01) var delay := 0.0
export(float, 0.0, 1.0, 0.01) var alpha_delay := 0.1
export(float, 0.1, 2.0, 0.01) var duration := 0.5

onready var layout: Control = get_node(_layout) if _layout else null
onready var group: Control = get_node(_group) if _group else null


func _ready() -> void:
	add_to_group("transition")

	if _transition_valid():
		if not layout_id:
			layout_id = layout.name

		_get_group_nodes()
		_init_children()

		if layout.visible:
			_show()


# Public static methods
static func go_to(owner: Node, id := "", function: FuncRef = null, args := []):
	owner.get_tree().call_group("transition", "_go_to", id, function, args)


static func update(owner: Node, function: FuncRef = null, args := []):
	owner.get_tree().call_group("transition", "_update", function, args)


static func show(owner: Node, id := ""):
	owner.get_tree().call_group("transition", "_show", id)


static func hide(owner: Node, id := ""):
	owner.get_tree().call_group("transition", "_hide", id)


# Private methods
func _go_to(id := "", function: FuncRef = null, args := []):
	if not id:
		return

	if _transition_valid() and layout.visible:
		if id != layout_id:
			_hide()
			yield(self, "tween_all_completed")

			if function:
				function.call_funcv(args)

			get_tree().call_group("transition", "_show", id)


func _update(function: FuncRef = null, args := []):
	if _transition_valid() and layout.visible:

		_hide(layout_id)
		yield(self, "tween_all_completed")

		if function:
			function.call_funcv(args)

		_show(layout_id)


func _show(id := ""):
	if _transition_valid() and (not id or id == layout_id):
		for node_info in nodes:
			if animation == Anim.FADE:
				_fade_in(node_info)
			else:
				_slide_in(node_info)
		start()


func _hide(id := ""):
	if _transition_valid() and layout.visible and (not id or id == layout_id):
		for node_info in nodes:
			if animation == Anim.FADE:
				_fade_out(node_info)
			else:
				_slide_out(node_info)

		start()
		yield(self, "tween_all_completed")
		layout.visible = false


# Abstraction methods
func _transition_valid() -> bool:
	return group and layout


func _slide_in(node_info: Dictionary):
	layout.visible = true

	# Bring alpha up
	interpolate_property(
		node_info.node, "modulate:a",
		0.0, 1.0,
		alpha_delay,
		Tween.TRANS_QUAD,
		Tween.EASE_IN_OUT,
		node_info.delay
	)

#	var initial_position := node_info.node.rect_position as Vector2
	var target_position := _get_target_position(node_info.node.rect_position)

	interpolate_property(
		node_info.node, "rect_position",
		target_position, node_info.initial_position,
		duration,
		DEFAULT_TRANS,
		DEFAULT_EASE,
		node_info.delay
	)
	_unset_clickable(node_info)
	yield(self, "tween_all_completed")
	_revert_clickable(node_info)


func _slide_out(node_info: Dictionary):
	node_info.node.rect_min_size = Vector2(1, 1)
	node_info.node.rect_min_size = Vector2.ZERO

	var initial_position := node_info.node.rect_position as Vector2
	var target_position := _get_target_position(node_info.node.rect_position)

	interpolate_property(
		node_info.node, "rect_position",
		initial_position, target_position,
		duration,
		DEFAULT_TRANS,
		DEFAULT_EASE,
		node_info.delay
	)
	_unset_clickable(node_info)
	yield(self, "tween_all_completed")
	node_info.node.modulate.a = 0.0
	layout.visible = false


func _fade_in(node_info: Dictionary):
	layout.visible = true

	interpolate_property(
		node_info.node, "modulate:a",
		0.0, 1.0,
		duration,
		DEFAULT_TRANS,
		DEFAULT_EASE,
		node_info.delay
	)
	_unset_clickable(node_info)
	yield(self, "tween_all_completed")
	_revert_clickable(node_info)


func _fade_out(node_info: Dictionary):
	interpolate_property(
		node_info.node, "modulate:a",
		1.0, 0.0,
		duration,
		DEFAULT_TRANS,
		DEFAULT_EASE,
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
	for node_info in nodes:
		node_info.node.modulate.a = 0.0
