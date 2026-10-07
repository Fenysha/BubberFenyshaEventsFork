#ifndef OLD_COMBAT_SYSTEM
// Takes care blood loss and regeneration
/mob/living/carbon/human/handle_blood(seconds_per_tick)
	// Under these circumstances blood handling is not necessary
	if(bodytemperature < BLOOD_STOP_TEMP || HAS_TRAIT(src, TRAIT_FAKEDEATH))
		return

	// Run the signal, still allowing mobs with noblood to "handle blood" in their own way
	var/sigreturn = SEND_SIGNAL(src, COMSIG_HUMAN_ON_HANDLE_BLOOD, seconds_per_tick)
	if((sigreturn & HANDLE_BLOOD_HANDLED) || !CAN_HAVE_BLOOD(src))
		return

	var/heart_blood_multiplier = get_heart_blood_regeneration_multiplier()
	//Blood regeneration if there is some space
	if(heart_blood_multiplier && !(sigreturn & HANDLE_BLOOD_NO_NUTRITION_DRAIN) && get_blood_volume() < BLOOD_VOLUME_NORMAL && !HAS_TRAIT(src, TRAIT_NOHUNGER))
		var/nutrition_ratio = round(nutrition / NUTRITION_LEVEL_WELL_FED, 0.2)

		if(satiety > 80)
			nutrition_ratio *= 1.25

		var/blood_to_restore = BLOOD_REGEN_FACTOR * physiology.blood_regen_mod * heart_blood_multiplier * nutrition_ratio * seconds_per_tick
		var/blood_restored = adjust_blood_volume(blood_to_restore, maximum = BLOOD_VOLUME_NORMAL)
		if (blood_restored > 0)
			adjust_nutrition(-nutrition_ratio * HUNGER_FACTOR * seconds_per_tick * (blood_restored / blood_to_restore))

	var/bleed_rate = get_bleed_rate()

	if(bleed_rate)
		bleed(bleed_rate * seconds_per_tick)


	for (var/obj/item/bodypart/bodypart as anything in get_bodyparts())
		if (bodypart.generic_bleedstacks)
			bodypart.adjustBleedStacks(-1, 0)
#endif
