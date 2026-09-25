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

	var/solid_height_threshold = 0.366
	var/list/open_band_thresholds
	var/list/open_band_turfs
	var/list/open_transition_thresholds
	var/list/open_transition_turfs
	var/list/closed_band_thresholds
	var/list/closed_band_turfs
	var/list/closed_transition_thresholds
	var/list/closed_transition_turfs

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

	solid_height_threshold = text2num(RW_HEIGHT_BAND_KEY_SOLID)
	var/list/open_bands = compile_height_bands(open_turf_by_height)
	open_band_thresholds = open_bands[1]
	open_band_turfs = open_bands[2]
	var/list/open_transitions = compile_height_bands(open_turf_by_height_transition)
	open_transition_thresholds = open_transitions[1]
	open_transition_turfs = open_transitions[2]
	var/list/closed_bands = compile_height_bands(closed_turf_by_height)
	closed_band_thresholds = closed_bands[1]
	closed_band_turfs = closed_bands[2]
	var/list/closed_transitions = compile_height_bands(closed_turf_by_height_transition)
	closed_transition_thresholds = closed_transitions[1]
	closed_transition_turfs = closed_transitions[2]

/datum/biome/rimworld/proc/compile_height_bands(list/table)
	var/list/thresholds = list()
	var/list/entries = list()
	if(!length(table))
		return list(thresholds, entries)

	for(var/threshold_key in table)
		var/threshold = text2num(threshold_key)
		if(isnull(threshold))
			continue
		var/inserted = FALSE
		for(var/i in 1 to length(thresholds))
			if(threshold < thresholds[i])
				thresholds.Insert(i, threshold)
				entries.Insert(i, table[threshold_key])
				inserted = TRUE
				break
		if(!inserted)
			thresholds += threshold
			entries += table[threshold_key]

	return list(thresholds, entries)

/datum/biome/rimworld/proc/pick_compiled_band(list/thresholds, list/entries, height)
	for(var/i in length(thresholds) to 1 step -1)
		if(height < thresholds[i])
			continue
		var/entry = entries[i]
		if(islist(entry))
			return pick(entry)
		return entry
	return null


/datum/biome/rimworld/proc/get_turf_for_height(height, sub_biome, is_cave = FALSE, is_transition = FALSE)
	height = clamp(height * height_modifier * get_subbiome_height_modifier(sub_biome), 0, 1)

	if(is_cave)
		if(open_turf_type_cave)
			return open_turf_type_cave

		if(is_transition && prob(transition_chance))
			return pick_compiled_band(open_transition_thresholds, open_transition_turfs, height) || open_turf_type
		return pick_compiled_band(open_band_thresholds, open_band_turfs, height) || open_turf_type

	if(height >= solid_height_threshold)
		if(is_transition && prob(transition_chance))
			return pick_compiled_band(closed_transition_thresholds, closed_transition_turfs, height) || closed_turf_type
		return pick_compiled_band(closed_band_thresholds, closed_band_turfs, height) || closed_turf_type

	if(is_transition && prob(transition_chance))
		return pick_compiled_band(open_transition_thresholds, open_transition_turfs, height) || open_turf_type

	return pick_compiled_band(open_band_thresholds, open_band_turfs, height) || open_turf_type


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
	list/deferred_init = null,
	planned_kind = null
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

	if(!isnull(planned_kind))
		return spawn_planned(target_turf, planned_kind, is_cave, deferred_init)

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


/datum/biome/rimworld/proc/spawn_planned(turf/target_turf, kind, is_cave, list/deferred_init)
	if(!kind)
		return TRUE

	var/list/table
	switch(kind)
		if(1)
			table = pick_content_table(flora_types, cave_flora_types, is_cave)
		if(2)
			table = pick_content_table(feature_types, cave_feature_types, is_cave)
		if(3)
			table = pick_content_table(fauna_types, cave_fauna_types, is_cave)

	if(!length(table))
		return TRUE

	var/picked = pick(table)
	if(!picked)
		return TRUE

	var/atom/spawned = SSatoms.NewUninitialized(picked, target_turf)
	if(spawned && deferred_init)
		deferred_init += spawned
	return TRUE


/datum/biome/rimworld/proc/stamp_rules(sub_biome_key)
	var/list/turf_meta = list()
	var/list/seen = list()
	note_stamp_turf(open_turf_type, turf_meta, seen)
	note_stamp_turf(closed_turf_type, turf_meta, seen)
	if(open_turf_type_cave)
		note_stamp_turf(open_turf_type_cave, turf_meta, seen)
	note_stamp_turf(/turf/open/rimworld/dirt/mud, turf_meta, seen)

	return list(
		"height_modifier" = height_modifier * get_subbiome_height_modifier(sub_biome_key),
		"solid_threshold" = solid_height_threshold,
		"transition_chance" = transition_chance,
		"transition_delta" = RW_HEIGHT_TRANSITION_DELTA,
		"cave_turf" = open_turf_type_cave ? "[open_turf_type_cave]" : "",
		"fallback_open" = "[open_turf_type]",
		"mud_path" = "/turf/open/rimworld/dirt/mud",
		"fallback_closed" = "[closed_turf_type]",
		"open_bands" = encode_stamp_bands(open_band_thresholds, open_band_turfs, turf_meta, seen),
		"open_transition_bands" = encode_stamp_bands(open_transition_thresholds, open_transition_turfs, turf_meta, seen),
		"closed_bands" = encode_stamp_bands(closed_band_thresholds, closed_band_turfs, turf_meta, seen),
		"closed_transition_bands" = encode_stamp_bands(closed_transition_thresholds, closed_transition_turfs, turf_meta, seen),
		"flora" = encode_stamp_weights(flora_types),
		"flora_cave" = encode_stamp_weights(cave_flora_types),
		"feature" = encode_stamp_weights(feature_types),
		"feature_cave" = encode_stamp_weights(cave_feature_types),
		"fauna" = encode_stamp_weights(fauna_types),
		"fauna_cave" = encode_stamp_weights(cave_fauna_types),
		"flora_density" = flora_density * get_density_mult(RW_SPAWN_FLORA, sub_biome_key),
		"feature_density" = feature_density * get_density_mult(RW_SPAWN_FEATURE, sub_biome_key),
		"fauna_density" = fauna_density * get_density_mult(RW_SPAWN_MOB, sub_biome_key),
		"turfs" = turf_meta,
	)


/datum/biome/rimworld/proc/encode_stamp_bands(list/thresholds, list/entries, list/turf_meta, list/seen)
	var/list/out = list()
	for(var/i in 1 to length(thresholds))
		out += list(list(
			"threshold" = thresholds[i],
			"options" = encode_stamp_weights(entries[i], turf_meta, seen, TRUE),
		))
	return out


/datum/biome/rimworld/proc/encode_stamp_weights(table, list/turf_meta, list/seen, register_turfs = FALSE)
	var/list/out = list()
	if(isnull(table))
		return out
	if(!islist(table))
		if(register_turfs)
			note_stamp_turf(table, turf_meta, seen)
		return list(stamp_weight(table, 1))
	if(!length(table))
		return out

	var/first = table[1]
	if(!isnull(table[first]) && isnum(table[first]))
		for(var/path in table)
			if(register_turfs)
				note_stamp_turf(path, turf_meta, seen)
			out += list(stamp_weight(path, table[path]))
		return out

	var/list/counts = list()
	for(var/path in table)
		counts["[path]"] += 1
		if(register_turfs)
			note_stamp_turf(path, turf_meta, seen)
	for(var/path in counts)
		out += list(stamp_weight(path, counts[path]))
	return out


/datum/biome/rimworld/proc/stamp_weight(path, weight)
	var/foliage = ""
	var/variants = 0
	if(ispath(path, /obj/structure/rimworld/flora/grayscale))
		var/obj/structure/rimworld/flora/grayscale/plant = path
		foliage = "[initial(plant.foliage_color)]"
		if(ispath(path, /obj/structure/rimworld/flora/grayscale/grass))
			var/obj/structure/rimworld/flora/grayscale/grass/tuft = path
			variants = initial(tuft.variant_amount)
		else if(ispath(path, /obj/structure/rimworld/flora/grayscale/tree))
			var/obj/structure/rimworld/flora/grayscale/tree/tree = path
			variants = initial(tree.variants)
	return list("path" = "[path]", "weight" = weight, "color" = foliage, "variants" = variants)


/datum/biome/rimworld/proc/note_stamp_turf(path, list/turf_meta, list/seen)
	if(!ispath(path))
		return
	var/key = "[path]"
	if(seen[key])
		return
	seen[key] = TRUE
	var/nature = 0
	var/blend = 0
	var/color = ""
	var/edge_priority = 0
	var/cardinal = 0
	var/edge_mask = 0
	var/smooth = 0
	var/rock = 0
	var/variants = 0
	var/water = 0
	if(ispath(path, /turf/open))
		var/turf/open/open_sample = path
		edge_priority = initial(open_sample.edge_priority)
		if(initial(open_sample.cardinal_edges_only))
			cardinal = 1
		var/sample_icon = initial(open_sample.icon)
		var/bit = 1
		for(var/direction in list(NORTH, SOUTH, EAST, WEST, NORTHEAST, NORTHWEST, SOUTHEAST, SOUTHWEST))
			var/edge_state = TURF_EDGE_STATE_FOR_DIR(direction)
			if(sample_icon && edge_state && icon_exists(sample_icon, edge_state))
				edge_mask |= bit
			bit *= 2
	if(ispath(path, /turf/open/rimworld))
		var/turf/open/rimworld/sample = path
		if(initial(sample.rw_turf_flags) & SUPPORTS_NATURE)
			nature = 1
		if(ispath(path, /turf/open/rimworld/grass))
			var/turf/open/rimworld/grass/grass = path
			color = "[initial(grass.color)]"
			blend = 1
			variants = initial(grass.variant_amount) + 1
		else if(ispath(path, /turf/open/rimworld/dirt))
			var/turf/open/rimworld/dirt/dirt = path
			variants = initial(dirt.variant_amount) + 1
	if(ispath(path, /turf/open/rimworld/rock) || ispath(path, /turf/closed/rw_wall/rock))
		rock = 1
	if(ispath(path, /turf/open/water))
		water = 1
	if(ispath(path, /turf/closed))
		var/turf/closed/closed_sample = path
		if(initial(closed_sample.smoothing_flags) & SMOOTH_BITMASK)
			smooth = 1
	turf_meta += list(list(
		"path" = key,
		"nature" = nature,
		"blend" = blend,
		"color" = color,
		"edge_priority" = edge_priority,
		"cardinal" = cardinal,
		"edge_mask" = edge_mask,
		"smooth" = smooth,
		"rock" = rock,
		"variants" = variants,
		"water" = water,
	))


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
