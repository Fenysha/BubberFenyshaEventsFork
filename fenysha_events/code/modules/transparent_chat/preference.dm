/datum/preference/choiced/tgpanel_layout
	category = PREFERENCE_CATEGORY_GAME_PREFERENCES
	savefile_key = "tgpanel_layout"
	savefile_identifier = PREFERENCE_PLAYER

/datum/preference/choiced/tgpanel_layout/init_possible_values()
	return list(
		TGPANEL_ONMAP,
		TGPANEL_PANEL,
		TGPANEL_WINDOW,
	)

/datum/preference/choiced/tgpanel_layout/create_default_value()
	return TGPANEL_ONMAP

/datum/preference/choiced/tgpanel_layout/compile_constant_data()
	var/list/data = ..()

	data[CHOICED_PREFERENCE_DISPLAY_NAMES] = list(
		TGPANEL_ONMAP = "Over the map",
		TGPANEL_PANEL = "Docked panel",
		TGPANEL_WINDOW = "Separate window",
	)

	return data

/datum/preference/choiced/tgpanel_layout/apply_to_client_updated(client/updated, value)
	if(updated.tgui_panel && updated.tgui_panel.current_layout != value)
		updated.tgui_panel.create_browser(value)
