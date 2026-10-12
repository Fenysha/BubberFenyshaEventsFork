/// Turns the say popup into a verb input with autocomplete; see tartarus-say.
/datum/preference/toggle/say_verb_input
	category = PREFERENCE_CATEGORY_GAME_PREFERENCES
	savefile_key = "say_verb_input"
	savefile_identifier = PREFERENCE_PLAYER
	default_value = FALSE

/datum/preference/toggle/say_verb_input/apply_to_client(client/client)
	client.tgui_say?.load()

/datum/tgui_say/proc/verb_input_enabled()
	return client?.prefs?.read_preference(/datum/preference/toggle/say_verb_input)

/datum/tgui_say/load()
	. = ..()
	window.send_message("verbinput", list("enabled" = verb_input_enabled()))

/datum/tgui_say/open(payload)
	. = ..()
	// Typing a verb is not speech
	if(verb_input_enabled())
		stop_thinking()

/datum/tgui_say/on_message(type, payload)
	switch(type)
		if("verbs/request")
			send_verbs()
			return TRUE
		if("verbs/request_targets")
			send_targets(payload)
			return TRUE
		if("verbs/request_typepaths")
			send_typepaths(payload)
			return TRUE
		if("verbs/invoke")
			return client?.tgui_panel?.on_message(type, payload)
	return ..()

/// Every verb the player can use, as the command bar receives them.
/datum/tgui_say/proc/send_verbs()
	if(!client)
		return

	var/list/entries = list()
	var/list/seen = list()
	var/list/sources = client.verbs.Copy()
	if(client.mob)
		sources += client.mob.verbs
		for(var/atom/movable/thing as anything in client.mob.contents)
			sources += thing.verbs

	for(var/procpath/verb_path as anything in sources)
		// Say, OOC and the ghost verbs carry no category
		if(!verb_path || verb_path.hidden || !verb_path.name || seen[verb_path.name])
			continue
		seen[verb_path.name] = TRUE

		var/list/entry = SSverbs.serialize_verb(verb_path)
		entry["metadata"] = !isnull(SSverbs.verbs_by_verb_path[verb_path]) || !isnull(SSadmin_verbs.admin_verbs_by_verb_path[verb_path])
		entries += list(entry)

	window.send_message("verbs", list("verbs" = entries))

/// What an entity argument can be filled with.
/datum/tgui_say/proc/send_targets(list/payload)
	var/verb_path = text2path(payload["verb_type"])
	if(!verb_path || !client)
		return
	if(!(verb_path in client.verbs) && !(client.mob && (verb_path in client.mob.verbs)))
		return

	var/list/arg_list
	var/datum/verb_metadata/meta = SSverbs.verbs_by_verb_path[verb_path]
	if(meta)
		arg_list = meta.arguments
	else
		var/datum/admin_verb/admin_meta = SSadmin_verbs.admin_verbs_by_verb_path[verb_path]
		if(admin_meta)
			arg_list = admin_meta.arguments
	if(!length(arg_list))
		return

	var/datum/verb_arg_metadata/entity_arg
	for(var/datum/verb_arg_metadata/arg in arg_list)
		if(arg.arg_type & VERB_ARG_TYPE_ENTITY)
			entity_arg = arg
			break
	if(!entity_arg)
		return

	var/list/target_data = list()
	for(var/atom/target in entity_arg.get_targets(client))
		target_data += list(list("name" = "[target]", "ref" = REF(target)))

	window.send_message("verbs/targets", list("targets" = target_data))

/// The direct children of a typepath, for typepath arguments.
/datum/tgui_say/proc/send_typepaths(list/payload)
	var/parent_text = payload["parent"]
	var/browse_type = text2path(parent_text)
	if(isnull(browse_type))
		browse_type = /datum

	var/list/children = list()
	for(var/child_type in typesof(browse_type))
		if(child_type == browse_type)
			continue
		var/child_text = "[child_type]"
		var/parent_len = length(parent_text || "/datum")
		if(findtext(copytext(child_text, parent_len + 1), "/", 2))
			continue
		children += child_text

	window.send_message("verbs/typepaths", list("parent" = parent_text, "paths" = children))
