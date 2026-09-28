/obj/item/bodypart
	/// Sharp tissue density (mm RHA) — reduces AP after this layer takes damage
	var/density_sharp = BODYPART_DENSITY_SHARP_DEFAULT
	/// Blunt tissue density (MPa)
	var/density_blunt = BODYPART_DENSITY_BLUNT_DEFAULT

	/// Natural armor on this part (carapace etc.), same units as clothing
	var/natural_sharp_armor = 0
	var/natural_blunt_armor = 0

	var/list/injuries
	var/injury_damage_multiplier = 1.0
	var/current_pain = 0

/obj/item/bodypart/proc/update_injuries(replaced = FALSE)
	var/new_multiplier = 1.0
	var/new_pain = 0

	for(var/datum/injury/injury as anything in injuries)
		new_multiplier *= injury.get_damage_multiplier()
		new_pain += injury.get_pain()

	injury_damage_multiplier = min(new_multiplier, MAX_INJURY_DAMAGE_MULTIPLIER)
	current_pain = new_pain

	if(owner)
		owner.update_pain_from_limb(src)

	refresh_bleed_rate()

/**
 * Returns existing injury on this limb with the given series, or null.
 */
/obj/item/bodypart/proc/find_injury_series(series_id)
	for(var/datum/injury/injury as anything in injuries)
		if(injury.series == series_id)
			return injury
	return null

/obj/item/bodypart/proc/has_injury_type(injury_type)
	for(var/datum/injury/injury as anything in injuries)
		if(injury.type == injury_type)
			return TRUE
	return FALSE

/obj/item/bodypart/proc/try_generate_injuries(brute, burn, sharpness, attack_direction, damage_source, wound_bonus = 0, exposed_wound_bonus = 0)
	if(wound_bonus == CANT_WOUND)
		return
	if(!is_woundable())
		return
	if(length(injuries) >= MAX_INJURIES_PER_LIMB)
		return

	var/total_damage = brute + burn
	if(total_damage < 5)
		return

	var/injury_type

	if(burn > brute && burn >= 8)
		if(burn >= 25)
			injury_type = /datum/injury/burn/critical
		else if(burn >= 14)
			injury_type = /datum/injury/burn/severe
		else
			injury_type = /datum/injury/burn
	else if(brute >= 8)
		if(sharpness & SHARP_EDGED)
			if(brute >= 22)
				injury_type = /datum/injury/laceration/critical
			else if(brute >= 13)
				injury_type = /datum/injury/laceration/severe
			else
				injury_type = /datum/injury/laceration
		else if(sharpness & SHARP_POINTY)
			injury_type = /datum/injury/puncture
		else
			if(brute >= 18 && prob(40))
				injury_type = /datum/injury/fracture
			else if(brute >= 12)
				injury_type = /datum/injury/contusion/severe
			else
				injury_type = /datum/injury/contusion

	if(!injury_type)
		return

	var/datum/injury/new_injury = new injury_type()
	// apply_to_limb handles series upgrade / absorb
	new_injury.apply_to_limb(src, attack_direction = attack_direction, source = damage_source)



#ifndef OLD_COMBAT_SYSTEM
/**
 * called when a bodypart is taking damage
 * Damage will not exceed max_damage using this proc, and negative damage cannot be used to heal
 * Returns TRUE if damage icon states changes
 * Args:
 * brute - The amount of brute damage dealt.
 * burn - The amount of burn damage dealt.
 * blocked - The amount of damage blocked by armor.
 * updating_health - Whether to update the owner's health from receiving the hit.
 * required_bodytype - A bodytype flag requirement to get this damage (ex: BODYTYPE_ORGANIC)
 * wound_bonus - Legacy, используется только для проверки CANT_WOUND.
 * exposed_wound_bonus - Legacy, не используется.
 * wound_clothing - Legacy, не используется.
 * sharpness - Flag on whether the attack is edged or pointy
 * attack_direction - The direction the bodypart is attacked from.
 * damage_source - The source of damage, typically a weapon.
 */
/obj/item/bodypart/proc/receive_damage(
	brute = 0,
	burn = 0,
	blocked = 0,
	updating_health = TRUE,
	forced = FALSE,
	required_bodytype = null,
	wound_bonus = 0,
	exposed_wound_bonus = 0,
	sharpness = NONE,
	attack_direction = null,
	damage_source,
	wound_clothing = TRUE
)
	SHOULD_CALL_PARENT(TRUE)

	var/hit_percent = forced ? 1 : (100 - blocked) / 100
	if((!brute && !burn) || hit_percent <= 0)
		return FALSE

	if(!forced)
		if(!isnull(owner))
			if(HAS_TRAIT(owner, TRAIT_GODMODE))
				return FALSE
			if(SEND_SIGNAL(owner, COMSIG_CARBON_LIMB_DAMAGED, src, brute, burn) & COMPONENT_PREVENT_LIMB_DAMAGE)
				return FALSE
		if(required_bodytype && !(bodytype & required_bodytype))
			return FALSE

	var/dmg_multi = CONFIG_GET(number/damage_multiplier) * hit_percent
	brute = round(max(brute * dmg_multi * brute_modifier * injury_damage_multiplier, 0), DAMAGE_PRECISION)
	burn = round(max(burn * dmg_multi * burn_modifier * injury_damage_multiplier, 0), DAMAGE_PRECISION)

	if(!brute && !burn)
		return FALSE

	if(owner)
		var/obj/item/stack/medical/wrap/current_gauze = LAZYACCESS(applied_items, LIMB_ITEM_GAUZE)
		if(istype(current_gauze, /obj/item/stack/medical/wrap/gauze))
			var/obj/item/stack/medical/wrap/gauze/our_gauze = current_gauze
			our_gauze.get_hit(src)
		try_generate_injuries(brute, burn, sharpness, attack_direction, damage_source, wound_bonus, exposed_wound_bonus)

	var/can_inflict = max_damage - get_damage()
	var/total_damage = brute + burn
	if(total_damage > can_inflict && total_damage > 0)
		brute = round(brute * (can_inflict / total_damage), DAMAGE_PRECISION)
		burn = round(burn * (can_inflict / total_damage), DAMAGE_PRECISION)

	if(can_inflict <= 0)
		return FALSE

	if(brute)
		set_brute_dam(brute_dam + brute)
	if(burn)
		set_burn_dam(burn_dam + burn)

	if(owner)
		if(can_be_disabled)
			update_disabled()
		if(updating_health)
			owner.updatehealth()

	return update_bodypart_damage_state()


/obj/item/bodypart/proc/dismemberable_by_total_damage()
	update_wound_theory()

	var/has_interior = (bio_status & ANATOMY_INTERIOR)
	var/can_theoretically_be_dismembered_by_wound = (any_existing_wound_can_mangle_our_interior || (any_existing_wound_can_mangle_our_exterior && has_interior))

	if (use_alternate_dismemberment_calc_even_if_mangleable || (!dismemberable_by_wound() && !can_theoretically_be_dismembered_by_wound))
		var/percent_to_total_max = (get_damage() / max_damage)
		if (percent_to_total_max >= hp_percent_to_dismemberable)
			return TRUE

	return FALSE
#endif


/**
 * Applies already-resolved penetration packet to this limb, then density + organs.
 */
/obj/item/bodypart/proc/take_penetrating_hit(list/packet, sharpness = NONE, wound_bonus = 0, attack_direction, damage_source)
	if(!packet || !owner)
		return

	var/dealt = packet["limb_damage"]
	var/damage_type = packet["damage_type"]

	if(dealt > 0)
		var/brute = (damage_type == BRUTE) ? dealt : 0
		var/burn = (damage_type == BURN) ? dealt : 0
		receive_damage(
			brute = brute,
			burn = burn,
			blocked = 0,
			forced = TRUE,
			wound_bonus = wound_bonus,
			sharpness = sharpness,
			attack_direction = attack_direction,
			damage_source = damage_source,
		)

	pen_apply_body_density(packet, density_sharp, density_blunt)

	if(pen_can_penetrate_deeper(packet))
		damage_organs_from_packet(packet)


/obj/item/bodypart/proc/damage_organs_from_packet(list/packet)
	var/list/candidates = list()
	for(var/obj/item/organ/O in src)
		if(O.organ_flags & ORGAN_EXTERNAL)
			continue
		candidates += O
	if(!length(candidates))
		return

	var/obj/item/organ/target = pick(candidates)
	var/organ_damage = packet["damage"] * 0.5
	if(organ_damage < 0.5)
		return

	pen_apply_body_density(packet, target.density_sharp, target.density_blunt)
	target.apply_organ_damage(organ_damage)
	target.on_external_damage(organ_damage, packet, null)
