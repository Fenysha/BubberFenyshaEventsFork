/datum/armor
	/// Sharp protection (mm RHA)
	VAR_PROTECTED/sharp = 0
	/// Blunt protection (MPa)
	VAR_PROTECTED/blunt = 0


/datum/armor/proc/get_sharp_rating()
	if(sharp)
		return sharp
	return max(bullet * 0.1, melee * 0.05)

/datum/armor/proc/get_blunt_rating()
	if(blunt)
		return blunt
	return max(melee * 0.08, bomb * 0.05)


/**
 * Returns the client readable name of an armor type
 *
 * Arguments:
 * * armor_type - The type to convert
 */
/armor_to_protection_name(armor_type)
	switch(armor_type)
		if(ACID)
			return "ACID"
		if(BIO)
			return "BIOHAZARD"
		if(BOMB)
			return "EXPLOSIVE"
		if(BULLET)
			return "BULLET"
		if(CONSUME)
			return "CONSUMING"
		if(ENERGY)
			return "ENERGY"
		if(FIRE)
			return "FIRE"
		if(LASER)
			return "LASER"
		if(MELEE)
			return "MELEE"
		if(WOUND)
			return "WOUNDING"
		if(SHARP)
			return "SHARP"
		if(BLUNT)
			return "BLUNT"
	CRASH("Unknown armor type '[armor_type]'")


/proc/create_pen_packet(damage, sharp_ap, blunt_ap, damage_type = BRUTE)
	return list(
		"damage" = damage,
		"sharp_ap" = sharp_ap,
		"blunt_ap" = blunt_ap,
		"damage_type" = damage_type,
		"deflected" = FALSE,
		"limb_damage" = 0,
	)

/**
 * One armor layer (clothing / natural / physiology).
 * Sharp: RemainingAP = AP - Armor; Damage *= RemainingAP/AP; Armor > AP → deflect + blunt trauma.
 * Blunt: same reduction without sharp→blunt conversion.
 */
/proc/pen_apply_armor_layer(list/packet, sharp_armor, blunt_armor)
	if(!packet || packet["damage"] <= 0)
		return packet
	if(packet["damage_type"] != BRUTE)
		return packet

	var/damage = packet["damage"]
	var/sharp_ap = packet["sharp_ap"]
	var/blunt_ap = packet["blunt_ap"]

	var/sharp_damage = 0
	var/residual_blunt = 0
	var/remaining_sharp_ap = sharp_ap

	if(sharp_ap > PENETRATION_MIN)
		if(PEN_SHARP_DEFLECTED(sharp_ap, sharp_armor))
			packet["deflected"] = TRUE
			remaining_sharp_ap = 0
			sharp_damage = 0
			residual_blunt = PEN_BLUNT_DAMAGE_FROM_AP(blunt_ap)
		else
			var/rem_ap = PEN_REMAINING_AP(sharp_ap, sharp_armor)
			var/mult = PEN_DAMAGE_MULT(sharp_ap, sharp_armor)
			var/remaining_damage = damage * mult
			var/stopped = damage - remaining_damage
			var/ap_lost = (sharp_ap - rem_ap) / max(sharp_ap, PENETRATION_MIN)
			var/dmg_lost = stopped / max(damage, PENETRATION_MIN)
			var/pen_multi = ap_lost * dmg_lost
			remaining_sharp_ap = rem_ap
			sharp_damage = remaining_damage
			residual_blunt = PEN_BLUNT_DAMAGE_FROM_AP(blunt_ap * pen_multi)
	else
		sharp_damage = 0
		residual_blunt = damage

	var/working_blunt_ap = blunt_ap
	var/blunt_component = (sharp_ap <= PENETRATION_MIN) ? damage : residual_blunt

	if(working_blunt_ap > PENETRATION_MIN && blunt_armor > 0)
		if(blunt_armor >= working_blunt_ap)
			blunt_component = 0
			working_blunt_ap = 0
		else
			blunt_component *= PEN_DAMAGE_MULT(working_blunt_ap, blunt_armor)
			working_blunt_ap = PEN_REMAINING_AP(working_blunt_ap, blunt_armor)

	packet["damage"] = sharp_damage + blunt_component
	packet["sharp_ap"] = remaining_sharp_ap
	packet["blunt_ap"] = working_blunt_ap
	return packet

/proc/pen_apply_body_density(list/packet, density_sharp, density_blunt)
	if(!packet)
		return packet
	packet["sharp_ap"] = max(0, packet["sharp_ap"] - density_sharp)
	packet["blunt_ap"] = max(0, packet["blunt_ap"] - density_blunt)
	return packet

/proc/pen_can_penetrate_deeper(list/packet)
	if(!packet || packet["damage"] <= 0)
		return FALSE
	return (packet["sharp_ap"] > PENETRATION_MIN) || (packet["blunt_ap"] > PENETRATION_MIN)

/proc/pen_packet_from_attack(damage, sharpness = NONE, obj/item/weapon, obj/projectile/proj, damage_type = BRUTE)
	if(damage_type != BRUTE)
		return create_pen_packet(damage, 0, 0, damage_type)

	var/sharp_ap = 0
	var/blunt_ap = 0

	if(proj)
		sharp_ap = proj.armour_penetration_sharp
		blunt_ap = proj.armour_penetration_blunt
		if(!sharp_ap && !blunt_ap && proj.armour_penetration)
			if(proj.sharpness & (SHARP_EDGED | SHARP_POINTY))
				sharp_ap = proj.armour_penetration * 0.1
				blunt_ap = proj.armour_penetration * 0.05
			else
				blunt_ap = proj.armour_penetration * 0.1
	else if(weapon)
		sharp_ap = weapon.armour_penetration_sharp
		blunt_ap = weapon.armour_penetration_blunt
		if(!sharp_ap && !blunt_ap && weapon.armour_penetration)
			if(sharpness & (SHARP_EDGED | SHARP_POINTY))
				sharp_ap = weapon.armour_penetration * 0.1
				blunt_ap = weapon.armour_penetration * 0.05
			else
				blunt_ap = weapon.armour_penetration * 0.1

	if(sharpness & (SHARP_EDGED | SHARP_POINTY))
		if(!sharp_ap)
			sharp_ap = max(damage * 0.15, 1)
		if(!blunt_ap)
			blunt_ap = max(damage * 0.05, 0.5)
	else if(!blunt_ap)
		blunt_ap = max(damage * 0.12, 1)

	return create_pen_packet(damage, sharp_ap, blunt_ap, BRUTE)


/obj/item
	var/armour_penetration_sharp = 0
	var/armour_penetration_blunt = 0

/obj/projectile
	var/armour_penetration_sharp = 0
	var/armour_penetration_blunt = 0
