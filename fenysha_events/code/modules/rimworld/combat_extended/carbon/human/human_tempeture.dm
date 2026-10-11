#ifndef OLD_COMBAT_SYSTEM

#define THERMAL_PROTECTION_HEAD 0.3
#define THERMAL_PROTECTION_CHEST 0.15
#define THERMAL_PROTECTION_GROIN 0.15
#define THERMAL_PROTECTION_LEG_LEFT 0.075
#define THERMAL_PROTECTION_LEG_RIGHT 0.075
#define THERMAL_PROTECTION_FOOT_LEFT 0.025
#define THERMAL_PROTECTION_FOOT_RIGHT 0.025
#define THERMAL_PROTECTION_ARM_LEFT 0.075
#define THERMAL_PROTECTION_ARM_RIGHT 0.075
#define THERMAL_PROTECTION_HAND_LEFT 0.025
#define THERMAL_PROTECTION_HAND_RIGHT 0.025

/// Which tile of the body, as THERMAL_PROTECTION_* weights, a zone represents.
/proc/rw_zone_weight(zone)
	switch(zone)
		if(BODY_ZONE_HEAD)
			return THERMAL_PROTECTION_HEAD
		if(BODY_ZONE_CHEST)
			return THERMAL_PROTECTION_CHEST + THERMAL_PROTECTION_GROIN
		if(BODY_ZONE_L_ARM)
			return THERMAL_PROTECTION_ARM_LEFT + THERMAL_PROTECTION_HAND_LEFT
		if(BODY_ZONE_R_ARM)
			return THERMAL_PROTECTION_ARM_RIGHT + THERMAL_PROTECTION_HAND_RIGHT
		if(BODY_ZONE_L_LEG)
			return THERMAL_PROTECTION_LEG_LEFT + THERMAL_PROTECTION_FOOT_LEFT
		if(BODY_ZONE_R_LEG)
			return THERMAL_PROTECTION_LEG_RIGHT + THERMAL_PROTECTION_FOOT_RIGHT
	return 0

/// body_parts_covered flag -> body zone list it touches.
/proc/rw_zones_for_coverage(flags)
	var/list/zones = list()
	if(flags & HEAD)
		zones += BODY_ZONE_HEAD
	if(flags & (CHEST | GROIN))
		zones += BODY_ZONE_CHEST
	if(flags & (ARM_LEFT | HAND_LEFT))
		zones += BODY_ZONE_L_ARM
	if(flags & (ARM_RIGHT | HAND_RIGHT))
		zones += BODY_ZONE_R_ARM
	if(flags & (LEG_LEFT | FOOT_LEFT))
		zones += BODY_ZONE_L_LEG
	if(flags & (LEG_RIGHT | FOOT_RIGHT))
		zones += BODY_ZONE_R_LEG
	return zones

/**
 * Per-zone and overall comfort range.
 * Returns list("min", "max", "zone_min" = list(zone = C), "zone_max" = list(zone = C)).
 * Layers inside one zone add up, but the sum is capped so that stacking ten coats is not infinite.
 */
/mob/living/carbon/human/proc/get_rw_comfort_range(force = FALSE)
	if(!force && rw_comfort_cache && world.time < rw_comfort_cache_time + 2 SECONDS)
		return rw_comfort_cache

	var/list/zone_cold = list()
	var/list/zone_heat = list()
	for(var/obj/item/clothing/C in get_equipped_items())
		if(!istype(C))
			continue
		var/cold = C.get_rw_cold_insulation()
		var/heat = C.get_rw_heat_insulation()
		if(!cold && !heat)
			continue
		for(var/zone in rw_zones_for_coverage(C.body_parts_covered))
			zone_cold[zone] = (zone_cold[zone] || 0) + cold
			zone_heat[zone] = (zone_heat[zone] || 0) + heat

	var/list/zone_min = list()
	var/list/zone_max = list()
	var/weighted_cold = 0
	var/weighted_heat = 0
	var/total_weight = 0
	var/list/all_zones = list(BODY_ZONE_HEAD, BODY_ZONE_CHEST, BODY_ZONE_L_ARM, BODY_ZONE_R_ARM, BODY_ZONE_L_LEG, BODY_ZONE_R_LEG)
	for(var/zone in all_zones)
		var/cold = min(zone_cold[zone] || 0, 120)
		var/heat = min(zone_heat[zone] || 0, 100)
		zone_min[zone] = rw_base_comfort_min - cold + rw_cold_tolerance_bonus
		zone_max[zone] = rw_base_comfort_max + heat + rw_heat_tolerance_bonus
		var/w = rw_zone_weight(zone)
		weighted_cold += cold * w
		weighted_heat += heat * w
		total_weight += w

	// The "overall" range is what the core feels: coverage-weighted, torso and head matter most.
	var/overall_cold = total_weight ? weighted_cold / total_weight : 0
	var/overall_heat = total_weight ? weighted_heat / total_weight : 0

	rw_comfort_cache = list(
		"min" = rw_base_comfort_min - overall_cold + rw_cold_tolerance_bonus,
		"max" = rw_base_comfort_max + overall_heat + rw_heat_tolerance_bonus,
		"zone_min" = zone_min,
		"zone_max" = zone_max,
	)
	rw_comfort_cache_time = world.time
	return rw_comfort_cache

/// Call when clothes change, to skip the 2s cache.
/mob/living/carbon/human/proc/invalidate_rw_comfort()
	rw_comfort_cache_time = -999


/**
 * Called from Life() instead of species.handle_body_temperature().
 */
/mob/living/carbon/human/proc/handle_rw_thermal(seconds_per_tick)
	if(stat == DEAD || HAS_TRAIT(src, TRAIT_GODMODE))
		return
	if(istype(loc, /obj/machinery/cryo_cell) || HAS_TRAIT(src, TRAIT_STASIS))
		return
	if(seconds_per_tick <= 0)
		return

	// Guard against uninitialized core temperature (0 K → −273 °C → instant critical hypo).
	// Normal human core is ~37 °C = 310.15 K.
	if(!coretemperature || coretemperature < 200)
		set_coretemperature(310.15) // ~37 C; BODYTEMP_NORMAL may be undefined here

	var/ambient = get_rw_ambient_temperature(src)
	if(isnull(ambient))
		return

	var/list/range = get_rw_comfort_range()
	if(!range)
		return
	var/cmin = range["min"]
	var/cmax = range["max"]

	// 1) Core temperature.
	var/stress = 0
	if(ambient < cmin)
		stress = cmin - ambient
	else if(ambient > cmax)
		stress = -(ambient - cmax)

	var/core_c = RW_TO_C(coretemperature)
	// Sanity: if somehow still absurd, snap toward normal before applying drift.
	if(core_c < 10 || core_c > 50)
		core_c = clamp(core_c, 20, 40)

	if(stress)
		var/drift = clamp(abs(stress) * RW_CORE_DRIFT_PER_STRESS, 0, RW_CORE_DRIFT_MAX) * seconds_per_tick
		core_c += (stress > 0 ? -drift : drift)
	else
		var/step = RW_CORE_RECOVERY * seconds_per_tick
		if(core_c < RW_CORE_NORMAL)
			core_c = min(RW_CORE_NORMAL, core_c + step)
		else if(core_c > RW_CORE_NORMAL)
			core_c = max(RW_CORE_NORMAL, core_c - step)

	set_coretemperature(RW_TO_K(clamp(core_c, 10, 50)))
	// Keep bodytemperature (skin / legacy systems) near core so TG cold damage
	// paths do not treat outdoor air as the body temperature and KO in seconds.
	if(bodytemperature)
		var/target_k = RW_TO_K(core_c)
		bodytemperature += (target_k - bodytemperature) * min(1, 0.35 * seconds_per_tick)

	update_rw_thermal_alert(stress, core_c)
	update_rw_thermal_mood(stress)

	sync_rw_thermal_injuries(core_c)
	process_rw_frostbite(ambient, range, seconds_per_tick, core_c)


/mob/living/carbon/human/proc/update_rw_thermal_alert(stress, core_c)
	var/severity = 0
	if(stress > 0 || core_c < RW_HYPO_MILD)
		severity = core_c < RW_HYPO_SEVERE ? 3 : (core_c < RW_HYPO_MODERATE ? 2 : 1)
		throw_alert(ALERT_TEMPERATURE, /atom/movable/screen/alert/cold, severity)
	else if(stress < 0 || core_c > RW_HYPER_MILD)
		severity = core_c > RW_HYPER_SEVERE ? 3 : (core_c > RW_HYPER_MODERATE ? 2 : 1)
		throw_alert(ALERT_TEMPERATURE, /atom/movable/screen/alert/hot, severity)
	else
		clear_alert(ALERT_TEMPERATURE)


/mob/living/carbon/human/proc/update_rw_thermal_mood(stress)
	var/datum/psychology/psy = get_psychology()
	if(!psy)
		return
	if(!stress)
		if(psy.get_factor("env_temperature"))
			psy.clear_factor("env_temperature")
		return
	var/amount = -clamp(abs(stress) * 0.25, 1, 10)
	var/text = stress > 0 ? "Uncomfortably cold." : "Uncomfortably hot."
	var/datum/psychology_factor/current = psy.get_factor("env_temperature")
	// Avoid recalculating mood every tick for tiny changes.
	if(current && abs(current.mood_change - amount) < 0.5 && current.description == text)
		return
	psy.add_factor("env_temperature", stress > 0 ? "cold" : "hot", round(amount, 0.5), text)



/// Which injury type corresponds to this core temperature (null = none).
/mob/living/carbon/human/proc/get_rw_core_injury_type(core_c)
	if(core_c < RW_HYPO_CRITICAL)
		return /datum/injury/hypothermia/critical
	if(core_c < RW_HYPO_SEVERE)
		return /datum/injury/hypothermia/severe
	if(core_c < RW_HYPO_MODERATE)
		return /datum/injury/hypothermia/moderate
	if(core_c < RW_HYPO_MILD)
		return /datum/injury/hypothermia
	if(core_c > RW_HYPER_CRITICAL)
		return /datum/injury/heatstroke/critical
	if(core_c > RW_HYPER_SEVERE)
		return /datum/injury/heatstroke/severe
	if(core_c > RW_HYPER_MODERATE)
		return /datum/injury/heatstroke/moderate
	if(core_c > RW_HYPER_MILD)
		return /datum/injury/heatstroke
	return null


/mob/living/carbon/human/proc/sync_rw_thermal_injuries(core_c)
	var/obj/item/bodypart/chest = get_bodypart(BODY_ZONE_CHEST)
	if(!chest)
		return
	// find_injury_series may not exist on older injury systems — guard hard.
	if(!hascall(chest, "find_injury_series"))
		return

	var/desired = get_rw_core_injury_type(core_c)
	var/datum/injury/existing = chest.find_injury_series(RW_SERIES_HYPOTHERMIA) || chest.find_injury_series(RW_SERIES_HEATSTROKE)

	if(!desired)
		// Back in the normal band: the injury stays until core temperature is close to normal, then it heals.
		if(existing && abs(core_c - RW_CORE_NORMAL) < 0.8)
			existing.remove_from_limb()
			qdel(existing)
		return

	if(existing && existing.type == desired)
		return

	var/datum/injury/new_injury = new desired
	if(!existing)
		new_injury.apply_to_limb(chest, silent = FALSE, source = "exposure")
		return
	// Same series can move up OR down; apply_to_limb() only upgrades, so swap manually.
	if(existing.series == new_injury.series)
		new_injury.skip_initial_response = new_injury.severity <= existing.severity
		existing.replace_with(new_injury, silent = new_injury.severity <= existing.severity, source = "exposure")
	else
		// Cold -> heat overshoot (rare): clear the old one first.
		existing.remove_from_limb()
		qdel(existing)
		new_injury.apply_to_limb(chest, silent = FALSE, source = "exposure")


/mob/living/carbon/human/proc/process_rw_frostbite(ambient, list/range, seconds_per_tick, core_c)
	var/list/zone_min = range["zone_min"]
	if(!islist(zone_min))
		return
	if(!rw_frost_exposure)
		rw_frost_exposure = list()
	for(var/zone in GLOB.rw_frostbite_zones)
		var/obj/item/bodypart/limb = get_bodypart(zone)
		if(!limb)
			rw_frost_exposure -= zone
			continue
		// Deep cold: well below what THIS limb's clothing allows.
		var/deficit = (zone_min[zone] - 12) - ambient
		var/exposure = rw_frost_exposure[zone] || 0
		if(core_c <= RW_HYPO_MILD && deficit > 0 && ambient < 0)
			// Frostnip takes ~38s at a 20 C deficit; deeper frostbite stages take longer.
			exposure += seconds_per_tick * clamp(deficit / 30, 0.25, 1.5)
		else
			exposure = max(0, exposure - seconds_per_tick * 2)
		rw_frost_exposure[zone] = exposure

		var/datum/injury/existing = limb.find_injury_series(RW_SERIES_FROSTBITE)
		var/desired
		if(exposure >= 120)
			desired = /datum/injury/frostbite/necrotic
		else if(exposure >= 60)
			desired = /datum/injury/frostbite/severe
		else if(exposure >= 25)
			desired = /datum/injury/frostbite
		if(!desired || (existing && existing.type == desired))
			continue
		// Frostbite only gets worse by exposure; it never downgrades here (healing does that).
		if(existing && existing.severity >= initial_injury_severity(desired))
			continue
		var/datum/injury/new_injury = new desired
		new_injury.apply_to_limb(limb, silent = FALSE, source = "frostbite")
#endif
