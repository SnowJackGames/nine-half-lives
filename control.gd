extends Control

@onready var scene = load("res://scenes/Node2D.tscn")
@onready var title = $CanvasLayer/TitleScreenTexture

#
## Called when the node enters the scene tree for the first time.
#func _ready() -> void:
	#pass
#
#
## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(_delta: float) -> void:
	#if Input.is_action_pressed("ui_accept"):
		#var instance = scene.instantiate()
		#add_child(instance)
		#title.hide()
