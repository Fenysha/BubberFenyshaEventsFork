/// Order the lobby button cycles through. Drives both the DM side and the JS label array, so the
/// two cannot drift apart.
GLOBAL_LIST_INIT(autotranslate_lobby_cycle, list(
	AUTOTRANSLATE_PREF_OFF,
	AUTOTRANSLATE_PREF_ENGLISH,
	AUTOTRANSLATE_PREF_RUSSIAN,
))

/// Lobby button label for one setting, styled like the READY and BE ANTAGONIST toggles beside it.
/proc/autotranslate_lobby_label(pref_value)
	switch(pref_value)
		if(AUTOTRANSLATE_PREF_ENGLISH)
			return "<span class='checked'>☑</span> AUTO-TRANSLATE: EN"
		if(AUTOTRANSLATE_PREF_RUSSIAN)
			return "<span class='checked'>☑</span> AUTO-TRANSLATE: RU"
	return "<span class='unchecked'>☒</span> AUTO-TRANSLATE: OFF"

/// Zero-based position in the cycle, for the JS label array. Unset or stale values land on Off.
/proc/autotranslate_lobby_index(pref_value)
	return max(GLOB.autotranslate_lobby_cycle.Find(pref_value) - 1, 0)

/// Advances the lobby toggle one step: Off -> English -> Russian -> Off.
/mob/dead/new_player/proc/cycle_autotranslate_preference()
	var/datum/preferences/preferences = client?.prefs
	if(!preferences)
		return
	var/list/cycle = GLOB.autotranslate_lobby_cycle
	// Find() returns 0 when the stored value is missing or no longer valid, which wraps to Off.
	var/index = cycle.Find(preferences.read_preference(/datum/preference/choiced/autotranslate_target))
	var/next = cycle[(index % length(cycle)) + 1]
	preferences.write_preference(GLOB.preference_entries[/datum/preference/choiced/autotranslate_target], next)
	client << output("[autotranslate_lobby_index(next)]", "title_browser:toggle_translate")

/// The labels as a JS array body, in cycle order, for the lobby's inline script.
/proc/autotranslate_lobby_label_array()
	var/list/quoted = list()
	for(var/option in GLOB.autotranslate_lobby_cycle)
		quoted += "\"[autotranslate_lobby_label(option)]\""
	return quoted.Join(", ")
