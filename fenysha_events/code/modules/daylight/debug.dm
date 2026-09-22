ADMIN_VERB(set_daylight_time, R_ADMIN, "Set Daylight Time (0-1)", "Force daylight intensity or return to auto", ADMIN_CATEGORY_EVENTS)
	if(!check_rights(R_ADMIN))
		return

	var/value = input(usr, "Set forced intensity (0 = night, 1 = day, -1 = auto)", "Daylight Control", -1) as num|null
	if(isnull(value))
		return

	value = clamp(value, -1, 1)
	if(value < 0)
		SSdaylight.manual_time = -1
		SSdaylight.time_locked = FALSE
		SSdaylight.cycle_locked = FALSE
	else
		SSdaylight.manual_time = value
		SSdaylight.time_locked = TRUE
		SSdaylight.cycle_locked = TRUE
		var/color = SSdaylight.get_manual_light_color(value)
		SSdaylight.set_intensity_and_color(value, color, force = TRUE)
		if(SSdaylight.use_planet_time)
			SSdaylight.set_all_rimworld_daylight(value, color)

	log_admin("[key_name(usr)] set daylight time to [value < 0 ? "AUTO" : value]")
	message_admins(span_adminnotice("[key_name_admin(usr)] set daytime: [value < 0 ? "auto" : value]"))


ADMIN_VERB(toggle_daylight_cycle_lock, R_ADMIN, "Toggle Daylight Cycle Lock", "Lock/unlock automatic day-night cycle", ADMIN_CATEGORY_EVENTS)
	if(!check_rights(R_ADMIN))
		return

	SSdaylight.cycle_locked = !SSdaylight.cycle_locked
	if(!SSdaylight.cycle_locked)
		SSdaylight.time_locked = FALSE
		SSdaylight.manual_time = -1
		if(SSdaylight.use_planet_time)
			SSdaylight.set_all_rimworld_daylight(null, null)

	log_admin("[key_name(usr)] [SSdaylight.cycle_locked ? "locked" : "unlocked"] daylight cycle")
	message_admins(span_adminnotice("[key_name_admin(usr)] [SSdaylight.cycle_locked ? "locked" : "unlocked"] daylight cycle"))


ADMIN_VERB(flash_daylight, R_ADMIN, "Flash Daylight", "Temporarily flash areas with a color", ADMIN_CATEGORY_EVENTS)
	if(!check_rights(R_ADMIN))
		return

	var/color = input(usr, "Choose flash color", "Flash Color") as color|null
	if(isnull(color))
		return

	var/duration = input(usr, "Set flash duration in seconds", "Flash Duration", 10) as num|null
	if(isnull(duration))
		return

	var/transition_time = input(usr, "Set transition time in seconds", "Transition Time", 2) as num|null
	if(isnull(transition_time))
		return

	SSdaylight.flash(color, duration SECONDS, transition_time SECONDS)

	log_admin("[key_name(usr)] triggered daylight flash with color [color] for [duration] seconds")
	message_admins(span_adminnotice("[key_name_admin(usr)] triggered daylight flash with color [color] for [duration] seconds"))


ADMIN_VERB(open_daylight_control_panel, R_ADMIN, "Open Daylight Control Panel", "Open UI panel for day/night and weather control", ADMIN_CATEGORY_EVENTS)
	if(!check_rights(R_ADMIN))
		return
	var/datum/daylight_control_panel/panel = new
	panel.ui_interact(usr)


ADMIN_VERB(daylight_reapply_lighting, R_ADMIN, "Daylight Reapply Area Lighting", "Re-add the daylight light overlay to all daylight areas", ADMIN_CATEGORY_EVENTS)
	if(!check_rights(R_ADMIN))
		return
	var/count = SSdaylight.reapply_lighting()
	to_chat(usr, span_notice("Reapplied the daylight light overlay to [count] daylight area(s)."))


/datum/daylight_control_panel


/datum/daylight_control_panel/ui_state(mob/user)
	return ADMIN_STATE(R_ADMIN)


/datum/daylight_control_panel/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "DaylightControl", "Daylight Control")
		ui.open()


/datum/daylight_control_panel/ui_data(mob/user)
	var/list/data = list()
	data["cycle_locked"] = SSdaylight.cycle_locked
	data["time_locked"] = SSdaylight.time_locked
	data["manual_time"] = SSdaylight.manual_time
	data["daylight_cycle"] = SSdaylight.daylight_cycle
	data["current_intensity"] = SSdaylight.current_intensity
	data["current_color"] = SSdaylight.current_color
	data["current_phase"] = SSdaylight.current_phase ? SSdaylight.current_phase.name : "Unknown"
	data["active_weather_count"] = (SSdaylight.visual_weather_override == "none") ? 0 : 1
	data["visual_weather_mode"] = SSdaylight.visual_weather_override
	data["use_planet_time"] = SSdaylight.use_planet_time
	if(SSdaylight.use_planet_time && SSrimworld_planetmap)
		data["planet_time_of_day"] = SSrimworld_planetmap.time_of_day
		data["planet_rotation"] = SSrimworld_planetmap.rotation_angle
		data["planet_year"] = SSrimworld_planetmap.current_year
		data["planet_quadrum"] = SSrimworld_planetmap.get_quadrum_name()
		data["planet_day"] = SSrimworld_planetmap.day_of_quadrum
	return data


/datum/daylight_control_panel/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	if(!check_rights_for(ui.user?.client, R_ADMIN))
		return

	switch(action)
		if("set_manual")
			var/value = text2num(params["value"])
			value = clamp(value, -1, 1)
			if(value < 0)
				SSdaylight.manual_time = -1
				SSdaylight.time_locked = FALSE
				SSdaylight.cycle_locked = FALSE
				if(SSdaylight.use_planet_time)
					SSdaylight.set_all_rimworld_daylight(null, null)
			else
				SSdaylight.manual_time = value
				SSdaylight.time_locked = TRUE
				SSdaylight.cycle_locked = TRUE
				var/color = SSdaylight.get_manual_light_color(value)
				SSdaylight.set_intensity_and_color(value, color, force = TRUE)
				if(SSdaylight.use_planet_time)
					SSdaylight.set_all_rimworld_daylight(value, color)
			return TRUE

		if("set_cycle_minutes")
			var/new_cycle = clamp(round(text2num(params["value"]), 1), 5, 240)
			SSdaylight.daylight_cycle = new_cycle
			return TRUE

		if("toggle_cycle_lock")
			SSdaylight.cycle_locked = !SSdaylight.cycle_locked
			if(!SSdaylight.cycle_locked)
				SSdaylight.time_locked = FALSE
				SSdaylight.manual_time = -1
				if(SSdaylight.use_planet_time)
					SSdaylight.set_all_rimworld_daylight(null, null)
			return TRUE

		if("set_auto")
			SSdaylight.manual_time = -1
			SSdaylight.time_locked = FALSE
			SSdaylight.cycle_locked = FALSE
			if(SSdaylight.use_planet_time)
				SSdaylight.set_all_rimworld_daylight(null, null)
			return TRUE

		if("set_planet_hour")
			if(!SSdaylight.use_planet_time || !SSrimworld_planetmap)
				return FALSE
			var/hour = text2num(params["value"])
			if(isnull(hour))
				return FALSE
			SSrimworld_planetmap.set_time_of_day(hour)
			return TRUE

		if("start_weather")
			var/selected = params["weather_type"]
			switch(selected)
				if("rain")
					SSdaylight.visual_weather_override = "rain"
				if("snow")
					SSdaylight.visual_weather_override = "snow"
				if("radiation")
					SSdaylight.visual_weather_override = "dust"
				if("mist")
					SSdaylight.visual_weather_override = "mist"
				if("auto")
					SSdaylight.visual_weather_override = "auto"
			log_admin("[key_name(ui.user)] switched visual weather to [SSdaylight.visual_weather_override] from daylight control panel")
			message_admins(span_adminnotice("[key_name_admin(ui.user)] switched visual weather to [SSdaylight.visual_weather_override] from daylight control panel"))
			return TRUE

		if("stop_weather")
			SSdaylight.visual_weather_override = "none"
			log_admin("[key_name(ui.user)] disabled visual weather from daylight control panel")
			message_admins(span_adminnotice("[key_name_admin(ui.user)] disabled visual weather from daylight control panel"))
			return TRUE

	return FALSE
