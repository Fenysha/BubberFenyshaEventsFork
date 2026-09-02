/proc/pref_check_emote(anything)
	return FALSE


/datum/preference
	/// If false then the preference is disabled and will not be shown in the preferences menu.
	var/preference_enabled = TRUE

/// Returns TRUE if the preference is enabled and should be shown in the preferences menu, FALSE otherwise.
/datum/preference/proc/is_preference_enabled()
	return preference_enabled

/datum/preferences/read_preference(preference_type)
	var/datum/preference/preference_entry = GLOB.preference_entries[preference_type]

	if (!preference_entry)
		return FALSE

	if (preference_entry && !preference_entry.is_preference_enabled())
		return FALSE

	return ..()

/datum/preferences/write_preference(datum/preference/preference, preference_value)
	if (preference && !preference.is_preference_enabled())
		return FALSE
	return ..()

/datum/preferences/update_preference(datum/preference/preference, preference_value)
	if (preference && !preference.is_preference_enabled())
		return FALSE
	return ..()


#if defined(NOERP)

/datum/preference/toggle/show_in_directory
	preference_enabled = FALSE


/datum/preference/text/character_ad
	preference_enabled = FALSE


/datum/preference/choiced/attraction
	preference_enabled = FALSE


/datum/preference/choiced/display_gender
	preference_enabled = FALSE


/datum/preference/choiced/emote_length
	preference_enabled = FALSE

/datum/preference/choiced/approach_pref
	preference_enabled = FALSE

/datum/preference/choiced/directory_character_prefs
	preference_enabled = FALSE

/datum/preference/choiced/directory_character_prefs/furry_pref
	preference_enabled = FALSE

/datum/preference/choiced/directory_character_prefs/scalie_pref
	preference_enabled = FALSE

/datum/preference/choiced/directory_character_prefs/other_pref
	preference_enabled = FALSE

/datum/preference/choiced/directory_character_prefs/demihuman_pref
	preference_enabled = FALSE

/datum/preference/choiced/directory_character_prefs/human_pref
	preference_enabled = FALSE

/datum/preference/text/flavor_text_nsfw
	preference_enabled = FALSE

/datum/preference/text/low_arousal
	preference_enabled = FALSE

/datum/preference/text/medium_arousal
	preference_enabled = FALSE

/datum/preference/text/high_arousal
	preference_enabled = FALSE

/datum/preference/text/flavor_text_nsfw/silicon
	preference_enabled = FALSE

/datum/preference/choiced/show_nsfw_flavor_text
	preference_enabled = FALSE

/datum/preference/text/headshot/nsfw
	preference_enabled = FALSE

/datum/preference/text/headshot/silicon/nsfw
	preference_enabled = FALSE

/datum/preference/text/headshot/art_ref
	preference_enabled = FALSE

/datum/preference/toggle/art_ref_nsfw
	preference_enabled = FALSE

#endif
