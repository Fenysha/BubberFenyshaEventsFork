/// Widest value a numeric character feature is allowed to import as. Every feature that means a size is far inside this.
#define MAX_IMPORTED_FEATURE_NUMBER 1000
/// Most colors a single feature entry is allowed to carry, matching the tri-color preferences.
#define MAX_IMPORTED_FEATURE_COLORS 3
/// Most languages an imported character may claim. The languages menu re-checks this against the species limit on load.
#define MAX_IMPORTED_LANGUAGES 20

/// The keys save_character_skyrat() writes are not preference entries, so sanitize_imported_preference_entries()
/// never sees them and they would otherwise come through unchecked. Rebuilt key by key against what this server
/// has; anything unvalidatable is left out for load_character_skyrat() to default.
/datum/preferences/proc/sanitize_imported_character_modular(list/imported, list/sanitized)
	sanitized["augments"] = sanitize_imported_augments(imported["augments"])
	sanitized["augment_limb_styles"] = sanitize_imported_augment_limb_styles(imported["augment_limb_styles"])
	sanitized["features"] = sanitize_imported_features(imported["features"])
	sanitized["mutant_bodyparts"] = sanitize_imported_mutant_bodyparts(imported["mutant_bodyparts"])
	sanitized["body_markings"] = sanitize_imported_body_markings(imported["body_markings"])
	sanitized["alt_job_titles"] = validate_alt_jobs(SANITIZE_LIST(imported["alt_job_titles"]))
	sanitized["languages"] = sanitize_imported_languages(imported["languages"])
	sanitized["food_preferences"] = sanitize_imported_food_preferences(imported["food_preferences"])
	sanitized["mismatched_customization"] = !!imported["mismatched_customization"]
	sanitized["allow_advanced_colors"] = !!imported["allow_advanced_colors"]
	sanitized["tgui_prefs_migration"] = !!imported["tgui_prefs_migration"]

	// Kept so the modular updater still runs on an older file, but never above ours or it skips migrations.
	var/imported_modular_version = imported["modular_version"]
	if(isnum(imported_modular_version) && imported_modular_version >= 1)
		sanitized["modular_version"] = min(round(imported_modular_version), get_modular_savefile_version_max())

	// The preset migration reads the pre-presets key; without this a save older than it silently loses its loadout.
	if(islist(imported["loadout_list"]))
		var/datum/preference/loadout/loadout_preference = GLOB.preference_entries[/datum/preference/loadout]
		sanitized["loadout_list"] = loadout_preference?.sanitize_loadout_list(imported["loadout_list"], null, parent)

/// Augment slot to augment typepath, keeping only augments this server actually offers.
/datum/preferences/proc/sanitize_imported_augments(imported_augments)
	var/list/sanitized = list()
	for(var/slot, augment in SANITIZE_LIST(imported_augments))
		if(!istext(slot))
			continue
		var/augment_path = istext(augment) ? _text2path(augment) : augment
		if(isnull(GLOB.augment_items[augment_path]))
			continue
		// Resolved path, not the JSON text: filter_invalid_quirks() keys GLOB.augment_items with it, unguarded.
		sanitized[slot] = augment_path
	return sanitized

/// Limb key to robotic style name, matching what load_character_skyrat() would otherwise strip on load anyway.
/datum/preferences/proc/sanitize_imported_augment_limb_styles(imported_styles)
	var/list/sanitized = list()
	for(var/limb_key, style in SANITIZE_LIST(imported_styles))
		if(!istext(limb_key) || !istext(style))
			continue
		if(isnull(GLOB.robotic_styles_list[style]))
			continue
		sanitized[limb_key] = style
	return sanitized

/// DNA features. prefs.features is handed straight to set_species() as override_features, so it becomes dna.features
/// and is read by species, organ and sprite code that assumes we wrote it. Unknown keys are dropped.
/datum/preferences/proc/sanitize_imported_features(imported_features)
	var/list/sanitized = list()
	var/list/known_keys = get_known_feature_keys()
	for(var/feature_key, value in SANITIZE_LIST(imported_features))
		if(!istext(feature_key) || !known_keys[feature_key])
			continue

		if(islist(value))
			// The tri-color features store a short list of hex colors and nothing else
			var/list/colors = list()
			for(var/color in value)
				if(!istext(color) || !findtext(color, GLOB.is_color))
					break
				colors += sanitize_hexcolor(color)
				if(length(colors) >= MAX_IMPORTED_FEATURE_COLORS)
					break
			if(length(colors))
				sanitized[feature_key] = colors
			continue

		if(isnum(value))
			sanitized[feature_key] = clamp(round(value), -MAX_IMPORTED_FEATURE_NUMBER, MAX_IMPORTED_FEATURE_NUMBER)
			continue

		if(istext(value))
			if(findtext(value, GLOB.is_color) || findtext(value, GLOB.is_alpha_color))
				sanitized[feature_key] = sanitize_hexcolor(value)
			else
				sanitized[feature_key] = STRIP_HTML_SIMPLE(value, MAX_MESSAGE_LEN)
			continue

	return sanitized

/// Every DNA feature key this build knows about, so an imported features list can be filtered down to it.
/datum/preferences/proc/get_known_feature_keys() as /list
	var/static/list/known_feature_keys

	if(!isnull(known_feature_keys))
		return known_feature_keys

	known_feature_keys = list()
	for(var/feature_key in MANDATORY_FEATURE_LIST)
		known_feature_keys[feature_key] = TRUE
	for(var/feature_key in SSaccessories.feature_list)
		known_feature_keys[feature_key] = TRUE
	for(var/datum/dna_block/feature/block as anything in subtypesof(/datum/dna_block/feature))
		if(block::feature_key)
			known_feature_keys[block::feature_key] = TRUE
	for(var/preference_type in GLOB.preference_entries)
		var/datum/preference/choiced/species_feature/preference = GLOB.preference_entries[preference_type]
		if(istype(preference) && preference.feature_key)
			known_feature_keys[preference.feature_key] = TRUE

	return known_feature_keys

/**
 * Mutant bodyparts, as bodypart key to a name and color list.
 *
 * The accessory has to exist, because the preferences menu dereferences it without a null check
 * (see the mutant_bodyparts loop in randomise_appearance_prefs).
 */
/datum/preferences/proc/sanitize_imported_mutant_bodyparts(imported_bodyparts)
	var/list/sanitized = list()
	for(var/bodypart_key, entry in SANITIZE_LIST(imported_bodyparts))
		if(!istext(bodypart_key) || !islist(entry))
			continue

		var/list/accessories = SSaccessories.sprite_accessories[bodypart_key]
		if(!length(accessories))
			continue

		var/list/details = entry
		var/accessory_name = details[MUTANT_INDEX_NAME]
		if(!istext(accessory_name) || isnull(accessories[accessory_name]))
			continue

		var/list/sanitized_entry = list()
		sanitized_entry[MUTANT_INDEX_NAME] = accessory_name
		sanitized_entry[MUTANT_INDEX_COLOR_LIST] = sanitize_imported_color_list(details[MUTANT_INDEX_COLOR_LIST])
		var/list/emissives = details[MUTANT_INDEX_EMISSIVE_LIST]
		if(islist(emissives))
			sanitized_entry[MUTANT_INDEX_EMISSIVE_LIST] = sanitize_imported_color_list(emissives)

		sanitized[bodypart_key] = sanitized_entry
	return sanitized

/// Body markings, as body zone to marking name to color. update_markings() normalises the value shape on load.
/datum/preferences/proc/sanitize_imported_body_markings(imported_markings)
	var/list/sanitized = list()
	for(var/zone, markings in SANITIZE_LIST(imported_markings))
		if(!istext(zone) || !islist(markings))
			continue

		var/list/sanitized_zone = list()
		for(var/marking_name, color in markings)
			// GLOB.body_markings is dereferenced without a null check when defaulting colors, so the name has to be real
			if(!istext(marking_name) || isnull(GLOB.body_markings[marking_name]))
				continue
			if(islist(color))
				var/list/color_entry = color
				sanitized_zone[marking_name] = list(sanitize_hexcolor(color_entry[1]), !!(length(color_entry) > 1 && color_entry[2]))
			else if(istext(color))
				sanitized_zone[marking_name] = sanitize_hexcolor(color)

		if(length(sanitized_zone))
			sanitized[zone] = sanitized_zone
	return sanitized

/// Language typepath to its understood/spoken bitflags. The languages menu re-checks the count against the species on load.
/datum/preferences/proc/sanitize_imported_languages(imported_languages)
	var/list/sanitized = list()
	for(var/language, flags in SANITIZE_LIST(imported_languages))
		if(!isnum(flags))
			continue
		var/language_path = istext(language) ? _text2path(language) : language
		if(!ispath(language_path, /datum/language))
			continue
		var/sanitized_flags = round(flags) & (UNDERSTOOD_LANGUAGE | SPOKEN_LANGUAGE)
		if(!sanitized_flags)
			continue
		sanitized[language] = sanitized_flags
		if(length(sanitized) >= MAX_IMPORTED_LANGUAGES)
			break
	return sanitized

/// Food category to its liked/disliked/toxic setting, plus the "enabled" toggle the food menu stores alongside them.
/datum/preferences/proc/sanitize_imported_food_preferences(imported_food)
	var/list/sanitized = list()
	for(var/food_entry, setting in SANITIZE_LIST(imported_food))
		if(!istext(food_entry))
			continue
		if(food_entry == "enabled")
			sanitized[food_entry] = !!setting
			continue
		// GLOB.food_defaults is what the menu builds itself from, so anything outside it has no category to apply to
		if(isnull(GLOB.food_defaults[food_entry]))
			continue
		if(!isnum(setting) || setting != round(setting) || setting < FOOD_PREFERENCE_TOXIC || setting > FOOD_PREFERENCE_OBSCURE)
			continue
		sanitized[food_entry] = setting
	return sanitized

/// A short list of hex colors, which is how both mutant bodyparts and features store their coloring.
/datum/preferences/proc/sanitize_imported_color_list(imported_colors)
	var/list/sanitized = list()
	if(istext(imported_colors))
		return list(sanitize_hexcolor(imported_colors))
	for(var/color in SANITIZE_LIST(imported_colors))
		sanitized += sanitize_hexcolor(istext(color) ? color : null)
		if(length(sanitized) >= MAX_IMPORTED_FEATURE_COLORS)
			break
	return sanitized

#undef MAX_IMPORTED_FEATURE_NUMBER
#undef MAX_IMPORTED_FEATURE_COLORS
#undef MAX_IMPORTED_LANGUAGES
