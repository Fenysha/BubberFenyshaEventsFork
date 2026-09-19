GLOBAL_VAR(rimworld_planet_noise_revision)

/**
 * Registers generated planet layer binaries as client assets.
 * One asset set per planet seed + revision.
 */
/datum/asset/simple/rimworld_planet_layers
	cross_round_cachable = FALSE

	var/registered_revision = -1
	var/registered_seed = null
	var/list/cached_urls


/datum/asset/simple/rimworld_planet_layers/register()
	return


/datum/asset/simple/rimworld_planet_layers/unregister()
	for(var/asset_name in assets)
		SSassets.transport.unregister_asset(asset_name)

	assets = list()
	registered_revision = -1
	registered_seed = null
	cached_urls = null


/**
 * Registers the planet's layer files (terrain, climate, geology and rivers) as assets.
 * Returns TRUE on success.
 */
/datum/asset/simple/rimworld_planet_layers/proc/register_for_planet(datum/rimworld_planet/planet)
	if(!planet)
		return FALSE

	if(registered_revision == planet.generation_revision && registered_seed == planet.seed && length(assets))
		return TRUE

	unregister()

	if(!planet.maps_generated())
		log_asset("ERROR: Planet layers not generated yet for seed [planet.seed]")
		return FALSE

	var/list/layer_names = list(
		"elevation",
		"heat",
		"humidity",
		"precipitation",
		"geology",
		"rivers"
	)

	for(var/layer_name in layer_names)
		var/file_path = planet.get_layer_file(layer_name)
		if(!file_path || !rustg_file_exists(file_path))
			log_asset("ERROR: Missing planet layer file [layer_name] at [file_path]")
			unregister()
			return FALSE

		var/asset_name = "rimworld_planet_[layer_name].bin"
		var/datum/asset_cache_item/ACI = SSassets.transport.register_asset(asset_name, file_path)
		if(!ACI)
			log_asset("ERROR: Failed to register [asset_name]")
			unregister()
			return FALSE

		assets[asset_name] = ACI

	registered_revision = planet.generation_revision
	registered_seed = planet.seed
	return TRUE


/datum/asset/simple/rimworld_planet_layers/get_url_mappings()
	if(!length(assets))
		return list()

	if(cached_urls)
		return cached_urls.Copy()

	var/list/result = list()
	for(var/asset_name in assets)
		result[asset_name] = SSassets.transport.get_asset_url(asset_name, assets[asset_name])

	cached_urls = result
	return result.Copy()


/datum/asset/simple/rimworld_planet_layers/send(client/C)
	if(!C || !length(assets))
		return FALSE
	return SSassets.transport.send_assets(C, assets)


/**
 * Returns the URL for a specific layer asset, or null.
 */
/datum/asset/simple/rimworld_planet_layers/proc/get_layer_url(layer_name)
	if(!length(assets))
		return null

	var/asset_name = "rimworld_planet_[layer_name].bin"
	if(cached_urls)
		return cached_urls[asset_name]

	if(!assets[asset_name])
		return null

	return SSassets.transport.get_asset_url(asset_name, assets[asset_name])
