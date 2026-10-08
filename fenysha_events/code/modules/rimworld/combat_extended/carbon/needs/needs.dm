#ifndef OLD_COMBAT_SYSTEM
/mob/living/carbon
	/// RimWorld hunger value, drained independently of vanilla nutrition.
	var/rw_hunger = PSY_NEED_MAX
	/// Nutrition snapshot used to recognize when the carbon mob has eaten.
	var/rw_last_nutrition
	/// Time spent at zero RimWorld hunger before starvation becomes an injury.
	var/rw_starvation_time = 0

/**
 * Custom psychology hunger. A nutrition increase represents eating and restores
 * the need; ordinary metabolism/movement drain does not accelerate this meter.
 */
/mob/living/carbon/proc/process_rw_hunger(seconds_per_tick, datum/psychology/psy)
	if(!psy)
		return

	if(isnull(rw_last_nutrition))
		rw_last_nutrition = nutrition
	else
		if(nutrition > rw_last_nutrition)
			rw_hunger = PSY_NEED_MAX
		rw_last_nutrition = nutrition

	if(HAS_TRAIT(src, TRAIT_NOHUNGER))
		rw_hunger = PSY_NEED_MAX
		rw_starvation_time = 0
		clear_starvation_injury()
	else
		var/hunger_rate_multiplier = 1
		if(ishuman(src))
			var/mob/living/carbon/human/human_holder = src
			var/metabolic_efficiency = human_holder.dna?.get_rw_metabolic_efficiency() || 0
			// RimWorld genes adjust food need by 10% per metabolic point.
			hunger_rate_multiplier = clamp(1 - metabolic_efficiency * 0.1, 0.1, 3)
		rw_hunger = max(rw_hunger - (100 / (30 MINUTES / 10)) * hunger_rate_multiplier * seconds_per_tick, PSY_NEED_MIN)
		if(rw_hunger <= PSY_NEED_MIN)
			rw_starvation_time += seconds_per_tick
			if(rw_starvation_time >= 5 MINUTES / 10)
				apply_starvation_injury()
		else
			rw_starvation_time = 0
			if(rw_hunger >= PSY_NEED_LOW)
				clear_starvation_injury()

	var/datum/psychology_need/hunger/hunger_need = psy.get_need(PSY_NEED_HUNGER)
	hunger_need?.set_value(rw_hunger)
	update_psychology_injury_factor(psy)

/mob/living/carbon/proc/apply_starvation_injury()
	var/obj/item/bodypart/chest = get_bodypart(BODY_ZONE_CHEST)
	if(!chest || chest.find_injury_series("malnutrition"))
		return
	var/datum/injury/malnutrition/injury = new
	injury.apply_to_limb(chest, silent = TRUE, source = "starvation")

/mob/living/carbon/proc/clear_starvation_injury()
	for(var/datum/injury/malnutrition/injury as anything in all_injuries?.Copy())
		injury.remove_from_limb()
		qdel(injury)

/mob/living/carbon/proc/update_psychology_injury_factor(datum/psychology/psy)
	if(!psy)
		return
	var/penalty = 0
	for(var/datum/injury/injury as anything in all_injuries)
		if(injury.severity < INJURY_SEVERITY_SEVERE)
			continue
		penalty -= injury.severity >= INJURY_SEVERITY_CRITICAL ? 6 : 3
		penalty = max(penalty, -12)
		if(penalty <= -12)
			break

	var/datum/psychology_factor/current = psy.get_factor(PSY_CATEGORY_INJURY)
	if(penalty)
		if(!current || current.mood_change != penalty)
			psy.add_factor(PSY_CATEGORY_INJURY, "serious_injuries", penalty, "Pain and distress from serious injuries.")
	else if(current)
		psy.clear_factor(PSY_CATEGORY_INJURY)
#endif
