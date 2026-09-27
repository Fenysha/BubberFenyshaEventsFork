//MARK:
/datum/turf_roof
	var/name = "Roof"
	var/desc = "A simple roof."

	var/blocks_light = TRUE
	var/blocks_weather = TRUE
	var/max_support_distance = 6
	var/can_be_removed = TRUE
	var/collapse_damage = 60
	var/collapse_debris_type = null


	var/atom/build_cost_type = null
	var/build_cost_amount = 0
	var/build_time = 1 SECONDS
	var/radial_icon = 'fenysha_events/icons/effects/roofs.dmi'
	var/radial_icon_state = "default"

/datum/turf_roof/constructed
	name = "Constructed Roof"
	desc = "A simple roof made of planks and sheet metal."
	max_support_distance = 6
	collapse_damage = 40
	build_cost_type = null
	build_cost_amount = 0
	build_time = 0.5 SECONDS
	radial_icon_state = "roof_basic"

/datum/turf_roof/rock_thick
	name = "Thick Rock Roof"
	desc = "Meters of solid rock. Cannot be dismantled by hand."
	can_be_removed = FALSE
	max_support_distance = 6
	collapse_damage = 150
	build_cost_type = /obj/item/stack/sheet/mineral/stone
	build_cost_amount = 4
	build_time = 3 SECONDS
	radial_icon_state = "roof_rock"

/datum/turf_roof/reinforced
	name = "Reinforced Roof"
	desc = "Heavy metal plating. Very sturdy."
	max_support_distance = 8
	collapse_damage = 80
	build_cost_type = /obj/item/stack/sheet/iron
	build_cost_amount = 2
	build_time = 2 SECONDS
	radial_icon_state = "roof_reinforced"


GLOBAL_LIST_EMPTY(roof_datums)

/proc/get_roof_datum(path)
	if(!ispath(path, /datum/turf_roof))
		return null
	if(!GLOB.roof_datums[path])
		GLOB.roof_datums[path] = new path()
	return GLOB.roof_datums[path]


//MARK: Roof building
/mob/living
	var/roof_building_mode = FALSE
	var/datum/turf_roof/selected_roof = null
	var/list/roof_view_images = null


/mob/living/proc/toggle_roof_building_mode()
	roof_building_mode = !roof_building_mode

	if(roof_building_mode)
		if(!selected_roof)
			selected_roof = get_roof_datum(/datum/turf_roof/constructed)
		to_chat(src, span_notice("Roof building mode <b>enabled</b>. RMB — build, Ctrl+Shift+RMB — menu."))
		update_roof_view_images()
		RegisterSignal(src, COMSIG_MOB_CLICKON, PROC_REF(on_roof_mode_click))
		RegisterSignal(src, COMSIG_MOVABLE_MOVED, PROC_REF(on_roof_mode_moved))
	else
		to_chat(src, span_notice("Roof building mode <b>disabled</b>."))
		clear_roof_view_images()
		UnregisterSignal(src, list(COMSIG_MOB_CLICKON, COMSIG_MOVABLE_MOVED))


/mob/living/proc/on_roof_mode_moved(atom/old_loc, dir, forced)
	SIGNAL_HANDLER
	if(roof_building_mode)
		update_roof_view_images()


/mob/living/proc/clear_roof_view_images()
	if(!client || !roof_view_images)
		return
	client.images -= roof_view_images
	QDEL_LIST(roof_view_images)
	roof_view_images = null


/mob/living/proc/update_roof_view_images()
	if(!client || !roof_building_mode)
		return

	clear_roof_view_images()
	roof_view_images = list()

	for(var/turf/open/rimworld/T in RANGE_TURFS(7, src))
		if(!T.has_roof())
			continue

		var/image/I = image('fenysha_events/icons/effects/roofs.dmi', T, "default")
		I.plane = ABOVE_GAME_PLANE
		I.layer = ABOVE_ALL_MOB_LAYER
		I.alpha = 200

		roof_view_images += I

	client.images += roof_view_images


/mob/living/proc/on_roof_mode_click(mob/user, atom/A, list/modifiers)
	SIGNAL_HANDLER
	roof_interaction(A, modifiers)

/mob/living/proc/roof_interaction(atom/A, list/modifiers)
	set waitfor = FALSE

	if(!roof_building_mode || !istype(A, /turf/open/rimworld))
		return NONE

	if(LAZYACCESS(modifiers, CTRL_CLICK) && LAZYACCESS(modifiers, RIGHT_CLICK))
		open_roof_radial_menu()
		return COMSIG_MOB_CANCEL_CLICKON

	if(LAZYACCESS(modifiers, RIGHT_CLICK))
		try_build_roof(A)
		return COMSIG_MOB_CANCEL_CLICKON

	return NONE


/mob/living/proc/try_build_roof(turf/open/rimworld/T)
	if(!roof_building_mode || !istype(T) || !selected_roof)
		return FALSE

	if(T.has_roof())
		to_chat(src, span_warning("There is already a roof here."))
		return FALSE

	var/has_support = FALSE
	for(var/turf/closed/rw_wall/neighbor in RANGE_TURFS(6, T))
		if(neighbor.is_roof_support_provider())
			has_support = TRUE
			break
	if(!has_support)
		to_chat(src, span_notice("There no support for building roof!"))
		return FALSE

	if(selected_roof.build_cost_amount > 0 && selected_roof.build_cost_type)
		if(!has_roof_resources(selected_roof))
			to_chat(src, span_warning("You lack the materials ([selected_roof.build_cost_amount] [initial(selected_roof.build_cost_type.name)])."))
			return FALSE

	if(selected_roof.build_time > 0)
		if(!do_after(src, selected_roof.build_time, T))
			return FALSE

	if(selected_roof.build_cost_amount > 0 && selected_roof.build_cost_type)
		if(!consume_roof_resources(selected_roof))
			return FALSE

	T.set_roof(selected_roof.type)
	to_chat(src, span_notice("You build a [selected_roof.name]."))
	update_roof_view_images()
	return TRUE


/mob/living/proc/has_roof_resources(datum/turf_roof/roof)
	if(!roof.build_cost_type || roof.build_cost_amount <= 0)
		return TRUE
	var/obj/item/stack/S = locate(roof.build_cost_type) in get_all_contents()
	return S?.amount >= roof.build_cost_amount


/mob/living/proc/consume_roof_resources(datum/turf_roof/roof)
	if(!roof.build_cost_type || roof.build_cost_amount <= 0)
		return TRUE
	var/obj/item/stack/S = locate(roof.build_cost_type) in get_all_contents()
	if(!S || S.amount < roof.build_cost_amount)
		return FALSE
	S.use(roof.build_cost_amount)
	return TRUE


/mob/living/proc/get_available_roof_types()
	return list(
		/datum/turf_roof/constructed,
		/datum/turf_roof/reinforced,
		/datum/turf_roof/rock_thick,
	)


/mob/living/proc/open_roof_radial_menu()
	if(!roof_building_mode)
		return

	var/list/choices = list()
	for(var/path in get_available_roof_types())
		var/datum/turf_roof/R = get_roof_datum(path)
		if(!R)
			continue
		var/cost_text = R.build_cost_amount > 0 ? " ([R.build_cost_amount] [initial(R.build_cost_type.name)])" : " (free)"
		choices[R.name + cost_text] = path

	var/choice = show_radial_menu(src, src, choices, require_near = FALSE, tooltips = TRUE)
	if(!choice)
		return

	selected_roof = get_roof_datum(choices[choice])
	to_chat(src, span_notice("Selected roof: <b>[selected_roof.name]</b>."))


/mob/living/verb/toggle_roof_mode()
	set name = "Toggle Roof Building Mode"
	set category = "IC"
	toggle_roof_building_mode()


// MARK:
/datum/element/roof
	element_flags = ELEMENT_BESPOKE | ELEMENT_DETACH_ON_HOST_DESTROY
	argument_hash_start_idx = 2

	var/datum/turf_roof/roof_data

/datum/element/roof/Attach(datum/target, datum/turf_roof/roof)
	. = ..()
	if(. == ELEMENT_INCOMPATIBLE)
		return

	if(!istype(target, /turf/open/rimworld) || !istype(roof))
		return ELEMENT_INCOMPATIBLE

	roof_data = roof
	var/turf/open/rimworld/T = target

	T.apply_roof_effects(roof_data)

	RegisterSignal(T, COMSIG_ATOM_EXAMINE, PROC_REF(on_examine))
	RegisterSignal(T, COMSIG_TURF_ROOF_SUPPORT_CHECK, PROC_REF(on_support_check))
	RegisterSignal(T, COMSIG_TURF_ROOF_COLLAPSE, PROC_REF(on_collapse))
	RegisterSignal(T, COMSIG_ATOM_ROOF_SUPPORT_LOST, PROC_REF(on_support_lost))

	ADD_TRAIT(T, TRAIT_HAS_ROOF, REF(src))

	if(!check_support(T))
		on_collapse(T)

	SEND_SIGNAL(T, COMSIG_TURF_ROOF_ADDED, roof_data)
	return .

/datum/element/roof/Detach(datum/source, force)
	var/turf/open/rimworld/T = source
	if(istype(T))
		T.remove_roof_effects(roof_data)
		REMOVE_TRAIT(T, TRAIT_HAS_ROOF, REF(src))
		SEND_SIGNAL(T, COMSIG_TURF_ROOF_REMOVED, roof_data)

	UnregisterSignal(source, list(
		COMSIG_ATOM_EXAMINE,
		COMSIG_TURF_ROOF_SUPPORT_CHECK,
		COMSIG_TURF_ROOF_COLLAPSE,
		COMSIG_ATOM_ROOF_SUPPORT_LOST
	))
	roof_data = null
	return ..()

/datum/element/roof/proc/on_examine(datum/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	examine_list += span_notice("There is a roof above: <b>[roof_data.name]</b>.")
	examine_list += span_notice("[roof_data.desc]")

/datum/element/roof/proc/check_support(turf/open/rimworld/T)
	if(!T || !roof_data)
		return FALSE
	for(var/turf/closed/rw_wall/neighbor in RANGE_TURFS(roof_data.max_support_distance, T))
		if(neighbor.is_roof_support_provider())
			return TRUE
	return FALSE

/datum/element/roof/proc/on_support_check(datum/source)
	SIGNAL_HANDLER
	return check_support(source)

/datum/element/roof/proc/on_support_lost(datum/source)
	SIGNAL_HANDLER
	var/turf/open/rimworld/T = source
	if(!check_support(T))
		on_collapse(T)

/datum/element/roof/proc/on_collapse(datum/source)
	SIGNAL_HANDLER
	var/turf/open/rimworld/T = source
	if(!T || !roof_data)
		return

	T.visible_message(span_userdanger("The roof above [T] collapses!"))
	// playsound(T, 'sound/effects/collapse.ogg', 80, TRUE)

	for(var/mob/living/L in T)
		L.take_bodypart_damage(brute = roof_data.collapse_damage)
		L.Paralyze(4 SECONDS)
		to_chat(L, span_userdanger("The roof collapses on top of you!"))

	for(var/obj/structure/S in T)
		S.take_damage(roof_data.collapse_damage, BRUTE)

	if(roof_data.collapse_debris_type)
		new roof_data.collapse_debris_type(T)

	T.RemoveElement(/datum/element/roof, roof_data)

// MARK: Implementation
/turf/open/rimworld/proc/set_roof(datum/turf_roof/roof_path)
	var/datum/turf_roof/R = get_roof_datum(roof_path)
	if(!R)
		return FALSE

	RemoveElement(/datum/element/roof)

	AddElement(/datum/element/roof, R)
	return TRUE

/turf/open/rimworld/proc/remove_roof(silent = FALSE)
	if(!HAS_TRAIT(src, TRAIT_HAS_ROOF))
		return FALSE
	if(!silent)
		visible_message(span_notice("The roof above [src] has been dismantled."))
	RemoveElement(/datum/element/roof)
	return TRUE

/turf/proc/has_roof()
	return HAS_TRAIT(src, TRAIT_HAS_ROOF)

/turf/open/rimworld/proc/apply_roof_effects(datum/turf_roof/roof)
	INVOKE_ASYNC(SSdaylight, TYPE_PROC_REF(/datum/controller/subsystem/daylight, refresh_turf_daylight), src)
	return TRUE

/turf/open/rimworld/proc/remove_roof_effects(datum/turf_roof/roof)
	INVOKE_ASYNC(SSdaylight, TYPE_PROC_REF(/datum/controller/subsystem/daylight, refresh_turf_daylight), src)
	return TRUE
