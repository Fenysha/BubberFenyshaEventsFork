#define MAX_STARTUP_MESSAGES 1

/mob/dead/new_player/get_title_html()
    var/dat = CUSTOM_TITLE_HTML
    if(SSticker.current_state == GAME_STATE_STARTUP)
        dat += {"<img src="loading_screen.gif" class="bg" id="bg_layer" alt="">"}
        dat += {"
        <div class="container_loading" id="parallax_loader">
            <div class="terminal_text" id="terminal"></div>
            <svg class="progress_ring" width="60" height="60">
                <circle class="progress_ring_bg" stroke="rgba(240, 211, 11, 1)" stroke-width="4" fill="transparent" r="24" cx="30" cy="30"/>
                <circle class="progress_ring_circle" id="progress_circle" stroke="#f0d30b" stroke-width="4" fill="transparent" r="24" cx="30" cy="30"/>
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
                while(terminal_lines.length > [MAX_STARTUP_MESSAGES]) {
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

    else
        dat += {"<img src="loading_screen.gif" class="bg" id="bg_layer" alt="">"}

        if(SStitle.current_notice)
            dat += {"
            <div class="container_notice">
                <p class="menu_notice">[SStitle.current_notice]</p>
            </div>
        "}

        dat += {"<div class="container_nav" id="parallax_nav">"}

        if(!SSticker || SSticker.current_state <= GAME_STATE_PREGAME)
            dat += {"<a id="ready" class="menu_button" href='byond://?src=[text_ref(src)];toggle_ready=1'>[ready == PLAYER_READY_TO_PLAY ? "<span class='checked'>☑</span> READY" : "<span class='unchecked'>☒</span> READY"]</a>"}
        else
            dat += {"
                <a class="menu_button" href='byond://?src=[text_ref(src)];late_join=1'>JOIN GAME</a>
                <a class="menu_button" href='byond://?src=[text_ref(src)];view_manifest=1'>CREW MANIFEST</a>
            "}

        dat += {"<a class="menu_button" href='byond://?src=[text_ref(src)];observe=1'>OBSERVE</a>"}

        dat += {"
            <hr>
            <a class="menu_button" href='byond://?src=[text_ref(src)];character_setup=1'>SETUP CHARACTER</a>
            <a class="menu_button" href='byond://?src=[text_ref(src)];game_options=1'>GAME OPTIONS</a>
            <a id="be_antag" class="menu_button" href='byond://?src=[text_ref(src)];toggle_antag=1'>[client.prefs.read_preference(/datum/preference/toggle/be_antag) ? "<span class='checked'>☑</span> BE ANTAGONIST" : "<span class='unchecked'>☒</span> BE ANTAGONIST"]</a>
        "}

        if(length(GLOB.lobby_station_traits))
            dat += {"<a class="menu_button" href='byond://?src=[text_ref(src)];job_traits=1'>JOB TRAITS</a>"}

        if(!is_guest_key(src.key))
            dat += playerpolls()

        dat += {"
            <div class="character_display">
                CURRENT CHARACTER:<br>
                <span id="character_slot" class="character_name">[uppertext(client.prefs.read_preference(/datum/preference/name/real_name))]</span>
            </div>
        "}

        dat += "</div>"
        dat += {"
        <script language="JavaScript">
            const PLAYER_READY_TO_PLAY = "[PLAYER_READY_TO_PLAY]"
            const PLAYER_NOT_READY = "[PLAYER_NOT_READY]"
            var ready_mark = document.getElementById("ready");
            function toggle_ready(setReady) {
                if(setReady === PLAYER_READY_TO_PLAY) {
                    ready_mark.innerHTML = "<span class='checked'>☑</span> READY"
                }
                else {
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
                }
                else {
                    antag_int++;
                    if (antag_int === antag_marks.length)
                        antag_int = 0;
                    antag_mark.innerHTML = antag_marks\[antag_int\];
                }
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

    if(!title_screen_is_ready)
        dat += {"
            <script>
                location.href = "byond://?src=[text_ref(src)];title_is_ready=1";
            </script>
        "}

    dat += "</body></html>"

    return dat

#undef MAX_STARTUP_MESSAGES
