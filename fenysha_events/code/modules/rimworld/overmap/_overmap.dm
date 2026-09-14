SUBSYSTEM_DEF(rimworld_planetmap)
	name = "\[RW\] Planet map"
	wait = 10
	ss_flags = SS_BACKGROUND

	var/datum/rimworld_planet/planet

/datum/controller/subsystem/rimworld_planetmap/Initialize()
	planet = new /datum/rimworld_planet
	planet.generate()

	return SS_INIT_SUCCESS


/datum/controller/subsystem/rimworld_planetmap/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)

	if(!ui)
		ui = new(user, src, "RimworldPlanetMap")
		ui.open()

/datum/controller/subsystem/rimworld_planetmap/ui_data(mob/user)
	return planet?.get_map_data() || list()


/datum/controller/subsystem/rimworld_planetmap/ui_state(mob/user)
	return GLOB.always_state


/datum/controller/subsystem/rimworld_planetmap/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()

	if(.)
		return

	switch(action)
		if("select_tile")
			var/x = text2num(params["x"])
			var/y = text2num(params["y"])

			if(!planet?.is_valid_coordinate(x, y))
				return

			// Detailed tile data can be handled here later.
			. = TRUE

		if("select_object")
			var/object_id = params["id"]

			if(!planet?.get_object(object_id))
				return

			// Object interaction can be handled here later.
			. = TRUE


ADMIN_VERB(open_planet_map, R_ADMIN, "\[RW\] Open planet map", "Open planet map.", ADMIN_CATEGORY_EVENTS)
	SSrimworld_planetmap.ui_interact(usr)
