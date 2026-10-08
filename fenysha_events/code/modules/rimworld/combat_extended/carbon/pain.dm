#ifndef OLD_COMBAT_SYSTEM
/mob/living/carbon/proc/set_pain(new_pain)
	pain_base = max(new_pain, 0)
	recalculate_medical_state()

/mob/living/carbon/proc/adjust_pain(amount)
	// pain_base is rebuilt from limbs; non-injury pain lives in its own variable.
	pain_misc = max(pain_misc + amount, 0)
	recalculate_medical_state()

/mob/living/carbon/proc/update_pain_from_limb(obj/item/bodypart/source_limb)
	var/total = 0
	for(var/obj/item/bodypart/BP as anything in bodyparts)
		total += BP.current_pain
	set_pain(total)

/mob/living/carbon/proc/apply_acute_pain(amount)
	if(amount <= 0)
		return
	acute_pain = clamp(acute_pain + amount, 0, PAIN_MAX * 2)
	recalculate_medical_state()

/**
 * Returns the current pain level.
 */
/mob/living/carbon/proc/get_pain()
	return pain

/**
 * Returns TRUE if the mob is experiencing significant pain.
 */
/mob/living/carbon/proc/in_pain()
	return pain >= PAIN_SHOCK_THRESHOLD

/// Keep a continuously scaled mood penalty for pain, independent of need levels.
/mob/living/carbon/proc/update_psychology_pain_factor()
	var/datum/psychology/psy = get_psychology()
	if(!psy)
		return
	if(pain <= 0)
		psy.clear_factor(PSY_CATEGORY_PAIN)
		return

	var/penalty = -round(clamp(pain / PAIN_MAX, 0, 1) * PSY_PAIN_MOOD_MAX_PENALTY, 0.1)
	var/datum/psychology_factor/current = psy.get_factor(PSY_CATEGORY_PAIN)
	if(!current || current.mood_change != penalty)
		psy.add_factor(PSY_CATEGORY_PAIN, "pain", penalty, "Ongoing pain reduces your mood.")

/atom/movable/screen/fullscreen/pain_spots
	icon = 'icons/hud/screen_full.dmi'
	icon_state = "brutedamageoverlay"
	layer = UI_DAMAGE_LAYER
	plane = FULLSCREEN_PLANE
	alpha = 0
	color = list(
		1.1, 0.05, 0.05, 0,
		0.15, 0.4, 0.1, 0,
		0.1, 0.05, 0.35, 0,
		0, 0, 0, 0.85,
		0, 0, 0, 0
	)

/atom/movable/screen/fullscreen/pain_spots/update_for_view(client_view)
	. = ..()
	animate(src, alpha = alpha, time = 0)
	animate(alpha = min(255, alpha + 40), time = 1.2 SECONDS, loop = -1, easing = SINE_EASING)
	animate(alpha = max(0, alpha - 30), time = 1.4 SECONDS, easing = SINE_EASING)

/**
 * Side effects of pain. Called once per Life tick,
 * all chances are per second and scaled by seconds_per_tick.
 */
/mob/living/carbon/proc/process_pain_effects(seconds_per_tick = 1)
	if(pain >= PAIN_FIBRILLATION_THRESHOLD && needs_heart())
		var/obj/item/organ/heart/heart = get_organ_slot(ORGAN_SLOT_HEART)
		if(heart && heart.damage > heart.high_threshold && !heart.fibrillating && heart.is_beating())
			var/cardiac_damage_factor = clamp(
				(heart.damage - heart.high_threshold) / max(heart.maxHealth - heart.high_threshold, 1),
				0,
				1,
			)
			var/fib_chance = abs((pain - PAIN_FIBRILLATION_THRESHOLD) * 0.01) * cardiac_damage_factor
			if(SPT_PROB(fib_chance, seconds_per_tick))
				if(heart.enter_fibrillation())
					to_chat(src, span_userdanger("Agony tears through your chest — your heart stumbles into chaos!"))
					visible_message(span_danger("[src] clutches at [src.p_their()] chest, face contorted in pure agony!"))

	if(consciousness_blackout)
		clear_fullscreen("pain_spots")
		update_pain_movespeed()
		return

	if(pain >= PAIN_BLUR_THRESHOLD)
		var/blur_strength = min(PAIN_BLUR_MAX, (pain - PAIN_BLUR_THRESHOLD) * 0.045 SECONDS)
		set_eye_blur_if_lower(blur_strength)

	if(pain >= PAIN_SPOTS_THRESHOLD)
		var/severity = clamp(round((pain - PAIN_SPOTS_THRESHOLD) / 18), 1, PAIN_SPOTS_MAX_SEVERITY)
		var/atom/movable/screen/fullscreen/pain_spots/spots = overlay_fullscreen("pain_spots", /atom/movable/screen/fullscreen/pain_spots, severity)
		spots.alpha = clamp(40 + severity * 28, 40, 220)
	else
		clear_fullscreen("pain_spots", animated = 8)

	if(pain >= PAIN_DROP_THRESHOLD)
		var/drop_chance = min(4 + (pain - PAIN_DROP_THRESHOLD) * 0.06, 18)
		if(SPT_PROB(drop_chance, seconds_per_tick))
			var/obj/item/held = get_active_held_item()
			if(held)
				dropItemToGround(held)
				visible_message(
					span_warning("[src] drops [held] in pain!"),
					span_userdanger("You drop [held] from the pain!")
				)
			if(pain >= PAIN_UNCONSCIOUS_THRESHOLD && prob(25))
				var/obj/item/offhand = get_inactive_held_item()
				if(offhand)
					dropItemToGround(offhand)

	update_pain_movespeed()

/**
 * Updates movement speed modifiers based on pain, shock, and consciousness.
 */
/datum/movespeed_modifier/pain
	variable = TRUE
	blacklisted_movetypes = FLOATING|FLYING

/mob/living/carbon/proc/update_pain_movespeed()
	remove_movespeed_modifier(/datum/movespeed_modifier/pain)

	var/slowdown = 0

	if(pain >= PAIN_CRIT_THRESHOLD)
		slowdown += 1.2
	else if(pain >= PAIN_SHOCK_THRESHOLD)
		slowdown += 0.6

	if(consciousness <= CONSCIOUSNESS_HEAVY)
		slowdown += 1.6
	else if(consciousness <= CONSCIOUSNESS_IMPAIRED)
		slowdown += 0.8

	if(shock >= SHOCK_SEVERE)
		slowdown += 0.5
	else if(shock >= SHOCK_MODERATE)
		slowdown += 0.25

	if(slowdown > 0)
		add_or_update_variable_movespeed_modifier(
			/datum/movespeed_modifier/pain,
			multiplicative_slowdown = slowdown
		)
#endif
