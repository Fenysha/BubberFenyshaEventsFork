/obj/machinery/rw_workbench
	name = "workbench"
	desc = "A sturdy workbench."
	icon_state = "workbench"
	anchored = TRUE
	density = TRUE
	use_power = IDLE_POWER_USE
	idle_power_usage = 50
	active_power_usage = 200

	var/datum/rw_faction/player/owner_faction

	var/can_do_crafting = FALSE
	var/attachment_range = 1

	/// If set, this bench only offers these recipe IDs. Takes precedence over recipe_categories.
	var/list/recipe_ids = list()
	/// If recipe_ids is empty, recipes in these categories are offered. Empty means any compatible recipe.
	var/list/recipe_categories = list()

/obj/machinery/rw_workbench/Initialize(mapload)
	. = ..()
	if(owner_faction)
		set_owner_faction(owner_faction)

/obj/machinery/rw_workbench/Destroy()
	set_owner_faction(null)
	return ..()

/obj/machinery/rw_workbench/proc/set_owner_faction(datum/rw_faction/player/new_faction)
	if(owner_faction?.techweb)
		owner_faction.techweb.benches -= src
	owner_faction = new_faction
	if(owner_faction?.techweb)
		owner_faction.techweb.benches |= src

/obj/machinery/rw_workbench/proc/get_nearby_attachments()
	var/list/found = list()
	for(var/obj/structure/rw_bench_attachment/attachment in range(attachment_range, src))
		if(attachment.is_functional())
			found += attachment
	return found

/obj/machinery/rw_workbench/proc/get_crafting_faction(mob/living/user)
	if(!istype(user))
		return null
	if(owner_faction)
		return owner_faction.is_member(user) ? owner_faction : null
	if(istype(user.rw_faction, /datum/rw_faction/player))
		return user.rw_faction
	return null

/obj/machinery/rw_workbench/proc/accepts_recipe(datum/rw_crafting_recipe/recipe)
	if(!can_do_crafting || !istype(recipe))
		return FALSE
	if(recipe.required_bench && !istype(src, recipe.required_bench))
		return FALSE
	if(length(recipe_ids))
		return recipe.id in recipe_ids
	if(length(recipe_categories))
		return recipe.category in recipe_categories
	return TRUE

/// Shared skill gate. Tells the user what is missing.
/obj/machinery/rw_workbench/proc/check_skill(mob/living/user, skill_id, min_level, silent = FALSE)
	if(!skill_id || min_level <= 0)
		return TRUE
	if(rw_has_skill(user, skill_id, min_level))
		return TRUE
	if(!silent)
		balloon_alert(user, "needs [rw_get_skill_name(skill_id)] [min_level]")
	return FALSE
