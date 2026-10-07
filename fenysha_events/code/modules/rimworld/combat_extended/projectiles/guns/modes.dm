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
