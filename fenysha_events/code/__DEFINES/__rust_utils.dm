#ifndef RUST_UTILS

/* This comment bypasses grep checks */ /var/__rust_utils

/proc/__detect_rust_utils()
	if(world.system_type == UNIX)
		if(fexists("./rust_utils.so"))
			// No need for LD_LIBRARY_PATH badness.
			return __rust_utils = "./rust_utils.so"
		else
			// It's not in the current directory, so try others
			return __rust_utils = "rust_utils.so"
	else
		return __rust_utils = "rust_utils"

#define RUST_UTILS (__rust_utils || __detect_rust_utils())
#endif

// Handle 515 call() -> call_ext() changes
#if DM_VERSION >= 515
#define CALL_LIB call_ext
#else
#define CALL_LIB call
#endif

/// Gets the version of rust_utils
/proc/rust_utils_get_version() return CALL_LIB(RUST_UTILS, "get_version")()

/**
 * Flatten DMI layers into a PNG and return JSON with a base64 payload.
 *
 * Input:
 *     recipe_json
 *         JSON object containing:
 *
 *         size: u32
 *             Canvas size in pixels (1..256). Default 48.
 *
 *         body: u32
 *             Body sprite size used to center layers. Default 32.
 *
 *         dir: i32
 *             BYOND dir (2 south, 1 north, 4 east, 8 west). Default 2.
 *
 *         crop_bottom: f64
 *             Fraction of the canvas to drop from the bottom (bust crop).
 *             Default 0.
 *
 *         trim: bool | 0/1
 *             Trim transparent padding after composite. Default true.
 *
 *         layers: array of
 *             path, state, multiply, pixel_w, pixel_z, layer
 *             blend: optional "rw_grad"
 *             mask_path, mask_state: required when blend is rw_grad
 *
 *         markings: string
 *             Optional packed pixels "x,y,#rrggbb;..."
 *
 * Output on success:
 *
 *     {"ok": true, "png": "<base64>"}
 *
 * Output on failure:
 *
 *     {"ok": false, "error": "<description>"}
 */
#define rustg_raw_rw_preview_flatten(recipe_json) \
	RUSTG_CALL(RUST_UTILS, "rw_preview_flatten")(recipe_json)

/proc/rustg_rw_preview_flatten(recipe_json)
	if(!istext(recipe_json) || !length(recipe_json))
		return "{\"ok\":false,\"error\":\"empty recipe\"}"
	return rustg_raw_rw_preview_flatten(recipe_json)

/**
 * Low-level call into the Rust sub-level heightmap generator.
 *
 * This is intentionally kept as a thin wrapper around the Rust bridge.
 * Validation belongs to the public procedure below.
 */
#define rustg_raw_tp_sublevel_generate(config_json) \
	RUSTG_CALL(RUST_UTILS, "tp_sublevel_generate")(config_json)

/**
 * Generates a continuous procedural height map for a sub-level.
 *
 * Input:
 *     config_json
 *         JSON object containing:
 *
 *         planet_seed: u32
 *             Global deterministic planet seed.
 *
 *         planet_x: i32
 *         planet_y: i32
 *             Global planet/sub-level coordinates.
 *
 *         width: usize
 *         height: usize
 *             Height-map dimensions.
 *
 *             Rust currently rejects:
 *                 width == 0
 *                 height == 0
 *                 width > 512
 *                 height > 512
 *
 *         neighbourhood: [u8; 9]
 *             Legacy 3x3 neighbourhood:
 *
 *                 0 1 2
 *                 3 4 5
 *                 6 7 8
 *
 *             Elevation values:
 *
 *                 0 = Ocean
 *                 1 = Coast
 *                 2 = Lowland
 *                 3 = Highland
 *                 4 = Mountain
 *                 5 = Snow
 *
 *             This is used when `neighbourhood_hex` is empty.
 *
 *         centre_elevation: u8
 *             Elevation of the current planet tile.
 *             Required when `neighbourhood_hex` is provided.
 *
 *         neighbourhood_hex: list
 *             Hexagonal neighbourhood around the current planet tile.
 *
 *             Each element contains:
 *
 *                 elevation: u8
 *                 bearing: f64
 *
 *             The Rust generator converts this ring into its internal
 *             3x3 neighbourhood representation.
 *
 *         biome: string
 *             Major biome.
 *             Defaults to `"grassland"`.
 *
 *         sub_biome: string
 *             Local sub-biome.
 *             Defaults to `"plains"`.
 *
 *         has_river: u8
 *             Numeric river flag.
 *
 *             0 = no planetary river
 *             non-zero = planetary river present
 *
 *         local_seed: u32
 *             Explicit local seed.
 *
 *             0 = derive automatically from planet seed and coordinates.
 *
 *         density_bias: f64
 *             Additional terrain density bias.
 *             Clamped by Rust to -0.5 .. +0.5.
 *
 *         smooth_passes: u32
 *             Number of smoothing passes.
 *             Rust limits this to 5.
 *
 *         relief_scale: f64
 *             Overall relief multiplier.
 *             Clamped by Rust to 0.2 .. 2.5.
 *
 *         detail_scale: f64
 *             Fine terrain detail multiplier.
 *             Clamped by Rust to 0.2 .. 2.5.
 *
 *         river_strength: f64
 *             River feature strength.
 *             Clamped by Rust to 0.0 .. 3.0.
 *
 *         lake_strength: f64
 *             Lake feature strength.
 *             Clamped by Rust to 0.0 .. 3.0.
 *
 *         cave_strength: f64
 *             Cave generation strength.
 *             Clamped by Rust to 0.0 .. 3.0.
 *
 *         water_bias: f64
 *             Additional water-level bias.
 *             Clamped by Rust to -0.15 .. +0.15.
 *
 *         caves: string
 *             Cave-generation switch.
 *
 *             `"caves_true"` = enabled
 *             any other value = disabled
 *
 * Output on success:
 *
 *     JSON string:
 *
 *         {
 *             "status": "ok",
 *             "width": <number>,
 *             "height": <number>,
 *             "heights": [<number>, ...],
 *             "cave_mask": [0, 1, ...],
 *             "meta": {...}
 *         }
 *
 *     `heights` and `cave_mask` are flat row-major arrays:
 *
 *         index = y * width + x
 *
 *     BYOND lists are 1-based:
 *
 *         list[y * width + x + 1]
 *
 * On failure:
 *
 *     ERROR: <description>
 */
/proc/rustg_tp_sublevel_generate(config_json)
	if(!istext(config_json) || !length(config_json))
		return "ERROR: config_json must be a non-empty string"

	return rustg_raw_tp_sublevel_generate(config_json)

/**
 * Low-level call into the Rust planet generator.
 *
 * This is intentionally kept as a thin wrapper around the Rust bridge.
 * Validation belongs to the public procedure below.
 */
#define rustg_raw_tp_planet_generate(config_json) \
	RUSTG_CALL(RUST_UTILS, "tp_planet_generate")(config_json)

/**
 * Generates all planet layers through Rust and writes the generated
 * packed layer files to the configured output directory.
 *
 * Input:
 *     config_json
 *         JSON object containing:
 *
 *         seed: u32
 *             Deterministic planet seed.
 *
 *         frequency: usize
 *             Hex-grid frequency used to construct the planet.
 *             The Rust generator currently accepts 1 .. 4096.
 *
 *         output_dir: string
 *             Directory where generated layer files are written.
 *
 *         mountains: f64
 *             Terrain ruggedness slider.
 *             Range: -5 .. +5.
 *
 *             -5 = mostly flat terrain
 *             +5 = strong mountain structure
 *
 *         ocean: f64
 *             Water coverage slider.
 *             Range: -5 .. +5.
 *
 *             -5 = mostly land
 *             +5 = water-heavy world
 *
 *         humidity: f64
 *             Humidity slider.
 *             Range: -5 .. +5.
 *
 *             -5 = dry
 *             +5 = humid
 *
 *         temperature: f64
 *             Temperature slider.
 *             Range: -5 .. +5.
 *
 *             -5 = cold
 *             +5 = hot
 *
 *         population: f64
 *             Population-density hint.
 *             Range: -5 .. +5.
 *
 *             This value does not affect terrain generation.
 *             It is returned as `population_bias` for later settlement
 *             generation.
 *
 * Output on success:
 *
 *     JSON string:
 *
 *         {
 *             "status": "ok",
 *             "seed": <number>,
 *             "width": <number>,
 *             "height": <number>,
 *             "layers": [
 *                 {
 *                     "name": "<layer>",
 *                     "path": "<file path>",
 *                     "bits_per_cell": <number>,
 *                     "bytes": <number>
 *                 }
 *             ],
 *             "river_count": <number>,
 *             "population_bias": <number>
 *         }
 *
 *     Generated layers currently include:
 *
 *         elevation
 *         heat
 *         humidity
 *         precipitation
 *         geology
 *         rivers
 *
 * On failure:
 *
 *     ERROR: <description>
 */
/proc/rustg_tp_planet_generate(config_json)
	if(!istext(config_json) || !length(config_json))
		return "ERROR: config_json must be a non-empty string"

	return rustg_raw_tp_planet_generate(config_json)

/**
 * Low-level call that reads one packed cell from a generated planet layer.
 *
 * The Rust side expects the coordinates as strings because they are received
 * through the generic BYOND -> Rust bridge.
 */
#define rustg_raw_tp_planet_get_cell(path, x, y) \
	RUSTG_CALL(RUST_UTILS, "tp_planet_get_cell")(path, "[x]", "[y]")

/**
 * Reads one cell from a generated planet layer file.
 *
 * Input:
 *     path: string
 *         Path to the packed layer file.
 *
 *     x: number
 *     y: number
 *         1-based BYOND coordinates.
 *
 * Output:
 *
 *     number
 *         Decoded cell value.
 *
 *     null
 *         If the path or coordinates are invalid, the file cannot be read,
 *         or Rust returns an error.
 *
 * Layer bit widths:
 *
 *     elevation      = 3 bits
 *     heat           = 2 bits
 *     humidity       = 2 bits
 *     precipitation  = 2 bits
 *     geology        = 3 bits
 *     rivers         = 6 bits
 *
 * On Rust-side failure the bridge returns:
 *
 *     ERROR: <description>
 */
/proc/rustg_tp_planet_get_cell(path, x, y)
	if(!istext(path) || !length(path))
		return null

	if(!isnum(x) || !isnum(y))
		return null

	if(x < 1 || y < 1)
		return null

	var/result = rustg_raw_tp_planet_get_cell(path, x, y)

	if(isnull(result))
		return null

	if(findtext(result, "ERROR: ") == 1)
		return null

	return text2num(result)





/**
 * Low-level call that scores every land tile against one or more settlement
 * "plans" and returns only the top candidates per kind.
 *
 * This reads the layer files `tp_planet_generate` already wrote to
 * `output_dir` (elevation/heat/humidity/precipitation/geology/rivers) — it
 * does NOT re-run any noise generation, so calling it is cheap even for the
 * full ~2M-tile planet. Scoring mirrors DM's old
 * `get_settlement_suitability()`; DM no longer needs to iterate the grid
 * itself, only walk the (already sorted, already capped) candidate lists
 * this returns while handling occupancy / min-distance / faction bookkeeping.
 */
#define rustg_raw_tp_planet_settlement_candidates(config_json) \
	RUSTG_CALL(RUST_UTILS, "tp_planet_settlement_candidates")(config_json)

/**
 * Input:
 *     config_json
 *         JSON object containing:
 *
 *         seed: u32
 *         frequency: usize
 *         output_dir: string
 *             Same three values passed to tp_planet_generate() for this
 *             planet — must point at the same directory its layers were
 *             written to, or this call fails. seed also drives the
 *             candidate sampling below.
 *
 *         plan: array of objects, each:
 *
 *             kind: string
 *                 Settlement kind identifier. Must match the exact string
 *                 value your RW_SETTLEMENT_* defines resolve to — the Rust
 *                 side matches on this string to apply kind-specific score
 *                 modifiers (pirate / gentle_tribe / fierce_tribe /
 *                 savage_tribe / mechanoid / insectoid / rough_outlander;
 *                 anything else gets only the generic suitability score).
 *
 *             min_score: f64
 *                 Tiles scoring below this are dropped before ever reaching
 *                 the candidate list (same meaning as the old
 *                 get_settlement_candidates(min_score=...) argument).
 *
 *             max_candidates: usize (optional, default 300)
 *                 Sample size per kind. Candidates are a seeded random
 *                 sample of every tile that clears min_score, weighted
 *                 towards higher scores, so they spread over the whole
 *                 planet instead of piling into the single best climate.
 *
 * Output on success:
 *
 *     JSON string:
 *
 *         {
 *             "status": "ok",
 *             "candidates": {
 *                 "<kind>": [
 *                     { "x": <number>, "y": <number>, "score": <number> },
 *                     ...
 *                 ],
 *                 ...
 *             }
 *         }
 *
 *     Each kind's list is in sampled order (walk it front to back) and capped
 *     at that entry's max_candidates. A kind with no plan entry is simply absent from the
 *     result.
 *
 * On failure:
 *
 *     ERROR: <description>
 *
 *     Common causes: output_dir doesn't contain layer files yet (planet not
 *     generated), frequency doesn't match the frequency the layers were
 *     generated with, or plan is empty.
 */
/proc/rustg_tp_planet_settlement_candidates(config_json)
	if(!istext(config_json) || !length(config_json))
		return "ERROR: config_json must be a non-empty string"

	return rustg_raw_tp_planet_settlement_candidates(config_json)



/**
 * Low-level call that connects a set of settlement coordinates with roads
 * and writes the result as a packed layer file, same bitmask scheme as the
 * `rivers` layer.
 */
#define rustg_raw_tp_planet_generate_roads(config_json) \
	RUSTG_CALL(RUST_UTILS, "tp_planet_generate_roads")(config_json)

/**
 * Builds a road network connecting the given settlements: a minimum
 * spanning tree per landmass decides which pairs get a direct road (so
 * every settlement is joined to the others on its landmass), then A* (terrain-
 * aware — water (ocean, shallows, sea ice) is impassable, rivers are only crossed, mountains/snow are expensive, reusing an
 * already-built segment is cheap so branches merge into a shared trunk)
 * finds the actual tile path for each MST edge.
 *
 * Input:
 *     config_json
 *         JSON object containing:
 *
 *         seed: u32
 *         frequency: usize
 *         output_dir: string
 *             Same three values passed to tp_planet_generate() for this
 *             planet — the elevation layer must already exist there.
 *
 *         settlements: array of objects, each:
 *
 *             x: usize
 *             y: usize
 *                 1-based BYOND coordinates of a settlement to connect.
 *                 Points that are out of bounds or sit on open ocean are
 *                 dropped (see skipped_settlements in the response) rather
 *                 than failing the whole call.
 *
 *             tier: RW_ROAD_DIRT .. RW_ROAD_ASPHALT (optional, default dirt)
 *                 Best road the settlement builds. A road takes the lesser tier
 *                 of its two ends; stretches two or more routes share are
 *                 upgraded one grade, up to RW_ROAD_HIGHWAY.
 *
 * Output on success:
 *
 *     JSON string:
 *
 *         {
 *             "status": "ok",
 *             "layer": {
 *                 "name": "roads",
 *                 "path": "<file path>",
 *                 "bits_per_cell": 6,
 *                 "bytes": <number>
 *             },
 *             "types_layer": {
 *                 "name": "road_types",
 *                 "path": "<file path>",
 *                 "bits_per_cell": 2,
 *                 "bytes": <number>
 *             },
 *             "edges": <number>,
 *             "road_tiles": <number>,
 *             "skipped_settlements": <number>,
 *             "networks": <number>
 *         }
 *
 *     "edges" is how many MST connections got a land path. "networks" is
 *     how many separate landmasses hold settlements; they get no road
 *     between them. "road_tiles" is how many tiles
 *     ended up with a nonzero road bitmask.
 *
 *     Read the layer exactly like rivers:
 *
 *         bit = tile's index in get_neighbors_with_bits()
 *         mask & (1 << bit) != 0  =>  road continues into that neighbour
 *
 * On failure:
 *
 *     ERROR: <description>
 *
 * Called with fewer than 2 valid settlements, this still succeeds and
 * writes an all-zero roads layer (so has_road()/get_road_mask() always have
 * something to read, even before any settlements exist).
 */
/proc/rustg_tp_planet_generate_roads(config_json)
	if(!istext(config_json) || !length(config_json))
		return "ERROR: config_json must be a non-empty string"

	return rustg_raw_tp_planet_generate_roads(config_json)

/**
 * The climate model's values for one tile (tp_planet_climate.rs, the only copy of that model),
 * read from the layers in output_dir.
 *
 * Output on success:
 *     { "status": "ok", "material", "latitude", "temperature", "precipitation",
 *       "rainfall", "snowfall", "water_availability", "biome", "sub_biome" }
 *
 *     material, biome and sub_biome are RW_MATERIAL_* / RW_BIOME_* / RW_SUBBIOME_*
 *     values; the numbers are 0-1 except latitude, in degrees.
 *
 * On failure:
 *     ERROR: <description>
 */
#define rustg_tp_planet_tile_info(output_dir, seed, x, y) \
	RUSTG_CALL(RUST_UTILS, "tp_planet_tile_info")(output_dir, "[seed]", "[x]", "[y]")

/**
 * Cheapest overland route between two tiles, by the rules roads follow: water impassable,
 * rivers only crossed, mountains expensive, existing roads cheap (unless use_roads is false).
 * Either end may be on water.
 *
 * Input: { seed, frequency, output_dir, from: [x, y], to: [x, y], use_roads (default true) }
 *
 * Output on success:
 *     { "status": "ok", "path": [[x, y], ...], "cost": <number> }, from and to included
 *     { "status": "no_path", "path": [], "cost": 0 } when they share no landmass
 *
 * On failure:
 *     ERROR: <description>
 */
#define rustg_tp_planet_find_path(config_json) \
	RUSTG_CALL(RUST_UTILS, "tp_planet_find_path")(config_json)

#define rustg_raw_tp_planet_bake_surface(config_json) \
	RUSTG_CALL(RUST_UTILS, "tp_planet_bake_surface")(config_json)

/**
 * Bakes the planet view's textures from the layers in output_dir (roads
 * included when present), so clients don't evaluate every tile themselves.
 *
 * Input: { seed, terrain_seed, frequency, output_dir }
 *
 * Output on success:
 *     { "status": "ok", "color": "<png path>", "decor": "<png path>" }
 *
 *     Both are RGBA, one texel per tile. color: biome colour. decor: R decor
 *     atlas frame + 1, G river mask, B road mask.
 *
 * On failure:
 *     ERROR: <description>
 */
/proc/rustg_tp_planet_bake_surface(config_json)
	if(!istext(config_json) || !length(config_json))
		return "ERROR: config_json must be a non-empty string"

	return rustg_raw_tp_planet_bake_surface(config_json)

#define rustg_raw_tp_planet_find_path(config_json) \
	RUSTG_CALL(RUST_UTILS, "tp_planet_find_path")(config_json)

#define rustg_raw_tp_planet_find_caravan_path(config_json) \
	RUSTG_CALL(RUST_UTILS, "tp_planet_find_caravan_path")(config_json)


/**
 * Finds a caravan route using terrain passability, biome travel costs and road grade costs.
 * `can_traverse_impassable` must only be enabled for movement types allowed to cross such tiles.
 */
/proc/rustg_tp_planet_find_caravan_path(config_json)
	if(!istext(config_json) || !length(config_json))
		return "ERROR: config_json must be a non-empty string"
	return rustg_raw_tp_planet_find_caravan_path(config_json)


#define rustg_raw_tp_area_init_z(z, width, height) \
	CALL_LIB(RUST_UTILS, "tp_area_init_z")("[z]", "[width]", "[height]")

#define rustg_raw_tp_area_set_tile(x, y, z, is_boundary, opaque, dense, kind, type_path) \
	CALL_LIB(RUST_UTILS, "tp_area_set_tile")("[x]", "[y]", "[z]", "[is_boundary]", "[opaque]", "[dense]", kind, type_path)

#define rustg_raw_tp_area_get_area_id(x, y, z) \
	CALL_LIB(RUST_UTILS, "tp_area_get_area_id")("[x]", "[y]", "[z]")

#define rustg_raw_tp_area_tile_info(x, y, z) \
	CALL_LIB(RUST_UTILS, "tp_area_tile_info")("[x]", "[y]", "[z]")

#define rustg_raw_tp_area_area_exists(area_id, z) \
	CALL_LIB(RUST_UTILS, "tp_area_area_exists")("[area_id]", "[z]")

#define rustg_raw_tp_area_force_rebuild(z) \
	CALL_LIB(RUST_UTILS, "tp_area_force_rebuild")("[z]")

#define rustg_raw_tp_area_set_tiles_batch(config_json) \
	CALL_LIB(RUST_UTILS, "tp_area_set_tiles_batch")(config_json)

#define rustg_raw_tp_area_get_area_tiles(area_id, z) \
	CALL_LIB(RUST_UTILS, "tp_area_get_area_tiles")("[area_id]", "[z]")

#define rustg_raw_tp_area_get_area_bounds(area_id, z) \
	CALL_LIB(RUST_UTILS, "tp_area_get_area_bounds")("[area_id]", "[z]")

#define rustg_raw_tp_area_get_neighbors(area_id, z) \
	CALL_LIB(RUST_UTILS, "tp_area_get_neighbors")("[area_id]", "[z]")

#define rustg_raw_tp_area_get_stats(z) \
	CALL_LIB(RUST_UTILS, "tp_area_get_stats")("[z]")


/proc/rustg_area_init_z(z, width, height)
	if(!isnum(z) || !isnum(width) || !isnum(height))
		return FALSE
	var/result = rustg_raw_tp_area_init_z(z, width, height)
	if(findtext(result, "ERROR:") == 1)
		stack_trace("rustg_area_init_z failed: [result]")
		return FALSE
	return TRUE

/**
 * Update a single tile. Returns new area_id or null on failure.
 *
 * is_boundary / opaque / dense — truthy values become "1", else "0".
 */
/proc/rustg_area_set_tile(x, y, z, is_boundary, opaque, dense, kind = "other", type_path = "")
	if(!isnum(x) || !isnum(y) || !isnum(z))
		return null
	var/result = rustg_raw_tp_area_set_tile(x, y, z, is_boundary ? "1" : "0", opaque ? "1" : "0", dense ? "1" : "0", kind || "other", type_path || "")
	if(findtext(result, "ERROR:") == 1)
		stack_trace("rustg_area_set_tile failed: [result]")
		return null
	return text2num(result)

/**
 * Batch update + full rebuild. tiles = list of assoc lists with keys:
 *   x, y, is_boundary, opaque, dense, kind, type_path
 */
/proc/rustg_area_set_tiles_batch(z, list/tiles)
	if(!isnum(z) || !islist(tiles))
		return FALSE
	// Normalise bools to 0/1 so Rust deserializer is happy
	var/list/normalised = list()
	for(var/list/t in tiles)
		normalised += list(list(
			"x" = t["x"],
			"y" = t["y"],
			"is_boundary" = t["is_boundary"] ? 1 : 0,
			"opaque" = t["opaque"] ? 1 : 0,
			"dense" = t["dense"] ? 1 : 0,
			"kind" = t["kind"] || "other",
			"type_path" = t["type_path"] || "",
		))
	var/list/payload = list("z" = z, "tiles" = normalised)
	var/result = rustg_raw_tp_area_set_tiles_batch(json_encode(payload))
	if(findtext(result, "ERROR:") == 1)
		stack_trace("rustg_area_set_tiles_batch failed: [result]")
		return FALSE
	return TRUE

/proc/rustg_area_get_area_id(x, y, z)
	var/result = rustg_raw_tp_area_get_area_id(x, y, z)
	if(findtext(result, "ERROR:") == 1)
		return null
	return text2num(result)

/**
 * Returns assoc: is_boundary, opaque, dense, area_id, kind, type_hash
 * Packed format from Rust: "b,o,d,aid,kind,hash"
 */
/proc/rustg_area_tile_info(x, y, z)
	var/result = rustg_raw_tp_area_tile_info(x, y, z)
	if(findtext(result, "ERROR:") == 1)
		return null
	var/list/parts = splittext(result, ",")
	if(length(parts) < 6)
		return null
	return list(
		"is_boundary" = text2num(parts[1]),
		"opaque" = text2num(parts[2]),
		"dense" = text2num(parts[3]),
		"area_id" = text2num(parts[4]),
		"kind" = text2num(parts[5]),
		"type_hash" = text2num(parts[6]),
	)

/proc/rustg_area_area_exists(area_id, z)
	var/result = rustg_raw_tp_area_area_exists(area_id, z)
	if(findtext(result, "ERROR:") == 1)
		return FALSE
	return result == "1"

/proc/rustg_area_force_rebuild(z)
	var/result = rustg_raw_tp_area_force_rebuild(z)
	if(findtext(result, "ERROR:") == 1)
		stack_trace("rustg_area_force_rebuild failed: [result]")
		return FALSE
	return TRUE

/proc/rustg_area_get_area_tiles(area_id, z)
	var/result = rustg_raw_tp_area_get_area_tiles(area_id, z)
	if(findtext(result, "ERROR:") == 1)
		return null
	var/list/decoded = json_decode(result)
	return decoded?["tiles"]

/proc/rustg_area_get_area_bounds(area_id, z)
	var/result = rustg_raw_tp_area_get_area_bounds(area_id, z)
	if(findtext(result, "ERROR:") == 1)
		return null
	var/list/decoded = json_decode(result)
	if(!decoded || decoded["status"] != "ok")
		return null
	return list(
		"min_x" = decoded["min_x"],
		"min_y" = decoded["min_y"],
		"max_x" = decoded["max_x"],
		"max_y" = decoded["max_y"],
		"size" = decoded["size"],
	)

/proc/rustg_area_get_neighbors(area_id, z)
	var/result = rustg_raw_tp_area_get_neighbors(area_id, z)
	if(findtext(result, "ERROR:") == 1)
		return null
	var/list/decoded = json_decode(result)
	return decoded?["neighbors"]

/proc/rustg_area_get_stats(z)
	var/result = rustg_raw_tp_area_get_stats(z)
	if(findtext(result, "ERROR:") == 1)
		return null
	return json_decode(result)


#define rustg_raw_tp_area_same_room(x1, y1, z1, x2, y2, z2) \
	CALL_LIB(RUST_UTILS, "tp_area_same_room")("[x1]", "[y1]", "[z1]", "[x2]", "[y2]", "[z2]")

#define rustg_raw_tp_area_can_see(x1, y1, z1, x2, y2, z2, see_thru, max_dist) \
	CALL_LIB(RUST_UTILS, "tp_area_can_see")("[x1]", "[y1]", "[z1]", "[x2]", "[y2]", "[z2]", "[see_thru]", "[max_dist]")

#define rustg_raw_tp_area_can_see_many(ox, oy, z, see_thru, max_dist, targets_json) \
	CALL_LIB(RUST_UTILS, "tp_area_can_see_many")("[ox]", "[oy]", "[z]", "[see_thru]", "[max_dist]", targets_json)

/proc/rustg_area_same_room(x1, y1, z1, x2, y2, z2)
	var/result = rustg_raw_tp_area_same_room(x1, y1, z1, x2, y2, z2)
	if(findtext(result, "ERROR:") == 1)
		return null
	return result == "1"

/**
 * Structural LOS using the DM step-towards path and opaque-turf state.
 * see_thru truthy ignores opaque turfs but never absolute cordons.
 * max_dist 0 = unlimited (Chebyshev).
 */
/proc/rustg_area_can_see(x1, y1, z1, x2, y2, z2, see_thru = FALSE, max_dist = 0)
	var/result = rustg_raw_tp_area_can_see(x1, y1, z1, x2, y2, z2, see_thru ? "1" : "0", max_dist)
	if(findtext(result, "ERROR:") == 1)
		return null
	return result == "1"

/**
 * Bulk LOS. targets = list of list(x, y) or list("x"=, "y"=).
 * Returns list of 0/1 in the same order, or null on error.
 */
/proc/rustg_area_can_see_many(ox, oy, z, list/targets, see_thru = FALSE, max_dist = 0)
	if(!islist(targets))
		return null
	var/list/packed = list()
	for(var/entry in targets)
		if(islist(entry))
			var/list/e = entry
			var/tx = e["x"]
			var/ty = e["y"]
			if(isnull(tx))
				tx = e[1]
				ty = e[2]
			packed += list(list(tx, ty))
	var/result = rustg_raw_tp_area_can_see_many(ox, oy, z, see_thru ? "1" : "0", max_dist, json_encode(packed))
	if(findtext(result, "ERROR:") == 1)
		return null
	var/list/decoded = json_decode(result)
	return decoded?["results"]
