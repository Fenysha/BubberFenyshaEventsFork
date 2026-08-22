/// Admin verbs for the database-backed whitelist, see `whitelist_db.dm`.
/// All of them are hidden unless the server actually runs a whitelist.

ADMIN_VERB(whitelist_add_ckey, R_BAN, "Whitelist CKey", "Adds a ckey to the server whitelist.", ADMIN_CATEGORY_MAIN)
	var/input_ckey = tgui_input_text(user, "CKey to add to the whitelist:", "Whitelist")
	var/target_ckey = ckey(input_ckey)
	if(!target_ckey)
		return

	if(!SSwhitelist.add_ckey(user, target_ckey))
		return

	message_admins("[target_ckey] has been whitelisted by [key_name(user)]")
	log_admin("[target_ckey] has been whitelisted by [key_name(user)]")

ADMIN_VERB_CUSTOM_EXIST_CHECK(whitelist_add_ckey)
	return CONFIG_GET(flag/usewhitelist)


ADMIN_VERB(whitelist_remove_ckey, R_BAN, "Unwhitelist CKey", "Removes a ckey from the server whitelist.", ADMIN_CATEGORY_MAIN)
	var/input_ckey = tgui_input_text(user, "CKey to remove from the whitelist:", "Whitelist")
	var/target_ckey = ckey(input_ckey)
	if(!target_ckey)
		return

	if(!SSwhitelist.remove_ckey(user, target_ckey))
		return

	message_admins("[target_ckey] has been removed from the whitelist by [key_name(user)]")
	log_admin("[target_ckey] has been removed from the whitelist by [key_name(user)]")

ADMIN_VERB_CUSTOM_EXIST_CHECK(whitelist_remove_ckey)
	return CONFIG_GET(flag/usewhitelist)


ADMIN_VERB(whitelist_show, R_BAN, "Show Whitelist", "Lists every ckey currently on the server whitelist.", ADMIN_CATEGORY_MAIN)
	var/list/whitelisted = sort_list(GLOB.whitelist?.Copy() || list())
	var/source = SSwhitelist.loaded ? "the database" : "whitelist.txt"
	to_chat(user, span_notice("<b>[length(whitelisted)] ckeys whitelisted, loaded from [source]:</b><br>[length(whitelisted) ? jointext(whitelisted, ", ") : "(empty)"]"))

ADMIN_VERB_CUSTOM_EXIST_CHECK(whitelist_show)
	return CONFIG_GET(flag/usewhitelist)


ADMIN_VERB(whitelist_reload, R_SERVER, "Reload Whitelist", "Re-reads the whitelist out of the database.", ADMIN_CATEGORY_SERVER)
	if(!SSwhitelist.load_whitelist_from_db())
		to_chat(user, span_warning("Failed to reload the whitelist from the database."))
		return

	message_admins("[key_name(user)] has reloaded the whitelist from the database ([length(GLOB.whitelist)] ckeys).")
	log_admin("[key_name(user)] has reloaded the whitelist from the database ([length(GLOB.whitelist)] ckeys).")

ADMIN_VERB_CUSTOM_EXIST_CHECK(whitelist_reload)
	return CONFIG_GET(flag/usewhitelist)


ADMIN_VERB(whitelist_import_legacy, R_SERVER, "Import Whitelist File", "Copies whitelist.txt into the database. Might be slow!", ADMIN_CATEGORY_SERVER)
	if(tgui_alert(user, "Copy every ckey in whitelist.txt into the database?", "Import Whitelist", list("Yes", "No")) != "Yes")
		return

	var/imported = SSwhitelist.import_legacy_file()
	if(isnull(imported))
		to_chat(user, span_warning("Failed to import the whitelist file, is the database connected?"))
		return

	SSwhitelist.load_whitelist_from_db()
	message_admins("[key_name(user)] has imported [imported] ckeys from whitelist.txt into the database.")
	log_admin("[key_name(user)] has imported [imported] ckeys from whitelist.txt into the database.")

ADMIN_VERB_CUSTOM_EXIST_CHECK(whitelist_import_legacy)
	return CONFIG_GET(flag/usewhitelist)
