/datum/injury
	/// TRUE = on_owner_moved() is called for every step the owner takes.
	var/reacts_to_movement = FALSE
	/// Mob we registered signals on (so we can always clean up).
	var/mob/living/carbon/effects_owner
	var/next_message_time = 0
	var/next_sound_time = 0
	/// Lungs currently carrying our ventilation modifier.
	var/datum/weakref/modified_lungs_ref


/datum/injury/proc/register_effects()
	if(!owner || effects_owner == owner)
		return
	unregister_effects()
	effects_owner = owner
	if(reacts_to_movement)
		RegisterSignal(owner, COMSIG_MOVABLE_MOVED, PROC_REF(on_owner_moved_signal))

/datum/injury/proc/unregister_effects(replaced = FALSE)
	if(effects_owner)
		UnregisterSignal(effects_owner, COMSIG_MOVABLE_MOVED)
		effects_owner = null
	clear_lung_modifier()

/datum/injury/proc/on_applied_effects(attack_direction)
	return

/datum/injury/proc/process_effects(seconds_per_tick)
	return

/datum/injury/proc/on_owner_moved_signal(datum/source, atom/old_loc, movement_dir, forced, list/old_locs)
	SIGNAL_HANDLER
	if(QDELETED(src) || source != owner || forced)
		return
	INVOKE_ASYNC(src, PROC_REF(on_owner_moved), movement_dir)

/datum/injury/proc/on_owner_moved(movement_dir)
	return

/datum/injury/proc/get_visible_signs(mob/user)
	return null

/// Convenience for wounds that stay visibly bad until properly treated.
/datum/injury/proc/get_untreated_sign(min_quality = INJURY_TREATMENT_ADEQUATE)
	if(!owner || !limb || treatment_quality >= min_quality)
		return null
	return span_danger(get_examine_text())


/datum/injury/proc/is_leg()
	return limb && (limb.body_zone == BODY_ZONE_L_LEG || limb.body_zone == BODY_ZONE_R_LEG)

/datum/injury/proc/is_arm()
	return limb && (limb.body_zone == BODY_ZONE_L_ARM || limb.body_zone == BODY_ZONE_R_ARM)

/// Shrinks a physiological penalty (0..1) according to how well the injury is treated.
/datum/injury/proc/scale_by_treatment(penalty)
	switch(treatment_quality)
		if(INJURY_TREATMENT_POOR)
			return penalty * 0.75
		if(INJURY_TREATMENT_ADEQUATE)
			return penalty * 0.35
		if(INJURY_TREATMENT_EXCELLENT)
			return penalty * 0.1
	return penalty

/// TRUE if the message may be shown now (per-injury cooldown).
/datum/injury/proc/effect_message_ready(cooldown = INJURY_MESSAGE_COOLDOWN)
	if(world.time < next_message_time)
		return FALSE
	next_message_time = world.time + cooldown
	return TRUE

/datum/injury/proc/play_effect_sound(sound_to_play, volume = 50, cooldown = 0)
	if(!owner || world.time < next_sound_time)
		return
	next_sound_time = world.time + cooldown
	playsound(owner, sound_to_play, volume, TRUE, -1)

/// Sudden pain spike with optional (rate limited) messages and emote.
/datum/injury/proc/pain_spike(amount, self_text, visible_text, emote_name)
	if(!owner || owner.stat == DEAD)
		return
	owner.apply_acute_pain(amount)
	if(!effect_message_ready())
		return
	if(self_text && visible_text)
		owner.visible_message(span_danger(visible_text), span_userdanger(self_text))
	if(emote_name)
		owner.emote(emote_name)

/// Blood thrown out of the wound in the direction of the hit (or randomly).
/datum/injury/proc/hit_spray(attack_direction, streams = 1, distance = 2, small = FALSE)
	if(!owner || !isturf(owner.loc))
		return
	for(var/i in 1 to streams)
		owner.ce_spray_blood((i == 1 && attack_direction) ? attack_direction : pick(GLOB.alldirs), distance, small)

/// Makes the holding hand drop whatever it holds. Returns TRUE if something was dropped.
/datum/injury/proc/drop_limb_item(reason = "gives out")
	if(!owner || !limb || !limb.held_index)
		return FALSE
	var/obj/item/held = owner.get_item_for_held_index(limb.held_index)
	if(!held || HAS_TRAIT(held, TRAIT_NODROP) || !owner.dropItemToGround(held))
		return FALSE
	owner.visible_message(
		span_danger("[owner] drops [held] as [owner.p_their()] [limb.plaintext_zone] [reason]!"),
		span_userdanger("Your [limb.plaintext_zone] [reason] and you drop [held]!"),
	)
	return TRUE

/datum/injury/proc/set_lung_modifier(multiplier)
	var/obj/item/organ/lungs/lungs = owner?.get_organ_slot(ORGAN_SLOT_LUNGS)
	var/obj/item/organ/lungs/old_lungs = modified_lungs_ref?.resolve()
	if(old_lungs && old_lungs != lungs)
		old_lungs.remove_ventilation_modifier(unique_id)
	modified_lungs_ref = null
	if(!lungs)
		return
	lungs.set_ventilation_modifier(unique_id, multiplier)
	modified_lungs_ref = WEAKREF(lungs)

/datum/injury/proc/clear_lung_modifier()
	var/obj/item/organ/lungs/old_lungs = modified_lungs_ref?.resolve()
	old_lungs?.remove_ventilation_modifier(unique_id)
	modified_lungs_ref = null


/// Bleeds into a body cavity: must never leak onto the floor.
/datum/injury/proc/is_internal_bleeder()
	return (injury_flags & INJURY_FLAG_INTERNAL) && !(injury_flags & INJURY_FLAG_EXTERNAL) && bleed_rate > 0

/// Internal bleeders are excluded from owner.total_bleed_rate (which is what
/// handle_blood() turns into floor drips), so they drain blood here instead.
/datum/injury/proc/process_internal_bleeding(seconds_per_tick)
	if(!is_internal_bleeder() || !owner || HAS_TRAIT(owner, TRAIT_GODMODE) || !CAN_HAVE_BLOOD(owner))
		return
	var/rate = get_bleed_rate()
	if(rate > 0)
		owner.adjust_blood_volume(-rate * seconds_per_tick)
