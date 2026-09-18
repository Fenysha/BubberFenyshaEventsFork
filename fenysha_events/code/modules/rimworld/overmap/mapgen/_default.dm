/**
 * Creates an atom without running Initialize.
 *
 * The INITIALIZATION_INSSATOMS state is active ONLY for the duration of this
 * single `new` call (including any nested `new` inside that atom's New()).
 * It is cleared before this proc returns, so CHECK_TICK / other systems are
 * unaffected and keep normal immediate initialization.
 *
 * Collect the returned atoms and pass them to InitializeAtoms() when ready.
 */
/datum/controller/subsystem/atoms/proc/NewUninitialized(path, atom/newloc)
	if(!ispath(path, /atom))
		CRASH("NewUninitialized: [path] is not an /atom path")

	var/static/uid = 0
	uid = WRAP_UID(uid + 1)
	var/source = "NewUninitialized [uid]"

	set_tracked_initalized(INITIALIZATION_INSSATOMS, source)
	var/atom/created = new path(newloc)
	clear_tracked_initalize(source)

	return created


/**
 * Same as NewUninitialized, but forwards extra arguments to New/Initialize later.
 * Extra args are stored on the atom only if you need them — by default mapload
 * InitializeAtoms always passes list(TRUE) as mapload.
 *
 * Prefer NewUninitialized for turfs; use this when the type expects args.
 */
/datum/controller/subsystem/atoms/proc/NewUninitializedArgs(path, atom/newloc, list/extra_args)
	if(!ispath(path, /atom))
		CRASH("NewUninitializedArgs: [path] is not an /atom path")

	var/static/uid = 0
	uid = WRAP_UID(uid + 1)
	var/source = "NewUninitializedArgs [uid]"

	set_tracked_initalized(INITIALIZATION_INSSATOMS, source)
	var/atom/created
	if(length(extra_args))
		created = new path(arglist(list(newloc) + extra_args))
	else
		created = new path(newloc)
	clear_tracked_initalize(source)

	return created


/datum/map_generator/sub_level
	/// Parent planetary map.
	var/datum/rimworld_planet/planet

	/// Planet cell currently being generated.
	var/datum/planet_cell/cell

	/// Global planetary cell coordinates.
	var/planet_x = 1
	var/planet_y = 1

	/// Cached 3x3 neighbourhood of macro elevation values.
	var/list/elevation_matrix

	/// Whether Rust should generate cave information.
	var/generate_caves = TRUE

	/// ------------------------------------------------------------------------
	/// Generated local data
	/// ------------------------------------------------------------------------

	/// Complete local heightmap returned by Rust.
	/// Index:
	///
	///     width * (local_y - 1) + local_x
	///
	var/list/heights

	/// Complete cave mask returned by Rust.
	var/list/cave_mask

	/// Local map dimensions.
	var/width = 0
	var/height = 0

	/// Biome controlling local turf selection.
	var/datum/biome/rimworld/target_biome

	/// Area assigned to the generated cell.
	var/area/rimworld/rimworld_area

	/// ------------------------------------------------------------------------
	/// Generated atom collections
	/// ------------------------------------------------------------------------

	/// Every newly generated turf.
	var/list/generated_turfs = list()

	/// Only open turfs.
	/// Used later for flora / feature / fauna population.
	var/list/generated_open_turfs = list()

	/// All atoms that still need deferred initialization.
	/// The area is inserted first.
	var/list/pending_init = list()

	/// TRUE after InitializeAtoms() has been executed for the whole map.
	var/turfs_initialized = FALSE


/datum/map_generator/sub_level/proc/setup_planet_context(
	datum/rimworld_planet/P,
	px,
	py,
	datum/planet_cell/C
)
	planet = P
	planet_x = px
	planet_y = py
	cell = C

	cache_planetary_neighborhood()



/datum/map_generator/sub_level/proc/cache_planetary_neighborhood()
	if(!planet)
		return FALSE

	elevation_matrix = list()

	for(var/dx in -1 to 1)
		var/dx_key = "[dx]"
		elevation_matrix[dx_key] = list()

		for(var/dy in -1 to 1)
			var/dy_key = "[dy]"

			var/target_x = planet_x + dx
			var/target_y = planet_y + dy
			var/value

			if(planet.is_valid_coordinate(target_x, target_y))
				value = planet.get_elevation_level(
					target_x,
					target_y
				)
			else
				value = planet.get_elevation_level(
					planet_x,
					planet_y
				)

			// Normalize the value to a real number.
			// get_elevation_level() may return a textual value.
			if(!isnum(value))
				value = text2num("[value]")

			if(isnull(value))
				log_world(
					"RimWorld sub-level: invalid elevation value \
					for planetary coordinate [target_x],[target_y]."
				)
				return FALSE

			// Elevation categories are represented by u8 on the Rust side.
			value = clamp(round(value), 0, 255)

			elevation_matrix[dx_key][dy_key] = value

	return TRUE


/**
 * Resolves the RimWorld biome used for this planetary cell.
 *
 * The macro biome is determined by the planetary generator from elevation,
 * heat and humidity.
 */
/datum/map_generator/sub_level/proc/get_target_biome()
	if(!planet)
		return null

	var/macro_elevation = planet.get_elevation_level(
		planet_x,
		planet_y
	)

	var/macro_heat = planet.get_heat_level(
		planet_x,
		planet_y
	)

	var/macro_humidity = planet.get_humidity_level(
		planet_x,
		planet_y
	)

	var/macro_biome = planet.get_biome(
		planet_x,
		planet_y,
		macro_elevation,
		macro_heat,
		macro_humidity
	)

	var/biome_type = planet.get_possible_biomes()[macro_biome]
	var/datum/biome/rimworld/resolved_biome

	if(biome_type)
		resolved_biome = SSmapping.biomes[biome_type]

	// Never fall back to a biome outside the RimWorld hierarchy.
	if(!istype(resolved_biome, /datum/biome/rimworld))
		resolved_biome = SSmapping.biomes[/datum/biome/rimworld/grassland]

	return resolved_biome


/**
 * Determines whether a local heightmap position lies on a geological
 * transition.
 *
 * This operates directly on the heightmap, so generation order does not
 * matter.
 */
/datum/map_generator/sub_level/proc/is_geological_transition_xy(
	local_x,
	local_y
)
	if(!length(heights))
		return FALSE

	if(local_x < 1 || local_x > width)
		return FALSE

	if(local_y < 1 || local_y > height)
		return FALSE

	var/index = width * (local_y - 1) + local_x
	var/current_height = heights[index]

	// West
	if(local_x > 1)
		if(abs(current_height - heights[index - 1]) >= RW_HEIGHT_TRANSITION_DELTA)
			return TRUE

	// East
	if(local_x < width)
		if(abs(current_height - heights[index + 1]) >= RW_HEIGHT_TRANSITION_DELTA)
			return TRUE

	// South
	if(local_y > 1)
		if(abs(current_height - heights[index - width]) >= RW_HEIGHT_TRANSITION_DELTA)
			return TRUE

	// North
	if(local_y < height)
		if(abs(current_height - heights[index + width]) >= RW_HEIGHT_TRANSITION_DELTA)
			return TRUE

	return FALSE


/**
 * ============================================================================
 * Preparation
 * ============================================================================
 *
 * Does everything which must exist before individual turfs can be placed.
 *
 * Nothing is initialized here.
 */
/datum/map_generator/sub_level/proc/prepare_sub_level_terrain(
	datum/turf_reservation/sub_level/reservation
)
	if(!planet || !cell || !reservation)
		return FALSE

	var/turf/BL = reservation.get_bottom_left_turf()
	var/turf/TR = reservation.get_top_right_turf()

	if(!BL || !TR)
		return FALSE

	width = reservation.width
	height = reservation.height

	if(width <= 0 || height <= 0)
		return FALSE

	target_biome = get_target_biome()

	if(!target_biome)
		log_world(
			"RimWorld sub-level: unable to resolve biome for [planet_x],[planet_y]."
		)
		return FALSE


	if(!length(elevation_matrix))
		cache_planetary_neighborhood()

	if(!length(elevation_matrix))
		return FALSE

	var/list/neigh = list(
		text2num("[elevation_matrix["-1"]["-1"]]"),
		text2num("[elevation_matrix["0"]["-1"]]"),
		text2num("[elevation_matrix["1"]["-1"]]"),

		text2num("[elevation_matrix["-1"]["0"]]"),
		text2num("[elevation_matrix["0"]["0"]]"),
		text2num("[elevation_matrix["1"]["0"]]"),

		text2num("[elevation_matrix["-1"]["1"]]"),
		text2num("[elevation_matrix["0"]["1"]]"),
		text2num("[elevation_matrix["1"]["1"]]")
	)


	var/list/config = list(
		"planet_seed" = planet.seed,
		"planet_x" = planet_x,
		"planet_y" = planet_y,

		"width" = width,
		"height" = height,

		"neighbourhood" = neigh,

		"local_seed" = 0,

		"density_bias" = 0.0,
		"smooth_passes" = 1,
		"caves" = generate_caves
	)

	var/result = rustg_tp_sublevel_generate(json_encode(config))

	if(!result || findtext(result, "ERROR:") == 1)
		log_world(
			"Sub-level heightmap generation failed: [result]"
		)
		return FALSE

	var/list/export = json_decode(result)

	if(!islist(export))
		log_world(
			"Sub-level generation returned invalid JSON payload."
		)
		return FALSE

	if(export["status"] != "ok")
		log_world(
			"Sub-level generation returned bad payload."
		)
		return FALSE

	heights = export["heights"]

	if(!islist(heights))
		log_world(
			"Sub-level generation returned no heightmap."
		)
		return FALSE

	if(length(heights) != width * height)
		log_world(
			"Sub-level heightmap size mismatch. \
			Expected [width * height], got [length(heights)]."
		)
		return FALSE

	for(var/i in 1 to length(heights))
		var/value = text2num("[heights[i]]")

		if(isnull(value))
			log_world(
				"Sub-level heightmap contains a non-numeric value at index [i]."
			)
			return FALSE

		heights[i] = clamp(value, 0, 1)


	cave_mask = export["cave_mask"]

	if(!islist(cave_mask))
		cave_mask = list()
	else if(length(cave_mask) != width * height)
		log_world(
			"Sub-level cave mask size mismatch."
		)
		return FALSE

	if(length(cave_mask))
		for(var/i in 1 to length(cave_mask))
			cave_mask[i] = text2num("[cave_mask[i]]") != 0

	rimworld_area = SSatoms.NewUninitialized(/area/rimworld, null)

	if(!rimworld_area)
		return FALSE

	rimworld_area.cell = cell
	rimworld_area.name = "Rim ([planet_x],[planet_y])"
	rimworld_area.daylight = TRUE
	rimworld_area.outdoors = TRUE

	// Area must be initialized before it can be registered.
	pending_init = list(rimworld_area)

	generated_turfs = list()
	generated_open_turfs = list()

	turfs_initialized = FALSE

	return TRUE



/datum/map_generator/sub_level/proc/place_sub_level_turf(
	datum/turf_reservation/sub_level/reservation,
	local_x,
	local_y
)
	if(!reservation || !target_biome)
		return null

	if(local_x < 1 || local_x > width)
		return null

	if(local_y < 1 || local_y > height)
		return null

	var/turf/BL = reservation.get_bottom_left_turf()

	if(!BL)
		return null

	var/world_x = BL.x + local_x - 1
	var/world_y = BL.y + local_y - 1

	var/turf/source_turf = locate(world_x, world_y, BL.z)

	if(!source_turf)
		return null
	source_turf.change_area(get_area(source_turf), rimworld_area)

	var/index = width * (local_y - 1) + local_x

	if(index < 1 || index > length(heights))
		return null

	var/terrain_height = heights[index]

	var/is_cave = FALSE

	if(length(cave_mask))
		is_cave = cave_mask[index]

	var/is_transition = is_geological_transition_xy(local_x, local_y)

	/**
	 * The biome determines the physical turf.
	 */
	var/turf_type = target_biome.get_turf_for_height(
		terrain_height,
		is_cave,
		is_transition
	)

	if(!turf_type)
		turf_type = /turf/open/genturf

	/**
	 * Create the new turf without Initialize().
	 */
	var/turf/new_turf = SSatoms.NewUninitialized(turf_type, source_turf)
	if(!new_turf)
		return null

	generated_turfs += new_turf
	pending_init += new_turf

	if(!istype(new_turf, /turf/closed))
		generated_open_turfs += new_turf

	return new_turf


/**
 *
 * This is intentionally executed ONCE after every turf has been placed.
 *
 * There is no tick slicing here.
 *
 * The entire map becomes initialized as one operation.
 */
/datum/map_generator/sub_level/proc/initialize_all_turfs()
	if(turfs_initialized)
		return TRUE

	if(!length(pending_init))
		return FALSE

	Master.StartLoadingMap()
	SSatoms.InitializeAtoms(pending_init)
	Master.StopLoadingMap()

	SSmapping.reg_in_areas_in_z(list(rimworld_area))
	turfs_initialized = TRUE
	return TRUE


/**
 *
 * Population is intentionally done AFTER InitializeAtoms().
 *
 * This proc expects the biome to expose populate_turf().
 */
/datum/map_generator/sub_level/proc/populate_turf(
	turf/target_turf,
	flora_allowed,
	features_allowed,
	fauna_allowed
)
	if(!target_turf || !target_biome)
		return FALSE

	if(istype(target_turf, /turf/closed))
		return TRUE

	if(target_turf.turf_flags & TURF_BLOCKS_POPULATE_TERRAIN_FLORAFEATURES)
		return TRUE

	return target_biome.populate_turf(
		target_turf,
		flora_allowed,
		features_allowed,
		fauna_allowed
	)


/datum/map_generator/sub_level/proc/get_generated_turf(index)
	if(index < 1 || index > length(generated_turfs))
		return null

	return generated_turfs[index]


/datum/map_generator/sub_level/proc/get_generated_open_turf(index)
	if(index < 1 || index > length(generated_open_turfs))
		return null

	return generated_open_turfs[index]


/datum/map_generator/sub_level/proc/get_generated_turf_count()
	return length(generated_turfs)


/datum/map_generator/sub_level/proc/get_generated_open_turf_count()
	return length(generated_open_turfs)
