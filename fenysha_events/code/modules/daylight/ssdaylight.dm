/**
 * ============================================================================
 * Daylight subsystem
 *
 * One shared wash source publishes colour+alpha as a render target; every outdoor
 * turf mirrors it onto the lighting plane (BLEND_ADD). On station maps the cycle
 * follows STATION_TIME. On rimworld maps the cycle follows SSrimworld_planetmap
 * rotation / calendar, and each /area/rimworld scales overlay strength by its
 * planet_cell solar intensity (day vs night sides of the globe).
 * ============================================================================
 */

// ── Render / plane ──────────────────────────────────────────────────────────

/// Animated wash publishes here; per-turf overlays render_source-mirror it.
#define DAYLIGHT_WASH_RENDER_TARGET "*DAYLIGHT_WASH"

/// Anchor plane so the wash source is on each client's screen. Must not collide
/// with planes in code/__DEFINES/layers.dm (gap between WEATHER_GLOW 26 and PIPECRAWL 30).
#define RENDER_PLANE_DAYLIGHT 27

/// Round-start offset on the 24h clock (12 HOURS = noon).
#define DAYLIGHT_CLOCK_OFFSET (12 HOURS)

/// Alpha per leak ring (nearest outdoor first).
GLOBAL_LIST_INIT(daylight_leak_falloff, list(165, 120, 90, 45))

/area
	var/daylight = FALSE
	/// TRUE after full-strength wash was applied to this area's turfs.
	var/daylight_lit = FALSE
	/// Indoor turfs we feathered into → overlay used (for cleanup).
	var/list/daylight_leaked


/area/Initialize(mapload)
	. = ..()
	INVOKE_ASYNC(src, PROC_REF(initialize_daylight), mapload)


/area/Destroy()
	INVOKE_ASYNC(src, PROC_REF(remove_daylight))
	return ..()


/area/proc/initialize_daylight(mapload = FALSE)
	if(!daylight)
		return
	SSdaylight.daylight_areas |= src
	// Roundstart: central pass in SSdaylight.Initialize. Runtime areas light now.
	if(!mapload || SSdaylight.setup_complete)
		apply_daylight_overlay()


/area/proc/remove_daylight()
	if(daylight)
		SSdaylight.daylight_areas -= src
	clear_daylight_overlay()

/// Full wash on every turf in this area, then feather into adjacent indoors.
/area/proc/apply_daylight_overlay()
	if(daylight_lit)
		return
	daylight_lit = TRUE
	var/list/own_turfs = list()
	// Do NOT use `as anything` — it skips the turf type filter and can yield mobs/objs.
	for(var/turf/area_turf in src)
		var/atom/holder = daylight_overlay_holder(area_turf)
		holder?.add_overlay(get_daylight_overlay_appearance(255, area_turf))
		own_turfs += area_turf
		CHECK_TICK
	leak_daylight(own_turfs)


/// Feather daylight into non-daylight neighbours; stops at opaque tiles.
/area/proc/leak_daylight(list/source_turfs)
	if(!length(source_turfs))
		return
	var/list/leak_falloff = GLOB.daylight_leak_falloff
	LAZYINITLIST(daylight_leaked)
	var/list/visited = list()
	for(var/turf/seed in source_turfs)
		if(!isturf(seed))
			continue
		visited[seed] = TRUE
	var/list/frontier = list()
	for(var/turf/seed in source_turfs)
		if(isturf(seed))
			frontier += seed
	for(var/ring in 1 to length(leak_falloff))
		var/list/next_frontier = list()
		for(var/turf/frontier_turf in frontier)
			if(!isturf(frontier_turf) || frontier_turf.opacity)
				continue
			for(var/dir in GLOB.cardinals)
				var/turf/neighbor = get_step(frontier_turf, dir)
				if(!isturf(neighbor) || visited[neighbor])
					continue
				visited[neighbor] = TRUE
				var/area/neighbor_area = neighbor.loc
				if(neighbor_area?.daylight)
					continue
				var/mutable_appearance/leak = get_daylight_overlay_appearance(leak_falloff[ring], neighbor)
				var/atom/holder = daylight_overlay_holder(neighbor)
				clear_daylight_wash(neighbor)
				holder?.add_overlay(leak)
				daylight_leaked[neighbor] = leak
				next_frontier += neighbor
		frontier = next_frontier
		CHECK_TICK


/area/proc/relight_daylight_leaks()
	if(!daylight_lit)
		return
	for(var/turf/leaked in daylight_leaked)
		if(isturf(leaked))
			clear_daylight_wash(leaked)
		CHECK_TICK
	daylight_leaked = null
	var/list/own_turfs = list()
	for(var/turf/area_turf in src)
		own_turfs += area_turf
		CHECK_TICK
	leak_daylight(own_turfs)


/area/proc/clear_daylight_overlay()
	if(!daylight_lit && !length(daylight_leaked))
		return
	daylight_lit = FALSE
	for(var/turf/area_turf in src)
		clear_daylight_wash(area_turf)
		CHECK_TICK
	for(var/turf/leaked in daylight_leaked)
		if(isturf(leaked))
			clear_daylight_wash(leaked)
		CHECK_TICK
	daylight_leaked = null


/**
 * Shared wash appearance: mirrors DAYLIGHT_WASH_RENDER_TARGET onto LIGHTING_PLANE.
 * strength 0-255. Cached per strength + plane offset (multi-z).
 */
/proc/get_daylight_overlay_appearance(strength = 255, turf/reference)
	var/static/list/cached = list()
	var/plane_offset = 0
	if(SSmapping.max_plane_offset && isturf(reference) && reference.z)
		plane_offset = GET_Z_PLANE_OFFSET(reference.z)
	var/cache_key = "[strength]-[plane_offset]"
	. = cached[cache_key]
	if(.)
		return
	var/mutable_appearance/light = new()
	light.plane = GET_NEW_PLANE(LIGHTING_PLANE, plane_offset)
	light.layer = LIGHTING_PRIMARY_LAYER
	light.blend_mode = BLEND_ADD
	light.appearance_flags = RESET_TRANSFORM | RESET_ALPHA | RESET_COLOR
	light.render_source = DAYLIGHT_WASH_RENDER_TARGET
	light.alpha = strength
	cached[cache_key] = light
	return light


/// Prefer lighting_object so BLEND_ADD composites against the same darkness tree.
/proc/daylight_overlay_holder(turf/target)
	if(!isturf(target))
		return null
	return target.lighting_object || target


/// Strip every known wash strength from both possible holders.
/proc/clear_daylight_wash(turf/target)
	if(!isturf(target))
		return
	var/atom/movable/lighting_object/lighting = target.lighting_object
	for(var/strength in (list(255) + GLOB.daylight_leak_falloff))
		var/mutable_appearance/wash = get_daylight_overlay_appearance(strength, target)
		target.cut_overlay(wash)
		lighting?.cut_overlay(wash)



/turf/AfterChange(flags, oldType)
	. = ..()
	INVOKE_ASYNC(SSdaylight, TYPE_PROC_REF(/datum/controller/subsystem/daylight, refresh_turf_daylight), src)


/turf/on_change_area(area/old_area, area/new_area)
	. = ..()
	INVOKE_ASYNC(SSdaylight, TYPE_PROC_REF(/datum/controller/subsystem/daylight, refresh_turf_daylight), src)


/datum/daylight_phase
	var/name = "Phase"
	var/color = "#ffffff"
	/// Start on the 24h clock (deciseconds).
	var/start_time = 0
	var/target_intensity = 1


/datum/daylight_phase/dawn
	name = "Dawn"
	color = "#31211b"
	start_time = 4 HOURS
	target_intensity = 0.2

/datum/daylight_phase/sunrise
	name = "Sunrise"
	color = "#F598AB"
	start_time = 5 HOURS
	target_intensity = 0.55

/datum/daylight_phase/daytime
	name = "Daytime"
	color = "#FFFFFF"
	start_time = 5.5 HOURS
	target_intensity = 1

/datum/daylight_phase/sunset
	name = "Sunset"
	color = "#ff8a63"
	start_time = 19 HOURS
	target_intensity = 0.45

/datum/daylight_phase/dusk
	name = "Dusk"
	color = "#2b2842"
	start_time = 19.5 HOURS
	target_intensity = 0.18

/datum/daylight_phase/midnight
	name = "Midnight"
	color = "#101c3b"
	start_time = 20 HOURS
	target_intensity = 0.08


SUBSYSTEM_DEF(daylight)
	name = "Daylight Controller"
	wait = 1 SECONDS
	runlevels = RUNLEVEL_GAME
	dependencies = list(
		/datum/controller/subsystem/mapping,
		/datum/controller/subsystem/lighting,
	)

	/// Outdoor areas that receive the wash.
	var/static/list/daylight_areas = list()
	var/static/list/obj/effect/light_emitter/daylight/all_emitters = list()

	/// Shared source mirrored by every turf overlay.
	var/obj/daylight_wash_source/wash_source
	/// TRUE after the first full lighting pass in Initialize.
	var/setup_complete = FALSE

	// Current / target lighting state
	var/current_intensity = 1
	var/current_color = "#ffffff"
	var/list/current_rgb = list(255, 255, 255)
	var/target_intensity = 1
	var/target_color = "#ffffff"
	var/start_intensity = 1
	var/start_color = "#ffffff"
	var/transition_steps = 0
	var/const/TRANSITION_STEPS = 6

	/// Fraction of the day treated as "day" for night-start signal (station only).
	var/daylight_fraction = 0.77
	/// Minimum cycle_progress delta before a phase update (station only).
	var/delta_cycle_progress = 0.05

	var/cycle_locked = FALSE
	var/time_locked = FALSE
	/// If >= 0, overrides automatic clock (0–1 progress). -1 = auto.
	var/manual_time = -1

	var/flashing = FALSE

	var/last_cycle_progress = -1
	var/datum/daylight_phase/current_phase
	var/datum/daylight_phase/next_phase
	var/list/daylight_phases
	var/last_phase_name

	/// Station: compress 24h into this many real minutes (default 60 → 24×).
	var/daylight_cycle = 60
	var/daylight_update_cooldown = 12 SECONDS
	COOLDOWN_DECLARE(daylight_update_cd)

	// Rimworld / planet
	var/use_planet_time = FALSE
	var/last_planet_rotation = -1
	COOLDOWN_DECLARE(rimworld_daylight_cd)

	// Optional visual weather particles (station flavour)
	var/list/phase_particle_weights
	var/current_particle_weather = /particles/daylight_weather/mist
	var/visual_weather_override = "auto"


/datum/controller/subsystem/daylight/Initialize()
	daylight_phases = list(
		new /datum/daylight_phase/dawn(),
		new /datum/daylight_phase/sunrise(),
		new /datum/daylight_phase/daytime(),
		new /datum/daylight_phase/sunset(),
		new /datum/daylight_phase/dusk(),
		new /datum/daylight_phase/midnight(),
	)
	phase_particle_weights = list(
		"Dawn" = list(/particles/daylight_weather/rain = 5, /particles/daylight_weather/mist = 3),
		"Sunrise" = list(/particles/daylight_weather/mist = 6, /particles/daylight_weather/rain = 2),
		"Daytime" = list(/particles/daylight_weather/dust = 7, /particles/daylight_weather/mist = 2),
		"Sunset" = list(/particles/daylight_weather/rain = 5, /particles/daylight_weather/dust = 2),
		"Dusk" = list(/particles/daylight_weather/snow = 5, /particles/daylight_weather/mist = 3),
		"Midnight" = list(/particles/daylight_weather/snow = 7, /particles/daylight_weather/mist = 2),
	)

	if(SSmapping.current_map?.rimworld_map)
		use_planet_time = TRUE
		if(SSrimworld_planetmap)
			RegisterSignal(SSrimworld_planetmap, COMSIG_RIMWORLD_PLANET_DAY_PASSED, PROC_REF(on_planet_day_passed))

	current_rgb = hex2rgb(current_color)
	var/list/phase_state = get_phase_light_state()
	current_intensity = phase_state["intensity"]
	current_color = phase_state["color"]
	last_cycle_progress = get_cycle_progress()

	wash_source = new()
	wash_source.color = current_color
	wash_source.alpha = round(clamp(current_intensity, 0, 1) * 255, 1)
	for(var/mob/viewer as anything in GLOB.player_list)
		viewer.hud_used?.register_reuse(wash_source)

	update_current(current_intensity, current_color, force = TRUE)

	for(var/area/daylit as anything in daylight_areas)
		daylit.apply_daylight_overlay()
		CHECK_TICK

	setup_complete = TRUE
	return SS_INIT_SUCCESS


/datum/controller/subsystem/daylight/fire()
	// Smooth multi-step transitions (both modes)
	if(transition_steps > 0)
		var/fraction = 1 - (transition_steps - 1) / TRANSITION_STEPS
		update_current(
			lerp(start_intensity, target_intensity, fraction),
			color_interpolate(start_color, target_color, fraction)
		)
		transition_steps--

	if(use_planet_time)
		process_rimworld_daylight()
		return

	process_station_daylight()

/**
 * Interpolate night↔day colour for a 0–1 manual intensity (admin forced time).
 */
/datum/controller/subsystem/daylight/proc/get_manual_light_color(value)
	if(!length(daylight_phases))
		return "#ffffff"
	var/datum/daylight_phase/day_phase = daylight_phases[3] // Daytime
	var/datum/daylight_phase/night_phase = daylight_phases[length(daylight_phases)] // Midnight
	return color_interpolate(night_phase.color, day_phase.color, clamp(value, 0, 1))


/**
 * Clear + re-apply wash on every daylight area (runtime templates / manual fix).
 */
/datum/controller/subsystem/daylight/proc/reapply_lighting()
	var/count = 0
	for(var/area/daylit_area as anything in daylight_areas)
		daylit_area.clear_daylight_overlay()
		if(istype(daylit_area, /area/rimworld))
			var/area/rimworld/RA = daylit_area
			RA.update_rimworld_daylight(force = TRUE)
		else
			daylit_area.apply_daylight_overlay()
		daylit_area.update_base_lighting()
		count++
	return count

/datum/controller/subsystem/daylight/proc/process_station_daylight()
	if(!COOLDOWN_FINISHED(src, daylight_update_cd))
		return
	COOLDOWN_START(src, daylight_update_cd, daylight_update_cooldown)

	if(manual_time >= 0 || time_locked || cycle_locked)
		return

	var/cycle_progress = get_cycle_progress()
	if(last_cycle_progress < 0)
		last_cycle_progress = cycle_progress
		return

	if(cycle_progress < last_cycle_progress - 0.01)
		message_admins("A new day has dawned on the station!")
		SEND_SIGNAL(src, COMSIG_DAYLIGHT_NEW_DAY)
		SEND_SIGNAL(src, COMSIG_DAYLIGHT_DAY_START)
	else if(last_cycle_progress < daylight_fraction && cycle_progress >= daylight_fraction)
		message_admins("Night has fallen on the station.")
		SEND_SIGNAL(src, COMSIG_DAYLIGHT_NIGHT_START)

	if(abs(cycle_progress - last_cycle_progress) < delta_cycle_progress)
		return

	resolve_phase()
	if(current_phase?.name != last_phase_name)
		last_phase_name = current_phase?.name

	var/list/phase_state = get_phase_light_state()
	set_target(phase_state["intensity"], phase_state["color"])
	last_cycle_progress = cycle_progress

/datum/controller/subsystem/daylight/proc/process_rimworld_daylight()
	if(!COOLDOWN_FINISHED(src, rimworld_daylight_cd))
		return
	COOLDOWN_START(src, rimworld_daylight_cd, RIMWORLD_DAYLIGHT_UPDATE_INTERVAL)

	if(!SSrimworld_planetmap)
		return

	var/angle = SSrimworld_planetmap.rotation_angle
	last_planet_rotation = angle

	// Global wash colour/intensity from planet clock (shared render target)
	if(manual_time < 0 && !time_locked)
		var/list/global_phase = get_phase_light_state_for_hour(SSrimworld_planetmap.time_of_day)
		set_target(global_phase["intensity"], global_phase["color"], RIMWORLD_DAYLIGHT_UPDATE_INTERVAL)

	// Per-area local strength from cell solar geometry
	for(var/area/rimworld/A as anything in GLOB.rimworld_areas)
		if(A.daylight)
			A.update_rimworld_daylight()
		CHECK_TICK

	for(var/obj/effect/light_emitter/daylight/E as anything in all_emitters)
		E.apply_current_state()


/datum/controller/subsystem/daylight/proc/on_planet_day_passed(datum/source, total_days, year, day_of_year)
	SEND_SIGNAL(src, COMSIG_DAYLIGHT_NEW_DAY)


/**
 * Time of day on the 24h clock (deciseconds), for phase lookup.
 * Station: compressed STATION_TIME. Planet: SSrimworld_planetmap.time_of_day.
 */
/datum/controller/subsystem/daylight/proc/station_clock()
	if(use_planet_time && SSrimworld_planetmap)
		return (SSrimworld_planetmap.time_of_day % 24) * (1 HOURS)
	var/rate = daylight_cycle > 0 ? (1440 / daylight_cycle) : 1
	return ((STATION_TIME_PASSED() * rate) + DAYLIGHT_CLOCK_OFFSET) % (24 HOURS)


/datum/controller/subsystem/daylight/proc/get_cycle_progress()
	if(manual_time >= 0)
		return clamp(manual_time, 0, 1)
	return station_clock() / (24 HOURS)


/datum/controller/subsystem/daylight/proc/resolve_phase()
	var/time_now = station_clock()
	var/datum/daylight_phase/new_current
	var/datum/daylight_phase/new_next
	for(var/i in 1 to length(daylight_phases))
		var/datum/daylight_phase/phase = daylight_phases[i]
		if(time_now >= phase.start_time)
			new_current = phase
			new_next = (i == length(daylight_phases)) ? daylight_phases[1] : daylight_phases[i + 1]
	if(!new_current)
		new_current = daylight_phases[length(daylight_phases)]
		new_next = daylight_phases[1]
	current_phase = new_current
	next_phase = new_next


/datum/controller/subsystem/daylight/proc/get_phase_progress()
	if(!current_phase || !next_phase)
		return 0
	var/full_day = 24 HOURS
	var/duration = next_phase.start_time - current_phase.start_time
	if(duration <= 0)
		duration += full_day
	var/elapsed = station_clock() - current_phase.start_time
	if(elapsed < 0)
		elapsed += full_day
	if(duration <= 0)
		return 0
	return clamp(elapsed / duration, 0, 1)


/datum/controller/subsystem/daylight/proc/get_phase_light_state()
	resolve_phase()
	return mix_phase_state(current_phase, next_phase, get_phase_progress())


/**
 * Phase colour/intensity for an arbitrary hour (0–24). Used by rimworld areas
 * with local solar time independent of the global wash clock.
 */
/datum/controller/subsystem/daylight/proc/get_phase_light_state_for_hour(hour)
	hour = hour % 24
	if(hour < 0)
		hour += 24
	var/time_now = hour * (1 HOURS)
	var/datum/daylight_phase/local_current
	var/datum/daylight_phase/local_next
	for(var/i in 1 to length(daylight_phases))
		var/datum/daylight_phase/phase = daylight_phases[i]
		if(time_now >= phase.start_time)
			local_current = phase
			local_next = (i == length(daylight_phases)) ? daylight_phases[1] : daylight_phases[i + 1]
	if(!local_current)
		local_current = daylight_phases[length(daylight_phases)]
		local_next = daylight_phases[1]

	var/full_day = 24 HOURS
	var/duration = local_next.start_time - local_current.start_time
	if(duration <= 0)
		duration += full_day
	var/elapsed = time_now - local_current.start_time
	if(elapsed < 0)
		elapsed += full_day
	var/mix = duration > 0 ? clamp(elapsed / duration, 0, 1) : 0
	return mix_phase_state(local_current, local_next, mix)


/datum/controller/subsystem/daylight/proc/mix_phase_state(datum/daylight_phase/from_phase, datum/daylight_phase/to_phase, mix)
	var/color = color_interpolate(from_phase.color, to_phase.color, mix)
	var/intensity = lerp(from_phase.target_intensity, to_phase.target_intensity, mix)
	if(from_phase.name == "Dusk" || from_phase.name == "Midnight" || to_phase.name == "Midnight")
		var/moonlight_ratio = clamp(1 - intensity, 0, 1)
		color = color_interpolate(color, "#6f86b6", moonlight_ratio * 0.4)
		intensity = max(intensity, 0.06)
	return list(
		"color" = color,
		"intensity" = clamp(intensity, 0, 1),
		"phase" = from_phase.name,
	)


/datum/controller/subsystem/daylight/proc/set_target(intensity, color, transition_time)
	target_intensity = clamp(intensity, 0, 1)
	target_color = color
	start_intensity = current_intensity
	start_color = current_color
	transition_steps = TRANSITION_STEPS
	if(isnull(transition_time))
		transition_time = TRANSITION_STEPS * wait
	update_wash(target_intensity, target_color, transition_time)


/datum/controller/subsystem/daylight/proc/set_intensity_and_color(intensity = target_intensity, color = target_color, force = FALSE)
	if(force)
		transition_steps = 0
		update_current(intensity, color, force = TRUE)
		update_wash(intensity, color, 0)
	else
		set_target(intensity, color)


/datum/controller/subsystem/daylight/proc/update_current(intensity, color, force = FALSE)
	var/changed = abs(current_intensity - intensity) > 0.001 || current_color != color
	if(!changed && !force)
		return
	current_intensity = intensity
	current_color = color
	current_rgb = hex2rgb(color)
	for(var/obj/effect/light_emitter/daylight/E as anything in all_emitters)
		E.apply_current_state()
	SEND_SIGNAL(src, COMSIG_DAYLIGHT_UPDATED, current_intensity, current_color)


/// Animate the shared wash; all turf overlays mirror it via render_source.
/datum/controller/subsystem/daylight/proc/update_wash(intensity = current_intensity, color = current_color, transition_time = 1 SECONDS)
	if(QDELETED(wash_source))
		return
	animate(
		wash_source,
		color = color,
		alpha = round(clamp(intensity, 0, 1) * 255, 1),
		time = max(0, transition_time),
		easing = SINE_EASING,
	)


/datum/controller/subsystem/daylight/proc/handle_loaded_turfs(list/turfs, rebuild_leaks = TRUE)
	if(!setup_complete || !length(turfs))
		return
	var/list/refreshed_areas = list()
	for(var/turf/loaded_turf in turfs)
		if(!isturf(loaded_turf))
			continue
		var/area/loaded_area = loaded_turf.loc
		if(isnull(loaded_area) || refreshed_areas[loaded_area])
			continue
		refreshed_areas[loaded_area] = TRUE
		loaded_area.update_base_lighting()

	for(var/turf/loaded_turf in turfs)
		if(!isturf(loaded_turf))
			continue
		var/area/loaded_area = loaded_turf.loc
		if(!loaded_area?.daylight)
			continue
		if(!loaded_area.daylight_lit)
			loaded_area.apply_daylight_overlay()
			continue
		var/mutable_appearance/light = get_daylight_overlay_appearance(255, loaded_turf)
		var/atom/holder = daylight_overlay_holder(loaded_turf)
		holder?.cut_overlay(light)
		holder?.add_overlay(light)
		CHECK_TICK

	if(rebuild_leaks)
		rebuild_daylight_leaks()


/datum/controller/subsystem/daylight/proc/refresh_turf_daylight(turf/changed)
	if(!setup_complete || !isturf(changed) || QDELETED(changed) || Master.map_loading)
		return
	var/atom/holder = daylight_overlay_holder(changed)
	if(isnull(holder))
		return
	clear_daylight_wash(changed)
	var/area/turf_area = changed.loc
	if(istype(turf_area, /area/rimworld) && turf_area.daylight)
		var/area/rimworld/RA = turf_area
		var/strength = round(clamp(RA.rimworld_sun_intensity >= 0 ? RA.rimworld_sun_intensity : 1, 0, 1) * 255, 1)
		if(strength > 0)
			holder.add_overlay(get_daylight_overlay_appearance(strength, changed))
		return
	if(turf_area?.daylight)
		holder.add_overlay(get_daylight_overlay_appearance(255, changed))
		return
	var/mutable_appearance/leaked = get_leaked_daylight(changed)
	if(leaked)
		holder.add_overlay(leaked)


/datum/controller/subsystem/daylight/proc/rebuild_daylight_leaks()
	if(!setup_complete)
		return 0
	var/rebuilt = 0
	for(var/area/daylit as anything in daylight_areas)
		daylit.relight_daylight_leaks()
		rebuilt++
	return rebuilt


/datum/controller/subsystem/daylight/proc/get_leaked_daylight(turf/target)
	for(var/area/daylit as anything in daylight_areas)
		var/mutable_appearance/leaked = daylit.daylight_leaked?[target]
		if(leaked)
			return leaked
	return null


/datum/controller/subsystem/daylight/proc/register_emitter(obj/effect/light_emitter/daylight/emitter)
	if(!emitter || QDELETED(emitter) || (emitter in all_emitters))
		return
	all_emitters += emitter
	emitter.apply_current_state()


/datum/controller/subsystem/daylight/proc/unregister_emitter(obj/effect/light_emitter/daylight/emitter)
	all_emitters -= emitter


/datum/controller/subsystem/daylight/proc/set_manual_time(progress = -1)
	manual_time = progress
	if(progress < 0)
		return
	var/hour = clamp(progress, 0, 1) * 24
	var/list/state = get_phase_light_state_for_hour(hour)
	set_intensity_and_color(state["intensity"], state["color"], force = TRUE)


/datum/controller/subsystem/daylight/proc/set_all_rimworld_daylight(intensity, color = null)
	for(var/area/rimworld/A as anything in GLOB.rimworld_areas)
		A.set_forced_daylight(intensity, color)


/datum/controller/subsystem/daylight/proc/flash(color, duration = 10 SECONDS, transition_time = 2 SECONDS, list/areas)
	set waitfor = FALSE
	if(flashing)
		return
	flashing = TRUE
	if(!areas)
		areas = daylight_areas.Copy()
	var/step_wait = 0.1 SECONDS
	var/orig_i = target_intensity
	var/orig_c = target_color
	var/steps_up = max(1, round(transition_time / wait, 1))
	var/steps_down = steps_up
	var/hold_steps = max(0, round(duration / step_wait, 1) - steps_up - steps_down)

	set_target(1, color, transition_time)
	for(var/i in 1 to steps_up)
		fire()
		sleep(step_wait)
		CHECK_TICK
	for(var/i in 1 to hold_steps)
		sleep(duration / max(hold_steps, 1))
		CHECK_TICK
	set_target(orig_i, orig_c, transition_time)
	for(var/i in 1 to steps_down)
		fire()
		sleep(step_wait)
		CHECK_TICK
	flashing = FALSE

/datum/controller/subsystem/daylight/proc/get_weather_particle_type()
	switch(visual_weather_override)
		if("rain")
			return /particles/daylight_weather/rain
		if("snow")
			return /particles/daylight_weather/snow
		if("dust")
			return /particles/daylight_weather/dust
		if("mist")
			return /particles/daylight_weather/mist
		if("none")
			return null
	resolve_phase()
	var/list/weights = phase_particle_weights[current_phase?.name]
	if(!length(weights))
		return /particles/daylight_weather/mist
	current_particle_weather = pick_weight(weights)
	return current_particle_weather


/proc/hex2rgb(hex)
	if(!hex)
		return list(255, 255, 255)
	if(copytext(hex, 1, 2) == "#")
		hex = copytext(hex, 2)
	if(length(hex) == 3)
		hex = "[copytext(hex,1,2)][copytext(hex,1,2)][copytext(hex,2,3)][copytext(hex,2,3)][copytext(hex,3,4)][copytext(hex,3,4)]"
	if(length(hex) != 6)
		return list(255, 255, 255)
	return list(
		hex2num(copytext(hex, 1, 3)),
		hex2num(copytext(hex, 3, 5)),
		hex2num(copytext(hex, 5, 7)),
	)


/proc/color_interpolate(color1, color2, ratio)
	var/list/c1 = hex2rgb(color1)
	var/list/c2 = hex2rgb(color2)
	return rgb(
		round(c1[1] + (c2[1] - c1[1]) * ratio, 1),
		round(c1[2] + (c2[2] - c1[2]) * ratio, 1),
		round(c1[3] + (c2[3] - c1[3]) * ratio, 1),
	)


/obj/daylight_wash_source
	icon = 'icons/effects/alphacolors.dmi'
	icon_state = "white"
	plane = LIGHTING_PLANE
	blend_mode = BLEND_ADD
	render_target = DAYLIGHT_WASH_RENDER_TARGET
	screen_loc = "1,1"
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT


/atom/movable/screen/plane_master/daylight_anchor
	name = "Daylight anchor"
	documentation = "Registers the shared daylight wash source onto each viewer so turf overlays can mirror it."
	plane = RENDER_PLANE_DAYLIGHT
	appearance_flags = PLANE_MASTER|NO_CLIENT_COLOR
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	render_relay_planes = list()


/atom/movable/screen/plane_master/daylight_anchor/show_to(mob/mymob)
	. = ..()
	if(offset != 0 || !mymob || !SSdaylight?.wash_source)
		return
	mymob.hud_used?.register_reuse(SSdaylight.wash_source)


/atom/movable/screen/plane_master/daylight_anchor/hide_from(mob/oldmob)
	. = ..()
	if(offset != 0 || !oldmob || !SSdaylight?.wash_source)
		return
	oldmob.hud_used?.unregister_reuse(SSdaylight.wash_source)


/obj/effect/light_emitter
	flags_1 = NO_TURF_MOVEMENT_1


/obj/effect/light_emitter/daylight
	set_luminosity = 2
	set_cap = 0.5
	var/initial_lum = 2
	var/initial_cap = 0.5


/obj/effect/light_emitter/daylight/Initialize(mapload)
	. = ..()
	initial_lum = set_luminosity
	initial_cap = set_cap
	SSdaylight?.register_emitter(src)


/obj/effect/light_emitter/daylight/Destroy()
	SSdaylight?.unregister_emitter(src)
	return ..()


/obj/effect/light_emitter/daylight/proc/apply_current_state()
	if(!SSdaylight)
		return
	light_power = initial_cap * SSdaylight.current_intensity
	light_color = SSdaylight.current_color
	update_light()



/particles/daylight_weather
	icon = 'icons/effects/particles/generic.dmi'
	width = 480
	height = 480
	count = 120
	spawning = 0.4
	lifespan = 1.8 SECONDS
	fade = 1.2 SECONDS
	position = generator(GEN_BOX, list(-240, -180, 0), list(240, 240, 0))
	gravity = list(0, -1.3)
	drift = generator(GEN_CIRCLE, 0, 2)
	friction = 0.25

/particles/daylight_weather/rain
	icon_state = list("drop" = 4, "dot" = 1)
	color = "#b0d8ff"
	spawning = 1.2
	count = 200
	lifespan = 1.1 SECONDS
	fade = 0.5 SECONDS
	gravity = list(0, -4.4)
	drift = generator(GEN_CIRCLE, 0, 1)

/particles/daylight_weather/snow
	icon_state = list("dot" = 3, "cross" = 2)
	color = "#f2f7ff"
	spawning = 0.5
	count = 140
	lifespan = 2.6 SECONDS
	fade = 1.4 SECONDS
	gravity = list(0, -1.1)
	drift = generator(GEN_CIRCLE, 0, 3)
	spin = generator(GEN_NUM, -8, 8)

/particles/daylight_weather/dust
	icon_state = list("dot" = 4, "cross" = 1)
	color = "#c59a6f"
	spawning = 0.45
	count = 110
	lifespan = 2.4 SECONDS
	fade = 1.1 SECONDS
	gravity = list(-1.2, -0.4)
	drift = generator(GEN_CIRCLE, 0, 4)
	spin = generator(GEN_NUM, -6, 6)

/particles/daylight_weather/mist
	icon_state = list("dot" = 4)
	color = "#c7d5e8"
	spawning = 0.35
	count = 90
	lifespan = 3 SECONDS
	fade = 1.7 SECONDS
	gravity = list(0, -0.4)
	drift = generator(GEN_CIRCLE, 0, 2)


/area/centcom/central_command_areas/admin/daylight
	daylight = TRUE
	outdoors = TRUE
