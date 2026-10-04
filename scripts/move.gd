extends Node

@onready var player : CharacterBody2D
@onready var tile_detection : Marker2D


func declare_move() -> void:
	var valid_dir := [] # "Up", etc
	for dir in player.directional_facing: # player.directional_facing: ui_up -> Up
		var valid_target := true
		var tile_detection_check : Vector2 = (player.dir_inputs[dir] * Globals.grid_size * 1) + player.position + player.kitty_center_offset
		if !tile_detection.moveonable(tile_detection_check):
			valid_target = false
		if valid_target:
			valid_dir.append(player.directional_facing[dir])
	
	if !valid_dir.is_empty():
		# In Combat
		if Globals.game_mode == 2:
			# Make sure we're not facing an illegal direction
			if !valid_dir.has(player.facing):
				player.facing = valid_dir[randi_range(0, (valid_dir.size() - 1))]
				player.sprite.animation = player.directional_walk_animations[player.directional_facing.find_key(player.facing)]
			move_hint(valid_dir, true)
		attempt_move(valid_dir)
	
	# No valid movement
	else:
		Debug.say("No valid movement")
		await player.get_tree().create_timer(0.1).timeout
		player.can_move = false
		player.FinishedMove.emit()



func attempt_move(valid_dir) -> void:
	# Exploration
	if Globals.game_mode == 1:
		for dir in player.dir_inputs.keys():
			if Input.is_action_pressed(dir):
				# Make sure we're not trying to move in two directions at once
				var is_multiple_buttons := false
				for dir2 in player.dir_inputs.keys():
					if (dir != dir2) and Input.is_action_pressed(dir2):
						is_multiple_buttons = true
				if !is_multiple_buttons:
					## Attempt move
					player.facing = player.directional_facing[dir]
					if player.directional_facing[dir] in valid_dir:
						player.can_move = false
						player.sprite.animation = player.directional_walk_animations[dir]
						enact_move(player.dir_inputs[player.directional_facing.find_key(player.facing)] * Globals.grid_size * 1)
					else:
						Debug.say("Invalid move")
						await player.get_tree().create_timer(0.15).timeout
						player.FinishedMove.emit()
						break
				else:
					# Won't let player move two ways at once
					await player.get_tree().create_timer(0.15).timeout
					player.FinishedMove.emit()
					break


	#Combat
	elif Globals.game_mode == 2:
		Globals.ui.move_combat_hover()
		var chose_option := false
		var should_move := false
		var tapped_dir : String
		await Globals.inputs_clear()
		
		while !chose_option and !Globals.GameManager.should_abandon_turn():
			# Don't process while paused
			if Globals.GameManager.paused:
				pass
			else:
				if Input.is_action_pressed("ui_cancel") and !Input.is_action_pressed("ui_accept"):
					chose_option = true
					should_move = false
				elif Input.is_action_pressed("ui_accept") and !Input.is_action_pressed("ui_cancel"):
					chose_option = true
					should_move = true
				else:
					for dir in player.dir_inputs.keys():
						if Input.is_action_pressed(dir):
							if player.directional_facing[dir] in valid_dir:
								player.facing = player.directional_facing[dir]
								player.sprite.animation = player.directional_walk_animations[dir]
								move_hint(valid_dir, true)
								# Can tap twice in same direction to confirm
								if tapped_dir == dir:
									chose_option = true
									should_move = true
								else:
									tapped_dir = dir
								await Globals.inputs_clear()
								break
			await player.get_tree().create_timer(0.08).timeout
		await Globals.inputs_clear()
		if should_move:
			player.can_move = false
			enact_move(player.dir_inputs[player.directional_facing.find_key(player.facing)] * Globals.grid_size * 1)
		else:
			move_hint([], false)
			player.FinishedMove.emit()

	
	else:
		
		push_error("Impossible state in attempt_move")


func move_hint(valid_dir: Array, shouldload: bool) -> void:
	var move_ui := "Targetting/Move/"
	if shouldload:
		var directions := ["Up", "Right", "Down", "Left"]
		for dir in directions:
			if valid_dir.has(dir):
				if player.facing == dir:
					player.get_node(move_ui + dir + "Focused").show()
					player.get_node(move_ui + dir + "Unfocused").hide()
				else:
					player.get_node(move_ui + dir + "Unfocused").show()
					player.get_node(move_ui + dir + "Focused").hide()
			else:
				player.get_node(move_ui + dir + "Focused").hide()
				player.get_node(move_ui + dir + "Unfocused").hide()
		# Reveal after processing visibility of sub-layers
		player.get_node(move_ui).show()
	else:
		player.get_node(move_ui).hide()

func enact_move(vector_pos: Vector2):
	move_hint([], false)
	if Globals.game_mode == 1:
		player.can_action = false
	player.sprite.animation = player.directional_walk_animations[player.directional_facing.find_key(player.facing)]
	var frame_target = player.sprite.frame
	frame_target += 1
	frame_target %= 4
	player.sprite.frame = frame_target
	player.position += 0.5 * vector_pos
	await player.get_tree().create_timer(0.15).timeout
	frame_target += 1
	frame_target %= 4
	player.sprite.frame = frame_target
	player.position += 0.5 * vector_pos
	await player.get_tree().create_timer(0.15).timeout
	player.check_for_tile_damage()
	player.FinishedMove.emit()
