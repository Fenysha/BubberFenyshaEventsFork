// Buttons live here because get_title_html() is overridden in custom_title; the hrefs are handled in
// modular_skyrat/modules/title_screen/code/new_player.dm, which already defines /mob/dead/new_player/Topic().

/// The title screen bakes the character name and antag toggle into its HTML, so both are stale after an import.
/// Targeted updates rather than update_title_screen(), which redraws the whole browser.
/datum/preferences/proc/refresh_lobby_after_import()
	var/mob/dead/new_player/lobby_mob = parent?.mob
	if(!istype(lobby_mob) || !lobby_mob.title_screen_is_ready)
		return

	SStitle.update_character_name(lobby_mob, read_preference(/datum/preference/name/real_name))
	parent << output(read_preference(/datum/preference/toggle/be_antag), "title_browser:toggle_antag")

/// Gated per direction, since a server may allow one and not the other.
/mob/dead/new_player/proc/preferences_file_buttons()
	var/dat = ""
	if(!CONFIG_GET(flag/forbid_preferences_export))
		dat += {"<a class="menu_button" href='byond://?src=[text_ref(src)];export_preferences=1'>EXPORT PREFERENCES</a>"}
	if(!CONFIG_GET(flag/forbid_preferences_import))
		dat += {"<a class="menu_button" href='byond://?src=[text_ref(src)];import_preferences=1'>IMPORT PREFERENCES</a>"}
	return dat
