// Sheet for automatic spread
/obj/machinery/door
	var/list/autodir_list = list(
		/obj/machinery/door/poddoor,
		/obj/machinery/door/airlock,
		/obj/structure/window/fulltile,
		/obj/structure/window/reinforced/fulltile,
		/obj/structure/window/reinforced/plasma/fulltile,
		/obj/structure/window/reinforced/tinted/fulltile
	)

/obj/machinery/door/poddoor/Initialize(mapload)
	. = ..()
	update_dir()

/obj/machinery/door/airlock/Initialize(mapload)
	. = ..()
	update_dir()

// Additional check for auto-rotation
/obj/machinery/door/proc/find_list_object_in_dir(search_dir)
	var/turf/adjacent_turf = get_step(src, search_dir)
	var/obj/item = null

	for(item in adjacent_turf)
		if(is_type_in_list(item, autodir_list))
			return 3

	if(istype(adjacent_turf, /turf/closed/wall))
		return 2 // Wall priority less than object from list

	return 0

// Auto-rotate
/obj/machinery/door/proc/update_dir()
	var/horizontal = find_list_object_in_dir(WEST) + find_list_object_in_dir(EAST)
	var/vertical = find_list_object_in_dir(NORTH) + find_list_object_in_dir(SOUTH)
	if(horizontal > vertical)
		setDir(2)
	else
		setDir(4)

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
