/*
*	The lobby half of the preferences import/export.
*
*	get_title_html() is overridden in fenysha_events/code/modules/custom_title, so the buttons live here and both
*	title screen variants just call preferences_file_buttons().
*
*	The matching hrefs are handled in modular_skyrat/modules/title_screen/code/new_player.dm, because
*	/mob/dead/new_player/Topic() is already defined there and DM only allows one definition per type.
*/

/**
 * Pushes what an import just changed back into the lobby.
 *
 * The title screen bakes the character name and the antag toggle into its HTML when it is built, so after an import
 * replaces the whole save they are both stale. This runs for the OOC verb as well as the lobby button, since the
 * player can be sat in the lobby either way.
 *
 * Uses the same targeted updates the preferences menu does rather than update_title_screen(), which redraws the whole
 * browser and is documented there as causing visual glitches.
 */
/datum/preferences/proc/refresh_lobby_after_import()
	var/mob/dead/new_player/lobby_mob = parent?.mob
	if(!istype(lobby_mob) || !lobby_mob.title_screen_is_ready)
		return

	SStitle.update_character_name(lobby_mob, read_preference(/datum/preference/name/real_name))
	parent << output(read_preference(/datum/preference/toggle/be_antag), "title_browser:toggle_antag")

/// The lobby buttons for getting a preferences file out of, or back into, this server.
/// Each is gated on its own config flag, since a server may well allow one direction and not the other.
/mob/dead/new_player/proc/preferences_file_buttons()
	var/dat = ""
	if(!CONFIG_GET(flag/forbid_preferences_export))
		dat += {"<a class="menu_button" href='byond://?src=[text_ref(src)];export_preferences=1'>EXPORT PREFERENCES</a>"}
	if(!CONFIG_GET(flag/forbid_preferences_import))
		dat += {"<a class="menu_button" href='byond://?src=[text_ref(src)];import_preferences=1'>IMPORT PREFERENCES</a>"}
	return dat
