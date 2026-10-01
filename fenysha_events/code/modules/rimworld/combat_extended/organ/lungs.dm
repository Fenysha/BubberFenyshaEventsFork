#ifndef OLD_COMBAT_SYSTEM

/obj/item/organ/lungs
	/// Amount of fluid in the lungs, from 0 to LUNG_FLUID_MAX.
	var/fluid = 0
	/// Part of `fluid` that is blood (haemothorax). Never larger than `fluid`.
	var/blood_fluid = 0
	/// Ventilation multipliers from injuries (pneumothorax, flail chest...), keyed by source.
	var/list/ventilation_modifiers


/// Returns ventilation efficiency from 0 to 1.
/// Ventilation is reduced by both organ damage and fluid accumulation.
/obj/item/organ/lungs/proc/get_ventilation()
	if(organ_flags & ORGAN_FAILING)
		return 0
	if(received_pressure_mult <= 0)
		return 0

	var/health_factor = clamp((maxHealth - damage) / maxHealth, 0, 1)
	var/fluid_ratio = clamp(fluid / LUNG_FLUID_MAX, 0, 1)
	var/fluid_factor = 1 - (fluid_ratio ** 1.35)
	if(fluid > LUNG_FLUID_SEVERE)
		fluid_factor *= 0.7

	return health_factor * fluid_factor * get_ventilation_modifier()

/// Returns the effective pressure multiplier for inhalation.
/// A minimum of 5% is preserved so that gas-related effects are never completely disabled.
/obj/item/organ/lungs/proc/get_effective_pressure_mult()
	return received_pressure_mult * max(get_ventilation(), 0.05)


/obj/item/organ/lungs/proc/set_ventilation_modifier(source, multiplier)
	LAZYSET(ventilation_modifiers, source, clamp(multiplier, 0, 1))

/obj/item/organ/lungs/proc/remove_ventilation_modifier(source)
	LAZYREMOVE(ventilation_modifiers, source)

/// Combined multiplier of every injury currently restricting ventilation.
/obj/item/organ/lungs/proc/get_ventilation_modifier()
	. = 1
	for(var/source in ventilation_modifiers)
		. *= ventilation_modifiers[source]

/// Amount of the lung fluid that is blood.
/obj/item/organ/lungs/proc/get_blood_fluid()
	return min(blood_fluid, fluid)

/// Adds (or, when negative, removes) lung fluid. Blood is tracked separately so it can be coughed up.
/obj/item/organ/lungs/proc/add_fluid(amount, is_blood = FALSE)
	var/old_fluid = fluid
	blood_fluid = min(blood_fluid, fluid)
	fluid = clamp(fluid + amount, 0, LUNG_FLUID_MAX)
	if(is_blood && amount > 0)
		blood_fluid += fluid - old_fluid
	else if(amount < 0 && old_fluid > 0)
		// Resorption / drainage takes blood and other fluid out proportionally.
		blood_fluid *= fluid / old_fluid
	blood_fluid = clamp(blood_fluid, 0, fluid)

/// Cough: drags fluid out of the lungs, and if it is blood, sprays it.
/obj/item/organ/lungs/proc/cough_up_fluid()
	owner.emote("cough")
	if(get_blood_fluid() < 5 || !prob(65))
		return
	owner.ce_cough_blood()
	add_fluid(-2)


/**
 * Handles pulmonary edema, fluid resorption, and related symptoms.
 */
/obj/item/organ/lungs/proc/process_fluid(seconds_per_tick)
	// A weakened heart combined with high blood pressure can cause cardiogenic pulmonary edema.
	var/obj/item/organ/heart/heart = owner.get_organ_slot(ORGAN_SLOT_HEART)
	if(heart && heart.damage > heart.high_threshold && owner.blood_pressure > BP_NORMAL * 1.2)
		add_fluid(0.4 * seconds_per_tick)

	// Healthy lungs gradually resorb accumulated fluid.
	else if(fluid > 0 && damage < low_threshold)
		add_fluid(-LUNG_FLUID_RESORB * seconds_per_tick)

	// Severe fluid accumulation causes coughing.
	if(fluid > LUNG_FLUID_SEVERE && SPT_PROB(6, seconds_per_tick))
		cough_up_fluid()

	// Completely flooded lungs can cause audible choking and gurgling.
	if(fluid >= LUNG_FLUID_MAX && SPT_PROB(3, seconds_per_tick))
		owner.visible_message(span_danger(get_blood_fluid() >= fluid * 0.5 ? "[owner] gurgles, choking on [owner.p_their()] own blood!" : "[owner] gurgles, choking on fluid!"))


/obj/item/organ/lungs/proc/update_blood_oxygenation(seconds_per_tick)
	if(HAS_TRAIT(owner, TRAIT_NOBREATH))
		owner.blood_oxygenation = 100
		return

	var/vent = get_ventilation()
	var/target = vent * 100
	target = max(target, 8)

	var/step = (target < owner.blood_oxygenation) ? LUNG_GAS_EXCHANGE_DOWN : LUNG_GAS_EXCHANGE_UP
	if(fluid > LUNG_FLUID_SEVERE)
		if(target < owner.blood_oxygenation)
			step *= 1.4
		else
			step *= 0.55

	owner.blood_oxygenation = clamp(
		owner.blood_oxygenation + clamp(target - owner.blood_oxygenation, -step, step) * seconds_per_tick,
		0,
		100
	)

/obj/item/organ/lungs/on_life(seconds_per_tick)
	. = ..()

	if(!owner)
		return

	process_fluid(seconds_per_tick)
	update_blood_oxygenation(seconds_per_tick)

	if(failed && !(organ_flags & ORGAN_FAILING))
		failed = FALSE
		return

	if(damage >= low_threshold)
		var/do_i_cough = SPT_PROB((damage < high_threshold) ? 2.5 : 5, seconds_per_tick)
		if(do_i_cough)
			owner.emote("cough")

	if(organ_flags & ORGAN_FAILING && !IS_UNCONSCIOUS_OR_CRIT(owner))
		owner.visible_message(
			span_danger("[owner] grabs [owner.p_their()] throat, struggling for breath!"),
			span_userdanger("You suddenly feel like you can't breathe!")
		)
		failed = TRUE


/obj/item/organ/lungs/proc/handle_suffocation(
	mob/living/carbon/human/suffocator = null,
	breath_pp = 0,
	safe_breath_min = 0,
	mole_count = 0
)
	. = 0

	if(isnull(suffocator) || safe_breath_min <= 0)
		return

	suffocator.failed_last_breath = TRUE

	if(prob(25))
		suffocator.emote("gasp")

	if(breath_pp > 0)
		// A partial breath still provides some oxygen.
		. = mole_count

		// Breathing at least 60% of the safe partial pressure is considered a successful breath.
		if(breath_pp >= safe_breath_min * 0.6)
			suffocator.failed_last_breath = FALSE

	return .


/obj/item/organ/lungs/proc/breathe_oxygen(
	mob/living/carbon/breather,
	datum/gas_mixture/breath,
	o2_pp,
	old_o2_pp
)
	if(o2_pp < safe_oxygen_min && !HAS_TRAIT(breather, TRAIT_NO_BREATHLESS_DAMAGE))
		breather.throw_alert(
			ALERT_NOT_ENOUGH_OXYGEN,
			/atom/movable/screen/alert/not_enough_oxy
		)

		var/gas_breathed = handle_suffocation(
			breather,
			o2_pp,
			safe_oxygen_min,
			breath.moles[/datum/gas/oxygen]
		)

		if(o2_pp)
			breathe_gas_volume(
				breath,
				/datum/gas/oxygen,
				/datum/gas/carbon_dioxide,
				volume = gas_breathed
			)

		return

	if(old_o2_pp < safe_oxygen_min)
		breather.failed_last_breath = FALSE
		breather.clear_alert(ALERT_NOT_ENOUGH_OXYGEN)

	breathe_gas_volume(
		breath,
		/datum/gas/oxygen,
		/datum/gas/carbon_dioxide
	)

#endif
