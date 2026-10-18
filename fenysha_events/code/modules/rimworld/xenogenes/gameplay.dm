/**
 * Generic gameplay hooks shared by every xenogene: engine traits, a granted action, skill bonuses and
 * physiology layers. Anything with its own state or tick logic lives on the subtype that owns it
 * (hemogen.dm, psychic.dm, mood.dm, aptitude.dm, archite.dm, ...).
 *
 * physiology_* are stat var name -> value maps. They are registered on the holder's /datum/physiology
 * under the "xenogene_[id]" source on gain and dropped again on loss. Humans only.
 */
/datum/rw_xenogene
	/// Multipliers, e.g. list("pain_mod" = 1.5). 0 is allowed (shock_mod = 0: shock never builds).
	var/list/physiology_multipliers
	/// Caps, the smallest one wins. e.g. list("pain_limit" = 80)
	var/list/physiology_limits
	/// Summed values, e.g. list("cold_limit_mod" = -40, "movespeed_slowdown" = -0.25)
	var/list/physiology_additive
	/// Engine traits added with this gene as the source.
	var/list/gameplay_traits
	/// Action granted for the duration of the gene.
	var/ability_path
	var/datum/action/granted_ability
	/// TRUE once this gene's skill_bonuses are inside the pawn's skill levels.
	var/skill_bonus_applied = FALSE
	/// Pawn the passive effects were applied to. Cleared even if on_lose is skipped.
	var/mob/living/effect_owner


/datum/rw_xenogene/proc/get_physiology_source()
	return "xenogene_[id]"

/datum/rw_xenogene/proc/apply_gameplay(mob/living/target)
	SHOULD_CALL_PARENT(TRUE)
	if(!target)
		return
	effect_owner = target
	for(var/trait in gameplay_traits)
		ADD_TRAIT(target, trait, REF(src))
	if(ability_path && !granted_ability)
		granted_ability = new ability_path
		granted_ability.Grant(target)
	if(length(skill_bonuses))
		var/datum/psychology/skill_psy = target.get_psychology()
		if(skill_psy?.persona_loaded && !skill_bonus_applied)
			adjust_skill_bonuses(target, 1)
			skill_bonus_applied = TRUE
	apply_physiology(target)

/datum/rw_xenogene/proc/clear_gameplay(mob/living/target)
	SHOULD_CALL_PARENT(TRUE)
	QDEL_NULL(granted_ability)
	if(target && !QDELETED(target))
		for(var/trait in gameplay_traits)
			REMOVE_TRAIT(target, trait, REF(src))
		clear_physiology(target)
		if(skill_bonus_applied)
			adjust_skill_bonuses(target, -1)
			skill_bonus_applied = FALSE
	if(effect_owner == target)
		effect_owner = null

/datum/rw_xenogene/proc/apply_physiology(mob/living/target)
	if(!iscarbon(target) || !(length(physiology_multipliers) || length(physiology_limits) || length(physiology_additive)))
		return
	var/mob/living/carbon/carbon_target = target
	var/source = get_physiology_source()
	for(var/stat in physiology_multipliers)
		carbon_target.set_physiology_multiplier(stat, source, physiology_multipliers[stat])
	for(var/stat in physiology_limits)
		carbon_target.set_physiology_limit(stat, source, physiology_limits[stat])
	for(var/stat in physiology_additive)
		carbon_target.set_physiology_additive(stat, source, physiology_additive[stat])

/datum/rw_xenogene/proc/clear_physiology(mob/living/target)
	if(!iscarbon(target))
		return
	var/mob/living/carbon/carbon_target = target
	carbon_target.remove_physiology_source(get_physiology_source())

/datum/rw_xenogene/proc/adjust_skill_bonuses(mob/living/target, direction)
	if(!length(skill_bonuses) || !target)
		return
	var/datum/component/rw_skills/skill_comp = target.GetComponent(/datum/component/rw_skills)
	if(!skill_comp)
		return
	for(var/skill_id in skill_bonuses)
		var/delta = skill_bonuses[skill_id]
		if(!isnum(delta) || !delta)
			continue
		skill_comp.set_skill(skill_id, skill_comp.get_skill(skill_id) + delta * direction)

/// Genes of this holder, skipping empty slots.
/datum/dna/proc/rw_each_gene()
	var/list/genes = list()
	for(var/gene_id in rw_xenogenes)
		var/datum/rw_xenogene/gene = rw_xenogenes[gene_id]
		if(gene && !QDELETED(gene))
			genes += gene
	return genes

/datum/dna/proc/rw_prevents_mental_breaks()
	return has_rw_xenogene(RW_XENOGENE_DEAD_CALM)
