#ifndef OLD_COMBAT_SYSTEM
/**
 * Thrown items
 */
/mob/living/hitby(atom/movable/AM, skipcatch, hitpush = TRUE, blocked = FALSE, datum/thrownthing/throwingdatum)
	if(!isitem(AM))
		if(check_block(AM, 30, "\the [AM.name]", THROWN_PROJECTILE_ATTACK, 0, BRUTE) & SUCCESSFUL_BLOCK)
			hitpush = FALSE
			skipcatch = TRUE
			blocked = TRUE
			return SUCCESSFUL_BLOCK
		else
			playsound(loc, 'sound/items/weapons/genhit.ogg', 50, TRUE, -1)
			if(!isvendor(AM) && !iscarbon(AM))
				visible_message(span_danger("[src] is hit by [AM]!"), \
							span_userdanger("You're hit by [AM]!"))
		log_combat(AM, src, "hit ")
		return ..()

	var/obj/item/thrown_item = AM
	var/mob/thrown_by = throwingdatum?.get_thrower()

	if(thrown_by != src)
		if(check_block(AM, thrown_item.throwforce, "\the [thrown_item.name]", THROWN_PROJECTILE_ATTACK, 0, thrown_item.damtype))
			hitpush = FALSE
			skipcatch = TRUE
			blocked = TRUE

	var/zone = get_random_valid_zone(BODY_ZONE_CHEST, 65)
	var/nosell_hit = (SEND_SIGNAL(thrown_item, COMSIG_MOVABLE_IMPACT_ZONE, src, zone, blocked, throwingdatum) & MOVABLE_IMPACT_ZONE_OVERRIDE)
	if(nosell_hit)
		skipcatch = TRUE
		hitpush = FALSE

	if(blocked)
		return SUCCESSFUL_BLOCK

	if(nosell_hit)
		log_hit_combat(thrown_by, thrown_item)
		return ..()

	if(try_dodge(thrown_by, "\the [thrown_item]", THROWN_PROJECTILE_ATTACK))
		return SUCCESSFUL_BLOCK

	visible_message(span_danger("[src] is hit by [thrown_item]!"),
		span_userdanger("You're hit by [thrown_item]!"))
	if(!thrown_item.throwforce)
		log_hit_combat(thrown_by, thrown_item)
		return

	run_armor_check(
		zone,
		MELEE,
		"Your armor has protected your [parse_zone_with_bodypart(zone)].",
		"Your armor has softened hit to your [parse_zone_with_bodypart(zone)].",
		thrown_item.armour_penetration,
		"",
		FALSE,
		thrown_item.weak_against_armour,
	)

	var/damage_dealt = apply_damage(
		thrown_item.throwforce,
		thrown_item.damtype,
		zone,
		blocked = 0,
		sharpness = thrown_item.get_sharpness(),
		wound_bonus = (nosell_hit * CANT_WOUND),
		attacking_item = thrown_item,
	)

	if(damage_dealt > 0)
		apply_status_effect(/datum/status_effect/rw_melee_recoil, 1)

	log_hit_combat(thrown_by, thrown_item)

	if(QDELETED(src))
		return
	if(body_position == LYING_DOWN)
		hitpush = FALSE

	return ..()
#endif
