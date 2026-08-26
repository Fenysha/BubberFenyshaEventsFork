ADMIN_VERB(set_daylight_time, R_ADMIN, "Set Daylight Time (0-1)", "Force daylight intensity or return to auto", ADMIN_CATEGORY_EVENTS)
	if(!check_rights(R_ADMIN))
		return

	var/value = input(usr, "Set forced intensity (0 = night, 1 = day, -1 = auto)", "Daylight Control", -1) as num|null
	if(isnull(value))
		return

	value = clamp(value, -1, 1)
	SSdaylight.manual_time = (value < 0 ? -1 : value)
	SSdaylight.time_locked = (value >= 0)
	SSdaylight.cycle_locked = (value >= 0)

	if(value >= 0)
		var/color = SSdaylight.get_manual_light_color(value)
		SSdaylight.set_intensity_and_color(value, color, FALSE)

	log_admin("[key_name(usr)] set daylight time to [value == -1 ? "AUTO" : value]")
	message_admins(span_adminnotice("[key_name_admin(usr)] set daytime: [value == -1 ? "auto" : value]"))

ADMIN_VERB(toggle_daylight_cycle_lock, R_ADMIN, "Toggle Daylight Cycle Lock", "Lock/unlock automatic day-night cycle", ADMIN_CATEGORY_EVENTS)
	if(!check_rights(R_ADMIN))
		return

	SSdaylight.cycle_locked = !SSdaylight.cycle_locked
	if(!SSdaylight.cycle_locked)
		SSdaylight.time_locked = FALSE
		SSdaylight.manual_time = -1

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

// ================= Daylight debugging (temporary) =================
// "Status Report" - confirms the daylight SOURCE exists + is registered on your screen, and how many daylight
//   areas got their per-turf light overlays. If 0 areas are lit, run "Reapply Area Lighting". If the source isn't
//   on your screen, run "Re-register Source".

ADMIN_VERB(daylight_debug_report, R_ADMIN, "Daylight Status", "Print daylight diagnostics", ADMIN_CATEGORY_EVENTS)
	var/list/lines = list()
	lines += "Daylight areas registered: [length(SSdaylight.daylight_areas)]"
	var/lit = 0
	for(var/area/daylit_area as anything in SSdaylight.daylight_areas)
		if(daylit_area.daylight_lit)
			lit++
	lines += "Areas with light overlay painted: [lit]"
	var/obj/daylight_wash_source/source = SSdaylight.wash_source
	if(source)
		lines += "Daylight source: present (color [source.color], alpha [source.alpha], target [source.render_target])"
		lines += "Source on your screen: [(usr.canon_client && (source in usr.canon_client.screen)) ? "YES" : "NO"]"
	else
		lines += "Daylight source: MISSING"
	lines += "Anchor plane on your HUD: [usr.hud_used?.get_plane_master(RENDER_PLANE_DAYLIGHT) ? "YES" : "NO"]"
	// Intensity state. The source's alpha is driven entirely from these, so if
	// alpha is 0 the answer is always somewhere in this block.
	lines += "--- intensity ---"
	lines += "current_intensity: [SSdaylight.current_intensity] (-> alpha [round(clamp(SSdaylight.current_intensity, 0, 1) * 255, 1)])"
	lines += "target_intensity: [SSdaylight.target_intensity] | start_intensity: [SSdaylight.start_intensity]"
	lines += "transition_steps: [SSdaylight.transition_steps]"
	lines += "current_color: [SSdaylight.current_color] | target_color: [SSdaylight.target_color]"
	lines += "--- cycle ---"
	lines += "phase: [SSdaylight.current_phase?.name || "NONE"] (intensity [SSdaylight.current_phase?.target_intensity]) -> next: [SSdaylight.next_phase?.name || "NONE"]"
	lines += "phase progress: [SSdaylight.get_phase_progress()] | cycle progress: [SSdaylight.get_cycle_progress()]"
	lines += "STATION_TIME_PASSED: [STATION_TIME_PASSED()] ds ([round(STATION_TIME_PASSED() / (1 HOURS), 0.01)] station hours)"
	lines += "manual_time: [SSdaylight.manual_time] | time_locked: [SSdaylight.time_locked] | cycle_locked: [SSdaylight.cycle_locked]"
	to_chat(usr, span_boldnotice("== Daylight debug ==\n[lines.Join("\n")]"))



/datum/controller/subsystem/daylight/proc/reapply_lighting()
	var/count = 0
	for(var/area/daylit_area as anything in SSdaylight.daylight_areas)
		daylit_area.clear_daylight_overlay()
		daylit_area.apply_daylight_overlay()
		count++
	return count

ADMIN_VERB(daylight_debug_reapply_lighting, R_ADMIN, "Daylight Reapply Area Lighting", "Re-add the daylight light overlay to all daylight areas", ADMIN_CATEGORY_EVENTS)
	var/count = SSdaylight.reapply_lighting()
	to_chat(usr, span_notice("Reapplied the daylight light overlay to [count] daylight area(s)."))

ADMIN_VERB(daylight_debug_reregister_source, R_ADMIN, "Daylight Re-register Source", "Re-add the daylight source to your screen", ADMIN_CATEGORY_EVENTS)
	if(!SSdaylight.wash_source)
		to_chat(usr, span_warning("No daylight source exists yet."))
		return
	usr.hud_used?.register_reuse(SSdaylight.wash_source)
	to_chat(usr, span_notice("Re-registered the daylight source onto your screen."))

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
			SSdaylight.manual_time = (value < 0 ? -1 : value)
			SSdaylight.time_locked = (value >= 0)
			SSdaylight.cycle_locked = (value >= 0)
			if(value >= 0)
				var/color = SSdaylight.get_manual_light_color(value)
				SSdaylight.set_intensity_and_color(value, color, FALSE)
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
			return TRUE

		if("set_auto")
			SSdaylight.manual_time = -1
			SSdaylight.time_locked = FALSE
			SSdaylight.cycle_locked = FALSE
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

/datum/preference/toggle/daylight_tint_fx
	category = PREFERENCE_CATEGORY_GAME_PREFERENCES
	savefile_key = "daylight_tint_fx"
	savefile_identifier = PREFERENCE_PLAYER

/datum/preference/toggle/daylight_tint_fx/create_default_value()
	return TRUE

/datum/preference/toggle/daylight_particle_fx
	category = PREFERENCE_CATEGORY_GAME_PREFERENCES
	savefile_key = "daylight_particle_fx"
	savefile_identifier = PREFERENCE_PLAYER

/datum/preference/toggle/daylight_particle_fx/create_default_value()
	return TRUE

/// Reports whether the daylight overlay is actually present on turfs, which is
/// the step between "the area says it painted" and "you can see light". An area
/// can report daylight_lit while individual turfs lost the overlay (turf
/// changes, ChangeTurf, template reloads).
ADMIN_VERB(daylight_debug_turf_overlays, R_ADMIN, "Daylight Turf Overlay Check", "Check which nearby turfs carry the daylight overlay", ADMIN_CATEGORY_EVENTS)
	var/turf/origin = get_turf(usr)
	if(!origin)
		to_chat(usr, span_warning("You are not on a turf."))
		return

	var/mutable_appearance/light = get_daylight_overlay_appearance(255, origin)
	var/area/here = origin.loc

	var/list/lines = list()
	lines += "Your turf: [origin] ([origin.x],[origin.y],[origin.z])"
	lines += "Your area: [here] (daylight: [here?.daylight ? "YES" : "no"], painted: [here?.daylight_lit ? "YES" : "no"])"
	lines += "Overlay on your turf: [(light in origin.overlays) ? "YES" : "NO"]"

	// Nearby sample - catches patchy loss that an area-level flag hides.
	var/checked = 0
	var/with_overlay = 0
	for(var/turf/nearby in range(7, origin))
		checked++
		if(light in nearby.overlays)
			with_overlay++
	lines += "Within range 7: [with_overlay]/[checked] turfs carry the overlay"

	// Whole area, so a partially-painted area is obvious.
	if(here)
		var/area_total = 0
		var/area_lit = 0
		for(var/turf/area_turf in here)
			area_total++
			if(light in area_turf.overlays)
				area_lit++
			CHECK_TICK
		lines += "Whole area: [area_lit]/[area_total] turfs carry the overlay"

	lines += "Source alpha right now: [SSdaylight.wash_source?.alpha] (0 = nothing to mirror, so overlays draw nothing)"

	// The actual darkness. The daylight overlay only ADDS onto the lighting
	// plane - it cannot erase a lighting_object underneath it. If these report
	// a dark lighting object on a lit turf, the wash is being drawn over
	// darkness rather than replacing it, and that is what the banding is.
	lines += "--- turf lighting state ---"
	lines += "Area static_lighting: [here?.static_lighting ? "TRUE (lighting objects exist)" : "FALSE (area is force-lit)"]"
	lines += "Area base lighting: alpha [here?.base_lighting_alpha], color [here?.base_lighting_color], has_base [here?.area_has_base_lighting ? "TRUE" : "FALSE"]"
	lines += "Your turf luminosity: [origin.luminosity]"
	var/atom/movable/lighting_object/lo = origin.lighting_object
	if(lo)
		lines += "lighting_object: present (plane [lo.plane], layer [lo.layer], alpha [lo.alpha], color [lo.color])"
		lines += "  expected plane for this z: [GET_NEW_PLANE(LIGHTING_PLANE, GET_Z_PLANE_OFFSET(origin.z))]"
	else
		lines += "lighting_object: NONE on this turf"

	// The underlying darkness, per corner. The daylight wash only ADDS on top
	// of this, so if a dark band and a lit tile report the same corner values
	// the wash is failing to draw there; if they differ, the band is genuine
	// unlit lighting and the wash is simply not strong enough to hide it.
	var/datum/lighting_corner/corner = origin.lighting_corner_NE
	if(corner)
		lines += "corner NE: lum r[corner.lum_r] g[corner.lum_g] b[corner.lum_b] | cache r[corner.cache_r] g[corner.cache_g] b[corner.cache_b] | affecting sources: [length(corner.affecting)]"
	else
		lines += "corner NE: NONE"
	lines += "turf opacity: [origin.opacity] | area lit by wash at alpha: [SSdaylight.wash_source?.alpha]"

	// Column scan. The banding has a vertical period, so walk north-south and
	// report what each row actually carries. Full strength is 255; the leak
	// feather uses 165/120/90/45, so if the bands line up with those the cause
	// is leak_daylight() reaching in, not the wash failing.
	lines += "--- column scan (south -> north) ---"
	var/static/list/known_strengths = list(255, 165, 120, 90, 45)
	for(var/dy = -10 to 10)
		var/turf/scan = locate(origin.x, origin.y + dy, origin.z)
		if(!scan)
			continue
		var/area/scan_area = scan.loc
		var/found = "NONE"
		for(var/strength in known_strengths)
			if(get_daylight_overlay_appearance(strength, scan) in scan.overlays)
				found = "[strength]"
				break
		lines += "  y[scan.y] [scan.type] | area [scan_area?.name] (daylight [scan_area?.daylight ? "Y" : "n"]) | overlay [found] | layer [scan.layer]"

	to_chat(usr, span_boldnotice("== Daylight column scan ==\n[lines.Join("\n")]"))
	return

	// Same sample across the area, so a per-turf inconsistency is visible.
	if(here)
		var/no_lo = 0
		var/checked_lo = 0
		for(var/turf/area_turf in here)
			checked_lo++
			if(!area_turf.lighting_object)
				no_lo++
			CHECK_TICK
		lines += "Turfs in area with NO lighting_object: [no_lo]/[checked_lo]"

	to_chat(usr, span_boldnotice("== Daylight turf overlays ==\n[lines.Join("\n")]"))
