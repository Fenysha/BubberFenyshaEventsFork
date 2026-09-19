/datum/rimworld_planet
	/// Runtime planet cells.
	/// Key format: "[x]:[y]"
	var/list/cells = list()

/**
 * Returns the runtime key for a planet cell.
 */
/datum/rimworld_planet/proc/get_cell_key(cell_x, cell_y)
	return "[cell_x]:[cell_y]"

/**
 * Returns an already created runtime planet cell.
 *
 * Does not create or generate anything.
 */
/datum/rimworld_planet/proc/get_cell(cell_x, cell_y)
	if(!is_valid_coordinate(cell_x, cell_y))
		return null

	return cells[get_cell_key(cell_x, cell_y)]

/**
 * Loads a single runtime planet cell.
 */
/datum/rimworld_planet/proc/load_cell(cell_x, cell_y, poi_name = null)
	var/datum/planet_cell/cell = get_or_create_cell(cell_x, cell_y, FALSE)
	if(!cell)
		return FALSE
	return cell.load(poi_name)

/**
 * Unloads a single runtime planet cell.
 *
 * The cell object remains cached on the planet.
 */
/datum/rimworld_planet/proc/unload_cell(cell_x, cell_y)
	var/datum/planet_cell/cell = get_cell(cell_x, cell_y)

	if(!cell)
		return FALSE

	return cell.unload()

/**
 * Returns an existing planet cell or creates a new one.
 *
 * By default the cell is created without generating local terrain.
 * Set auto_generate to TRUE to immediately load it.
 */
/datum/rimworld_planet/proc/get_or_create_cell(cell_x, cell_y, auto_generate = FALSE)
	if(!is_valid_coordinate(cell_x, cell_y))
		return null

	var/key = get_cell_key(cell_x, cell_y)
	var/datum/planet_cell/cell = cells[key]

	if(cell)
		if(auto_generate && !cell.is_generated && !cell.is_generating)
			cell.generate_local_content()

		return cell

	cell = new /datum/planet_cell(
		src,
		cell_x,
		cell_y,
		auto_generate
	)

	if(!cell)
		return null

	cells[key] = cell

	return cell

/**
 * Completely destroys a runtime planet cell and removes it from the cache.
 */
/datum/rimworld_planet/proc/remove_cell(cell_x, cell_y)
	var/key = get_cell_key(cell_x, cell_y)
	var/datum/planet_cell/cell = cells[key]

	if(!cell)
		return FALSE

	cells -= key
	qdel(cell)

	return TRUE


/**
 * Generates a unique object id with the given prefix.
 */
/datum/rimworld_planet/proc/generate_object_id(prefix = "object")
	var/id
	do
		id = "[prefix]_[rand(1, 2000000000)]"
	while(objects[id])
	return id

/**
 * Adds an object to the planet. Returns TRUE on success.
 */
/datum/rimworld_planet/proc/add_object(datum/rimworld_planet_object/object)
	if(!object)
		return FALSE
	if(!is_valid_coordinate(object.x, object.y))
		return FALSE
	if(objects[object.id])
		return FALSE

	objects[object.id] = object

	if(istype(object, /datum/rimworld_planet_object/settlement))
		settlements[object.id] = object
	else if(istype(object, /datum/rimworld_planet_object/point_of_interest))
		points_of_interest[object.id] = object
	else if(istype(object, /datum/rimworld_planet_object/road))
		roads[object.id] = object

	return TRUE

/**
 * Removes an object by id. Returns TRUE on success.
 */
/datum/rimworld_planet/proc/remove_object(object_id)
	var/datum/rimworld_planet_object/object = objects[object_id]
	if(!object)
		return FALSE

	objects -= object_id
	settlements -= object_id
	points_of_interest -= object_id
	roads -= object_id
	return TRUE

/**
 * Returns an object by id, or null.
 */
/datum/rimworld_planet/proc/get_object(object_id)
	return objects[object_id]

/**
 * Returns all objects located at the given coordinates.
 */
/datum/rimworld_planet/proc/get_objects_at(x, y)
	var/list/result = list()
	for(var/object_id in objects)
		var/datum/rimworld_planet_object/object = objects[object_id]
		if(object.x == x && object.y == y)
			result += list(object.get_data())
	return result

/**
 * Returns all objects within the given radius.
 */
/datum/rimworld_planet/proc/get_objects_in_radius(x, y, radius)
	var/list/result = list()
	for(var/object_id in objects)
		var/datum/rimworld_planet_object/object = objects[object_id]
		if(get_tile_distance(x, y, object.x, object.y) <= radius)
			result += list(object.get_data())
	return result

/**
 * Moves an object to new coordinates. Returns TRUE on success.
 */
/datum/rimworld_planet/proc/move_object(object_id, new_x, new_y)
	var/datum/rimworld_planet_object/object = objects[object_id]
	if(!object)
		return FALSE
	if(!is_valid_coordinate(new_x, new_y))
		return FALSE
	object.x = new_x
	object.y = new_y
	return TRUE

/**
 * Creates and registers a new settlement.
 */
/datum/rimworld_planet/proc/create_settlement(x, y, settlement_name = "Settlement")
	if(!is_valid_coordinate(x, y))
		return null
	var/id = generate_object_id("settlement")
	var/datum/rimworld_planet_object/settlement/object = new /datum/rimworld_planet_object/settlement(id, x, y, settlement_name)
	if(!add_object(object))
		qdel(object)
		return null
	return object

/**
 * Creates and registers a new point of interest.
 */
/datum/rimworld_planet/proc/create_point_of_interest(x, y, poi_name = "Point of Interest")
	if(!is_valid_coordinate(x, y))
		return null
	var/id = generate_object_id("poi")
	var/datum/rimworld_planet_object/point_of_interest/object = new /datum/rimworld_planet_object/point_of_interest(id, x, y, poi_name)
	if(!add_object(object))
		qdel(object)
		return null
	return object

/**
 * Creates and registers a new road.
 */
/datum/rimworld_planet/proc/create_road(start_x, start_y, end_x, end_y)
	if(!is_valid_coordinate(start_x, start_y))
		return null
	if(!is_valid_coordinate(end_x, end_y))
		return null
	var/id = generate_object_id("road")
	var/datum/rimworld_planet_object/road/object = new /datum/rimworld_planet_object/road(id, start_x, start_y, end_x, end_y)
	if(!add_object(object))
		qdel(object)
		return null
	return object


/**
 * Returns a list of all interactive objects.
 */
/datum/rimworld_planet/proc/get_interactive_objects()
	var/list/result = list()
	for(var/object_id in objects)
		var/datum/rimworld_planet_object/object = objects[object_id]
		result += list(object.get_data())
	return result


/datum/rimworld_planet/proc/get_possible_biomes()
	RETURN_TYPE(/list)
	if(!possible_biomes)
		possible_biomes = list()
		for(var/type in subtypesof(/datum/biome/rimworld))
			var/datum/biome/rimworld/b = type
			if(!b:biome_key)
				qdel(b)
				continue
			possible_biomes[b:biome_key] = b
	return possible_biomes.Copy()
