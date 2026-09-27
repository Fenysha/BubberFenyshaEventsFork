/turf/open/bottom_or_region


/turf/closed/rw_wall
	name = "wall"
	desc = "A huge chunk of iron used to separate rooms."
	icon = 'fenysha_events/icons/turf/closed/material_wall.dmi'
	icon_state = "materialwall-0"
	base_icon_state = "materialwall"
	explosive_resistance = 1
	rust_resistance = RUST_RESISTANCE_BASIC
	rw_turf_flags = USE_MATERIAL_COLOR | SHOW_DAMAGE_NUMBERS

	uses_integrity = TRUE
	max_integrity = 100
	integrity_failure = 0 // 0 = no special "broken" state, destroy at 0

	thermal_conductivity = WALL_HEAT_TRANSFER_COEFFICIENT
	heat_capacity = 62500

	baseturfs = /turf/open/bottom_or_region

	flags_ricochet = RICOCHET_HARD

	smoothing_flags = SMOOTH_BITMASK
	smoothing_groups = SMOOTH_GROUP_RWWALLS + SMOOTH_GROUP_CLOSED_TURFS
	canSmoothWith = SMOOTH_GROUP_RWWALLS

	rcd_memory = RCD_MEMORY_WALL

	///lower numbers are harder. Used to determine the probability of a hulk smashing through.
	var/hardness = 40
	var/deconstruct_time = 7 SECONDS

	var/list/dent_decals

	/// Minimum damage dealt by a generic weapon.
	var/min_weapon_damage = 10
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

	var/supports_roof = TRUE

	/// Prevents the wall from taking damage after destruction has started.
	var/destroying = FALSE

	COOLDOWN_DECLARE(damage_number_cd)


/turf/closed/rw_wall/Initialize(mapload)
	. = ..()
	register_context()


/turf/closed/rw_wall/AfterChange(flags, oldType)
	levelupdate()
	SSair.high_pressure_delta -= src


/turf/closed/rw_wall/air_update_turf(update = FALSE, remove = FALSE)
	return


/turf/closed/rw_wall/Destroy(force)
	. = ..()


/turf/closed/rw_wall/proc/update_damage_effects(ratio = get_health_ratio())
	return


/turf/closed/rw_wall/proc/get_health_ratio()
	if(max_integrity <= 0)
		return 0
	return clamp(get_integrity() / max_integrity, 0, 1)


/turf/closed/rw_wall/proc/is_wall_destroyed()
	return destroying || get_integrity() <= 0


/turf/closed/rw_wall/proc/heal_wall(amount)
	if(amount <= 0 || destroying)
		return FALSE
	return repair_damage(amount) > 0


/turf/closed/rw_wall/proc/add_dent(x = rand(-8, 8), y = rand(-8, 8))
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


/turf/closed/rw_wall/proc/is_roof_support_provider()
	return supports_roof


/**
 * Main wall damage proc.
 * Applies multipliers → damage numbers → integrity update → possible destruction.
 */
/turf/closed/rw_wall/proc/take_wall_damage(
	amount,
	damage_type = BRUTE,
	mob/living/attacker,
	atom/source,
	show_dent = TRUE,
	damage_flag = ""
)
	if(amount <= 0 || destroying || !uses_integrity)
		return FALSE

	var/damage_multiplier = other_damage_multiplier
	switch(damage_type)
		if(BRUTE)
			damage_multiplier = brute_damage_multiplier
		if(BURN)
			damage_multiplier = burn_damage_multiplier

	amount = round(amount * damage_multiplier)
	if(amount <= 0)
		return FALSE

	if(COOLDOWN_FINISHED(src, damage_number_cd))
		// Visual damage numbers
		new /obj/effect/temp_visual/damage_numbers(src, amount, null, damage_type)
		COOLDOWN_START(src, damage_number_cd, 0.3 SECONDS)

	if(show_dent && amount >= dent_damage_threshold)
		add_dent()

	var/previous = get_integrity()
	update_integrity(previous - amount)
	update_damage_effects()

	if(integrity_failure && previous > integrity_failure * max_integrity && get_integrity() <= integrity_failure * max_integrity)
		atom_break(damage_flag)

	if(get_integrity() <= 0)
		atom_destruction(damage_flag)
		return TRUE

	return TRUE


/turf/closed/rw_wall/proc/take_brute_damage(amount, mob/living/attacker, atom/source)
	return take_wall_damage(amount, BRUTE, attacker, source, damage_flag = MELEE)


/turf/closed/rw_wall/proc/take_burn_damage(amount, mob/living/attacker, atom/source)
	return take_wall_damage(amount, BURN, attacker, source, damage_flag = FIRE)


/turf/closed/rw_wall/proc/take_explosion_damage(amount, mob/living/attacker, atom/source)
	if(amount <= 0 || destroying)
		return FALSE
	amount = round(amount * explosion_damage_multiplier)
	if(amount <= 0)
		return FALSE
	return take_wall_damage(amount, BRUTE, attacker, source, show_dent = FALSE, damage_flag = BOMB)


/turf/closed/rw_wall/proc/get_weapon_damage(obj/item/weapon, mob/user)
	if(!weapon || weapon.force < min_weapon_damage)
		return 0
	return max(1, min(weapon.force, max_weapon_damage))


/turf/closed/rw_wall/atom_destruction(damage_flag)
	if(destroying)
		return
	destroying = TRUE
	break_wall(TRUE, damage_flag == BOMB)
	return ..()


/turf/closed/rw_wall/proc/break_wall(devastated = FALSE, explode = FALSE)
	SHOULD_CALL_PARENT(TRUE)

	visible_message(span_warning("The [name] crumbles!"))
	ScrapeAway()
	QUEUE_SMOOTH_NEIGHBORS(src)


/turf/closed/rw_wall/attack_hand(mob/user, list/modifiers)
	. = ..()
	if(.)
		return

	user.changeNext_move(CLICK_CD_MELEE)
	to_chat(user, span_notice("You push the wall but nothing happens!"))
	playsound(src, 'sound/items/weapons/genhit.ogg', 25, TRUE)
	add_fingerprint(user)


/turf/closed/rw_wall/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	if(!ISADVANCEDTOOLUSER(user))
		to_chat(user, span_warning("You don't have the dexterity to do this!"))
		return ITEM_INTERACT_BLOCKING

	add_fingerprint(user)

	if(user.combat_mode)
		user.do_attack_animation(src)

		var/damage = get_weapon_damage(tool, user)

		if(damage <= 0 || !(tool.damtype in list(BRUTE, BURN)))
			playsound(src, 'sound/items/weapons/genhit.ogg', 50, TRUE)
			visible_message(span_warning("[tool] bounces off [src] without leaving a mark!"))
			user.changeNext_move(CLICK_CD_MELEE * 2)
			return ITEM_INTERACT_SUCCESS

		if(tool.hitsound)
			playsound(src, tool.hitsound, tool.get_clamped_volume(), TRUE, -1)
		else
			playsound(src, 'sound/items/weapons/genhit.ogg', 50, TRUE)

		user.visible_message(
			span_danger("[user] hits [src] with [tool]!"),
			span_danger("You hit [src] with [tool]!"),
			span_hear("You hear a thud!"),
			COMBAT_MESSAGE_RANGE
		)

		switch(tool.damtype)
			if(BRUTE)
				take_brute_damage(damage, user, tool)
			if(BURN)
				take_burn_damage(damage, user, tool)

		user.changeNext_move(CLICK_CD_MELEE)
		return ITEM_INTERACT_SUCCESS

	return NONE


/turf/closed/rw_wall/bullet_act(obj/projectile/hitting_projectile, list/modifiers, list/attack_modifiers)
	. = ..()
	if(. == BULLET_ACT_BLOCK || . == BULLET_ACT_FORCE_PIERCE)
		return

	if(hitting_projectile.damage > 0)
		take_wall_damage(
			hitting_projectile.damage,
			hitting_projectile.damage_type,
			hitting_projectile.firer,
			hitting_projectile,
		)


/turf/closed/rw_wall/wrench_act(mob/living/user, obj/item/tool)
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


/turf/closed/rw_wall/add_context(atom/source, list/context, obj/item/held_item, mob/user)
	. = NONE

	var/current = get_integrity()
	var/max = max_integrity
	context[SCREENTIP_CONTEXT_CTRL_LMB] = "Health: [current]/[max]"

	if(!isnull(held_item))
		if((initial(smoothing_flags) & SMOOTH_DIAGONAL_CORNERS) && held_item.tool_behaviour == TOOL_WRENCH)
			context[SCREENTIP_CONTEXT_LMB] = "Adjust Wall Corner"
			return CONTEXTUAL_SCREENTIP_SET

	return CONTEXTUAL_SCREENTIP_SET


/turf/closed/rw_wall/add_large_wall_overlay(wall_icon, wall_state)
	var/static/list/mutable_appearance/wall_overlays = list()
	var/mutable_appearance/wall_overlay = wall_overlays["[wall_icon]-[wall_state]"]
	if (!wall_overlay)
		wall_overlay = mutable_appearance('icons/turf/mining.dmi', wall_state, appearance_flags = RESET_TRANSFORM|RESET_COLOR)
		wall_overlays["[wall_icon]-[wall_state]"] = wall_overlay
	wall_overlay.plane = MUTATE_PLANE(WALL_PLANE, src)
	wall_overlay.color = color
	overlays += wall_overlay
