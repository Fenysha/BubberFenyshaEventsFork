/obj/machinery/door
	var/list/autodir_list = list(
		/obj/machinery/door,
		/obj/structure/window/fulltile,
		/obj/structure/window/reinforced/fulltile,
		/obj/structure/window/reinforced/plasma/fulltile,
		/obj/structure/window/reinforced/tinted/fulltile
	)

/obj/machinery/door/post_machine_initialize()
	. = ..()
	SSshadow.queue_door(src)

// Additional check for auto-rotation
/obj/machinery/door/proc/find_list_object_in_dir(search_dir)
	var/turf/adjacent_turf = get_step(src, search_dir)
	if(!adjacent_turf)
		return 0

	for(var/atom/movable/item in adjacent_turf)
		if(is_type_in_list(item, autodir_list))
			return 3

	if(isclosedturf(adjacent_turf))
		return 2

	return 0

// Auto-rotate
/obj/machinery/door/proc/update_dir()
	var/north = find_list_object_in_dir(NORTH)
	var/south = find_list_object_in_dir(SOUTH)
	var/east  = find_list_object_in_dir(EAST)
	var/west  = find_list_object_in_dir(WEST)

	var/vertical_score   = north + south
	var/horizontal_score = east + west

	if(vertical_score == 0 && horizontal_score == 0)
		return

	var/new_dir

	if(horizontal_score > vertical_score)
		new_dir = (north < south) ? NORTH : SOUTH
	else if(vertical_score > horizontal_score)
		new_dir = (west < east) ? WEST : EAST
	else
		var/max_score = max(north, south, east, west)
		if(west == max_score)
			new_dir = EAST
		else if(east == max_score)
			new_dir = WEST
		else if(north == max_score)
			new_dir = SOUTH
		else
			new_dir = NORTH

	if(dir != new_dir)
		setDir(new_dir)
	update_icon()

// Mechanism for turning the gateway with a key
/obj/machinery/door/airlock/proc/airlock_dir_change(mob/user, obj/item/wrench, new_dir, time = 40)
	if(wrench.tool_behaviour != TOOL_WRENCH)
		return CANT_UNFASTEN

	if(time)
		to_chat(user, span_notice("You begin changing [src]'s direction..."))

	if(!wrench.use_tool(src, user, time))
		return FAILED_UNFASTEN

	wrench.play_tool_sound(src, 50)
	setDir(new_dir)

/obj/machinery/door/airlock/examine(mob/user)
	. = ..()
	. += span_notice("The <b>direction</b> of the airlock can be changed with a <b>wrench when the wiring is open</b>.")
