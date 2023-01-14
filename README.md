<p align="center">
  <img height="128" alt="Simple GUI Transitions" src="addons/simple-gui-transitions/icon.svg">
</p>
<h1 align="center">Godot's Simple GUI Transitions</h1>

*"Simple GUI transitions to swap between menus elegantly."*

This plugin gives access to the `GuiTransition` node which allows to transition between multiple GUI layouts easily. Designed for Godot 3.5.x.
See the example scene on `addons/simple-gui-transitions/example` to see it in action.

## Node `GuiTransition`
The node `GuiTransition` is responsible for transitioning a specific layout.

### Properties
#### Auto Start
If the current layout will trigger its transition at startup.

#### Layout ID
ID of layout to trigger changes on the singleton `GuiTransitions` (at method parameters named `id`).
If empty, will be assumed as the `Layout` node name.

#### Animation
The animation type of the transition. The available animations are:

- Slide left, right, up and down
- Fade
- Scale vertical, horizontal and both

_* Currently the slide animations only work properly if `display/window/stretch/mode` is set to `2D`._

#### Duration
The total animation duration in seconds.

#### Layout
The main layout node. It will be hidden and shown accordingly. Should be the topmost node of the current layout.

#### Group
A node with children controls to be animated in sequence.
Example: a `HBoxContainer` or `VBoxContainer` with several buttons as children will allow to animate all of those buttons one by one.
See the `Delay` property.

#### Delay
Delay between each `Group`'s children transitions.

#### Transition Type
Transition curve of the transition animation. Same as `Tween.TransitionType`.

#### Ease Type
Ease curve of the transition animation. Same as `Tween.EaseType`.

## Singleton `GuiTransitions`
The singleton `GuiTransitions` allows to trigger the transitions globally and swap between GUI layouts.

### Signals
#### show_completed
The signal `show_completed` is emited after a layout has been shown.

#### hide_completed
The signal `hide_completed` is emited after a layout has been hidden.

### Public Methods
#### go_to(id: String, function: FuncRef, args: Array)
The method `go_to` hides the current layout and shows the layout with the given `id`.
If `function` (optional) and `args` (optional) are passed in, the `function` will be executed halfway through.
Both signals `hide_completed` and `show_completed` are emited accordingly.

#### update(function: FuncRef, args: Array)
The method `update` hides and shows the current layout.
If `function` (optional) and `args` (optional) are passed in, the `function` will be executed halfway through.
Both signals `hide_completed` and `show_completed` are emited accordingly.

#### show(id: String)
The method `show` shows the layout with the given `id`.
Emits the signal `show_completed` on completion.

#### hide(id: String)
The method `hide` hides the layout with the given `id`, or all visible layouts if no `id` is passed in.
Emits the signal `hide_completed` on completion.
