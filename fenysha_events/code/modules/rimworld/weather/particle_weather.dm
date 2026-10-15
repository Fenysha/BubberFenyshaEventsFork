/// Subtype which uses particle systems instead of overlays to display its effects
/datum/weather/particle
	abstract_type = /datum/weather/particle
	/// Particles used to display the weather visuals
	var/particles/weather/particle_type = null
	/// Secondary (layered ontop) particle type which is rendered as emissive in case you want embers or whatever
	var/particles/weather/emissive_type = null
	/// Minimum possible severity for the weather, (0~100]
	var/min_severity = 1
	/// Maximum possible severity for the weather, (0~100]
	var/max_severity = MAXIMUM_WEATHER_SEVERITY
	/// Maximum variation in severity each weather frame
	var/severity_variation = 5
	/// Optimal point towards which severity will try to gravitate by influencing random values
	var/optimal_severity = 70
	/// How often can we change our severity?
	/// Don't set this too low or it'll look jank
	var/severity_cooldown = 5 SECONDS
	/// Alpha of the area overlay when the particle weather pref is enabled
	var/particle_weather_alpha = 255

	/// Current weather severity
	var/severity = 0
	/// Last tick during which we've changed our visual severity
	var/last_severity_tick = 0
	/// List of weather object lists (as we can have multiple if emissives are involved) by plane offset
	var/list/weather_objects = list()
	/// Legacy left/right wind direction used by existing weather.
	var/wind_sign = 0
	/// Optional downwind vector supplied by the planetary cell weather.
	/// Only dedicated planetary subtypes use it; stock weather keeps its old random left/right wind.
	var/list/cell_wind_vector
	/// Whether this weather should use the planetary cell's wind direction and speed.
	var/uses_cell_wind = FALSE

/datum/weather/particle/New(list/z_levels, list/weather_data)
	. = ..()
	if (isnull(particle_type) && isnull(emissive_type))
		CRASH("[src] ([type]) attempted to initialize without normal or emissive particle types!")

	for (var/offset in 0 to SSmapping.max_plane_offset)
		var/list/object_list = list()
		if (particle_type)
			var/obj/effect/abstract/weather_holder/holder = new()
			SET_PLANE_W_SCALAR(holder, RENDER_PLANE_PARTICLE_WEATHER, offset)
			holder.particles = new particle_type()
			object_list[holder] = impacted_z_levels

		if (emissive_type)
			var/obj/effect/abstract/weather_holder/holder = new()
			holder.particles = new emissive_type()
			SET_PLANE_W_SCALAR(holder, RENDER_PLANE_EMISSIVE_PARTICLE_WEATHER, offset)
			object_list[holder] = impacted_z_levels

		weather_objects += list(object_list)

	SSweather.add_weather_objects(weather_objects)

/datum/weather/particle/Destroy()
	SSweather.remove_weather_objects(weather_objects)
	for(var/list/object_list as anything in weather_objects)
		QDEL_LIST(object_list)
	weather_objects = null
	return ..()

/datum/weather/particle/telegraph(list/weather_data)
	. = ..()
	if (!.)
		return
	animate_severity(0)

/datum/weather/particle/end()
	. = ..()
	if (!.)
		return
	animate_severity(0)

/// Adjust our severity by a random number based on our stage
/datum/weather/particle/proc/process_particles()
	if (last_severity_tick + severity_cooldown > world.time)
		return

	last_severity_tick = world.time
	var/new_severity = severity
	switch (stage)
		if (STARTUP_STAGE)
			// Aims at minimum severity, and can only go up
			new_severity += rand() * severity_variation * (1 - severity / min_severity)
		if (MAIN_STAGE)
			// Tries to stay close to optimal severity
			new_severity += LERP(-severity_variation * clamp(INVERSE_LERP(min_severity, optimal_severity, severity), 0, 1), severity_variation * clamp(INVERSE_LERP(max_severity, optimal_severity, severity), 0, 1), rand())
			new_severity = clamp(new_severity, min(new_severity, min_severity), max_severity)
		if (WIND_DOWN_STAGE)
			// Slowly goes down to zero
			new_severity += rand() * -severity_variation * 4 * max(severity / min_severity, 1)

	animate_severity(new_severity)

/datum/weather/particle/proc/animate_severity(new_severity)
	if (!wind_sign)
		wind_sign = pick(-1, 1)

	severity = new_severity
	var/wind_parameter = (uses_cell_wind && islist(cell_wind_vector)) ? cell_wind_vector : wind_sign
	for (var/list/holder_list as anything in weather_objects)
		for (var/obj/effect/abstract/weather_holder/holder as anything in holder_list)
			var/particles/weather/particle_effect = holder.particles
			particle_effect.animate_severity(severity / MAXIMUM_WEATHER_SEVERITY, wind_parameter)

/datum/weather/particle/generate_overlay_cache()
	. = ..()

	if (stage == END_STAGE)
		return

	// Change alpha of overlays on the particle weather plane
	for(var/mutable_appearance/overlay as anything in .)
		if (PLANE_TO_TRUE(overlay.plane) == PARTICLE_WEATHER_PLANE)
			overlay.alpha = particle_weather_alpha

	for (var/offset in 0 to SSmapping.max_plane_offset)
		. += mutable_appearance('icons/effects/weather_overlay.dmi', "weather_overlay", overlay_layer, null, WEATHER_MASK_PLANE, offset_const = offset)

/// Planet-cell rain: same gameplay/weather handling as stock rain, but its particles follow the cell wind.
/datum/weather/particle/rain_storm/rw_cell_directional
	uses_cell_wind = TRUE
	probability = 0

/// Strong planetary storms use the same directional precipitation with a denser particle field.
/datum/weather/particle/rain_storm/rw_cell_directional/storm
	name = "planetary storm"
	min_severity = 45
	optimal_severity = 90
	severity_variation = 8
	probability = 0

/// Directional snow is a particle-weather variant because the stock snow_storm is overlay/sound driven.
/datum/weather/particle/rw_cell_snow
	name = "snowstorm"
	desc = "Cold wind drives dense snowfall across the open terrain."
	particle_type = /particles/weather/rw_cell_snow
	min_severity = 15
	max_severity = MAXIMUM_WEATHER_SEVERITY
	optimal_severity = 65
	severity_variation = 6
	uses_cell_wind = TRUE
	probability = 0
	telegraph_message = span_warning("Loose snow begins drifting across the terrain.")
	telegraph_overlay = "light_snow"
	telegraph_duration = 10 SECONDS
	weather_message = span_userdanger("Wind-driven snow sweeps across the area!")
	weather_overlay = "snow_storm"
	end_message = span_notice("The snowfall begins to ease.")
	end_overlay = "light_snow"
	end_duration = 10 SECONDS
	weather_duration_lower = 1 MINUTES
	weather_duration_upper = 2.5 MINUTES
	area_type = /area
	target_trait = ZTRAIT_SNOWSTORM
	immunity_type = TRAIT_SNOWSTORM_IMMUNE
	weather_temperature = ICEBOX_MIN_TEMPERATURE - 40
	weather_flags = (WEATHER_MOBS | WEATHER_BAROMETER | WEATHER_TEMPERATURE_BYPASS_CLOTHING | WEATHER_STRICT_ALERT)
	overlay_planes = list(WEATHER_PLANE)
	use_glow = FALSE

/// Directional planetary sandstorm. It keeps the stock storm's exposed-mob damage without reusing its static dust overlay.
/datum/weather/particle/rw_cell_sandstorm
	name = "sandstorm"
	desc = "A dry, abrasive storm drives dust and sand across the open terrain."
	particle_type = /particles/weather/rw_cell_sand
	min_severity = 20
	max_severity = MAXIMUM_WEATHER_SEVERITY
	optimal_severity = 75
	severity_variation = 7
	uses_cell_wind = TRUE
	probability = 0
	telegraph_message = span_danger("Dust starts rising as the wind strengthens.")
	telegraph_overlay = "dust_med"
	weather_message = span_userdanger("Hot sand and wind batter you! Get inside!")
	weather_overlay = "dust_high"
	end_message = span_notice("The sandstorm weakens and the dust begins to settle.")
	end_overlay = "dust_med"
	area_type = /area
	target_trait = ZTRAIT_SANDSTORM
	immunity_type = TRAIT_SANDSTORM_IMMUNE
	weather_flags = (WEATHER_MOBS | WEATHER_BAROMETER)
	overlay_planes = list(WEATHER_PLANE)

/datum/weather/particle/rw_cell_sandstorm/weather_act_mob(mob/living/victim)
	victim.adjust_brute_loss(5, required_bodytype = BODYTYPE_ORGANIC)
	return ..()

/obj/effect/abstract/weather_holder
	icon = null
	appearance_flags = TILE_BOUND | PIXEL_SCALE
	blocks_emissive = EMISSIVE_BLOCK_NONE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/particles/weather
	spawning = 0
	// Wider than our view due to weird BYOND jank
	width = 800
	height = 800
	count = 8000

	lifespan = 30 SECONDS
	fade = 1 SECONDS
	fadein = 0.5 SECONDS

	/// Increase in speed per tick
	var/wind_strength = 0
	/// Minimum number of spawned particles per tick for easing
	var/min_spawn = 0
	/// Maximum amount of spawned particles at full strength
	var/max_spawn = 0
	/// Snapshot of original gravity so directional wind never erases a particle's natural trajectory.
	var/list/wind_base_gravity
	/// Reduced vertical wind influence keeps rain and snow moving in their normal fall direction.
	var/wind_vertical_factor = 0.25

/// Changes the strength of the weather visual effect, severity should be between 0 and 1
/particles/weather/proc/animate_severity(severity, wind_sign)
	// Stop spawning if severity is zero or negative.
	if (severity <= 0)
		spawning = 0
		return

	var/wind_x = 0
	var/wind_y = 0
	if (islist(wind_sign))
		var/direction_x = length(wind_sign) >= 1 && isnum(wind_sign[1]) ? wind_sign[1] : 0
		var/direction_y = length(wind_sign) >= 2 && isnum(wind_sign[2]) ? wind_sign[2] : 0
		wind_x = wind_strength * severity * direction_x
		wind_y = wind_strength * severity * direction_y * wind_vertical_factor
	else
		wind_x = wind_strength * severity * wind_sign
	spawning = LERP(min_spawn, max_spawn, severity)
	if (islist(wind_sign))
		// The directional variant adds wind to the configured gravity instead of replacing it.
		// This preserves rain/snow fall acceleration while allowing the particles to drift downwind.
		if (!islist(wind_base_gravity))
			wind_base_gravity = islist(gravity) ? gravity : list(0, 0, 0)
		var/list/new_gravity = wind_base_gravity.Copy()
		while (length(new_gravity) < 2)
			new_gravity += list(0)
		var/base_gravity_x = length(wind_base_gravity) >= 1 && isnum(wind_base_gravity[1]) ? wind_base_gravity[1] : 0
		var/base_gravity_y = length(wind_base_gravity) >= 2 && isnum(wind_base_gravity[2]) ? wind_base_gravity[2] : 0
		new_gravity[1] = base_gravity_x + wind_x
		new_gravity[2] = base_gravity_y + wind_y
		gravity = new_gravity
	else if (islist(gravity) && length(gravity))
		// Preserve legacy behavior for stock particle weather.
		gravity[1] = wind_x
	else
		gravity = list(wind_x)



/// Lightweight snow particles which drift along the local cell's downwind vector.
/particles/weather/rw_cell_snow
	icon = 'icons/effects/particles/generic.dmi'
	icon_state = list("dot" = 3, "cross" = 2, "curl" = 1)
	color = "#edf5ff"
	position = generator(GEN_BOX, list(-510, -256, 0), list(400, 512, 0))
	gravity = list(0, -3.5, 0.1)
	drift = generator(GEN_CIRCLE, 0, 1)
	friction = 0.3
	min_spawn = 45
	max_spawn = 260
	wind_strength = 2.8

/// Dust particles used by the planetary sandstorm instead of a static overlay.
/particles/weather/rw_cell_sand
	icon = 'icons/effects/particles/generic.dmi'
	icon_state = list("dot" = 4, "cross" = 2, "curl" = 1)
	color = "#c7ad7a"
	position = generator(GEN_BOX, list(-510, -256, 0), list(400, 512, 0))
	gravity = list(0, -2.5, 0.1)
	drift = generator(GEN_CIRCLE, 0, 1)
	friction = 0.15
	min_spawn = 40
	max_spawn = 300
	wind_strength = 3.5
