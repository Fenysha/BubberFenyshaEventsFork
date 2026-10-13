/// Storyteller-facing helpers for planet cells: is there a colony here, who lives in it,
/// how rich is it. Everything is cached for a few seconds because events ask every tick.
/datum/planet_cell
	var/datum/rimworld_planet_object/settlement/storyteller_colony
	var/list/mob/living/storyteller_colonists = list()
	var/storyteller_snapshot_expires = 0
	/// Cached market value of the colony (structures + items + tech bonus).
	var/storyteller_wealth_cache = 0
	var/storyteller_wealth_expires = 0

/datum/planet_cell/proc/refresh_storyteller_snapshot(force = FALSE)
	if(!force && world.time < storyteller_snapshot_expires)
		return
	storyteller_snapshot_expires = world.time + 10 SECONDS
	storyteller_colony = null
	storyteller_colonists = list()

	var/datum/rimworld_planet_object/settlement/settlement = planet?.get_settlement_at(x, y)
	if(settlement?.is_player_settlement())
		storyteller_colony = settlement

	if(!is_loaded())
		return
	for(var/mob/living/player as anything in GLOB.player_list)
		if(!istype(player) || player.stat == DEAD)
			continue
		var/turf/player_turf = get_turf(player)
		if(!player_turf || get_planet_cell(player_turf) != src)
			continue
		storyteller_colonists += player

/// The player settlement standing on this cell, or null.
/datum/planet_cell/proc/get_colony_settlement()
	refresh_storyteller_snapshot()
	return storyteller_colony

/datum/planet_cell/proc/has_colony()
	return !isnull(get_colony_settlement())

/// Living player-controlled mobs currently standing on this cell's local map.
/datum/planet_cell/proc/get_colonists()
	refresh_storyteller_snapshot()
	return storyteller_colonists

/datum/planet_cell/proc/get_colonist_count()
	return length(get_colonists())

/**
 * Colony wealth in "silver" units.
 * Primary source: live sum of get_rw_market_value() over the loaded map
 * (buildings, machines, items, worn gear) + research knowledge bonus.
 * Fallback: settlement.data["wealth"] if the map is not loaded or calculation returns 0.
 * Result is cached for 30 seconds.
 */
/datum/planet_cell/proc/get_colony_wealth()
	if(world.time < storyteller_wealth_expires)
		return storyteller_wealth_cache

	var/calculated = 0
	if(is_loaded())
		calculated = calculate_colony_wealth() + calculate_tech_wealth_bonus()

	// Persist into settlement data so unloaded cells / other systems can read it.
	var/datum/rimworld_planet_object/settlement/settlement = get_colony_settlement()
	if(settlement)
		if(calculated > 0)
			settlement.data["wealth"] = calculated
		else
			calculated = max(0, text2num("[settlement.data["wealth"]]") || 0)

	storyteller_wealth_cache = calculated
	storyteller_wealth_expires = world.time + 30 SECONDS
	return storyteller_wealth_cache

/// Planet days since the storyteller first saw this cell.
/datum/planet_cell/proc/get_colony_age_days()
	return max(0, SSstorytellers.get_current_day() - get_storyteller_plan().first_seen_day)

/// Highest tech era reached by the player faction that owns this colony (0 = none).
/datum/planet_cell/proc/get_colony_tech_level()
	var/datum/rimworld_planet_object/settlement/settlement = get_colony_settlement()
	if(!settlement)
		return 0
	var/datum/rw_faction/player/fac = SSfactions.get_faction(settlement.data["faction"])
	if(!istype(fac))
		return 0
	return fac.get_tech_level()
