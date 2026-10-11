/// Default ambient temperature (C) for areas that do not simulate climate.
/area/proc/rw_get_temperature()
	return 20

/// Outdoor cell air temperature (C). Safe when cell is unbound or climate not ready.
/area/rimworld/rw_get_temperature()
	if(!cell)
		return 15
	return cell.get_outdoor_temperature()

/area/rimworld/zone/rw_get_temperature()
	if(!rw_temp_initialised)
		rw_init_thermal()
	return rw_temperature

/area/rimworld/zone/proc/rw_init_thermal()
	rw_temp_initialised = TRUE
	var/datum/planet_cell/C = rw_get_cell()
	// Prefer live outdoor temp; fall back to a mild default so spawn never hits absolute zero.
	rw_temperature = C ? C.get_outdoor_temperature() : 15


/proc/get_rw_ambient_temperature(atom/movable/subject)
	if(!subject)
		return null

	var/turf/T = isturf(subject.loc) ? subject.loc : get_turf(subject)
	if(!T)
		return null

	var/area/A = T.loc
	if(!A)
		return null

	var/temp = A.rw_get_temperature()

	// Weather exposure only applies outdoors (non-zone rimworld area with a bound cell).
	if(istype(A, /area/rimworld) && !istype(A, /area/rimworld/zone))
		var/area/rimworld/R = A
		if(R.cell)
			temp += R.cell.get_weather_exposure_offset()

	return temp

/// One thermal step for an indoor zone. `seconds` = real elapsed seconds since the last step.
/area/rimworld/zone/proc/rw_tick_thermal(seconds)
	if(seconds <= 0)
		return
	if(!rw_size)
		// Stats not ready yet — try a cheap init so temperature is at least defined.
		if(!rw_temp_initialised)
			rw_init_thermal()
		return
	if(!rw_temp_initialised)
		rw_init_thermal()

	var/datum/planet_cell/C = rw_get_cell()
	var/outdoor = C ? C.get_outdoor_temperature() : 15

	// Heat leak through the border, normalized by room size.
	var/leak = (rw_border_walls * RW_LEAK_WALL \
		+ rw_doors_closed * RW_LEAK_DOOR_CLOSED \
		+ rw_doors_open * RW_LEAK_DOOR_OPEN \
		+ rw_gaps * RW_LEAK_GAP) / max(rw_size, 1)
	// Never overshoot the outdoor temperature in one step.
	var/exchange = clamp(leak * seconds, 0, 0.95)
	var/new_temp = rw_temperature + (outdoor - rw_temperature) * exchange

	// Heaters / coolers.
	var/power = 0
	if(length(rw_thermal_objects))
		for(var/obj/O as anything in rw_thermal_objects)
			if(QDELETED(O) || !O.rw_heater_active())
				continue
			if(!isnull(O.rw_heat_target))
				if(O.rw_heat_output > 0 && new_temp >= O.rw_heat_target)
					continue
				if(O.rw_heat_output < 0 && new_temp <= O.rw_heat_target)
					continue
			power += O.rw_heat_output
	if(power)
		new_temp += (power / (rw_size * RW_ZONE_HEAT_CAPACITY)) * seconds

	rw_temperature = clamp(new_temp, RW_CLIMATE_MIN_C - 20, 200)

/// Instantly equalise (used for freshly loaded cells / debug).
/area/rimworld/zone/proc/rw_snap_to_outdoor()
	rw_init_thermal()
