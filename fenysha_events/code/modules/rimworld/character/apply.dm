/datum/rimworld_preferences/proc/apply_to_human(mob/living/carbon/human/target, visuals_only = FALSE)
	if(!istype(target))
		return FALSE
	sanitize_character()
	target.real_name = real_name
	target.name = real_name
	if(istype(target, /mob/living/carbon/human/dummy))
		target.underwear_visibility = NONE
	var/datum/preferences/bridge = ensure_pref_bridge()
	refresh_pref_species()
	if(bridge)
		bridge.apply_prefs_to(target, icon_updates = FALSE, visuals_only = visuals_only)
	target.dna.set_rw_xenogenes(xenogenes, apply = TRUE)
	var/list/final_skills = list()
	for(var/skill_id in GLOB.all_rw_skills)
		final_skills[skill_id] = get_skill_level(skill_id)
	var/datum/component/rw_skills/skill_comp = target.GetComponent(/datum/component/rw_skills)
	if(skill_comp)
		skill_comp.set_levels(final_skills)
	else
		target.AddComponent(/datum/component/rw_skills, final_skills)
	for(var/item_id in loadout)
		var/datum/rw_loadout_item/item = GLOB.all_rw_loadout[item_id]
		item?.equip_to(target)
	target.icon_render_keys = list()
	target.update_body(TRUE)
	if(istype(target, /mob/living/carbon/human/dummy))
		apply_dummy_clothes(target)
	target.update_hair()
	target.update_eyes()
	return TRUE

/datum/rimworld_preferences/proc/apply_saved_look(mob/living/carbon/human/target, list/data)
	if(!istype(target) || !data)
		return FALSE
	var/list/saved = serialize_character()
	deserialize_character(data)
	apply_to_human(target, visuals_only = TRUE)
	deserialize_character(saved)
	return TRUE
