extends Marker2D

func check_end_point(pos: Vector2) -> Array:
	var space_state := get_world_2d().direct_space_state
	var query := PhysicsPointQueryParameters2D.new()
	query.position = pos
	return space_state.intersect_point(query)

func is_empty(pos: Vector2) -> bool:
	return check_end_point(pos).is_empty()

func contains(pos: Vector2, object_name: String) -> bool:
	var results := check_end_point(pos)
	if results.is_empty():
		return false

	for result in results:
		if result.collider.name == object_name:
			return true
	return false

func objectnamesatspot(pos: Vector2) -> Array:
	var results := check_end_point(pos)
	var objectnames : Array[String]
	if results.is_empty():
		return []
	
	for result in results:
		if result.collider.name:
			objectnames.append(str(result.collider.name))
	
	return objectnames

func tile_damage_ground(pos) -> int:
	var results := check_end_point(pos)
	var dmg := 0
	if results.is_empty():
		return 0
	
	for result in results:
		if "tile_damage_ground" in result.collider:
			dmg += result.collider.tile_damage_ground
	
	return dmg
	
func tile_damage_air(pos) -> int:
	var results := check_end_point(pos)
	var dmg := 0
	if results.is_empty():
		return 0
	
	for result in results:
		if "tile_damage_air" in result.collider:
			dmg += result.collider.tile_damage_air
	
	return dmg

func moveonable(pos) -> bool:
	return has_attribute(pos, "moveonable")

func pounceoverable(pos) -> bool:
	return has_attribute(pos, "pounceoverable")

func landonable(pos) -> bool:
	return has_attribute(pos, "landonable")

func slashthroughable(pos) -> bool:
	return has_attribute(pos, "slashthroughable")
	
func damageable(pos) -> bool:
	return has_attribute(pos, "damageable")
	
func damage_object(pos, amt: int) -> void:
	var results := check_end_point(pos)
	if !results.is_empty():
		for result in results:
			if is_instance_valid(result.collider):
				if "is_enemy" in result.collider or result.collider.get("is_enemy"):
					if result.collider.is_enemy:
						Globals.entity_to_damage = result.collider
						await Globals.entity_to_damage.take_damage(amt)
				elif "is_player" in result.collider or result.collider.get("is_player"):
					if result.collider.is_player:
						Globals.entity_to_damage = result.collider
						await Globals.entity_to_damage.take_damage(amt)

func damage_enemy(pos, amt: int) -> void:
	var results := check_end_point(pos)
	if !results.is_empty():
		for result in results:
			if is_instance_valid(result.collider):
				if "is_enemy" in result.collider or result.collider.get("is_enemy"):
					if result.collider.is_enemy:
						Globals.entity_to_damage = result.collider
						await Globals.entity_to_damage.take_damage(amt)

func damage_player(pos, amt: int) -> void:
	var results := check_end_point(pos)
	if !results.is_empty():
		for result in results:
			if is_instance_valid(result.collider):
				if "is_player" in result.collider or result.collider.get("is_player"):
					if result.collider.is_enemy:
						Globals.entity_to_damage = result.collider
						await Globals.entity_to_damage.take_damage(amt)
	
func has_attribute(pos : Vector2, attribute : String) -> bool:
	var results := check_end_point(pos)
	
	if results.is_empty():
		return false

	for result in results:
		if not attribute in result.collider or not result.collider.get(attribute):
			return false
		
	return true

func enemy_on_tile(pos) -> bool:
	var results := check_end_point(pos)
	if results.is_empty():
		return false
	for result in results:
		if "is_enemy" in result.collider or result.collider.get("is_enemy"):
			if result.collider.is_enemy:
				return true
	
	return false

func get_enemy_path_from_spot(pos) -> Variant:
	var results := check_end_point(pos)
	if results.is_empty():
		return
		
	for result in results:
		if "is_enemy" in result.collider or result.collider.get("is_enemy"):
			if result.collider.is_enemy:
				return result.collider.get_path()
	return ""

func player_on_tile(pos) -> bool:
	var results := check_end_point(pos)
	if results.is_empty():
		return false
	for result in results:
		if "is_player" in result.collider or result.collider.get("is_player"):
			if result.collider.is_player:
				return true
	
	return false
