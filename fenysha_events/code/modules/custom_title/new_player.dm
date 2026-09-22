/// BYOND timestamp corresponding to deadline (Jun. 16, 2025)
#define DEADLINE_TIMESTAMP 8033472000

/mob/dead/new_player
	/// Title screen is ready to receive signals
	var/title_screen_is_ready = FALSE
	/// Whether the player (if unvetted) has acknowledged the deadline warning
	var/unvetted_notified = FALSE

/**
 * Check player vetting status and if necessary warn about upcoming deadline
 *
 * Returns FALSE if unvetted and deadline has passed, TRUE otherwise
 */
/mob/dead/new_player/proc/trigger_unvetted_warning()
	if(!CONFIG_GET(flag/check_vetted))
		unvetted_notified = TRUE
		return TRUE
	if(!SSplayer_ranks.initialized)
		return TRUE
	if(SSplayer_ranks.is_vetted(client, admin_bypass = FALSE))
		unvetted_notified = TRUE
		return TRUE

	// Time's up
	if(DEADLINE_TIMESTAMP - world.realtime <= 0)
		tgui_alert(
			src,
			"Unvetted players are no longer allowed to join or observe rounds, please visit #get-vetted in the Discord to submit a vetting application",
			"You are unvetted!",
			timeout = 10 SECONDS,
		)
		return FALSE

	var/remaining_time = round((DEADLINE_TIMESTAMP - world.realtime) / (1 DAYS), 1)
	tgui_deadline_alert(
		src,
		"Unvetted players will lose the ability to join or observe rounds in [remaining_time] day\s!",
		"Get vetted by [time2text(DEADLINE_TIMESTAMP, "Month DD YYYY")]!",
		days_remaining = remaining_time,
		timeout = 10 SECONDS,
	)
	unvetted_notified = TRUE
	return TRUE

/mob/dead/new_player/Topic(href, href_list)
	if(src != usr)
		return

	if(SStitle.active_lobby?.Topic(href, href_list, src))
		return

	. = ..()

/mob/dead/new_player/Login()
	. = ..()
	show_title_screen()

/**
 * Shows the titlescreen to a new player.
 */
/mob/dead/new_player/proc/show_title_screen()
	SStitle.active_lobby?.show(src)

/**
 * Hard updates the title screen HTML, it causes visual glitches if used.
 */
/mob/dead/new_player/proc/update_title_screen()
	SStitle.active_lobby?.update(src)

/**
 * Removes the titlescreen entirely from a mob.
 */
/mob/dead/new_player/proc/hide_title_screen()
	SStitle.active_lobby?.hide(src)

/mob/dead/new_player/proc/play_lobby_button_sound()
	SEND_SOUND(src, sound('modular_skyrat/master_files/sound/effects/save.ogg'))

/**
 * Allows the player to select a server to join from any loaded servers.
 */
/mob/dead/new_player/proc/server_swap()
	var/list/servers = CONFIG_GET(keyed_list/cross_server)
	if(LAZYLEN(servers) == 1)
		var/server_name = servers[1]
		var/server_ip = servers[server_name]
		var/confirm = tgui_alert(src, "Are you sure you want to swap to [server_name] ([server_ip])?", "Swapping server!", list("Connect me!", "Stay here"))
		if(confirm == "Connect me!")
			to_chat_immediate(src, "So long, spaceman.")
			client << link(server_ip)
		return
	var/server_name = tgui_input_list(src, "Please select the server you wish to swap to:", "Swap servers!", servers)
	if(!server_name)
		return
	var/server_ip = servers[server_name]
	var/confirm = tgui_alert(src, "Are you sure you want to swap to [server_name] ([server_ip])?", "Swapping server!", list("Connect me!", "Stay here!"))
	if(confirm == "Connect me!")
		to_chat_immediate(src, "So long, spaceman.")
		src.client << link(server_ip)

/**
 * Shows currently available job traits
 */
/mob/dead/new_player/proc/show_job_traits()
	if (!client || client.interviewee)
		return
	if(!length(GLOB.lobby_station_traits))
		to_chat(src, span_warning("There are currently no job traits available!"))
		return
	var/list/available_lobby_station_traits = list()
	for (var/datum/station_trait/trait as anything in GLOB.lobby_station_traits)
		if (!trait.can_display_lobby_button(client))
			continue
		available_lobby_station_traits += trait

	if(!LAZYLEN(available_lobby_station_traits))
		to_chat(src, span_warning("There are currently no job traits available!"))
		return

	var/datum/station_trait/clicked_trait = tgui_input_list(src, "Select a job trait to sign up for:", "Job Traits", available_lobby_station_traits)

	if(!clicked_trait)
		return

	clicked_trait.on_lobby_button_click(src)

/**
 * Shows the player a list of current polls, if any.
 */
/mob/dead/new_player/proc/playerpolls()
	if(!usr || !client)
		return

	var/output
	if (!SSdbcore.Connect())
		return
	var/isadmin = FALSE
	if(client?.holder)
		isadmin = TRUE
	var/datum/db_query/query_get_new_polls = SSdbcore.NewQuery({"
		SELECT id FROM [format_table_name("poll_question")]
		WHERE (adminonly = 0 OR :isadmin = 1)
		AND Now() BETWEEN starttime AND endtime
		AND deleted = 0
		AND id NOT IN (
			SELECT pollid FROM [format_table_name("poll_vote")]
			WHERE ckey = :ckey
			AND deleted = 0
		)
		AND id NOT IN (
			SELECT pollid FROM [format_table_name("poll_textreply")]
			WHERE ckey = :ckey
			AND deleted = 0
		)
	"}, list("isadmin" = isadmin, "ckey" = ckey))

	if(!query_get_new_polls.Execute())
		qdel(query_get_new_polls)
		return
	if(query_get_new_polls.NextRow())
		output +={"<a class="menu_button menu_newpoll" href='byond://?src=[text_ref(src)];polls_menu=1'>POLLS (NEW)</a>"}
	else
		output +={"<a class="menu_button" href='byond://?src=[text_ref(src)];polls_menu=1'>POLLS</a>"}
	qdel(query_get_new_polls)
	if(QDELETED(src))
		return
	return output

#undef DEADLINE_TIMESTAMP


/datum/asset/simple/lobby
	assets = list(
		"OCRAExtended.ttf" = 'fenysha_events/html/OCRAEXT.TTF',
	)


