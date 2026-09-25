#define MAX_STARTUP_MESSAGES 1


/datum/lobby
	var/name = "Standard Lobby"
	var/max_startup_messages = MAX_STARTUP_MESSAGES

	var/list/loading_screens = list()
	var/list/title_screens = list()

/datum/lobby/proc/get_loading_screen()
	if(length(loading_screens))
		return pick(loading_screens)
	return DEFAULT_TITLE_LOADING_SCREEN


/datum/lobby/proc/get_title_screen()
	if(length(title_screens))
		return pick(title_screens)
	return DEFAULT_TITLE_SCREEN_IMAGE

/datum/lobby/proc/get_html(mob/dead/new_player/user)
	var/dat = CUSTOM_TITLE_HTML

	if(SSticker.current_state == GAME_STATE_STARTUP)
		dat += get_loading_screen_html(user)
	else
		dat += get_main_html(user)

	if(!user.title_screen_is_ready)
		dat += {"
			<script>
				location.href = "byond://?src=[text_ref(user)];title_is_ready=1";
			</script>
		"}

	dat += lobby_key_forwarding_script()
	dat += "</body></html>"
	return dat


/datum/lobby/proc/get_loading_screen_html(mob/dead/new_player/user)
	var/dat = {"<img src="loading_screen.gif" class="bg" id="bg_layer" alt="">"}

	dat += {"
	<div id="parallax_loader" style="position:absolute; bottom:40px; right:40px; white-space:nowrap; text-align:right; z-index:2;">
		<div id="terminal" style="display:inline-block; vertical-align:middle; margin-right:15px; max-width:60vw; overflow:hidden; text-overflow:ellipsis; text-align:right; font-family:'Fixedsys', monospace; font-size:1.8vmin; color:#f0d30b;"></div>
		<svg width="60" height="60" style="display:inline-block; vertical-align:middle; transform:rotate(-90deg); overflow:visible;">
			<circle stroke="rgba(240, 211, 11, 1)" stroke-width="4" fill="transparent" r="24" cx="30" cy="30"/>
			<circle id="progress_circle" stroke="#a19020" stroke-width="4" fill="transparent" r="24" cx="30" cy="30" style="transition:stroke-dashoffset 0.15s ease-out;"/>
		</svg>
	</div>
	"}

	dat += {"
	<script language="JavaScript">
		var terminal = document.getElementById("terminal");
		var terminal_lines = \[
	"}

	for(var/message in GLOB.startup_messages)
		dat += {""[replacetext(message, "\"", "\\\"")]","}

	dat += {"
		\];

		function append_terminal_text(text) {
			if(text) {
				terminal_lines.push(text);
			}
			while(terminal_lines.length > [max_startup_messages]) {
				terminal_lines.shift();
			}
			var last_msg = terminal_lines.slice(-1);
			terminal.innerHTML = last_msg.length ? last_msg.pop() : '';
		}

		append_terminal_text();

		var circle = document.getElementById("progress_circle");
		var radius = circle.r.baseVal.value;
		var circumference = 2 * Math.PI * radius;
		circle.style.strokeDasharray = circumference + ' ' + circumference;
		circle.style.strokeDashoffset = circumference;

		function setProgress(percent) {
			var offset = circumference - (percent / 100 * circumference);
			circle.style.strokeDashoffset = offset;
		}

		var previous_tick = new Date().getTime();
		var progress_current_time = [world.timeofday - SStitle.progress_reference_time];
		var progress_completion_time = [SStitle.average_completion_time];
		var progress_current_position = 0;

		setInterval(function() {
			if(progress_current_time < progress_completion_time) {
				var current_tick = new Date().getTime();
				progress_current_time += (current_tick - previous_tick) / 100;
				previous_tick = current_tick;
			}

			progress_current_position = Math.min(Math.max(progress_current_time / progress_completion_time * 100, progress_current_position), 100);
			setProgress(progress_current_position);
		}, 16.666666667);

		function update_loading_progress(current_time, total_time) {
			progress_current_time = parseFloat(current_time);
			progress_completion_time = parseFloat(total_time);
		}

		function update_current_character() {}
	</script>
	"}

	return dat

/datum/lobby/proc/get_main_html(mob/dead/new_player/user)
	. = {"<img src="loading_screen.gif" class="bg" id="bg_layer" alt="">"}

	if(SStitle.current_notice)
		. += {"
		<div class="container_notice">
			<p class="menu_notice">[SStitle.current_notice]</p>
		</div>
		"}

	. += {"<div class="container_nav" id="parallax_nav">"}

	if(!SSticker || SSticker.current_state <= GAME_STATE_PREGAME)
		. += {"<a id="ready" class="menu_button" href='byond://?src=[text_ref(user)];toggle_ready=1'>[user.ready == PLAYER_READY_TO_PLAY ? "<span class='checked'>☑</span> READY" : "<span class='unchecked'>☒</span> READY"]</a>"}
	else
		. += {"
			<a class="menu_button" href='byond://?src=[text_ref(user)];late_join=1'>JOIN GAME</a>
			<a class="menu_button" href='byond://?src=[text_ref(user)];view_manifest=1'>CREW MANIFEST</a>
		"}

	. += {"<a class="menu_button" href='byond://?src=[text_ref(user)];observe=1'>OBSERVE</a>"}

	. += {"
		<hr>
		<a class="menu_button" href='byond://?src=[text_ref(user)];character_setup=1'>SETUP CHARACTER</a>
		<a class="menu_button" href='byond://?src=[text_ref(user)];rimworld_character_setup=1'>PREPARE COLONIST</a>
		<a class="menu_button" href='byond://?src=[text_ref(user)];game_options=1'>GAME OPTIONS</a>
		<a id="be_antag" class="menu_button" href='byond://?src=[text_ref(user)];toggle_antag=1'>[user.client.prefs.read_preference(/datum/preference/toggle/be_antag) ? "<span class='checked'>☑</span> BE ANTAGONIST" : "<span class='unchecked'>☒</span> BE ANTAGONIST"]</a>
		<a id="translate" class="menu_button" href='byond://?src=[text_ref(user)];toggle_translate=1'>[autotranslate_lobby_label(user.client.prefs.read_preference(/datum/preference/choiced/autotranslate_target))]</a>
	"}

	. += user.preferences_file_buttons(user)

	if(length(GLOB.lobby_station_traits))
		. += {"<a class="menu_button" href='byond://?src=[text_ref(user)];job_traits=1'>JOB TRAITS</a>"}

	if(!is_guest_key(user.key))
		. += user.playerpolls()

	. += {"
		<div class="character_display">
			CURRENT CHARACTER:<br>
			<span id="character_slot" class="character_name">[uppertext(user.client.prefs.read_preference(/datum/preference/name/real_name))]</span>
		</div>
	"}

	. += "</div>"

	. += {"
	<script language="JavaScript">
		const PLAYER_READY_TO_PLAY = "[PLAYER_READY_TO_PLAY]"
		const PLAYER_NOT_READY = "[PLAYER_NOT_READY]"
		var ready_mark = document.getElementById("ready");
		function toggle_ready(setReady) {
			if(setReady === PLAYER_READY_TO_PLAY) {
				ready_mark.innerHTML = "<span class='checked'>☑</span> READY"
			} else {
				ready_mark.innerHTML = "<span class='unchecked'>☒</span> READY"
			}
		}

		var antag_int = 0;
		var antag_mark = document.getElementById("be_antag");
		var antag_marks = \[ "<span class='unchecked'>☒</span> BE ANTAGONIST", "<span class='checked'>☑</span> BE ANTAGONIST" \];
		function toggle_antag(setAntag) {
			if(setAntag) {
				antag_int = setAntag;
				antag_mark.innerHTML = antag_marks\[antag_int\];
			} else {
				antag_int++;
				if (antag_int === antag_marks.length)
					antag_int = 0;
				antag_mark.innerHTML = antag_marks\[antag_int\];
			}
		}

		var translate_int = [autotranslate_lobby_index(user.client.prefs.read_preference(/datum/preference/choiced/autotranslate_target))];
		var translate_mark = document.getElementById("translate");
		var translate_marks = \[ [autotranslate_lobby_label_array()] \];
		function toggle_translate(state) {
			translate_int = Number(state);
			if(isNaN(translate_int) || translate_int < 0 || translate_int >= translate_marks.length)
				translate_int = 0;
			translate_mark.innerHTML = translate_marks\[translate_int\];
		}

		var character_name_slot = document.getElementById("character_slot");
		function update_current_character(name) {
			if (character_name_slot) {
				character_name_slot.textContent = name.toUpperCase();
			}
		}

		document.addEventListener("mousemove", function(e) {
			var cx = window.innerWidth / 2;
			var cy = window.innerHeight / 2;
			var dx = (e.clientX - cx) / cx;
			var dy = (e.clientY - cy) / cy;

			var nav = document.getElementById("parallax_nav");
			var loader = document.getElementById("parallax_loader");
			var bg = document.getElementById("bg_layer");

			if (nav) {
				nav.style.transform = "translate(" + (dx * 15) + "px, calc(-50% + " + (dy * 15) + "px))";
			}
			if (loader) {
				loader.style.transform = "translate(" + (dx * 15) + "px, " + (dy * 15) + "px)";
			}
			if (bg) {
				bg.style.transform = "translate(calc(-50% + " + (-dx * 10) + "px), calc(-50% + " + (-dy * 10) + "px))";
			}
		});
	</script>
	"}


/datum/lobby/proc/get_default_title_html(mob/dead/new_player/user)
	var/dat = SStitle.title_html

	if(SSticker.current_state == GAME_STATE_STARTUP)
		dat += get_loading_screen_html(user)
	else
		dat += {"<img src="loading_screen.gif" class="bg" alt="">"}

		if(SStitle.current_notice)
			dat += {"
			<div class="container_notice">
				<p class="menu_notice">[SStitle.current_notice]</p>
			</div>
			"}

		dat += {"<div class="container_nav">"}

		if(!SSticker || SSticker.current_state <= GAME_STATE_PREGAME)
			dat += {"<a id="ready" class="menu_button" href='byond://?src=[text_ref(user)];toggle_ready=1'>[user.ready == PLAYER_READY_TO_PLAY ? "<span class='checked'>☑</span> READY" : "<span class='unchecked'>☒</span> READY"]</a>"}
		else
			dat += {"
				<a class="menu_button" href='byond://?src=[text_ref(user)];late_join=1'>JOIN GAME</a>
				<a class="menu_button" href='byond://?src=[text_ref(user)];view_manifest=1'>CREW MANIFEST</a>
			"}

		dat += {"<a class="menu_button" href='byond://?src=[text_ref(user)];observe=1'>OBSERVE</a>"}

		dat += {"
			<hr>
			<a class="menu_button" href='byond://?src=[text_ref(user)];character_setup=1'>SETUP CHARACTER (<span id="character_slot">[uppertext(user.client.prefs.read_preference(/datum/preference/name/real_name))]</span>)</a>
			<a class="menu_button" href='byond://?src=[text_ref(user)];rimworld_character_setup=1'>PREPARE COLONIST</a>
			<a class="menu_button" href='byond://?src=[text_ref(user)];game_options=1'>GAME OPTIONS</a>
			<a id="be_antag" class="menu_button" href='byond://?src=[text_ref(user)];toggle_antag=1'>[user.client.prefs.read_preference(/datum/preference/toggle/be_antag) ? "<span class='checked'>☑</span> BE ANTAGONIST" : "<span class='unchecked'>☒</span> BE ANTAGONIST"]</a>
			<hr>
			<a id="translate" class="menu_button" href='byond://?src=[text_ref(user)];toggle_translate=1'>[autotranslate_lobby_label(user.client.prefs.read_preference(/datum/preference/choiced/autotranslate_target))]</a>
		"}

		dat += user.preferences_file_buttons(user)

		if(length(GLOB.lobby_station_traits))
			dat += {"<a class="menu_button" href='byond://?src=[text_ref(user)];job_traits=1'>JOB TRAITS</a>"}

		if(!is_guest_key(user.key))
			dat += user.playerpolls()

		dat += "</div>"

		dat += {"
		<script language="JavaScript">
			const PLAYER_READY_TO_PLAY = "[PLAYER_READY_TO_PLAY]"
			const PLAYER_NOT_READY = "[PLAYER_NOT_READY]"
			var ready_mark = document.getElementById("ready");
			function toggle_ready(setReady) {
				if(setReady === PLAYER_READY_TO_PLAY) {
					ready_mark.innerHTML = "<span class='checked'>☑</span> READY"
				} else {
					ready_mark.innerHTML = "<span class='unchecked'>☒</span> READY"
				}
			}
			var antag_int = 0;
			var antag_mark = document.getElementById("be_antag");
			var antag_marks = \[ "<span class='unchecked'>☒</span> BE ANTAGONIST", "<span class='checked'>☑</span> BE ANTAGONIST" \];
			function toggle_antag(setAntag) {
				if(setAntag) {
					antag_int = setAntag;
					antag_mark.innerHTML = antag_marks\[antag_int\];
				} else {
					antag_int++;
					if (antag_int === antag_marks.length)
						antag_int = 0;
					antag_mark.innerHTML = antag_marks\[antag_int\];
				}
			}

			var translate_int = [autotranslate_lobby_index(user.client.prefs.read_preference(/datum/preference/choiced/autotranslate_target))];
			var translate_mark = document.getElementById("translate");
			var translate_marks = \[ [autotranslate_lobby_label_array()] \];
			function toggle_translate(state) {
				translate_int = Number(state);
				if(isNaN(translate_int) || translate_int < 0 || translate_int >= translate_marks.length)
					translate_int = 0;
				translate_mark.innerHTML = translate_marks\[translate_int\];
			}

			var character_name_slot = document.getElementById("character_slot");
			function update_current_character(name) {
				character_name_slot.textContent = name.toUpperCase();
			}

			function append_terminal_text() {}
			function update_loading_progress() {}
		</script>
		"}

	if(!user.title_screen_is_ready)
		dat += {"
			<script>
				location.href = "byond://?src=[text_ref(user)];title_is_ready=1";
			</script>
		"}

	dat += lobby_key_forwarding_script()
	dat += "</body></html>"
	return dat

/**
 * Обработка Topic
 */
/datum/lobby/Topic(href, href_list, mob/dead/new_player/user)
	if(user != usr || !user.client || user.client.interviewee)
		return FALSE

	// Звук кнопки
	if(href_list["observe"] || href_list["job_traits"] || href_list["server_swap"] || href_list["view_manifest"] || \
	   href_list["character_directory"] || href_list["toggle_antag"] || href_list["character_setup"] || \
	   href_list["rimworld_character_setup"] || href_list["game_options"] || href_list["toggle_ready"] || href_list["late_join"] || \
	   href_list["polls_menu"] || href_list["toggle_translate"] || href_list["export_preferences"] || href_list["import_preferences"])
		user.play_lobby_button_sound()

	if(href_list["observe"])
		if(!user.unvetted_notified && !user.trigger_unvetted_warning())
			return TRUE
		SSrimworld_planetmap.create_observer(user)
		return TRUE

	if(href_list["job_traits"])
		if(!user.unvetted_notified && !user.trigger_unvetted_warning())
			return TRUE
		user.show_job_traits()
		return TRUE

	if(href_list["server_swap"])
		user.server_swap()
		return TRUE

	if(href_list["toggle_translate"])
		user.cycle_autotranslate_preference()
		return TRUE

	if(href_list["view_manifest"])
		user.ViewManifest()
		return TRUE

	if(href_list["character_directory"])
#if !defined(NOERP)
		user.client.show_character_directory()
#endif
		return TRUE

	if(href_list["toggle_antag"])
		var/datum/preferences/preferences = user.client.prefs
		preferences.write_preference(GLOB.preference_entries[/datum/preference/toggle/be_antag], !preferences.read_preference(/datum/preference/toggle/be_antag))
		user.client << output(preferences.read_preference(/datum/preference/toggle/be_antag), "title_browser:toggle_antag")
		return TRUE

	if(href_list["character_setup"])
		var/datum/preferences/preferences = user.client.prefs
		preferences.current_window = PREFERENCE_TAB_CHARACTER_PREFERENCES
		preferences.update_static_data(user)
		preferences.ui_interact(user)
		return TRUE

	if(href_list["rimworld_character_setup"])
		if(!user.client.rw_prefs)
			user.client.rw_prefs = new /datum/rimworld_preferences(user.client)
		user.client.rw_prefs.ui_interact(user)
		return TRUE

	if(href_list["game_options"])
		var/datum/preferences/preferences = user.client.prefs
		preferences.current_window = PREFERENCE_TAB_GAME_PREFERENCES
		preferences.update_static_data(usr)
		preferences.ui_interact(usr)
		return TRUE

	if(href_list["export_preferences"])
		if(CONFIG_GET(flag/forbid_preferences_export))
			return TRUE
		user.client.prefs?.savefile?.export_json_to_client(user, user.client.ckey)
		return TRUE

	if(href_list["import_preferences"])
		if(CONFIG_GET(flag/forbid_preferences_import))
			return TRUE
		user.client.prefs?.import_preferences_from_client(user)
		return TRUE

	if(href_list["toggle_ready"])
		if(SSticker.current_state >= GAME_STATE_SETTING_UP)
			to_chat(user, span_notice("The round is starting. You cannot ready up at this time."))
			return TRUE

		if(CONFIG_GET(flag/min_flavor_text))
			var/datum/preferences/preferences = user.client.prefs
			var/uses_silicon_flavortext = (is_silicon_job(preferences?.get_highest_priority_job()) && length_char(user.client?.prefs?.read_preference(/datum/preference/text/silicon_flavor_text)) < CONFIG_GET(number/silicon_flavor_text_character_requirement))
			var/uses_normal_flavortext = (!is_silicon_job(preferences?.get_highest_priority_job()) && length_char(user.client?.prefs?.read_preference(/datum/preference/text/flavor_text)) < CONFIG_GET(number/flavor_text_character_requirement))
			if(uses_silicon_flavortext)
				to_chat(user, span_notice("You need at least [CONFIG_GET(number/silicon_flavor_text_character_requirement)] characters of Silicon Flavor Text to ready up for the round. You have [length_char(user.client.prefs.read_preference(/datum/preference/text/silicon_flavor_text))] characters."))
				return TRUE
			if(uses_normal_flavortext)
				to_chat(user, span_notice("You need at least [CONFIG_GET(number/flavor_text_character_requirement)] characters of Flavor Text to ready up for the round. You have [length_char(user.client.prefs.read_preference(/datum/preference/text/flavor_text))] characters."))
				return TRUE

		if(!user.unvetted_notified && !user.trigger_unvetted_warning())
			return TRUE

		user.ready = user.is_ready_to_play() ? PLAYER_NOT_READY : PLAYER_READY_TO_PLAY
		user.client << output(user.ready, "title_browser:toggle_ready")
		return TRUE

	if(href_list["late_join"])
		if(!user.unvetted_notified && !user.trigger_unvetted_warning())
			return TRUE
		GLOB.latejoin_menu.ui_interact(usr)
		return TRUE

	if(href_list["title_is_ready"])
		user.title_screen_is_ready = TRUE
		return TRUE

	if(href_list["polls_menu"])
		user.handle_player_polling()
		return TRUE

	return FALSE

/datum/lobby/proc/show(mob/dead/new_player/user)
	if(user.client?.interviewee)
		return

	winset(user, "title_browser", "is-disabled=false;is-visible=true")
	winset(user, "status_bar", "is-visible=false")

	var/datum/asset/assets = get_asset_datum(/datum/asset/simple/lobby)
	assets.send(user)

	update(user)

/datum/lobby/proc/update(mob/dead/new_player/user)
	var/dat = get_html(user)
	user << browse(SStitle.current_title_screen, "file=loading_screen.gif;display=0")
	user << browse(dat, "window=title_browser")

/datum/lobby/proc/hide(mob/dead/new_player/user)
	if(user.client?.mob)
		winset(user.client, "title_browser", "is-disabled=true;is-visible=false")
		winset(user.client, "status_bar", "is-visible=true")

#undef MAX_STARTUP_MESSAGES
