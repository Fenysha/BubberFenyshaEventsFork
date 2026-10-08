/datum/psychology/proc/get_skill_component()
	if(!owner)
		return
	return get_skills(owner)

/datum/psychology/proc/initialize_skills(list/base_levels, list/source_passions, list/source_traits, childhood, adulthood, list/source_xenogenes)
	if(!owner)
		return
	var/datum/component/rw_skills/skill_comp = get_or_add_skills(owner)
	if(!skill_comp)
		return
	for(var/skill_id in skill_comp.all_skills)
		var/base_level = islist(base_levels) ? (base_levels[skill_id] || RW_SKILL_MIN) : RW_SKILL_MIN
		var/final_level = rw_psychology_get_skill_level(skill_id, base_level, childhood, adulthood, source_traits, source_xenogenes)
		skill_comp.set_skill(skill_id, final_level)
		skill_comp.set_passion(skill_id, islist(source_passions) ? (source_passions[skill_id] || RW_PASSION_NONE) : RW_PASSION_NONE)
	apply_xenogene_passions(source_xenogenes)
	mark_xenogene_skill_bonuses(source_xenogenes)

/datum/psychology/proc/apply_xenogene_passions(list/xenogene_ids)
	if(!islist(xenogene_ids))
		return
	for(var/gene_id in xenogene_ids)
		var/datum/rw_xenogene/gene = GLOB.all_rw_xenogenes[gene_id]
		if(!gene?.passion_skill || isnull(gene.passion_grant))
			continue
		if(gene.passion_grant <= RW_PASSION_NONE)
			set_passion(gene.passion_skill, RW_PASSION_NONE)
		else if(get_passion(gene.passion_skill) < gene.passion_grant)
			set_passion(gene.passion_skill, gene.passion_grant)

/// Spawn applies skill numbers inside initialize_skills. Mark the live genes so removal can undo them.
/datum/psychology/proc/mark_xenogene_skill_bonuses(list/xenogene_ids)
	if(!iscarbon(owner) || !islist(xenogene_ids))
		return
	var/mob/living/carbon/pawn = owner
	if(!pawn.dna)
		return
	for(var/gene_id in xenogene_ids)
		var/datum/rw_xenogene/gene = pawn.dna.rw_xenogenes[gene_id]
		if(gene?.skill_bonuses)
			gene.skill_bonus_applied = TRUE

/proc/rw_psychology_get_skill_bonus(skill_id, childhood_id, adulthood_id, list/trait_ids, list/xenogene_ids)
	. = 0
	var/datum/rw_backstory/childhood = GLOB.all_rw_backstories[childhood_id]
	if(childhood?.skill_bonuses)
		. += childhood.skill_bonuses[skill_id] || 0
	var/datum/rw_backstory/adulthood = GLOB.all_rw_backstories[adulthood_id]
	if(adulthood?.skill_bonuses)
		. += adulthood.skill_bonuses[skill_id] || 0
	for(var/trait_id in trait_ids)
		var/datum/rw_trait/trait = GLOB.all_rw_traits[trait_id]
		if(trait?.skill_bonuses)
			. += trait.skill_bonuses[skill_id] || 0
	for(var/gene_id in xenogene_ids)
		var/datum/rw_xenogene/gene = GLOB.all_rw_xenogenes[gene_id]
		if(gene?.skill_bonuses)
			. += gene.skill_bonuses[skill_id] || 0

/proc/rw_psychology_get_skill_level(skill_id, base_level, childhood_id, adulthood_id, list/trait_ids, list/xenogene_ids)
	return clamp(round(text2num(base_level) || 0) + rw_psychology_get_skill_bonus(skill_id, childhood_id, adulthood_id, trait_ids, xenogene_ids), RW_SKILL_MIN, RW_SKILL_MAX)

/datum/psychology/proc/get_passion(skill_id)
	var/datum/component/rw_skills/skill_comp = get_skill_component()
	return skill_comp?.get_passion(skill_id) || RW_PASSION_NONE

/datum/psychology/proc/set_passion(skill_id, value, sync = TRUE)
	var/datum/component/rw_skills/skill_comp = get_skill_component()
	if(!skill_comp)
		return
	skill_comp.set_passion(skill_id, value)

/datum/psychology/proc/set_passions(list/source, sync = TRUE)
	var/datum/component/rw_skills/skill_comp = get_skill_component()
	if(!skill_comp)
		return
	for(var/skill_id in skill_comp.all_skills)
		skill_comp.set_passion(skill_id, islist(source) ? source[skill_id] || RW_PASSION_NONE : RW_PASSION_NONE)

/datum/psychology/proc/build_skill_level_ui_data()
	var/list/data = list()
	var/datum/component/rw_skills/skill_comp = get_skill_component()
	if(!skill_comp)
		return data
	for(var/skill_id in skill_comp.all_skills)
		data[skill_id] = skill_comp.get_skill(skill_id)
	return data

/datum/psychology/proc/build_skill_ui_data()
	var/list/data = list()
	var/datum/component/rw_skills/skill_comp = get_skill_component()
	if(!skill_comp)
		return data
	var/list/ordered = list()
	for(var/skill_id in skill_comp.all_skills)
		var/datum/rw_skill/skill = skill_comp.all_skills[skill_id]
		if(skill)
			ordered += list(list("id" = skill_id, "sortOrder" = skill.sort_order))
	sortTim(ordered, /proc/cmp_rw_skill_ui_order)
	for(var/list/entry in ordered)
		var/list/skill_data = rw_get_skill_data(owner, entry["id"])
		if(skill_data)
			data += list(skill_data)
	return data
