/**
 * ============================================================================
 * Map-edge exit zones for loaded planet cells
 * ============================================================================
 *
 * After a cell finishes loading, edge turfs are tagged and we register
 * COMSIG_ATOM_ENTERED on each of them. Crossing an edge turf offers to leave
 * for the planetary map. A thin visual marker is still spawned for feedback.
 *
 * Exit cooldown is stored on the planet_cell and set by callers — this file
 * only reads it.
 */

/obj/effect/rimworld_map_edge
	name = "map edge"
	desc = "The edge of the loaded region. Crossing it lets you leave for the planetary map."
	icon = 'icons/hud/screen_gen.dmi'
	icon_state = "living1"
	alpha = 90
	anchored = TRUE
	density = FALSE
	opacity = FALSE
	mouse_opacity = MOUSE_OPACITY_ICON
	layer = ABOVE_MOB_LAYER
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF

	var/datum/planet_cell/cell
	var/exit_side // NORTH/SOUTH/EAST/WEST


/obj/effect/rimworld_map_edge/Initialize(mapload, datum/planet_cell/parent_cell, side)
	. = ..()
	cell = parent_cell
	exit_side = side
	if(cell)
		LAZYADD(cell.edge_markers, src)

	var/turf/T = get_turf(src)
	if(T)
		RegisterSignal(T, COMSIG_ATOM_ENTERED, PROC_REF(on_turf_entered))


/obj/effect/rimworld_map_edge/Destroy(force)
	var/turf/T = loc
	if(istype(T))
		UnregisterSignal(T, COMSIG_ATOM_ENTERED)

	if(cell)
		LAZYREMOVE(cell.edge_markers, src)
		cell = null
	return ..()


/obj/effect/rimworld_map_edge/proc/on_turf_entered(turf/source, atom/movable/arrived, atom/old_loc)
	SIGNAL_HANDLER
	try_exit(arrived)


/obj/effect/rimworld_map_edge/attack_hand(mob/living/user)
	try_exit(user)
	return TRUE


/**
 * Entry point for living mobs and vehicles that enter an edge turf.
 */
/obj/effect/rimworld_map_edge/proc/try_exit(atom/movable/AM)
	if(!cell || QDELETED(cell) || !cell.is_loaded())
		return

	if(istype(AM, /obj/vehicle/sealed))
		try_exit_vehicle(AM)
		return

	if(!isliving(AM))
		return

	var/mob/living/user = AM
	if(user.rimworld_caravan)
		return

	if(cell.is_exit_on_cooldown())
		to_chat(user, span_warning("This region is locked down — you cannot leave yet. ([cell.get_exit_cooldown_text()])"))
		return

	INVOKE_ASYNC(src, PROC_REF(prompt_and_exit_mob), user)


/obj/effect/rimworld_map_edge/proc/prompt_and_exit_mob(mob/living/user)
	if(QDELETED(user) || QDELETED(src) || !cell)
		return

	var/choice = tgui_alert(
		user,
		"Leave this region and travel on the planetary map?",
		"Exit to Overmap",
		list("Leave", "Stay")
	)
	if(choice != "Leave" || QDELETED(user) || QDELETED(src) || !cell)
		return

	if(cell.is_exit_on_cooldown())
		to_chat(user, span_warning("This region is locked down — you cannot leave yet."))
		return

	var/turf/user_turf = get_turf(user)
	if(!user_turf || (get_dist(user, src) > 1 && !(src in user_turf.contents)))
		to_chat(user, span_warning("You moved away from the map edge."))
		return

	create_foot_caravan(user, cell, exit_side)


/obj/effect/rimworld_map_edge/proc/try_exit_vehicle(obj/vehicle/sealed/V)
	if(!V || QDELETED(V) || V.rimworld_caravan)
		return
	if(cell.is_exit_on_cooldown())
		for(var/mob/occupant as anything in V.return_occupants())
			to_chat(occupant, span_warning("This region is locked down — the vehicle cannot leave yet."))
		return

	INVOKE_ASYNC(src, PROC_REF(prompt_and_exit_vehicle), V)


/obj/effect/rimworld_map_edge/proc/prompt_and_exit_vehicle(obj/vehicle/sealed/V)
	if(QDELETED(V) || QDELETED(src) || !cell)
		return

	var/mob/driver = length(V.return_drivers()) ? V.return_drivers()[1] : null
	var/mob/prompter = driver || (length(V.return_occupants()) ? V.return_occupants()[1] : null)
	if(!prompter)
		return

	var/choice = tgui_alert(
		prompter,
		"Drive this vehicle onto the planetary map?",
		"Exit to Overmap",
		list("Leave", "Stay")
	)
	if(choice != "Leave" || QDELETED(V) || QDELETED(src) || !cell)
		return

	if(cell.is_exit_on_cooldown())
		to_chat(prompter, span_warning("This region is locked down."))
		return

	rimworld_vehicle_enter_overmap(V, cell, exit_side)


// ── Cell edge placement / cooldown ───────────────────────────────────────────

/datum/planet_cell
	/// Exit lock until this world.time
	var/exit_cooldown_until = 0
	/// Placed map-edge markers
	var/list/obj/effect/rimworld_map_edge/edge_markers


/datum/planet_cell/proc/is_exit_on_cooldown()
	return world.time < exit_cooldown_until


/datum/planet_cell/proc/set_exit_cooldown(duration)
	exit_cooldown_until = world.time + duration


/datum/planet_cell/proc/get_exit_cooldown_text()
	if(!is_exit_on_cooldown())
		return "ready"
	var/left = max(0, exit_cooldown_until - world.time)
	return "[round(left / 10, 0.1)]s"


/datum/planet_cell/proc/clear_edge_markers()
	for(var/obj/effect/rimworld_map_edge/E as anything in edge_markers)
		if(!QDELETED(E))
			qdel(E)
	edge_markers = null


/**
 * Place edge overlays along the reservation perimeter and register
 * COMSIG_ATOM_ENTERED on those turfs (via the marker Initialize).
 * Call after the cell finishes loading.
 */
/datum/planet_cell/proc/place_edge_markers()
	clear_edge_markers()
	if(!is_loaded())
		return

	var/turf/BL = reservation.get_inner_bottom_left_turf()
	var/turf/TR = reservation.get_inner_top_right_turf()
	if(!BL || !TR)
		return

	for(var/x = BL.x to TR.x)
		var/turf/T = locate(x, BL.y, BL.z)
		if(T)
			new /obj/effect/rimworld_map_edge(T, src, SOUTH)

	for(var/x = BL.x to TR.x)
		var/turf/T = locate(x, TR.y, BL.z)
		if(T)
			new /obj/effect/rimworld_map_edge(T, src, NORTH)

	for(var/y = BL.y + 1 to TR.y - 1)
		var/turf/T = locate(BL.x, y, BL.z)
		if(T)
			new /obj/effect/rimworld_map_edge(T, src, WEST)

	for(var/y = BL.y + 1 to TR.y - 1)
		var/turf/T = locate(TR.x, y, BL.z)
		if(T)
			new /obj/effect/rimworld_map_edge(T, src, EAST)


// Unload cleanup is handled in planet_tile.dm unload_local_content().
