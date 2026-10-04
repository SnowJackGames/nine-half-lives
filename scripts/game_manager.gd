extends Node2D

@onready var levels_scene : Node2D = $Levels
@onready var current_level : Node2D
@onready var current_level_index := 0

@onready var player_character: CharacterBody2D = $Player
@onready var ai_enemy : CharacterBody2D
@onready var ai_array : Array[CharacterBody2D] = []

@onready var game_over_player = $GameOverSequence
@onready var pause_menu = $PauseMenu/CanvasLayer
@onready var pause_menu_node = $PauseMenu
@onready var paused = false
@onready var turn_running = false

signal FinishedTurnCycle

var bus_name: String
var bus_index: int

const ambience1 = preload("res://sound/ambience/Ambience 1.mp3")

const steppin = preload("res://sound/music/Side Steppin'.mp3")
const blurr = preload("res://sound/music/Blurr.mp3")
const emerald = preload("res://sound/music/Emerald Gold.mp3")
const magenta = preload("res://sound/music/Magenta.mp3")
const opening = preload("res://sound/music/Opening.mp3")
const spurr = preload("res://sound/music/Spurr.mp3")
const teeter = preload("res://sound/music/Teeter.mp3")

const deeperred = preload("res://sound/music/9 - 29 - 26 Deeper Red.mp3")
const fell = preload("res://sound/music/9-29-26 Fell.mp3")
const underriser = preload("res://sound/music/9-29-26 Underriser.mp3")
const receivingsignals = preload("res://sound/music/9-29-2026 Receiving Signals.mp3")
const sendingsignals = preload("res://sound/music/9-29-2026 Sending Signals.mp3")
var reloading : bool

## Main loop for the turn cycle, containing player and enemy phases.
## [br]Attempts to abandon running any phases or moving automatically to next turn
## [br] if player health <= 0, or if we sent a signal to restart the level.
func next_turn() -> void:
	turn_running = true
	Debug.say("starting turn")
	
	#region Enemy Phases
	if !should_abandon_turn():
		await calc_ai_array()
		if ai_array:
			Globals.game_mode = 2
			await enemy_phase_one()
		else:
			# Exploration
			Globals.game_mode = 1
	else:
		Debug.say("abandoning turn\n--------")
		await get_tree().create_timer(0.01).timeout
		turn_running = false
		FinishedTurnCycle.emit()
		return
	#endregion
		
	#region Player Phases
	if !should_abandon_turn():
		await calc_ai_array() # in case any AI died during their turn
		if ai_array:
			Globals.game_mode = 2
		else:
			Globals.game_mode = 1
	
		# Player turn
		await player_character.begin_turn()
		await player_character.FinishedTurn
		await player_character.end_turn()
	else:
		Debug.say("abandoning turn\n--------")
		await get_tree().create_timer(0.01).timeout
		turn_running = false
		FinishedTurnCycle.emit()
		return
	#endregion

	#region Next Enemy Phases
	if !should_abandon_turn():
		# Recalc array after player turn
		await calc_ai_array()
		if ai_array:
			Globals.game_mode = 2
			await enemy_phase_two()
		else:
			Globals.game_mode = 1
	else:
		Debug.say("abandoning turn\n--------")
		await get_tree().create_timer(0.01).timeout
		turn_running = false
		FinishedTurnCycle.emit()
		return
	#endregion
	#region End of Turn Handling
	if !should_abandon_turn():
		# Unlock stairs
		await calc_ai_array()
		if !ai_array:
			if current_level.get_node("Elements/Stairs"):
				current_level.get_node("Elements/Stairs").unlock()

		if player_character.on_level_exit:
			await increment_active_level()
	else:
		Debug.say("abandoning turn\n--------")
		await get_tree().create_timer(0.01).timeout
		turn_running = false
		FinishedTurnCycle.emit()
		return

	Debug.say("finished turn\n--------")
	await get_tree().create_timer(0.01).timeout
	FinishedTurnCycle.emit()
	#endregion
	
	#region Next Turn Handling
	if !should_abandon_turn():
		next_turn()
	#endregion

## Initial movements and bump-slash
func enemy_phase_one() -> void:
	for ai in ai_array:
		await Globals.not_paused()
		
		if should_abandon_turn():
			return
		elif "is_alive" in ai:
			if ai.is_alive:
					ai.begin_turn()
					await ai.FinishedPhase
					# If player dies or we're restarting, abandon turn
					if should_abandon_turn():
						return
					else:
						await get_tree().create_timer(randf_range(0.1, 0.2)).timeout # stagger time btwn enemy turns

## Enacting declared attack
func enemy_phase_two() -> void:
	for ai in ai_array:
		await Globals.not_paused()
		
		if should_abandon_turn():
			return
		elif "declared_attack" and "is_alive" in ai:
			if ai.declared_attack and ai.is_alive:
				#ai enacts attack
				ai.attack()
				await ai.FinishedPhase
				await ai.end_turn()
				# If player dies or we're restarting, abandon turn
				if should_abandon_turn():
					return
				else:
					await get_tree().create_timer(randf_range(0.1, 0.2)).timeout # random slight delay btwn enemy turns

func reload_level(from_game_over := false):
	await unpause_game()
	player_character.just_took_damage = false
	reloading = true
	# Wait for current turn to be cleaned up
	while turn_running:
		await get_tree().create_timer(0.1).timeout
		
	# Now, reload things
	Debug.say("resetting")
	
	if from_game_over:
		await get_tree().create_timer(1.5).timeout
		game_over_player.play_game_over()
		await game_over_player.animation_finished
	else:
		game_over_player.play_fade_out()
		await game_over_player.animation_finished
		
	# Now we are currently blacked out
	await load_level(current_level_index)
	
	# Finished reloading, now resume process
	game_over_player.play_fade_in()
	await game_over_player.animation_finished
	game_over_player.clean_up()
	
	reloading = false
	await get_tree().create_timer(0.1).timeout
	next_turn()

func pause_game():
	await get_tree().create_timer(.05).timeout
	paused = true
	pause($Levels)
	pause($Player)
	unpause(pause_menu_node)
	pause_menu.show()
	
func unpause_game():
	await Globals.inputs_clear()
	paused = false
	unpause($Levels)
	unpause($Player)
	pause_menu.hide()
	pause(pause_menu_node)

func increment_active_level() -> void:
	current_level_index += 1
	
	if current_level_index >= levels_scene.level_order.size():
		Debug.say("Finished last level")
		get_tree().quit()
	
	else:
		await load_level(current_level_index)


func load_level(index : int) -> void:
	# Unload whatever level is currently up
	var walls : Node2D
	if current_level:
		walls = get_node("Levels/" + levels_scene.level_order[current_level_index].name + "/Elements/WallTiles")
		if walls != null:
			walls.collision_enabled = false
		current_level.visible = false
		current_level.process_mode = Node.PROCESS_MODE_DISABLED
	
	player_character.reset_status()
	current_level = get_node("Levels/" + str(levels_scene.level_order[index]))
	current_level.visible = true
	walls = get_node("Levels/" + levels_scene.level_order[index].name + "/Elements/WallTiles")
	if walls != null:
		walls.collision_enabled = true
	current_level.process_mode = Node.PROCESS_MODE_INHERIT
	
	# Move player to starting position of level
	player_character.position = current_level.player_start_position
	update_camera_target()
	
	# reset status of AI units
	for child in current_level.find_children("*", "CharacterBody2D"):
		if "is_enemy" in child or child.get("is_enemy"):
			child.reset_status()
	
	# Audio
	if !reloading:
		if current_level.name == "Tutorial1":
			Globalaudio.playVolume(0.35)
			Globalaudio.fadeInTime(8.0)
			Globalaudio.play_music_level_random_start(fell,-10.0)
			Globalambienceplayer.playVolume(0.75)
			Globalambienceplayer.play_music_level_random_start(ambience1)
		if current_level.name == "Level1":
			Globalaudio.fadeInTime(0.5)
			Globalambienceplayer.fadeInTime(15.0)
			Globalaudio.toggle()
			Globalambienceplayer.toggle()
			#Globalcombatmusic.playVolume(0.7)
			#Globalcombatmusic.fadeInTime(4)
			Globalcombatmusic.fadeInTime(0.0)
			Globalcombatmusic.play_music_level(steppin)
			
		if current_level.name == "Level5":
			Globalaudio.playVolume(0.35)
			Globalaudio.fadeInTime(8.0)
			Globalaudio.play_music_level_random_start(spurr,-10.0)
			Globalaudio.fadeInTime(0.1)
			Globalambienceplayer.playVolume(0.75)
			Globalambienceplayer.play_music_level_random_start(ambience1)
			
		if current_level.name == "Level6":
			Globalaudio.play_music_level(teeter)
		if current_level.name == "Exploration2":
			Globalaudio.play_music_level(opening)
		if current_level.name == "Level8":
			Globalaudio.play_music_level(teeter)
		if current_level.name == "Exploration3":
			Globalaudio.play_music_level(magenta)
		if current_level.name == "Level12":
			Globalaudio.play_music_level(spurr)
		if current_level.name == "Level13":
			Globalaudio.play_music_level(blurr)
		if current_level.name == "Level15":
			Globalaudio.play_music_level(emerald)
	
	await get_tree().create_timer(0.1).timeout

func update_camera_target() -> void: 	
	$Player/RemoteTransform2D.remote_path = NodePath("")  
	
	await get_tree().process_frame

	Globals.level_camera = current_level.get_node("Camera2D")
	
	if Globals.level_camera: 
		Globals.level_camera.make_current()
		$Player/RemoteTransform2D.use_global_coordinates = true
		$Player/RemoteTransform2D.remote_path = Globals.level_camera.get_path()
		$Player/RemoteTransform2D.force_update_cache()
		global_position = global_position.round()
		Globals.level_camera.global_position = $Player.global_position.round()
		#Globals.level_camera.global_position = $Player.global_position
	else: 
		push_error("Current level " + current_level.name + " does not contain Camera2D")

func should_abandon_turn() -> bool:
	if (player_character.cur_health <= 0) or reloading:
		player_character.turn_over = true
		return true
	return false

# calculate ai_array
func calc_ai_array() -> void:
	# Wait one single frame to make sure any enemies that disappeared with queue_free() are gone
	var unsorted_array : Array[CharacterBody2D] = []
	# search to see if any enemies
	
	for child in current_level.find_children("*", "CharacterBody2D"):
		if "is_enemy" in child or child.get("is_enemy"):
			if "is_alive" in child:
				if !child.is_alive:
					# remove the entity, then wait one frame for it to disappear
					child.hide()
					child.process_mode = Node.PROCESS_MODE_DISABLED
					await get_tree().process_frame
				else:
					child.show()
					child.process_mode = Node.PROCESS_MODE_INHERIT
					await get_tree().process_frame
					unsorted_array.append(child)

	# sort them left to right, top to bottom
	# but for now
	ai_array = unsorted_array
	
	# returns the int representing the current level index

func load_game() -> int:
	var file = FileAccess.open("user://save.save", FileAccess.READ)
	if not FileAccess.file_exists("user://save.save"):
		return -1 # if no save is present, returns the starting index
	var saved_level = int(file.get_as_text())
	return saved_level
	
func pause(branch : Node):
	branch.process_mode = PROCESS_MODE_DISABLED

func unpause(branch : Node):
	branch.process_mode = PROCESS_MODE_INHERIT

func _ready() -> void:
	bus_index = AudioServer.get_bus_index(bus_name)
	Globals.player = $Player
	Globals.ui = $UI
	Globals.GameManager = self
	reloading = false
	pause_menu_node.game_resume.connect(unpause_game)
	pause_menu_node.reload_room.connect(reload_level)
	player_character.damaged.connect(_on_player_damaged)
	pause_menu.hide()
	pause(pause_menu_node)
	show()
	levels_scene.show()
	player_character.show()
	await load_level(current_level_index)
	next_turn()

	
func _on_player_damaged(current_health: int, max_health: int) -> void:
	Debug.say("Health: %s / %s" % [current_health, max_health])
	
	if Globals.GameManager.should_abandon_turn():
		reload_level(true)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_close_dialog") and !Globals.GameManager.should_abandon_turn():
		if paused == false:
			pause_game()
