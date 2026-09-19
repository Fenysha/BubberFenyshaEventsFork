/// Feeds the chat panel's verb search and pinned verb chips. The panel does the searching,
/// pinning and running (verbs run client-side through Byond.command, as the statpanel does),
/// so all DM has to do is keep it told which verbs exist and what the status tab says.

#define COMSIG_KB_CLIENT_VERBSEARCH_DOWN "keybinding_client_verbsearch_down"
#define VERB_SEARCH_REFRESH_DELAY (1 SECONDS)

/datum/tgui_panel
	/// Whether we're listening for verbs being added to or removed from the client
	var/verb_search_listening = FALSE

/datum/tgui_panel/proc/on_verb_search_message(type)
	switch(type)
		if("verbsearch/request")
			if(!verb_search_listening)
				verb_search_listening = TRUE
				RegisterSignals(client, list(COMSIG_CLIENT_VERB_ADDED, COMSIG_CLIENT_VERB_REMOVED), PROC_REF(queue_verb_search_refresh))
			send_verb_search()
			send_verb_search_status()
		if("verbsearch/request_status")
			send_verb_search_status()
	return TRUE

/// Verbs tend to arrive in bursts (equipping, changing mobs), so batch them into one send.
/datum/tgui_panel/proc/queue_verb_search_refresh()
	SIGNAL_HANDLER
	addtimer(CALLBACK(src, PROC_REF(send_verb_search)), VERB_SEARCH_REFRESH_DELAY, TIMER_UNIQUE)

/// Same verbs the statpanel shows: visible, categorised, from the client, its mob and what it carries.
/datum/tgui_panel/proc/send_verb_search()
	if(!client)
		return
	var/list/verbs_to_process = client.verbs.Copy()
	var/mob/user = client.mob
	if(user)
		verbs_to_process += user.verbs
		for(var/atom/movable/thing as anything in user.contents)
			verbs_to_process += thing.verbs

	var/list/seen = list()
	var/list/entries = list()
	for(var/procpath/verb_path as anything in verbs_to_process)
		if(!verb_path || verb_path.hidden || !istext(verb_path.category))
			continue
		// Several held items can share a verb name; one entry runs the same command
		if(seen[verb_path.name])
			continue
		seen[verb_path.name] = TRUE
		entries += list(list(
			"name" = verb_path.name,
			"category" = verb_path.category,
			"desc" = verb_path.desc,
		))
	window.send_message("verbsearch/verbs", list("verbs" = entries))

/// The statpanel Status tab as plain lines, shown along the top of the search.
/datum/tgui_panel/proc/send_verb_search_status()
	if(!client)
		return
	var/list/lines = list()
	for(var/entry in SSstatpanels.global_data)
		if(istext(entry))
			lines += entry
		else if(islist(entry))
			var/list/parts = entry
			// same_line entries are links tacked onto the previous line
			if(length(parts) && istext(parts[1]) && parts[1] != "same_line")
				lines += parts[1]
	var/list/mob_items = client.mob?.get_status_tab_items()
	for(var/entry in mob_items)
		if(istext(entry) && length(entry))
			lines += entry
	window.send_message("verbsearch/status", list("lines" = lines))

/datum/tgui_panel/proc/open_verb_search()
	// The docked layouts keep the statpanel, so the search is overlay-only
	if(current_layout != TGPANEL_ONMAP)
		return
	send_verb_search_status()
	window.send_message("verbsearch/open")
	winset(client, "browseroutput", "focus=true")

/datum/keybinding/client/verb_search
	hotkey_keys = list("CtrlK")
	name = "verb_search"
	full_name = "Search Verbs"
	description = "Search every verb you can use, and pin favourites above the chat."
	keybind_signal = COMSIG_KB_CLIENT_VERBSEARCH_DOWN

/datum/keybinding/client/verb_search/down(client/user, turf/target, mousepos_x, mousepos_y)
	. = ..()
	if(.)
		return
	user.tgui_panel?.open_verb_search()
	return TRUE

#undef COMSIG_KB_CLIENT_VERBSEARCH_DOWN
#undef VERB_SEARCH_REFRESH_DELAY
