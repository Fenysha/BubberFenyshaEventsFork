#ifndef OLD_COMBAT_SYSTEM
/obj/item/bodypart
	/// Sharp tissue density (mm RHA) — reduces AP after this layer takes damage.
	var/density_sharp = BODYPART_DENSITY_SHARP_DEFAULT
	/// Blunt tissue density (MPa).
	var/density_blunt = BODYPART_DENSITY_BLUNT_DEFAULT

	/// Natural armor on this part (carapace etc.), same units as clothing.
	var/natural_sharp_armor = 0
	var/natural_blunt_armor = 0

	var/list/injuries
	var/injury_damage_multiplier = 1.0
	var/current_pain = 0

/obj/item/bodypart/proc/update_injuries(replaced = FALSE)
	var/new_multiplier = 1.0
	var/new_pain = 0

	for(var/datum/injury/injury as anything in injuries)
		new_multiplier *= injury.get_damage_multiplier()
		new_pain += injury.get_pain()

	injury_damage_multiplier = min(new_multiplier, MAX_INJURY_DAMAGE_MULTIPLIER)
	current_pain = new_pain

	if(owner)
		owner.update_pain_from_limb(src)

	refresh_bleed_rate()

/**
 * Returns existing injury on this limb with the given series, or null.
 */
/obj/item/bodypart/proc/find_injury_series(series_id)
	for(var/datum/injury/injury as anything in injuries)
		if(injury.series == series_id)
			return injury
	return null

/obj/item/bodypart/proc/has_injury_type(injury_type)
	for(var/datum/injury/injury as anything in injuries)
		if(injury.type == injury_type)
			return TRUE
	return FALSE

/**
 * Returns the fraction of the limb's structural integrity that has been lost.
 *
 * Brute damage represents destruction of muscle, connective tissue,
 * bone and other physical structures.
 *
 * 0.0 = intact
 * 1.0 = completely destroyed
 */
/obj/item/bodypart/proc/get_physical_damage_ratio()
	if(max_damage <= 0)
		return 1
	return clamp(brute_dam / max_damage, 0, 1)

/**
 * Returns the fraction of the limb's skin integrity that has been lost.
 *
 * Burn damage represents destruction of the skin and superficial tissue.
 *
 * 0.0 = intact
 * 1.0 = completely destroyed
 */
/obj/item/bodypart/proc/get_skin_damage_ratio()
	if(max_damage <= 0)
		return 1
	return clamp(burn_dam / max_damage, 0, 1)

/obj/item/bodypart/proc/get_physical_integrity()
	return 1 - get_physical_damage_ratio()

/obj/item/bodypart/proc/get_skin_integrity()
	return 1 - get_skin_damage_ratio()
#endif
