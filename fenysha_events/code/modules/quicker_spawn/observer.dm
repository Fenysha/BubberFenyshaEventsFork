#define IC_SPAWN_BST   "Bluespace Tech"
#define IC_SPAWN_NAKED "Naked"

/datum/outfit/ic_spawn_naked
	name = "Ic naked"

/mob/dead/observer
	/// Target currently selected for the quick-spawn radial menu.
	var/mob/quick_spawn_target

	/// TRUE while the quick-spawn radial menu is active.
	///
	/// A second CtrlClick on quick_spawn_target immediately performs
	/// an Admin spawn.
	var/quick_spawn_active = FALSE


/mob/dead/observer/CtrlClickOn(mob/target)
	if(!isobserver(target))
		return

	if(!check_rights(R_SPAWN, FALSE))
		return

	/*
	 * The first click stores the target and opens the radial menu.
	 *
	 * If the player CtrlClicks the same target again while the
	 * quick-spawn state is active, skip everything and spawn as
	 * Admin immediately.
	 */
	if(quick_spawn_active && quick_spawn_target == target)
		quick_spawn_active = FALSE
		quick_spawn_target = null

		quickicspawn_admin(target, src)
		return
	quick_spawn_active = TRUE
	quick_spawn_target = target
	INVOKE_ASYNC(src, PROC_REF(open_quick_spawn_menu), target)


/mob/dead/observer/proc/open_quick_spawn_menu(
	mob/target
)
	/*
	 * Don't do anything if the target was changed/cancelled
	 * while the menu was opening.
	 */
	if(!quick_spawn_active || quick_spawn_target != target)
		return

	var/list/options = list(
		"Bluespace Tech",
		"Admin",
		"Naked",
	)

	var/selection = show_radial_menu(
		src,
		target,
		options,
		require_near = FALSE,
	)

	/*
	 * The player may have used the double-CtrlClick shortcut
	 * while this menu was open.
	 *
	 * In that case Admin spawn has already happened and this
	 * menu result must be ignored.
	 */
	if(!quick_spawn_active || quick_spawn_target != target)
		return

	/*
	 * The menu was closed/selected normally.
	 */
	quick_spawn_active = FALSE
	quick_spawn_target = null

	if(!selection)
		return

	switch(selection)
		if("Bluespace Tech")
			quickicspawn(
				target,
				src,
				IC_SPAWN_BST,
			)

		if("Admin")
			quickicspawn_admin(
				target,
				src,
			)

		if("Naked")
			quickicspawn(
				target,
				src,
				IC_SPAWN_NAKED,
			)


/mob/dead/observer/proc/quickicspawn_admin(
	mob/target,
	mob/user
)
	if(!target || !user)
		return

	if(!isobserver(target))
		return

	if(!check_rights(R_SPAWN, FALSE))
		return

	var/turf/current_turf = get_turf(target)

	if(!current_turf)
		return

	/*
	 * Create directly on the observer's tile.
	 */
	var/mob/living/carbon/human/new_player = new(current_turf)

	/*
	 * Copy the selected character.
	 */
	new_player.name = target.name
	new_player.real_name = target.real_name

	target.client?.prefs.safe_transfer_prefs_to(new_player)

	new_player.dna.update_dna_identity()

	/*
	 * Admin outfit only.
	 *
	 * This outfit itself grants noclip.
	 */
	new_player.equipOutfit(
		/datum/outfit/ss_construct/admin
	)
	SSfactions.add_member(
		"admin",
		new_player,
	)
	/*
	 * Transfer the mind/key exactly like the normal
	 * quick-spawn implementation.
	 */
	if(target.mind)
		target.mind.transfer_to(
			new_player,
			TRUE,
		)
	else
		new_player.key = target.key
	qdel(target)


/mob/dead/observer/quickicspawn(
	mob/target,
	mob/user,
	spawn_mode = IC_SPAWN_BST
)
	if(!target || !user)
		return

	if(!isobserver(target))
		return

	if(!check_rights(R_SPAWN, FALSE))
		return

	var/turf/current_turf = get_turf(target)

	if(!current_turf)
		return

	var/is_naked = spawn_mode == IC_SPAWN_NAKED


	var/teleport_option

	var/list/teleport_options = list(
		"Bluespace",
		"Pod",
		"Cancel",
	)

	var/pod_style

	var/static/list/pod_styles

	teleport_option = tgui_alert(
		user,
		"How would you like to be spawned in?",
		"IC Quick Spawn",
		teleport_options,
	)

	if(!teleport_option)
		return

	if(teleport_option == "Cancel")
		return

	if(teleport_option == "Pod")
		if(!pod_styles)
			pod_styles = list()

			for(var/datum/pod_style/style as anything in typesof(/datum/pod_style))
				pod_styles[style::ui_name] = style

		var/pod_name = tgui_input_list(
			user,
			"Which style of pod?",
			"IC Quick Spawn",
			pod_styles,
		)

		if(!pod_name)
			return

		pod_style = pod_styles[pod_name]

		if(!pod_style)
			return

	var/character_option
	var/is_selected_character = FALSE

	var/list/character_options = list(
		"Selected Character",
		"Random Character",
		"Cancel",
	)

	if(!is_naked)
		character_option = tgui_alert(
			user,
			"Which character to spawn as?",
			"IC Quick Spawn",
			character_options,
		)

		if(!character_option)
			return

		if(character_option == "Cancel")
			return

		is_selected_character = character_option == "Selected Character"

	var/outfit_option

	if(is_naked)
		outfit_option = /datum/outfit/ic_spawn_naked

	else
		var/list/outfit_options = list(
			"Bluespace Tech" = /datum/outfit/admin/bst,
			"Naked" = /datum/outfit,
			"Show All" = "Show All",
		)

		var/outfit_selection = tgui_input_list(
			user,
			"Which outfit to use?",
			"IC Quick Spawn",
			outfit_options,
		)

		if(!outfit_selection)
			return

		if(outfit_selection == "Show All")
			outfit_option = user.client?.robust_dress_shop_skyrat()
		else
			outfit_option = outfit_options[outfit_selection]

		if(!outfit_option)
			return

	var/give_return

	if(target != user)
		give_return = tgui_alert(
			user,
			"Do you want to give them the power to return? Not recommended for non-admins.",
			"IC Quick Spawn",
			list("No", "Yes"),
		)

		if(!give_return)
			return

	var/give_quirks_loadout

	if(is_selected_character)
		var/list/quirk_loadout_options = list(
			"Quirks Only",
			"Loadout Only",
			"Quirks & Loadout",
			"None",
		)

		give_quirks_loadout = tgui_input_list(
			user,
			"Include quirks/loadout?",
			"IC Quick Spawn",
			quirk_loadout_options,
		)

		if(!give_quirks_loadout)
			return

	var/mob/living/carbon/human/new_player = new(current_turf)

	if(is_selected_character)
		new_player.name = target.name
		new_player.real_name = target.real_name

		target.client?.prefs.safe_transfer_prefs_to(new_player)

		new_player.dna.update_dna_identity()

	if(is_naked)
		new_player.equipOutfit(
			outfit_option,
		)

	else
		switch(give_quirks_loadout)
			if("Quirks Only")
				SSquirks.AssignQuirks(
					new_player,
					target.client,
				)

				new_player.equipOutfit(
					outfit_option,
				)

			if("Loadout Only")
				new_player.equip_outfit_and_loadout(
					outfit_option,
					target.client?.prefs,
				)

			if("Quirks & Loadout")
				SSquirks.AssignQuirks(
					new_player,
					target.client,
				)

				new_player.equip_outfit_and_loadout(
					outfit_option,
					target.client?.prefs,
				)

			else
				new_player.equipOutfit(
					outfit_option,
				)

	if(target.mind)
		target.mind.transfer_to(
			new_player,
			TRUE,
		)
	else
		new_player.key = target.key

	qdel(target)

	if(give_return == "Yes")
		var/datum/action/cooldown/spell/return_back/return_spell = new
		return_spell.Grant(new_player)


	switch(teleport_option)
		if("Bluespace")
			new_player.forceMove(current_turf)

			do_sparks(
				10,
				TRUE,
				new_player,
				spark_type = /datum/effect_system/basic/spark_spread/quantum,
			)

			playsound(
				new_player,
				'sound/effects/magic/Disable_Tech.ogg',
				100,
				FALSE,
			)

		if("Pod")
			var/obj/structure/closet/supplypod/podspawn/empty_pod = new(
				null,
				pod_style,
			)

			new_player.forceMove(empty_pod)

			new /obj/effect/pod_landingzone(
				current_turf,
				empty_pod,
			)
#undef IC_SPAWN_BST
#undef IC_SPAWN_NAKED
