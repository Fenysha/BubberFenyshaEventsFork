/datum/rw_xenogene/hemogen/hemogenic
	id = RW_XENOGENE_HEMOGENIC
	name = "Hemogenic"
	desc = "Produces and stores hemogen. Required for other hemogen genes."
	complexity = 1
	metabolic_efficiency = 0
	xenogen_flags = RW_XENOGEN_PROCESSING
	var/hemogen_regen = 0.002
	incompatibility_group = RW_XENOGENE_GROUP_HEMOGEN_BASE
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "hemogenic"

/datum/rw_xenogene/hemogen/bloodfeeder
	id = RW_XENOGENE_BLOODFEEDER
	name = "Bloodfeeder"
	desc = "Retractable fangs extract hemogen from warm blood."
	complexity = 1
	metabolic_efficiency = 0
	ability_path = /datum/action/cooldown/rw_xenogene/bloodfeed
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "bloodfeeder"

/datum/rw_xenogene/hemogen/coagulate
	id = RW_XENOGENE_COAGULATE
	name = "Coagulate"
	desc = "Spend hemogen to instantly stop bleeding on self or others."
	complexity = 1
	metabolic_efficiency = 0
	ability_path = /datum/action/cooldown/rw_xenogene/coagulate
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "coagulate"

/datum/rw_xenogene/hemogen/deathrest
	id = RW_XENOGENE_DEATHREST
	name = "Deathrest"
	desc = "Periodic deathrest needed. Gains powerful bonuses while deathresting."
	complexity = 1
	metabolic_efficiency = 0
	xenogen_flags = RW_XENOGEN_PROCESSING
	var/last_deathrest = 0
	ability_path = /datum/action/cooldown/rw_xenogene/deathrest
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "deathrest"

/datum/rw_xenogene/hemogen/longjump_legs
	id = RW_XENOGENE_LONGJUMP_LEGS
	name = "Longjump legs"
	desc = "Spend hemogen to leap a long distance."
	complexity = 1
	metabolic_efficiency = 0
	ability_path = /datum/action/cooldown/rw_xenogene/longjump
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "longjump_legs"

/datum/rw_xenogene/hemogen/piercing_spine
	id = RW_XENOGENE_PIERCING_SPINE
	name = "Piercing spine"
	desc = "Spend hemogen to fire a deadly spine projectile."
	complexity = 1
	metabolic_efficiency = 0
	ability_path = /datum/action/cooldown/rw_xenogene/piercing_spine
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "piercing_spine"

/datum/rw_xenogene/hemogen/hemogen_drain
	id = RW_XENOGENE_HEMOGEN_DRAIN
	name = "Hemogen drain"
	desc = "Passively drains hemogen from nearby hemogenic pawns."
	complexity = 1
	metabolic_efficiency = 0
	negative = TRUE
	xenogen_flags = RW_XENOGEN_PROCESSING
	var/hemogen_drain_range = 4
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "hemogen_drain"

/mob/living/carbon
	var/rw_hemogen = 0

/mob/living/carbon/proc/rw_spend_hemogen(amount)
	if(rw_hemogen < amount)
		return FALSE
	rw_hemogen -= amount
	return TRUE

// --- Hemogenic: passive regen ------------------------------------------------
/datum/rw_xenogene/hemogen/hemogenic/apply_gameplay(mob/living/target)
	. = ..()
	if(iscarbon(target))
		var/mob/living/carbon/pawn = target
		if(pawn.rw_hemogen <= 0)
			pawn.rw_hemogen = 0.5

/datum/rw_xenogene/hemogen/hemogenic/clear_gameplay(mob/living/target)
	target?.get_psychology()?.clear_factor("xenogene_hemogen")
	return ..()

/datum/rw_xenogene/hemogen/hemogenic/on_life(seconds_per_tick, mob/living/new_holder)
	if(!iscarbon(new_holder))
		return
	var/mob/living/carbon/pawn = new_holder
	pawn.rw_hemogen = min(1, pawn.rw_hemogen + hemogen_regen * seconds_per_tick)
	var/datum/psychology/psy = pawn.get_psychology()
	if(pawn.rw_hemogen <= 0.05)
		psy?.add_factor("xenogene_hemogen", id, -8, "Hemogen depleted.")
	else
		psy?.clear_factor("xenogene_hemogen")

// --- Hemogen drain -----------------------------------------------------------
/datum/rw_xenogene/hemogen/hemogen_drain/on_life(seconds_per_tick, mob/living/new_holder)
	if(!iscarbon(new_holder))
		return
	var/mob/living/carbon/drainer = new_holder
	for(var/mob/living/carbon/other in oview(hemogen_drain_range, drainer))
		if(!other.dna?.has_rw_xenogene(RW_XENOGENE_HEMOGENIC) || other.rw_hemogen <= 0)
			continue
		var/stolen = min(0.015 * seconds_per_tick, other.rw_hemogen)
		other.rw_hemogen -= stolen
		drainer.rw_hemogen = min(1, drainer.rw_hemogen + stolen)

// --- Deathrest ---------------------------------------------------------------
/datum/rw_xenogene/hemogen/deathrest/apply_gameplay(mob/living/target)
	. = ..()
	last_deathrest = world.time

/datum/rw_xenogene/hemogen/deathrest/clear_gameplay(mob/living/target)
	target?.get_psychology()?.clear_factor("xenogene_deathrest")
	return ..()

/// Called by the deathrest action.
/datum/rw_xenogene/hemogen/deathrest/proc/mark_deathrested()
	last_deathrest = world.time

/datum/rw_xenogene/hemogen/deathrest/on_life(seconds_per_tick, mob/living/new_holder)
	var/datum/psychology/psy = new_holder.get_psychology()
	if(!last_deathrest)
		last_deathrest = world.time
	if(world.time - last_deathrest > 12 MINUTES)
		psy?.add_factor("xenogene_deathrest", id, -10, "Needs deathrest.")
	else
		psy?.clear_factor("xenogene_deathrest")
