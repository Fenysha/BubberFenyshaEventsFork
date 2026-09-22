#define TRAINSTATION_TITLE_HTML {"
<html>
<head>
<meta http-equiv='X-UA-Compatible' content='IE=edge'>
<meta http-equiv='Content-Type' content='text/html; charset=UTF-8' />
<style type='text/css'>

@font-face {
    font-family: 'Fixedsys';
    src: url('FixedsysExcelsior3.01Regular.ttf');
}

@font-face {
    font-family: 'OCR-A';
    src: url('OCRAExtended.ttf');
}

/* ===== BODY ===== */
body, html {
    margin: 0;
    padding: 0;
    overflow: hidden;
    height: 100vh;
    width: 100vw;
    background: transparent;
    color: #ffdd99;
    font-family: 'Fixedsys', 'OCR-A', 'Courier New', Courier, monospace;
    font-smooth: never;
    -webkit-font-smoothing: none;
    -moz-osx-font-smoothing: grayscale;
    image-rendering: pixelated;
    text-rendering: geometricPrecision;
    -ms-user-select: none;
    cursor: default;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
}

body::after {
    content: '';
    position: fixed;
    inset: 0;
    width: 100vw;
    height: 100vh;
    background: radial-gradient(circle at center, transparent 30%, rgba(0,0,0,0.85) 80%);
    pointer-events: none;
    z-index: 0;
}

img.bg {
    position: fixed;
    inset: 0;
    width: 100vw;
    height: 100vh;
    object-fit: cover;
    z-index: -2;
    image-rendering: pixelated;
}

/* ===== TERMINAL ===== */
.container_terminal {
    position: relative;
    width: auto;
    max-width: 85vmin;
    overflow: hidden;
    padding: 2vmin 3vmin;
    z-index: 1;
    margin: 1vmin auto;
}

.terminal_text {
    display: block;
    width: 100%;
    text-align: left;
    color: #e8c68a;
    text-shadow: 1px 1px 0 #000, 2px 2px 4px #000;
    font-family: 'Fixedsys', monospace;
    font-size: 2.1vmin;
    line-height: 1.35;
    letter-spacing: 0.8px;
    white-space: pre-wrap;
    word-break: break-all;
}

/* ===== PROGRESS ===== */
/* Boot uses the ring from get_loading_screen_html(), which is styled inline. */
.container_progress {
    position: relative;
    height: 5vmin;
    width: 55vmin;
    margin: 3vmin auto;
    padding: 3px;
    background: rgba(10, 12, 25, 0.92);
    border: 3px solid #ffcc44;
    border-image: linear-gradient(#ffcc44, #aa8800) 1;
    box-shadow: inset 0 0 12px #ffaa0044;
    image-rendering: crisp-edges;
}

.progress_bar {
    width: 0%;
    height: 100%;
    background: linear-gradient(to right, #ffdd55, #ff8800);
    box-shadow: 0 0 12px #ffaa00;
}

/* ===== MENU PANEL ===== */
.container_nav {
    position: relative;
    top: 8vh;
    z-index: 1;
    background: transparent;
    border: none;
    padding: 0;
    margin: 2vmin auto;
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 1.2vmin;
	transform: translateY(10vh);
}

.container_nav hr {
    display: none;
}

/* ===== MENU BUTTON ===== */
.menu_button {
    display: inline-block;
    font-family: 'Fixedsys', monospace;
    font-size: 1.6vmin;
    line-height: 1.1;
    padding: 0.8vmin 3vmin;
    min-width: 25vmin;
    text-align: center;
    color: #e8c68a;
    text-shadow: 2px 2px 0 #000;
    letter-spacing: 1.5px;
    cursor: pointer;
    white-space: nowrap;
    transition: all 0.18s ease;
    border: 2px solid transparent;
    background: transparent;
    image-rendering: crisp-edges;
    text-decoration: none;
}

.menu_button:hover {
    color: #ffff88;
    text-shadow: 0 0 10px #ffdd55, 2px 2px 0 #000;
    background: transparent;
    transform: translateX(8px);
    letter-spacing: 2.2px;
}

.menu_button:active {
    transform: translate(3px, 3px);
    filter: brightness(0.85);
}

.menu_button:hover::before {
    content: ">>";
    margin-right: 1.5vmin;
    color: #ffdd55;
}

/* ===== NOTICE ===== */
.container_notice {
    position: relative;
    top: 8vh;
    z-index: 1;
    margin: 2vmin auto;
    padding: 1.5vmin 3vmin;
    max-width: 70vmin;
}

.menu_notice {
    display: block;
    text-align: center;
    color: #cccccc;
    font-family: 'Fixedsys', monospace;
    font-size: 1.6vmin;
    line-height: 1.3;
    text-shadow: 2px 2px 0 #000;
}

/* ===== STATES ===== */
.unchecked { color: #ff4444; }
.checked   { color: #44ff88; }

/* ===== ANIMATIONS ===== */
@keyframes fade_out {
    to { opacity: 0; }
}

.fade_out {
    animation: fade_out 1.8s forwards;
}

</style>
</head>
<body>
"}

/datum/lobby/trainstation
	name = "Trainstation Lobby"
	title_screens = list(
		'fenysha_events/icons/lobby/trainstation_v3.png'
	)


/datum/lobby/trainstation/get_html(mob/dead/new_player/user)
	var/dat = TRAINSTATION_TITLE_HTML

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
			<a class="menu_button" href='byond://?src=[text_ref(user)];character_setup=1'>SETUP CHARACTER</a>
			<a class="menu_button" href='byond://?src=[text_ref(user)];game_options=1'>GAME OPTIONS</a>
			<a id="be_antag" class="menu_button" href='byond://?src=[text_ref(user)];toggle_antag=1'>[user.client.prefs.read_preference(/datum/preference/toggle/be_antag) ? "<span class='checked'>☑</span> BE ANTAGONIST" : "<span class='unchecked'>☒</span> BE ANTAGONIST"]</a>
		"}

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
			function update_current_character() {}
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


/datum/controller/subsystem/train_controller/proc/update_tittle_screen()
	SStitle.set_lobby_type(/datum/lobby/trainstation)
	SStitle.show_title_screen()

	SSticker.set_lobby_music('fenysha_events/sounds/trainstation_lobbymusic.ogg', override = TRUE)
	for(var/client/C in GLOB.clients)
		C?.playtitlemusic(volume_multiplier = 1)

#undef TRAINSTATION_TITLE_HTML

/datum/controller/subsystem/train_controller/proc/announce_game()
	to_chat(world, span_boldnotice( \
		"[span_big("Trainstation mode - active")] \n \
		\n \
		The station will be replaced with a train, which is tasked with an important mission: to deliver a valuable cargo. \
		To do this, the train crew will have to guide the train across the trans-atlantic railway. \
		On the way to the goal, the train will face numerous threats and obstacles. \
		Drive the train and reach the final station. \n \
		\n \
		Event author: Fenysha, \n \
		Special thanks: Kierri, Mold, TYWONKA, V1S1Ti, Arturlang \n \
		Inspired by: The final station, Far: Lone Sails\
	"))


/datum/controller/subsystem/train_controller/proc/set_lobby_screen()
	SStitle.change_title_screen('fenysha_events/icons/lobby/trainstation_v3.png')
	return
