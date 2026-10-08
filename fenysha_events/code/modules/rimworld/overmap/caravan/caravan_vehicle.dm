/**
 * ============================================================================
 * Vehicle ↔ overmap caravan bridge
 * ============================================================================
 *
 * Vehicles with an interior: body moves to nullspace, occupants stay in the
 * interior, the driver controls caravan movement via the map UI.
 *
 * Vehicles without an interior: treated like a fast foot caravan; occupants
 * are moved to the holding level (immobilised) unless we keep them "in" the
 * vehicle abstractly — here we park the vehicle in nullspace too and put
 * living occupants on the holding level for consistency.
 */

/**
 * Called from map-edge when a vehicle chooses to leave for the overmap.
 */
/proc/rimworld_vehicle_enter_overmap(obj/vehicle/sealed/V, datum/planet_cell/cell, exit_side)
	if(!V || !cell?.planet || V.rimworld_caravan)
		return null



	var/has_interior = FALSE
	if(istype(V, /obj/vehicle/sealed/armored/multitile))
		var/obj/vehicle/sealed/armored/multitile/MV = V
		has_interior = MV.interior
	var/list/occupants = V.return_occupants()
	var/mob/living/driver = null
	var/list/drivers = V.return_drivers()
	if(length(drivers))
		driver = drivers[1]

	var/datum/rimworld_caravan/C = new /datum/rimworld_caravan(cell.planet, cell.x, cell.y, driver)
	C.exit_side = exit_side
	C.register_vehicle(V, has_interior)

	if(has_interior)
		// Occupants remain inside the interior; vehicle body → nullspace
		V.forceMove(null)
		for(var/mob/living/M as anything in occupants)
			if(!M)
				continue
			if(!(M in C.members))
				C.add_member(M)
			// Do NOT immobilise interior occupants — they can walk inside the cabin
			C.mobilize_member(M)
			to_chat(M, span_notice("The vehicle leaves the local map. The driver can open the planetary caravan map."))
	else
		// No cabin: park vehicle, members go to holding level
		V.forceMove(null)
		for(var/mob/living/M as anything in occupants)
			if(!M)
				continue
			if(!(M in C.members))
				C.add_member(M)
			C.move_member_to_holding(M)
			to_chat(M, span_notice("You leave the local map with the vehicle."))

	if(driver)
		C.open_map_for(driver)
	else if(length(C.members))
		C.open_map_for(C.members[1])

	return C


/**
 * Icon used when this vehicle is shown as a caravan marker on the planetary map.
 * Override on subtypes to supply a dedicated map sprite; default is flat appearance.
 */
/obj/vehicle/sealed/proc/get_caravan_map_icon()
	return getFlatIcon(src, SOUTH, start = FALSE)


/**
 * Optional dedicated DMI path / state for planetary-map display.
 * If caravan_map_icon is set, it is preferred over getFlatIcon.
 */
/obj/vehicle/sealed/armored
	var/caravan_map_icon
	var/caravan_map_icon_state


/obj/vehicle/sealed/armored/get_caravan_map_icon()
	if(caravan_map_icon)
		return icon(caravan_map_icon, caravan_map_icon_state || "")
	return getFlatIcon(src, SOUTH, start = FALSE)


/**
 * Driver (or any member with drive control) may open the caravan UI while the
 * vehicle is on the overmap. Closing the UI does not stop passive travel —
 * movement is owned by the caravan datum, not the open window.
 */
/obj/vehicle/sealed/proc/rimworld_open_caravan_ui(mob/user)
	if(!rimworld_caravan)
		to_chat(user, span_warning("This vehicle is not on the planetary map."))
		return
	if(!(user in return_occupants()))
		to_chat(user, span_warning("You are not part of this caravan."))
		return
	rimworld_caravan.open_map_for(user)


/**
 * Leaving a vehicle while it is on the overmap creates a solo foot caravan
 * for the leaver. If the vehicle still has an open hatch / is enterable,
 * they can climb back in later (re-join the vehicle caravan).
 */
/obj/vehicle/sealed/proc/rimworld_on_overmap_exit(mob/living/leaver)
	if(!rimworld_caravan || !leaver)
		return FALSE

	var/datum/rimworld_caravan/parent = rimworld_caravan

	parent.remove_member(leaver, disband = TRUE)

	var/datum/rimworld_caravan/solo = new /datum/rimworld_caravan(
		parent.planet,
		parent.current_x,
		parent.current_y,
		leaver
	)
	solo.exit_side = parent.exit_side
	solo.move_member_to_holding(leaver)
	solo.open_map_for(leaver)

	to_chat(leaver, span_notice("You leave the vehicle and form your own caravan. You can re-enter the vehicle if it is still open."))

	// If nobody left in the vehicle caravan and no other members, keep vehicle caravan alive while vehicle exists
	if(!length(parent.members) && parent.vehicle)
		// Vehicle-only caravan remains until destroyed / re-entered
		return

	return TRUE


/**
 * Re-enter a vehicle that is already on the overmap (open hatch).
 * Merges the foot caravan into the vehicle's caravan.
 */
/obj/vehicle/sealed/proc/rimworld_on_overmap_reenter(mob/living/enterer)
	if(!rimworld_caravan || !enterer)
		return FALSE

	var/datum/rimworld_caravan/parent = rimworld_caravan
	var/datum/rimworld_caravan/foot = enterer.rimworld_caravan

	if(foot && foot != parent)
		foot.remove_member(enterer, disband = TRUE)
		if(!length(foot.members) && !foot.vehicle)
			qdel(foot)

	parent.add_member(enterer)
	if(parent.has_interior)
		parent.mobilize_member(enterer)
	else
		parent.move_member_to_holding(enterer)

	parent.open_map_for(enterer)
	to_chat(enterer, span_notice("You rejoin the vehicle caravan."))
	return TRUE


// Wire into armored exit/enter when on overmap
/obj/vehicle/sealed/armored/mob_exit(mob/leaving, silent = FALSE, randomstep = FALSE)
	if(rimworld_caravan && isliving(leaving))
		. = ..()
		rimworld_on_overmap_exit(leaving)
		return
	return ..()


/obj/vehicle/sealed/armored/mob_enter(mob/entering, silent = FALSE)
	if(rimworld_caravan && isliving(entering))
		. = ..()
		if(.)
			rimworld_on_overmap_reenter(entering)
		return
	return ..()
