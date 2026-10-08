/proc/create_pen_packet(damage, sharp_ap, blunt_ap, damage_type = BRUTE)
	return list(
		"damage" = damage,
		"sharp_ap" = sharp_ap,
		"blunt_ap" = blunt_ap,
		"damage_type" = damage_type,
		"deflected" = FALSE,
		"limb_damage" = 0,
	)

/// Applies one armor layer. Sharp AP can penetrate or be deflected into blunt trauma;
/// blunt AP is reduced independently.
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

/proc/pen_finalize_soft_damage(list/packet, soft_damage_mult = 1)
	if(!packet || packet["damage"] <= 0)
		return packet
	packet["damage"] *= max(0, soft_damage_mult)
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
		sharp_ap = proj.rw_ap_sharp
		blunt_ap = proj.rw_ap_blunt
		if(!sharp_ap && !blunt_ap && proj.armour_penetration)
			if(proj.sharpness & (SHARP_EDGED | SHARP_POINTY))
				sharp_ap = proj.armour_penetration * 0.1
				blunt_ap = proj.armour_penetration * 0.05
			else
				blunt_ap = proj.armour_penetration * 0.1
	else if(weapon)
		sharp_ap = weapon.rw_ap_sharp
		blunt_ap = weapon.rw_ap_blunt
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
		// Bare-limb strikes generate less blunt AP and have no minimum AP floor.
		blunt_ap = istype(weapon, /obj/item/bodypart) ? damage * 0.08 : max(damage * 0.12, 1)

	return create_pen_packet(damage, sharp_ap, blunt_ap, BRUTE)

/obj/item
	var/rw_ap_sharp = 0
	var/rw_ap_blunt = 0

/obj/projectile
	var/rw_ap_sharp = 0
	var/rw_ap_blunt = 0
