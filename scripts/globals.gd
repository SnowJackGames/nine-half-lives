extends Node

const grid_size := 16

# 0 is null
# 1 is exploration
# 2 is combat
var game_mode := 0

@onready var level_camera : Camera2D

@onready var player : CharacterBody2D

@onready var ui : Control

@onready var entity_to_damage : CharacterBody2D

@onready var GameManager : Node2D

signal ui_accept_pressed

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		ui_accept_pressed.emit()


## When given an [Array] of [String]s containing inputs [br](ex. [enum "ui_accept"], [enum "ui_cancel"] etc.),
## [br]waits for those inputs to be [i]not[/i] being pressed down [br](i.e. being "clear") before continuing.
## [br][br]If not given a particular list, defaults to: [br][[br] [enum "ui_accept"][br] [enum "ui_cancel"]
## [br] [enum "ui_up"][br] [enum "ui_down"][br] [enum "ui_left"][br] [enum "ui_right"][br]]
func inputs_clear(inputs : Array[String] = []) -> void:
	await get_tree().process_frame
	for input in inputs:
		if input is not String:
			push_error("item in Array given to await_inputs_clear() was not a string")

	var inputs_waiting_for : Array[String]
	if inputs.is_empty():
		inputs_waiting_for = [
			"ui_close_dialog",
			"ui_accept",
			"ui_cancel",
			"ui_up",
			"ui_down",
			"ui_left",
			"ui_right"
		]
	else:
		inputs_waiting_for = inputs as Array[String]

	var can_move_on
	
	for awaited_input in inputs_waiting_for:
		can_move_on = false
		while !can_move_on:
			if !Input.is_action_pressed(awaited_input):
				can_move_on = true
			await get_tree().create_timer(0.01).timeout


#
## Deleting something, like a bomb or an enemy dying
#func remove_object(object_full_path : String) -> void:
	#if object_full_path:
		#get_node(object_full_path).queue_free()

## You can [b]await Globals.not_paused()[/b] to make sure that we're not
## [br]running things while paused.
func not_paused() -> void:
	while !GameManager.pause:
		await get_tree().create_timer(.01).timeout
