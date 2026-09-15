/turf/open/bottom_or_region

/turf/closed/rw_wall
	name = "wall"
	desc = "A huge chunk of iron used to separate rooms."
	icon = 'icons/turf/walls/material_wall.dmi'
	icon_state = "material_wall-0"
	base_icon_state = "material_wall"
	explosive_resistance = 1
	rust_resistance = RUST_RESISTANCE_BASIC

	thermal_conductivity = WALL_HEAT_TRANSFER_COEFFICIENT
	heat_capacity = 62500

	baseturfs = /turf/open/bottom_or_region

	flags_ricochet = RICOCHET_HARD

	smoothing_flags = SMOOTH_BITMASK
	smoothing_groups = SMOOTH_GROUP_WALLS + SMOOTH_GROUP_CLOSED_TURFS
	canSmoothWith = SMOOTH_GROUP_WALLS

	rcd_memory = RCD_MEMORY_WALL


	///lower numbers are harder. Used to determine the probability of a hulk smashing through.
	var/hardness = 40
	var/slicing_duration = 100  //default time taken to slice the wall


	var/list/dent_decals

	/// Maximum structural integrity of the wall.
	var/max_health = 200
	/// Current structural integrity.
	var/health = 200
	/// Minimum damage dealt by a generic weapon.
	var/min_weapon_damage = 5
	/// Maximum damage dealt by a generic weapon.
	var/max_weapon_damage = 60
	/// Damage multiplier for brute damage.
	var/brute_damage_multiplier = 1
	/// Damage multiplier for burn damage.
	var/burn_damage_multiplier = 0.25
	/// Damage multiplier for explosion damage.
	var/explosion_damage_multiplier = 1
	/// Damage multiplier for miscellaneous damage.
	var/other_damage_multiplier = 1
	/// Minimum amount of damage required to create a dent.
	var/dent_damage_threshold = 5
	/// Prevents the wall from taking damage after destruction has started.
	var/destroying = FALSE



/turf/closed/rw_wall/Initialize(mapload)
	. = ..()


	health = max_health
	register_context()

/turf/closed/rw_wall/Destroy(force)
	. = ..()


/turf/closed/rw_wall/proc/update_damage_effects(ration = get_health_ratio())
	return

/turf/closed/rw_wall/proc/get_health_ratio()
	if(max_health <= 0)
		return 0
	return clamp(health / max_health, 0, 1)


/turf/closed/rw_wall/proc/is_wall_destroyed()
	return destroying || health <= 0


/turf/closed/rw_wall/proc/heal_wall(amount)
	if(amount <= 0 || destroying)
		return FALSE

	var/old_health = health

	health = min(health + amount, max_health)
	return health != old_health

/turf/closed/rw_wall/proc/add_dent(x=rand(-8, 8), y=rand(-8, 8))
	if(LAZYLEN(dent_decals) >= MAX_DENT_DECALS)
		return

	var/mutable_appearance/decal = mutable_appearance('icons/effects/effects.dmi', "", BULLET_HOLE_LAYER)
	decal.icon_state = "impact[rand(1, 3)]"

	decal.pixel_w = x
	decal.pixel_z = y

	if(LAZYLEN(dent_decals))
		cut_overlay(dent_decals)
		dent_decals += decal
	else
		dent_decals = list(decal)
	add_overlay(dent_decals)

/**
 * Main wall damage proc.
 *
 * damage:
 *	Raw incoming damage.
 *
 * damage_type:
 *	BRUTE / BURN / etc.
 *
 * attacker:
 *	Mob responsible for the damage.
 *
 * source:
 *	Atom which caused the damage.
 *
 * show_dent:
 *	Whether a dent should be added.
 */
/turf/closed/rw_wall/proc/take_wall_damage(
	amount,
	damage_type = BRUTE,
	mob/living/attacker,
	atom/source,
	show_dent = TRUE
)
	if(amount <= 0 || destroying)
		return FALSE

	var/damage_multiplier = 1

	switch(damage_type)
		if(BRUTE)
			damage_multiplier = brute_damage_multiplier

		if(BURN)
			damage_multiplier = burn_damage_multiplier

		else
			damage_multiplier = other_damage_multiplier

	amount *= damage_multiplier

	if(amount <= 0)
		return FALSE

	health -= amount

	if(show_dent && amount >= dent_damage_threshold)
		add_dent()
	update_damage_effects()

	if(health <= 0)
		// destroy_wall(attacker, source)
		return TRUE

	return TRUE


/turf/closed/rw_wall/proc/take_brute_damage(amount, mob/living/attacker, atom/source)
	return take_wall_damage(
		amount,
		BRUTE,
		attacker,
		source
	)


/turf/closed/rw_wall/proc/take_burn_damage(amount, mob/living/attacker, atom/source)
	return take_wall_damage(
		amount,
		BURN,
		attacker,
		source
	)


/turf/closed/rw_wall/proc/take_explosion_damage(amount, mob/living/attacker, atom/source)
	if(amount <= 0 || destroying)
		return FALSE

	amount *= explosion_damage_multiplier

	health -= amount

	if(health <= 0)
		// destroy_wall(attacker, source)
		return TRUE

	return TRUE


/turf/closed/rw_wall/proc/get_weapon_damage(obj/item/weapon, mob/user)
	if(!weapon || weapon.force < min_weapon_damage)
		return 0

	return max(1, min(weapon.force, max_weapon_damage))


/turf/closed/rw_wall/attack_hand(mob/user, list/modifiers)
	. = ..()
	if(.)
		return

	user.changeNext_move(CLICK_CD_MELEE)

	to_chat(user, span_notice("You push the wall but nothing happens!"))
	playsound(src, 'sound/items/weapons/genhit.ogg', 25, TRUE)

	add_fingerprint(user)


/turf/closed/rw_wall/attacked_by(obj/item/attacking_item, mob/living/user, list/modifiers, list/attack_modifiers)
	. = ..()


/turf/closed/rw_wall/wrench_act(mob/living/user, obj/item/tool)
	. = ..()

	if(user.combat_mode || !(initial(smoothing_flags) & SMOOTH_DIAGONAL_CORNERS))
		return ITEM_INTERACT_SKIP_TO_ATTACK

	if(smoothing_flags & SMOOTH_DIAGONAL_CORNERS)
		smoothing_flags &= ~SMOOTH_DIAGONAL_CORNERS
	else
		smoothing_flags |= SMOOTH_DIAGONAL_CORNERS

	QUEUE_SMOOTH(src)
	to_chat(user, span_notice("You adjust [src]."))

	tool.play_tool_sound(src)

	return ITEM_INTERACT_SUCCESS


/turf/closed/rw_wall/rock
