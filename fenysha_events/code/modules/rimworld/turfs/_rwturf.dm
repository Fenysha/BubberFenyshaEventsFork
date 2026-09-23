/turf
	var/rw_turf_flags

/turf/open/bottom_or_region

/turf/closed/rw_wall
	name = "wall"
	desc = "A huge chunk of iron used to separate rooms."
	icon = 'icons/turf/walls/material_wall.dmi'
	icon_state = "material_wall-0"
	base_icon_state = "material_wall"
	explosive_resistance = 1
	rust_resistance = RUST_RESISTANCE_BASIC
	rw_turf_flags = NONE


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

	var/supports_roof = TRUE

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


/turf/closed/rw_wall/proc/is_roof_support_provider()
	return supports_roof
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


/turf/closed/rw_wall/add_large_wall_overlay(wall_icon, wall_state)
	var/static/list/mutable_appearance/wall_overlays = list()
	var/mutable_appearance/wall_overlay = wall_overlays["[wall_icon]-[wall_state]"]
	if (!wall_overlay)
		wall_overlay = mutable_appearance('icons/turf/mining.dmi', wall_state, appearance_flags = RESET_TRANSFORM|RESET_COLOR)
		wall_overlays["[wall_icon]-[wall_state]"] = wall_overlay
	wall_overlay.plane = MUTATE_PLANE(WALL_PLANE, src)
	wall_overlay.color = color
	overlays += wall_overlay


/datum/turf_roof
	var/name = "Roof"
	var/desc = "A simple roof."

	/// Blocks sunlight
	var/blocks_light = TRUE
	/// Blocks weather effects
	var/blocks_weather = TRUE
	/// Maximum distance to the nearest wall/support
	var/max_support_distance = 6
	/// Can this roof be removed by hand?
	var/can_be_removed = TRUE
	/// Damage dealt to objects and mobs on collapse
	var/collapse_damage = 60
	/// Debris type spawned on collapse
	var/collapse_debris_type = null

/datum/turf_roof/rock_thick
	name = "Thick Rock Roof"
	desc = "Meters of solid rock. Cannot be dismantled by hand."
	can_be_removed = FALSE
	max_support_distance = 6
	collapse_damage = 150

/datum/turf_roof/constructed
	name = "Constructed Roof"
	desc = "A simple roof made of planks and sheet metal."
	max_support_distance = 6
	collapse_damage = 40


// Global cache of roof datums
GLOBAL_LIST_EMPTY(roof_datums)

/proc/get_roof_datum(path)
	if(!ispath(path, /datum/turf_roof))
		return null
	if(!GLOB.roof_datums[path])
		GLOB.roof_datums[path] = new path()
	return GLOB.roof_datums[path]

/datum/element/roof
	element_flags = ELEMENT_BESPOKE | ELEMENT_DETACH_ON_HOST_DESTROY
	argument_hash_start_idx = 2

	/// The roof data this element is using
	var/datum/turf_roof/roof_data

/datum/element/roof/Attach(datum/target, datum/turf_roof/roof)
	. = ..()
	if(. == ELEMENT_INCOMPATIBLE)
		return

	if(!istype(target, /turf/open/rimworld) || !istype(roof))
		return ELEMENT_INCOMPATIBLE

	roof_data = roof

	var/turf/open/rimworld/T = target

	// Apply immediate effects
	T.apply_roof_effects(roof_data)

	// Register signals
	RegisterSignal(T, COMSIG_ATOM_EXAMINE, PROC_REF(on_examine))
	RegisterSignal(T, COMSIG_TURF_ROOF_SUPPORT_CHECK, PROC_REF(on_support_check))
	RegisterSignal(T, COMSIG_TURF_ROOF_COLLAPSE, PROC_REF(on_collapse))
	RegisterSignal(T, COMSIG_ATOM_ROOF_SUPPORT_LOST, PROC_REF(on_support_lost))

	// Immediate support check
	if(!check_support(T))
		on_collapse(T)

	SEND_SIGNAL(T, COMSIG_TURF_ROOF_ADDED, roof_data)
	return .

/datum/element/roof/Detach(datum/source, force)
	var/turf/open/rimworld/T = source
	if(istype(T))
		T.remove_roof_effects(roof_data)
		SEND_SIGNAL(T, COMSIG_TURF_ROOF_REMOVED, roof_data)

	UnregisterSignal(source, list(COMSIG_ATOM_EXAMINE, COMSIG_TURF_ROOF_SUPPORT_CHECK, COMSIG_TURF_ROOF_COLLAPSE, COMSIG_ATOM_ROOF_SUPPORT_LOST))
	roof_data = null
	return ..()

/datum/element/roof/proc/on_examine(datum/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	examine_list += span_notice("There is a roof above: <b>[roof_data.name]</b>.")
	examine_list += span_notice("[roof_data.desc]")

/datum/element/roof/proc/check_support(turf/open/rimworld/T)
	if(!T || !roof_data)
		return FALSE

	for(var/turf/closed/rw_wall/neighbor in RANGE_TURFS(roof_data.max_support_distance, T))
		if(neighbor.is_roof_support_provider())
			return TRUE
	return FALSE

/datum/element/roof/proc/on_support_check(datum/source)
	SIGNAL_HANDLER
	return check_support(source)

/datum/element/roof/proc/on_support_lost(datum/source)
	SIGNAL_HANDLER
	var/turf/open/rimworld/T = source
	if(!check_support(T))
		on_collapse(T)

/datum/element/roof/proc/on_collapse(datum/source)
	SIGNAL_HANDLER
	var/turf/open/rimworld/T = source
	if(!T || !roof_data)
		return

	T.visible_message(span_userdanger("The roof above [T] collapses!"))
	// playsound(T, 'sound/effects/collapse.ogg', 80, TRUE)

	for(var/mob/living/L in T)
		L.take_bodypart_damage(brute = roof_data.collapse_damage)
		L.Paralyze(4 SECONDS)
		to_chat(L, span_userdanger("The roof collapses on top of you!"))

	for(var/obj/structure/S in T)
		S.take_damage(roof_data.collapse_damage, BRUTE)

	if(roof_data.collapse_debris_type)
		new roof_data.collapse_debris_type(T)

	// Detach ourselves (this also fires COMSIG_TURF_ROOF_REMOVED)
	T.RemoveElement(/datum/element/roof, roof_data)

/turf/open/rimworld
	name = "ground"
	desc = "The ground."
	baseturfs = /turf/open/bottom_or_region

	flags_1 = NO_SCREENTIPS_1 | CAN_BE_DIRTY_1
	turf_flags = IS_SOLID | NO_RUST

	footstep = FOOTSTEP_FLOOR
	barefootstep = FOOTSTEP_HARD_BAREFOOT
	clawfootstep = FOOTSTEP_HARD_CLAW
	heavyfootstep = FOOTSTEP_GENERIC_HEAVY

	underfloor_accessibility = UNDERFLOOR_INTERACTABLE
	smoothing_groups = SMOOTH_GROUP_TURF_OPEN
	canSmoothWith = SMOOTH_GROUP_TURF_OPEN + SMOOTH_GROUP_OPEN_FLOOR

	rw_turf_flags = SUPPORTS_NATURE|SUPPORTS_MOBS

	/// Fertility of the soil (0.0 - 2.0+). Affects plant growth speed and quality.
	var/fertility = 0.0

	/// Whether heavy machinery / multi-tile structures can be placed here.
	var/can_support_heavy = TRUE
	/// Whether the turf can be tilled / turned into farmland.
	var/can_be_tilled = FALSE

	var/tiled_type
	/// Softness of the ground (affects sinking, footprints, some constructions).
	var/softness = 0.5		// 0.0 = hard rock, 1.0 = deep mud

	/// Temperature modifier (added to ambient temperature).
	var/temperature_mod = 0
	/// Humidity / moisture level (0.0 - 1.0). Affects plant growth & some buildings.
	var/moisture = 0.5
	/// Whether water can pool / flood here easily.
	var/floodable = TRUE

	/// Should this turf be created with a roof on map load?
	var/init_with_roof = FALSE
	/// Roof type used when init_with_roof is TRUE
	var/roof_type

	var/seasonal_color = FALSE

/turf/open/rimworld/Initialize(mapload)
	. = ..()

	if(seasonal_color)
		if(base_color)
			set_base_color(base_color)
		else if(color)
			set_base_color(color)
		AddElement(/datum/element/season_visual, CALLBACK(src, PROC_REF(update_season_visual)))

	if(init_with_roof && roof_type)
		var/datum/turf_roof/R = get_roof_datum(roof_type)
		if(R)
			AddElement(/datum/element/roof, R)

/turf/open/rimworld/examine(mob/user)
	. = ..()
	if(can_support_heavy)
		. += span_notice("Can support heavy structures.")
	else
		. += span_notice("Cannot support heavy structures.")
	if(fertility > 0)
		. += span_notice("Can grow plants with <b>[fertility * 100]%</b> efficiency.")
	else
		. += span_notice("Cannot grow plants.")


/turf/open/rimworld/proc/update_season_visual(atom/host, hemisphere, old_season, new_season, quadrum, year)
	if(!seasonal_color || !base_color)
		return
	var/tint
	var/amount
	switch(new_season)
		if(RW_SEASON_SPRING)
			tint = RW_SEASON_TINT_SPRING
			amount = RW_SEASON_TINT_AMOUNT_SPRING
		if(RW_SEASON_SUMMER)
			tint = RW_SEASON_TINT_SUMMER
			amount = RW_SEASON_TINT_AMOUNT_SUMMER
		if(RW_SEASON_FALL)
			tint = RW_SEASON_TINT_FALL
			amount = RW_SEASON_TINT_AMOUNT_FALL
		if(RW_SEASON_WINTER)
			tint = RW_SEASON_TINT_WINTER
			amount = RW_SEASON_TINT_AMOUNT_WINTER
		else
			reset_to_base_color()
			return
	modulate_color_towards(tint, amount)

/turf/open/rimworld/proc/set_roof(datum/turf_roof/roof_path)
	var/datum/turf_roof/R = get_roof_datum(roof_path)
	if(!R)
		return FALSE

	// Remove any existing roof first
	RemoveElement(/datum/element/roof)

	AddElement(/datum/element/roof, R)
	return TRUE

/turf/open/rimworld/proc/remove_roof(silent = FALSE)
	if(!HAS_TRAIT(src, TRAIT_HAS_ROOF))
		return FALSE
	if(!silent)
		visible_message(span_notice("The roof above [src] has been dismantled."))

	RemoveElement(/datum/element/roof)
	return TRUE

/turf/open/rimworld/proc/has_roof()
	return HAS_TRAIT(src, TRAIT_HAS_ROOF)

/turf/open/rimworld/proc/apply_roof_effects(datum/turf_roof/roof)
	INVOKE_ASYNC(SSdaylight, TYPE_PROC_REF(/datum/controller/subsystem/daylight, refresh_turf_daylight), src)
	// You can expand this later (weather blocking, temperature, etc.)
	return TRUE

/turf/open/rimworld/proc/remove_roof_effects(datum/turf_roof/roof)
	INVOKE_ASYNC(SSdaylight, TYPE_PROC_REF(/datum/controller/subsystem/daylight, refresh_turf_daylight), src)
	return TRUE

/turf/open/rimworld/proc/get_fertility()
	return fertility

/turf/open/rimworld/proc/can_support_structure(obj/structure/S)
	return TRUE

/turf/open/rimworld/proc/can_grow_plants()
	return fertility > 0.0

/turf/open/rimworld/proc/get_growth_multiplier()
	return fertility * (0.5 + moisture * 0.5)

/turf/open/rimworld/attackby(obj/item/I, mob/user, params)
	if(can_be_tilled && I.tool_behaviour == TOOL_HOE && tiled_type)
		if(do_after(user, 3 SECONDS, src))
			to_chat(user, span_notice("You till the ground."))
			ChangeTurf(tiled_type)
			return TRUE
	return ..()
