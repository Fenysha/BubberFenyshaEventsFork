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

	/**
	 * Primary open turfs by height band (RW_HEIGHT_BAND_* as string keys).
	 * Value: type path or weighted list.
	 */
	var/list/open_turf_by_height = list(
		RW_HEIGHT_BAND_0  = /turf/open/genturf,
		RW_HEIGHT_BAND_1  = /turf/open/genturf,
		RW_HEIGHT_BAND_2  = /turf/open/genturf,
		RW_HEIGHT_BAND_3  = /turf/open/genturf,
		RW_HEIGHT_BAND_4  = /turf/open/genturf,
		RW_HEIGHT_BAND_5  = /turf/open/genturf,
		RW_HEIGHT_BAND_6  = /turf/open/genturf,
		RW_HEIGHT_BAND_7  = /turf/open/genturf,
		RW_HEIGHT_BAND_8  = /turf/open/genturf,
		RW_HEIGHT_BAND_9  = /turf/open/genturf,
		RW_HEIGHT_BAND_10 = /turf/open/genturf,
	)

	/**
	 * Transition open turfs — used on geological edges between layers.
	 * Prefer the neighbouring bands material so borders blend.
	 * Same keys as open_turf_by_height.
	 */
	var/list/open_turf_by_height_transition = list(
		RW_HEIGHT_BAND_0  = /turf/open/genturf, // edge toward band 1
		RW_HEIGHT_BAND_1  = /turf/open/genturf, // blend 0 ↔ 2
		RW_HEIGHT_BAND_2  = /turf/open/genturf,
		RW_HEIGHT_BAND_3  = /turf/open/genturf,
		RW_HEIGHT_BAND_4  = /turf/open/genturf,
		RW_HEIGHT_BAND_5  = /turf/open/genturf,
		RW_HEIGHT_BAND_6  = /turf/open/genturf,
		RW_HEIGHT_BAND_7  = /turf/open/genturf,
		RW_HEIGHT_BAND_8  = /turf/open/genturf,
		RW_HEIGHT_BAND_9  = /turf/open/genturf,
		RW_HEIGHT_BAND_10 = /turf/open/genturf,
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


/datum/biome/rimworld/proc/get_turf_for_height(height, is_cave = FALSE, is_transition = FALSE)
	height = clamp(height, 0, 1)

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


/**
 * Populates cell generated turfs with biome content.
 * WARNING: It calls before all objects are loaded
 */
/datum/biome/rimworld/proc/populate_turf(
	turf/target_turf,
	flora_allowed,
	features_allowed,
	fauna_allowed
)
	if(!target_turf)
		return FALSE

	if(istype(target_turf, /turf/closed))
		return TRUE

	if(target_turf.turf_flags & TURF_BLOCKS_POPULATE_TERRAIN_FLORAFEATURES)
		return TRUE

	if(flora_allowed && prob(flora_density) && length(flora_types))
		var/flora_type = pick(flora_types)
		new flora_type(target_turf)
		return TRUE

	if(features_allowed && prob(feature_density) && length(feature_types))
		var/picked_feature = pick(feature_types)
		new picked_feature(target_turf)
		return TRUE

	if(fauna_allowed && prob(fauna_density) && length(fauna_types))
		var/picked_mob = pick(fauna_types)
		new picked_mob(target_turf)
		return TRUE

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
