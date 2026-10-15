/// Global override table: typepath -> value. Checked before type vars.
GLOBAL_LIST_EMPTY(rw_market_value_overrides)

/// Base market value stored on the type (initial()). Prefer this over hardcoding in procs.
/atom
	VAR_PROTECTED/rw_base_value = 0

/atom/proc/get_rw_market_value()
	if(rw_base_value)
		return max(0, rw_base_value)
	var/override = GLOB.rw_market_value_overrides[type]
	if(!isnull(override))
		return max(0, override)
	return 0

/atom/movable/get_rw_market_value()
	. = ..()
	for(var/atom/movable/thing as anything in contents)
		if(QDELETED(thing))
			continue
		. += thing.get_rw_market_value()

/obj/item/get_rw_market_value()
	. = ..()
	if(custom_price)
		return max(., custom_price)
	// Stacks: value per unit * amount when amount exists.
	if(isstack(src))
		var/obj/item/stack/S = src
		var/unit = rw_base_value || GLOB.rw_market_value_overrides[type] || 1
		return max(0, unit * S.amount)
	return .

/obj/item/stack/get_rw_market_value()
	. = ..()
	. *= amount
	return .

/obj/structure/get_rw_market_value()
	. = ..()
	if(!.)
		. = 25

/obj/machinery/get_rw_market_value()
	. = ..()
	if(!.)
		. = 80

/turf/get_rw_market_value()
	// Floors/walls themselves are usually covered by structures; only count explicit values.
	return rw_base_value || GLOB.rw_market_value_overrides[type] || 0

/// Register a typepath value (call from an init or module load).
/proc/rw_set_market_value(typepath, value)
	if(!ispath(typepath))
		return
	GLOB.rw_market_value_overrides[typepath] = max(0, value)

/**
 * Sum market value of every atom on the local map of a planet cell.
 * Expensive — cache the result (storyteller already snapshots every 10s).
 */
/datum/planet_cell/proc/calculate_colony_wealth()
	if(!is_loaded())
		return 0

	var/total = 0
	var/list/processed = list()

	for(var/turf/T as anything in get_local_turfs())
		if(!T)
			continue
		total += T.get_rw_market_value()
		for(var/atom/movable/A as anything in T)
			if(QDELETED(A) || processed[A])
				continue
			processed[A] = TRUE
			// Living mobs: only count their worn/held gear, not the body itself (colonists are
			// already counted via pawn_points in threat formula).
			if(isliving(A))
				var/mob/living/L = A
				if(L.stat == DEAD)
					continue
				for(var/obj/item/I as anything in L.get_equipped_items())
					if(QDELETED(I) || processed[I])
						continue
					processed[I] = TRUE
					total += I.get_rw_market_value()
				continue
			total += A.get_rw_market_value()

	return max(0, round(total))

/// Optional: value contributed by researched blueprints / tech (not physical objects).
/datum/planet_cell/proc/calculate_tech_wealth_bonus()
	var/datum/rimworld_planet_object/settlement/settlement = get_colony_settlement()
	if(!settlement)
		return 0
	var/datum/rw_faction/player/player_fac = SSfactions.get_faction(settlement.data["faction"])
	if(!istype(player_fac) || !player_fac.techweb)
		return 0
	var/nodes = length(player_fac.techweb.researched_nodes)
	// Each researched node is worth a flat "knowledge" value toward colony wealth.
	return nodes * 40

/// Example defaults — expand this list as real blueprints/items are added.
/proc/init_rw_default_market_values()
	// Structures / furniture
	return
