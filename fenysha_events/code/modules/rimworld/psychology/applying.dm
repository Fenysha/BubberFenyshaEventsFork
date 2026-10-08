/// Returns the psychology datum on a mob, or null.
/mob/living/proc/get_psychology()
	RETURN_TYPE(/datum/psychology)
	return GetComponent(/datum/component/psychology)?.psychology

/// Ensures the mob has a psychology component + datum (no persona fill).
/mob/living/proc/ensure_psychology()
	RETURN_TYPE(/datum/psychology)
	var/datum/component/psychology/C = GetComponent(/datum/component/psychology)
	if(!C)
		C = AddComponent(/datum/component/psychology)
	return C.psychology

/**
 * Component that owns the psychology datum and keeps it tied to the mob.
 */
/datum/component/psychology
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/datum/psychology/psychology

/datum/component/psychology/Initialize()
	if(!isliving(parent))
		return COMPONENT_INCOMPATIBLE
	psychology = new /datum/psychology(parent)

/datum/component/psychology/Destroy(force)
	QDEL_NULL(psychology)
	return ..()

/**
 * Global: assign psychology to a living mob.
 *
 * Arguments:
 * * target — living mob that receives psychology
 * * persona_data — neutral persona payload; when null, persona is randomized
 *
 * Returns the /datum/psychology instance, or null on failure.
 */
/proc/apply_psychology(mob/living/target, list/persona_data = null)
	RETURN_TYPE(/datum/psychology)
	if(!isliving(target))
		return null
	var/datum/psychology/psy = target.ensure_psychology()
	if(!psy)
		return null
	if(islist(persona_data))
		psy.load_persona(persona_data)
	else
		psy.randomize_persona()
	return psy

/**
 * Convenience wrapper on prefs — Psychology owns component initialization and persona effects.
 */
/datum/rimworld_preferences/proc/apply_psychology_to(mob/living/carbon/human/target)
	if(!istype(target) || istype(target, /mob/living/carbon/human/dummy))
		return null
	var/list/persona_data = list(
		"childhood" = childhood_id,
		"adulthood" = adulthood_id,
		"traits" = effective_trait_ids(),
		"skills" = copy_list(skills),
		"passions" = copy_list(passions),
		"xenogenes" = copy_list(xenogenes),
	)
	return apply_psychology(target, persona_data)

/**
 * Verb to open the psychology UI.
 */
/mob/living/proc/view_psychology()
	var/datum/psychology/psy = get_psychology()
	if(!psy)
		psy = apply_psychology(src) // random persona if nothing was set yet
	if(!psy)
		return
	var/datum/tgui/ui = new(src, psy, "Psychology")
	ui.open()

// TGUI host on the psychology datum
/datum/psychology/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Psychology")
		ui.set_autoupdate(TRUE)
		ui.open()

/datum/psychology/ui_state(mob/user)
	return GLOB.conscious_state

/datum/psychology/ui_data(mob/user)
	var/list/data = build_ui_data()
	data["persona"] = build_ui_persona_data()
	data["pawnName"] = owner?.real_name || owner?.name || "Unknown colonist"
	data["speciesName"] = owner?.name || "Unknown species"
	if(ishuman(owner))
		var/mob/living/carbon/human/H = owner
		data["speciesName"] = H.dna?.species?.name || "Human"
		if(H.dna?.rw_xenotype)
			data["xenotype"] = H.dna.rw_xenotype.compile_ui_data()
	if(GLOB.all_rw_backstories)
		var/datum/rw_backstory/child = GLOB.all_rw_backstories[childhood_id]
		var/datum/rw_backstory/adult = GLOB.all_rw_backstories[adulthood_id]
		data["childhoodName"] = child?.name || childhood_id || "None"
		data["adulthoodName"] = adult?.name || adulthood_id || "None"
	else
		data["childhoodName"] = childhood_id || "None"
		data["adulthoodName"] = adulthood_id || "None"
	if(GLOB.all_rw_traits)
		var/list/trait_names = list()
		for(var/tid in trait_ids)
			var/datum/rw_trait/T = GLOB.all_rw_traits[tid]
			trait_names += T?.name || tid
		data["traitNames"] = trait_names
	else
		data["traitNames"] = trait_ids?.Copy() || list()
	return data

/datum/psychology/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	switch(action)
		if("mental_break")
			if(!ui?.user || (ui.user != owner && !ui.user.client?.holder))
				return FALSE
			if(is_in_break())
				return FALSE
			var/severity = text2num(params["severity"])
			if(!(severity in list(PSY_BREAK_MINOR, PSY_BREAK_MAJOR, PSY_BREAK_EXTREME)))
				severity = PSY_BREAK_MINOR
			return start_mental_break(severity)
	return FALSE
