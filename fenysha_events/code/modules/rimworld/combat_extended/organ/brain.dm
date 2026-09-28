/obj/item/organ/brain
	/// Abstract cerebral oxygenation state, 0..BRAIN_O2_MAX.
	/// This is not blood SpO2; it represents oxygen available to brain tissue.
	var/oxygen = BRAIN_O2_MAX

/**
 * Updates cerebral oxygen delivery from blood perfusion and blood oxygenation.
 * Called from carbon Life after the final blood-pressure/hemorrhage pass so
 * the same tick's blood loss can immediately affect cerebral perfusion.
 */
/obj/item/organ/brain/proc/process_cerebral_oxygenation(seconds_per_tick)
	if(!owner || owner.stat == DEAD || HAS_TRAIT(owner, TRAIT_GODMODE))
		return

	var/perfusion = clamp(owner.get_brain_perfusion(), 0, 1.2)
	var/spo2 = clamp(owner.blood_oxygenation / 100, 0, 1)

	// At perfusion 0.5 and SpO2 100 this equals the configured oxygen
	// consumption, matching BRAIN_O2_SUPPLY_MULT.
	var/oxygen_supply = perfusion * spo2 * BRAIN_O2_SUPPLY_MULT
	var/oxygen_delta = (oxygen_supply - BRAIN_O2_CONSUMPTION) * BRAIN_O2_RATE

	// Recovery is intentionally slower than depletion.
	if(oxygen_delta > 0)
		oxygen_delta *= BRAIN_O2_RECOVERY_MULT

	oxygen = clamp(oxygen + oxygen_delta * seconds_per_tick, 0, BRAIN_O2_MAX)

	// Severe hypoxia starts damaging neurons. The damage reaches the configured
	// maximum at oxygen == 0 and eventually uses the normal brain death path.
	if(oxygen < BRAIN_O2_SEVERE && !HAS_TRAIT(src, TRAIT_BRAIN_DAMAGE_NODEATH))
		var/hypoxia_ratio = 1 - clamp(oxygen / BRAIN_O2_SEVERE, 0, 1)
		var/hypoxic_damage = BRAIN_HYPOXIA_DAMAGE_MAX * hypoxia_ratio * seconds_per_tick
		if(hypoxic_damage > 0)
			apply_organ_damage(hypoxic_damage)

	if(damage >= maxHealth && !HAS_TRAIT(src, TRAIT_BRAIN_DAMAGE_NODEATH))
		to_chat(owner, span_userdanger("The last electrical activity in your brain fades away from prolonged oxygen deprivation..."))
		owner.investigate_log("has been killed by cerebral hypoxia.", INVESTIGATE_DEATHS)
		owner.death()

/obj/item/organ/brain/proc/get_oxygen_ratio()
	return clamp(oxygen / BRAIN_O2_MAX, 0, 1)

/obj/item/organ/brain/on_life(seconds_per_tick)
	. = ..()

	if(HAS_TRAIT(src, TRAIT_BRAIN_DAMAGE_NODEATH))
		return
	if(!owner)
		return
	if(damage >= maxHealth)
		to_chat(owner, span_userdanger("The last spark of life in your brain fizzles out..."))
		owner.investigate_log("has been killed by brain damage.", INVESTIGATE_DEATHS)
		owner.death()
