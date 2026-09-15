/*
 * Copyright (c) 2026 Fenysha
 * SPDX-License-Identifier: MIT
 *
 * Original implementation by Fenysha.
 */


SUBSYSTEM_DEF(rimworld_planetmap)

	name = "\[RW\] Planet map"
	wait = 10
	ss_flags = SS_BACKGROUND

	var/datum/rimworld_planet/planet
	var/default_planet_type = RW_PLANET_PRESET_TERRAN
	var/list/active_views = list()


/datum/controller/subsystem/rimworld_planetmap/Initialize()

	planet = new /datum/rimworld_planet(null, default_planet_type)
	planet.generate()

	return SS_INIT_SUCCESS


/datum/controller/subsystem/rimworld_planetmap/proc/generate_planet(planet_type = RW_PLANET_PRESET_TERRAN, planet_seed = null, list/custom_params = null)
	if(planet)
		qdel(planet)

	planet = new /datum/rimworld_planet(planet_seed, planet_type, custom_params)
	planet.generate()

	for(var/datum/planetmap_view/view as anything in active_views)
		view.bind_planet(planet)

	return planet


/datum/controller/subsystem/rimworld_planetmap/proc/register_view(datum/planetmap_view/view)
	if(view)
		active_views |= view


/datum/controller/subsystem/rimworld_planetmap/proc/unregister_view(datum/planetmap_view/view)
	active_views -= view


/datum/controller/subsystem/rimworld_planetmap/proc/find_view(mob/user, view_type)
	for(var/datum/planetmap_view/view as anything in active_views)
		if(view.viewer == user && view.view_type == view_type)
			return view

	return null


/datum/controller/subsystem/rimworld_planetmap/proc/open_view(mob/user, datum/planetmap_view/view_path = /datum/planetmap_view/overview)
	if(!user || !planet)
		return null

	var/datum/planetmap_view/existing = find_view(user, initial(view_path.view_type))

	if(existing)
		existing.ui_interact(user)
		return existing

	var/datum/planetmap_view/view = new view_path(user, planet)
	view.ui_interact(user)
	return view


/datum/controller/subsystem/rimworld_planetmap/proc/open_admin_view(mob/user)
	return open_view(user, /datum/planetmap_view/admin)


/datum/controller/subsystem/rimworld_planetmap/proc/open_overview(mob/user)
	return open_view(user, /datum/planetmap_view/overview)


/datum/controller/subsystem/rimworld_planetmap/proc/open_caravan_view(mob/user, caravan_id = null, origin_x = null, origin_y = null)
	if(!user || !planet)
		return null

	var/datum/planetmap_view/caravan/existing = find_view(user, "caravan")

	if(existing)
		existing.ui_interact(user)
		return existing

	var/datum/planetmap_view/caravan/view = new(user, planet, caravan_id, origin_x, origin_y)
	view.ui_interact(user)
	return view


ADMIN_VERB(open_planet_map, R_ADMIN, "\[RW\] Open planet map", "Open the planetary admin map.", ADMIN_CATEGORY_EVENTS)
	SSrimworld_planetmap.open_admin_view(usr)
