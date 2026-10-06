/obj/item/gun/rimworld
	var/rw_muzzle_flash_state = "muzzle_flash"
	var/rw_muzzle_flash_lum = 3
	var/rw_muzzle_flash_color = COLOR_VERY_SOFT_YELLOW
	var/rw_muzzle_flash_radius = 13
	var/rw_muzzle_flash_x_offset = 0
	var/rw_muzzle_flash_y_offset = 0
	var/obj/effect/abstract/rw_muzzle_flash/rw_muzzle_flash


	var/rw_camera_recoil = 3
	var/rw_recoil_per_skill = 0.1

	var/rw_fire_rattle
	var/rw_low_ammo_frac = 0.25

	var/rw_fire_anim_state

	var/rw_saved_fire_sound
	var/rw_saved_fire_volume


/obj/item/gun/rimworld/proc/rw_fire_effects(mob/living/user, atom/target)
	var/angle = get_angle(user, target)
	if(!rw_att_silenced)
		rw_do_muzzle_flash(user, angle)
	rw_do_camera_recoil(user, angle)
	if(rw_fire_anim_state)
		flick(rw_fire_anim_state, src)


/obj/item/gun/rimworld/proc/rw_is_low_ammo()
	var/max_ammo_count = rw_get_ammo_max()
	if(max_ammo_count <= 0)
		return FALSE
	return (rw_get_ammo_count() / max_ammo_count) <= rw_low_ammo_frac


/obj/item/gun/rimworld/proc/rw_fire_audio_begin()
	rw_saved_fire_sound = fire_sound
	rw_saved_fire_volume = fire_sound_volume
	if(rw_att_silenced)
		fire_sound = suppressed_sound
		fire_sound_volume = suppressed_volume
	else if(rw_fire_rattle && rw_is_low_ammo())
		fire_sound = rw_fire_rattle

/obj/item/gun/rimworld/proc/rw_fire_audio_end()
	fire_sound = rw_saved_fire_sound
	fire_sound_volume = rw_saved_fire_volume

// MARK: Muzzle flash

/obj/effect/abstract/rw_muzzle_flash
	name = "muzzle flash"
	icon = RW_ICON_MUZZLE_FLASH
	icon_state = "muzzle_bullet"

	layer = ABOVE_MOB_LAYER
	vis_flags = VIS_INHERIT_PLANE
	appearance_flags = RESET_COLOR|RESET_TRANSFORM|KEEP_APART

	var/applied = FALSE

/obj/effect/abstract/rw_muzzle_flash/Initialize(mapload, flash_state)
	. = ..()
	if(flash_state)
		icon_state = flash_state


/obj/effect/abstract/rw_muzzle_flash/proc/show(atom/movable/holder, duration = 0.2 SECONDS)
	holder.vis_contents += src
	applied = TRUE
	addtimer(CALLBACK(src, PROC_REF(hide), WEAKREF(holder)), duration)

/obj/effect/abstract/rw_muzzle_flash/proc/hide(datum/weakref/holder_ref)
	var/atom/movable/holder = holder_ref?.resolve()
	if(holder)
		holder.vis_contents -= src
	applied = FALSE

/obj/item/gun/rimworld/proc/rw_do_muzzle_flash(mob/living/user, angle)
	if(rw_muzzle_flash_lum > 0)
		new /obj/effect/dummy/lighting_obj(get_turf(user), rw_muzzle_flash_color, rw_muzzle_flash_lum, 1.5, 0.15 SECONDS)
	if(!rw_muzzle_flash_state)
		return
	if(!rw_muzzle_flash)
		rw_muzzle_flash = new(null, rw_muzzle_flash_state)
	if(rw_muzzle_flash.applied)
		return

	rw_muzzle_flash.pixel_x = round(sin(angle) * rw_muzzle_flash_radius) + rw_muzzle_flash_x_offset
	rw_muzzle_flash.pixel_y = round(cos(angle) * rw_muzzle_flash_radius) + rw_muzzle_flash_y_offset
	var/matrix/flash_matrix = matrix()
	flash_matrix.Turn(angle)
	rw_muzzle_flash.transform = flash_matrix
	rw_muzzle_flash.show(user)


/obj/item/gun/rimworld/proc/rw_calc_camera_recoil(mob/living/user)
	var/skill = rw_ranged_skill(user)
	var/manip = clamp(rw_manipulation(user), 0.2, 1)
	var/total = rw_camera_recoil + rw_att_camera_recoil
	total -= skill * rw_recoil_per_skill
	total += (1 - manip) * 3
	if(rw_fire_mode != RW_FIRE_SINGLE)
		total += 0.5
	total += min(rw_shots_in_row * 0.15, 1.5)
	return max(total, 0)

/obj/item/gun/rimworld/proc/rw_do_camera_recoil(mob/living/user, angle)
	var/strength = rw_calc_camera_recoil(user)
	if(strength >= 0.25)
		rw_recoil_camera(user, strength, angle)

/proc/rw_recoil_camera(mob/target, strength, angle)
	var/client/target_client = target?.client
	if(!target_client || strength <= 0)
		return
	var/pixels = clamp(round(strength * 1.5), 1, 12)
	var/push_angle = angle + 180 + rand(-22, 22)
	var/dx = round(sin(push_angle) * pixels)
	var/dy = round(cos(push_angle) * pixels)
	if(!dx && !dy)
		return
	var/back_time = clamp(round(strength * 2), 2, 8)
	animate(target_client, pixel_x = dx, pixel_y = dy, time = 1, easing = SINE_EASING|EASE_OUT, flags = ANIMATION_RELATIVE|ANIMATION_PARALLEL)
	animate(target_client, pixel_x = -dx, pixel_y = -dy, time = back_time, easing = SINE_EASING|EASE_IN, flags = ANIMATION_RELATIVE)


/proc/rw_flinch_animation(mob/living/target)
	var/dx = pick(-3, 3)
	var/dy = pick(-2, 0, 2)
	animate(target, pixel_x = dx, pixel_y = dy, time = 1, flags = ANIMATION_RELATIVE|ANIMATION_PARALLEL)
	animate(pixel_x = -dx, pixel_y = -dy, time = 2, flags = ANIMATION_RELATIVE)

/proc/rw_flash_color(mob/living/target, flash_color = "#ff7070", speed = 2)
	if(target.stat == DEAD)
		return
	var/old_color = target.color
	animate(target, color = flash_color, time = speed)
	animate(color = old_color, time = speed)


// MARK: Recoil
/datum/status_effect/rw_fire_recoil
	id = "rw_fire_recoil"
	duration = RW_FIRE_SLOWDOWN_DURATION
	status_type = STATUS_EFFECT_REFRESH
	alert_type = null
	tick_interval = STATUS_EFFECT_NO_TICK
	var/stacks = 1

/datum/status_effect/rw_fire_recoil/on_creation(mob/living/new_owner, starting_stacks = 1)
	stacks = clamp(starting_stacks, 1, RW_FIRE_SLOWDOWN_MAX)
	return ..()

/datum/status_effect/rw_fire_recoil/on_apply()
	. = ..()
	if(!.)
		return
	rw_update_movespeed()

/datum/status_effect/rw_fire_recoil/on_remove()
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/rw_fire_recoil)
	return ..()

/datum/status_effect/rw_fire_recoil/refresh(effect, starting_stacks = 1)
	stacks = min(stacks + 1, RW_FIRE_SLOWDOWN_MAX)
	duration = RW_FIRE_SLOWDOWN_DURATION
	rw_update_movespeed()

/datum/status_effect/rw_fire_recoil/proc/rw_update_movespeed()
	if(QDELETED(owner))
		return
	owner.add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/rw_fire_recoil, multiplicative_slowdown = RW_FIRE_SLOWDOWN * stacks)


/datum/movespeed_modifier/rw_fire_recoil
	variable = TRUE
	multiplicative_slowdown = RW_FIRE_SLOWDOWN
	id = MOVESPEED_ID_RW_FIRE_RECOIL
	priority = 100
