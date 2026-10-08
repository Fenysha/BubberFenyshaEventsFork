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
	if(isliving(user))
		var/mob/living/shooter = user
		result *= shooter.get_rw_ranged_spread_mult()
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
