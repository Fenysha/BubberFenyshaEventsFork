/obj/item/gun/rimworld/process_fire(atom/target, mob/living/user, message = TRUE, params = null, zone_override = "", bonus_spread = 0)
	if(!rw_wielded)
		balloon_alert(user, "grip it with both hands first!")
		return ITEM_INTERACT_BLOCKING

	// The off-hand must be free, except for the two-handed component's offhand item.
	var/obj/item/offhand_check = user.get_inactive_held_item()
	if(!user.is_holding(src) || (offhand_check && !istype(offhand_check, /obj/item/offhand)))
		rw_unwield(user, silent = TRUE)
		balloon_alert(user, "need a free off-hand!")
		return ITEM_INTERACT_BLOCKING

	if(!rw_is_ready())
		return ITEM_INTERACT_BLOCKING
	if(rw_manipulation(user) < RW_MIN_MANIPULATION)
		balloon_alert(user, "can't hold it steady!")
		return ITEM_INTERACT_BLOCKING
	if(bolt_locked)
		balloon_alert(user, "[bolt_wording] locked!")
		return ITEM_INTERACT_BLOCKING
	if(!chambered?.loaded_projectile)
		shoot_with_empty_chamber(user)
		return user.combat_mode ? ITEM_INTERACT_SKIP_TO_ATTACK : NONE

	rw_recalc_attachments(user)
	rw_sanitize_modes(user)
	add_fingerprint(user)
	SEND_SIGNAL(src, COMSIG_GUN_FIRED, user, target, params, zone_override)

	// Reset the recoil streak after a long pause.
	if(world.time - rw_last_shot > RW_SHOT_STREAK_RESET)
		rw_shots_in_row = 0

	var/rounds = 1
	var/delay = rw_cooldown
	switch(rw_fire_mode)
		if(RW_FIRE_BURST)
			rounds = max(2, rw_burst_size_rw + rw_att_burst_add)
			delay = rw_burst_delay * rw_att_burst_delay_mult
		if(RW_FIRE_AUTO)
			rounds = rw_auto_rounds
			delay = rw_auto_delay

	firing_burst = rounds > 1
	// Tentative next-fire time; rw_end_sequence overwrites with the real cooldown.
	rw_next_fire = world.time + rounds * delay + rw_calc_cooldown(user)
	rw_fire_round(user, target, params, message, rounds, 1, delay)
	rw_update_ready_overlay()
	rw_refresh_hud()
	return TRUE


/// Fire one round of a (possibly multi-round) sequence, then schedule the next.
/obj/item/gun/rimworld/proc/rw_fire_round(mob/living/user, atom/target, params, message, rounds_left, index, delay)
	if(QDELETED(src) || QDELETED(user) || QDELETED(target) || (index > 1 && !user.is_holding(src)))
		return rw_end_sequence(user)
	if(!chambered?.loaded_projectile)
		shoot_with_empty_chamber(user)
		return rw_end_sequence(user)
	if(HAS_TRAIT(user, TRAIT_PACIFISM) && chambered.harmful)
		to_chat(user, span_warning("[src] is lethally chambered! You don't want to risk harming anyone..."))
		return rw_end_sequence(user)

	var/max_spread = rw_calc_spread(user)
	// Generate a symmetric spread offset.
	var/shot_spread = round((rand() + rand() - 1) * max_spread, 0.1)

	// Snapshot shot data before creating the projectile.
	rw_current_shot = list(
		"aim_mode" = rw_aim_mode,
		"area" = user.rw_aim_area,
		"precise" = (!user.rw_aim_area && rw_ranged_skill(user) >= RW_REQ_SKILL_LIMB && rw_aim_mode != RW_AIM_SUPPRESS) ? user.zone_selected : null,
		"zone_accuracy_pct" = rw_calc_zone_accuracy_pct(user),
		"miss_base" = rw_calc_miss_base(user),
	)

	before_firing(target, user)
	if(!chambered.fire_casing(target, user, params, 0, suppressed, "", shot_spread, src))
		shoot_with_empty_chamber(user)
		rw_current_shot = null
		return rw_end_sequence(user)
	rw_current_shot = null

	rw_fire_audio_begin()
	shoot_live_shot(user, get_dist(user, target) <= 1, target, message && index == 1 && !rw_att_silenced)
	rw_fire_audio_end()
	rw_fire_effects(user, target)
	if(!QDELETED(src))
		process_chamber()
		// Parent fire_gun() calls postfire_empty_checks after the shot.
		// Our custom fire path never reaches fire_gun, so lock the bolt here.
		rw_postfire_bolt_check(TRUE)
		update_appearance()
	rw_shots_in_row++
	rw_last_shot = world.time
	RW_TRAIN_SKILL(user, RW_SKILL_RANGED, RW_SKILL_POINTS_TINY)
	user.update_held_items()
	rw_apply_fire_slowdown(user)
	rw_refresh_hud()

	if(rounds_left > 1)
		addtimer(CALLBACK(src, PROC_REF(rw_fire_round), user, target, params, message, rounds_left - 1, index + 1, delay), delay)
		return TRUE
	return rw_end_sequence(user)


/// Clean up after a single-shot or the last shot of a burst/auto sequence.
/obj/item/gun/rimworld/proc/rw_end_sequence(mob/living/user)
	firing_burst = FALSE
	var/cd = user ? rw_calc_cooldown(user) : rw_cooldown

	if(rw_fire_mode != RW_FIRE_SINGLE)
		cd *= RW_POST_BURST_MULT
	rw_next_fire = world.time + cd
	rw_refresh_hud()
	rw_update_ready_overlay()
	// TIMER_UNIQUE|OVERRIDE so rapid re-fires don't leave orphan timers that
	// clear the overlay while a newer cooldown is still running (or vice versa).
	var/wait = max(rw_next_fire - world.time, 0) + 1
	addtimer(CALLBACK(src, PROC_REF(rw_on_ready_again)), wait, TIMER_UNIQUE | TIMER_OVERRIDE | TIMER_STOPPABLE)
	return FALSE


/// Mirror of /obj/item/gun/ballistic/postfire_empty_checks for our custom fire path.
/// Locks a LOCKING bolt when the chamber and magazine are empty after a live shot.
/obj/item/gun/rimworld/proc/rw_postfire_bolt_check(last_shot_succeeded)
	if(!last_shot_succeeded)
		return
	if(chambered || get_ammo())
		return
	if(bolt_type == BOLT_TYPE_LOCKING && semi_auto)
		bolt_locked = TRUE
		if(lock_back_sound)
			playsound(src, lock_back_sound, lock_back_sound_volume, lock_back_sound_vary)
	else if(bolt_type == BOLT_TYPE_OPEN && !bolt_locked)
		bolt_locked = TRUE
		if(bolt_drop_sound)
			playsound(src, bolt_drop_sound, bolt_drop_sound_volume)


/// Copy the transient shot bag onto a rimworld projectile.
/obj/item/gun/rimworld/proc/rw_apply_shot_data(obj/projectile/rimworld/proj)
	if(!rw_current_shot)
		return
	proj.rw_aim_mode = rw_current_shot["aim_mode"]
	proj.rw_area_zones = rw_current_shot["area"] ? GLOB.rw_area_zones[rw_current_shot["area"]] : null
	proj.rw_precise_zone = rw_current_shot["precise"]
	proj.rw_zone_accuracy_pct = rw_current_shot["zone_accuracy_pct"]
	proj.rw_miss_base = rw_current_shot["miss_base"]
	proj.rw_effective_range = rw_effective_range * rw_att_range_mult
	proj.damage *= rw_att_damage_mult
	proj.speed *= rw_att_speed_mult
