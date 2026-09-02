GAME_VERB_PROC_DESC(/client, import_preferences, "Import Preferences", "Replace your current preferences with a previously exported file.", "OOC")

	ASSERT(prefs, "User attempted to import preferences while preferences were null!") // what the fuck

	prefs.import_preferences_from_client(usr)
