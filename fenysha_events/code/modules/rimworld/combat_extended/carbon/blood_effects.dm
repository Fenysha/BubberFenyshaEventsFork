#ifndef OLD_COMBAT_SYSTEM
/mob/living/carbon/update_blood_effects()
	. = ..()

	update_blood_pallor()
	update_blood_colorgrade()

/mob/living/carbon/proc/update_blood_pallor()
	if(!CAN_HAVE_BLOOD(src))
		set_blood_pallor(0)
		return

	var/blood_ratio = get_blood_ratio()

	var/pallor = 0
	if(blood_ratio < BLOOD_PALLOR_START)
		pallor = clamp(
			(BLOOD_PALLOR_START - blood_ratio) / (BLOOD_PALLOR_START - BLOOD_PALLOR_FULL),
			0,
			1
		)

	// Don't rebuild all bodypart overlays for microscopic changes.
	pallor = round(pallor, 0.025)

	if(abs(pallor - blood_pallor_visual) < 0.025)
		return

	blood_pallor_visual = pallor
	set_blood_pallor(pallor)

/mob/living/carbon/proc/set_blood_pallor(pallor)
	for(var/obj/item/bodypart/bodypart as anything in get_bodyparts())
		bodypart.remove_color_override(BLOOD_PALLOR_COLOR_PRIORITY)

		// Static-colored bodyparts don't have a greyscale draw color
		// that can safely be recolored through this mechanism.
		if(!bodypart.should_draw_greyscale)
			bodypart.update_limb()
			continue

		// Restore the original highest-priority color first.
		bodypart.update_draw_color()

		if(pallor <= 0)
			bodypart.update_limb()
			continue

		var/base_color = bodypart.draw_color

		if(!base_color)
			base_color = COLOR_WHITE

		var/pale_color = blend_color(
			base_color,
			rgb(255, 255, 255, round(pallor * 255))
		)

		bodypart.add_color_override(
			pale_color,
			BLOOD_PALLOR_COLOR_PRIORITY
		)

		bodypart.update_limb()

/mob/living/carbon/proc/update_blood_colorgrade()
	if(!hud_used)
		return

	if(!CAN_HAVE_BLOOD(src))
		apply_blood_colorgrade(0)
		return

	var/blood_ratio = get_blood_ratio()

	var/strength = 0
	if(blood_ratio < BLOOD_COLORGRADE_START)
		strength = clamp(
			(BLOOD_COLORGRADE_START - blood_ratio) / (BLOOD_COLORGRADE_START - BLOOD_COLORGRADE_FULL),
			0,
			1
		)

	strength = round(strength, 0.025)

	if(abs(strength - blood_colorgrade_visual) < 0.025)
		return

	blood_colorgrade_visual = strength
	apply_blood_colorgrade(strength)

/mob/living/carbon/proc/apply_blood_colorgrade(strength)
	if(!hud_used)
		return

	var/list/masters = hud_used.get_true_plane_masters(RENDER_PLANE_MASTER)

	for(var/atom/movable/screen/plane_master/rendering_plate/master as anything in masters)
		if(strength <= 0)
			master.remove_filter("blood_loss_colorgrade")
			continue

		/*
		 * HSL color grading:
		 *
		 * - Hue is untouched.
		 * - Saturation decreases as blood is lost.
		 * - Lightness increases slightly.
		 *
		 * This pushes the screen toward white/grey without turning
		 * red objects into neutral grey.
		 */
		var/saturation = 1 - (0.65 * strength)
		var/lightness = 1 + (0.10 * strength)

		var/matrix/matrix = list(
			1, 0, 0,
			0, saturation, 0,
			0, 0, lightness,
			0, 0, 0
		)

		master.add_filter("blood_loss_colorgrade", 10, color_matrix_filter(matrix, FILTER_COLOR_HSL))

/mob/living/carbon/proc/append_blood_loss_examine(mob/user, list/examine_list)
	if(!user || !CAN_HAVE_BLOOD(src))
		return

	var/blood_ratio = get_blood_ratio()

	switch(blood_ratio)
		if(BLOOD_PALLOR_START to INFINITY)
			return

		if(0.65 to BLOOD_PALLOR_START)
			examine_list += span_warning("[p_They()] look pale.")
		if(0.50 to 0.65)
			examine_list += span_warning("[p_They()] look pale and clammy.")
		if(0.35 to 0.50)
			examine_list += span_danger("[p_They()] are extremely pale and visibly weakened.")
		if(-INFINITY to 0.35)
			examine_list += span_userdanger("[p_They()] are deathly pale, with almost no color left in [p_their()] skin.")
#endif

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
