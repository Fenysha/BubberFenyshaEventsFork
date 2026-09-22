GLOBAL_LIST_EMPTY(startup_messages)

SUBSYSTEM_DEF(title)
	name = "Title Screen"
	ss_flags = SS_NO_FIRE
	init_stage = INITSTAGE_EARLY

	var/file_path
	var/icon/startup_splash

	/// The current title screen being displayed
	var/current_title_screen
	/// The current notice text, or null.
	var/current_notice
	/// The preamble html that includes all styling and layout.
	var/title_html
	/// Legacy list (оставляем для совместимости, но приоритет у active_lobby)
	var/list/title_screens = list()

	/// average realtime seconds it takes to load the map we're currently running
	var/average_completion_time = DEFAULT_TITLE_MAP_LOADTIME
	/// a given startup message => average timestamp in realtime seconds
	var/list/startup_message_timings = list()
	/// Raw data to update later
	var/list/progress_json = list()
	/// The reference realtime that we're treating as 0 for this run
	var/progress_reference_time = 0
	/// A list of station traits that have lobby buttons
	var/list/available_lobby_station_traits = list()

	var/datum/lobby/active_lobby

/datum/controller/subsystem/title/Initialize()
	var/dat
	if(!fexists("[global.config.directory]/bubbers/bubbers_title.txt"))
		to_chat(world, span_boldwarning("CRITICAL ERROR: Unable to read bubbers_title.txt, reverting to backup title html, please check your server config and ensure this file exists."))
		dat = DEFAULT_TITLE_HTML
	else
		dat = file2text("[global.config.directory]/bubbers/bubbers_title.txt")

	title_html = dat

	var/list/provisional_title_screens = flist("[global.config.directory]/title_screens/images/")
	var/list/local_title_screens = list()
	var/list/current_map_file = splittext(SSmapping.current_map.map_file, ".")

	for(var/screen in provisional_title_screens)
		var/list/formatted_list = splittext(screen, "+")
		if((LOWER_TEXT(formatted_list[1]) == LOWER_TEXT(current_map_file[1])))
			local_title_screens += screen
			continue

		if(LAZYLEN(formatted_list) > 1 && LOWER_TEXT(formatted_list[1]) == "startup_splash")
			var/file_path = "[global.config.directory]/title_screens/images/[screen]"
			ASSERT(fexists(file_path))
			startup_splash = new(fcopy_rsc(file_path))

	if(local_title_screens.len == 0)
		for(var/screen in provisional_title_screens)
			var/list/formatted_list = splittext(screen, "+")
			if((LAZYLEN(formatted_list) == 1 && (formatted_list[1] != "exclude" && formatted_list[1] != "blank.png" && formatted_list[1] != "startup_splash")))
				local_title_screens += screen

	check_progress_reference_time()
	load_progress_json()

	active_lobby = new /datum/lobby/rimworld()

	apply_lobby_screens()

	return SS_INIT_SUCCESS

/datum/controller/subsystem/title/proc/apply_lobby_screens()
	if(!active_lobby)
		return

	var/loading = active_lobby.get_loading_screen()
	if(loading)
		current_title_screen = loading
		startup_splash = loading

	if(SSticker?.current_state != GAME_STATE_STARTUP)
		var/main_screen = active_lobby.get_title_screen()
		if(main_screen)
			current_title_screen = main_screen

/**
 * Make sure reference time is set up. If not, this is now time 0.
 */
/datum/controller/subsystem/title/proc/check_progress_reference_time()
	if(!progress_reference_time)
		progress_reference_time = world.timeofday

/**
 * Handle and clean up leaving startup
 */
/datum/controller/subsystem/title/proc/check_finish_progress()
	//It's the first time we're firing out of startup -> pregame
	if(progress_json && SSticker.current_state == GAME_STATE_PREGAME)
		save_progress_json()

		// Когда выходим из startup — переключаем на основной экран лобби
		if(active_lobby)
			var/main_screen = active_lobby.get_title_screen()
			if(main_screen)
				current_title_screen = main_screen

/**
 * Load the progress info json and setup that part of the SS.
 */
/datum/controller/subsystem/title/proc/load_progress_json()
	var/json_file = file(TITLE_PROGRESS_CACHE_FILE)
	if(!fexists(json_file))
		return

	progress_json = json_decode(file2text(json_file))

	if(progress_json["_version"] != TITLE_PROGRESS_CACHE_VERSION)
		progress_json.Cut()
		return

	var/list/map_info = progress_json[SSmapping.current_map.map_name]
	if(!islist(map_info))
		return

	average_completion_time = map_info["total"] || DEFAULT_TITLE_MAP_LOADTIME
	startup_message_timings = map_info["messages"] || list()

/datum/controller/subsystem/title/proc/save_progress_json()
	var/json_file = file(TITLE_PROGRESS_CACHE_FILE)
	var/list/map_info = list()

	progress_json["_version"] = TITLE_PROGRESS_CACHE_VERSION

	if(progress_json[SSmapping.current_map.map_name])
		map_info["total"] = 0.75 * average_completion_time + 0.25 * (world.timeofday - progress_reference_time)
	else
		map_info["total"] = world.timeofday - progress_reference_time
	map_info["messages"] = startup_message_timings
	progress_json[SSmapping.current_map.map_name] = map_info

	fdel(json_file)
	WRITE_FILE(json_file, json_encode(progress_json))

	progress_json = null

/datum/controller/subsystem/title/Recover()
	startup_splash = SStitle.startup_splash
	file_path = SStitle.file_path

	current_title_screen = SStitle.current_title_screen
	current_notice = SStitle.current_notice
	title_html = SStitle.title_html
	title_screens = SStitle.title_screens

	average_completion_time = SStitle.average_completion_time
	startup_message_timings = SStitle.startup_message_timings
	progress_json = SStitle.progress_json
	progress_reference_time = SStitle.progress_reference_time

	active_lobby = SStitle.active_lobby

/datum/controller/subsystem/title/proc/set_lobby_type(path)
	if(!ispath(path, /datum/lobby))
		return FALSE

	qdel(active_lobby)
	active_lobby = new path()

	apply_lobby_screens()
	show_title_screen()
	return TRUE

/**
 * Show the title screen to all new players.
 */
/datum/controller/subsystem/title/proc/show_title_screen()
	for(var/mob/dead/new_player/new_player in GLOB.new_player_list)
		INVOKE_ASYNC(new_player, TYPE_PROC_REF(/mob/dead/new_player, show_title_screen))

/**
 * Adds a notice to the main title screen in the form of big red text!
 */
/datum/controller/subsystem/title/proc/set_notice(new_title)
	current_notice = new_title ? sanitize_text(new_title) : null
	show_title_screen()

/datum/controller/subsystem/title/proc/change_title_screen(new_screen)
	if(new_screen)
		current_title_screen = new_screen
	else if(active_lobby)
		if(SSticker?.current_state == GAME_STATE_STARTUP)
			current_title_screen = active_lobby.get_loading_screen()
		else
			current_title_screen = active_lobby.get_title_screen()
	else if(LAZYLEN(title_screens))
		current_title_screen = pick(title_screens)
	else
		current_title_screen = DEFAULT_TITLE_SCREEN_IMAGE

	check_finish_progress()
	show_title_screen()

/**
 * Update a user's character setup name.
 */
/datum/controller/subsystem/title/proc/update_character_name(mob/dead/new_player/user, name)
	if(!(istype(user) && user.title_screen_is_ready))
		return

	user.client << output(name, "title_browser:update_current_character")

/**
 * Adds a startup message to the splashscreen.
 */
/proc/add_startup_message(msg, warning)
	var/static/regex/msg_key_regex = new(@"[0-9.]+( second)?s?!", "ig")

	var/msg_html = {"<p class="terminal_text">[warning ? "☒ " : ""][msg]</p>"}
	var/msg_key = msg_key_regex.Replace(msg, "#")

	GLOB.startup_messages += msg_html

	SStitle.check_progress_reference_time()

	var/old_timing = SStitle.startup_message_timings[msg_key]
	var/new_timing
	if(!old_timing)
		new_timing = world.timeofday - SStitle.progress_reference_time
	else
		new_timing = 0.75 * old_timing + 0.25 * (world.timeofday - SStitle.progress_reference_time)
	SStitle.startup_message_timings[msg_key] = new_timing

	for(var/mob/dead/new_player/new_player in GLOB.new_player_list)
		if(!new_player.title_screen_is_ready)
			continue

		new_player.client << output(msg_html, "title_browser:append_terminal_text")
		new_player.client << output(list2params(list(new_timing, SStitle.average_completion_time)), "title_browser:update_loading_progress")
