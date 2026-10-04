extends Control


signal animation_finished

@onready var animation_player = $CanvasLayer/AnimationPlayer

func _ready() -> void:
	$title_screen.hide()
	$CanvasLayer.hide()
	animation_player.animation_finished.connect(_on_animation_player_animation_finished)

func run_start_sequence() -> void:
	$CanvasLayer.show()
	$title_screen.hide()
	animation_player.play("opening_sequence")
	
func start_menu() -> void:
	$CanvasLayer.hide()
	$title_screen.show()
	
func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	animation_finished.emit()
	

func clean_up() -> void:
	$CanvasLayer.hide()
	$title_screen.hide()
