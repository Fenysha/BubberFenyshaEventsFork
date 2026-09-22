#define CUSTOM_RIMWORLD_HTML {"
<html>
<head>
	<meta http-equiv=\"X-UA-Compatible\" content=\"IE=edge\">
	<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\" />
	<style type='text/css'>
		@font-face {
			font-family: 'OCR-A';
			src: url('OCRAExtended.ttf');
		}

		body, html {
			margin: 0;
			overflow: hidden;
			text-align: center;
			background-color: #0a0a0c;
			image-rendering: pixelated;
			-ms-interpolation-mode: nearest-neighbor;
			text-rendering: geometricPrecision;
			-webkit-font-smoothing: none;
			-moz-osx-font-smoothing: grayscale;
			-ms-user-select: none;
			cursor: default;
			width: 100%;
			height: 100%;
			font-family: \"Fixedsys\", monospace;
		}

		img {
			border-style: none;
			image-rendering: pixelated;
			-ms-interpolation-mode: nearest-neighbor;
		}

		.bg {
			position: absolute;
			top: 0;
			left: 0;
			width: 100%;
			height: 100%;
			object-fit: cover;
			object-position: center;
			z-index: 0;
			filter: contrast(1.15) brightness(0.82);
		}

		.container_loading {
			display: flex;
			flex-direction: row;
			align-items: center;
			justify-content: flex-end;
			gap: 15px;
			position: absolute;
			bottom: 40px;
			right: 40px;
			z-index: 2;
		}

		.terminal_text {
			text-align: right;
			font-family: \"Fixedsys\", monospace;
			font-size: 1.8vmin;
			color: #e8d48b;
			text-shadow: 1px 1px 0 #000;
		}

		.title_block {
			position: absolute;
			top: 9.5vmin;
			right: 30vmin;
			width: 42vmin;
			text-align: right;
			z-index: 1;
			pointer-events: none;
		}

		.title_main {
			font-family: \"Fixedsys\", monospace;
			font-size: 8.6vmin;
			font-weight: bold;
			color: #f4eac8;
			text-shadow:
				0 0 12px rgba(210, 170, 60, 0.65),
				3px 3px 0 #000,
				-1px -1px 0 #3a2a10;
			letter-spacing: 4px;
			line-height: 1.0;
			margin: 0;
			white-space: nowrap;
		}

		.title_sub {
			font-family: \"Fixedsys\", monospace;
			font-size: 1.9vmin;
			color: #c9b87a;
			text-shadow: 1px 1px 0 #000;
			margin-top: 0.4vmin;
			letter-spacing: 1.8px;
		}

		.container_nav {
			position: absolute;
			box-sizing: border-box;
			width: 34vmin;
			top: 50%;
			right: 9vmin;
			transform: translateY(-50%);
			z-index: 1;
			padding: 0;
			background: transparent;
			border: none;
			box-shadow: none;
		}

		.character_display {
			margin-top: 2.8vmin;
			font-family: \"Fixedsys\";
			font-size: 1.7vmin;
			color: #a09070;
			text-align: right;
			text-shadow: 1px 1px 0 #000;
		}

		.character_name {
			font-size: 2.5vmin;
			color: #e8d48b;
			font-weight: bold;
			letter-spacing: 1px;
		}

		.menu_button {
			display: block;
			box-sizing: border-box;
			font-family: \"Fixedsys\", monospace;
			font-weight: normal;
			text-decoration: none;
			font-size: 2.55vmin;
			line-height: 1.35;
			width: 100%;
			text-align: right;
			color: #e6e0c8;
			background: #5a4328;
			border: 3px solid;
			border-top-color: #7a6238;
			border-left-color: #3e2e18;
			border-right-color: #7a6238;
			border-bottom-color: #3e2e18;
			outline: 1px solid #0a0804;
			padding: 0.65vmin 1.3vmin;
			margin: 0.55vmin 0;
			letter-spacing: 1px;
			cursor: pointer;
			white-space: nowrap;
			overflow: hidden;
			text-shadow: 1px 1px 0 #000;
			box-shadow:
				inset 0 1px 0 rgba(255, 220, 140, 0.15),
				inset 0 -8px 12px rgba(0, 0, 0, 0.35);
			transition: all 0.12s ease;
		}

		.menu_button:hover {
			color: #fff8d0;
			background: #6e5332;
			border-top-color: #9a7a48;
			border-right-color: #9a7a48;
			transform: scale(1.03);
			box-shadow:
				inset 0 1px 0 rgba(255, 230, 160, 0.25),
				inset 0 -8px 12px rgba(0, 0, 0, 0.25),
				0 0 12px rgba(180, 140, 50, 0.35);
		}

		.menu_button:active {
			color: #d8c070;
			background: #4a3720;
			transform: scale(0.98);
			box-shadow: inset 0 3px 8px rgba(0, 0, 0, 0.5);
		}

		.menu_button:hover::before {
			content: \"▶ \";
			color: #e8c060;
		}

		.container_notice {
			position: absolute;
			box-sizing: border-box;
			width: auto;
			top: 5.5vmin;
			left: 50%;
			transform: translateX(-50%);
			z-index: 1;
		}

		.menu_notice {
			font-family: \"Fixedsys\";
			color: #e05040;
			text-shadow: 1px 1px 0 #000;
			font-size: 2.5vmin;
			background: rgba(20, 10, 5, 0.75);
			padding: 0.7vmin 1.8vmin;
			border: 1px solid #6a3020;
		}

		/* ===== STATUS (center-bottom) ===== */
		.container_status {
			position: absolute;
			left: 50%;
			bottom: 6vmin;
			transform: translateX(-50%);
			z-index: 2;
			text-align: center;
			pointer-events: none;
		}

		.status_line {
			font-family: \"Fixedsys\", monospace;
			font-size: 2.1vmin;
			color: #e8d48b;
			text-shadow: 1px 1px 0 #000;
			letter-spacing: 1.5px;
			margin: 0.3vmin 0;
		}

		.status_planet {
			font-size: 2.6vmin;
			color: #f4eac8;
			font-weight: bold;
			letter-spacing: 2px;
		}

		.status_dim {
			color: #a09070;
			font-size: 1.7vmin;
		}

		.container_icons {
			position: absolute;
			bottom: 3.5vmin;
			left: 3.5vmin;
			display: flex;
			flex-direction: row;
			gap: 1.2vmin;
			z-index: 5;
		}

		.icon_button {
			display: flex;
			align-items: center;
			justify-content: center;
			width: 5.2vmin;
			height: 5.2vmin;
			box-sizing: border-box;
			font-family: \"Fixedsys\", monospace;
			font-size: 2.4vmin;
			text-decoration: none;
			color: #d8c8a0;
			background: #4a3820;
			border: 2px solid;
			border-top-color: #6a542e;
			border-left-color: #2e2414;
			border-right-color: #6a542e;
			border-bottom-color: #2e2414;
			outline: 1px solid #0a0804;
			cursor: pointer;
			text-shadow: 1px 1px 0 #000;
			box-shadow: inset 0 1px 0 rgba(255, 220, 140, 0.12);
			transition: all 0.12s ease;
			user-select: none;
			position: relative;
		}

		.icon_button:hover {
			color: #fff0c0;
			background: #5e4828;
			border-top-color: #8a6e3e;
			border-right-color: #8a6e3e;
			transform: scale(1.08);
			box-shadow:
				inset 0 1px 0 rgba(255, 230, 160, 0.2),
				0 0 10px rgba(180, 140, 50, 0.4);
		}

		.icon_button:active {
			transform: scale(0.95);
			background: #3a2c18;
		}

		.icon_button .tooltip {
			position: absolute;
			bottom: 120%;
			left: 50%;
			transform: translateX(-50%);
			background: #2a1e10;
			color: #e8d48b;
			padding: 0.4vmin 1vmin;
			font-size: 1.5vmin;
			white-space: nowrap;
			border: 1px solid #6a542e;
			opacity: 0;
			pointer-events: none;
			transition: opacity 0.15s;
			z-index: 10;
		}

		.icon_button:hover .tooltip {
			opacity: 1;
		}
	</style>
</head>
<body>
"}

/datum/lobby/rimworld
	name = "Rimworld Lobby"

	title_screens = list(
		'fenysha_events/icons/lobby/rimworld_ideology.png'
	)

/datum/lobby/rimworld/get_html(mob/dead/new_player/user)
	if(SSmapping.current_map?.override_titlescreen)
		return get_default_title_html(user)

	var/dat = CUSTOM_RIMWORLD_HTML

	if(SSticker.current_state == GAME_STATE_STARTUP)
		dat += get_loading_screen_html(user)
	else
		var/game_started = SSticker && SSticker.current_state >= GAME_STATE_PLAYING
		var/status_text = get_rimworld_lobby_status()
		var/planet_name = get_rimworld_planet_name()

		dat += {"<img src="loading_screen.gif" class="bg" id="bg_layer" alt="">"}

		if(SStitle.current_notice)
			dat += {"
			<div class="container_notice">
				<p class="menu_notice">[SStitle.current_notice]</p>
			</div>
			"}

		dat += {"
		<div class="title_block">
			<div class="title_main">RIMSTATION 13</div>
			<div class="title_sub">story generator by Fenysha</div>
		</div>
		"}

		dat += {"<div class="container_nav" id="parallax_nav">"}

		if(game_started)
			dat += {"<a class="menu_button" href='byond://?src=[text_ref(user)];late_join=1'>Join world</a>"}

		dat += {"<a class="menu_button" href='byond://?src=[text_ref(user)];observe=1'>Observer</a>"}
		dat += {"
			<a class="menu_button" href='byond://?src=[text_ref(user)];character_setup=1'>Edit character</a>
			<a class="menu_button" href='byond://?src=[text_ref(user)];game_options=1'>Options</a>
		"}

		if(length(GLOB.lobby_station_traits))
			dat += {"<a class="menu_button" href='byond://?src=[text_ref(user)];job_traits=1'>JOB TRAITS</a>"}

		if(!is_guest_key(user.key))
			dat += user.playerpolls()

		dat += {"
			<div class="character_display">
				CURRENT CHARACTER:<br>
				<span id="character_slot" class="character_name">[uppertext(user.client.prefs.read_preference(/datum/preference/name/real_name))]</span>
			</div>
		"}
		dat += "</div>"

		dat += {"
		<div class="container_status">
			<div class="status_line status_planet">[html_encode(planet_name)]</div>
			<div class="status_line">[html_encode(status_text)]</div>
			<div class="status_line status_dim">SEED [SSrimworld_planetmap?.planet?.seed || "—"]</div>
		</div>
		"}

		dat += {"
		<div class="container_icons">
			<a class="icon_button" href='byond://?src=[text_ref(user)];import_prefs=1' title="Import Preferences">
				⬇
				<span class="tooltip">Import Prefs</span>
			</a>
			<a class="icon_button" href='byond://?src=[text_ref(user)];export_prefs=1' title="Export Preferences">
				⬆
				<span class="tooltip">Export Prefs</span>
			</a>
			<a id="translate" class="icon_button" href='byond://?src=[text_ref(user)];toggle_translate=1' title="Toggle Translator">
				文
				<span class="tooltip">Translator</span>
			</a>
			<a class="icon_button" href="https://discord.gg/2GZh9nPzuY" target="_blank" title="Discord">
				◈
				<span class="tooltip">Discord</span>
			</a>
			<a class="icon_button" href="https://github.com/Fenysha/BubberFenyshaEventsFork/tree/master-events" target="_blank" title="GitHub">
				⌘
				<span class="tooltip">GitHub</span>
			</a>
		</div>
		"}

		dat += {"
		<script language="JavaScript">
			var translate_int = [autotranslate_lobby_index(user.client.prefs.read_preference(/datum/preference/choiced/autotranslate_target))];
			var translate_mark = document.getElementById("translate");
			function toggle_translate(state) {
				translate_int = Number(state);
				if(isNaN(translate_int) || translate_int < 0)
					translate_int = 0;
			}

			var character_name_slot = document.getElementById("character_slot");
			function update_current_character(name) {
				if (character_name_slot) {
					character_name_slot.textContent = name.toUpperCase();
				}
			}
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

/datum/lobby/rimworld/proc/get_rimworld_lobby_status()
	if(!SSticker)
		return "INITIALIZING"
	switch(SSticker.current_state)
		if(GAME_STATE_STARTUP)
			return "STARTING UP"
		if(GAME_STATE_PREGAME)
			return "IN LOBBY"
		if(GAME_STATE_SETTING_UP)
			return "SETTING UP"
		if(GAME_STATE_PLAYING)
			return "IN PROGRESS"
		if(GAME_STATE_FINISHED)
			return "ROUND END"
	return "UNKNOWN"

/datum/lobby/rimworld/proc/get_rimworld_planet_name()
	var/datum/rimworld_planet/P = SSrimworld_planetmap?.planet
	if(P && P.name)
		return P.name
	return "Unknown World"
