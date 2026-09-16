/**
 * Low-level call into the Rust planet generator.
 */
#define rustg_raw_tp_planet_generate(config_json) \
	RUSTG_CALL(RUST_G, "tp_planet_generate")(config_json)

/**
 * Generates planet layers via Rust and writes them to disk.
 * Returns a JSON string on success or an error string starting with "ERROR: ".
 */
/proc/rustg_tp_planet_generate(config_json)
	if(!length(config_json))
		return "ERROR: config_json must be a list"

	return rustg_raw_tp_planet_generate(config_json)

/**
 * Low-level call that reads a single packed cell from a layer file.
 */
#define rustg_raw_tp_planet_get_cell(path, x, y) \
	RUSTG_CALL(RUST_G, "tp_planet_get_cell")(path, x, y)

/**
 * Reads one cell from a generated planet layer file.
 * Coordinates are 1-based.
 * Returns a number on success, null on failure.
 */
/proc/rustg_tp_planet_get_cell(path, x, y)
	if(!istext(path) || !length(path))
		return null
	if(!isnum(x) || !isnum(y))
		return null

	var/result = rustg_raw_tp_planet_get_cell(path, "[x]", "[y]")
	if(!result)
		return null
	if(findtext(result, "ERROR") == 1)
		return null

	return text2num(result)


/**
 * Low-level call into the Rust sub-level heightmap generator.
 *
 * This is intentionally kept as a thin wrapper around the Rust bridge.
 * Validation and documentation belong to the public procedure below.
 */
#define rustg_raw_tp_sublevel_generate(config_json) \
	RUSTG_CALL(RUST_G, "tp_sublevel_generate")(config_json)

/**
 * Generates a continuous height map (0.0-1.0) for a sub-level.
 *
 * Input:
 *     config_json
 * JSON object containing:
 *
 *     planet_seed: u32
 *         Global deterministic planet seed.
 *
 *     planet_x: i32
 *     planet_y: i32
 *         Planetary/sub-level coordinates.
 *
 *     width: usize
 *     height: usize
 *         Generated map dimensions.
 *
 *     neighbourhood: [u8; 9]
 *         3x3 elevation neighbourhood in row-major order:
 *
 *             0 1 2
 *             3 4 5
 *             6 7 8
 *
 *         Elevation values:
 *
 *             0 = Ocean
 *             1 = Coast
 *             2 = Lowland
 *             3 = Highland
 *             4 = Mountain
 *             5 = Snow
 *     local_seed: u32
 *         Optional explicit sub-level seed.
 *         0 = automatically derived.
 *     density_bias: f64
 *         Additional terrain bias.
 *         Recommended range: -0.5 .. +0.5.
 *     smooth_passes: u32
 *         Terrain smoothing passes.
 *         Range: 0 .. 3.
 *     caves: bool
 *         Enables cave generation.
 *
 *
 * Output:
 *
 *     JSON string:
 *
 *         {
 *             "status": "ok",
 *             "width": <number>,
 *             "height": <number>,
 *             "heights": [<f32>, ...],
 *             "cave_mask": [0, 1, ...],
 *             "meta": {...}
 *         }
 *
 *     heights and cave_mask are flat row-major arrays:
 *
 *         index = y * width + x
 *
 *     BYOND list indexing is 1-based, therefore when accessing them:
 *
 *         list[y * width + x + 1]
 *
 * On failure:
 *
 *     ERROR: <description>
 *
 * ----------------------------------------------------------------------------
 * Example DM usage
 * ----------------------------------------------------------------------------
 *
 *     var/list/config = list(
 *         "planet_seed" = planet_seed,
 *         "planet_x" = planet_x,
 *         "planet_y" = planet_y,
 *
 *         "width" = map_width,
 *         "height" = map_height,
 *
 *         "neighbourhood" = list(
 *             north_west,
 *             north,
 *             north_east,
 *
 *             west,
 *             centre,
 *             east,
 *
 *             south_west,
 *             south,
 *             south_east
 *         ),
 *
 *         "local_seed" = 0,
 *         "density_bias" = 0.0,
 *         "smooth_passes" = 1,
 *         "caves" = TRUE
 *     )
 *
 *     var/config_json = json_encode(config)
 *     var/result_json = rustg_tp_sublevel_generate(config_json)
 *
 *     if(copytext(result_json, 1, 8) == "ERROR: ")
 *         CRASH(result_json)
 *
 *     var/list/result = json_decode(result_json)
 *
 *     var/list/heights = result["heights"]
 *     var/list/cave_mask = result["cave_mask"]
 *
 *     for(var/y = 0; y < result["height"]; y++)
 *         for(var/x = 0; x < result["width"]; x++)
 *             var/index = y * result["width"] + x + 1
 *
 *             var/terrain_height = heights[index]
 *             var/is_cave = cave_mask[index]
 */
/proc/rustg_tp_sublevel_generate(config_json)
	if(!istext(config_json) || !length(config_json))
		return "ERROR: config_json must be a non-empty string"

	return rustg_raw_tp_sublevel_generate(config_json)
