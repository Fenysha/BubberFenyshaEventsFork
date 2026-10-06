/**
 * CE-style penetrating hit entry point for carbons.
 * Clothing / physiology resolved here (human override); limb only receives the result.
 */
/mob/living/carbon/proc/apply_penetrating_damage(
	damage,
	damage_type = BRUTE,
	def_zone = null,
	sharpness = NONE,
	obj/item/weapon,
	obj/projectile/proj,
	wound_bonus = 0,
	attack_direction,
	damage_source,
)
	if(damage <= 0)
		return 0
	if(HAS_TRAIT(src, TRAIT_GODMODE))
		return 0

	var/obj/item/bodypart/BP = isbodypart(def_zone) ? def_zone : get_bodypart(check_zone(def_zone))
	if(!BP)
		return apply_damage(damage, damage_type, def_zone)

	var/used_sharpness = sharpness
	if(used_sharpness == NONE)
		if(weapon && !proj)
			used_sharpness = weapon.get_sharpness()
		else if(proj)
			used_sharpness = proj.sharpness

	var/list/packet = pen_packet_from_attack(damage, used_sharpness, weapon, proj, damage_type)
	packet = run_armor_penetration(BP, packet)

	var/limb_damage = packet["damage"]
	packet["limb_damage"] = limb_damage

	if(limb_damage <= 0 && !pen_can_penetrate_deeper(packet))
		return 0

	new /obj/effect/temp_visual/damage_numbers(get_turf(src), packet["damage"], def_zone, damage_type)
	BP.take_penetrating_hit(
		packet,
		used_sharpness,
		wound_bonus,
		attack_direction,
		damage_source || weapon || proj,
	)
	return packet["limb_damage"]

/**
 * Base carbon: natural limb armor only. Humans add clothing + physiology.
 */
/mob/living/carbon/proc/run_armor_penetration(obj/item/bodypart/BP, list/packet)
	if(!BP || !packet)
		return packet
	if(BP.natural_sharp_armor || BP.natural_blunt_armor)
		packet = pen_apply_armor_layer(packet, BP.natural_sharp_armor, BP.natural_blunt_armor)
	return packet




// code/modules/mob/living/carbon/carbon_damage_routing.dm
// Compile AFTER living damage procs and carbon_penetration.dm
// Toggle: #define OLD_COMBAT_SYSTEM restores stock apply_damage path

#ifndef OLD_COMBAT_SYSTEM
/**
 * Carbon damage routing into CE-style penetration + injury system.
 *
 * BRUTE + targeted zone  → apply_penetrating_damage (clothing → limb → organs)
 * BURN + targeted zone   → bodypart.receive_damage (no sharp/blunt pen for now)
 * spread / no zone       → parent behavior
 * TOX / OXY / STAMINA / BRAIN → parent
 */
/mob/living/carbon/apply_damage(
	damage = 0,
	damagetype = BRUTE,
	def_zone = null,
	blocked = 0,
	forced = FALSE,
	spread_damage = FALSE,
	wound_bonus = 0,
	exposed_wound_bonus = 0,
	sharpness = NONE,
	attack_direction = null,
	attacking_item,
	wound_clothing = TRUE,
)
	// Spread or non-localized: keep stock distribution
	if(spread_damage || (damagetype != BRUTE && damagetype != BURN))
		return ..()

	// Resolve bodypart
	var/obj/item/bodypart/hit_part
	if(isbodypart(def_zone))
		hit_part = def_zone
	else if(def_zone)
		hit_part = get_bodypart(check_zone(def_zone))

	// No limb / no zone: stock path (adjust_X_loss)
	if(!hit_part)
		return ..()

	var/damage_amount = damage
	if(!forced)
		damage_amount *= ((100 - blocked) / 100)
		damage_amount *= get_incoming_damage_modifier(
			damage_amount,
			damagetype,
			hit_part,
			sharpness,
			attack_direction,
			attacking_item,
		)

	SEND_SIGNAL(src, COMSIG_MOB_ALWAYS_APPLY_DAMAGE, damage_amount, damagetype, hit_part, blocked, wound_bonus, exposed_wound_bonus, sharpness, attack_direction,attacking_item, wound_clothing)
	if(damage_amount <= 0)
		return 0

	SEND_SIGNAL(src, COMSIG_MOB_APPLY_DAMAGE, damage_amount, damagetype, hit_part, blocked, wound_bonus, exposed_wound_bonus, sharpness, attack_direction, attacking_item, wound_clothing)

	var/damage_dealt = 0

	switch(damagetype)
		if(BRUTE)
			// Penetration pipeline owns clothing / natural armor / density / organs
			var/before = hit_part.get_damage()
			var/dealt = apply_penetrating_damage(
				damage = damage_amount,
				damage_type = BRUTE,
				def_zone = hit_part,
				sharpness = sharpness,
				weapon = attacking_item,
				proj = istype(attacking_item, /obj/projectile) ? attacking_item : null,
				wound_bonus = wound_bonus,
				attack_direction = attack_direction,
				damage_source = attacking_item,
			)
			// apply_penetrating_damage already called take_penetrating_hit → receive_damage
			// Prefer measured limb delta if available
			var/after = hit_part.get_damage()
			damage_dealt = max(dealt, after - before)
			if(damage_dealt)
				update_damage_overlays()

		if(BURN)
			// Burns skip sharp/blunt pen; still hit the limb for injuries
			var/before_burn = hit_part.get_damage()
			if(hit_part.receive_damage(
				brute = 0,
				burn = damage_amount,
				blocked = 0,
				forced = TRUE,
				wound_bonus = wound_bonus,
				exposed_wound_bonus = exposed_wound_bonus,
				sharpness = sharpness,
				attack_direction = attack_direction,
				damage_source = attacking_item,
				wound_clothing = wound_clothing,
			))
				update_damage_overlays()
			damage_dealt = hit_part.get_damage() - before_burn

	SEND_SIGNAL(src, COMSIG_MOB_AFTER_APPLY_DAMAGE, damage_dealt, damagetype, hit_part, blocked, wound_bonus, exposed_wound_bonus, sharpness, attack_direction, attacking_item, wound_clothing)
	return damage_dealt

/**
 * Single random (or targeted) bodypart hit — route through apply_damage.
 */
/mob/living/carbon/take_bodypart_damage(
	brute = 0,
	burn = 0,
	updating_health = TRUE,
	required_bodytype,
	check_armor = FALSE,
	wound_bonus = 0,
	exposed_wound_bonus = 0,
	sharpness = NONE,
)
	var/obj/item/bodypart/part
	if(required_bodytype)
		var/list/valid = list()
		for(var/obj/item/bodypart/BP as anything in bodyparts)
			if(BP.bodytype & required_bodytype)
				valid += BP
		if(length(valid))
			part = pick(valid)
	if(!part)
		part = pick(bodyparts)

	var/dealt = 0
	if(brute)
		dealt += apply_damage(
			brute,
			BRUTE,
			part,
			blocked = 0,
			wound_bonus = wound_bonus,
			exposed_wound_bonus = exposed_wound_bonus,
			sharpness = sharpness,
		)
	if(burn)
		dealt += apply_damage(
			burn,
			BURN,
			part,
			blocked = 0,
			wound_bonus = wound_bonus,
			exposed_wound_bonus = exposed_wound_bonus,
			sharpness = sharpness,
		)
	if(dealt && updating_health)
		updatehealth()
	return dealt

/**
 * Overall damage: split across bodyparts, each chunk through apply_damage.
 */
/mob/living/carbon/take_overall_damage(
	brute = 0,
	burn = 0,
	stamina = 0,
	updating_health = TRUE,
	forced = FALSE,
	required_bodytype,
)
	var/list/parts = list()
	for(var/obj/item/bodypart/BP as anything in bodyparts)
		if(required_bodytype && !(BP.bodytype & required_bodytype))
			continue
		parts += BP

	if(!length(parts))
		return ..()

	var/dealt = 0
	if(brute)
		var/per = brute / length(parts)
		for(var/obj/item/bodypart/BP as anything in parts)
			dealt += apply_damage(per, BRUTE, BP, forced = forced)
	if(burn)
		var/per_burn = burn / length(parts)
		for(var/obj/item/bodypart/BP as anything in parts)
			dealt += apply_damage(per_burn, BURN, BP, forced = forced)
	if(stamina)
		dealt += adjust_stamina_loss(abs(stamina), updating_stamina = FALSE, forced = forced)

	if(dealt && updating_health)
		updatehealth()
	return dealt

#endif // OLD_COMBAT_SYSTEM
