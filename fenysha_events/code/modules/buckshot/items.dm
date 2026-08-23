#define ITEM_TARGET_ITEM "item"
#define ITEM_TARGET_MOB "mob"
#define ITEM_TARGET_SHOTGUN "shotgun"

/obj/item/buckshot_game
	name = "buckshot game item"
	// Description of the item used in the game
	var/use_desc = "This item is used to manage a game of buckshot roulette."
	// Owner of the item
	var/mob/living/carbon/human/owner_player = null
	// Party this item is linked to
	var/datum/buckshot_roulette_party/party = null
	// Can the item be used on a dead player
	var/use_on_death = FALSE
	// Target type for this item
	var/potential_target = ITEM_TARGET_MOB
	// Can the item be stolen
	var/can_be_stolen = TRUE
	// Sound played when using the item
	var/use_sound
	// Time required to use the item
	var/use_time = 3 SECONDS
	// Message broadcast when using the item
	// %user% - player using the item
	// %item% - the item being used
	// %itemtarget% - target of the item (player or shotgun)
	var/use_text = "%user% uses %item% on %itemtarget%"

	w_class = WEIGHT_CLASS_HUGE
	obj_flags = INDESTRUCTIBLE | BOMB_PROOF | LAVA_PROOF | FIRE_PROOF
	VAR_PROTECTED/using = FALSE

/obj/item/buckshot_game/Initialize(mapload, mob/living/carbon/human/owner, datum/buckshot_roulette_party/party_instance)
	. = ..()
	owner_player = owner
	party = party_instance

/obj/item/buckshot_game/examine(mob/user)
	. = ..()
	. += "\n" + span_notice(use_desc)
	. += "\n" + span_notice(get_target_desc())

/obj/item/buckshot_game/proc/get_target_desc()
	switch(potential_target)
		if(ITEM_TARGET_MOB)
			return "Used on yourself or other players!"
		if(ITEM_TARGET_SHOTGUN)
			return "Used on the shotgun."
	return "Unknown target."

/obj/item/buckshot_game/proc/get_use_text(mob/living/user, atom/target)
	var/final_string = use_text
	final_string = replacetext(final_string, "%user%", user)
	final_string = replacetext(final_string, "%item%", src)
	final_string = replacetext(final_string, "%itemtarget%", target)

	return final_string

/obj/item/buckshot_game/attempt_pickup(mob/living/user, skip_grav)
	. = ..()
	if(!party)
		return FALSE
	if(party.game_started)
		return FALSE
	if(user != owner_player)
		to_chat(user, span_warning("This is not your item!"))
		return FALSE

/obj/item/buckshot_game/ranged_interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(!ishuman(interacting_with) && !istype(interacting_with, /obj/item/buckshot_game) && !istype(interacting_with, /obj/item/gun/ballistic/shotgun/buckshot_game))
		return ..()

	attempt_use_on(interacting_with, user)
	return ITEM_INTERACT_SUCCESS

/obj/item/buckshot_game/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(!ishuman(interacting_with) && !istype(interacting_with, /obj/item/buckshot_game) && !istype(interacting_with, /obj/item/gun/ballistic/shotgun/buckshot_game))
		return ..()

	attempt_use_on(interacting_with, user)
	return ITEM_INTERACT_SUCCESS

/obj/item/buckshot_game/proc/is_valid_target(atom/target, mob/living/user)
	return TRUE

/obj/item/buckshot_game/proc/attempt_use_on(atom/target, mob/living/user, del_on_fail = FALSE)
	if(using)
		return

	var/able_to_use = TRUE

	if(!party || !party.game_started)
		to_chat(user, span_warning("The game has not started yet!"))
		able_to_use = FALSE
	if(user != owner_player)
		to_chat(user, span_warning("This is not your item!"))
		able_to_use = FALSE
	if(party && party.current_turn_player != user)
		to_chat(user, span_warning("It is not your turn!"))
		able_to_use = FALSE
	if(!is_valid_target(target, user))
		able_to_use = FALSE

	if(!able_to_use)
		if(del_on_fail)
			qdel(src)
		return

	if(istype(target, /mob/living/carbon/human) && potential_target == ITEM_TARGET_MOB)
		var/mob/living/carbon/human/player = target
		if(!party.is_participant(player))
			to_chat(user, span_warning("This player is not participating in the game!"))
			return
		if(player.stat == DEAD && !use_on_death)
			to_chat(user, span_warning("You cannot use this item on a dead player!"))
			return

		using = TRUE
		if(use_sound)
			playsound(src, use_sound, 50, 1)
		if(use_text)
			var/final_use_text = get_use_text(user, target)
			user.balloon_alert_to_viewers(final_use_text)
		if(!do_after(user, use_time))
			using = FALSE
			if(del_on_fail)
				qdel(src)
			return

		if(player == user)
			use_on_self(player)
		else
			use_on_other(user, player)

	if(istype(target, /obj/item/buckshot_game) && potential_target == ITEM_TARGET_ITEM)
		using = TRUE
		if(use_sound)
			playsound(src, use_sound, 50, 1)
		if(use_text)
			var/final_use_text = get_use_text(user, target)
			user.balloon_alert_to_viewers(final_use_text)
		if(!do_after(user, use_time))
			using = FALSE
			if(del_on_fail)
				qdel(src)
			return

		var/obj/item/buckshot_game/other_item = target
		use_on_item(other_item, user)
		return TRUE

	if(istype(target, /obj/item/gun/ballistic/shotgun/buckshot_game) && potential_target == ITEM_TARGET_SHOTGUN)
		using = TRUE
		if(use_sound)
			playsound(src, use_sound, 50, 1)
		if(use_text)
			var/final_use_text = get_use_text(user, target)
			user.balloon_alert_to_viewers(final_use_text)

		if(!do_after(user, use_time))
			using = FALSE
			if(del_on_fail)
				qdel(src)
			return

		use_on_shotgun(target, user)

/obj/item/buckshot_game/proc/use_on_other(mob/living/carbon/human/player, mob/living/carbon/human/other_player)
	return

/obj/item/buckshot_game/proc/use_on_self(mob/living/carbon/human/player)
	return

/obj/item/buckshot_game/proc/use_on_shotgun(obj/item/gun/ballistic/shotgun/buckshot_game/gun, mob/living/carbon/human/player)
	return

/obj/item/buckshot_game/proc/use_on_item(obj/item/buckshot_game/other_item, mob/living/carbon/human/player)
	return


/obj/item/buckshot_game/cigarettes
	name = "premium cigarettes"
	desc = "A pack of cigarettes."
	icon = 'icons/obj/cigarettes.dmi'
	icon_state = "robust"
	use_desc = "Restores one charge to the CRT mechanism."

	use_sound = 'fenysha_events/sounds/effects/buckshot/item_cigarettes.ogg'
	use_text = "%user% smokes a cigarette."
	use_time = 4 SECONDS
	potential_target = ITEM_TARGET_MOB

/obj/item/buckshot_game/cigarettes/is_valid_target(atom/target, mob/living/user)
	if(!ishuman(target))
		return FALSE
	if(target != user)
		return FALSE
	var/mob/living/carbon/human/player = target
	var/datum/component/buckshot_roulette_participant/participant = player.GetComponent(/datum/component/buckshot_roulette_participant)
	if(!participant)
		to_chat(player, span_warning("You are not participating in the game!"))
		return FALSE
	if(participant.lives >= 3)
		to_chat(player, span_warning("You already have maximum lives!"))
		return FALSE
	return TRUE

/obj/item/buckshot_game/cigarettes/use_on_self(mob/living/carbon/human/player)
	var/datum/component/buckshot_roulette_participant/participant = player.GetComponent(/datum/component/buckshot_roulette_participant)
	if(participant)
		participant.add_lives(1)
	qdel(src)


/obj/item/buckshot_game/glass
	name = "magnifying glass"
	desc = "A magnifying glass."
	use_desc = "Allows you to inspect the current round chambered in the shotgun."
	icon = 'modular_skyrat/modules/primitive_production/icons/prim_fun.dmi'
	icon_state = "magnifying_glass"

	use_text = "%user% uses a magnifying glass to check the chambered round."
	use_sound = 'fenysha_events/sounds/effects/buckshot/item_magnifier.ogg'
	use_time = 4 SECONDS
	potential_target = ITEM_TARGET_SHOTGUN

/obj/item/buckshot_game/glass/is_valid_target(atom/target, mob/living/user)
	if(!istype(target, /obj/item/gun/ballistic/shotgun/buckshot_game))
		return FALSE
	var/obj/item/gun/ballistic/shotgun/buckshot_game/gun = target
	if(!gun.chambered)
		to_chat(user, span_warning("There is no round in the chamber!"))
		return FALSE
	return TRUE

/obj/item/buckshot_game/glass/use_on_shotgun(obj/item/gun/ballistic/shotgun/buckshot_game/gun, mob/living/carbon/human/player)
	var/obj/item/ammo_casing/shotgun/buckshot/round = gun.chambered
	var/msg = "The chambered round is "
	if(istype(round, /obj/item/ammo_casing/shotgun/buckshot/live))
		msg += "a live shell."
	else if(istype(round, /obj/item/ammo_casing/shotgun/buckshot/blank))
		msg += "a blank shell."
	else
		msg += "an unknown shell."
	to_chat(player, span_notice(msg))
	qdel(src)


/obj/item/buckshot_game/beer
	name = "space beer"
	desc = "Canned beer. In space."
	icon = 'icons/obj/drinks/soda.dmi'
	icon_state = "space_beer"
	use_desc = "Racks the shotgun action to rack out the current round."

	use_sound = 'fenysha_events/sounds/effects/buckshot/item_beer.ogg'
	use_text = "%user% drinks a beer and racks the shotgun action."
	use_time = 5 SECONDS
	potential_target = ITEM_TARGET_SHOTGUN

/obj/item/buckshot_game/beer/use_on_shotgun(obj/item/gun/ballistic/shotgun/buckshot_game/gun, mob/living/carbon/human/player)
	gun.rack(player)
	qdel(src)


/obj/item/buckshot_game/saw
	name = "hand saw"
	desc = "A hand saw."
	icon_state = "bonesaw"
	icon = 'modular_skyrat/modules/exp_corps/icons/bonesaw.dmi'
	lefthand_file = 'icons/mob/inhands/weapons/swords_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/swords_righthand.dmi'
	worn_icon_state = "knife"

	use_desc = "Saws off the shotgun barrel, doubling the damage of the next shot!"
	use_sound = 'fenysha_events/sounds/effects/buckshot/handsaw.ogg'
	use_text = "%user% uses a saw to shorten the shotgun barrel."
	use_time = 4 SECONDS
	potential_target = ITEM_TARGET_SHOTGUN

/obj/item/buckshot_game/saw/is_valid_target(atom/target, mob/living/user)
	if(!istype(target, /obj/item/gun/ballistic/shotgun/buckshot_game))
		return FALSE
	var/obj/item/gun/ballistic/shotgun/buckshot_game/gun = target
	if(gun.sawed_off)
		to_chat(user, span_warning("The shotgun is already sawed-off!"))
		return FALSE
	return TRUE

/obj/item/buckshot_game/saw/use_on_shotgun(obj/item/gun/ballistic/shotgun/buckshot_game/gun, mob/living/carbon/human/player)
	gun.saw_off(player)
	qdel(src)


/obj/item/restraints/handcuffs/buckshot_game
	breakouttime = 2 MINUTES
	var/turns_spend = 0

	var/datum/buckshot_roulette_party/party
	var/mob/living/carbon/human/player

	item_flags = DROPDEL | SKIP_FANTASY_ON_SPAWN | ABSTRACT

/obj/item/restraints/handcuffs/buckshot_game/Destroy(force)
	playsound(get_turf(src), 'fenysha_events/sounds/effects/buckshot/handcuffs_off.ogg', 50, 1)
	if(player)
		REMOVE_TRAIT(player, TRAIT_BUCKSHOT_SKIPTURN, REF(src))
		to_chat(player, span_notice("You are freed from the handcuffs!"))
	if(party)
		UnregisterSignal(party, COMSIG_BUCKSHOT_NEXT_TURN)
	. = ..()

/obj/item/restraints/handcuffs/buckshot_game/proc/apply(mob/living/carbon/target)
	target.equip_to_slot(src, ITEM_SLOT_HANDCUFFED)
	SEND_SIGNAL(target, COMSIG_MOB_HANDCUFFED)

	player = target
	ADD_TRAIT(player, TRAIT_BUCKSHOT_SKIPTURN, REF(src))
	if(party)
		RegisterSignal(party, COMSIG_BUCKSHOT_NEXT_TURN, PROC_REF(on_next_turn))
	addtimer(CALLBACK(src, PROC_REF(release)), breakouttime)

/obj/item/restraints/handcuffs/buckshot_game/proc/release()
	if(player)
		player.dropItemToGround(src, TRUE, TRUE, FALSE)
		player.set_handcuffed(null)
		player.update_handcuffed()

/obj/item/restraints/handcuffs/buckshot_game/proc/on_next_turn()
	SIGNAL_HANDLER
	release()


/obj/item/buckshot_game/handcuffs
	name = "handcuffs"
	desc = "A pair of handcuffs."
	icon_state = "handcuff"
	worn_icon_state = "handcuff"
	inhand_icon_state = "handcuff"
	icon = 'icons/obj/weapons/restraints.dmi'
	lefthand_file = 'icons/mob/inhands/equipment/security_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/security_righthand.dmi'
	use_desc = "Apply to a player to force them to skip their next turn!"

	potential_target = ITEM_TARGET_MOB
	use_sound = 'fenysha_events/sounds/effects/buckshot/handcuffs.ogg'
	use_text = "%user% puts handcuffs on %itemtarget%, forcing them to skip their next turn."
	use_time = 3 SECONDS
	can_be_stolen = FALSE

/obj/item/buckshot_game/handcuffs/is_valid_target(atom/target, mob/living/user)
	if(!ishuman(target))
		return FALSE
	if(target == user)
		return FALSE
	var/mob/living/carbon/human/player = target
	if(!party.is_participant(player))
		to_chat(user, span_warning("This player is not participating in the game!"))
		return FALSE
	if(player.stat == DEAD)
		to_chat(user, span_warning("You cannot use handcuffs on a dead player!"))
		return FALSE
	if(HAS_TRAIT(player, TRAIT_BUCKSHOT_SKIPTURN))
		to_chat(user, span_warning("This player is already handcuffed!"))
		return FALSE
	var/datum/component/buckshot_roulette_participant/participant = player.GetComponent(/datum/component/buckshot_roulette_participant)
	if(participant && participant.player_completely_dead())
		to_chat(user, span_warning("You cannot use handcuffs on an eliminated player!"))
		return FALSE
	return TRUE

/obj/item/buckshot_game/handcuffs/use_on_other(mob/living/carbon/human/player, mob/living/carbon/human/other_player)
	var/obj/item/restraints/handcuffs/buckshot_game/handcuffs = new(other_player)
	handcuffs.party = src.party
	handcuffs.apply(other_player)
	qdel(src)


/obj/item/buckshot_game/adrenaline
	name = "adrenaline medipen"
	desc = "A medipen filled with adrenaline."
	icon = 'modular_skyrat/modules/deforest_medical_items/icons/injectors.dmi'
	base_icon_state = "adrenaline"
	icon_state = "adrenaline"
	use_desc = "Allows you to steal and immediately use another player's item."
	use_text = "%user% injects adrenaline and steals an item."
	use_sound = 'fenysha_events/sounds/effects/buckshot/adrenaline.ogg'
	use_time = 2 SECONDS
	potential_target = ITEM_TARGET_ITEM
	can_be_stolen = FALSE

/obj/item/buckshot_game/adrenaline/is_valid_target(atom/target, mob/living/user)
	if(!istype(target, /obj/item/buckshot_game))
		return FALSE

	var/obj/item/buckshot_game/other_item = target
	if(other_item.owner_player == user)
		to_chat(user, span_warning("You cannot steal your own item with adrenaline!"))
		return FALSE
	if(!other_item.can_be_stolen)
		to_chat(user, span_warning("This item cannot be stolen with adrenaline!"))
		return FALSE
	if(!other_item.owner_player)
		to_chat(user, span_warning("This item does not belong to a player!"))
		return FALSE

	return TRUE

/obj/item/buckshot_game/adrenaline/use_on_item(obj/item/buckshot_game/other_item, mob/living/carbon/human/player)
	if(QDELETED(other_item) || !party)
		return

	other_item.owner_player = player
	player.adjust_drunk_effect(10)

	var/turf/current = get_turf(other_item)
	var/turf/target_turf = get_turf(player)
	while(current && current != target_turf)
		var/turf/next_step = get_step_towards(current, target_turf)
		if(!next_step)
			break
		other_item.forceMove(next_step)
		current = next_step
		sleep(0.2 SECONDS)

	player.put_in_hands(other_item, TRUE)
	if(QDELETED(other_item))
		return

	switch(other_item.potential_target)
		if(ITEM_TARGET_MOB)
			other_item.attempt_use_on(player, player, TRUE)
		if(ITEM_TARGET_SHOTGUN)
			var/obj/item/gun/ballistic/shotgun/buckshot_game/gun = party.get_shotgun()
			if(gun)
				other_item.attempt_use_on(gun, player, TRUE)

	qdel(src)


/obj/item/buckshot_game/inverter
	name = "inverter"
	desc = "A strange device that inverts the state of the chambered round."
	icon = 'icons/obj/devices/syndie_gadget.dmi'
	icon_state = "desynchronizer"
	inhand_icon_state = "electronic"

	use_desc = "Swaps the chambered shotgun round to its opposite type."
	use_text = "%user% uses the inverter on the shotgun chamber, altering the shell."
	use_sound = 'fenysha_events/sounds/effects/buckshot/inverter.ogg'
	use_time = 4 SECONDS
	potential_target = ITEM_TARGET_SHOTGUN

/obj/item/buckshot_game/inverter/is_valid_target(atom/target, mob/living/user)
	if(!istype(target, /obj/item/gun/ballistic/shotgun/buckshot_game))
		return FALSE
	var/obj/item/gun/ballistic/shotgun/buckshot_game/gun = target
	if(!gun.chambered)
		to_chat(user, span_warning("There is no round in the chamber!"))
		return FALSE
	return TRUE

/obj/item/buckshot_game/inverter/use_on_shotgun(obj/item/gun/ballistic/shotgun/buckshot_game/gun, mob/living/carbon/human/player)
	if(!gun.chambered)
		return

	var/obj/item/ammo_casing/shotgun/buckshot/old_round = gun.chambered

	if(istype(old_round, /obj/item/ammo_casing/shotgun/buckshot/live))
		gun.chambered = new /obj/item/ammo_casing/shotgun/buckshot/blank(gun)
	else if(istype(old_round, /obj/item/ammo_casing/shotgun/buckshot/blank))
		gun.chambered = new /obj/item/ammo_casing/shotgun/buckshot/live(gun)
	else
		return

	QDEL_NULL(old_round)
	qdel(src)


/obj/item/buckshot_game/burner_phone
	name = "burner phone"
	desc = "A cheap disposable phone."
	icon = 'icons/obj/antags/syndicate_tools.dmi'
	icon_state = "suspiciousphone"

	use_desc = "Reveals information about a random shell inside the shotgun."
	use_sound = 'fenysha_events/sounds/effects/buckshot/item_phone.ogg'
	use_text = "%user% uses a burner phone to inspect the shotgun shells."
	use_time = 7 SECONDS
	potential_target = ITEM_TARGET_SHOTGUN

/obj/item/buckshot_game/burner_phone/is_valid_target(atom/target, mob/living/user)
	if(!istype(target, /obj/item/gun/ballistic/shotgun/buckshot_game))
		return FALSE

	var/obj/item/gun/ballistic/shotgun/buckshot_game/gun = target
	var/rounds_left = (gun.chambered ? 1 : 0) + length(gun.chambers)

	if(rounds_left < 2)
		to_chat(user, span_warning("How unfortunate..."))
		return FALSE

	return TRUE

/obj/item/buckshot_game/burner_phone/use_on_shotgun(obj/item/gun/ballistic/shotgun/buckshot_game/gun, mob/living/carbon/human/player)
	var/list/all_rounds = list()

	if(gun.chambered)
		all_rounds += gun.chambered
	if(length(gun.chambers))
		all_rounds += gun.chambers

	if(!length(all_rounds))
		to_chat(player, span_warning("How unfortunate..."))
		return

	var/index = rand(1, length(all_rounds))
	var/obj/item/ammo_casing/shotgun/buckshot/round = all_rounds[index]

	var/location_text = ""
	if(index == 1)
		location_text = "in the current chamber"
	else
		location_text = "at position [index] in the magazine"

	var/type_text = ""
	if(istype(round, /obj/item/ammo_casing/shotgun/buckshot/live))
		type_text = "live shell"
	else if(istype(round, /obj/item/ammo_casing/shotgun/buckshot/blank))
		type_text = "blank shell"
	else
		type_text = "unknown shell"

	to_chat(player, span_notice("The phone reveals: [location_text], [type_text]."))
	qdel(src)


/obj/item/buckshot_game/expired_medicine
	name = "expired medicine"
	desc = "A questionable medical injector."
	icon = 'modular_skyrat/modules/deforest_medical_items/icons/stack_items.dmi'
	base_icon_state = "synth_patch"
	icon_state = "synth_patch"
	use_desc = "50/50 chance: Grants 2 charges or removes 1 charge. Removes life fatally if on the last charge."
	use_sound = 'fenysha_events/sounds/effects/buckshot/item_medicine.ogg'
	use_text = "%user% uses expired medicine."
	use_time = 4.5 SECONDS
	potential_target = ITEM_TARGET_MOB

/obj/item/buckshot_game/expired_medicine/is_valid_target(atom/target, mob/living/user)
	if(!ishuman(target))
		return FALSE
	if(target != user)
		to_chat(user, span_warning("This medicine can only be used on yourself!"))
		return FALSE

	var/mob/living/carbon/human/player = target
	var/datum/component/buckshot_roulette_participant/participant = player.GetComponent(/datum/component/buckshot_roulette_participant)
	if(!participant)
		to_chat(user, span_warning("You are not participating in the game!"))
		return FALSE

	return TRUE

/obj/item/buckshot_game/expired_medicine/use_on_self(mob/living/carbon/human/player)
	var/datum/component/buckshot_roulette_participant/participant = player.GetComponent(/datum/component/buckshot_roulette_participant)
	if(!participant)
		return
	sleep(1.5 SECONDS)

	if(prob(50))
		participant.add_lives(2)
		to_chat(player, span_notice("The medicine worked. You gained 2 charges."))
	else
		playsound(get_turf(player), 'fenysha_events/sounds/effects/buckshot/death_medicine.ogg', 100, 1)

		if(participant.lives <= 0)
			to_chat(player, span_warning("The medicine was lethal. You are eliminated from the game!"))
			player.death()
			if(party)
				party.start_next_turn()
		else
			participant.add_lives(-1, TRUE)
			to_chat(player, span_warning("The medicine was expired. You lost 1 charge."))

	qdel(src)
