/datum/injury/stump
	name = "severed limb stump"
	undiagnosed_name = "traumatic amputation"
	desc = "An open, bleeding stump where a limb used to be."
	examine_desc = "has a ragged, bleeding stump"
	visibility = INJURY_VISIBILITY_FULL

	severity = INJURY_SEVERITY_CRITICAL
	series = "stump" // will be specialized per zone in New/apply

	upgrade_path = null // terminal

	bleed_rate = 1.05
	pain_amount = 55
	initial_shock = 45
	initial_consciousness_impact = 28
	damage_multiplier = 1.0
	dismemberment_weight = 0

	interaction_penalty = 1.0
	limp_slowdown = 0
	limp_chance = 0
	disabling = FALSE

	injury_flags = INJURY_FLAG_EXTERNAL | INJURY_FLAG_BLEEDING | INJURY_FLAG_PAINFUL | INJURY_FLAG_ACCEPTS_GAUZE | INJURY_FLAG_ACCEPTS_SUTURE

	processes = TRUE
	base_healing_rate = 0 // never self-heals; requires surgery / advanced treatment
	treated_bleed_mult = 0.25
	treated_heal_mult = 0.4
	treated_pain_mult = 0.55

	/// Body zone that was lost (BODY_ZONE_L_ARM etc.). Used for series uniqueness and messaging.
	var/lost_zone

/datum/injury/stump/New()
	. = ..()
	if(lost_zone)
		series = "stump_[lost_zone]"
		name = "[parse_zone(lost_zone)] stump"
		examine_desc = "has a ragged stump where the [parse_zone(lost_zone)] should be"

/datum/injury/stump/apply_to_limb(obj/item/bodypart/target_limb, silent = FALSE, attack_direction = null, source = "Unknown")
	if(lost_zone)
		series = "stump_[lost_zone]"
		name = "[parse_zone(lost_zone)] stump"
		examine_desc = "has a ragged stump where the [parse_zone(lost_zone)] should be"
	return ..()

/datum/injury/stump/can_apply_to(obj/item/bodypart/target_limb)
	// Only the torso carries stump injuries for lost extremities.
	return target_limb && target_limb.body_zone == BODY_ZONE_CHEST

/datum/injury/stump/get_initial_shock()
	if(initial_shock > 0)
		return initial_shock
	return ..()

/datum/injury/stump/get_initial_consciousness_impact()
	if(initial_consciousness_impact > 0)
		return initial_consciousness_impact
	return ..()

/datum/injury/stump/handle_process(seconds_per_tick)
	if(!owner || owner.stat == DEAD)
		return

	// Untreated stumps keep bleeding and can slowly worsen pain.
	if(treatment_quality == INJURY_TREATMENT_NONE && bleed_rate > 0.4)
		// Mild progression of untreated arterial spray
		bleed_rate = min(bleed_rate + 0.015 * seconds_per_tick, 2.2)

	if(get_bleed_rate() > 0.7 && SPT_PROB(12, seconds_per_tick))
		owner.visible_message(
			span_danger("Blood sprays from [owner]'s [name]!"),
			span_userdanger("Blood sprays from your [name]!")
		)
		playsound(owner, INJURY_SOUND_BLOOD, 50, TRUE)

/datum/injury/stump/get_visible_signs(mob/user)
	if(visibility < INJURY_VISIBILITY_FULL)
		return null
	return span_warning("[owner.p_They()] [examine_desc]!")
