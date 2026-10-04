@tool
extends StaticBody2D

@onready var tile_map_layer : TileMapLayer = $TileMapLayer

@onready var pounceoverable := false
@onready var landonable := false
@onready var moveonable := false
@onready var slashthroughable := false
@onready var level_exit := true



# We want to be able to customize every tile instance for specific textures / rotations
@export_group("Visuals")
@export_range(0, 1) var atlas_source_id : int = 0:
	set(value):
		atlas_source_id = value
		_update_stairs()
		
# Rotate tile in 90-degree steps 
@export_range(0, 3) var tile_rotation_steps : int = 0:
	set(value):
		tile_rotation_steps = value
		_update_stairs()

func _ready() -> void:
	_update_stairs()
	
func _update_stairs() -> void:
	if not is_inside_tree() or not tile_map_layer:
		return
	
	var local_atlas_coords := Vector2i(0, 0)
	tile_map_layer.set_cell(Vector2i(0, 0), atlas_source_id, local_atlas_coords)
	
	tile_map_layer.rotation_degrees = tile_rotation_steps * 90
	
	match tile_rotation_steps:
		0: tile_map_layer.position = Vector2(0,0)
		1: tile_map_layer.position = Vector2(Globals.grid_size,0)
		2: tile_map_layer.position = Vector2(Globals.grid_size,Globals.grid_size)
		3: tile_map_layer.position = Vector2(0,Globals.grid_size)

func unlock() -> void:
	atlas_source_id = 1
	moveonable = true
	landonable = true
	pounceoverable = true
	
	_update_stairs()
	
func lock() -> void:
	pass
