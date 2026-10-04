extends Control

#signals when it's time to reload the room
signal animation_finished

@onready var animation_player = $CanvasLayer/AnimationPlayer

func _ready() -> void:
	$CanvasLayer.hide()

func play_game_over():
	$CanvasLayer.show()
	animation_player.play("game_over")
	
func play_fade_out():
	$CanvasLayer.show()
	animation_player.play("fade-to-black")
	
func play_fade_in():
	$CanvasLayer.show()
	animation_player.play("fade-from-black")

func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	animation_finished.emit()
	
func clean_up() -> void:
	$CanvasLayer.hide()
