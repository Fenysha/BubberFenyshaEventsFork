#define ARTILLERY_ASCEND_TIME (1.5 SECONDS)
#define ARTILLERY_DESCEND_TIME (0.5 SECONDS)

#define ARTILLERY_ASCEND_HEIGHT 256

#define ARTILLERY_IMPACT_RADIUS 1
#define ARTILLERY_DIRECT_DAMAGE 60
#define ARTILLERY_AOE_DAMAGE 30

/obj/projectile/mutant_artillery
	name = "blood artillery shell"
	icon_state = "blastwave"

	speed = 0
	range = 0
	can_hit_turfs = FALSE
	layer = LARGE_MOB_LAYER

	var/impact_radius = ARTILLERY_IMPACT_RADIUS
	var/direct_damage = ARTILLERY_DIRECT_DAMAGE
	var/aoe_damage = ARTILLERY_AOE_DAMAGE

	var/direct_knockdown = 4 SECONDS
	var/direct_paralyze = 2 SECONDS

	var/turf/impact_turf
	var/is_descending = FALSE
	var/is_ascending = FALSE


/obj/projectile/mutant_artillery/Initialize(mapload)
	. = ..()
	is_descending = FALSE


/obj/projectile/mutant_artillery/can_hit_target(atom/target, direct_target, ignore_loc, cross_failed)
	if(!is_descending || is_ascending)
		return FALSE
	return ..()


/obj/projectile/mutant_artillery/proc/launch_upwards(turf/target)
	if(!target || QDELETED(src))
		return

	impact_turf = target
	is_ascending = TRUE
	// Launch upward without rotating.
	animate(
		src,
		pixel_y = ARTILLERY_ASCEND_HEIGHT,
		transform = matrix(0.25, MATRIX_SCALE),
		alpha = 0,
		time = ARTILLERY_ASCEND_TIME,
		easing = SINE_EASING,
		flags = ANIMATION_PARALLEL,
	)
	sleep(ARTILLERY_ASCEND_TIME)
	is_ascending = FALSE
	forceMove(target)
	if(QDELETED(src))
		return

	// Briefly remain above the battlefield.
	sleep(0.5 SECONDS)

	if(QDELETED(src))
		return

	// Begin descending.
	is_descending = TRUE

	var/matrix/descending_transform = matrix(180, MATRIX_ROTATE)
	descending_transform.Scale(1.5, 1.5)

	animate(
		src,
		pixel_y = 0,
		transform = descending_transform,
		alpha = 255,
		time = ARTILLERY_DESCEND_TIME,
		easing = QUAD_EASING,
		flags = ANIMATION_PARALLEL,
	)

	sleep(ARTILLERY_DESCEND_TIME)

	if(QDELETED(src))
		return

	impact()


/obj/projectile/mutant_artillery/impact()
	var/turf/impact = impact_turf

	if(!impact)
		qdel(src)
		return

	playsound(impact, 'sound/effects/splat.ogg', 80, TRUE)
	// Blood splash around the impact point.
	for(var/turf/T in range(impact_radius, impact))
		new /obj/effect/decal/cleanable/blood(T)

	for(var/mob/living/L in range(impact_radius, impact))
		if(L.incorporeal_move)
			continue

		var/dist = get_dist(L, impact)

		if(dist <= 1)
			// Direct hit.
			L.apply_damage(
				direct_damage,
				BRUTE,
				BODY_ZONE_CHEST
			)

			L.Knockdown(direct_knockdown)
			L.Paralyze(direct_paralyze)
			shake_camera(L, 5, 1)

			L.visible_message(
				span_danger("[L] is crushed by a falling mass of flesh!"),
				span_userdanger("A massive projectile slams into you!")
			)

		else
			// Area damage.
			var/damage = max(1, aoe_damage - (dist * 3))
			L.apply_damage(damage, BRUTE, BODY_ZONE_CHEST)
			L.Knockdown(1 SECONDS)
	qdel(src)


/datum/action/cooldown/mob_cooldown/artillery
	name = "Blood Artillery"
	desc = "Launch projectiles into the sky, causing them to rain down on a targeted area."

	button_icon = 'icons/mob/simple/lavaland/lavaland_monsters.dmi'
	button_icon_state = "goliath_baby"
	background_icon_state = "bg_alien"
	overlay_icon_state = "bg_alien_border"

	click_to_activate = TRUE
	cooldown_time = 10 SECONDS
	melee_cooldown_time = 0
	shared_cooldown = NONE

	var/projectile_type = /obj/projectile/mutant_artillery
	/// Number of shells fired.
	var/shots = 1
	/// Maximum base spread in tiles.
	var/base_spread = 0
	/// Delay between individual launches.
	var/shot_delay = 0.3 SECONDS
	/// Additional accuracy penalty for multiple shots.
	/// Higher values make large barrages less accurate.
	var/spread_per_extra_shot = 0.5

	var/min_range = 3
	var/max_distance = 20

/datum/action/cooldown/mob_cooldown/artillery/PreActivate(atom/target)
	if(get_dist(target, owner) < min_range)
		owner.balloon_alert(owner, "To close!")
		return FALSE
	var/area/own_area = get_area(owner)
	var/area/target_area = get_area(target)
	if(target_area.outdoors != own_area.outdoors)
		owner.balloon_alert(owner, "Can't shoot here!")
		return FALSE
	if(!can_see(owner, target, max_distance))
		owner.balloon_alert(owner, "Can't shoot here!")
		return FALSE
	return ..()

/datum/action/cooldown/mob_cooldown/artillery/Activate(atom/target)
	target = get_turf(target)

	if(!target)
		return FALSE

	. = ..()
	INVOKE_ASYNC(src, PROC_REF(fire_artillery), target)
	return TRUE


/datum/action/cooldown/mob_cooldown/artillery/proc/get_spread()
	if(shots <= 1)
		return base_spread

	return round(base_spread + ((shots - 1) * spread_per_extra_shot))


/datum/action/cooldown/mob_cooldown/artillery/proc/get_impact_turf(turf/target)
	var/spread = get_spread()

	if(!spread)
		return target

	var/offset_x = rand(-spread, spread)
	var/offset_y = rand(-spread, spread)

	return locate(
		target.x + offset_x,
		target.y + offset_y,
		target.z
	)


/datum/action/cooldown/mob_cooldown/artillery/proc/fire_artillery(turf/target)
	owner.visible_message(
		span_danger("[owner] launches a barrage of massive projectiles into the air!"),
		span_userdanger("You launch [shots] projectile\s into the sky!")
	)

	playsound(owner, 'sound/effects/explosion/explosionfar.ogg', 20, TRUE)

	for(var/i = 1 to shots)
		if(QDELETED(owner))
			return

		var/turf/impact = get_impact_turf(target)

		if(!impact)
			continue

		new /obj/effect/temp_visual/telegraphing/boss_hit/aoe(impact)

		var/obj/projectile/mutant_artillery/shell = new projectile_type(get_turf(owner))
		shell.firer = owner

		INVOKE_ASYNC(shell, TYPE_PROC_REF(/obj/projectile/mutant_artillery, launch_upwards), impact)

		if(i < shots)
			sleep(shot_delay)


/datum/action/cooldown/mob_cooldown/artillery/multi
	shots = 8
