/datum/injury/hemothorax
	name = "Hemothorax"
	undiagnosed_name = "blood-filled chest"
	desc = "Blood filling the pleural space and the lungs. Compromises breathing and circulating volume."
	examine_desc = "has a chest full of blood"
	series = "hemothorax"
	upgrade_path = null
	severity = INJURY_SEVERITY_CRITICAL
	visibility = INJURY_VISIBILITY_MEDICAL

	injury_flags = INJURY_FLAG_INTERNAL | INJURY_FLAG_BLEEDING | INJURY_FLAG_PAINFUL | INJURY_FLAG_PROGRESSING

	bleed_rate = 0.9
	pain_amount = 22
	processes = TRUE

	base_healing_rate = 0.004
	base_treat_time = 8 SECONDS

	treatable_by = list(
		/obj/item/stack/medical/medicine/medkit/indusrtial = INJURY_TREATMENT_EFFECTIVENESS_ADEQUATE,
		/obj/item/chest_drain = INJURY_TREATMENT_EFFECTIVENESS_EXCELLENT,
	)

	var/fluid_per_bleed = 0.35
	var/ventilation_penalty = 0.15

/datum/injury/hemothorax/can_apply_to(obj/item/bodypart/target_limb)
	return target_limb.body_zone == BODY_ZONE_CHEST

/datum/injury/hemothorax/resolve_treatment_quality(obj/item/tool, mob/user)
	if(istype(tool, /obj/item/chest_drain))
		return INJURY_TREATMENT_EXCELLENT
	return INJURY_TREATMENT_POOR

/datum/injury/hemothorax/occur_text()
	return "starts filling with blood"

/datum/injury/hemothorax/register_effects()
	. = ..()
	update_lung_effects()

/datum/injury/hemothorax/on_treated(quality, mob/user)
	. = ..()
	update_lung_effects()

/datum/injury/hemothorax/proc/update_lung_effects()
	set_lung_modifier(1 - scale_by_treatment(ventilation_penalty))

/datum/injury/hemothorax/process_effects(seconds_per_tick)
	update_lung_effects()

	var/obj/item/organ/lungs/lungs = owner.get_organ_slot(ORGAN_SLOT_LUNGS)
	if(!lungs)
		return

	var/rate = get_bleed_rate()
	if(rate > 0)
		lungs.add_fluid(rate * fluid_per_bleed * seconds_per_tick, TRUE)

	if(treatment_quality > INJURY_TREATMENT_NONE)
		lungs.add_fluid(-treatment_quality * 0.2 * seconds_per_tick)

/datum/injury/hemothorax/get_visible_signs(mob/user)
	if(!owner || treatment_quality >= INJURY_TREATMENT_ADEQUATE)
		return null
	var/obj/item/organ/lungs/lungs = owner.get_organ_slot(ORGAN_SLOT_LUNGS)
	if(!lungs || lungs.get_blood_fluid() < 20)
		return null
	return span_userdanger("Bloody foam bubbles at [owner.p_their()] lips with every wet, rattling breath.")
