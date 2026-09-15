#define KHARA_SMOKE_RANGE 3
#define KHARA_SMOKE_AMOUNT 25

#define KHARA_SHOT_DELAY (0.35 SECONDS)

#define KHARA_LINE_SPACING 2
#define KHARA_MAX_LINE_SPREAD 8


/obj/projectile/khara_fog
	name = "khara fog sphere"
	icon_state = "leaper"

	speed = 2
	range = 16
	layer = LARGE_MOB_LAYER
	can_hit_turfs = TRUE

	var/smoke_range = KHARA_SMOKE_RANGE
	var/smoke_amount = KHARA_SMOKE_AMOUNT


/obj/projectile/khara_fog/on_hit(atom/target, blocked, pierce_hit)
	if(isliving(target))
		var/mob/living/living = target
		living.apply_damage(50, BRUTE, CHEST)
		living.Knockdown(30)
		living.Stun(10)
	var/turf/impact_turf = get_turf(target)
	if(!impact_turf)
		return ..()

	playsound(
		impact_turf,
		'sound/effects/splat.ogg',
		50,
		TRUE,
		extrarange = SILENCED_SOUND_EXTRARANGE
	)

	do_chem_smoke(smoke_range, src, get_turf(src), /datum/reagent/toxin/khara, 10, log = FALSE, amount = smoke_amount, smoke_type = /datum/effect_system/fluid_spread/smoke/chem/khara)
	for(var/turf/T in circle_range(impact_turf, 1))
		new /obj/effect/decal/cleanable/blood(T)
	. = ..()


/datum/action/cooldown/mob_cooldown/khara_fog
	name = "Khara Fog"
	desc = "Launch a sphere of Khara fog at a targeted location."

	button_icon = 'icons/mob/simple/lavaland/lavaland_monsters.dmi'
	button_icon_state = "goliath_baby"
	background_icon_state = "bg_alien"
	overlay_icon_state = "bg_alien_border"

	click_to_activate = TRUE
	cooldown_time = 13 SECONDS
	melee_cooldown_time = 0
	shared_cooldown = NONE

	var/obj/projectile/khara_fog/projectile_type = /obj/projectile/khara_fog
	/// Amount of fog spheres fired.
	var/shots = 1
	/// Distance between consecutive impact points.
	var/line_spacing = KHARA_LINE_SPACING
	/// Maximum total length of the barrage.
	var/max_line_spread = KHARA_MAX_LINE_SPREAD
	/// Delay between shots.
	var/shot_delay = KHARA_SHOT_DELAY
	/// Max shoot range
	var/max_range = 15
	/// Delay before shot
	var/delay = 3 SECONDS

/datum/action/cooldown/mob_cooldown/khara_fog/PreActivate(atom/target)
	if(!can_see(owner, target, max_range))
		owner.balloon_alert(owner, "Can't shot here!")
		return
	return ..()

/datum/action/cooldown/mob_cooldown/khara_fog/Activate(atom/target)
	if(QDELETED(target) || QDELETED(owner))
		return
	INVOKE_ASYNC(src, PROC_REF(launch_fog), target)
	. = ..()


/datum/action/cooldown/mob_cooldown/khara_fog/proc/create_fog_telegraph(turf/center, range)
	if(!center)
		return

	for(var/turf/T in circle_range(center, range))
		new /obj/effect/temp_visual/telegraphing/boss_hit(T)

/datum/action/cooldown/mob_cooldown/khara_fog/proc/get_line_impact(
	turf/target,
	turf/origin,
	index
)
	if(shots <= 1)
		return target

	var/direction = get_dir(origin, target)

	if(!direction)
		return target

	// We want the spread to be perpendicular
	// to the direction towards the target.
	var/perpendicular

	switch(direction)
		if(NORTH, SOUTH)
			perpendicular = EAST
		if(EAST, WEST)
			perpendicular = NORTH
		else
			perpendicular = turn(direction, 90)

	var/center_index = (shots + 1) / 2
	var/offset = round((index - center_index) * line_spacing)

	var/turf/result = target

	if(abs(offset) > max_line_spread)
		offset = clamp(
			offset,
			-max_line_spread,
			max_line_spread
		)

	if(offset > 0)
		for(var/i = 1 to offset)
			var/turf/next = get_step(result, perpendicular)

			if(!next)
				break

			result = next

	else if(offset < 0)
		for(var/i = 1 to abs(offset))
			var/turf/next = get_step(result, turn(perpendicular, 180))

			if(!next)
				break

			result = next

	return result

/datum/action/cooldown/mob_cooldown/khara_fog/proc/launch_fog(turf/target)
	var/turf/origin = get_turf(owner)


	var/message = "[owner] launches [shots > 1 ? "a barrage of" : "a"] Khara fog sphere[shots > 1 ? "s" : ""]!"
	var/self_message = "You launch [shots > 1 ? "a barrage of" : "a"] Khara fog sphere[shots > 1 ? "s" : ""]!"
	owner.visible_message(span_danger(message), span_userdanger(self_message))
	if(!do_after(owner, delay, owner))
		owner.balloon_alert(owner, "Failed to shot!")
		return

	for(var/i = 1 to shots)
		if(QDELETED(owner))
			return

		var/turf/impact = get_line_impact(
			target,
			origin,
			i
		)

		if(!impact)
			continue

		// Telegraph the entire future fog area.
		var/obj/projectile/khara_fog/shell = new projectile_type(origin)
		create_fog_telegraph(impact, shell.smoke_range)
		shell.aim_projectile(impact, owner)

		INVOKE_ASYNC(shell, TYPE_PROC_REF(/obj/projectile, fire))

		if(i < shots)
			sleep(shot_delay)


/datum/action/cooldown/mob_cooldown/khara_fog/extreme
	shots = 8
	delay = 1 SECONDS
	line_spacing = KHARA_LINE_SPACING + 1
	cooldown_time = 40 SECONDS
