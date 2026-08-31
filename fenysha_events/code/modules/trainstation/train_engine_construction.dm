// Construction, research and part handling for the train's steam turbine.
//
// The turbine ships assembled on the train template, so none of this ran before: the parts had no
// circuit board, could not be deconstructed, and a part built next to the core never linked to it.
// Mirrors /obj/machinery/power/turbine, minus its directional part scan - the train core locates its
// neighbours anywhere in orange(1), so a rebuild does not have to reproduce the original layout.

// ====================================================================
// Circuit boards
// ====================================================================

/obj/item/circuitboard/machine/train_turbine_compressor
	name = "Train Turbine - Inlet Compressor"
	greyscale_colors = CIRCUIT_COLOR_ENGINEERING
	build_path = /obj/machinery/power/train_turbine/inlet_compressor
	req_components = list(
		/obj/item/stack/cable_coil = 5,
		/obj/item/stack/sheet/iron = 5,
		/obj/item/turbine_parts/compressor = 1,
	)

/obj/item/circuitboard/machine/train_turbine_rotor
	name = "Train Turbine - Core Rotor"
	greyscale_colors = CIRCUIT_COLOR_ENGINEERING
	build_path = /obj/machinery/power/train_turbine/core_rotor
	req_components = list(
		/obj/item/stack/cable_coil = 5,
		/obj/item/stack/sheet/iron = 5,
		/obj/item/turbine_parts/rotor = 1,
	)

/obj/item/circuitboard/machine/train_turbine_stator
	name = "Train Turbine - Outlet Stator"
	greyscale_colors = CIRCUIT_COLOR_ENGINEERING
	build_path = /obj/machinery/power/train_turbine/turbine_outlet
	req_components = list(
		/obj/item/stack/cable_coil = 5,
		/obj/item/stack/sheet/iron = 5,
		/obj/item/turbine_parts/stator = 1,
	)

/obj/item/circuitboard/machine/train_heater
	name = "Train Plasma Heater"
	greyscale_colors = CIRCUIT_COLOR_ENGINEERING
	build_path = /obj/machinery/plumbing/train_heater
	req_components = list(
		/obj/item/stack/cable_coil = 5,
		/obj/item/stack/sheet/iron = 5,
	)

/obj/item/circuitboard/computer/train_turbine_computer
	name = "Train Turbine Control Console"
	greyscale_colors = CIRCUIT_COLOR_ENGINEERING
	build_path = /obj/machinery/computer/train_turbine_computer

// ====================================================================
// Research
// ====================================================================

/datum/design/board/train_turbine_compressor
	name = "Train Turbine Compressor Board"
	desc = "The circuit board for a train turbine inlet compressor."
	id = "train_turbine_compressor"
	build_path = /obj/item/circuitboard/machine/train_turbine_compressor
	category = list(
		RND_CATEGORY_MACHINE + RND_SUBCATEGORY_MACHINE_ATMOS
	)
	departmental_flags = DEPARTMENT_BITFLAG_ENGINEERING

/datum/design/board/train_turbine_rotor
	name = "Train Turbine Rotor Board"
	desc = "The circuit board for a train turbine core rotor."
	id = "train_turbine_rotor"
	build_path = /obj/item/circuitboard/machine/train_turbine_rotor
	category = list(
		RND_CATEGORY_MACHINE + RND_SUBCATEGORY_MACHINE_ATMOS
	)
	departmental_flags = DEPARTMENT_BITFLAG_ENGINEERING

/datum/design/board/train_turbine_stator
	name = "Train Turbine Stator Board"
	desc = "The circuit board for a train turbine outlet stator."
	id = "train_turbine_stator"
	build_path = /obj/item/circuitboard/machine/train_turbine_stator
	category = list(
		RND_CATEGORY_MACHINE + RND_SUBCATEGORY_MACHINE_ATMOS
	)
	departmental_flags = DEPARTMENT_BITFLAG_ENGINEERING

/datum/design/board/train_turbine_console
	name = "Train Turbine Console Board"
	desc = "The circuit board for a train turbine control console."
	id = "train_turbine_console"
	build_path = /obj/item/circuitboard/computer/train_turbine_computer
	category = list(
		RND_CATEGORY_MACHINE + RND_SUBCATEGORY_MACHINE_ATMOS
	)
	departmental_flags = DEPARTMENT_BITFLAG_ENGINEERING

/datum/design/board/train_heater
	name = "Train Plasma Heater Board"
	desc = "The circuit board for a train plasma heater."
	id = "train_heater"
	build_path = /obj/item/circuitboard/machine/train_heater
	category = list(
		RND_CATEGORY_MACHINE + RND_SUBCATEGORY_MACHINE_ATMOS
	)
	departmental_flags = DEPARTMENT_BITFLAG_ENGINEERING

/// The turbine is the train's only power source, so the boards for it and the heater that feeds it
/// have to be printable before any research happens - a crew that blows it up on the first stop
/// cannot research their way back.
/// Atmospherics is a starting node. Injected in New() rather than Initialize(): SSresearch calls
/// Initialize() over the previous node list, which is empty on the only run, so it never fires.
/datum/techweb_node/atmos/New()
	. = ..()
	design_ids += list(
		"train_turbine_compressor",
		"train_turbine_rotor",
		"train_turbine_stator",
		"train_turbine_console",
		"train_heater",
	)

// ====================================================================
// Deconstruction and part handling
// ====================================================================

/// The core this part belongs to, whether or not it is currently linked. Falls back to a scan so a
/// part that was just built - and so has never been linked by anything - can still find its core.
/obj/machinery/power/train_turbine/proc/find_rotor()
	var/obj/machinery/power/train_turbine/core_rotor/found = rotor
	if(!QDELETED(found))
		return found
	found = locate() in orange(1, src)
	return found

/obj/machinery/power/train_turbine/core_rotor/find_rotor()
	return src

/// Re-runs the core's part scan. activate_parts() re-locates unconditionally, so this is safe to call
/// on a running turbine - it will not drop a working link.
/obj/machinery/power/train_turbine/proc/relink_turbine(mob/user)
	var/obj/machinery/power/train_turbine/core_rotor/core = find_rotor()
	if(QDELETED(core))
		return FALSE
	return core.activate_parts(user)

/obj/machinery/power/train_turbine/post_machine_initialize()
	. = ..()
	relink_turbine()

/obj/machinery/power/train_turbine/add_context(atom/source, list/context, obj/item/held_item, mob/user)
	if(isnull(held_item))
		return NONE

	if(panel_open && istype(held_item, part_path))
		context[SCREENTIP_CONTEXT_LMB] = "[installed_part ? "Replace" : "Install"] part"
		return CONTEXTUAL_SCREENTIP_SET

	switch(held_item.tool_behaviour)
		if(TOOL_SCREWDRIVER)
			context[SCREENTIP_CONTEXT_LMB] = "[panel_open ? "Close" : "Open"] panel"
			return CONTEXTUAL_SCREENTIP_SET
		if(TOOL_WRENCH)
			if(panel_open)
				context[SCREENTIP_CONTEXT_LMB] = "Rotate"
				return CONTEXTUAL_SCREENTIP_SET
		if(TOOL_CROWBAR)
			if(installed_part)
				context[SCREENTIP_CONTEXT_RMB] = "Remove part"
			if(panel_open)
				context[SCREENTIP_CONTEXT_LMB] = "Deconstruct"
			return CONTEXTUAL_SCREENTIP_SET

	return NONE

/obj/machinery/power/train_turbine/examine(mob/user)
	. = ..()
	if(installed_part)
		. += span_notice("A tier [installed_part.current_tier] part is installed.")
	else if(panel_open)
		. += span_warning("It has no upgrade part installed, and runs at base efficiency.")
	if(panel_open)
		. += span_notice("It can be rotated with a [EXAMINE_HINT("wrench")], or pried apart with a [EXAMINE_HINT("crowbar")].")

/obj/machinery/power/train_turbine/screwdriver_act(mob/living/user, obj/item/tool)
	. = ITEM_INTERACT_BLOCKING
	if(is_active())
		balloon_alert(user, "turn it off first!")
		return
	tool.play_tool_sound(src, 50)
	toggle_panel_open()
	// An open panel is a disassembled machine as far as the core is concerned; closing it re-links.
	if(panel_open)
		find_rotor()?.deactivate_parts()
	else
		relink_turbine(user)
	update_appearance(UPDATE_OVERLAYS)
	return ITEM_INTERACT_SUCCESS

/obj/machinery/power/train_turbine/wrench_act(mob/living/user, obj/item/tool)
	. = ITEM_INTERACT_BLOCKING
	if(is_active())
		balloon_alert(user, "turn it off first!")
		return
	if(default_change_direction_wrench(user, tool))
		relink_turbine(user)
		return ITEM_INTERACT_SUCCESS

/obj/machinery/power/train_turbine/crowbar_act(mob/living/user, obj/item/tool)
	return default_deconstruction_crowbar(user, tool)

/// Pulls the upgrade part back out, so one salvaged from a wrecked turbine can go into its replacement.
/obj/machinery/power/train_turbine/crowbar_act_secondary(mob/living/user, obj/item/tool)
	. = ITEM_INTERACT_BLOCKING
	if(!panel_open)
		balloon_alert(user, "open the panel first!")
		return
	if(!installed_part)
		balloon_alert(user, "no part installed!")
		return
	if(is_active())
		balloon_alert(user, "turn it off first!")
		return
	user.put_in_hands(installed_part)
	balloon_alert(user, "part removed")
	// max_temperature / max_rpm / efficiency are only recomputed by the core's scan.
	relink_turbine(user)
	return ITEM_INTERACT_SUCCESS

/obj/machinery/power/train_turbine/item_interaction(mob/living/user, obj/item/turbine_parts/tool, list/modifiers)
	. = NONE
	if(!istype(tool, part_path))
		return
	if(is_active())
		balloon_alert(user, "turn it off first!")
		return ITEM_INTERACT_BLOCKING
	if(!panel_open)
		balloon_alert(user, "open the panel first!")
		return ITEM_INTERACT_BLOCKING
	if(!do_after(user, 2 SECONDS, src))
		return ITEM_INTERACT_BLOCKING

	if(installed_part)
		user.put_in_hands(installed_part)
		balloon_alert(user, "part replaced")
	else
		balloon_alert(user, "part installed")
	user.transferItemToLoc(tool, src)
	installed_part = tool
	efficiency = installed_part.get_tier_value(TURBINE_MAX_EFFICIENCY) || efficiency
	// Re-scan so an upgraded tier raises max_temperature and max_rpm straight away, rather than on
	// whatever next happens to relink the turbine.
	relink_turbine(user)
	return ITEM_INTERACT_SUCCESS

/// Keeps the reference honest however the part leaves - crowbar, deconstruction or a stray forceMove.
/obj/machinery/power/train_turbine/Exited(atom/movable/gone, direction)
	. = ..()
	if(gone == installed_part)
		installed_part = null
		efficiency = initial(efficiency)

/// Drop the upgrade part rather than deleting it with the machine, and drop the core's stale links.
/obj/machinery/power/train_turbine/on_deconstruction(disassembled)
	installed_part?.forceMove(loc)
	find_rotor()?.deactivate_parts()
	return ..()
