/datum/rw_xenogene/psychic/psychically_deaf
	id = RW_XENOGENE_PSYCHICALLY_DEAF
	name = "Psychically deaf"
	desc = "Completely immune to psychic effects, positive and negative."
	complexity = 1
	metabolic_efficiency = 1
	negative = TRUE
	psychic_sensitivity = 0
	incompatibility_group = RW_XENOGENE_GROUP_PSYCHIC_SENSITIVITY
	ui_icon = RW_XENOGENE_ICONS
	icon_state = "psychically_dull"

/datum/rw_xenogene/psychic/psychically_dull
	id = RW_XENOGENE_PSYCHICALLY_DULL
	name = "Psychically dull"
	desc = "Reduced psychic sensitivity."
	complexity = 1
	metabolic_efficiency = 0
	psychic_sensitivity = 0.5
	incompatibility_group = RW_XENOGENE_GROUP_PSYCHIC_SENSITIVITY
	ui_icon = RW_XENOGENE_ICONS
	icon_state = "psychically_dull"

/datum/rw_xenogene/psychic/psy_sensitive
	id = RW_XENOGENE_PSY_SENSITIVE
	name = "Psy-sensitive"
	desc = "Increased psychic sensitivity."
	complexity = 1
	metabolic_efficiency = -1
	psychic_sensitivity = 1.5
	incompatibility_group = RW_XENOGENE_GROUP_PSYCHIC_SENSITIVITY
	ui_icon = RW_XENOGENE_ICONS
	icon_state = "psy_sensitive"

/datum/rw_xenogene/psychic/super_psy_sensitive
	id = RW_XENOGENE_SUPER_PSY_SENSITIVE
	name = "Super psy-sensitive"
	desc = "Greatly increased psychic sensitivity."
	complexity = 2
	metabolic_efficiency = -2
	psychic_sensitivity = 2
	incompatibility_group = RW_XENOGENE_GROUP_PSYCHIC_SENSITIVITY
	ui_icon = RW_XENOGENE_ICONS
	icon_state = "super_psy_sensitive"

/datum/rw_xenogene/psychic/psychic_bonding
	id = RW_XENOGENE_PSYCHIC_BONDING
	name = "Psychic bonding"
	desc = "Bonds with the first person who stands beside you. Their closeness lifts your mood; distance drags it down. Psychic deafness blocks the feeling."
	complexity = 2
	metabolic_efficiency = 0
	xenogen_flags = RW_XENOGEN_PROCESSING
	var/mob/living/psychic_bond
	ui_icon = RW_XENOGENE_ICONS
	icon_state = "psychic_bonding"

/// Product of every sensitivity gene; 1 when none is present.
/datum/dna/proc/get_rw_psychic_sensitivity()
	var/result = 1
	for(var/datum/rw_xenogene/psychic/gene in rw_each_gene())
		if(!isnull(gene.psychic_sensitivity))
			result *= gene.psychic_sensitivity
	return result

/datum/rw_xenogene/psychic/psychic_bonding/clear_gameplay(mob/living/target)
	psychic_bond = null
	target?.get_psychology()?.clear_factor("xenogene_bond")
	return ..()

/datum/rw_xenogene/psychic/psychic_bonding/on_life(seconds_per_tick, mob/living/new_holder)
	var/datum/psychology/psy = new_holder.get_psychology()
	var/sensitivity = 1
	if(ishuman(new_holder))
		var/mob/living/carbon/human/H = new_holder
		sensitivity = H.dna?.get_rw_psychic_sensitivity() || 1
	if(isnull(sensitivity))
		sensitivity = 1
	if(sensitivity <= 0)
		psy?.clear_factor("xenogene_bond")
		return
	if(!psychic_bond || QDELETED(psychic_bond) || psychic_bond.stat == DEAD)
		psychic_bond = null
		for(var/mob/living/carbon/human/near in oview(1, new_holder))
			if(near.stat == DEAD)
				continue
			psychic_bond = near
			to_chat(new_holder, span_notice("A psychic bond snaps into place with [near]."))
			break
	if(!psychic_bond)
		psy?.clear_factor("xenogene_bond")
	else if(get_dist(new_holder, psychic_bond) <= 8)
		psy?.add_factor("xenogene_bond", id, round(8 * sensitivity), "Psychic bond is close.")
	else
		psy?.add_factor("xenogene_bond", id, round(-6 * sensitivity), "Psychic bond is far away.")
