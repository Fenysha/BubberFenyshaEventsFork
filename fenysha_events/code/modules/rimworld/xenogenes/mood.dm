/datum/rw_xenogene/mood/very_unhappy
	id = RW_XENOGENE_VERY_UNHAPPY
	name = "Very unhappy"
	desc = "Baseline mood greatly reduced."
	complexity = 1
	metabolic_efficiency = 2
	negative = TRUE
	mood_offset = -12
	incompatibility_group = RW_XENOGENE_GROUP_MOOD
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "very_unhappy"

/datum/rw_xenogene/mood/unhappy
	id = RW_XENOGENE_UNHAPPY
	name = "Unhappy"
	desc = "Baseline mood reduced."
	complexity = 1
	metabolic_efficiency = 1
	negative = TRUE
	mood_offset = -6
	incompatibility_group = RW_XENOGENE_GROUP_MOOD
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "unhappy"

/datum/rw_xenogene/mood/happy
	id = RW_XENOGENE_HAPPY
	name = "Happy"
	desc = "Baseline mood increased."
	complexity = 1
	metabolic_efficiency = -1
	mood_offset = 6
	incompatibility_group = RW_XENOGENE_GROUP_MOOD
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "happy"

/datum/rw_xenogene/mood/very_happy
	id = RW_XENOGENE_VERY_HAPPY
	name = "Very happy"
	desc = "Baseline mood greatly increased."
	complexity = 2
	metabolic_efficiency = -2
	mood_offset = 12
	incompatibility_group = RW_XENOGENE_GROUP_MOOD
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "very_happy"

/datum/rw_xenogene/mood/apply_gameplay(mob/living/target)
	. = ..()
	if(!mood_offset || !iscarbon(target))
		return
	var/mob/living/carbon/pawn = target
	var/datum/psychology/psy = (pawn.mind || pawn.client) ? pawn.ensure_psychology() : pawn.get_psychology()
	psy?.add_factor("xenogene_[id]", id, mood_offset, name, permanent = TRUE)

/datum/rw_xenogene/mood/clear_gameplay(mob/living/target)
	target?.get_psychology()?.clear_factor("xenogene_[id]")
	return ..()
