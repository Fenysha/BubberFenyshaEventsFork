/**
 * Database-backed connection whitelist.
 *
 * Core keeps the whitelist in `config/whitelist.txt` and checks it from
 * `check_whitelist()` in `code/modules/admin/whitelist.dm`. That check only ever reads
 * `GLOB.whitelist`, so this module leaves core alone entirely and just swaps the contents
 * of that list for what the database says once the subsystem comes up.
 *
 * Entries live in the shared `player_rank` table under the `whitelist` rank, so there is
 * no schema migration to run - the table, and the triggers that mirror every change into
 * `player_rank_log`, already exist. See `SQL/skyrat_schema.sql`.
 *
 * Requires `USEWHITELIST` in `config/config.txt` to be set, same as the core system.
 * Optionally, add to `config/game_options.txt`:
 *
 *   ## Keeps the whitelist in config/whitelist.txt instead of the database.
 *   #WHITELIST_LEGACY_SYSTEM
 */

/// The table holding every player rank, the whitelist included.
#define WHITELIST_TABLE_NAME "player_rank"
/// The value of the `rank` column used for whitelist entries.
#define WHITELIST_RANK_TITLE "whitelist"

/// Set to keep reading the whitelist from `whitelist.txt`, leaving the database untouched.
/datum/config_entry/flag/whitelist_legacy_system
	protection = CONFIG_ENTRY_LOCKED


SUBSYSTEM_DEF(whitelist)
	name = "Whitelist"
	init_stage = INITSTAGE_EARLY
	ss_flags = SS_NO_FIRE
	dependencies = list(
		/datum/controller/subsystem/dbcore,
		/datum/controller/subsystem/admin_verbs,
	)
	/// Whether `GLOB.whitelist` currently reflects the database rather than `whitelist.txt`.
	var/loaded = FALSE


/datum/controller/subsystem/whitelist/Initialize()
	if(!CONFIG_GET(flag/usewhitelist))
		return SS_INIT_NO_NEED

	if(CONFIG_GET(flag/whitelist_legacy_system))
		return SS_INIT_NO_NEED

	// Core's "Whitelist CKey" verb appends to config/whitelist.txt, which nothing reads once
	// the database owns the list. Drop it so admins can't reach for it by mistake, and so it
	// doesn't sit in the panel under the same name as the one in whitelist_verbs.dm.
	SSadmin_verbs.admin_verbs_by_type -= /datum/admin_verb/whitelist_player

	if(!load_whitelist_from_db())
		return SS_INIT_FAILURE

	return SS_INIT_SUCCESS


/**
 * Replaces `GLOB.whitelist` with every non-deleted whitelist ckey in the database.
 *
 * On failure the list is left exactly as core loaded it from `whitelist.txt`, so a dead
 * database degrades to the flat file instead of locking every player out of the server.
 *
 * Returns TRUE if the list now comes from the database.
 */
/datum/controller/subsystem/whitelist/proc/load_whitelist_from_db()
	if(IsAdminAdvancedProcCall())
		return FALSE

	if(!SSdbcore.Connect())
		report_load_failure("could not connect to the database")
		return FALSE

	var/datum/db_query/query_load_whitelist = SSdbcore.NewQuery(
		"SELECT ckey FROM [format_table_name(WHITELIST_TABLE_NAME)] WHERE deleted = 0 AND rank = :rank",
		list("rank" = WHITELIST_RANK_TITLE),
	)

	if(!query_load_whitelist.warn_execute())
		qdel(query_load_whitelist)
		report_load_failure("the whitelist query failed")
		return FALSE

	// Kept as a flat list of ckeys rather than an associative one, because core's
	// check_whitelist() does a plain `in` against it.
	var/list/whitelisted_ckeys = list()
	while(query_load_whitelist.NextRow())
		var/whitelisted_ckey = ckey(query_load_whitelist.item[1])
		if(whitelisted_ckey)
			whitelisted_ckeys |= whitelisted_ckey

	qdel(query_load_whitelist)

	GLOB.whitelist = whitelisted_ckeys
	loaded = TRUE
	return TRUE


/**
 * Complains loudly when the whitelist could not be read out of the database, since the
 * server is now running off a flat file that nobody has been maintaining.
 *
 * Arguments:
 * * reason - What went wrong, for the logs and the admin notice.
 */
/datum/controller/subsystem/whitelist/proc/report_load_failure(reason)
	PROTECTED_PROC(TRUE)

	loaded = FALSE
	var/message = "Whitelist: [reason], falling back to whitelist.txt ([length(GLOB.whitelist)] ckeys)."
	log_config(message)
	log_game(message)
	message_admins(span_adminnotice(message))


/**
 * Adds a ckey to the whitelist, in the database and in the running round.
 *
 * Arguments:
 * * user - The admin making the change, used for the permission check and the audit trail.
 * * target_ckey - The ckey to whitelist.
 *
 * Returns TRUE if the ckey ended up whitelisted.
 */
/datum/controller/subsystem/whitelist/proc/add_ckey(client/user, target_ckey)
	if(IsAdminAdvancedProcCall())
		return FALSE

	if(!istype(user) || !user.holder?.check_for_rights(R_BAN))
		to_chat(user, span_warning("You do not possess the permissions to do this."))
		return FALSE

	target_ckey = ckey(target_ckey)
	if(!target_ckey)
		return FALSE

	if(target_ckey in GLOB.whitelist)
		to_chat(user, span_warning("[target_ckey] is already whitelisted!"))
		return FALSE

	if(!can_edit_whitelist(user))
		return FALSE

	var/datum/db_query/query_add_whitelist = SSdbcore.NewQuery(
		"INSERT INTO [format_table_name(WHITELIST_TABLE_NAME)] (ckey, rank, admin_ckey) VALUES (:ckey, :rank, :admin_ckey) \
		ON DUPLICATE KEY UPDATE deleted = 0, admin_ckey = :admin_ckey",
		list("ckey" = target_ckey, "rank" = WHITELIST_RANK_TITLE, "admin_ckey" = user.ckey),
	)

	. = query_add_whitelist.warn_execute()
	qdel(query_add_whitelist)

	if(!.)
		return FALSE

	if(!GLOB.whitelist)
		GLOB.whitelist = list()

	GLOB.whitelist |= target_ckey
	return TRUE


/**
 * Removes a ckey from the whitelist, in the database and in the running round.
 *
 * The database row is only flagged deleted, so `player_rank_log` keeps the full history.
 *
 * Arguments:
 * * user - The admin making the change, used for the permission check and the audit trail.
 * * target_ckey - The ckey to unwhitelist.
 *
 * Returns TRUE if the ckey ended up off the whitelist.
 */
/datum/controller/subsystem/whitelist/proc/remove_ckey(client/user, target_ckey)
	if(IsAdminAdvancedProcCall())
		return FALSE

	if(!istype(user) || !user.holder?.check_for_rights(R_BAN))
		to_chat(user, span_warning("You do not possess the permissions to do this."))
		return FALSE

	target_ckey = ckey(target_ckey)
	if(!target_ckey)
		return FALSE

	if(!(target_ckey in GLOB.whitelist))
		to_chat(user, span_warning("[target_ckey] is not whitelisted!"))
		return FALSE

	if(!can_edit_whitelist(user))
		return FALSE

	var/datum/db_query/query_remove_whitelist = SSdbcore.NewQuery(
		"UPDATE [format_table_name(WHITELIST_TABLE_NAME)] SET deleted = 1, admin_ckey = :admin_ckey WHERE ckey = :ckey AND rank = :rank",
		list("ckey" = target_ckey, "rank" = WHITELIST_RANK_TITLE, "admin_ckey" = user.ckey),
	)

	. = query_remove_whitelist.warn_execute()
	qdel(query_remove_whitelist)

	if(!.)
		return FALSE

	GLOB.whitelist -= target_ckey
	return TRUE


/**
 * Guards the two editing procs against writing somewhere the change would not stick.
 *
 * Arguments:
 * * user - The admin to complain to.
 */
/datum/controller/subsystem/whitelist/proc/can_edit_whitelist(client/user)
	PROTECTED_PROC(TRUE)

	if(CONFIG_GET(flag/whitelist_legacy_system))
		to_chat(user, span_warning("The server is running the legacy whitelist, edit config/whitelist.txt instead."))
		return FALSE

	if(!SSdbcore.Connect())
		to_chat(user, span_warning("The database is not connected, the whitelist cannot be edited."))
		return FALSE

	return TRUE


/**
 * Copies every ckey in the legacy `whitelist.txt` into the database, leaving the ones
 * that already have a row there alone.
 *
 * Returns the number of ckeys read out of the file, or null if the import did not run.
 */
/datum/controller/subsystem/whitelist/proc/import_legacy_file()
	if(IsAdminAdvancedProcCall())
		return null

	if(!SSdbcore.Connect())
		return null

	var/list/rows_to_insert = list()
	for(var/line in world.file2list("[global.config.directory]/whitelist.txt"))
		if(!length(line) || findtextEx(line, "#", 1, 2))
			continue

		var/imported_ckey = ckey(line)
		if(!imported_ckey)
			continue

		rows_to_insert += list(list(
			"ckey" = imported_ckey,
			"rank" = WHITELIST_RANK_TITLE,
			"admin_ckey" = "LEGACY",
		))

	if(!length(rows_to_insert))
		return 0

	// Existing rows keep their original admin_ckey, an import shouldn't rewrite history.
	SSdbcore.MassInsert(
		format_table_name(WHITELIST_TABLE_NAME),
		rows_to_insert,
		duplicate_key = "\nON DUPLICATE KEY UPDATE ckey = ckey",
		warn = TRUE,
	)

	return length(rows_to_insert)


#undef WHITELIST_TABLE_NAME
#undef WHITELIST_RANK_TITLE
