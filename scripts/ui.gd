extends Control

@onready var attack_combat_atlas = $CanvasLayer/AttackCombatHover.texture
@onready var health_ones_atlas = $CanvasLayer/HealthOnes.texture

func _ready() -> void:
	hide_all()

func hide_all() -> void:
	hide()
	for node in $CanvasLayer.get_children():
		node.hide()

func attack_combat_hover(index : int) -> void:
	hide_all()
	show()
	$CanvasLayer.show()
	health(Globals.player.cur_health)
	# Slash
	if index == 0:
		attack_combat_atlas.region = Rect2(0,0,0,0)
	# Pounce
	elif index == 1:
		attack_combat_atlas.region = Rect2(160,0,0,0)
	# Knight
	elif index == 2:
		attack_combat_atlas.region = Rect2(320,0,0,0)
	# skip
	elif index == 3:
		attack_combat_atlas.region = Rect2(480,0,0,0)
	else:
		push_error("impossible index given to attack_combat_hover in ui.gd")
	
	$CanvasLayer/AttackCombatHover.show()


func move_combat_hover() -> void:
	hide_all()
	show()
	$CanvasLayer.show()
	$CanvasLayer/MoveCombatHover.show()
	$CanvasLayer/Health.show()
	$CanvasLayer/HealthTens.show()
	health(Globals.player.cur_health)
	
func attack_combat_return_hover() -> void:
	hide_all()
	show()
	$CanvasLayer.show()
	$CanvasLayer/AttackCombatReturnHover.show()
	health(Globals.player.cur_health)
	
func health(h := 15) -> void:
	$CanvasLayer/Health.show()
	if h >= 10:
		$CanvasLayer/HealthTens.show()
	else:
		$CanvasLayer/HealthTens.hide()
	$CanvasLayer/HealthOnes.show()
	var ones_place = h % 10
	if ones_place == 0:
		health_ones_atlas.region = Rect2(0,0,16,16)
	elif ones_place == 1:
		health_ones_atlas.region = Rect2(16,0,16,16)
	elif ones_place == 2:
		health_ones_atlas.region = Rect2(32,0,16,16)
	elif ones_place == 3:
		health_ones_atlas.region = Rect2(48,0,16,16)
	elif ones_place == 4:
		health_ones_atlas.region = Rect2(0,16,16,16)
	elif ones_place == 5:
		health_ones_atlas.region = Rect2(16,16,16,16)
	elif ones_place == 6:
		health_ones_atlas.region = Rect2(32,16,16,16)
	elif ones_place == 7:
		health_ones_atlas.region = Rect2(48,16,16,16)
	elif ones_place == 8:
		health_ones_atlas.region = Rect2(0,32,16,16)
	elif ones_place == 9:
		health_ones_atlas.region = Rect2(16,32,16,16)


func win() -> void:
	hide_all()
	show()
	$CanvasLayer.show()
	$CanvasLayer/WinScreen.show()
