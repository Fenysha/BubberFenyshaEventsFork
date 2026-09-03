// Item details are otherwise carried through from the savefile untouched, which is not good enough for one a
// player handed us. Overrides rather than core edits.

/// Filters presets before the downstream deserialize walks them, to the same rules the loadout menu enforces.
/datum/preference/loadout/deserialize(list/input, datum/preferences/preferences)
	if(!islist(input))
		return create_default_value(preferences)

	var/list/allowed_presets = list()
	for(var/preset_name in input)
		if(!istext(preset_name) || length(preset_name) < 1 || length(preset_name) > LOADOUT_MAX_NAME_LENGTH)
			continue
		allowed_presets[preset_name] = input[preset_name]
		if(length(allowed_presets) >= LOADOUT_MAX_PRESETS)
			break

	if(!length(allowed_presets))
		return create_default_value(preferences)

	return ..(allowed_presets, preferences)

/// Rebuild each item's detail list once the parent has resolved and filtered the paths.
/datum/preference/loadout/sanitize_loadout_list(list/passed_list, mob/optional_loadout_owner, client/owner_client)
	. = ..()
	for(var/item_path in .)
		.[item_path] = sanitize_item_details(.[item_path])

/// Rebuilds one entry's detail list from only the keys we know about. Always a list - the menu treats null as
/// "not in the loadout".
/datum/preference/loadout/proc/sanitize_item_details(list/details) as /list
	var/list/sanitized = list()
	if(!islist(details))
		return sanitized

	// Fed directly to set_greyscale(), so it has to actually be a GAGS color string
	var/greyscale_colors = details[INFO_GREYSCALE]
	if(istext(greyscale_colors) && findtext(greyscale_colors, GLOB.is_color_string))
		sanitized[INFO_GREYSCALE] = greyscale_colors

	var/custom_name = details[INFO_NAMED]
	if(istext(custom_name))
		custom_name = trim(STRIP_HTML_SIMPLE(custom_name, MAX_NAME_LEN), PREVENT_CHARACTER_TRIM_LOSS(MAX_NAME_LEN))
		if(length(custom_name))
			sanitized[INFO_NAMED] = custom_name

	// Reskins are matched against the item's own skin list on equip, so this only needs to be the right shape
	var/reskin = details[INFO_RESKIN]
	if(istext(reskin) && length(reskin) <= MAX_NAME_LEN)
		sanitized[INFO_RESKIN] = reskin

	// Layer is a boolean for accessories and a style name for lipstick, both of which fall back safely on anything unexpected
	var/layer = details[INFO_LAYER]
	if(isnum(layer) || (istext(layer) && length(layer) <= MAX_NAME_LEN))
		sanitized[INFO_LAYER] = layer

	// Written onto the equipped item's desc
	var/custom_description = details[INFO_DESCRIBED]
	if(istext(custom_description))
		custom_description = trim(STRIP_HTML_SIMPLE(custom_description, MAX_DESC_LEN), PREVENT_CHARACTER_TRIM_LOSS(MAX_DESC_LEN))
		if(length(custom_description))
			sanitized[INFO_DESCRIBED] = custom_description

	// Fed to color_transition_filter(), so it has to be a real color
	var/custom_color = details[INFO_CUSTOM_COLOR]
	if(istext(custom_color) && (findtext(custom_color, GLOB.is_color) || findtext(custom_color, GLOB.is_alpha_color)))
		sanitized[INFO_CUSTOM_COLOR] = sanitize_hexcolor(custom_color)

	// Only ever read for truthiness, to pick between two saturation modes
	if(!isnull(details[INFO_COLOR_MODE]))
		sanitized[INFO_COLOR_MODE] = !!details[INFO_COLOR_MODE]

	// Both of these are re-checked against the item's own component style on equip (see sanitize_core_selection and
	// sanitize_accessories), so they only need to survive as lists
	if(islist(details[INFO_GREYSCALE_COMPONENT_CORES]))
		sanitized[INFO_GREYSCALE_COMPONENT_CORES] = details[INFO_GREYSCALE_COMPONENT_CORES].Copy()
	if(islist(details[INFO_GREYSCALE_COMPONENT_ACCESSORIES]))
		sanitized[INFO_GREYSCALE_COMPONENT_ACCESSORIES] = details[INFO_GREYSCALE_COMPONENT_ACCESSORIES].Copy()

	return sanitized
