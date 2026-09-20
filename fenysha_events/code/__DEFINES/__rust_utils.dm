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
 * Low-level call that reads one packed cell from a generated planet layer.
 *
 * The Rust side expects the coordinates as strings because they are received
 * through the generic BYOND -> Rust bridge.
 */
#define rustg_raw_tp_planet_get_cell(path, x, y) \
	RUSTG_CALL(RUST_UTILS, "tp_planet_get_cell")(path, "[x]", "[y]")


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

