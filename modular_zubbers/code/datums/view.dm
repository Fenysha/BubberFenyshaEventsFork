/datum/view_data/proc/getScreenSize()
	var/pref_value = chief.prefs.read_preference(/datum/preference/choiced/widescreen)
	if(pref_value)
		// FENYSHA EDIT ADDITION BEGIN - TRANSPARENT_CHAT - take back the width the docked pane used
		if(chief.prefs.read_preference(/datum/preference/choiced/tgpanel_layout) != TGPANEL_PANEL)
			return widen_viewport_for_onmap(pref_value)
		// FENYSHA EDIT ADDITION END
		return pref_value
	return SQUARE_VIEWPORT_SIZE
