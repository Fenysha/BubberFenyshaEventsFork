#ifndef OLD_COMBAT_SYSTEM
/**
 * Called when a bodypart takes damage.
 *
 * Brute damage represents structural destruction.
 * Burn damage represents skin and superficial tissue destruction.
 *
 * The latest impact is kept separately from stored bodypart damage so that
 * a hit can still cause pain, shock and consciousness loss even when the
 * bodypart has no remaining damage capacity.
 *
 * Injury generation happens after damage is committed, allowing injuries
 * to emerge from accumulated bodypart damage instead of only the latest hit.
 */
/obj/item/bodypart/proc/receive_damage(brute = 0, burn = 0, blocked = 0, updating_health = TRUE, forced = FALSE, required_bodytype = null, wound_bonus = 0, exposed_wound_bonus = 0, sharpness = NONE, attack_direction = null, damage_source, wound_clothing = TRUE)
	SHOULD_CALL_PARENT(TRUE)

	var/hit_percent = forced ? 1 : (100 - blocked) / 100
	if((!brute && !burn) || hit_percent <= 0)
		return FALSE

	if(!forced)
		if(owner)
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

	/*
	 * Keep the resolved incoming impact separate from the amount that can
	 * still be stored by the bodypart.
	 */
	var/impact_brute = brute
	var/impact_burn = burn

	if(owner)
		var/obj/item/stack/medical/wrap/current_gauze = LAZYACCESS(applied_items, LIMB_ITEM_GAUZE)
		if(istype(current_gauze, /obj/item/stack/medical/wrap/gauze))
			var/obj/item/stack/medical/wrap/gauze/our_gauze = current_gauze
			our_gauze.get_hit(src)

	/*
	 * Acute combat response is based on the actual impact, not the remaining
	 * damage capacity of the bodypart.
	 */
	if(owner)
		if(impact_brute > 0)
			owner.apply_combat_impact_response(impact_brute, body_zone, BRUTE, damage_source)

		if(impact_burn > 0)
			owner.apply_combat_impact_response(impact_burn, body_zone, BURN, damage_source)

	/*
	 * Determine how much new damage the bodypart can actually store.
	 */
	var/remaining_capacity = max(max_damage - get_damage(), 0)
	var/incoming_total = impact_brute + impact_burn

	var/applied_brute = impact_brute
	var/applied_burn = impact_burn

	if(incoming_total > remaining_capacity && incoming_total > 0)
		var/capacity_ratio = remaining_capacity / incoming_total
		applied_brute = round(impact_brute * capacity_ratio, DAMAGE_PRECISION)
		applied_burn = round(impact_burn * capacity_ratio, DAMAGE_PRECISION)

	if(applied_brute > 0)
		set_brute_dam(brute_dam + applied_brute)

	if(applied_burn > 0)
		set_burn_dam(burn_dam + applied_burn)

	/*
	 * The bodypart state has now changed, so injury generation must happen
	 * after damage is committed.
	 */
	update_wound_theory()

	try_generate_injuries(brute = impact_brute, burn = impact_burn, sharpness = sharpness, attack_direction = attack_direction, damage_source = damage_source, wound_bonus = wound_bonus, exposed_wound_bonus = exposed_wound_bonus)

	/*
	 * Recalculate pain, bleeding and future damage modifiers after the
	 * newly generated injuries have been applied.
	 */
	if(owner && impact_brute > 0)
		if(try_dismember_from_damage(impact_brute, impact_burn, sharpness))
			return TRUE
	update_injuries()

	if(owner)
		if(can_be_disabled)
			update_disabled()

		if(updating_health)
			owner.updatehealth()

	return update_bodypart_damage_state()

/**
 * Applies an already-resolved penetration packet to this limb, then
 * processes body density and any internal organs.
 */
/obj/item/bodypart/proc/take_penetrating_hit(list/packet, sharpness = NONE, wound_bonus = 0, attack_direction, damage_source)
	if(!packet || !owner)
		return

	var/dealt = packet["limb_damage"]
	var/damage_type = packet["damage_type"]

	if(dealt > 0)
		var/brute = (damage_type == BRUTE) ? dealt : 0
		var/burn = (damage_type == BURN) ? dealt : 0

		receive_damage(brute = brute, burn = burn, blocked = 0, forced = TRUE, wound_bonus = wound_bonus, sharpness = sharpness, attack_direction = attack_direction, damage_source = damage_source)

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

	// Prefer vital organs when present (brain on head, heart/lungs on chest).
	var/obj/item/organ/target
	if(body_zone == BODY_ZONE_HEAD)
		target = owner?.get_organ_slot(ORGAN_SLOT_BRAIN)
	else if(body_zone == BODY_ZONE_CHEST)
		// Slight preference for heart, then lungs.
		target = owner?.get_organ_slot(ORGAN_SLOT_HEART) || owner?.get_organ_slot(ORGAN_SLOT_LUNGS)

	if(!target || !(target in candidates))
		target = pick(candidates)

	// Remaining kinetic energy / AP after tissue determines organ trauma severity.
	var/remaining_damage = packet["damage"]
	var/remaining_sharp_ap = packet["sharp_ap"]
	var/remaining_blunt_ap = packet["blunt_ap"]
	var/ap_factor = 1.0 + max(remaining_sharp_ap, remaining_blunt_ap) * 0.08

	// Full penetration (high residual AP) transfers far more energy into organs.
	var/base_mult = 0.55
	if(remaining_sharp_ap > 4 || remaining_blunt_ap > 6)
		base_mult = 0.95
	if(remaining_sharp_ap > 8 || remaining_blunt_ap > 12)
		base_mult = 1.35

	// Headshots that fully defeat protection are especially lethal to the brain.
	if(body_zone == BODY_ZONE_HEAD && istype(target, /obj/item/organ/brain))
		base_mult *= 1.6
		// High-velocity / high-AP rounds can instantly cripple or destroy the brain.
		if(remaining_sharp_ap > 6)
			base_mult *= 1.4

	var/organ_damage = remaining_damage * base_mult * ap_factor

	if(organ_damage < 0.5)
		return

	pen_apply_body_density(packet, target.density_sharp, target.density_blunt)
	target.apply_organ_damage(organ_damage)
	target.on_external_damage(organ_damage, packet, null)

	// Extra shock / consciousness impulse for deep organ trauma, especially brain.
	if(owner && organ_damage >= 8)
		var/extra_shock = organ_damage * 0.35
		var/extra_consc = organ_damage * 0.25
		if(istype(target, /obj/item/organ/brain))
			extra_shock *= 1.8
			extra_consc *= 2.2
		owner.apply_shock_impulse(extra_shock, target)
		owner.apply_consciousness_impulse(extra_consc, target)
#endif
