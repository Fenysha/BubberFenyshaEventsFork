/datum/injury/dislocation
	name = "Dislocation"
	undiagnosed_name = "dislocated joint"
	desc = "The joint has been forced out of its socket."
	examine_desc = "is dislocated"
	series = "dislocation"
	upgrade_path = null
	severity = INJURY_SEVERITY_SEVERE

	injury_flags = INJURY_FLAG_INTERNAL | INJURY_FLAG_PAINFUL | INJURY_FLAG_DISABLING | INJURY_FLAG_ACCEPTS_SPLINT

	pain_amount = 25
	disabling = TRUE
	interaction_penalty = 2.5
	limp_slowdown = 4
	limp_chance = 80

	// A dislocation never fixes itself. Once the joint is reduced, recovery is quick.
	base_healing_rate = 0.02
	base_treat_time = 6 SECONDS
	treatable_by = list(
		/obj/item/stack/medical/medicine/medkit/crude = INJURY_TREATMENT_EFFECTIVENESS_POOR,
		/obj/item/stack/medical/medicine/medkit/indusrtial = INJURY_TREATMENT_EFFECTIVENESS_NORMAL,
	)
	treatable_tools = list(TOOL_BONESET)

/datum/injury/dislocation/can_apply_to(obj/item/bodypart/target_limb)
	return target_limb.body_zone in list(BODY_ZONE_L_ARM, BODY_ZONE_R_ARM, BODY_ZONE_L_LEG, BODY_ZONE_R_LEG)

/datum/injury/dislocation/resolve_treatment_quality(obj/item/tool, mob/user)
	// Only a proper reduction fixes the joint; a splint just immobilises it.
	if(tool.tool_behaviour == TOOL_BONESET)
		return INJURY_TREATMENT_EXCELLENT
	return INJURY_TREATMENT_POOR

/datum/injury/dislocation/occur_text()
	return "is wrenched out of its socket"

/datum/injury/dislocation/on_applied_effects(attack_direction)
	play_effect_sound(INJURY_SOUND_BONE_CRACK, 70)
	if(prob(70))
		owner.emote("scream")

/datum/injury/dislocation/get_visible_signs(mob/user)
	if(!owner || !limb || treatment_quality >= INJURY_TREATMENT_ADEQUATE)
		return null
	return span_danger("[owner.p_Their()] [limb.plaintext_zone] hangs at an unnatural angle.")
