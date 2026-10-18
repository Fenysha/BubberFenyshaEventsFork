/datum/rw_xenogene/archite/scarless
	id = RW_XENOGENE_SCARLESS
	name = "Scarless"
	desc = "Special regenerator cells heal old wounds and chronic illnesses. Prevents new scars."
	complexity = 4
	metabolic_efficiency = 0
	physiology_multipliers = list("wound_heal_mod" = 3)
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "scarless"

/datum/rw_xenogene/archite/gene_implanter
	id = RW_XENOGENE_GENE_IMPLANTER
	name = "Gene implanter"
	desc = "Can implant a copy of xenogenes into another person. Genes regrow slowly."
	complexity = 3
	metabolic_efficiency = 0
	ability_path = /datum/action/cooldown/rw_xenogene/gene_implanter
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "gene_implanter"

/datum/rw_xenogene/archite/perfect_immunity
	id = RW_XENOGENE_PERFECT_IMMUNITY
	name = "Perfect immunity"
	desc = "Totally immune to most normal illnesses."
	complexity = 3
	metabolic_efficiency = 0
	physiology_multipliers = list("immunity_mod" = 4)
	gameplay_traits = list(TRAIT_VIRUSIMMUNE)
	incompatibility_group = RW_XENOGENE_GROUP_IMMUNITY
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "perfect_immunity"

/datum/rw_xenogene/archite/non_senescent
	id = RW_XENOGENE_NON_SENESCENT
	name = "Non-senescent"
	desc = "Never get chronic age-related diseases."
	complexity = 3
	metabolic_efficiency = 0
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "non_senescent"

/mob/living/carbon/human/CanContractDisease(datum/disease/disease)
	if(dna && (disease.disease_flags & CHRONIC) && dna.has_rw_xenogene(RW_XENOGENE_NON_SENESCENT))
		return FALSE
	return ..()

/datum/rw_xenogene/archite/ageless
	id = RW_XENOGENE_AGELESS
	name = "Ageless"
	desc = "Aging slows from 13 and stops completely by 18.5."
	complexity = 3
	metabolic_efficiency = 0
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "ageless"

/datum/rw_xenogene/archite/deathless
	id = RW_XENOGENE_DEATHLESS
	name = "Deathless"
	desc = "As long as the brain remains intact, never dies. Enters regenerative coma instead."
	complexity = 7
	metabolic_efficiency = 0
	xenogen_flags = RW_XENOGEN_PROCESSING
	var/deathless_coma = FALSE
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "deathless"

/datum/rw_xenogene/archite/archite_metabolism
	id = RW_XENOGENE_ARCHITE_METABOLISM
	name = "Archite metabolism"
	desc = "Archites optimize metabolism. +6 metabolic efficiency."
	complexity = 6
	metabolic_efficiency = 6
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "archite_metabolism"

/datum/rw_xenogene/archite/breathless
	id = RW_XENOGENE_BREATHLESS
	name = "Breathless"
	desc = "Rarely need to breathe. Immune to vacuum, tox gas, acidic smog, rot stink."
	complexity = 3
	metabolic_efficiency = 0
	physiology_multipliers = list("tox_taken_mod" = 0)
	gameplay_traits = list(TRAIT_NOBREATH, TRAIT_TOXIMMUNE, TRAIT_RESISTLOWPRESSURE)
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "breathless"

/datum/scar/generate(obj/item/bodypart/BP, datum/wound/W, add_to_scars = TRUE)
	if(ishuman(BP?.owner))
		var/mob/living/carbon/human/scar_host = BP.owner
		if(scar_host.dna?.has_rw_xenogene(RW_XENOGENE_SCARLESS))
			qdel(src)
			return
	return ..()

/datum/rw_xenogene/archite/ageless/apply_gameplay(mob/living/target)
	. = ..()
	if(ishuman(target))
		var/mob/living/carbon/human/human_target = target
		if(human_target.age > 18)
			human_target.age = 18

/datum/rw_xenogene/archite/deathless/apply_gameplay(mob/living/target)
	. = ..()
	RegisterSignal(target, COMSIG_LIVING_DEATH, PROC_REF(on_deathless))

/datum/rw_xenogene/archite/deathless/clear_gameplay(mob/living/target)
	if(target)
		UnregisterSignal(target, COMSIG_LIVING_DEATH)
	deathless_coma = FALSE
	return ..()

/datum/rw_xenogene/archite/deathless/proc/on_deathless(mob/living/source, gibbed)
	SIGNAL_HANDLER
	if(gibbed || deathless_coma)
		return
	var/obj/item/organ/brain/brain = source.get_organ_slot(ORGAN_SLOT_BRAIN)
	if(!brain || (brain.organ_flags & ORGAN_FAILING))
		return
	deathless_coma = TRUE
	addtimer(CALLBACK(src, PROC_REF(begin_deathless_coma), source), 1)

/datum/rw_xenogene/archite/deathless/proc/begin_deathless_coma(mob/living/source)
	if(QDELETED(src) || source != holder || QDELETED(source))
		deathless_coma = FALSE
		return
	source.revive(NONE, 0, TRUE)
	source.Unconscious(90 SECONDS)
	to_chat(source, span_notice("Deathless archites drag you back from death. You are locked in a regenerative coma."))

/datum/rw_xenogene/archite/deathless/on_life(seconds_per_tick, mob/living/new_holder)
	if(!deathless_coma || !iscarbon(new_holder))
		return
	new_holder.adjust_brute_loss(-1.5 * seconds_per_tick, forced = TRUE)
	new_holder.adjust_fire_loss(-1.5 * seconds_per_tick, forced = TRUE)
	if(new_holder.stat == STABLE && !IS_UNCONSCIOUS(new_holder))
		deathless_coma = FALSE
		to_chat(new_holder, span_notice("The regenerative coma lifts."))
