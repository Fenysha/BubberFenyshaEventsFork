/**
 * Starting scenarios for player colonies.
 * Chosen at settlement foundation; gear is dropped near the first landing colonist.
 */

/datum/rimworld_scenario
	abstract_type = /datum/rimworld_scenario
	var/id = "default"
	var/name = "Crashlanding"
	var/desc = "You arrive with only the bare essentials."
	/// Weighted list of item paths or nested lists: list(path = weight) or list(list(path, amount), weight)
	var/list/starting_items = list()
	/// Flat guaranteed items: list(/obj/item/foo = 1, /obj/item/bar = 3)
	var/list/guaranteed_items = list()

/datum/rimworld_scenario/crashlanding
	id = "crashlanding"
	name = "Crashlanding"
	desc = "Emergency pod. Minimal tools, some food, a weapon."
	guaranteed_items = list(
		/obj/item/flashlight = 1,
		/obj/item/storage/box/survival = 1,
	)

/datum/rimworld_scenario/rich_explorer
	id = "rich_explorer"
	name = "Rich Explorer"
	desc = "Well-funded expedition. Extra tools and materials."
	guaranteed_items = list(
		/obj/item/flashlight = 2,
		/obj/item/storage/box/survival = 2,
	)

/datum/rimworld_scenario/tribal
	id = "tribal"
	name = "Tribal Landing"
	desc = "Simple tools and survival gear of a tribal group."
	guaranteed_items = list(
		/obj/item/flashlight = 1,
	)

/datum/rimworld_scenario/lost_colony
	id = "lost_colony"
	name = "Lost Colony Seed"
	desc = "Remnants of a larger colonial effort. More building materials."
	guaranteed_items = list(
		/obj/item/flashlight = 1,
		/obj/item/storage/box/survival = 1,
	)

/**
 * Registry helper — returns list of scenario datums (singletons by type).
 */
/proc/get_rimworld_scenarios()
	RETURN_TYPE(/list)
	var/static/list/cache
	if(!cache)
		cache = list()
		for(var/path in subtypesof(/datum/rimworld_scenario))
			var/datum/rimworld_scenario/S = new path
			cache[S.id] = S
	return cache

/proc/get_rimworld_scenario(id)
	RETURN_TYPE(/datum/rimworld_scenario)
	var/list/all = get_rimworld_scenarios()
	return all[id] || all["crashlanding"]

/**
 * Spawns scenario gear around a turf (near the landing pod).
 */
/datum/rimworld_scenario/proc/spawn_starting_gear(datum/planet_cell/cell, mob/living/first_colonist = null)
	if(!cell)
		return

	for(var/item_path in guaranteed_items)
		var/amount = guaranteed_items[item_path]
		if(!ispath(item_path, /obj/item))
			continue
		for(var/i in 1 to max(1, amount))
			launch_rimworld_pod(cell, list(new item_path()))

	for(var/entry in starting_items)
		// optional weighted random extras — leave for later expansion
		continue
