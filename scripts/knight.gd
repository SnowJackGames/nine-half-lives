extends Node

@onready var player : CharacterBody2D
@onready var tile_detection : Marker2D

var knight_spot
var knight_direction
var knight_spot_dictionary : Dictionary[String, Vector2]

static var knight_direction_to_walk_animation := {
	"UpUpLeft" : "walk up",
	"UpUpRight" : "walk up",
	"LeftLeftUp" : "walk left",
	"RightRightUp" : "walk right",
	"LeftLeftDown" : "walk left",
	"RightRightDown" : "walk right",
	"DownDownLeft" : "walk down",
	"DownDownRight" : "walk down",
}

static var directional_knight_animations := {
	"UpUpLeft" : "knight up up left",
	"UpUpRight" : "knight up up right",
	"LeftLeftUp" : "knight left left up",
	"RightRightUp" : "knight right right up",
	"LeftLeftDown" : "knight left left down",
	"RightRightDown" : "knight right right down",
	"DownDownLeft" : "knight down down left",
	"DownDownRight" : "knight down down right",
}

var knight_dir_to_vectors : Dictionary[String, Vector2] = {
	"UpUpLeft" : Vector2.UP + Vector2.UP + Vector2.LEFT,
	"UpUpRight" : Vector2.UP + Vector2.UP + Vector2.RIGHT,
	"LeftLeftUp" : Vector2.LEFT + Vector2.LEFT + Vector2.UP,
	"RightRightUp" : Vector2.RIGHT + Vector2.RIGHT + Vector2.UP,
	"LeftLeftDown" : Vector2.LEFT + Vector2.LEFT + Vector2.DOWN,
	"RightRightDown" : Vector2.RIGHT + Vector2.RIGHT + Vector2.DOWN,
	"DownDownLeft" : Vector2.DOWN + Vector2.DOWN + Vector2.LEFT,
	"DownDownRight" : Vector2.DOWN + Vector2.DOWN + Vector2.RIGHT,
}

var knight_dir_to_check_spots : Dictionary[String, Array] = {
	"UpUpLeft" : [Vector2.UP, Vector2.UP + Vector2.LEFT],
	"UpUpRight" : [Vector2.UP, Vector2.UP + Vector2.RIGHT],
	"LeftLeftUp" : [Vector2.LEFT, Vector2.LEFT + Vector2.UP],
	"RightRightUp" : [Vector2.RIGHT, Vector2.RIGHT + Vector2.UP],
	"LeftLeftDown" : [Vector2.LEFT, Vector2.LEFT + Vector2.DOWN],
	"RightRightDown" : [Vector2.RIGHT, Vector2.RIGHT + Vector2.DOWN],
	"DownDownLeft" : [Vector2.DOWN, Vector2.DOWN + Vector2.LEFT],
	"DownDownRight" : [Vector2.DOWN, Vector2.DOWN + Vector2.RIGHT],
}

func reset() -> void:
	knight_direction = null
	knight_spot = null
	knight_spot_dictionary = {} as Dictionary[String, Vector2]

func declare_knight() -> void:
	var valid_dir := []
	#Build knight_spot_dictionary 
	# iterate over knight_dir_to_vectors
	var tile_detection_check_1 : Vector2
	var tile_detection_check_2 : Vector2
	var tile_to_land_on : Vector2
	for dir in knight_dir_to_vectors:
		tile_detection_check_1 = (knight_dir_to_check_spots[dir][0] * Globals.grid_size) + player.position + player.kitty_center_offset
		tile_detection_check_2 = (knight_dir_to_check_spots[dir][1] * Globals.grid_size) + player.position + player.kitty_center_offset
		print(dir)
		print(player.position)
		print(tile_detection_check_1)
		print(tile_detection_check_2)
		print()
		# if at least one tile_detection.pounceoverable in knight_dir_to_check_spots
		if tile_detection.pounceoverable(tile_detection_check_1) or tile_detection.pounceoverable(tile_detection_check_2):
			tile_to_land_on = (knight_dir_to_vectors[dir] * Globals.grid_size) + player.position
			if tile_detection.enemy_on_tile(tile_to_land_on):
				knight_spot_dictionary[dir] = tile_to_land_on
				valid_dir.append(dir)
		
	if !valid_dir.is_empty():
		# Make sure we're not player.facing an illegal direction
		var invalid_facing := true
		if player.facing == "Up":
			if valid_dir.has("UpUpLeft") or valid_dir.has("UpUpRight"):
				invalid_facing = false
				if valid_dir.has("UpUpLeft"):
					knight_direction = "UpUpLeft"
				else:
					knight_direction = "UpUpRight"
		elif player.facing == "Down":
			if valid_dir.has("DownDownLeft") or valid_dir.has("DownDownRight"):
				invalid_facing = false
				if valid_dir.has("DownDownLeft"):
					knight_direction = "DownDownLeft"
				else:
					knight_direction = "DownDownRight"
		elif player.facing == "Left":
			if valid_dir.has("LeftLeftUp") or valid_dir.has("LeftLeftDown"):
				invalid_facing = false
				if valid_dir.has("LeftLeftUp"):
					knight_direction = "LeftLeftUp"
				else:
					knight_direction = "LeftLeftDown"
		elif player.facing == "Right":
			if valid_dir.has("RightRightUp") or valid_dir.has("RightRightDown"):
				invalid_facing = false
				if valid_dir.has("RightRightUp"):
					knight_direction = "RightRightUp"
				else:
					knight_direction = "RightRightDown"
		
		if invalid_facing:
			var random_knight_direction = valid_dir[randi_range(0, (valid_dir.size() - 1))]
			knight_direction = random_knight_direction
			player.facing = player.directional_facing[player.directional_walk_animations.find_key(knight_direction_to_walk_animation[random_knight_direction])]
			player.sprite.animation = player.directional_walk_animations[player.directional_facing.find_key(player.facing)]
		
		knight_spot = knight_spot_dictionary[knight_direction]
		knight_hint(valid_dir, true)
		attempt_knight(valid_dir)
	
	else:
		Debug.say("No valid knight target!")
		# Animate shake head
		await player.get_tree().create_timer(0.2).timeout
		await Globals.inputs_clear()
		player.FinishedAction.emit()
	pass

func attempt_knight(valid_dir: Array) -> void:
	# Only in Combat
	if Globals.game_mode == 2:
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
						break
					# If a direction is pressed, *flip* which of the two knight moves is being selected
					elif Input.is_action_pressed(dir) and !Input.is_action_pressed("ui_accept") and !Input.is_action_pressed("ui_cancel"):
						# set the knight_direction
						if dir == "ui_up":
							if knight_spot_dictionary.has("UpUpLeft"):
								if knight_spot_dictionary.has("UpUpRight"):
									# if has right AND left, swap or go left
									if knight_direction == "UpUpLeft":
										knight_direction = "UpUpRight"
									else:
										knight_direction = "UpUpLeft"
								# left but no right
								else:
									knight_direction = "UpUpLeft"
								knight_spot = knight_spot_dictionary[knight_direction]
								player.sprite.animation = knight_direction_to_walk_animation[knight_direction]
								player.facing = player.directional_facing[player.directional_walk_animations.find_key(knight_direction_to_walk_animation[knight_direction])]
								knight_hint(valid_dir, true)
							# right but no left
							elif knight_spot_dictionary.has("UpUpRight"):
								knight_direction = "UpUpRight"
								knight_spot = knight_spot_dictionary[knight_direction]
								player.sprite.animation = knight_direction_to_walk_animation[knight_direction]
								player.facing = player.directional_facing[player.directional_walk_animations.find_key(knight_direction_to_walk_animation[knight_direction])]
								knight_hint(valid_dir, true)
						elif dir == "ui_down":
							if knight_spot_dictionary.has("DownDownLeft"):
								if knight_spot_dictionary.has("DownDownRight"):
									if knight_direction == "DownDownLeft":
										knight_direction = "DownDownRight"
									else:
										knight_direction = "DownDownLeft"
								else:
									knight_direction = "DownDownLeft"
								knight_spot = knight_spot_dictionary[knight_direction]
								player.sprite.animation = knight_direction_to_walk_animation[knight_direction]
								player.facing = player.directional_facing[player.directional_walk_animations.find_key(knight_direction_to_walk_animation[knight_direction])]
								knight_hint(valid_dir, true)
							elif knight_spot_dictionary.has("DownDownRight"):
								knight_direction = "DownDownRight"
								knight_spot = knight_spot_dictionary[knight_direction]
								player.sprite.animation = knight_direction_to_walk_animation[knight_direction]
								player.facing = player.directional_facing[player.directional_walk_animations.find_key(knight_direction_to_walk_animation[knight_direction])]
								knight_hint(valid_dir, true)
						elif dir == "ui_left":
							if knight_spot_dictionary.has("LeftLeftUp"):
								if knight_spot_dictionary.has("LeftLeftDown"):
									if knight_direction == "LeftLeftUp":
										knight_direction = "LeftLeftDown"
									else:
										knight_direction = "LeftLeftUp"
								else:
									knight_direction = "LeftLeftUp"
								knight_spot = knight_spot_dictionary[knight_direction]
								player.sprite.animation = knight_direction_to_walk_animation[knight_direction]
								player.facing = player.directional_facing[player.directional_walk_animations.find_key(knight_direction_to_walk_animation[knight_direction])]
								knight_hint(valid_dir, true)
							elif knight_spot_dictionary.has("LeftLeftDown"):
								knight_direction = "LeftLeftDown"
								knight_spot = knight_spot_dictionary[knight_direction]
								player.sprite.animation = knight_direction_to_walk_animation[knight_direction]
								player.facing = player.directional_facing[player.directional_walk_animations.find_key(knight_direction_to_walk_animation[knight_direction])]
								knight_hint(valid_dir, true)
						elif dir == "ui_right":
							if knight_spot_dictionary.has("RightRightUp"):
								if knight_spot_dictionary.has("RightRightDown"):
									if knight_direction == "RightRightUp":
										knight_direction = "RightRightDown"
									else:
										knight_direction = "RightRightUp"
								else:
									knight_direction = "RightRightUp"
								knight_spot = knight_spot_dictionary[knight_direction]
								player.sprite.animation = knight_direction_to_walk_animation[knight_direction]
								player.facing = player.directional_facing[player.directional_walk_animations.find_key(knight_direction_to_walk_animation[knight_direction])]
								knight_hint(valid_dir, true)
							elif knight_spot_dictionary.has("RightRightDown"):
								knight_direction = "RightRightDown"
								knight_spot = knight_spot_dictionary[knight_direction]
								player.sprite.animation = knight_direction_to_walk_animation[knight_direction]
								player.facing = player.directional_facing[player.directional_walk_animations.find_key(knight_direction_to_walk_animation[knight_direction])]
								knight_hint(valid_dir, true)
						else:
							push_error("somehow invalid direction given in attempt_knight")
						break
			await player.get_tree().create_timer(0.1).timeout
		await Globals.inputs_clear()
		if attacking:
			player.can_action = false
			enact_knight()
		else:
			knight_hint([], false)
			player.FinishedAction.emit()
	else:
		push_error("can only Knight in combat")
	
func knight_hint(valid_dir: Array, shouldload: bool) -> void:
	var knight_ui := "Targetting/Knight/"
	if shouldload:
		for dir in ["UpUpLeft", "UpUpRight", "LeftLeftUp", "LeftLeftDown", "RightRightUp", "RightRightDown", "DownDownLeft", "DownDownRight"]:
			if valid_dir.has(dir):
				if knight_direction == dir:
					player.get_node(knight_ui + dir + "Focused").show()
					player.get_node(knight_ui + dir + "Unfocused").hide()
				else:
					player.get_node(knight_ui + dir + "Unfocused").show()
					player.get_node(knight_ui + dir + "Focused").hide()
			else:
				player.get_node(knight_ui + dir + "Focused").hide()
				player.get_node(knight_ui + dir + "Unfocused").hide()
		player.get_node(knight_ui).show()
	else:
		player.get_node(knight_ui).hide()
	
func enact_knight() -> void:
	Globals.ui.hide_all()
	knight_hint([], false)
	Globalaudio.play_FX(player.catattack_fx)
	var damage_spot = knight_spot
	var target_enemy = player.get_node(tile_detection.get_enemy_path_from_spot(damage_spot))
	var push_spot
	var movement_vector = damage_spot - player.position
	player.sprite.animation = directional_knight_animations[knight_direction]
	player.sprite.frame = 0
	await player.get_tree().create_timer(0.15).timeout
	player.sprite.frame = 1
	await player.get_tree().create_timer(0.15).timeout
	player.sprite.frame = 2
	player.position += 0.75 * movement_vector
	await player.get_tree().create_timer(0.15).timeout
	player.sprite.frame = 3
	player.position += 0.25 * movement_vector
	await player.get_tree().create_timer(0.15).timeout

	await tile_detection.damage_enemy(damage_spot, player.knight_damage)
	# check if enemy exists after taking initial damage
	target_enemy = player.get_node(tile_detection.get_enemy_path_from_spot(damage_spot))
	if target_enemy.get("pushed_onto") and target_enemy.is_alive:
		print("why")
		if knight_direction in ["UpUpLeft", "UpUpRight"]:
			push_spot = target_enemy.where_can_be_pushed("Up")
			if target_enemy.where_can_be_pushed("Up"):
				await target_enemy.pushed_onto(push_spot)
			else:
				tile_detection.damage_enemy(damage_spot, player.knight_damage)
		elif knight_direction in ["LeftLeftUp", "LeftLeftDown"]:
			push_spot = target_enemy.where_can_be_pushed("Left")
			if target_enemy.where_can_be_pushed("Left"):
				await target_enemy.pushed_onto(push_spot)
			else:
				await tile_detection.damage_enemy(damage_spot, player.knight_damage)
		elif knight_direction in ["RightRightUp", "RightRightDown"]:
			push_spot = target_enemy.where_can_be_pushed("Right")
			if target_enemy.where_can_be_pushed("Right"):
				await target_enemy.pushed_onto(push_spot)
			else:
				await tile_detection.damage_enemy(damage_spot, player.knight_damage)
		elif knight_direction in ["DownDownLeft", "DownDownRight"]:
			push_spot = target_enemy.where_can_be_pushed("Down")
			if target_enemy.where_can_be_pushed("Down"):
				await target_enemy.pushed_onto(push_spot)
			else:
				await tile_detection.damage_enemy(damage_spot, player.knight_damage)
		else:
			push_error("knight_direction " + knight_direction + "not valid")
	Debug.say("Knight " + knight_direction + "!")
	# If pounced onto damaging spot, take damage
	player.sprite.animation = player.directional_walk_animations[player.directional_facing.find_key(player.facing)]
	player.check_for_tile_damage()
	player.FinishedAction.emit()
