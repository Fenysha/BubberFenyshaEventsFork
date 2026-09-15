
/datum/action/cooldown/mob_cooldown/boss_charge
	name = "Charge"
	desc = "Charge towards a targeted location, dealing heavy damage on impact."
	button_icon = 'icons/mob/simple/lavaland/lavaland_monsters.dmi'
	button_icon_state = "goliath_baby"
	background_icon_state = "bg_alien"
	overlay_icon_state = "bg_alien_border"
	click_to_activate = TRUE
	cooldown_time = 12 SECONDS
	melee_cooldown_time = 0
	shared_cooldown = NONE

	var/max_range = 10
	var/charge_sound = 'fenysha_events/sounds/mobs/mutant_boss_attack_01.ogg'
	var/charge_delay = 5

/datum/action/cooldown/mob_cooldown/boss_charge/PreActivate(atom/target)
	target = get_turf(target)
	if (get_dist(owner, target) > max_range)
		return FALSE
	return ..()

/datum/action/cooldown/mob_cooldown/boss_charge/Activate(atom/target)
	var/dist = get_dist(owner, target) - 1
	if(dist <= 1)
		owner.balloon_alert(owner, "To close!")
		return
	INVOKE_ASYNC(src, PROC_REF(do_charge), get_turf(target))
	StartCooldown()
	return TRUE

/datum/action/cooldown/mob_cooldown/boss_charge/proc/do_charge(turf/target)
	owner.visible_message(span_danger("[owner] charges towards [target]!"))
	if(charge_delay)
		new /obj/effect/temp_visual/telegraphing/boss_hit(target)
		if(!do_after(owner, charge_delay))
			owner.balloon_alert(owner, "Interupted!")
	if(charge_sound)
		playsound(owner, charge_sound, 40)
	var/dist = get_dist(owner, target) - 1
	for(var/i = 1 to dist)
		if(get_dist(owner, target) <= 1)
			break
		new /obj/effect/temp_visual/decoy/fading/halfsecond(owner.loc, owner)
		owner.forceMove(get_step_towards(owner, target))

	for(var/mob/living/living_target in target.contents)
		if(get_dist(owner, living_target) <= 1)
			var/damage = rand(20, 30)
			if(!(living_target.check_block(owner, damage, armour_penetration = 50) == SUCCESSFUL_BLOCK))
				living_target.take_bodypart_damage(damage)
				living_target.Knockdown(10)
				shake_camera(living_target)
	playsound(owner, 'sound/effects/blob/blobattack.ogg', 100, TRUE)

/datum/action/cooldown/mob_cooldown/boss_charge/weak
	max_range = 6
	charge_delay = 1 SECONDS



#define ZIGZAG_CHARGE_MAX_RANGE 10
#define ZIGZAG_CHARGE_STEPS 5
#define ZIGZAG_CHARGE_STEP_DISTANCE 2
#define ZIGZAG_CHARGE_STEP_DELAY (0.15 SECONDS)

#define ZIGZAG_CHARGE_DAMAGE_MIN 15
#define ZIGZAG_CHARGE_DAMAGE_MAX 25
#define ZIGZAG_CHARGE_KNOCKDOWN (2 SECONDS)

/datum/action/cooldown/mob_cooldown/zigzag_charge
	name = "Zigzag Charge"
	desc = "Perform a series of rapid charges towards a targeted location, weaving from side to side."

	button_icon = 'icons/mob/simple/lavaland/lavaland_monsters.dmi'
	button_icon_state = "goliath_baby"
	background_icon_state = "bg_alien"
	overlay_icon_state = "bg_alien_border"

	click_to_activate = TRUE
	cooldown_time = 8 SECONDS
	melee_cooldown_time = 0
	shared_cooldown = NONE

	var/max_range = ZIGZAG_CHARGE_MAX_RANGE
	var/charge_steps = ZIGZAG_CHARGE_STEPS
	var/step_distance = ZIGZAG_CHARGE_STEP_DISTANCE
	var/step_delay = ZIGZAG_CHARGE_STEP_DELAY

	var/charge_sound = 'fenysha_events/sounds/mobs/mutant_boss_attack_01.ogg'


/datum/action/cooldown/mob_cooldown/zigzag_charge/PreActivate(atom/target)
	target = get_turf(target)

	if(!target)
		return FALSE

	if(get_dist(owner, target) > max_range)
		return FALSE

	return ..()


/datum/action/cooldown/mob_cooldown/zigzag_charge/Activate(atom/target)
	target = get_turf(target)

	if(!target)
		return FALSE

	if(get_dist(owner, target) <= 1)
		owner.balloon_alert(owner, "Too close!")
		return FALSE

	. = ..()

	INVOKE_ASYNC(src, PROC_REF(do_charge), target)
	StartCooldown()

	return TRUE


/datum/action/cooldown/mob_cooldown/zigzag_charge/proc/do_charge(turf/target)
	if(!owner || QDELETED(owner))
		return

	owner.visible_message(
		span_danger("[owner] begins a violent zigzag charge!")
	)

	new /obj/effect/temp_visual/telegraphing/boss_hit(target)

	if(charge_sound)
		playsound(owner, charge_sound, 60, TRUE)

	for(var/i = 1 to charge_steps)
		if(!owner || QDELETED(owner))
			return

		var/turf/current = get_turf(owner)

		if(!current)
			return

		var/turf/charge_target

		// The final charge always goes directly toward the target.
		if(i == charge_steps)
			charge_target = target
		else
			var/direction = get_dir(current, target)

			if(!direction)
				break

			var/turf/forward = get_ranged_target_turf(
				current,
				direction,
				step_distance
			)

			if(!forward)
				break

			// Alternate between left and right.
			var/side_direction

			if(i % 2)
				side_direction = turn(direction, 90)
			else
				side_direction = turn(direction, -90)

			charge_target = get_step(
				forward,
				side_direction
			)

			if(!charge_target)
				charge_target = forward

		perform_charge(charge_target)

		if(get_dist(owner, target) <= 1)
			break

		if(i < charge_steps)
			sleep(step_delay)


/datum/action/cooldown/mob_cooldown/zigzag_charge/proc/perform_charge(turf/target)
	if(!owner || QDELETED(owner) || !target)
		return

	var/turf/start = get_turf(owner)

	if(!start)
		return

	new /obj/effect/temp_visual/decoy/fading/halfsecond(start, owner)

	owner.forceMove(target)

	for(var/mob/living/living_target in range(1, target))
		if(living_target == owner)
			continue

		if(living_target.stat == DEAD)
			continue

		var/damage = rand(
			ZIGZAG_CHARGE_DAMAGE_MIN,
			ZIGZAG_CHARGE_DAMAGE_MAX
		)

		if(living_target.check_block(owner, damage, armour_penetration = 50) == SUCCESSFUL_BLOCK)
			continue

		living_target.take_bodypart_damage(damage)
		living_target.Knockdown(ZIGZAG_CHARGE_KNOCKDOWN)
		shake_camera(living_target)

		living_target.visible_message(
			span_danger("[living_target] is struck by [owner]!"),
			span_userdanger("You are struck by [owner]!")
		)
