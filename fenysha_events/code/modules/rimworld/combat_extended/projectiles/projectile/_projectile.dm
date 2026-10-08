// Base projectile for the Combat Extended-style ballistic model.
/obj/projectile/rimworld
	name = "bullet"
	icon_state = "bullet"
	damage = 20
	damage_type = BRUTE
	armor_flag = BULLET
	speed = 5

	icon = 'fenysha_events/icons/items/projectiles.dmi'
	icon_state = "bullet"

	/// Aim data stamped by the gun at fire time
	var/rw_aim_mode = RW_AIM_SNAP
	var/list/rw_area_zones
	var/rw_precise_zone
	var/rw_zone_accuracy_pct = 50
	var/rw_miss_base = 0.35
	var/rw_effective_range = 12 TILES
	var/list/rw_miss_cache

	/// Sharp penetration in mm RHA equivalent
	rw_ap_sharp = 4 MM_RHA
	/// Blunt penetration / kinetic transfer in MPa
	rw_ap_blunt = 18 MPA
	/// Extra damage multiplier vs soft tissue when sharp is stopped (HP bias)
	var/rw_soft_damage_mult = 1
	/// Caliber tag
	var/rw_caliber = RW_CALIBER_9MM
	/// Ammo class for examine
	var/rw_ammo_class = "FMJ"
	/// On-hit fire stacks
	var/rw_fire_stacks = 0
	/// Small explosion radius (HE); 0 = none
	var/rw_he_radius = 0
	/// HE devastation / heavy / light / flash radii (only if rw_he_radius > 0)
	var/rw_he_dev = 0
	var/rw_he_heavy = 0
	var/rw_he_light = 0
	var/rw_he_flash = 0
	var/rw_hit_flash = TRUE
	light_system = OVERLAY_LIGHT


/obj/projectile/rimworld/fire(fire_angle, atom/direct_target)
	var/obj/item/gun/rimworld/source_gun = fired_from
	if(istype(source_gun))
		source_gun.rw_apply_shot_data(src)
	return ..()


/obj/projectile/rimworld/proc/rw_get_size_class(atom/target)
	if(isturf(target))
		return RW_SIZE_LARGE
	if(isliving(target))
		var/mob/living/living_target = target
		return living_target.mob_size >= MOB_SIZE_HUMAN ? RW_SIZE_LARGE : RW_SIZE_SMALL
	if(isitem(target))
		return RW_SIZE_SMALL
	if(isobj(target))
		var/obj/object = target
		if(object.anchored || istype(object, /obj/structure) || istype(object, /obj/machinery) || ismecha(object))
			return RW_SIZE_LARGE
		// Small movable objects are treated as pass-through targets.
	return RW_SIZE_LARGE


/obj/projectile/rimworld/proc/rw_calc_miss_chance(atom/target)
	var/turf/origin = starting || get_turf(src)
	var/turf/dest = get_turf(target)
	if(!origin || !dest)
		return rw_miss_base

	var/distance = get_dist(origin, dest)
	var/effective_range = max(rw_effective_range, 1)
	var/miss = rw_miss_base

	if(distance > effective_range)
		var/over = clamp((distance - effective_range) / effective_range, 0, 1)
		miss = max(miss, RW_MISS_BEYOND_RANGE_MIN + (RW_MISS_BEYOND_RANGE_MAX - RW_MISS_BEYOND_RANGE_MIN) * over)
	else
		miss += RW_MISS_RANGE_FALLOFF * (distance / effective_range) ** 2

	if(distance <= 1)
		if(rw_aim_mode == RW_AIM_SUPPRESS)
			miss *= RW_MISS_SUPPRESS_POINT_BLANK_MULT
		else
			miss *= RW_MISS_POINT_BLANK_MULT

	return clamp(miss, 0, RW_MISS_BEYOND_RANGE_MAX)


/obj/projectile/rimworld/proc/rw_roll_miss(mob/living/target)
	var/datum/weakref/target_ref = WEAKREF(target)
	if(!isnull(rw_miss_cache?[target_ref]))
		return rw_miss_cache[target_ref]

	var/chance = rw_calc_miss_chance(target)
	var/missed = prob(chance * 100)

	LAZYSET(rw_miss_cache, target_ref, missed)

	var/trains = isliving(firer) && rw_aim_mode != RW_AIM_SUPPRESS
	if(missed)
		if(target.client)
			to_chat(target, span_danger("A round cracks past!"))
		create_floating_combat_text(target, "Miss", "#FFB45E")
		if(trains)
			RW_TRAIN_SKILL(firer, RW_SKILL_RANGED, RW_SKILL_POINTS_TINY)
	else if(trains)
		RW_TRAIN_SKILL(firer, RW_SKILL_RANGED, RW_SKILL_POINTS_SMALL)

	return missed


/obj/projectile/rimworld/proc/rw_should_pass(atom/target, direct_target)
	if(isliving(target))
		var/mob/living/living_target = target
		if(living_target == firer)
			return FALSE
		if(rw_get_size_class(living_target) == RW_SIZE_LARGE)
			return rw_roll_miss(living_target)
		return !(direct_target || target == original)

	if(direct_target || target == original)
		return FALSE
	return rw_get_size_class(target) == RW_SIZE_SMALL


/obj/projectile/rimworld/can_hit_target(atom/target, direct_target = FALSE, ignore_loc = FALSE, cross_failed = FALSE)
	. = ..()
	if(!.)
		return FALSE
	if(rw_should_pass(target, direct_target))
		return FALSE
	return TRUE


/obj/projectile/rimworld/CanPassThrough(atom/blocker, movement_dir, blocker_opinion)
	if(..())
		return TRUE
	return rw_should_pass(blocker, blocker == original)


/obj/projectile/rimworld/impact(atom/target)
	if(deletion_queued)
		return
	if(impacted[target.weak_reference])
		return
	if(rw_should_pass(target, target == original))
		impacted[WEAKREF(target)] = TRUE
		return
	return ..()


/obj/projectile/rimworld/prehit_pierce(atom/target)
	def_zone = rw_resolve_def_zone(target)
	return ..()


/obj/projectile/rimworld/proc/rw_resolve_def_zone(atom/target)
	if(!isliving(target))
		return def_zone
	var/mob/living/victim = target

	if(rw_aim_mode == RW_AIM_SUPPRESS)
		return victim.get_random_valid_zone(even_weights = TRUE, bypass_warning = TRUE) || def_zone

	if(rw_precise_zone)
		if(prob(rw_zone_accuracy_pct) && rw_victim_has_zone(victim, rw_precise_zone))
			return rw_precise_zone
		var/list/neighbours = list()
		for(var/zone in GLOB.rw_area_zones[rw_area_of_zone(rw_precise_zone)])
			if(rw_victim_has_zone(victim, zone))
				neighbours += zone
		if(length(neighbours))
			return pick(neighbours)
		return victim.get_random_valid_zone(even_weights = TRUE, bypass_warning = TRUE) || def_zone

	var/list/candidates = list()
	for(var/zone in rw_area_zones)
		if(rw_victim_has_zone(victim, zone))
			candidates += zone
	if(length(candidates))
		return pick(candidates)
	return victim.get_random_valid_zone(even_weights = TRUE, bypass_warning = TRUE) || def_zone


/obj/projectile/rimworld/proc/rw_victim_has_zone(mob/living/victim, zone)
	if(iscarbon(victim))
		var/mob/living/carbon/carbon_victim = victim
		return !!carbon_victim.get_bodypart(zone)
	return TRUE


/// Apply CE-style effects after a living hit (fire, HE). Call from on_hit or your damage pipeline.
/obj/projectile/rimworld/proc/rw_on_hit_living(mob/living/victim, blocked = 0)
	if(rw_fire_stacks > 0 && blocked < 100)
		victim.adjust_fire_stacks(rw_fire_stacks)
		victim.ignite_mob()
	if(rw_he_radius > 0)
		explosion(
			get_turf(victim),
			devastation_range = rw_he_dev,
			heavy_impact_range = rw_he_heavy,
			light_impact_range = rw_he_light,
			flash_range = rw_he_flash,
			explosion_cause = src,
		)


/obj/projectile/rimworld/on_hit(atom/target, blocked = 0, pierce_hit)
	. = ..()
	if(. == BULLET_ACT_HIT && isliving(target))
		rw_on_hit_living(target, blocked)
	if(rw_hit_flash && isliving(target) && blocked < 100 && damage > 0)
		rw_flash_color(target)
	return .


/obj/projectile/rimworld/examine(mob/user)
	. = ..()
	. += span_notice("[rw_ammo_class] · [rw_caliber]")
	. += span_notice("Sharp AP: [rw_ap_sharp] mm RHA · Blunt AP: [rw_ap_blunt] MPa · Damage: [damage]")
