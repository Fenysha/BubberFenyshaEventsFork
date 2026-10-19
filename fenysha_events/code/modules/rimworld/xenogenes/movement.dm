/datum/rw_xenogene/movement/slow_runner
	id = RW_XENOGENE_SLOW_RUNNER
	name = "Slow runner"
	desc = "Moves more slowly."
	complexity = 1
	metabolic_efficiency = 1
	negative = TRUE
	physiology_additive = list("movespeed_slowdown" = 0.7)
	incompatibility_group = RW_XENOGENE_GROUP_MOVE_SPEED
	ui_icon = RW_XENOGENE_ICONS
	icon_state = "slow_runner"

/datum/rw_xenogene/movement/fast_runner
	id = RW_XENOGENE_FAST_RUNNER
	name = "Fast runner"
	desc = "Moves faster."
	complexity = 1
	metabolic_efficiency = -1
	physiology_additive = list("movespeed_slowdown" = -0.25)
	incompatibility_group = RW_XENOGENE_GROUP_MOVE_SPEED
	ui_icon = RW_XENOGENE_ICONS
	icon_state = "fast_runner"

/datum/rw_xenogene/movement/very_fast_runner
	id = RW_XENOGENE_VERY_FAST_RUNNER
	name = "Very fast runner"
	desc = "Moves much faster."
	complexity = 2
	metabolic_efficiency = -2
	physiology_additive = list("movespeed_slowdown" = -0.45)
	incompatibility_group = RW_XENOGENE_GROUP_MOVE_SPEED
	ui_icon = RW_XENOGENE_ICONS
	icon_state = "very_fast_runner"

/datum/rw_xenogene/movement/naked_speed
	id = RW_XENOGENE_NAKED_SPEED
	name = "Naked speed"
	desc = "Moves faster when wearing little or no clothing."
	complexity = 1
	metabolic_efficiency = 0
	xenogen_flags = RW_XENOGEN_PROCESSING
	var/naked_movespeed = -0.4
	var/naked_speed_active = FALSE
	ui_icon = RW_XENOGENE_ICONS
	icon_state = "naked_speed"

/datum/rw_xenogene/movement/naked_speed/proc/wearing_little(mob/living/carbon/pawn)
	var/worn = 0
	for(var/slot in list(ITEM_SLOT_OCLOTHING, ITEM_SLOT_ICLOTHING, ITEM_SLOT_GLOVES, ITEM_SLOT_FEET, ITEM_SLOT_HEAD))
		if(pawn.get_item_by_slot(slot))
			worn++
	return worn <= 1

/datum/rw_xenogene/movement/naked_speed/on_life(seconds_per_tick, mob/living/new_holder)
	if(!iscarbon(new_holder))
		return
	var/mob/living/carbon/pawn = new_holder
	var/active = wearing_little(pawn)
	if(active == naked_speed_active)
		return
	naked_speed_active = active
	if(active)
		pawn.set_physiology_additive("movespeed_slowdown", "[get_physiology_source()]_naked", naked_movespeed)
	else
		pawn.remove_physiology_additive("movespeed_slowdown", "[get_physiology_source()]_naked")

/datum/rw_xenogene/movement/naked_speed/clear_gameplay(mob/living/target)
	if(iscarbon(target))
		var/mob/living/carbon/pawn = target
		pawn.remove_physiology_additive("movespeed_slowdown", "[get_physiology_source()]_naked")
	naked_speed_active = FALSE
	return ..()
