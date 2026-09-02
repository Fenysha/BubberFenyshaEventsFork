/datum/json_savefile
	/// Cooldown that tracks the time between attempts to upload a savefile.
	COOLDOWN_DECLARE(upload_cooldown)

/// Replaces the entire tree with the given one and writes it out. Only for callers that built the tree themselves.
/datum/json_savefile/proc/overwrite_tree(list/new_tree)
	tree = new_tree.Copy()
	save()

/// Anything bigger than this is not one of our exports, and we would rather not decode a megabyte of nesting to find that out.
#define MAX_IMPORTED_PREFERENCES_SIZE (1 * 1024 * 1024)

/**
 * Prompts the requester to upload a preferences JSON file and decodes it.
 *
 * The returned list is raw, attacker controlled data that has been checked for nothing beyond "it decoded into a list".
 * Sanitizing it is entirely the caller's job, see [/datum/preferences/proc/import_preferences_from_client].
 */
/datum/json_savefile/proc/request_json_from_client(mob/requester)
	if(!istype(requester) || !path)
		return null

	if(!COOLDOWN_FINISHED(src, upload_cooldown))
		tgui_alert(requester, "You must wait [DisplayTimeText(COOLDOWN_TIMELEFT(src, upload_cooldown))] before importing preferences again!", "Import Preferences JSON")
		return null

	var/confirmation = tgui_alert(
		requester,
		"Importing will replace every preference and character slot you currently have. \
		A copy of your existing save is kept on the server in case the import goes wrong. Continue?",
		"Import Preferences JSON",
		list("Cancel", "Yes"),
	)
	if(confirmation != "Yes")
		return null

	var/uploaded_file = input(requester, "Choose a preferences JSON file to import.", "Import Preferences JSON") as null|file
	if(isnull(uploaded_file))
		return null

	COOLDOWN_START(src, upload_cooldown, (CONFIG_GET(number/seconds_cooldown_for_preferences_import) * (1 SECONDS)))

	if(length(uploaded_file) > MAX_IMPORTED_PREFERENCES_SIZE)
		tgui_alert(requester, "That file is far too large to be a preferences export.", "Import Preferences JSON")
		return null

	var/list/decoded
	try
		decoded = json_decode(file2text(uploaded_file))
	catch
		decoded = null

	if(!islist(decoded) || !length(decoded))
		tgui_alert(requester, "That file could not be read as a preferences JSON export.", "Import Preferences JSON")
		return null

	return decoded

#undef MAX_IMPORTED_PREFERENCES_SIZE
