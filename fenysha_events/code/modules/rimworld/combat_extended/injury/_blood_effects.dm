/**
 * Mob-side visual helpers. Every direct engine call for blood visuals lives here,
 * so if your tree differs (blood decal refactors, etc.) this is the only file to touch.
 */

/// Blood splatter decal on a turf (uses the stock floor-splatter proc).
/mob/living/carbon/proc/ce_splatter_at(turf/target, small = FALSE)
	if(!isturf(target) || isspaceturf(target) || !CAN_HAVE_BLOOD(src))
		return
	add_splatter_floor(target, small)

/// Throws blood in a straight line: decals on every open tile, blood on anyone in the way,
/// and on the first obstacle it hits.
/mob/living/carbon/proc/ce_spray_blood(direction, distance = 2, small = FALSE)
	var/turf/origin = get_turf(src)
	if(!origin || !direction || !CAN_HAVE_BLOOD(src))
		return
	ce_splatter_at(origin, small)
	var/turf/far = get_ranged_target_turf(origin, direction, distance)
	if(!far)
		return
	for(var/turf/line_turf as anything in get_line(origin, far))
		if(line_turf == origin)
			continue
		if(line_turf.density || line_turf.is_blocked_turf(exclude_mobs = TRUE))
			line_turf.add_mob_blood(src)
			return
		ce_splatter_at(line_turf, small)
		for(var/mob/living/victim in line_turf)
			victim.add_mob_blood(src)

/mob/living/carbon/proc/ce_gib_splatter()
	var/turf/here = get_turf(src)
	if(!here || isspaceturf(here) || !CAN_HAVE_BLOOD(src))
		return
	new /obj/effect/decal/cleanable/blood/gibs(here)

/// Coughing up blood (haemothorax / lung trauma).
/mob/living/carbon/proc/ce_cough_blood()
	visible_message(span_danger("[src] coughs up a spray of blood!"), span_userdanger("You cough up blood!"))
	ce_splatter_at(get_turf(src))
	var/turf/front = get_step(src, dir)
	if(front && !front.density)
		ce_splatter_at(front, TRUE)
	adjust_blood_volume(-1)
