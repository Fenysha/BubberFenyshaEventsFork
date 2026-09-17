/datum/asset/simple/rimworld_planet_icons
	cross_round_cachable = TRUE

	var/registered = FALSE
	var/list/cached_urls


/datum/asset/simple/rimworld_planet_icons/register()
	if(registered && length(assets))
		return TRUE

	assets = list()
	cached_urls = null

	var/ok = TRUE

	/*
	// 64x64 tile decor sheets. Each PNG is a 1x4 strip of variants
	// (256x64 px total) — see planetIcons.ts for the frame layout.
	ok = register_icon_sheets("fenysha_events/icons/planet_map/default", list(
		"mountains",
		"mountains_i",
		"hills",
		"hills_big",
	)) && ok

	// 128x128 tile decor sheets (1x4 strip, 512x128 px total).
	ok = register_icon_sheets("fenysha_events/icons/planet_map/default/128", list(
		"forest",
		"forest_d",
	)) && ok
	*/
	// 128x128 object markers, one per planet object type.
	ok = register_icon_sheets("fenysha_events/icons/planet_map/markers", list(
		RW_PLANET_CELL_TOWN,
		RW_PLANET_CELL_TOWN_OTHER,
		RW_PLANET_CELL_TOWN_TRIBAL,
		RW_PLANET_CELL_TOWN_PIRATE,
		RW_PLANET_CELL_TOWN_ICON,
	)) && ok

	if(!ok)
		log_asset("ERROR: One or more planet map icons failed to register, see above")

	registered = TRUE
	return length(assets) > 0


/datum/asset/simple/rimworld_planet_icons/unregister()
	for(var/asset_name in assets)
		SSassets.transport.unregister_asset(asset_name)

	assets = list()
	registered = FALSE
	cached_urls = null


/**
 * Registers every icon_name in base_path/[icon_name].png under the
 * asset key "rimworld_planet_icon_[icon_name].png". Missing files are
 * logged and skipped rather than failing the whole batch, since art
 * tends to land incrementally.
 */
/datum/asset/simple/rimworld_planet_icons/proc/register_icon_sheets(base_path, list/icon_names)
	var/ok = TRUE

	for(var/icon_name in icon_names)
		var/file_path = "[base_path]/[icon_name].png"

		if(!rustg_file_exists(file_path))
			log_asset("ERROR: Missing planet map icon [icon_name] at [file_path]")
			ok = FALSE
			continue

		var/asset_name = "rimworld_planet_icon_[icon_name].png"
		var/datum/asset_cache_item/ACI = SSassets.transport.register_asset(asset_name, file_path)

		if(!ACI)
			log_asset("ERROR: Failed to register planet map icon asset [asset_name]")
			ok = FALSE
			continue

		assets[asset_name] = ACI

	return ok


/datum/asset/simple/rimworld_planet_icons/get_url_mappings()
	if(!length(assets))
		return list()

	if(cached_urls)
		return cached_urls.Copy()

	var/list/result = list()
	for(var/asset_name in assets)
		result[asset_name] = SSassets.transport.get_asset_url(asset_name, assets[asset_name])

	cached_urls = result
	return result.Copy()


/datum/asset/simple/rimworld_planet_icons/send(client/C)
	if(!C)
		return FALSE

	// Defensive: normally register() already ran during SSassets init,
	// since (unlike rimworld_planet_layers) this datum doesn't need to
	// wait on any planet-specific data.
	if(!registered)
		register()

	if(!length(assets))
		return FALSE

	return SSassets.transport.send_assets(C, assets)
