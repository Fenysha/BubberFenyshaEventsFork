/datum/injury/skull_fracture
	name = "Skull Fracture"
	undiagnosed_name = "cracked skull"
	desc = "A fracture of the cranial bone. High risk of brain injury."
	examine_desc = "has a visibly deformed or cracked skull"
	series = "skull_fracture"
	upgrade_path = /datum/injury/skull_fracture/depressed
	severity = INJURY_SEVERITY_SEVERE

	injury_flags = INJURY_FLAG_INTERNAL | INJURY_FLAG_PAINFUL | INJURY_FLAG_SELF_HEALING

	pain_amount = 32
	damage_multiplier = 1.2

	base_healing_rate = 0.001
	base_treat_time = 8 SECONDS

	treatable_by = list(
		/obj/item/stack/medical/medicine/medkit/crude = INJURY_TREATMENT_EFFECTIVENESS_POOR,
		/obj/item/stack/medical/medicine/bone_gel = INJURY_TREATMENT_EFFECTIVENESS_NORMAL,
		/obj/item/stack/medical/medicine/medkit/indusrtial = INJURY_TREATMENT_EFFECTIVENESS_EXCELLENT,
	)
	treatable_tools = list(TOOL_BONESET)

/datum/injury/skull_fracture/can_apply_to(obj/item/bodypart/target_limb)
	return target_limb.body_zone == BODY_ZONE_HEAD

/datum/injury/skull_fracture/resolve_treatment_quality(obj/item/tool, mob/user)
	if(istype(tool, /obj/item/stack/medical/bone_gel))
		return INJURY_TREATMENT_EXCELLENT
	return INJURY_TREATMENT_ADEQUATE

/datum/injury/skull_fracture/occur_text()
	return "cracks under the impact"


/datum/injury/skull_fracture/on_applied_effects(attack_direction)
	play_effect_sound(INJURY_SOUND_BONE_CRACK, 70)
	hit_spray(attack_direction, 1, 2, TRUE)

/datum/injury/skull_fracture/get_visible_signs(mob/user)
	return get_untreated_sign()

/datum/injury/skull_fracture/depressed
	name = "Depressed Skull Fracture"
	undiagnosed_name = "caved-in skull"
	desc = "Bone fragments driven inward toward the brain. Life-threatening."
	examine_desc = "has a caved-in section of skull"
	upgrade_path = null
	severity = INJURY_SEVERITY_CRITICAL

	injury_flags = INJURY_FLAG_INTERNAL | INJURY_FLAG_PAINFUL

	pain_amount = 45
	disabling = TRUE
	damage_multiplier = 1.35
	processes = TRUE

	base_healing_rate = 0.002
	base_treat_time = 20 SECONDS
	treatable_by = list(
		/obj/item/stack/medical/medicine/medkit/indusrtial = INJURY_TREATMENT_EFFECTIVENESS_POOR,
	)
	treatable_tools = list()

	COOLDOWN_DECLARE(grind_cd)

/datum/injury/skull_fracture/depressed/process_effects(seconds_per_tick)
	if(treatment_quality >= INJURY_TREATMENT_ADEQUATE || !COOLDOWN_FINISHED(src, grind_cd) || !SPT_PROB(8, seconds_per_tick))
		return
	// Bone fragments grind against the brain.
	var/obj/item/organ/brain/brain = owner.get_organ_slot(ORGAN_SLOT_BRAIN)
	brain?.apply_organ_damage(1.5)
	if(effect_message_ready())
		to_chat(owner, span_userdanger("A stabbing pressure grinds inside your skull!"))
	owner.apply_consciousness_impulse(50, src)
	COOLDOWN_START(src, grind_cd, 4 SECONDS)
