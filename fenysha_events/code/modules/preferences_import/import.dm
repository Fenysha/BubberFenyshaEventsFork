/// The most keys a keybind is allowed to be bound to, matching what the keybindings menu itself enforces.
#define MAX_IMPORTED_HOTKEY_SLOTS 3
/// The longest a single key name is allowed to be, matching what the keybindings menu itself enforces.
#define MAX_IMPORTED_HOTKEY_LENGTH 100

/**
 * Prompts for a preferences JSON export, sanitizes it, and replaces the player's save. Returns TRUE if written.
 *
 * The new tree is built up rather than filtered down: we walk our own preference entries and ask each for a value,
 * so anything the file holds that we have no datum for never reaches the savefile. That is what makes a save from
 * a server with content we lack (ERP keys on a NOERP build) safe to import.
 */
/datum/preferences/proc/import_preferences_from_client(mob/requester)
	if(!load_and_save || !path || path == DEV_PREFS_PATH)
		tgui_alert(requester, "Your preferences aren't saved on this server, so there's nothing to import them into.", "Import Preferences JSON")
		return FALSE

	var/list/imported = savefile.request_json_from_client(requester)
	if(!length(imported))
		return FALSE

	// The version drives which migrations run afterwards, so it's the one value we have to reject on rather than default
	var/list/version_bounds = get_savefile_version_bounds()
	var/minimum_version = version_bounds[1]
	var/maximum_version = version_bounds[2]
	var/imported_version = imported["version"]
	if(!isnum(imported_version) || imported_version < minimum_version || imported_version > maximum_version)
		tgui_alert(
			requester,
			"That save is version [isnum(imported_version) ? imported_version : "unknown"], and this server only accepts \
			[minimum_version] through [maximum_version].",
			"Import Preferences JSON",
		)
		return FALSE

	var/list/errored_keys = list()
	var/list/sanitized = sanitize_imported_savefile(imported, imported_version, errored_keys)
	if(length(errored_keys))
		stack_trace("Preference keys threw while sanitizing an imported savefile: [json_encode(unique_list(errored_keys))]")

	// Own backup path: importing an older save runs the updater, which would clobber the updater's own backup.
	var/backup_path = PREFS_IMPORT_BACKUP_PATH(path)
	if(fexists(backup_path))
		fdel(backup_path)
	if(fexists(path))
		fcopy(path, backup_path)

	savefile.overwrite_tree(sanitized)

	// Reload from the tree we just wrote, which also runs the normal versioning and load time sanitization.
	value_cache = list() // untyped downstream, so it cannot be Cut() directly
	recently_updated_keys.Cut()
	key_bindings = deep_copy_list(GLOB.default_hotkeys)
	key_bindings_by_key = get_key_bindings_by_key(key_bindings)
	randomise = get_default_randomization()

	if(!load_preferences() || !load_character())
		randomise_appearance_prefs()
		all_quirks = list()
		save_character(TRUE) // save_character takes an update argument downstream

	apply_all_client_preferences()
	parent?.set_macros()
	parent?.update_special_keybinds()

	tainted_character_profiles = TRUE
	character_preview_view?.update_body()
	update_static_data_for_all_viewers()
	refresh_lobby_after_import()

	log_game("[key_name(parent)] imported a preferences JSON file (save version [imported_version]).")
	tgui_alert(requester, "Your preferences have been imported. Anything this server didn't recognise was reset to its default.", "Import Preferences JSON")
	return TRUE

/// Builds a fresh, fully sanitized savefile tree out of an untrusted decoded preferences export.
/datum/preferences/proc/sanitize_imported_savefile(list/imported, imported_version, list/errored_keys = list())
	var/list/sanitized = list()
	sanitized["version"] = imported_version

	errored_keys += sanitize_imported_preference_entries(imported, sanitized, PREFERENCE_PLAYER)

	sanitized["lastchangelog"] = sanitize_text(imported["lastchangelog"], initial(lastchangelog))
	sanitized["default_slot"] = sanitize_integer(imported["default_slot"], 1, max_save_slots, initial(default_slot))
	sanitized["toggles"] = sanitize_integer(imported["toggles"], 0, SHORT_REAL_LIMIT - 1, initial(toggles))
	sanitized["chat_toggles"] = sanitize_integer(imported["chat_toggles"], 0, SHORT_REAL_LIMIT - 1, initial(chat_toggles))
	sanitized["be_special"] = sanitize_be_special(SANITIZE_LIST(imported["be_special"]))
	sanitized["key_bindings"] = sanitize_imported_keybindings(imported["key_bindings"])
	sanitized["ignoring"] = sanitize_imported_ignoring(imported["ignoring"])
	sanitized["favorite_outfits"] = sanitize_imported_favorite_outfits(imported["favorite_outfits"])
	sanitized["job_assigned_profiles"] = sanitize_imported_job_profiles(imported["job_assigned_profiles"])

	// Never imported, none of it being the file's to hand out: hearted_until and antag_tickets are server granted,
	// and the vore trees (vore, bellies*, slot_metadata, slot_lookup_table) have no datum to sanitize them.

	// Only slots we would have made ourselves, so a file cannot stuff the tree full of character slots
	for(var/slot in 1 to max_save_slots)
		var/list/imported_slot = imported["character[slot]"]
		if(!islist(imported_slot) || !length(imported_slot))
			continue
		sanitized["character[slot]"] = sanitize_imported_character(imported_slot, imported_version, errored_keys)

	// Land on a slot the import actually gave us, rather than an empty one that would just get randomised on load
	if(!("character[sanitized["default_slot"]]" in sanitized))
		for(var/slot in 1 to max_save_slots)
			if("character[slot]" in sanitized)
				sanitized["default_slot"] = slot
				break

	return sanitized

/// Builds a fresh, fully sanitized character slot out of one untrusted slot of an imported savefile.
/datum/preferences/proc/sanitize_imported_character(list/imported, imported_version, list/errored_keys = list())
	var/list/sanitized = list()
	sanitized["version"] = imported_version

	errored_keys += sanitize_imported_preference_entries(imported, sanitized, PREFERENCE_CHARACTER)

	sanitized["randomise"] = sanitize_imported_randomisation(imported["randomise"])
	sanitized["job_preferences"] = sanitize_imported_job_preferences(imported["job_preferences"])
	sanitize_imported_character_modular(imported, sanitized) // The downstream character keys are not preference entries
	sanitized["all_quirks"] = SSquirks.filter_invalid_quirks(sanitize_imported_quirks(imported["all_quirks"]), sanitized["augments"]) // Augments move the quirk point balance downstream

	return sanitized

/// Runs each imported value for this identifier through its own preference datum. A value only survives if its
/// datum can deserialize and validate it; anything else is left out so load generates a default. Keys with no
/// datum on this build are never asked for. Returns the keys whose datum threw, for the caller to log.
/datum/preferences/proc/sanitize_imported_preference_entries(list/imported, list/sanitized, savefile_identifier)
	var/list/errored_keys = list()

	// Priority order, so entries that read other preferences to build their value see the sane ones first
	for(var/datum/preference/preference as anything in get_preferences_in_priority_order())
		if(preference.savefile_identifier != savefile_identifier)
			continue

		var/raw_value = imported[preference.savefile_key]
		if(isnull(raw_value))
			continue

		// deserialize() and is_valid() are only ever promised to handle values we wrote ourselves, and a preference
		// that chokes on a hostile one should cost that single preference rather than the whole import.
		try
			var/value = preference.deserialize(raw_value, src)
			if(!isnull(value) && preference.is_valid(value, src))
				sanitized[preference.savefile_key] = preference.serialize(value)
		catch
			errored_keys += preference.savefile_key

	return errored_keys

/// Keybind name to a short list of key names, matching what the keybindings menu will accept.
/datum/preferences/proc/sanitize_imported_keybindings(imported_key_bindings)
	var/list/sanitized = list()
	// sanitize_keybindings drops every bind name we do not have a keybinding datum for
	for(var/keybind_name in sanitize_keybindings(imported_key_bindings))
		var/list/keys = list()
		for(var/key in SANITIZE_LIST(imported_key_bindings[keybind_name]))
			if(!istext(key) || length(key) > MAX_IMPORTED_HOTKEY_LENGTH)
				continue
			keys |= key
			if(length(keys) >= MAX_IMPORTED_HOTKEY_SLOTS)
				break
		sanitized[keybind_name] = keys
	return sanitized

/// Ckeys of players being ignored in OOC.
/datum/preferences/proc/sanitize_imported_ignoring(imported_ignoring)
	var/list/sanitized = list()
	for(var/entry in SANITIZE_LIST(imported_ignoring))
		if(!istext(entry))
			continue
		var/cleaned = ckey(entry)
		if(cleaned)
			sanitized |= cleaned
	return sanitized

/// Outfit typepaths, kept as the text the savefile stores them as.
/datum/preferences/proc/sanitize_imported_favorite_outfits(imported_outfits)
	var/list/sanitized = list()
	for(var/entry in SANITIZE_LIST(imported_outfits))
		if(!istext(entry))
			continue
		if(ispath(text2path(entry), /datum/outfit))
			sanitized |= entry
	return sanitized

/// Job title to the character slot that job should use. Both halves have to be real for the entry to survive.
/datum/preferences/proc/sanitize_imported_job_profiles(imported_profiles)
	var/list/sanitized = list()
	for(var/job_title, slot in SANITIZE_LIST(imported_profiles))
		if(!isnum(slot) || slot != sanitize_integer(slot, 1, max_save_slots, null))
			continue
		if(!istext(job_title) || isnull(SSjob.get_job(job_title)))
			continue
		sanitized[job_title] = slot
	return sanitized

/// Job title to priority, matching what the jobs menu will accept.
/datum/preferences/proc/sanitize_imported_job_preferences(imported_preferences)
	var/list/sanitized = list()
	for(var/job_title, priority in SANITIZE_LIST(imported_preferences))
		if(priority != JP_LOW && priority != JP_MEDIUM && priority != JP_HIGH)
			continue
		if(!istext(job_title))
			continue
		var/datum/job/job = SSjob.get_job(job_title)
		if(isnull(job) || job.faction != FACTION_STATION)
			continue
		sanitized[job_title] = priority
	return sanitized

/// Randomisation toggles, keyed by the savefile key of a preference that can actually be randomized.
/datum/preferences/proc/sanitize_imported_randomisation(imported_randomise)
	var/list/sanitized = list()
	for(var/preference_key, setting in SANITIZE_LIST(imported_randomise))
		// Same rule the randomisation menu uses: only these two are stored, and RANDOM_DISABLED is the absence of a key
		if(setting != RANDOM_ENABLED && setting != RANDOM_ANTAG_ONLY)
			continue
		var/datum/preference/preference = GLOB.preference_entries_by_key[preference_key]
		if(isnull(preference) || !preference.is_randomizable())
			continue
		sanitized[preference_key] = setting
	return sanitized

/// Quirk names, deduplicated. filter_invalid_quirks() handles existence, blacklists and the point balance afterwards.
/datum/preferences/proc/sanitize_imported_quirks(imported_quirks)
	var/list/sanitized = list()
	for(var/quirk_name in SANITIZE_LIST(imported_quirks))
		if(istext(quirk_name))
			sanitized |= quirk_name
	return sanitized

#undef MAX_IMPORTED_HOTKEY_SLOTS
#undef MAX_IMPORTED_HOTKEY_LENGTH
