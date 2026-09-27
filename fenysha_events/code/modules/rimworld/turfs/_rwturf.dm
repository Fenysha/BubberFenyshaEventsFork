/turf
	var/rw_turf_flags


// One shared mix for every outdoor tile. Planetary atmos would allocate a gas_mixture per turf.
/datum/gas_mixture/immutable/planetary/rimworld/New()
	..()
	parse_string_immutable(OPENTURF_DEFAULT_ATMOS)

/turf/open/rimworld
	name = "ground"
	desc = "The ground."
	baseturfs = /turf/open/bottom_or_region
	blocks_air = TRUE
	init_air = FALSE

	var/static/datum/gas_mixture/immutable/planetary/rimworld/static_air

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
	/// Set when the loader already applied the finished color. Init must not paint it again.
	var/stamp_visual = FALSE

/turf/open/rimworld/Initialize(mapload)
	if(!static_air)
		static_air = new
	air = static_air
	. = ..()

	if(seasonal_color)
		if(!stamp_visual)
			if(base_color)
				set_base_color(base_color)
			else if(color)
				set_base_color(color)
		AddElement(/datum/element/season_visual, CALLBACK(src, PROC_REF(update_season_visual)))

	if(init_with_roof && roof_type)
		var/datum/turf_roof/R = get_roof_datum(roof_type)
		if(R)
			AddElement(/datum/element/roof, R)

/turf/open/rimworld/AfterChange(flags, oldType)
	levelupdate()
	RemoveLattice()

/turf/open/rimworld/air_update_turf(update = FALSE, remove = FALSE)
	return

/turf/open/rimworld/atmos_spawn_air(text)
	return

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
	if(stamp_visual && !old_season)
		return
	stamp_visual = FALSE
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
