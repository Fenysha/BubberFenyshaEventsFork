/datum/rw_crafting_recipe
	var/id
	var/name = "Unnamed Recipe"
	var/desc = ""

	/// Display category shown in the crafting UI and used for workbench filtering.
	var/category = "General"

	var/result_path
	var/result_amount = 1

	/// Item typepath => quantity consumed per craft.
	var/list/requirements = list()

	/**
	 * How the recipe is crafted:
	 *
	 * RW_CRAFT_TYPE_DELIVER   - bring every ingredient to the bench, then one timed craft runs.
	 * RW_CRAFT_TYPE_WORKPIECE - once the ingredients are on the bench they are absorbed into a
	 *                           workpiece that stores the recipe. The player then works on the
	 *                           workpiece in `work_steps` consecutive steps.
	 */
	var/craft_type = RW_CRAFT_TYPE_DELIVER

	/// Total time at ideal skill. For workpiece recipes it is split between `work_steps`.
	var/crafting_time = 3 SECONDS

	/// Number of work steps. Only used by RW_CRAFT_TYPE_WORKPIECE.
	var/work_steps = 4

	/// Optional workbench type restriction. If unset, the bench's category/ID filter applies.
	var/required_bench

	/// Skill that is used for timing and trained by crafting this recipe.
	var/required_skill = RW_SKILL_CRAFTING
	/// Crafter must have at least this level to start/work on the recipe.
	var/min_skill = 0
	/// Skill level at which `crafting_time` is used unchanged.
	var/ideal_skill = 6
	/// XP granted per finished step (or once for deliver recipes).
	var/skill_xp = 1


/datum/rw_crafting_recipe/proc/is_workpiece()
	return craft_type == RW_CRAFT_TYPE_WORKPIECE

/// Steps the job consists of. Deliver recipes are a single step.
/datum/rw_crafting_recipe/proc/get_total_steps()
	return is_workpiece() ? max(1, work_steps) : 1

/// Time of one step before skill modifiers.
/datum/rw_crafting_recipe/proc/get_step_time()
	return max(0.1 SECONDS, crafting_time / get_total_steps())


/// Returns a PNG base64 string for an item's icon, cached by typepath for TGUI use.
/proc/rw_get_recipe_item_icon_src(item_path)
	if(!ispath(item_path, /obj/item))
		return null

	var/static/list/icon_cache = list()
	var/cache_key = "[item_path]"
	if(!isnull(icon_cache[cache_key]))
		return icon_cache[cache_key]

	var/obj/item/item_type = item_path
	if(!initial(item_type.icon))
		icon_cache[cache_key] = ""
		return null

	var/icon/item_icon = icon(initial(item_type.icon), initial(item_type.icon_state), SOUTH, 1)
	if(!item_icon)
		icon_cache[cache_key] = ""
		return null

	var/icon_src = icon2base64(item_icon)
	icon_cache[cache_key] = icon_src
	return icon_src


/// Human readable skill name for UI/balloons.
/proc/rw_get_skill_name(skill_id)
	if(!skill_id)
		return "None"
	if(length(GLOB.all_rw_skills))
		var/datum/rw_skill/skill = GLOB.all_rw_skills[skill_id]
		if(skill)
			return skill.name
	return capitalize("[skill_id]")


/**
 * Whether `I` can be taken from `user` for crafting/delivering.
 * Worn clothing is never available, only held items and things in containers.
 */
/proc/rw_item_is_available(mob/living/user, obj/item/I)
	if(QDELETED(I))
		return FALSE
	if(ismob(I.loc) && !user.is_holding(I))
		return FALSE
	return TRUE

/// Counts items of `item_path` (stacks by amount) the user can use.
/proc/rw_count_items_of_type(mob/living/user, item_path, list/contents = null)
	if(!user || !ispath(item_path, /obj/item))
		return 0
	if(!islist(contents))
		contents = user.get_all_contents()
	var/total = 0
	for(var/obj/item/I in contents)
		if(!istype(I, item_path) || !rw_item_is_available(user, I))
			continue
		if(istype(I, /obj/item/stack))
			var/obj/item/stack/S = I
			total += S.amount
		else
			total++
	return total
