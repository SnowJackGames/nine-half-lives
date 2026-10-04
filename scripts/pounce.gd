extends Node

@onready var player : CharacterBody2D
@onready var tile_detection : Marker2D

static var directional_pounce_animations_exploration := {
	'ui_up': "pounce up exploration",
	'ui_down': "pounce down exploration",
	'ui_left': "pounce left exploration",
	'ui_right': "pounce right exploration"
}

static var directional_pounce_animations_combat := {
	'ui_up': "pounce up combat",
	'ui_down': "pounce down combat",
	'ui_left': "pounce left combat",
	'ui_right': "pounce right combat"
}

func declare_pounce() -> void:
	# First check to see in what directions we can pounce
	var valid_dir := [] # "Up", etc
	var tile_detection_check : Vector2
	for dir in player.directional_facing: # player.directional_facing: ui_up -> Up
		var valid_target
		# move tile_detection to each increasing spot towards the target
		# if 1 and 2 away cannot be pounced over, or 3 away cannot be landed on,
		# then cannot pounce
		tile_detection_check = (player.dir_inputs[dir] * Globals.grid_size * 1) + player.position + player.kitty_center_offset
		var tile_detection_check_2 = (player.dir_inputs[dir] * Globals.grid_size * 2) + player.position + player.kitty_center_offset
		if tile_detection.pounceoverable(tile_detection_check) and tile_detection.pounceoverable(tile_detection_check_2):
			valid_target = true
		else:
			valid_target = false
		
		tile_detection_check = (player.dir_inputs[dir] * Globals.grid_size * 3) + player.position + player.kitty_center_offset
		if valid_target == true:
			if !tile_detection.landonable(tile_detection_check):
				valid_target = false
			
		if valid_target:
			valid_dir.append(player.directional_facing[dir])
	
	if !valid_dir.is_empty():
		# Make sure we're not facing an illegal direction...
		if !valid_dir.has(player.facing):
			# Face a random valid direction
			player.facing = valid_dir[randi_range(0, (valid_dir.size() - 1))]
			# ex. player.facing: Up -> player.directional_facing: ui_up -> directional_walk_animations: walk up
			player.sprite.animation = player.directional_walk_animations[player.directional_facing.find_key(player.facing)]
		pounce_hint(valid_dir, true)
		attempt_pounce(valid_dir)
	else:
		Debug.say("No valid pounce target!")
		# Animate shake head
		await player.get_tree().create_timer(0.2).timeout
		await Globals.inputs_clear()
		player.FinishedAction.emit()

func attempt_pounce(valid_dir: Array) -> void:
	# Exploration
	if Globals.game_mode == 1:
		# Until "ui_cancel" is no longer being pressed, or until we press pause
		while Input.is_action_pressed('ui_cancel') and !Globals.GameManager.paused and !Globals.GameManager.should_abandon_turn():
			# Updating direction
			for dir in player.dir_inputs: # player.dir_inputs: ui_up -> Vector2.up -> walk up
				if Input.is_action_pressed(dir):
					if valid_dir.has(player.directional_facing[dir]): # player.directional_facing: ui_up -> Up
						player.facing = player.directional_facing[dir]
						player.sprite.animation = player.directional_walk_animations[dir]
						pounce_hint(valid_dir, true)
						break
			# Reduce speed of loop waiting for key release
			await player.get_tree().create_timer(0.05).timeout
		if !Globals.GameManager.paused and !Globals.GameManager.should_abandon_turn():
			enact_pounce()
			player.can_action = false
		else:
			pounce_hint([], false)
			player.FinishedAction.emit()

	# Combat
	elif Globals.game_mode == 2:
		Globals.ui.attack_combat_return_hover()
		var chose_option := false
		var attacking := false
		while !chose_option and !Globals.GameManager.should_abandon_turn():
			# Don't process while paused
			if Globals.GameManager.paused:
				pass
			else:
				for dir in player.dir_inputs.keys():
					# (A) accept
					if Input.is_action_pressed("ui_accept") and !Input.is_action_pressed("ui_cancel"):
						chose_option = true
						attacking = true
						break
					# (B) cancel
					elif Input.is_action_pressed("ui_cancel") and !Input.is_action_pressed("ui_accept"):
						attacking = false
						chose_option = true
						break
					elif Input.is_action_pressed(dir) and !Input.is_action_pressed("ui_accept") and !Input.is_action_pressed("ui_cancel"):
						if player.directional_facing[dir] in valid_dir:
							player.facing = player.directional_facing[dir]
							player.sprite.animation = player.directional_walk_animations[dir]
							pounce_hint(valid_dir, true)
							break
			await player.get_tree().create_timer(0.08).timeout
		await Globals.inputs_clear()
		if attacking:
			player.can_action = false
			enact_pounce()
		else:
			pounce_hint([], false)
			player.FinishedAction.emit()

	else:
		push_error("Impossible state in attempt_pounce")

func pounce_hint(valid_dir: Array, shouldload: bool) -> void:
	var pounce_ui := "Targetting/Pounce/"
	if shouldload:
		var directions := ["Up", "Right", "Down", "Left"]
		for dir in directions:
			if valid_dir.has(dir):
				if player.facing == dir:
					player.get_node(pounce_ui + dir + "Focused").show()
					player.get_node(pounce_ui + dir + "Unfocused").hide()
				else:
					player.get_node(pounce_ui + dir + "Unfocused").show()
					player.get_node(pounce_ui + dir + "Focused").hide()
			else:
				player.get_node(pounce_ui + dir + "Focused").hide()
				player.get_node(pounce_ui + dir + "Unfocused").hide()
		# Reveal after processing visibility of sub-layers
		player.get_node(pounce_ui).show()
	else:
		player.get_node(pounce_ui).hide()
	
func enact_pounce() -> void:
	Globals.ui.hide_all()
	pounce_hint([], false)
	Globalaudio.play_FX(player.catattack_fx)
	# Facing: Up -> player.directional_facing: ui_up -> player.dir_inputs: Vector2.UP
	var pounce_vector_pos : Vector2 = player.dir_inputs[player.directional_facing.find_key(player.facing)] * Globals.grid_size * 3
	var damage_spot = (player.dir_inputs[player.directional_facing.find_key(player.facing)] * Globals.grid_size * 3) + player.position
	if Globals.game_mode == 1 or !tile_detection.enemy_on_tile(damage_spot):
		player.sprite.animation = directional_pounce_animations_exploration[player.directional_facing.find_key(player.facing)]
	else:
		player.sprite.animation = directional_pounce_animations_combat[player.directional_facing.find_key(player.facing)]

	# We animate moving
	if Globals.game_mode == 1:
		player.sprite.frame = 0
		Debug.say("Pounce " + player.facing + "!")
		await player.get_tree().create_timer(0.085).timeout
		player.sprite.frame = 1
		player.position += 0.5 * pounce_vector_pos
		await player.get_tree().create_timer(0.085).timeout
		player.sprite.frame = 2
		player.position += 0.25 * pounce_vector_pos
		await player.get_tree().create_timer(0.085).timeout
		player.sprite.frame = 3
		player.position += 0.25 * pounce_vector_pos
		await player.get_tree().create_timer(0.085).timeout
		await tile_detection.damage_enemy(damage_spot, player.pounce_damage)
		player.sprite.animation = player.directional_walk_animations[player.directional_facing.find_key(player.facing)]
	# If pounced onto damaging spot, take damage
	if Globals.game_mode == 2:
		player.sprite.frame = 0
		Debug.say("Pounce " + player.facing + "!")
		await player.get_tree().create_timer(0.1).timeout
		player.sprite.frame = 1
		player.position += 0.5 * pounce_vector_pos
		await player.get_tree().create_timer(0.12).timeout
		player.sprite.frame = 2
		player.position += 0.25 * pounce_vector_pos
		await player.get_tree().create_timer(0.12).timeout
		player.sprite.frame = 3
		player.position += 0.25 * pounce_vector_pos
		await player.get_tree().create_timer(0.12).timeout
		await tile_detection.damage_enemy(damage_spot, player.pounce_damage)
		player.sprite.animation = player.directional_walk_animations[player.directional_facing.find_key(player.facing)]
	player.check_for_tile_damage()
	player.FinishedAction.emit()
