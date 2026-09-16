
/**
 * Low-level call into the Rust planet generator.
 */
#define rustg_raw_tp_planet_generate(seed, width, height, layers_json, output_dir) \
	RUSTG_CALL(RUST_G, "tp_planet_generate")(seed, width, height, layers_json, output_dir)

/**
 * Generates planet layers via Rust and writes them to disk.
 * Returns a JSON string on success or an error string starting with "ERROR: ".
 */
/proc/rustg_tp_planet_generate(seed, width, height, layers_json, output_dir)
	if(!isnum(seed) || !isnum(width) || !isnum(height))
		return "ERROR: seed, width and height must be numbers"
	if(!istext(layers_json) || !length(layers_json))
		return "ERROR: layers_json must be a non-empty string"
	if(!istext(output_dir) || !length(output_dir))
		return "ERROR: output_dir must be a non-empty string"

	return rustg_raw_tp_planet_generate("[seed]", "[width]", "[height]", layers_json, output_dir)

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
