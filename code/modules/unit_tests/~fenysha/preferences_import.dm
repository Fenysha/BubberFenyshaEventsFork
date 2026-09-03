
/// Requires an imported preferences file to only ever contribute values our own datums are willing to accept.
/datum/unit_test/preferences_import_sanitization

/datum/unit_test/preferences_import_sanitization/Run()
	var/datum/preferences/preferences = new(new /datum/client_interface)
	// The savefile the preferences datum just wrote for itself is, by definition, at a version we accept
	var/current_version = preferences.savefile.get_entry("version")
	TEST_ASSERT_NOTNULL(current_version, "a freshly created preferences datum had no save version")

	// Taken from the server's own list so this does not rot when the augment roster changes
	var/real_augment_path = length(GLOB.augment_items) ? GLOB.augment_items[1] : null
	TEST_ASSERT_NOTNULL(real_augment_path, "the server has no augments to test the import against")

	var/list/hostile_save = list(
		"version" = current_version,
		"totally_made_up_key" = "should not survive",
		"hearted_until" = world.realtime + 10 HOURS,
		"antag_tickets" = 9999,
		"default_slot" = 9999,
		"toggles" = "not a number",
		"be_special" = list("ROLE_DEFINITELY_NOT_REAL"),
		"ignoring" = list("Some Guy", list("nested")),
		"favorite_outfits" = list("/datum/outfit/job/assistant", "/obj/item/not_an_outfit", 42),
		"job_assigned_profiles" = list(JOB_ASSISTANT = 9999, "Not A Job" = 1),
		"key_bindings" = list("not_a_keybind" = list("A"), "swap_hands" = list("A", "B", "C", "D", 5)),
		"character1" = list(
			"version" = current_version,
			"real_name" = "Test Testerson",
			"made_up_character_key" = "should not survive",
			"job_preferences" = list(JOB_ASSISTANT = "not a priority", "Not A Job" = JP_HIGH),
			"all_quirks" = list("Not A Quirk", list("nested")),
			"randomise" = list(
				"not_a_preference" = RANDOM_ENABLED,
				"species" = RANDOM_ANTAG_ONLY,
				"hairstyle_name" = "not a randomisation setting",
			),
			// The modular character keys, which are not preference entries
			// A real augment, taken as text the way JSON would hold it, alongside one that doesn't exist.
			// filter_invalid_quirks() prices every surviving augment out of GLOB.augment_items without a null
			// check, so a kept entry has to be stored as something that list can actually be keyed by.
			"augments" = list("head" = "[real_augment_path]", "chest" = "/obj/item/definitely_not_an_augment"),
			"augment_limb_styles" = list("l_arm" = "Not A Robotic Style"),
			"mutant_bodyparts" = list("not_a_bodypart" = list("name" = "Nonexistent", "color" = list("#FFFFFF"))),
			"body_markings" = list("chest" = list("Not A Marking" = "#FFFFFF")),
			"languages" = list("/datum/language/common" = UNDERSTOOD_LANGUAGE | SPOKEN_LANGUAGE, "/obj/item/not_a_language" = 3),
			"food_preferences" = list("enabled" = TRUE, "Not A Food Category" = FOOD_PREFERENCE_LIKED),
			"modular_version" = 9999,
			"features" = list(
				"mcolor" = "#00FF00",
				"not_a_feature_key" = "should not survive",
				"flavor_text" = "<script>alert(1)</script>plain",
				"penis_size" = 99999,
			),
		),
		"character99" = list("version" = current_version, "real_name" = "Out Of Bounds"),
	)

	var/list/sanitized = preferences.sanitize_imported_savefile(hostile_save, current_version)

	TEST_ASSERT(!("totally_made_up_key" in sanitized), "an unrecognised key survived import sanitization")
	TEST_ASSERT(!("hearted_until" in sanitized), "hearted_until survived import sanitization")
	TEST_ASSERT(!("antag_tickets" in sanitized), "antag_tickets survived import sanitization")
	TEST_ASSERT(!("character99" in sanitized), "a character slot past max_save_slots survived import sanitization")
	TEST_ASSERT_EQUAL(sanitized["default_slot"], initial(preferences.default_slot), "an out of range default_slot wasn't reset")
	TEST_ASSERT_EQUAL(sanitized["toggles"], initial(preferences.toggles), "a non numeric toggles bitfield wasn't reset")
	TEST_ASSERT_EQUAL(length(sanitized["be_special"]), 0, "a made up antag flag survived import sanitization")
	TEST_ASSERT_EQUAL(length(sanitized["favorite_outfits"]), 1, "favorite outfits weren't filtered down to real outfit paths")
	TEST_ASSERT_EQUAL(length(sanitized["job_assigned_profiles"]), 0, "an unknown job or out of range slot survived import sanitization")

	var/list/ignoring = sanitized["ignoring"]
	TEST_ASSERT_EQUAL(length(ignoring), 1, "ignoring wasn't filtered down to real ckeys")
	TEST_ASSERT_EQUAL(ignoring[1], "someguy", "an ignored name wasn't converted to a ckey")

	var/list/key_bindings = sanitized["key_bindings"]
	TEST_ASSERT(!("not_a_keybind" in key_bindings), "an unknown keybind survived import sanitization")
	TEST_ASSERT_EQUAL(length(key_bindings["swap_hands"]), 3, "a keybind kept more keys than the keybindings menu allows")

	var/list/character = sanitized["character1"]
	TEST_ASSERT_NOTNULL(character, "a valid character slot was dropped by import sanitization")
	TEST_ASSERT(!("made_up_character_key" in character), "an unrecognised character key survived import sanitization")
	TEST_ASSERT_EQUAL(character["real_name"], "Test Testerson", "a valid character preference was dropped by import sanitization")
	TEST_ASSERT_EQUAL(length(character["job_preferences"]), 0, "an invalid job preference survived import sanitization")
	TEST_ASSERT_EQUAL(length(character["all_quirks"]), 0, "a made up quirk survived import sanitization")
	var/list/randomise = character["randomise"]
	TEST_ASSERT(!("not_a_preference" in randomise), "a randomisation toggle for an unknown preference survived import sanitization")
	TEST_ASSERT(!("hairstyle_name" in randomise), "a randomisation toggle with a junk setting survived import sanitization")
	TEST_ASSERT_EQUAL(randomise["species"], RANDOM_ANTAG_ONLY, "an antag-only randomisation toggle was dropped by import sanitization")

	// The modular character keys
	var/list/imported_augments = character["augments"]
	TEST_ASSERT_EQUAL(length(imported_augments), 1, "a made up augment survived import sanitization, or a real one was dropped")
	TEST_ASSERT_NOTNULL(GLOB.augment_items[imported_augments["head"]], "a surviving augment was not stored as something GLOB.augment_items can be keyed by")
	TEST_ASSERT_EQUAL(length(character["augment_limb_styles"]), 0, "a made up robotic limb style survived import sanitization")
	TEST_ASSERT_EQUAL(length(character["mutant_bodyparts"]), 0, "a mutant bodypart with no sprite accessory survived import sanitization")
	TEST_ASSERT_EQUAL(length(character["body_markings"]), 0, "a made up body marking survived import sanitization")
	TEST_ASSERT_EQUAL(length(character["languages"]), 1, "languages weren't filtered down to real language typepaths")
	TEST_ASSERT_EQUAL(length(character["food_preferences"]), 1, "a made up food category survived import sanitization")
	TEST_ASSERT(character["modular_version"] <= 8, "an out of range modular_version wasn't clamped to our own")

	var/list/features = character["features"]
	TEST_ASSERT(!("not_a_feature_key" in features), "an unknown DNA feature key survived import sanitization")
	// sanitize_hexcolor() normalises to lowercase, so compare against that rather than what we fed in
	TEST_ASSERT_EQUAL(features["mcolor"], "#00ff00", "a valid DNA feature color was dropped by import sanitization")
	TEST_ASSERT(!findtext(features["flavor_text"], "<script>"), "markup in a DNA feature text wasn't stripped")
	TEST_ASSERT(features["penis_size"] <= 1000, "an out of range numeric DNA feature wasn't clamped")

/// Requires a save exported from a server with erotic content to lose all of it on a build that doesn't compile it.
/datum/unit_test/preferences_import_drops_uncompiled_content

/datum/unit_test/preferences_import_drops_uncompiled_content/Run()
	var/datum/preferences/preferences = new(new /datum/client_interface)
	var/current_version = preferences.savefile.get_entry("version")

	// Savefile keys of the erotic preferences, taken from the modules a NOERP build leaves out. These are exactly
	// what an export from an ERP enabled downstream carries, and none of them may come back in through an import.
	var/static/list/erotic_savefile_keys = list(
		"master_erp_pref",
		"erp_pref",
		"erp_status_pref",
		"erp_status_pref_hypnosis",
		"erp_free_use",
		"sextoy_pref",
		"hypnosis_pref",
		"genitalia_removal_pref",
		"vore_pref",
	)

	var/list/erotic_player_values = list("version" = current_version)
	var/list/erotic_character_values = list("version" = current_version)
	for(var/erotic_key in erotic_savefile_keys)
		erotic_player_values[erotic_key] = "Yes"
		erotic_character_values[erotic_key] = "Yes"

	// The lewd character data that lives outside the preference entries entirely
	erotic_character_values["features"] = list("penis_size" = 25, "breasts_size" = 9)
	erotic_character_values["mutant_bodyparts"] = list("penis" = list("name" = "Human", "color" = list("#FFFFFF")))
	erotic_player_values["character1"] = erotic_character_values
	erotic_player_values["vore"] = list("belly_prefs" = "should not survive")
	erotic_player_values["bellies1"] = list("stomach" = "should not survive")
	erotic_player_values["slot_metadata"] = list("junk")
	erotic_player_values["slot_lookup_table"] = list("junk")

	var/list/sanitized = preferences.sanitize_imported_savefile(erotic_player_values, current_version)
	var/list/character = sanitized["character1"]
	TEST_ASSERT_NOTNULL(character, "the character slot of an erotic content export was dropped entirely")

	for(var/erotic_key in erotic_savefile_keys)
		// A key only survives if this build actually compiled a preference datum that owns it
		var/uncompiled = isnull(GLOB.preference_entries_by_key[erotic_key])
		if(!uncompiled)
			continue
		TEST_ASSERT(!(erotic_key in sanitized), "erotic preference key [erotic_key] survived import with no datum to own it")
		TEST_ASSERT(!(erotic_key in character), "erotic character key [erotic_key] survived import with no datum to own it")

	TEST_ASSERT(!("vore" in sanitized), "the vore preference tree survived import sanitization")
	TEST_ASSERT(!("bellies1" in sanitized), "a vore belly tree survived import sanitization")
	TEST_ASSERT(!("slot_metadata" in sanitized), "vore slot metadata survived import sanitization")
	TEST_ASSERT(!("slot_lookup_table" in sanitized), "the vore slot lookup table survived import sanitization")

	// Genital sprite accessories aren't compiled either, so the bodypart entry has nothing to resolve against
	if(isnull(SSaccessories.sprite_accessories["penis"]))
		TEST_ASSERT_EQUAL(length(character["mutant_bodyparts"]), 0, "a genital mutant bodypart survived import with no accessory to match")



