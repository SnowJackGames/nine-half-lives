extends CharacterBody2D


@onready var tile_detection : Marker2D = $TileDetection
@onready var sprite : AnimatedSprite2D = $AnimatedSprite2D

@onready var pounceoverable := true
@onready var slashthroughable := false
@onready var slashable := true
@onready var landonable := true
@onready var moveonable := false
@onready var is_enemy := true
@onready var is_alive : bool


var ratattack = preload("res://sound/sfx/RatAttack.mp3")  
var ratdeath = preload("res://sound/sfx/RatDeath.mp3")  
var ratsteps = preload("res://sound/sfx/RatSteps-glued.mp3")  
var ratdamage = preload("res://sound/sfx/OtherDamage.mp3")  




const rat_center_offset := Vector2(8,8)

var facing := "Up"
var bump_attacking : bool
var cur_health : int
var declared_attack : bool
var declared_attack_pos_near
var declared_attack_pos_far
var declared_attack_direction
var declared_move_pos
var player : CharacterBody2D

var max_health := 5
var bump_slash_damage := 3
var quick_attack_damage := 3

signal FinishedPhase

static var direction_dictionary = {
	"Up Left" : Vector2.UP + Vector2.LEFT,
	"Up" : Vector2.UP,
	"Up Right" : Vector2.UP + Vector2.RIGHT,
	"Right" : Vector2.RIGHT,
	"Down Right" : Vector2.RIGHT + Vector2.DOWN,
	"Down" : Vector2.DOWN,
	"Down Left" :Vector2.DOWN + Vector2.LEFT,
	"Left" : Vector2.LEFT
}

# Only 4 directions
static var simple_direction_dictionary = {
	"Up" : Vector2.UP,
	"Right" : Vector2.RIGHT,
	"Down" : Vector2.DOWN,
	"Left" : Vector2.LEFT
}

static var directional_walk_animations := {
	"Up Left" : "walk up",
	"Up" : "walk up",
	"Up Right" : "walk up",
	"Right" : "walk right",
	"Down Right" : "walk down",
	"Down" : "walk down",
	"Down Left" : "walk down",
	"Left" : "walk left"
}

static var eight_direction_to_four_directions := {
	"Up Left" : "Up",
	"Up" : "Up",
	"Up Right" : "Up",
	"Right" : "Right",
	"Down Right" : "Down",
	"Down" : "Down",
	"Down Left" : "Down",
	"Left" : "Left"
}

static var direction_slash_animation := {
	"Up": "slash up",
	"Down": "slash down",
	"Left": "slash left",
	"Right": "slash right",
}

static var direction_hurt_animation := {
	"Up": "hurt up",
	"Down": "hurt down",
	"Left": "hurt left",
	"Right": "hurt right",
}



func begin_turn() -> void:
	player = Globals.player
	declared_attack_pos_near = null
	declared_attack_pos_far = null
	declared_attack_direction = null
	declared_move_pos = null
	declared_attack = false
	bump_attacking = false
	phase_one()
	
func end_turn() -> void:
	pass
	
func _ready() -> void:
	is_alive = true
	cur_health = 5
	$MoveHint.hide()
	$AttackHint.hide()
	$AttackHint2.hide()
	show()
	sprite.animation = directional_walk_animations[facing]

# Determine if rat should either bump slash, or move then declare attack
func phase_one() -> void:
	var is_beside_player := false
	var direction_towards_player : String
	# check surrounding 8 tiles
	var tile_detection_check : Vector2
	for direction in direction_dictionary:
		tile_detection_check = direction_dictionary[direction] * Globals.grid_size + position + rat_center_offset
		if tile_detection.contains(tile_detection_check, "Player"):
			is_beside_player = true
			direction_towards_player = direction
	# Bump slash
	if is_beside_player and direction_towards_player in ["Up", "Down", "Left", "Right"]:
		bump_attacking = true
		declared_move_pos = player.position
		facing = direction_towards_player
		var push_target = player.where_can_be_pushed(direction_towards_player)
		# declare initial position, then move position halfway towards player?
		if push_target:
			await move(declared_move_pos)
			if !Globals.GameManager.should_abandon_turn():
				await Globals.not_paused()
				sprite.animation = direction_slash_animation[eight_direction_to_four_directions[facing]]
				sprite.frame = 0
				await get_tree().create_timer(0.05).timeout
				sprite.frame = 1
				await get_tree().create_timer(0.05).timeout
				sprite.frame = 2
				await get_tree().create_timer(0.05).timeout
				sprite.animation = directional_walk_animations[eight_direction_to_four_directions[facing]]
				await player.take_damage(bump_slash_damage)
				player.pushed_onto(push_target)
				$AttackHint.hide()
		else:
			$AttackHint.global_position = declared_move_pos
			$AttackHint.show()
			if !Globals.GameManager.should_abandon_turn():
				await Globals.not_paused()
				await get_tree().create_timer(0.1).timeout
				sprite.animation = direction_slash_animation[eight_direction_to_four_directions[facing]]
				sprite.frame = 0
				await get_tree().create_timer(0.10).timeout
				sprite.frame = 1
				await get_tree().create_timer(0.10).timeout
				sprite.frame = 2
				await get_tree().create_timer(0.10).timeout
				sprite.animation = directional_walk_animations[eight_direction_to_four_directions[facing]]
				await player.take_damage(player.cornered_damage)
				await player.take_damage(bump_slash_damage)
				$AttackHint.hide()
		if !Globals.GameManager.should_abandon_turn():
			# Then they damage themselves
			await take_damage(bump_slash_damage)
	else:
		# Move towards player
		var closest_tile_to_player := position + rat_center_offset
		var distance_to_player := closest_tile_to_player.distance_to(player.position + rat_center_offset)
		for direction in direction_dictionary:
			tile_detection_check = direction_dictionary[direction] * Globals.grid_size + position + rat_center_offset
			if tile_detection.moveonable(tile_detection_check) and !tile_detection.tile_damage_ground(tile_detection_check):
				# select the better spot
				if tile_detection_check.distance_to(player.position + rat_center_offset) < distance_to_player:
					facing = direction
					closest_tile_to_player = tile_detection_check
					distance_to_player = tile_detection_check.distance_to(player.position + + rat_center_offset)
			declared_move_pos = closest_tile_to_player
		await move(declared_move_pos - rat_center_offset)
		if !Globals.GameManager.should_abandon_turn():
			# Declare attack
			declare_attack()
	FinishedPhase.emit()

func declare_attack() -> void:
	# iterate across orthogonal directions checking 1 tile away
	# whichever is closest to player, attack in that direction
	var direction_towards_player : String
	var distance_to_player := position.distance_to(player.position)
	var tile_detection_check : Vector2
	# Check 4 directions
	for direction in simple_direction_dictionary:
		tile_detection_check = simple_direction_dictionary[direction] * Globals.grid_size + position + rat_center_offset
		# If player is right next to us, attack there of course
		if tile_detection.player_on_tile(tile_detection_check):
			declared_attack = true
			facing = direction
			sprite.animation = directional_walk_animations[eight_direction_to_four_directions[facing]]
			direction_towards_player = direction
			distance_to_player = tile_detection_check.distance_to(player.position)
			declared_attack_direction = direction_towards_player
			declared_attack_pos_near = tile_detection_check - rat_center_offset
			break
		# If it's a tile we can slash through or if its an enemy
		elif tile_detection.slashthroughable(tile_detection_check) or tile_detection.enemy_on_tile(tile_detection_check):
			# confirm that we will be attacking
			declared_attack = true
			# If there's a tile closer, we choose that one
			if tile_detection_check.distance_to(player.position) < distance_to_player:
				facing = direction
				sprite.animation = directional_walk_animations[eight_direction_to_four_directions[facing]]
				direction_towards_player = direction
				distance_to_player = tile_detection_check.distance_to(player.position)
				declared_attack_pos_near = tile_detection_check - rat_center_offset
	declared_attack_direction = direction_towards_player
	
	# Discard attack if its trying to attack its own tile, bc that's the closest tile
	if declared_attack_pos_near == position:
		declared_attack = false
	
	# If we can attack 1 tile away, let's see if we attack 2 tiles away
	if declared_attack and declared_attack_direction:
		tile_detection_check = direction_dictionary[declared_attack_direction] * Globals.grid_size * 2 + position + rat_center_offset
		if tile_detection.player_on_tile(tile_detection_check) or tile_detection.enemy_on_tile(tile_detection_check) or tile_detection.slashthroughable(tile_detection_check):
			declared_attack_pos_far = tile_detection_check - rat_center_offset
		attack_hint()
	pass

func attack_hint() -> void:
	if declared_attack_direction:
		if declared_attack_pos_near:
			$AttackHint.global_position = declared_attack_pos_near
			$AttackHint.show()
		if declared_attack_pos_far:
			$AttackHint2.global_position = declared_attack_pos_far
			$AttackHint2.show()

func attack() -> void:
	if !Globals.GameManager.should_abandon_turn():
		await Globals.not_paused()
		Globalaudio.play_FX(ratattack)
		sprite.animation = direction_slash_animation[eight_direction_to_four_directions[facing]]
		sprite.frame = 0
		await get_tree().create_timer(0.10).timeout
		sprite.frame = 1
		await get_tree().create_timer(0.10).timeout
		sprite.frame = 2
		await get_tree().create_timer(0.10).timeout
		if declared_attack:
			for attack_spot in [declared_attack_pos_near, declared_attack_pos_far]:
				if attack_spot != null:
					if tile_detection.player_on_tile(attack_spot):
						await player.take_damage(quick_attack_damage)
		
		$AttackHint.hide()
		$AttackHint2.hide()
		sprite.animation = directional_walk_animations[eight_direction_to_four_directions[facing]]
		FinishedPhase.emit()

func move(pos: Vector2):
	if !Globals.GameManager.should_abandon_turn():
		await Globals.not_paused()
		Globalaudio.play_FX(ratsteps)
		sprite.animation = directional_walk_animations[eight_direction_to_four_directions[facing]]
		$MoveHint.global_position = pos
		$MoveHint.show()
		if bump_attacking:
			$AttackHint.global_position = pos
			$AttackHint.show()
		await get_tree().create_timer(0.10).timeout
		var frame_target = sprite.frame
		var movement_vector = pos - position
		frame_target += 1
		frame_target %= 4
		sprite.frame = frame_target
		$MoveHint.hide()
		$AttackHint.hide()
		position += 0.5 * movement_vector
		await get_tree().create_timer(0.10).timeout
		frame_target += 1
		frame_target %= 4
		sprite.frame = frame_target
		position += 0.5 * movement_vector
		await get_tree().create_timer(0.10).timeout
		check_for_tile_damage()

func check_for_tile_damage() -> void:
	# If moved onto damaging tile, take damage
	var tile_damage := 0
	tile_damage += tile_detection.tile_damage_ground(position)
	tile_damage += tile_detection.tile_damage_air(position)
	if tile_damage > 0:
		await take_damage(tile_damage)

func pushed_onto(pos : Vector2) -> void:
	position = pos
	# clear out any declared attacks, bc we got staggered
	declared_attack = false
	$AttackHint.hide()
	$AttackHint2.hide()
	await check_for_tile_damage()

func where_can_be_pushed(source_direction) -> Variant:
	var push_spot = null
	var tile_detection_check : Vector2
	if source_direction == "Up":
		tile_detection_check = (Vector2.UP) * Globals.grid_size * 1 + position + rat_center_offset
		if tile_detection.moveonable(tile_detection_check) and !tile_detection.enemy_on_tile(tile_detection_check - rat_center_offset):
			push_spot = tile_detection_check - rat_center_offset
	elif source_direction == "Down":
		tile_detection_check = (Vector2.DOWN) * Globals.grid_size * 1 + position + rat_center_offset
		if tile_detection.moveonable(tile_detection_check) and !tile_detection.enemy_on_tile(tile_detection_check - rat_center_offset):
			push_spot = tile_detection_check - rat_center_offset
	elif source_direction == "Left":
		tile_detection_check = (Vector2.LEFT) * Globals.grid_size * 1 + position + rat_center_offset
		if tile_detection.moveonable(tile_detection_check) and !tile_detection.enemy_on_tile(tile_detection_check - rat_center_offset):
			push_spot = tile_detection_check - rat_center_offset
	elif source_direction == "Right":
		tile_detection_check = (Vector2.RIGHT) * Globals.grid_size * 1 + position + rat_center_offset
		if tile_detection.moveonable(tile_detection_check) and !tile_detection.enemy_on_tile(tile_detection_check - rat_center_offset):
			push_spot = tile_detection_check - rat_center_offset
	elif source_direction == "Up Left":
		tile_detection_check = ((Vector2.UP) + (Vector2.LEFT)) * Globals.grid_size * 1 + position + rat_center_offset
		if tile_detection.moveonable(tile_detection_check) and !tile_detection.enemy_on_tile(tile_detection_check - rat_center_offset):
			push_spot = tile_detection_check - rat_center_offset
	elif source_direction == "Up Right":
		tile_detection_check = ((Vector2.UP) + (Vector2.RIGHT)) * Globals.grid_size * 1 + position + rat_center_offset
		if tile_detection.moveonable(tile_detection_check) and !tile_detection.enemy_on_tile(tile_detection_check - rat_center_offset):
			push_spot = tile_detection_check - rat_center_offset
	elif source_direction == "Down Left":
		tile_detection_check = ((Vector2.DOWN) + (Vector2.LEFT)) * Globals.grid_size * 1 + position + rat_center_offset
		if tile_detection.moveonable(tile_detection_check) and !tile_detection.enemy_on_tile(tile_detection_check - rat_center_offset):
			push_spot = tile_detection_check - rat_center_offset
	elif source_direction == "Down Right":
		tile_detection_check = ((Vector2.DOWN) + (Vector2.RIGHT)) * Globals.grid_size * 1 + position + rat_center_offset
		if tile_detection.moveonable(tile_detection_check) and !tile_detection.enemy_on_tile(tile_detection_check - rat_center_offset):
			push_spot = tile_detection_check - rat_center_offset
	else:
		push_error("received impossible direction: " + source_direction)
	return push_spot

func take_damage (damage : int):
	if !is_alive:
		return
		
	Globalaudio.play_FX(ratdamage)
	var attack_shown = $AttackHint.visible
	var attack2_shown = $AttackHint2.visible
	sprite.animation = direction_hurt_animation[facing]
	if damage > 0:
		sprite.animation = direction_hurt_animation[facing]
		cur_health -= damage
		# Take damage animation
		if attack_shown:
			$AttackHint.hide()
		if attack2_shown:
			$AttackHint2.hide()
		sprite.frame = 1
		await get_tree().create_timer(0.05).timeout
		sprite.frame = 0
		await get_tree().create_timer(0.05).timeout
		sprite.frame = 1
		await get_tree().create_timer(0.05).timeout
		sprite.frame = 0
		await get_tree().create_timer(0.05).timeout
		sprite.frame = 1
		await get_tree().create_timer(0.05).timeout
		sprite.animation = directional_walk_animations[facing]
	if cur_health <= 0:
		Globalaudio.play_FX(ratdeath)
		is_alive = false
		hide()
		
	else:
		if attack_shown:
			$AttackHint.show()
		if attack2_shown:
			$AttackHint2.show()
		await get_tree().create_timer(0.1).timeout
