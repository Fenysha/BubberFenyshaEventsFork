// Lets a player upload a preferences JSON they previously exported and have it replace their save.
// Ported from tgstation. Nothing in an uploaded file is trusted - see import.dm.

/// Separate from PREFS_BACKUP_PATH so the version updater running on the imported save can't clobber it.
#define PREFS_IMPORT_BACKUP_PATH(base_path) "[base_path].importbac"

/// One or more six digit hex colors run together, which is how GAGS color strings are stored.
GLOBAL_DATUM_INIT(is_color_string, /regex, regex("^(#\[0-9a-fA-F]{6})+$"))

/// Allows players to import a previously exported JSON file over their preferences. Left as a config toggle in case it needs to be turned off due to server-specific needs.
/datum/config_entry/flag/forbid_preferences_import
	default = FALSE

/// The number of seconds a player must wait between preference import attempts.
/datum/config_entry/number/seconds_cooldown_for_preferences_import
	default = 60
	min_val = 1
