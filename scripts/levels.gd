extends Node2D


const steppin = preload("res://sound/music/Side Steppin'.mp3")
const blurr = preload("res://sound/music/Blurr.mp3")
const emerald = preload("res://sound/music/Emerald Gold.mp3")
const magenta = preload("res://sound/music/Magenta.mp3")
const opening = preload("res://sound/music/Opening.mp3")
const spurr = preload("res://sound/music/Spurr.mp3")
const teeter = preload("res://sound/music/Teeter.mp3")


@onready var level_order = [
	
	
	$Tutorial1,
	$Exploration0,
	$Level1,
	$Level2,
	$Level3,
	$Level4,
	$Level5,
	$Exploration1,
	$Level6,
	$Level7,
	$Exploration2,
	$Level8,
	$Level9,
	$Level10,
	$Level11,
	$Exploration3,
	$Level12,
	$Level13,
	$Level14,
	$Level15,
	$Level16,
	$Level17,
	$Level18,
	
]


func _ready() -> void:
	Globalaudio.play_music_level(steppin)
	disable_all()


func disable_all() -> void:
	print("disabling everything MEOWWWW")
	for level in level_order:
		level.visible = false
		level.process_mode = PROCESS_MODE_DISABLED
		
		#Disable Wall collision
		var collisionDisable = get_node(str(level))
		var collisionDisable2 = str(collisionDisable.name)
		print(collisionDisable2 + "/Elements/WallTiles")
		
		
		var collisionDisable3 = get_node(collisionDisable2 + "/Elements/WallTiles")
		print(collisionDisable3)
		
		if collisionDisable3 != null:
			collisionDisable3.collision_enabled = false
