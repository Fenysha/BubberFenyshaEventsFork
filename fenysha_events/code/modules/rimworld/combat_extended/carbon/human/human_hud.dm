#ifndef OLD_COMBAT_SYSTEM
/atom/movable/screen/healthdoll/human
	mouse_over_pointer = MOUSE_HAND_POINTER
	VAR_PRIVATE/list/atom/movable/screen/limbs
	VAR_PRIVATE/list/animated_zones

/atom/movable/screen/healthdoll/human/Initialize(mapload, datum/hud/hud_owner)
	. = ..()
	if(isnull(hud_owner))
		return
	update_body_zones()
	update_appearance()

/atom/movable/screen/healthdoll/human/update_body_zones()
	vis_contents.Cut()
	QDEL_LIST_ASSOC_VAL(limbs)
	limbs ||= list()
	var/mob/living/carbon/human/owner = hud.mymob
	for(var/body_zone in owner.get_all_limbs())
		var/atom/movable/screen/healthdoll_limb/limb = new(src, null)
		limb.layer = body_zone == BODY_ZONE_CHEST ? layer + 0.05 : layer
		limbs[body_zone] = limb
		vis_contents += limb

/atom/movable/screen/healthdoll/human/Destroy()
	QDEL_LIST_ASSOC_VAL(limbs)
	vis_contents.Cut()
	return ..()


/atom/movable/screen/healthdoll/human/proc/pain_to_icon_key(pain_amount)
	if(pain_amount <= 0)
		return 0
	if(pain_amount < BODY_PART_PAIN_HUD_MINOR)
		return 1
	if(pain_amount < BODY_PART_PAIN_HUD_MODERATE)
		return 2
	if(pain_amount < BODY_PART_PAIN_HUD_SEVERE)
		return 3
	if(pain_amount < BODY_PART_PAIN_HUD_CRITICAL)
		return 4
	return 5

/**
 * Returns the pain contribution of a bodypart for the healthdoll.
 * Uses bodypart.current_pain when present; otherwise sums injury pain.
 */
/atom/movable/screen/healthdoll/human/proc/get_limb_pain(obj/item/bodypart/body_part)
	if(isnull(body_part))
		return 0

	if(!isnull(body_part.current_pain))
		return body_part.current_pain

	var/total = 0
	for(var/datum/injury/injury as anything in body_part.injuries)
		total += injury.get_pain()
	return total


/atom/movable/screen/healthdoll/human/proc/limb_should_animate(obj/item/bodypart/body_part)
	if(isnull(body_part) || !length(body_part.injuries))
		return FALSE

	for(var/datum/injury/injury as anything in body_part.injuries)
		if(injury.get_pain() > 0 || injury.get_bleed_rate() > 0)
			return TRUE
		if(!injury.treatment_quality && injury.severity >= INJURY_SEVERITY_MODERATE)
			return TRUE

	return FALSE

/atom/movable/screen/healthdoll/human/update_icon_state()
	. = ..()
	var/mob/living/carbon/human/owner = hud?.mymob
	if(isnull(owner))
		return

	if(owner.stat == DEAD)
		for(var/limb in limbs)
			limbs[limb].icon_state = "[limb]DEAD"
		return

	var/list/current_animated = LAZYLISTDUPLICATE(animated_zones)

	for(var/part_zone, body_part_untyped in owner.get_bodyparts_by_zones())
		if(!limbs[part_zone])
			continue

		var/icon_key = 0
		var/obj/item/bodypart/body_part = body_part_untyped
		var/list/overridable_key = list(icon_key)

		if(isnull(body_part) || IS_STUMP(body_part))
			icon_key = 6
		else if(body_part.bodypart_disabled)
			icon_key = 7
		else if(owner.stat == DEAD)
			icon_key = "DEAD"
		else if(SEND_SIGNAL(body_part, COMSIG_BODYPART_UPDATING_HEALTH_HUD, owner, overridable_key) & OVERRIDE_BODYPART_HEALTH_HUD)
			icon_key = overridable_key[1]
		else if(!owner.has_status_effect(/datum/status_effect/grouped/screwy_hud/fake_healthy))
			icon_key = pain_to_icon_key(get_limb_pain(body_part))

		if(limb_should_animate(body_part))
			LAZYSET(animated_zones, part_zone, TRUE)
		else
			LAZYREMOVE(animated_zones, part_zone)

		limbs[part_zone].icon_state = "[part_zone][icon_key]"

	if(animated_zones ~! current_animated)
		for(var/animated_zone in animated_zones)
			var/atom/wounded_zone = limbs[animated_zone]
			var/existing_filter = wounded_zone.get_filter("wound_outline")
			if(existing_filter)
				animate(existing_filter)
			else
				wounded_zone.add_filter("wound_outline", 1, list("type" = "outline", "color" = "#FF0033", "alpha" = 0, "size" = 1.2))
				existing_filter = wounded_zone.get_filter("wound_outline")
			animate(existing_filter, alpha = 200, time = 1.5 SECONDS, loop = -1)
			animate(alpha = 0, time = 1.5 SECONDS)

		if(LAZYLEN(current_animated))
			for(var/lost_zone in current_animated - animated_zones)
				limbs[lost_zone].remove_filter("wound_outline")

/atom/movable/screen/healthdoll_limb
	screen_loc = ui_living_healthdoll
	vis_flags = VIS_INHERIT_ID | VIS_INHERIT_PLANE
#endif
