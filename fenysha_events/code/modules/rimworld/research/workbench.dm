/obj/machinery/rw_workbench
	name = "workbench"
	desc = "A sturdy workbench."
	/// icon = 'icons/obj/machines/rw_workbench.dmi'
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

/obj/machinery/rw_workbench/research
	name = "research bench"
	desc = "A bench dedicated to studying and experimenting."
	icon_state = "research_bench"

	var/research_power = 1

/obj/machinery/rw_workbench/research/proc/is_valid_for_node(datum/techweb_node/rw/node)
	if(research_power <= 0)
		return FALSE
	if(length(node.workbench_types) && !is_type_in_list(src, node.workbench_types))
		return FALSE
	return TRUE

/obj/machinery/rw_workbench/research/proc/get_missing_attachments(datum/techweb_node/rw/node)
	var/list/missing = list()
	var/list/nearby = get_nearby_attachments()
	for(var/required_path in node.required_attachments)
		var/found = FALSE
		for(var/obj/structure/rw_bench_attachment/attachment as anything in nearby)
			if(istype(attachment, required_path))
				found = TRUE
				break
		if(!found)
			var/atom/required_atom = required_path
			missing += initial(required_atom.name)
	return missing

/obj/machinery/rw_workbench/research/proc/can_research(datum/techweb_node/rw/node)
	if(QDELETED(src) || !anchored || (machine_stat & (BROKEN|NOPOWER)))
		return FALSE
	if(!is_valid_for_node(node))
		return FALSE
	return !length(get_missing_attachments(node))

/obj/machinery/rw_workbench/research/proc/get_research_multiplier(datum/techweb_node/rw/node)
	if(!can_research(node))
		return 0
	var/mult = research_power
	for(var/obj/structure/rw_bench_attachment/attachment as anything in get_nearby_attachments())
		mult += attachment.research_bonus
	return mult

/obj/machinery/rw_workbench/research/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if(.)
		return
	try_research(user)

/obj/machinery/rw_workbench/research/proc/try_research(mob/living/user)
	if(!owner_faction)
		balloon_alert(user, "no faction assigned!")
		return
	if(!owner_faction.is_member(user))
		balloon_alert(user, "not your faction!")
		return
	if(!owner_faction.can_manage_research(user))
		balloon_alert(user, "you can't research!")
		return

	var/datum/techweb/faction/web = owner_faction.techweb
	if(!web?.current_research_id)
		balloon_alert(user, "nothing to research!")
		return

	var/datum/techweb_node/rw/node = web.get_rw_node(web.current_research_id)
	if(!node)
		balloon_alert(user, "invalid research!")
		return

	if(!can_research(node))
		var/list/missing = get_missing_attachments(node)
		if(length(missing))
			balloon_alert(user, "missing: [english_list(missing)]")
		else
			balloon_alert(user, "wrong workbench!")
		return

	do_research_cycle(user, web, node)

/obj/machinery/rw_workbench/research/proc/do_research_cycle(mob/living/user, datum/techweb/faction/web, datum/techweb_node/rw/node)
	var/mult = get_research_multiplier(node)
	if(mult <= 0)
		return

	var/progress_gain = RW_RESEARCH_BASE_PROGRESS * mult

	var/success = rw_do_after(
		user,
		RW_RESEARCH_CYCLE_TIME,
		src,
		RW_SKILL_INTELLECTUAL,
		RW_RESEARCH_IDEAL_SKILL,
		minimum_delay = 1.5 SECONDS,
		skill_points = 2,
		timed_action_flags = IGNORE_USER_LOC_CHANGE,
		show_progress = TRUE
	)

	if(!success)
		return

	if(QDELETED(src) || QDELETED(web) || web.current_research_id != node.id)
		return

	web.add_research_progress(progress_gain)
	balloon_alert(user, "+[progress_gain] research")
	to_chat(user, span_notice("You make progress on [node.display_name]."))

/obj/machinery/rw_workbench/crafting
	name = "crafting station"
	desc = "A general-purpose crafting station."
	icon_state = "crafting_bench"
	can_do_crafting = TRUE

	var/crafting_in_progress = FALSE

/obj/machinery/rw_workbench/crafting/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if(.)
		return
	ui_interact(user)

/obj/machinery/rw_workbench/crafting/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "RWWorkbench", name)
		ui.open()

/obj/machinery/rw_workbench/crafting/ui_state(mob/user)
	if(!isliving(user))
		return GLOB.never_state
	if(owner_faction && !owner_faction.is_member(user))
		return GLOB.never_state
	return GLOB.not_incapacitated_state

/obj/machinery/rw_workbench/crafting/ui_data(mob/user)
	var/list/data = list()
	var/mob/living/L = user
	var/datum/rw_faction/player/F = get_crafting_faction(L)
	var/datum/techweb/faction/web = F?.techweb
	var/list/contents = L ? L.get_all_contents() : list()

	data["bench_name"] = name
	data["has_faction"] = !!F
	data["can_craft"] = !!F && !crafting_in_progress && anchored && !(machine_stat & (BROKEN|NOPOWER))
	data["busy"] = crafting_in_progress
	data["message"] = ""
	if(!F)
		data["message"] = owner_faction ? "This workbench belongs to another faction." : "Join a faction to use researched crafting recipes."
	else if(machine_stat & BROKEN)
		data["message"] = "The workbench is broken."
	else if(machine_stat & NOPOWER)
		data["message"] = "The workbench has no power."
	else if(crafting_in_progress)
		data["message"] = "Crafting is already in progress."

	var/list/recipes = list()
	if(web)
		for(var/recipe_id in web.unlocked_recipes)
			if(!web.unlocked_recipes[recipe_id])
				continue
			var/datum/rw_crafting_recipe/recipe = SSresearch.get_rw_crafting_recipe(recipe_id)
			if(!accepts_recipe(recipe))
				continue
			if(!ispath(recipe.result_path, /obj/item))
				continue

			var/list/requirements = list()
			var/enough_materials = TRUE
			for(var/item_path in recipe.requirements)
				var/atom/item_type = item_path
				var/needed = recipe.requirements[item_path]
				var/have = rw_count_recipe_items(L, item_path, contents)
				if(have < needed)
					enough_materials = FALSE
				requirements += list(list(
					"path" = "[item_path]",
					"name" = initial(item_type.name),
					"amount" = needed,
					"have" = have,
					"iconSrc" = rw_get_recipe_item_icon_src(item_path)
				))

			var/obj/item/result_type = recipe.result_path
			recipes += list(list(
				"id" = recipe.id,
				"name" = recipe.name,
				"desc" = recipe.desc,
				"category" = recipe.category,
				"crafting_time" = recipe.crafting_time / 10,
				"result_name" = initial(result_type.name),
				"result_amount" = recipe.result_amount,
				"resultIconSrc" = rw_get_recipe_item_icon_src(recipe.result_path),
				"requirements" = requirements,
				"canCraft" = data["can_craft"] && enough_materials
			))

	data["recipes"] = recipes
	return data

/obj/machinery/rw_workbench/crafting/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	if(action != "craft")
		return FALSE
	if(!istext(params["id"]))
		return FALSE
	return try_craft(ui.user, params["id"])

/obj/machinery/rw_workbench/crafting/proc/try_craft(mob/living/user, recipe_id)
	if(!istype(user) || QDELETED(src) || get_dist(user, src) > 1 || user.z != z)
		return FALSE
	if(crafting_in_progress)
		user.balloon_alert(user, "already crafting")
		return FALSE
	if(machine_stat & (BROKEN|NOPOWER))
		user.balloon_alert(user, "workbench unavailable")
		return FALSE

	var/datum/rw_faction/player/F = get_crafting_faction(user)
	var/datum/techweb/faction/web = F?.techweb
	if(!web || !F.is_member(user))
		user.balloon_alert(user, "no faction access")
		return FALSE
	if(!web.unlocked_recipes[recipe_id])
		user.balloon_alert(user, "recipe not researched")
		return FALSE

	var/datum/rw_crafting_recipe/recipe = SSresearch.get_rw_crafting_recipe(recipe_id)
	if(!accepts_recipe(recipe) || !ispath(recipe.result_path, /obj/item))
		user.balloon_alert(user, "recipe unavailable here")
		return FALSE
	if(!rw_has_recipe_items(user, recipe))
		user.balloon_alert(user, "missing materials")
		return FALSE

	crafting_in_progress = TRUE
	update_appearance(UPDATE_ICON)
	SStgui.update_uis(src)
	var/success = FALSE
	if(recipe.required_skill)
		success = rw_do_after(
			user,
			max(0.1 SECONDS, recipe.crafting_time),
			src,
			recipe.required_skill,
			recipe.skill_level,
			minimum_delay = 0.5 SECONDS,
			skill_points = 1,
			show_progress = TRUE
		)
	else
		success = do_after(user, max(0.1 SECONDS, recipe.crafting_time), src)

	if(!QDELETED(src))
		crafting_in_progress = FALSE
		update_appearance(UPDATE_ICON)
		SStgui.update_uis(src)
	if(!success || QDELETED(src) || QDELETED(user))
		return FALSE
	if(get_dist(user, src) > 1 || user.z != z || !anchored || (machine_stat & (BROKEN|NOPOWER)))
		user.balloon_alert(user, "workbench unavailable")
		return FALSE

	F = get_crafting_faction(user)
	web = F?.techweb
	if(!web || !F.is_member(user) || !web.unlocked_recipes[recipe_id] || !accepts_recipe(recipe))
		user.balloon_alert(user, "crafting interrupted")
		return FALSE
	if(!rw_has_recipe_items(user, recipe))
		user.balloon_alert(user, "missing materials")
		return FALSE
	if(!rw_consume_recipe_items(user, recipe))
		user.balloon_alert(user, "could not take materials")
		return FALSE

	var/turf/drop_turf = get_turf(src)
	if(!drop_turf)
		return FALSE
	if(ispath(recipe.result_path, /obj/item/stack))
		new recipe.result_path(drop_turf, max(1, recipe.result_amount))
	else
		for(var/i in 1 to max(1, recipe.result_amount))
			new recipe.result_path(drop_turf)

	user.balloon_alert(user, "crafted [recipe.name]")
	return TRUE

/obj/machinery/rw_workbench/crafting/proc/rw_has_recipe_items(mob/living/user, datum/rw_crafting_recipe/recipe)
	if(!user || !recipe)
		return FALSE
	var/list/contents = user.get_all_contents()
	for(var/item_path in recipe.requirements)
		if(rw_count_recipe_items(user, item_path, contents) < recipe.requirements[item_path])
			return FALSE
	return TRUE

/obj/machinery/rw_workbench/crafting/proc/rw_count_recipe_items(mob/living/user, item_path, list/contents = null)
	if(!user || !ispath(item_path, /obj/item))
		return 0
	if(!islist(contents))
		contents = user.get_all_contents()
	var/total = 0
	for(var/obj/item/I as anything in contents)
		if(QDELETED(I) || !istype(I, item_path))
			continue
		if(istype(I, /obj/item/stack))
			var/obj/item/stack/S = I
			total += S.amount
		else if(I.loc == user)
			total++
	return total

/obj/machinery/rw_workbench/crafting/proc/rw_consume_recipe_items(mob/living/user, datum/rw_crafting_recipe/recipe)
	if(!user || !recipe || !rw_has_recipe_items(user, recipe))
		return FALSE
	var/list/contents = user.get_all_contents()
	for(var/item_path in recipe.requirements)
		var/remaining = recipe.requirements[item_path]
		for(var/obj/item/I as anything in contents.Copy())
			if(remaining <= 0)
				break
			if(QDELETED(I) || !istype(I, item_path))
				continue
			if(istype(I, /obj/item/stack))
				var/obj/item/stack/S = I
				var/taken = min(S.amount, remaining)
				if(taken <= 0 || !S.use(taken))
					return FALSE
				remaining -= taken
			else
				if(I.loc != user || !user.temporarilyRemoveItemFromInventory(I))
					continue
				qdel(I)
				remaining--
		if(remaining > 0)
			return FALSE
	return TRUE

/obj/structure/rw_bench_attachment
	name = "bench attachment"
	desc = "Equipment that works together with a nearby workbench."
	anchored = TRUE
	density = TRUE
	var/research_bonus = 0

/obj/structure/rw_bench_attachment/proc/is_functional()
	return !QDELETED(src) && anchored

/obj/structure/rw_bench_attachment/analyzer
	name = "multi-analyzer"
	desc = "A set of instruments that speeds up research."
	research_bonus = 0.5
