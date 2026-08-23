#define SOUND_EMITTER_LOCAL "local" //Plays the sound like a normal heard sound
#define SOUND_EMITTER_DIRECT "direct" //Plays the sound directly to hearers regardless of pressure/proximity/et cetera

#define SOUND_EMITTER_RADIUS "radius" //Plays the sound to everyone in a radius
#define SOUND_EMITTER_ZLEVEL "zlevel" //Plays the sound to everyone on the z-level
#define SOUND_EMITTER_GLOBAL "global" //Plays the sound to everyone in the game world
#define SOUND_EMITTER_COORDS "coords" //Plays the sound around a specific x, y, z coordinate
#define SOUND_EMITTER_SPECIFIC_Z "specific_z" //Plays the sound on a targeted Z-level

//Admin sound emitters with highly customizable functions!
/obj/effect/sound_emitter_looping
	name = "sound emitter"
	desc = "Emits sounds, presumably."
	icon = 'icons/effects/effects.dmi'
	icon_state = "shield2"
	invisibility = INVISIBILITY_OBSERVER
	anchored = TRUE
	density = FALSE
	opacity = FALSE
	alpha = 175
	var/sound_file //The sound file the emitter plays
	var/sound_volume = 50 //The volume the sound file is played at
	var/play_radius = 3 //Any mobs within this many tiles will hear the sounds played if it's using the appropriate mode
	var/motus_operandi = SOUND_EMITTER_LOCAL //The mode this sound emitter is using
	var/emitter_range = SOUND_EMITTER_ZLEVEL //The range this emitter's sound is heard at

	// Ручные координаты и Z-уровень
	var/target_x = 1
	var/target_y = 1
	var/target_z = 1

	// Цикличность
	var/looping = FALSE
	var/loop_interval = 50 // В децисекундах (50 = 5 секунд)
	var/timer_id

/obj/effect/sound_emitter_looping/Destroy(force)
	if(!force)
		return QDEL_HINT_LETMELIVE
	stop_loop()
	. = ..()

/obj/effect/sound_emitter_looping/singularity_act()
	return

/obj/effect/sound_emitter_looping/singularity_pull(atom/singularity, current_size)
	return

/obj/effect/sound_emitter_looping/examine(mob/user)
	. = ..()
	if(!isobserver(user))
		return
	. += "[span_boldnotice("Sound File:")] [sound_file ? sound_file : "None chosen"]"
	. += span_boldnotice("Mode:</span> [motus_operandi]")
	. += span_boldnotice("Range:</span> [emitter_range]")
	. += "<b>Sound is playing at [sound_volume]% volume.</b>"
	. += "<b>Looping:</b> [looping ? "ENABLED ([loop_interval / 10]s)" : "DISABLED"]"
	if(user.client?.holder)
		. += "<b>Alt-click it to quickly activate it!</b>"

/obj/effect/sound_emitter_looping/attack_ghost(mob/user)
	if(!check_rights_for(user.client, R_SOUND))
		user.examinate(src)
		return
	edit_emitter(user)

/obj/effect/sound_emitter_looping/click_alt(mob/user)
	if(!check_rights_for(user.client, R_SOUND))
		return CLICK_ACTION_BLOCKING

	activate(user)
	to_chat(user, span_notice("Sound emitter activated."), confidential = TRUE)
	return CLICK_ACTION_SUCCESS

/obj/effect/sound_emitter_looping/proc/edit_emitter(mob/user)
	var/dat = ""
	dat += "<b>Label:</b> <a href='byond://?src=[text_ref(src)];edit_label=1'>[maptext ? maptext : "No label set!"]</a><br>"
	dat += "<br>"
	dat += "<b>Sound File:</b> <a href='byond://?src=[text_ref(src)];edit_sound_file=1'>[sound_file ? sound_file : "No file chosen!"]</a><br>"
	dat += "<b>Volume:</b> <a href='byond://?src=[text_ref(src)];edit_volume=1'>[sound_volume]%</a><br>"
	dat += "<br>"
	dat += "<b>Mode:</b> <a href='byond://?src=[text_ref(src)];edit_mode=1'>[motus_operandi]</a><br>"
	if(motus_operandi != SOUND_EMITTER_LOCAL)
		dat += "<b>Range:</b> <a href='byond://?src=[text_ref(src)];edit_range=1'>[emitter_range]</a><br>"
		if(emitter_range == SOUND_EMITTER_RADIUS)
			dat += "<b>Radius:</b> <a href='byond://?src=[text_ref(src)];edit_radius=1'>[play_radius]-tile radius</a><br>"
		else if(emitter_range == SOUND_EMITTER_COORDS)
			dat += "<b>Target Coords:</b> <a href='byond://?src=[text_ref(src)];edit_coords=1'>([target_x], [target_y], [target_z])</a> | <a href='byond://?src=[text_ref(src)];edit_radius=1'>Radius: [play_radius]</a><br>"
		else if(emitter_range == SOUND_EMITTER_SPECIFIC_Z)
			dat += "<b>Target Z-Level:</b> <a href='byond://?src=[text_ref(src)];edit_specific_z=1'>Z-[target_z]</a><br>"

	dat += "<br>"
	dat += "<b>Looping Status:</b> <a href='byond://?src=[text_ref(src)];toggle_loop=1'>[looping ? "ENABLED" : "DISABLED"]</a><br>"
	if(looping)
		dat += "<b>Loop Interval:</b> <a href='byond://?src=[text_ref(src)];edit_interval=1'>[loop_interval / 10] seconds</a><br>"

	dat += "<br>"
	dat += "<a href='byond://?src=[text_ref(src)];play=1'>Play Sound Once</a><br>"
	var/datum/browser/popup = new(user, "emitter", "Sound Emitter", 500, 650)
	popup.set_content(dat)
	popup.open()

/obj/effect/sound_emitter_looping/Topic(href, href_list)
	..()
	if(!ismob(usr) || !usr.client || !check_rights_for(usr.client, R_SOUND))
		return
	var/mob/user = usr
	if(href_list["edit_label"])
		var/new_label = tgui_input_text(user, "Choose a new label", "Sound Emitter", max_length = MAX_NAME_LEN)
		if(!new_label)
			return
		maptext = MAPTEXT(new_label)
		to_chat(user, span_notice("Label set to [maptext]."), confidential = TRUE)

	if(href_list["edit_sound_file"])
		var/new_file = input(user, "Choose a sound file.", "Sound Emitter") as null|sound
		if(!new_file)
			return
		sound_file = new_file
		to_chat(user, span_notice("New sound file set to [sound_file]."), confidential = TRUE)

	if(href_list["edit_volume"])
		var/new_volume = tgui_input_number(user, "Choose a volume", "Sound Emitter", sound_volume, 100)
		if(!new_volume)
			return
		sound_volume = new_volume
		to_chat(user, span_notice("Volume set to [sound_volume]%."), confidential = TRUE)

	if(href_list["edit_mode"])
		var/mode_list = list(
			"Local (normal sound)" = SOUND_EMITTER_LOCAL,
			"Direct (not affected by environment/location)" = SOUND_EMITTER_DIRECT
		)
		var/new_mode = tgui_input_list(user, "Choose a new mode", "Sound Emitter", mode_list)
		if(!new_mode)
			return
		motus_operandi = mode_list[new_mode]
		to_chat(user, span_notice("Mode set to [motus_operandi]."), confidential = TRUE)

	if(href_list["edit_range"])
		var/range_list = list(
			"Radius (around emitter)" = SOUND_EMITTER_RADIUS,
			"Z-Level (current z-level)" = SOUND_EMITTER_ZLEVEL,
			"Global (all players)" = SOUND_EMITTER_GLOBAL,
			"Exact Coordinates (x, y, z)" = SOUND_EMITTER_COORDS,
			"Specific Z-Level" = SOUND_EMITTER_SPECIFIC_Z
		)
		var/new_range = tgui_input_list(user, "Choose a new range", "Sound Emitter", range_list)
		if(!new_range)
			return
		emitter_range = range_list[new_range]
		to_chat(user, span_notice("Range set to [emitter_range]."), confidential = TRUE)

	if(href_list["edit_radius"])
		var/new_radius = tgui_input_number(user, "Choose a radius", "Sound Emitter", play_radius, 127)
		if(!new_radius)
			return
		play_radius = new_radius
		to_chat(user, span_notice("Audible radius set to [play_radius]."), confidential = TRUE)

	if(href_list["edit_coords"])
		var/input_x = tgui_input_number(user, "Set X Coordinate", "Target X", target_x, world.maxx, 1)
		if(isnull(input_x)) return
		var/input_y = tgui_input_number(user, "Set Y Coordinate", "Target Y", target_y, world.maxy, 1)
		if(isnull(input_y)) return
		var/input_z = tgui_input_number(user, "Set Z Coordinate", "Target Z", target_z, world.maxz, 1)
		if(isnull(input_z)) return

		target_x = input_x
		target_y = input_y
		target_z = input_z
		to_chat(user, span_notice("Target coordinates set to ([target_x], [target_y], [target_z])."), confidential = TRUE)

	if(href_list["edit_specific_z"])
		var/input_z = tgui_input_number(user, "Set Z-Level Target", "Target Z-Level", target_z, world.maxz, 1)
		if(isnull(input_z)) return
		target_z = input_z
		to_chat(user, span_notice("Target Z-Level set to [target_z]."), confidential = TRUE)

	if(href_list["toggle_loop"])
		looping = !looping
		if(looping)
			start_loop()
			to_chat(user, span_notice("Looping enabled."), confidential = TRUE)
		else
			stop_loop()
			to_chat(user, span_notice("Looping disabled."), confidential = TRUE)

	if(href_list["edit_interval"])
		var/new_interval = tgui_input_number(user, "Set interval in seconds", "Loop Interval", loop_interval / 10, 3600, 1)
		if(!new_interval)
			return
		loop_interval = new_interval * 10
		if(looping)
			start_loop() // Restart loop timer with new interval
		to_chat(user, span_notice("Loop interval set to [new_interval] seconds."), confidential = TRUE)

	if(href_list["play"])
		activate(user)

	edit_emitter(user)

/obj/effect/sound_emitter_looping/proc/start_loop()
	stop_loop()
	activate()
	timer_id = addtimer(CALLBACK(src, PROC_REF(loop_tick)), loop_interval, TIMER_STOPPABLE | TIMER_LOOP)

/obj/effect/sound_emitter_looping/proc/stop_loop()
	if(timer_id)
		deltimer(timer_id)
		timer_id = null

/obj/effect/sound_emitter_looping/proc/loop_tick()
	if(!looping)
		stop_loop()
		return
	activate()

/obj/effect/sound_emitter_looping/proc/activate(mob/user)
	if(!sound_file)
		return

	if(motus_operandi == SOUND_EMITTER_LOCAL)
		playsound(src, sound_file, sound_volume, FALSE)
		if(user)
			log_admin("[ADMIN_LOOKUPFLW(user)] activated local sound emitter with file \"[sound_file]\" at [AREACOORD(src)]")
		flick("shield1", src)
		return

	var/list/hearing_mobs = list()

	switch(emitter_range)
		if(SOUND_EMITTER_RADIUS)
			for(var/mob/M in GLOB.player_list)
				if(get_dist(src, M) <= play_radius && M.z == z)
					hearing_mobs += M

		if(SOUND_EMITTER_ZLEVEL)
			for(var/mob/M in GLOB.player_list)
				if(M.z == z)
					hearing_mobs += M

		if(SOUND_EMITTER_GLOBAL)
			hearing_mobs = GLOB.player_list.Copy()

		if(SOUND_EMITTER_COORDS)
			var/turf/target_turf = locate(target_x, target_y, target_z)
			if(target_turf)
				for(var/mob/M in GLOB.player_list)
					if(get_dist(target_turf, M) <= play_radius && M.z == target_z)
						hearing_mobs += M

		if(SOUND_EMITTER_SPECIFIC_Z)
			for(var/mob/M in GLOB.player_list)
				if(M.z == target_z)
					hearing_mobs += M

	for(var/mob/M in hearing_mobs)
		var/pref_volume = M.client?.prefs?.read_preference(/datum/preference/numeric/volume/sound_midi) || 100
		if(pref_volume > 0)
			M.playsound_local(M, sound_file, (sound_volume * (pref_volume / 100)), FALSE, channel = CHANNEL_ADMIN, pressure_affected = FALSE)

	if(user)
		log_admin("[ADMIN_LOOKUPFLW(user)] activated a sound emitter with file \"[sound_file]\" at [AREACOORD(src)]")
	flick("shield1", src)

#undef SOUND_EMITTER_LOCAL
#undef SOUND_EMITTER_DIRECT
#undef SOUND_EMITTER_RADIUS
#undef SOUND_EMITTER_ZLEVEL
#undef SOUND_EMITTER_GLOBAL
#undef SOUND_EMITTER_COORDS
#undef SOUND_EMITTER_SPECIFIC_Z
