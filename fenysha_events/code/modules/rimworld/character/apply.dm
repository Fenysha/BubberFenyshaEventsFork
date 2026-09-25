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
	apply_xenogene_options()
	var/list/skip_prefs = list(
		/datum/preference/numeric/body_size,
		/datum/preference/choiced/species,
	)
	var/wanted_species = rw_species()
	if(target.dna && target.dna.species?.type != wanted_species)
		var/list/features
		var/list/mutantparts
		var/list/markings
		if(bridge)
			features = copy_list(bridge.features)
			mutantparts = copy_list(bridge.mutant_bodyparts)
			markings = copy_list(bridge.body_markings)
		target.set_species(wanted_species, FALSE, FALSE, TRUE, features, mutantparts, markings)
	if(istype(target, /mob/living/carbon/human/dummy))
		var/wanted_legs = NORMAL_LEGS
		if((RW_XENOGENE_LEGS in xenogenes) && islist(xenogene_values) && xenogene_values[RW_XENOGENE_LEGS])
			wanted_legs = xenogene_values[RW_XENOGENE_LEGS]
		var/has_digitigrade = !!(target.bodyshape & BODYSHAPE_DIGITIGRADE)
		if(has_digitigrade == (wanted_legs == DIGITIGRADE_LEGS))
			skip_prefs += /datum/preference/choiced/digitigrade_legs
	if(bridge)
		bridge.apply_prefs_to(target, FALSE, skip_prefs, visuals_only)
	apply_body_size_to(target)
	apply_xenogene_visuals(target)
	if(target.dna && !istype(target, /mob/living/carbon/human/dummy))
		target.dna.set_rw_xenogenes(xenogenes, xenogene_values, TRUE)
		if(target.dna.rw_xenogenes)
			for(var/gene_id in target.dna.rw_xenogenes)
				var/datum/rw_xenogene/live_gene = target.dna.rw_xenogenes[gene_id]
				if(live_gene)
					live_gene.inheritable = islist(xenogene_inheritable) && (gene_id in xenogene_inheritable)
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
		if(item)
			item.equip_to(target)
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
	apply_to_human(target, TRUE)
	deserialize_character(saved)
	return TRUE

/datum/rimworld_preferences/proc/apply_body_size_to(mob/living/carbon/human/target)
	if(!istype(target))
		return
	var/wanted = RESIZE_DEFAULT_SIZE
	if(RW_XENOGENE_BODY_SIZE in xenogenes)
		var/raw = islist(xenogene_values) ? xenogene_values[RW_XENOGENE_BODY_SIZE] : null
		if(isnum(raw))
			wanted = raw
		else if(!isnull(raw))
			wanted = text2num(raw)
		if(!isnum(wanted))
			wanted = RESIZE_DEFAULT_SIZE
		wanted = clamp(wanted, BODY_SIZE_MIN, BODY_SIZE_MAX)
	if(abs(target.current_size - wanted) < 0.001)
		return
	if(!istype(target, /mob/living/carbon/human/dummy))
		target.update_transform(wanted / target.current_size)
		return
	target.current_size = RESIZE_DEFAULT_SIZE
	target.transform = matrix()
	if(wanted == RESIZE_DEFAULT_SIZE)
		return
	var/matrix/scaled = matrix()
	scaled.Scale(wanted)
	scaled.Translate(0, (wanted - 1) * 16)
	target.transform = scaled
	target.current_size = wanted

/datum/rimworld_preferences/proc/apply_xenogene_visuals(mob/living/carbon/human/target)
	if(!istype(target) || !target.dna)
		return
	if(!islist(xenogene_values))
		xenogene_values = list()
	for(var/gene_id in GLOB.all_rw_xenogenes)
		var/datum/rw_xenogene/gene = GLOB.all_rw_xenogenes[gene_id]
		if(!gene || !(gene.xenogen_flags & RW_XENOGEN_VISUAL))
			continue
		gene.apply_visual(target, (gene_id in xenogenes), xenogene_values[gene_id])
	if(!target.dna.species)
		return
	var/is_dummy = istype(target, /mob/living/carbon/human/dummy)
	target.dna.species.regenerate_organs(target, null, is_dummy, null, is_dummy, TRUE)
