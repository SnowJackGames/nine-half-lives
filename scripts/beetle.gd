# Beatles.... in Nine Half-Lives...

extends CharacterBody2D


@onready var tile_detection : Marker2D = $TileDetection
@onready var sprite : AnimatedSprite2D = $AnimatedSprite2D
@onready var initial_position := position

@onready var pounceoverable := true
@onready var slashthroughable := false
@onready var slashable := true
@onready var landonable := true
@onready var moveonable := false
@onready var is_enemy := true
@onready var is_alive : bool

const beetle_center_offset := Vector2(8,8)

var facing := "Up"
var cur_health : int
var declared_attack : bool
var declared_attack_pos_1
var declared_attack_pos_2
var declared_attack_pos_3
var declared_attack_pos_4
var declared_attack_direction
var declared_move_pos
var player : CharacterBody2D

var max_health := 3
var spit_attack_damage := 3

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

static var invert_direction := {
	"Up Left" : "Down Right",
	"Up" : "Down",
	"Up Right" : "Down Left",
	"Right" : "Left",
	"Down Right" : "Up Left",
	"Down" : "Up",
	"Down Left" : "Up Right",
	"Left" : "Right"
}

static var direction_slash_animation := {
	"Up": "slash up",
	"Down": "slash down",
	"Left": "slash left",
	"Right": "slash right",
	"Up Left" : "slash up",
	"Up Right" : "slash up",
	"Down Left" : "slash down",
	"Down Right" : "slash down"
}
static var direction_bump_slash_animation := {
	"Up": "bump up",
	"Down": "bump down",
	"Left": "bump left",
	"Right": "bump right",
	"Up Left" : "bump up",
	"Up Right" : "bump up",
	"Down Left" : "bump down",
	"Down Right" : "bump down"
}

static var direction_hurt_animation := {
	"Up": "hurt up",
	"Down": "hurt down",
	"Left": "hurt left",
	"Right": "hurt right",
	"Up Left" : "hurt up",
	"Up Right" : "hurt up",
	"Down Left" : "hurt down",
	"Down Right" : "hurt left",
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

func begin_turn() -> void:
	player = Globals.player
	declared_attack_pos_1 = null
	declared_attack_pos_2 = null
	declared_attack_pos_3 = null
	declared_attack_pos_4 = null
	declared_attack_direction = null
	declared_move_pos = null
	declared_attack = false
	phase_one()
	
func end_turn() -> void:
	pass
	
func _ready() -> void:
	reset_status()
	
func reset_status() -> void:
	position = initial_position
	$MoveHint.hide()
	$AttackHint.hide()
	$AttackHint2.hide()
	$AttackHint3.hide()
	$AttackHint4.hide()
	show()
	is_alive = true
	facing = "Up"
	sprite.animation = directional_walk_animations[facing]
	cur_health = 3

# Determine if beetle should move, then declare attack
func phase_one() -> void:
	var tile_distance_to_player : float
	var direction_towards_player : String
	var direction_away_from_player : String
	tile_distance_to_player = position.distance_to(player.position) / 16
	
	# Determine direction of player
	var tile_detection_check : Vector2
	var closest_tile_to_player := position + beetle_center_offset
	var furthest_tile_to_player := position + beetle_center_offset
	var closest_distance_to_player := closest_tile_to_player.distance_to(player.position + beetle_center_offset)
	var furthest_distance_to_player := furthest_tile_to_player.distance_to(player.position + beetle_center_offset)
		
	# For every direction, figure out the closest and furthest tile to player
	for direction in direction_dictionary:
		tile_detection_check = direction_dictionary[direction] * Globals.grid_size + position + beetle_center_offset
		if tile_detection.moveonable(tile_detection_check):
			# replace with closer spot
			if tile_detection_check.distance_to(player.position + beetle_center_offset) < closest_distance_to_player:
				closest_tile_to_player = tile_detection_check
				closest_distance_to_player = tile_detection_check.distance_to(player.position)
				direction_towards_player = direction
			# replace with further spot
			if tile_detection_check.distance_to(player.position + beetle_center_offset) > furthest_distance_to_player:
				furthest_tile_to_player = tile_detection_check
				furthest_distance_to_player = tile_detection_check.distance_to(player.position)
				direction_away_from_player = direction
	
	var can_move_closer = false
	var can_move_further = false
	if (position + beetle_center_offset) != closest_tile_to_player:
		can_move_closer = true
	if (position + beetle_center_offset) != furthest_tile_to_player:
		can_move_further = true

	# Get closer
	if tile_distance_to_player > 4:
		if can_move_closer:
			facing = eight_direction_to_four_directions[direction_towards_player]
			await move(closest_tile_to_player - beetle_center_offset)
		else:
			await get_tree().create_timer(0.2).timeout
	# stay
	elif tile_distance_to_player == 4:
		await get_tree().create_timer(0.2).timeout
	# move away
	elif tile_distance_to_player < 4:
		if can_move_further:
			facing = eight_direction_to_four_directions[direction_away_from_player]
			await move(furthest_tile_to_player - beetle_center_offset)
		else:
			await get_tree().create_timer(0.2).timeout
	
	# Declare attack
	declare_attack()
	await get_tree().create_timer(0.2).timeout
	FinishedPhase.emit()

func declare_attack() -> void:
	# iterate across orthogonal directions checking 1 tile away
	# whichever is closest to player, attack in that direction
	var direction_towards_player : String
	var current_tile := position + beetle_center_offset
	var distance_to_player := current_tile.distance_to(player.position + beetle_center_offset)
	var tile_detection_check : Vector2
	# Check 4 directions
	for direction in direction_dictionary:
		tile_detection_check = direction_dictionary[direction] * Globals.grid_size + position + beetle_center_offset
		# If player is right next to us, attack there of course
		if tile_detection.player_on_tile(tile_detection_check):
			declared_attack = true
			facing = eight_direction_to_four_directions[direction]
			direction_towards_player = direction
			distance_to_player = tile_detection_check.distance_to(player.position + beetle_center_offset)
			declared_attack_direction = direction_towards_player
			declared_attack_pos_1 = tile_detection_check - beetle_center_offset
			break
		# If it's a tile we can slash through or if its an enemy
		elif tile_detection.slashthroughable(tile_detection_check) or tile_detection.enemy_on_tile(tile_detection_check):
			# confirm that we will be attacking
			declared_attack = true
			# If there's a tile closer, we choose that one
			if tile_detection_check.distance_to(player.position + beetle_center_offset) < distance_to_player:
				facing = eight_direction_to_four_directions[direction]
				direction_towards_player = direction
				distance_to_player = tile_detection_check.distance_to(player.position + beetle_center_offset)
				declared_attack_pos_1 = tile_detection_check - beetle_center_offset
	declared_attack_direction = direction_towards_player
	
	# If we can attack 1 tile away, let's see if we attack 2 tiles away, then 3, then 4
	if declared_attack and declared_attack_direction:
		tile_detection_check = direction_dictionary[declared_attack_direction] * Globals.grid_size * 2 + position + beetle_center_offset
		if tile_detection.player_on_tile(tile_detection_check) or tile_detection.enemy_on_tile(tile_detection_check) or tile_detection.slashthroughable(tile_detection_check):
			declared_attack_pos_2 = tile_detection_check - beetle_center_offset
			tile_detection_check = direction_dictionary[declared_attack_direction] * Globals.grid_size * 3 + position + beetle_center_offset
			if tile_detection.player_on_tile(tile_detection_check) or tile_detection.enemy_on_tile(tile_detection_check) or tile_detection.slashthroughable(tile_detection_check):
				declared_attack_pos_3 = tile_detection_check - beetle_center_offset
				tile_detection_check = direction_dictionary[declared_attack_direction] * Globals.grid_size * 4 + position + beetle_center_offset
				if tile_detection.player_on_tile(tile_detection_check) or tile_detection.enemy_on_tile(tile_detection_check) or tile_detection.slashthroughable(tile_detection_check):
					declared_attack_pos_4 = tile_detection_check - beetle_center_offset
	attack_hint()
	pass

func attack_hint() -> void:
	if declared_attack_direction:
		if declared_attack_pos_1:
			$AttackHint.global_position = declared_attack_pos_1
			$AttackHint.show()
		if declared_attack_pos_2:
			$AttackHint2.global_position = declared_attack_pos_2
			$AttackHint2.show()
		if declared_attack_pos_3:
			$AttackHint3.global_position = declared_attack_pos_3
			$AttackHint3.show()
		if declared_attack_pos_4:
			$AttackHint4.global_position = declared_attack_pos_4
			$AttackHint4.show()
			await get_tree().create_timer(0.1).timeout

func attack() -> void:
	sprite.animation = direction_slash_animation[eight_direction_to_four_directions[facing]]
	sprite.frame = 0
	await get_tree().create_timer(0.15).timeout
	sprite.frame = 1
	await get_tree().create_timer(0.15).timeout
	sprite.frame = 2
	await get_tree().create_timer(0.15).timeout
	if declared_attack:
		for attack_spot in [declared_attack_pos_1, declared_attack_pos_2, declared_attack_pos_3, declared_attack_pos_4]:
			if attack_spot != null:
				if tile_detection.player_on_tile(attack_spot + beetle_center_offset):
					await player.take_damage(spit_attack_damage)
	
	$AttackHint.hide()
	$AttackHint2.hide()
	$AttackHint3.hide()
	$AttackHint4.hide()
	sprite.animation = directional_walk_animations[eight_direction_to_four_directions[facing]]
	FinishedPhase.emit()
		
func move(pos: Vector2):
	sprite.animation = directional_walk_animations[eight_direction_to_four_directions[facing]]
	$MoveHint.global_position = pos
	$MoveHint.show()
	await get_tree().create_timer(0.2).timeout
	var frame_target = sprite.frame
	var movement_vector = pos - position
	frame_target += 1
	frame_target %= 4
	sprite.frame = frame_target
	$MoveHint.hide()
	position += 0.5 * movement_vector
	await get_tree().create_timer(0.15).timeout
	frame_target += 1
	frame_target %= 4
	sprite.frame = frame_target
	position += 0.5 * movement_vector
	await get_tree().create_timer(0.15).timeout
	await check_for_tile_damage()
	sprite.animation = directional_walk_animations[eight_direction_to_four_directions[facing]]
	
	

func check_for_tile_damage() -> void:
	# If moved onto damaging tile, take damage
	# They fly now
	var tile_damage : int = tile_detection.tile_damage_air(position + beetle_center_offset)
	if tile_damage > 0:
		await take_damage(tile_damage)

func pushed_onto(pos : Vector2) -> void:
	position = pos
	# clear out any declared attacks, bc we got staggered
	declared_attack = false
	$AttackHint.hide()
	$AttackHint2.hide()
	$AttackHint3.hide()
	$AttackHint4.hide()
	await check_for_tile_damage()

func where_can_be_pushed(source_direction) -> Variant:
	var push_spot = null
	var tile_detection_check : Vector2
	if source_direction == "Up":
		tile_detection_check = (Vector2.UP) * Globals.grid_size * 1 + position + beetle_center_offset
		if tile_detection.moveonable(tile_detection_check) and !tile_detection.enemy_on_tile(tile_detection_check):
			push_spot = tile_detection_check - beetle_center_offset
	elif source_direction == "Down":
		tile_detection_check = (Vector2.DOWN) * Globals.grid_size * 1 + position + beetle_center_offset
		if tile_detection.moveonable(tile_detection_check) and !tile_detection.enemy_on_tile(tile_detection_check):
			push_spot = tile_detection_check - beetle_center_offset
	elif source_direction == "Left":
		tile_detection_check = (Vector2.LEFT) * Globals.grid_size * 1 + position + beetle_center_offset
		if tile_detection.moveonable(tile_detection_check) and !tile_detection.enemy_on_tile(tile_detection_check):
			push_spot = tile_detection_check - beetle_center_offset
	elif source_direction == "Right":
		tile_detection_check = (Vector2.RIGHT) * Globals.grid_size * 1 + position + beetle_center_offset
		if tile_detection.moveonable(tile_detection_check) and !tile_detection.enemy_on_tile(tile_detection_check):
			push_spot = tile_detection_check - beetle_center_offset
	elif source_direction == "Up Left":
		tile_detection_check = ((Vector2.UP) + (Vector2.LEFT)) * Globals.grid_size * 1 + position + beetle_center_offset
		if tile_detection.moveonable(tile_detection_check) and !tile_detection.enemy_on_tile(tile_detection_check):
			push_spot = tile_detection_check - beetle_center_offset
	elif source_direction == "Up Right":
		tile_detection_check = ((Vector2.UP) + (Vector2.RIGHT)) * Globals.grid_size * 1 + position + beetle_center_offset
		if tile_detection.moveonable(tile_detection_check) and !tile_detection.enemy_on_tile(tile_detection_check):
			push_spot = tile_detection_check- beetle_center_offset
	elif source_direction == "Down Left":
		tile_detection_check = ((Vector2.DOWN) + (Vector2.LEFT)) * Globals.grid_size * 1 + position + beetle_center_offset
		if tile_detection.moveonable(tile_detection_check) and !tile_detection.enemy_on_tile(tile_detection_check):
			push_spot = tile_detection_check - beetle_center_offset
	elif source_direction == "Down Right":
		tile_detection_check = ((Vector2.DOWN) + (Vector2.RIGHT)) * Globals.grid_size * 1 + position + beetle_center_offset
		if tile_detection.moveonable(tile_detection_check) and !tile_detection.enemy_on_tile(tile_detection_check):
			push_spot = tile_detection_check - beetle_center_offset
	else:
		push_error("received impossible direction: " + source_direction)
	return push_spot

func take_damage (damage : int):
	if damage > 0:
		$AttackHint.hide()
		$AttackHint2.hide()
		$AttackHint3.hide()
		$AttackHint4.hide()
		cur_health -= damage
		# Take damage animation
		sprite.animation = direction_hurt_animation[eight_direction_to_four_directions[facing]]
		sprite.frame = 0
		await get_tree().create_timer(0.1).timeout
		sprite.frame = 1
		await get_tree().create_timer(0.1).timeout
		sprite.frame = 0
		await get_tree().create_timer(0.1).timeout
		sprite.frame = 1
		await get_tree().create_timer(0.1).timeout
		sprite.frame = 2
		await get_tree().create_timer(0.2).timeout
		hide()
		await get_tree().create_timer(0.01).timeout
		# Should always die in one hit
		is_alive = false
		hide()
