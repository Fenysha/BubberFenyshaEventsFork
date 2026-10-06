/mob/living
	/// Current paper-doll aim area (RW_AREA_HEAD / TORSO / LEGS). Null = precise limb targeting when skill allows.
	var/rw_aim_area = RW_AREA_TORSO
	var/datum/component/rw_gun_hud/rw_gun_hud


/// Maps a body zone string to one of the three coarse aim areas.
/proc/rw_area_of_zone(zone)
	switch(zone)
		if(BODY_ZONE_HEAD, BODY_ZONE_PRECISE_EYES, BODY_ZONE_PRECISE_MOUTH)
			return RW_AREA_HEAD
		if(BODY_ZONE_L_LEG, BODY_ZONE_R_LEG)
			return RW_AREA_LEGS
	return RW_AREA_TORSO


GLOBAL_LIST_INIT(rw_area_zones, list(
	RW_AREA_HEAD = list(BODY_ZONE_HEAD),
	RW_AREA_TORSO = list(BODY_ZONE_CHEST, BODY_ZONE_L_ARM, BODY_ZONE_R_ARM),
	RW_AREA_LEGS = list(BODY_ZONE_L_LEG, BODY_ZONE_R_LEG),
))


/obj/item/gun/rimworld
	name = "rimworld gun"
	desc = "A firearm with a biometric lock."
	abstract_type = /obj/item/gun/rimworld
	parent_type = /obj/item/gun/ballistic

	// Biocode replaces the normal firing pin.
	pin = null
	pinless = TRUE

	/// Current aim mode: snap / aimed / suppress.
	var/rw_aim_mode = RW_AIM_SNAP
	/// Current fire mode: single / burst / auto.
	var/rw_fire_mode = RW_FIRE_SINGLE
	/// Which fire modes this gun type may select.
	var/list/rw_allowed_fire_modes = list(RW_FIRE_SINGLE, RW_FIRE_BURST)

	/// TRUE while the two_handed component reports the gun as wielded.
	var/rw_wielded = FALSE
	/// TRUE while the do_after for gripping is running (blocks re-entry).
	var/rw_wield_busy = FALSE
	/// Base time to bring the gun into a two-handed grip (scaled by skill/manip).
	var/rw_wield_time = 0.8 SECONDS

	/// Distance (tiles) at which range falloff starts to dominate miss chance.
	var/rw_effective_range = 12 TILES

	/// Intrinsic angular spread of this gun before skill/mode modifiers.
	var/rw_base_spread = 2 DEGREES
	/// Base inter-shot cooldown (single-fire) before skill/mode/manip scaling.
	var/rw_cooldown = 0.7 SECONDS
	/// Rounds fired in one burst.
	var/rw_burst_size_rw = 3
	/// Delay between individual shots inside a burst.
	var/rw_burst_delay = 0.15 SECONDS
	/// Rounds fired in one full-auto sequence.
	var/rw_auto_rounds = 8
	/// Delay between individual shots in full-auto.
	var/rw_auto_delay = 0.1 SECONDS
	/// Extra spread added per consecutive shot (recoil build-up).
	var/rw_recoil_spread = 0.8 DEGREES

	/// Peak extra spread while the shooter is still "moving" (decays over settle time).
	var/rw_moving_spread = 20 DEGREES
	/// How long the shooter must stand still before moving penalty fully disappears.
	var/rw_settle_time = 1.5 SECONDS
	/// world.time of the last movement of the current holder.
	var/rw_last_move = 0

	/// Earliest world.time the gun may fire again.
	var/rw_next_fire = 0
	/// Consecutive shots without a long pause (feeds recoil spread + miss).
	var/rw_shots_in_row = 0
	/// world.time of the most recent live shot.
	var/rw_last_shot = 0
	/// Transient bag of aim data copied onto the projectile for the current shot.
	var/list/rw_current_shot

	/// If FALSE, biocode is completely disabled for this gun type.
	var/rw_biocode_enabled = TRUE
	/// If TRUE, the gun auto-binds to the first living mind that equips it.
	var/rw_biocode_on_equip = FALSE
	/// Weakref to the mind the gun is locked to (null = unbound).
	var/datum/weakref/rw_biocode_mind
	/// Cached real_name of the biocoded owner (for examine / alerts).
	var/rw_biocode_name

	/// HUD component that draws ammo / aim / fire-mode buttons.
	var/datum/component/rw_gun_hud/rw_hud



/obj/item/gun/rimworld/Initialize(mapload)
	. = ..()
	rw_hud = AddComponent(/datum/component/rw_gun_hud)
	AddComponent(/datum/component/two_handed, \
		require_twohands = FALSE, \
		wield_callback = CALLBACK(src, PROC_REF(rw_on_wield)), \
		unwield_callback = CALLBACK(src, PROC_REF(rw_on_unwield)))
	rw_init_attachments()


/// Subtypes override to report current magazine / internal ammo count.
/obj/item/gun/rimworld/proc/rw_get_ammo_count()
	return 0

/// Subtypes override to report magazine capacity.
/obj/item/gun/rimworld/proc/rw_get_ammo_max()
	return 0

/// Returns the user's ranged skill.
/obj/item/gun/rimworld/proc/rw_ranged_skill(mob/living/user)
	if(!user)
		return 0
	return RW_GET_SKILL(user, RW_SKILL_RANGED)

/// Returns the user's manipulation capacity.
/obj/item/gun/rimworld/proc/rw_manipulation(mob/living/user)
	if(iscarbon(user))
		var/mob/living/carbon/C = user
		return C.get_manipulation_capacity()
	return 1

/// Whether the user's skill is high enough for the given aim mode.
/obj/item/gun/rimworld/proc/rw_can_use_aim_mode(mob/living/user, mode)
	var/skill = rw_ranged_skill(user)
	switch(mode)
		if(RW_AIM_SNAP)
			return TRUE
		if(RW_AIM_AIMED)
			return skill >= RW_REQ_SKILL_AIMED
		if(RW_AIM_SUPPRESS)
			return skill >= RW_REQ_SKILL_SUPPRESS
	return FALSE

/// Whether the fire mode is allowed by the gun and by the current aim mode.
/// Full-auto is only legal while suppressing.
/obj/item/gun/rimworld/proc/rw_can_use_fire_mode(mode, aim_mode = rw_aim_mode)
	if(!(mode in rw_allowed_fire_modes) && !(mode in rw_att_fire_modes))
		return FALSE
	if(mode == RW_FIRE_AUTO && aim_mode != RW_AIM_SUPPRESS)
		return FALSE
	return TRUE


/// Clamp current aim/fire modes to what the user can actually use.
/obj/item/gun/rimworld/proc/rw_sanitize_modes(mob/living/user)
	if(!rw_can_use_aim_mode(user, rw_aim_mode))
		rw_aim_mode = RW_AIM_SNAP
	if(!rw_can_use_fire_mode(rw_fire_mode))
		rw_fire_mode = RW_FIRE_SINGLE
	if(user && rw_ranged_skill(user) < RW_REQ_SKILL_LIMB && !user.rw_aim_area)
		user.rw_aim_area = rw_area_of_zone(user.zone_selected)


/// Cycle aim mode to the next one the user is skilled enough to use.
/obj/item/gun/rimworld/proc/rw_cycle_aim_mode(mob/living/user)
	var/static/list/order = list(RW_AIM_SNAP, RW_AIM_AIMED, RW_AIM_SUPPRESS)
	var/idx = order.Find(rw_aim_mode)
	for(var/i in 1 to length(order))
		idx = (idx % length(order)) + 1
		var/candidate = order[idx]
		if(rw_can_use_aim_mode(user, candidate))
			rw_aim_mode = candidate
			break
	rw_sanitize_modes(user)
	playsound(src, SFX_FIRE_MODE_SWITCH, 40, TRUE)
	rw_refresh_hud()


/// Cycle fire mode to the next legal mode for this gun + current aim mode.
/obj/item/gun/rimworld/proc/rw_cycle_fire_mode(mob/living/user)
	var/static/list/order = list(RW_FIRE_SINGLE, RW_FIRE_BURST, RW_FIRE_AUTO)
	var/idx = order.Find(rw_fire_mode)
	for(var/i in 1 to length(order))
		idx = (idx % length(order)) + 1
		if(rw_can_use_fire_mode(order[idx]))
			rw_fire_mode = order[idx]
			break
	playsound(src, SFX_FIRE_MODE_SWITCH, 40, TRUE)
	rw_refresh_hud()


/obj/item/gun/rimworld/proc/rw_calc_spread(mob/living/user)
	var/skill = rw_ranged_skill(user)
	var/manip = clamp(rw_manipulation(user), 0.2, 1)

	var/mode_mult = RW_SPREAD_MULT_SNAP
	var/skill_mult = clamp(1.5 - 0.06 * skill, 0.3, 1.5)
	var/flat_spread = 0 DEGREES
	switch(rw_aim_mode)
		if(RW_AIM_AIMED)
			mode_mult = RW_SPREAD_MULT_AIMED
		if(RW_AIM_SUPPRESS)
			mode_mult = RW_SPREAD_MULT_SUPPRESS
			skill_mult = 1 // Suppression is intentionally skill-independent.
			flat_spread = RW_SUPPRESS_FLAT_SPREAD

	var/result = (rw_base_spread + spread + rw_att_spread) * mode_mult * skill_mult + flat_spread
	result *= 1 + (1 - manip) * 2.5
	result += rw_calc_moving_penalty()
	result += rw_recoil_spread * rw_att_recoil_spread_mult * rw_shots_in_row
	return max(result, 0)


/// Extra spread that decays linearly after the shooter stops moving.
/obj/item/gun/rimworld/proc/rw_calc_moving_penalty()
	var/still_time = world.time - rw_last_move
	if(still_time >= rw_settle_time)
		return 0
	return rw_moving_spread * rw_att_moving_spread_mult * (1 - still_time / max(rw_settle_time, 1))


/obj/item/gun/rimworld/proc/rw_calc_cooldown(mob/living/user)
	var/skill = rw_ranged_skill(user)
	var/manip = clamp(rw_manipulation(user), 0.3, 1)
	var/mode_mult = RW_DELAY_MULT_SNAP
	switch(rw_aim_mode)
		if(RW_AIM_AIMED)
			mode_mult = RW_DELAY_MULT_AIMED
		if(RW_AIM_SUPPRESS)
			mode_mult = RW_DELAY_MULT_SUPPRESS
	var/skill_mult = clamp(1.25 - 0.025 * skill, 0.75, 1.25)

	return max(RW_COOLDOWN_FLOOR, rw_cooldown * rw_att_cooldown_mult * mode_mult * skill_mult / manip)


/// Chance (0-100) that a hit lands on the intended area/zone rather than scattering.
/obj/item/gun/rimworld/proc/rw_calc_zone_accuracy_pct(mob/living/user)
	var/skill = rw_ranged_skill(user)
	var/manip = clamp(rw_manipulation(user), 0.2, 1)
	var/accuracy_pct = (35 + skill * 3) * manip
	if(rw_aim_mode == RW_AIM_AIMED)
		accuracy_pct += 10
	accuracy_pct += rw_att_zone_acc_add
	accuracy_pct -= rw_calc_moving_penalty() * 2
	return clamp(accuracy_pct, 5, 98)


/obj/item/gun/rimworld/proc/rw_calc_miss_base(mob/living/user)
	var/skill = rw_ranged_skill(user)
	var/manip = clamp(rw_manipulation(user), 0.2, 1)

	var/miss = max(RW_MISS_UNSKILLED - RW_MISS_PER_SKILL_LEVEL * skill, RW_MISS_MIN)

	switch(rw_aim_mode)
		if(RW_AIM_AIMED)
			miss *= 0.45
		if(RW_AIM_SUPPRESS)
			miss = max(miss, 0.55) + RW_MISS_SUPPRESS_BONUS
			miss *= 1.15

	miss += (1 - manip) * RW_MISS_MANIP_FACTOR
	miss += (rw_calc_moving_penalty() / max(rw_moving_spread, 1)) * RW_MISS_MOVING_FACTOR
	miss += min(rw_shots_in_row * 0.04, 0.25) // Sustained fire worsens accuracy.
	miss += rw_att_miss_add

	return clamp(miss, 0, 0.97)



/obj/item/gun/rimworld/proc/rw_on_wield(obj/item/source, mob/living/user)
	rw_wielded = TRUE
	update_appearance()
	user?.update_held_items()
	rw_refresh_hud()
	return NONE

/obj/item/gun/rimworld/proc/rw_on_unwield(obj/item/source, mob/living/user)
	rw_wielded = FALSE
	update_appearance()
	user?.update_held_items()
	rw_refresh_hud()
	return NONE


/obj/item/gun/rimworld/attack_self(mob/living/user)
	if(rw_wield_busy)
		return
	var/datum/component/two_handed/th = GetComponent(/datum/component/two_handed)
	if(!th)
		return
	if(th.wielded)
		th.unwield(user)
		return
	rw_try_wield(user)


/// Time (ds) required to finish the two-handed grip do_after.
/obj/item/gun/rimworld/proc/rw_wield_duration(mob/living/user)
	var/skill = rw_ranged_skill(user)
	var/manip = clamp(rw_manipulation(user), 0.3, 1)
	// Floor of 2 ds so the do_after never becomes instant.
	return max(2, round(rw_wield_time * rw_att_wield_mult * clamp(1.4 - 0.03 * skill, 0.8, 1.4) / manip))


/// Start the do_after that ends in a proper two-handed wield.
/obj/item/gun/rimworld/proc/rw_try_wield(mob/living/user)
	if(!user.is_holding(src))
		return
	if(user.get_inactive_held_item())
		balloon_alert(user, "free your other hand!")
		return
	if(HAS_TRAIT(user, TRAIT_HANDS_BLOCKED) || HAS_TRAIT(user, TRAIT_NO_TWOHANDING))
		balloon_alert(user, "can't use two hands!")
		return
	if(user.usable_hands < 2)
		balloon_alert(user, "not enough hands!")
		return

	rw_wield_busy = TRUE
	user.visible_message(
		span_notice("[user] begins to bring [src] up in a two-handed grip."),
		span_notice("You start gripping [src] with both hands..."),
	)
	var/ok = do_after(user, rw_wield_duration(user), src, IGNORE_USER_LOC_CHANGE)
	rw_wield_busy = FALSE
	if(!ok || QDELETED(src) || !user.is_holding(src) || user.get_inactive_held_item())
		return

	var/datum/component/two_handed/th = GetComponent(/datum/component/two_handed)
	if(th)
		th.wield(user)


/obj/item/gun/rimworld/proc/rw_unwield(mob/living/user, silent = FALSE)
	var/datum/component/two_handed/th = GetComponent(/datum/component/two_handed)
	if(th?.wielded)
		th.unwield(user, show_message = !silent)


/obj/item/gun/rimworld/update_icon_state()
	inhand_icon_state = "[base_icon_state][rw_wielded ? "_w" : ""]"
	. = ..()


/// TRUE when the gun is gripped and not on cooldown / mid-burst.
/obj/item/gun/rimworld/proc/rw_can_fire_now()
	return rw_wielded && !firing_burst && world.time >= rw_next_fire

/// Ready for the next trigger pull (ignores wield state — used by overlay).
/obj/item/gun/rimworld/proc/rw_is_ready()
	return !firing_burst && world.time >= rw_next_fire



/obj/item/gun/rimworld/proc/rw_apply_fire_slowdown(mob/living/user)
	if(!user)
		return

	user.apply_status_effect(/datum/status_effect/rw_fire_recoil)
