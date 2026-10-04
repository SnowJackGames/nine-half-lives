extends Node

@onready var player : CharacterBody2D
@onready var tile_detection : Marker2D

static var directional_slash_animations := {
	'ui_up': "slash up",
	'ui_down': "slash down",
	'ui_left': "slash left",
	'ui_right': "slash right"
}


func declare_slash() -> void:
	# Check to see in what directions we can slash, and how far
	var valid_dir := [] # "UpNear", "UpFar", etc
	var valid_dir_without_near_or_far := []
	for dir in player.directional_facing: # ui_up -> Up
		var tile_detection_check_near : Vector2 = (player.dir_inputs[dir] * Globals.grid_size * 1) + player.position + player.kitty_center_offset
		var tile_detection_check_far : Vector2 = (player.dir_inputs[dir] * Globals.grid_size * 2) + player.position + player.kitty_center_offset
		
		# Check if enemy is near
		if tile_detection.enemy_on_tile(tile_detection_check_near):
			valid_dir.append(player.directional_facing[dir] + "Near") # ex. "UpNear"
			valid_dir_without_near_or_far.append(player.directional_facing[dir])
		# Check if near is slashthroughable
		elif tile_detection.slashthroughable(tile_detection_check_near):
			# if so, is enemy far
			if tile_detection.enemy_on_tile(tile_detection_check_far):
				valid_dir.append(player.directional_facing[dir] + "Far") # ex. "UpFar"
				valid_dir_without_near_or_far.append(player.directional_facing[dir])
			# otherwise, is far slashthroughable
			elif tile_detection.slashthroughable(tile_detection_check_far):
				valid_dir.append(player.directional_facing[dir] + "Far") # ex. "UpFar"
				valid_dir_without_near_or_far.append(player.directional_facing[dir])
			# otherwise, near is slashthroughable but not far
			else:
				valid_dir.append(player.directional_facing[dir] + "Near") # ex. "UpNear"
				valid_dir_without_near_or_far.append(player.directional_facing[dir])
	
	if !valid_dir.is_empty():
		# Make sure we're not player.facing an illegal direction...
		if !(valid_dir.has(player.facing + "Near") or valid_dir.has(player.facing + "Far")):
			# Face a random valid direction
			player.facing = valid_dir_without_near_or_far[randi_range(0, (valid_dir_without_near_or_far.size() - 1))]
			# ex. player.facing: Up -> player.directional_facing: ui_up -> player.directional_walk_animations: walk up
			player.sprite.animation = player.directional_walk_animations[player.directional_facing.find_key(player.facing)]
			
		slash_hint(valid_dir, true)
		attempt_slash(valid_dir)
	else:
		Debug.say("No valid slash target!")
		# Animate shake head
		await player.get_tree().create_timer(0.2).timeout
		await Globals.inputs_clear()
		player.FinishedAction.emit()

func attempt_slash(valid_dir: Array) -> void:
	# Exploration
	if Globals.game_mode == 1:
		# Until "ui_accept" is no longer being pressed
		while Input.is_action_pressed('ui_accept') and !Globals.GameManager.paused and !Globals.GameManager.should_abandon_turn():
			# Updating direction
			for dir in player.dir_inputs.keys():
				if Input.is_action_pressed(dir):
					if player.directional_facing[dir] + "Far" or player.directional_facing[dir] + "Near" in valid_dir:
						player.facing = player.directional_facing[dir]
						player.sprite.animation = player.directional_walk_animations[dir]
						slash_hint(valid_dir, true)
						break
			# Reduce speed of loop waiting for key release
			await player.get_tree().create_timer(0.08).timeout
		if !Globals.GameManager.paused and !Globals.GameManager.should_abandon_turn():
			enact_slash(valid_dir)
		else:
			slash_hint([], false)
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
						attacking = true
						chose_option = true
						break
					# (B) cancel
					elif Input.is_action_pressed("ui_cancel") and !Input.is_action_pressed("ui_accept"):
						attacking = false
						chose_option = true
						print("canceled")
						break
					elif Input.is_action_pressed(dir) and !Input.is_action_pressed("ui_accept")and !Input.is_action_pressed("ui_cancel"):
						player.facing = player.directional_facing[dir]
						player.sprite.animation = player.directional_walk_animations[dir]
						slash_hint(valid_dir, true)
						break
			await player.get_tree().create_timer(0.08).timeout
		await Globals.inputs_clear()
		print(attacking)
		if attacking:
			player.can_action = false
			enact_slash(valid_dir)
		else:
			slash_hint([], false)
			player.FinishedAction.emit()
	
	else:
		push_error("Impossible state in attempt_slash")

func slash_hint(valid_dir: Array, shouldload: bool = false) -> void:
	var slash_ui := "Targetting/Slash/"
	if shouldload:
		var directions := ["Up", "Right", "Down", "Left"]
		for dir in directions:
			# Only show near hints
			if valid_dir.has(dir + "Near") and !valid_dir.has(dir + "Far"):
				# Hide the fars
				player.get_node(slash_ui + dir + "FarFocused").hide()
				player.get_node(slash_ui + dir + "FarUnfocused").hide()
				if player.facing == dir:
					player.get_node(slash_ui + dir + "NearFocused").show()
					player.get_node(slash_ui + dir + "NearUnfocused").hide()
				else:
					player.get_node(slash_ui + dir + "NearUnfocused").show()
					player.get_node(slash_ui + dir + "NearFocused").hide()

			# show near and far hints
			elif valid_dir.has(dir + "Far") and !valid_dir.has(dir + "Near"):
				if player.facing == dir:
					player.get_node(slash_ui + dir + "NearFocused").show()
					player.get_node(slash_ui + dir + "FarFocused").show()
					player.get_node(slash_ui + dir + "NearUnfocused").hide()
					player.get_node(slash_ui + dir + "FarUnfocused").hide()
				else:
					player.get_node(slash_ui + dir + "NearUnfocused").show()
					player.get_node(slash_ui + dir + "FarUnfocused").show()
					player.get_node(slash_ui + dir + "NearFocused").hide()
					player.get_node(slash_ui + dir + "FarFocused").hide()
			
			# Error state
			elif valid_dir.has(dir + "Near") and valid_dir.has(dir + "Far"):
				push_error("cannot slash both near and far")
			
			# Hide everything
			else:
				player.get_node(slash_ui + dir + "NearFocused").hide()
				player.get_node(slash_ui + dir + "FarFocused").hide()
				player.get_node(slash_ui + dir + "NearUnfocused").hide()
				player.get_node(slash_ui + dir + "FarUnfocused").hide()
		# Reveal after processing visibility of sub-layers
		player.get_node(slash_ui).show()

	else:
		player.get_node(slash_ui).hide()

func enact_slash(valid_dir: Array) -> void:
	Globalaudio.play_FX(player.catattack_fx)
	Globals.ui.hide_all()
	slash_hint([], false)
	var damage_spot : Vector2
	# Near slash
	if valid_dir.has((player.facing + "Near")) and !valid_dir.has((player.facing + "Far")):
		player.sprite.animation = directional_slash_animations[player.directional_facing.find_key(player.facing)]
		Debug.say("Slash " + player.facing + " Near!")
		player.sprite.frame = 0
		await player.get_tree().create_timer(0.12).timeout
		player.sprite.frame = 1
		await player.get_tree().create_timer(0.12).timeout
		player.sprite.frame = 2
		await player.get_tree().create_timer(0.12).timeout
		player.sprite.frame = 3
		await player.get_tree().create_timer(0.12).timeout
		damage_spot = (player.dir_inputs[player.directional_facing.find_key(player.facing)] * Globals.grid_size * 1) + player.position
		await tile_detection.damage_enemy(damage_spot, player.slash_damage)
		player.sprite.animation = player.directional_walk_animations[player.directional_facing.find_key(player.facing)]
		player.sprite.frame = 0
		await player.get_tree().create_timer(0.12).timeout
	# Far slash
	elif valid_dir.has((player.facing + "Far")) and !valid_dir.has((player.facing + "Near")):
		player.sprite.animation = directional_slash_animations[player.directional_facing.find_key(player.facing)]
		Debug.say("Slash " + player.facing + " Near!")
		player.sprite.frame = 0
		await player.get_tree().create_timer(0.15).timeout
		player.sprite.frame = 1
		await player.get_tree().create_timer(0.15).timeout
		player.sprite.frame = 2
		await player.get_tree().create_timer(0.15).timeout
		player.sprite.frame = 3
		await player.get_tree().create_timer(0.15).timeout
		damage_spot = (player.dir_inputs[player.directional_facing.find_key(player.facing)] * Globals.grid_size * 2) + player.position
		await tile_detection.damage_enemy(damage_spot, player.slash_damage)
		player.sprite.animation = player.directional_walk_animations[player.directional_facing.find_key(player.facing)]
		player.sprite.frame = 0
		await player.get_tree().create_timer(0.15).timeout

	elif valid_dir.has((player.facing + "Near")) and valid_dir.has((player.facing + "Far")):
		push_error("Cannot slash both near and far")
	
	else:
		push_error("Asked to slash this direction but cannot")
	player.FinishedAction.emit()
