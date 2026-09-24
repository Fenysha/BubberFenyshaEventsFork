/datum/biome/rimworld
	var/biome_key

	/// ======== BIOME STATS =========

	/// How does this biome affect traversability on the planet map? 1.0 by default, less - faster, more - slower
	var/speed_modifier = 1.0
	/// Is it possible to traverse this biome on the planet map?
	var/passable = TRUE
	/// Is it possible to fly across this biome? Drop-pods or flying vehicles.
	var/passable_flying = TRUE
	/// Is it possible to load a cell containing this region?
	/// This will determine whether settlements or any points of interest will appear in this region on the map.
	var/loadable = TRUE

	/// ======== GENERATION =========


	var/height_modifier = 1.0
	/**
	 * Primary open turfs by height band (RW_HEIGHT_BAND_* as string keys).
	 * Value: type path or weighted list.
	 */
	var/list/open_turf_by_height = list(
		RW_HEIGHT_BAND_KEY_0  = /turf/open/genturf,
		RW_HEIGHT_BAND_KEY_1  = /turf/open/genturf,
		RW_HEIGHT_BAND_KEY_2  = /turf/open/genturf,
		RW_HEIGHT_BAND_KEY_3  = /turf/open/genturf,
		RW_HEIGHT_BAND_KEY_4  = /turf/open/genturf,
		RW_HEIGHT_BAND_KEY_5  = /turf/open/genturf,
		RW_HEIGHT_BAND_KEY_6  = /turf/open/genturf,
		RW_HEIGHT_BAND_KEY_7  = /turf/open/genturf,
		RW_HEIGHT_BAND_KEY_8  = /turf/open/genturf,
		RW_HEIGHT_BAND_KEY_9  = /turf/open/genturf,
		RW_HEIGHT_BAND_KEY_10 = /turf/open/genturf,
	)

	/**
	 * Transition open turfs — used on geological edges between layers.
	 * Prefer the neighbouring bands material so borders blend.
	 * Same keys as open_turf_by_height.
	 */
	var/list/open_turf_by_height_transition = list(
		RW_HEIGHT_BAND_KEY_0  = /turf/open/genturf,
		RW_HEIGHT_BAND_KEY_1  = /turf/open/genturf,
		RW_HEIGHT_BAND_KEY_2  = /turf/open/genturf,
		RW_HEIGHT_BAND_KEY_3  = /turf/open/genturf,
		RW_HEIGHT_BAND_KEY_4  = /turf/open/genturf,
		RW_HEIGHT_BAND_KEY_5  = /turf/open/genturf,
		RW_HEIGHT_BAND_KEY_6  = /turf/open/genturf,
		RW_HEIGHT_BAND_KEY_7  = /turf/open/genturf,
		RW_HEIGHT_BAND_KEY_8  = /turf/open/genturf,
		RW_HEIGHT_BAND_KEY_9  = /turf/open/genturf,
		RW_HEIGHT_BAND_KEY_10 = /turf/open/genturf,
	)

	/**
	 * Closed turfs by height (normally only SOLID+).
	 * Extra keys allowed if a biome wants staggered wall types.
	 */
	var/list/closed_turf_by_height = list(
		RW_HEIGHT_BAND_KEY_SOLID = /turf/closed/rw_wall/rock/auto,
	)

	var/list/closed_turf_by_height_transition = list(
		RW_HEIGHT_BAND_KEY_SOLID = /turf/closed/rw_wall/rock/auto,
	)

	var/open_turf_type_cave = null
	var/transition_chance = 35

	open_turf_type = /turf/open/genturf
	closed_turf_type = /turf/closed/rw_wall/rock/auto

	/// Base chance (0-100) to attempt flora on an eligible open turf.
	flora_density = 0
	/// Base chance to attempt a special feature (geyser, rock formation, etc.).
	feature_density = 0
	/// Base chance to attempt fauna.
	fauna_density = 0

	/// Weighted type paths. Empty = never spawn that category.
	flora_types = list()
	feature_types = list()
	fauna_types = list()

	/// Optional cave-only overrides. If null, surface tables are reused.
	var/list/cave_flora_types = null
	var/list/cave_feature_types = null
	var/list/cave_fauna_types = null


	megafauna_types = null


	feature_exclusion_radius = 6
	mob_exclusion_radius = 10
	tendril_exclusion_radius = 12

	var/flora_soft_radius = 2
	var/flora_soft_penalty = 0.55  // multiply density by this when soft-blocked

	/// Multipliers applied to density based on current sub-biome key.
	/// Missing key → 1.0
	var/list/subbiome_flora_mult = list(
		RW_SUBBIOME_SHORE        = 0.7,
		RW_SUBBIOME_PLAINS       = 1.0,
		RW_SUBBIOME_MARSH        = 1.35,
		RW_SUBBIOME_ROCKY_HILLS  = 0.45,
		RW_SUBBIOME_FOREST_HILLS = 1.55,
	)
	var/list/subbiome_feature_mult = list(
		RW_SUBBIOME_SHORE        = 0.8,
		RW_SUBBIOME_PLAINS       = 1.0,
		RW_SUBBIOME_MARSH        = 1.2,
		RW_SUBBIOME_ROCKY_HILLS  = 1.4,
		RW_SUBBIOME_FOREST_HILLS = 0.9,
	)
	var/list/subbiome_fauna_mult = list(
		RW_SUBBIOME_SHORE        = 0.6,
		RW_SUBBIOME_PLAINS       = 1.0,
		RW_SUBBIOME_MARSH        = 1.15,
		RW_SUBBIOME_ROCKY_HILLS  = 0.85,
		RW_SUBBIOME_FOREST_HILLS = 1.25,
	)

	/// When TRUE, flora/feature/fauna attempts are mutually exclusive on one turf
	/// (first success wins: flora → feature → fauna).
	var/exclusive_content = TRUE

	/// Runtime: set by generator before a populate pass so exclusion works across turfs.
	/// Structure: list(category = list(turf, turf, ...))
	var/list/spawn_book = null


/datum/biome/rimworld/New()
	. = ..()
	if(islist(cave_flora_types) && length(cave_flora_types))
		cave_flora_types = expand_weights(fill_with_ones(cave_flora_types))
	if(islist(cave_feature_types) && length(cave_feature_types))
		cave_feature_types = expand_weights(fill_with_ones(cave_feature_types))
	if(islist(cave_fauna_types) && length(cave_fauna_types))
		cave_fauna_types = expand_weights(fill_with_ones(cave_fauna_types))


/datum/biome/rimworld/proc/get_turf_for_height(height, sub_biome, is_cave = FALSE, is_transition = FALSE)
	height = clamp(height * height_modifier * get_subbiome_height_modifier(sub_biome), 0, 1)

	if(is_cave)
		if(open_turf_type_cave)
			return open_turf_type_cave

		return pick_from_height_table(
			open_turf_by_height,
			open_turf_by_height_transition,
			height,
			is_transition
		) || open_turf_type

	if(height >= text2num(RW_HEIGHT_BAND_KEY_SOLID))
		return pick_from_height_table(
			closed_turf_by_height,
			closed_turf_by_height_transition,
			height,
			is_transition
		) || closed_turf_type

	return pick_from_height_table(
		open_turf_by_height,
		open_turf_by_height_transition,
		height,
		is_transition
	) || open_turf_type


/datum/biome/rimworld/proc/pick_from_height_table(list/primary, list/secondary, height, is_transition)
	if(!length(primary))
		return null

	var/list/table = primary

	if(is_transition && length(secondary) && prob(transition_chance))
		table = secondary

	var/best_threshold = null
	var/best_entry = null

	for(var/threshold_key in table)
		var/t = text2num(threshold_key)

		if(isnull(t))
			continue

		if(height < t)
			continue

		if(isnull(best_threshold) || t > best_threshold)
			best_threshold = t
			best_entry = table[threshold_key]

	if(isnull(best_entry))
		return null

	if(islist(best_entry))
		return pick(best_entry)

	return best_entry


/datum/biome/rimworld/proc/get_subbiome_height_modifier(subiome_key)
	switch(subiome_key)
		if(RW_SUBBIOME_SHORE)
			return 2
		if(RW_SUBBIOME_PLAINS)
			return 2
		if(RW_SUBBIOME_MARSH)
			return 1.70
		if(RW_SUBBIOME_ROCKY_HILLS)
			return 0.91
		if(RW_SUBBIOME_FOREST)
			return 2.11
		if(RW_SUBBIOME_FOREST_HILLS)
			return 0.89
		else
			return 1


/// Call once at the start of a cell population pass so exclusion radii work.
/datum/biome/rimworld/proc/begin_population_pass()
	spawn_book = list(
		RW_SPAWN_FLORA     = list(),
		RW_SPAWN_FEATURE   = list(),
		RW_SPAWN_MOB       = list(),
	)


/datum/biome/rimworld/proc/end_population_pass()
	spawn_book = null


/datum/biome/rimworld/proc/get_density_mult(category, sub_biome_key)
	var/list/table
	switch(category)
		if(RW_SPAWN_FLORA)
			table = subbiome_flora_mult
		if(RW_SPAWN_FEATURE)
			table = subbiome_feature_mult
		if(RW_SPAWN_MOB)
			table = subbiome_fauna_mult
		else
			return 1.0

	if(!islist(table) || isnull(table[sub_biome_key]))
		return 1.0
	return table[sub_biome_key]


/datum/biome/rimworld/proc/pick_content_table(list/surface, list/cave, is_cave)
	if(is_cave && islist(cave) && length(cave))
		return cave
	return surface


/datum/biome/rimworld/proc/within_exclusion(turf/T, category, radius)
	if(!spawn_book || !length(spawn_book[category]) || radius <= 0)
		return FALSE
	for(var/turf/other as anything in spawn_book[category])
		if(get_dist(T, other) <= radius)
			return TRUE
	return FALSE


/datum/biome/rimworld/proc/record_spawn(turf/T, category)
	if(!spawn_book)
		return
	spawn_book[category] += T

/**
 * Populates a single open turf.
 * Content is created deferred and initialized later by the sub-level loader.
 *
 * target_turf     turf to decorate
 * flora_allowed
 * features_allowed
 * fauna_allowed
 * is_cave         optional — if the generator knows this tile is a cave
 * sub_biome_key   optional — defaults to plains-style if omitted
 */
/datum/biome/rimworld/proc/populate_turf(
	turf/target_turf,
	flora_allowed,
	features_allowed,
	fauna_allowed,
	is_cave = FALSE,
	sub_biome_key = null,
	list/deferred_init = null
)
	if(!target_turf)
		return FALSE

	if(istype(target_turf, /turf/open/rimworld))
		var/turf/open/rimworld/rw_open_turf = target_turf
		if(!(rw_open_turf.rw_turf_flags & SUPPORTS_NATURE))
			return TRUE
	else
		return TRUE

	if(target_turf.turf_flags & TURF_BLOCKS_POPULATE_TERRAIN_FLORAFEATURES)
		return TRUE

	if(isnull(sub_biome_key))
		sub_biome_key = RW_SUBBIOME_PLAINS

	var/list/flora_table = pick_content_table(flora_types, cave_flora_types, is_cave)
	var/list/feature_table = pick_content_table(feature_types, cave_feature_types, is_cave)
	var/list/fauna_table = pick_content_table(fauna_types, cave_fauna_types, is_cave)

	if(flora_allowed && length(flora_table))
		var/eff_density = flora_density * get_density_mult(RW_SPAWN_FLORA, sub_biome_key)
		if(within_exclusion(target_turf, RW_SPAWN_FLORA, flora_soft_radius))
			eff_density *= flora_soft_penalty

		if(prob(eff_density))
			var/flora_type = pick(flora_table)
			if(flora_type)
				var/atom/flora = SSatoms.NewUninitialized(flora_type, target_turf)
				if(flora && deferred_init)
					deferred_init += flora
				record_spawn(target_turf, RW_SPAWN_FLORA)
				if(exclusive_content)
					return TRUE

	if(features_allowed && length(feature_table))
		var/eff_density = feature_density * get_density_mult(RW_SPAWN_FEATURE, sub_biome_key)
		if(prob(eff_density) && !within_exclusion(target_turf, RW_SPAWN_FEATURE, feature_exclusion_radius))
			var/picked_feature = pick(feature_table)
			if(picked_feature)
				var/atom/feature = SSatoms.NewUninitialized(picked_feature, target_turf)
				if(feature && deferred_init)
					deferred_init += feature
				record_spawn(target_turf, RW_SPAWN_FEATURE)
				if(exclusive_content)
					return TRUE

	if(fauna_allowed && length(fauna_table))
		var/eff_density = fauna_density * get_density_mult(RW_SPAWN_MOB, sub_biome_key)
		if(prob(eff_density) && !within_exclusion(target_turf, RW_SPAWN_MOB, mob_exclusion_radius))
			var/picked_mob = pick(fauna_table)
			if(picked_mob)
				var/atom/fauna = SSatoms.NewUninitialized(picked_mob, target_turf)
				if(fauna && deferred_init)
					deferred_init += fauna
				record_spawn(target_turf, RW_SPAWN_MOB)

	return TRUE




/datum/biome/rimworld/land
	/// Generic terrestrial biome.
	/// Terrain reaching the solid height threshold becomes a closed rock wall.
	closed_turf_by_height = list(
		RW_HEIGHT_BAND_KEY_SOLID = /turf/closed/rw_wall/rock/auto,
	)

	closed_turf_by_height_transition = list(
		RW_HEIGHT_BAND_KEY_SOLID = /turf/closed/rw_wall/rock/auto,
	)

	closed_turf_type = /turf/closed/rw_wall/rock/auto


/datum/biome/rimworld/water
	/// Water biomes never generate closed terrain.
	closed_turf_by_height = list()
	closed_turf_by_height_transition = list()

	open_turf_type = /turf/open/water
	closed_turf_type = /turf/open/water
