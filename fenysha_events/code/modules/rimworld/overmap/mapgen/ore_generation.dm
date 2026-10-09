/**
 * Ore & rock-chunk generation for planet cells.
 *
 * Uses rustg cellular-automata / dbp noise to place ore veins inside
 * /turf/closed/rw_wall/rock walls and scatter /obj/item/rock_chunk on open ground.
 *
 * Call from map generator after walls are stamped, e.g. from
 * /datum/map_generator/sub_level after populate, or from the load job
 * before finish().
 */

#define RW_ORE_MIN_VEINS 4
#define RW_ORE_TARGET_VEINS 8
#define RW_ORE_CHUNK_CHANCE 0.04
#define RW_ORE_CHUNK_MIN 12
#define RW_ORE_CHUNK_TARGET 60

/// Weighted ore table: path = weight (higher = more common)
/proc/rw_ore_weighted_table()
	RETURN_TYPE(/list)
	return list(
		/obj/item/stack/ore/rimworld/steel = 40,
		/obj/item/stack/ore/rimworld/silver = 18,
		/obj/item/stack/ore/rimworld/gold = 12,
		/obj/item/stack/ore/rimworld/plasteel = 10,
		/obj/item/stack/ore/rimworld/uranium = 8,
		/obj/item/stack/ore/rimworld/bioferrite = 12,
	)

/**
 * Generates a binary noise mask (string of 0/1) for the given dimensions.
 * Prefers dbp (perlin-like); falls back to cnoise; falls back to pure random.
 */
/proc/rw_generate_ore_noise(seed, width, height, density = 0.12)
	var/noise
	// dbp: seed, accuracy, stamp_size, world_size, lower_range, upper_range
	// lower/upper select which band of the continuous noise becomes "on"
	noise = rustg_dbp_generate("[seed]", "4", "8", "[width]", "0.55", "1.0")
	if(istext(noise) && length(noise) >= width * height)
		return noise

	// cnoise: percentage (start closed), iterations, birth, death, w, h
	var/pct = round(density * 100)
	noise = rustg_cnoise_generate("[pct]", "4", "4", "3", "[width]", "[height]")
	if(istext(noise) && length(noise) >= width * height)
		return noise

	// Pure random fallback
	var/list/chars = list()
	chars.len = width * height
	for(var/i in 1 to width * height)
		chars[i] = (prob(density * 100) ? "1" : "0")
	return jointext(chars, "")

/**
 * Collects all rock walls in the generated set that can host ore.
 */
/datum/map_generator/sub_level/proc/collect_ore_host_rocks()
	RETURN_TYPE(/list)
	var/list/rocks = list()
	for(var/turf/T as anything in generated_turfs)
		if(!istype(T, /turf/closed/rw_wall/rock))
			continue
		var/turf/closed/rw_wall/rock/R = T
		if(R.has_ore())
			continue
		rocks += R
	return rocks

/**
 * Main entry: place ore veins + surface rock chunks.
 * Returns list("ore_veins" = N, "ore_tiles" = N, "chunks" = N)
 */
/datum/map_generator/sub_level/proc/generate_ores_and_chunks()
	var/list/result = list("ore_veins" = 0, "ore_tiles" = 0, "chunks" = 0)
	if(!width || !height)
		return result

	var/seed_base = planet ? planet.seed : rand(1, 999999)
	var/cell_salt = cell ? (cell.x * 10007 + cell.y * 13) : rand(1, 9999)
	var/seed = seed_base + cell_salt

	var/list/rocks = collect_ore_host_rocks()
	if(length(rocks))
		result = generate_ore_veins(rocks, seed, result)

	result = generate_surface_rock_chunks(seed + 17, result)
	return result

/**
 * Places ore into rock walls using noise + vein growth (create_vein).
 * Guarantees at least RW_ORE_MIN_VEINS veins when enough host rocks exist.
 */
/datum/map_generator/sub_level/proc/generate_ore_veins(list/rocks, seed, list/result)
	var/noise = rw_generate_ore_noise(seed, width, height, 0.10)
	var/list/ore_table = rw_ore_weighted_table()
	var/list/candidates = list()

	// Index rocks by flat grid position when possible
	for(var/turf/closed/rw_wall/rock/R as anything in rocks)
		var/lx = R.x - origin_x
		var/ly = R.y - origin_y
		if(lx < 0 || ly < 0 || lx >= width || ly >= height)
			// outside local grid — still eligible via random pass
			candidates += R
			continue
		var/idx = ly * width + lx + 1
		if(idx > length(noise))
			candidates += R
			continue
		if(noise[idx] == "1")
			candidates += R

	// Ensure minimum candidate pool
	if(length(candidates) < RW_ORE_MIN_VEINS && length(rocks) >= RW_ORE_MIN_VEINS)
		var/list/shuffled = shuffle(rocks.Copy())
		for(var/turf/closed/rw_wall/rock/R as anything in shuffled)
			if(R in candidates)
				continue
			candidates += R
			if(length(candidates) >= RW_ORE_TARGET_VEINS * 2)
				break

	var/target_veins = clamp(RW_ORE_TARGET_VEINS, RW_ORE_MIN_VEINS, max(RW_ORE_MIN_VEINS, round(length(rocks) * 0.08)))
	var/veins_placed = 0
	var/tiles_ore = 0
	var/list/used = list()

	candidates = shuffle(candidates)

	for(var/turf/closed/rw_wall/rock/R as anything in candidates)
		if(veins_placed >= target_veins)
			break
		if(used[R] || R.has_ore())
			continue

		var/ore_path = pick_weight(ore_table)
		var/obj/item/stack/ore/rimworld/ore_dummy = ore_path
		var/min_amt = initial(ore_dummy.min_vein_size) || 1
		var/max_amt = initial(ore_dummy.max_vein_size) || 2
		var/amount = rand(min_amt, max_amt)
		var/radius = 1
		var/chance = initial(ore_dummy.spread_chance) || 30

		// Seed the center
		if(!R.add_ore(ore_path, amount))
			continue
		used[R] = TRUE
		tiles_ore++
		veins_placed++

		// Grow a local vein
		var/grown = R.create_vein(ore_path, radius = radius + (chance >= 40 ? 1 : 0), chance = chance, min_amount = min_amt, max_amount = max_amt)
		tiles_ore += grown

		// Mark grown tiles so we don't double-seed
		for(var/turf/closed/rw_wall/rock/N in RANGE_TURFS(radius + 1, R))
			if(N.has_ore())
				used[N] = TRUE

	// Hard minimum guarantee: force-place remaining veins on unused rocks
	if(veins_placed < RW_ORE_MIN_VEINS)
		var/list/remaining = list()
		for(var/turf/closed/rw_wall/rock/R as anything in rocks)
			if(!used[R] && !R.has_ore())
				remaining += R
		remaining = shuffle(remaining)
		for(var/turf/closed/rw_wall/rock/R as anything in remaining)
			if(veins_placed >= RW_ORE_MIN_VEINS)
				break
			var/ore_path = pick_weight(ore_table)
			var/amount = rand(1, 3)
			if(R.add_ore(ore_path, amount))
				veins_placed++
				tiles_ore++
				R.create_vein(ore_path, radius = 1, chance = 40, min_amount = 1, max_amount = 2)

	result["ore_veins"] = veins_placed
	result["ore_tiles"] = tiles_ore
	return result

/**
 * Scatter rock chunks on open non-water turfs (RimWorld-style surface stone).
 */
/datum/map_generator/sub_level/proc/generate_surface_rock_chunks(seed, list/result)
	var/list/open = generated_open_turfs
	if(!length(open))
		return result

	var/noise = rw_generate_ore_noise(seed, width, height, RW_ORE_CHUNK_CHANCE)
	var/chunks = 0
	var/target = clamp(RW_ORE_CHUNK_TARGET, RW_ORE_CHUNK_MIN, max(RW_ORE_CHUNK_MIN, round(length(open) * RW_ORE_CHUNK_CHANCE * 1.5)))

	var/list/candidates = list()
	for(var/i in 1 to length(open))
		var/turf/T = open[i]
		if(!T || is_space_or_openspace(T))
			continue
		// Prefer rocky / mountain open tiles; still allow general land
		var/lx = T.x - origin_x
		var/ly = T.y - origin_y
		var/on = FALSE
		if(lx >= 0 && ly >= 0 && lx < width && ly < height)
			var/idx = ly * width + lx + 1
			if(idx <= length(noise) && noise[idx] == "1")
				on = TRUE
		if(on || prob(RW_ORE_CHUNK_CHANCE * 100 * 0.5))
			candidates += T

	candidates = shuffle(candidates)
	for(var/turf/T as anything in candidates)
		if(chunks >= target)
			break
		if(locate(/obj/item/rock_chunk) in T)
			continue
		var/obj/item/rock_chunk/chunk = new /obj/item/rock_chunk(T)
		// Tint with regional material when available
		if(stamp_rock_material)
			chunk.material = stamp_rock_material
			chunk.name = "[stamp_rock_material.name] [chunk.name]"
			chunk.color = stamp_rock_material.color
		else if(cell?.material)
			var/datum/material/rimworld_material/mat = SSmaterials.get_material(RW_MATERIAL_NAME_TO_TYPE[cell.material])
			if(mat)
				chunk.material = mat
				chunk.name = "[mat.name] [chunk.name]"
				chunk.color = mat.color
		chunks++

	// Guarantee minimum
	if(chunks < RW_ORE_CHUNK_MIN)
		var/list/extra = shuffle(open.Copy())
		for(var/turf/T as anything in extra)
			if(chunks >= RW_ORE_CHUNK_MIN)
				break
			if(is_space_or_openspace(T))
				continue
			if(locate(/obj/item/rock_chunk) in T)
				continue
			new /obj/item/rock_chunk(T)
			chunks++

	result["chunks"] = chunks
	return result

/**
 * Hook for the sub-level load job — call after open turfs are populated
 * and rock walls exist, before finish().
 *
 * Example integration in loader.dm (populate phase end):
 *   generator.generate_ores_and_chunks()
 */
/datum/rimworld_sublevel_load_job/proc/run_ore_generation()
	if(!generator || QDELETED(generator))
		return
	var/list/stats = generator.generate_ores_and_chunks()
	if(stats)
		log_world("RW ore gen cell [cell?.id]: veins=[stats["ore_veins"]] tiles=[stats["ore_tiles"]] chunks=[stats["chunks"]]")
