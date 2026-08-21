#define ITEM_TARGET_ITEM "item"
#define ITEM_TARGET_MOB "mob"
#define ITEM_TARGET_SHOTGUN "shotgun"

/obj/item/buckshot_game
	name = "buckshot game item"
	// Описание предмета для игры
	var/use_desc = "This item is used to manage a game of buckshot roulette."
	// Владелец предмета
	var/mob/living/carbon/human/owner_player = null
	// Пати к которой привязан предмет
	var/datum/buckshot_roulette_party/party = null
	// Можно ли применить предмет к мертому игроку
	var/use_on_death = FALSE
	// Цель применения этого предмета
	var/potential_target = ITEM_TARGET_MOB
	// Может ли предмет быть украден
	var/can_be_stolen = TRUE
	// Звук при использовании предмета
	var/use_sound
	// Время для использования предмета
	var/use_time = 3 SECONDS
	// Текст при использовании предмета
	// %user% - игрок, который использует предмет
	// %item% - используемый предмет
	// %itemtarget% - цель использования (игрок или дробовик)
	var/use_text = "%user% использует %item% на %itemtarget%"

	w_class = WEIGHT_CLASS_HUGE
	obj_flags = INDESTRUCTIBLE|BOMB_PROOF|LAVA_PROOF|FIRE_PROOF
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
			return "Используется на себе или других игроках!"
		if(ITEM_TARGET_SHOTGUN)
			return "Используется на дробовике."
	return "Неизвестная цель."

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
		to_chat(user, span_warning("Это не твой предмет!"))
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

	if(!party.game_started)
		to_chat(user, span_warning("Игра еще не началась!"))
		able_to_use = FALSE
	if(user != owner_player)
		to_chat(user, span_warning("Это не твой предмет!"))
		able_to_use = FALSE
	if(party.current_turn_player != user)
		to_chat(user, span_warning("Сейчас не твой ход!"))
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
			to_chat(user, span_warning("Этот игрок не участвует в игре!"))
			return
		if(player.stat == DEAD && !use_on_death)
			to_chat(user, span_warning("Нельзя использовать предмет на мертвого игрока!"))
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
	use_desc = "Восстанавливают один заряд CRT механизма."

	use_sound = 'fenysha_events/sounds/effects/buckshot/item_cigarettes.ogg'
	use_text = "%user% выкуривает сигарету."
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
		to_chat(player, span_warning("Вы не участвуете в игре!"))
		return FALSE
	if(participant.lives >= 3)
		to_chat(player, span_warning("У вас уже максимальное количество жизней!"))
		return FALSE
	return TRUE

/obj/item/buckshot_game/cigarettes/use_on_self(mob/living/carbon/human/player)
	var/datum/component/buckshot_roulette_participant/participant = player.GetComponent(/datum/component/buckshot_roulette_participant)
	if(participant)
		participant.add_lives(1)
	qdel(src)


/obj/item/buckshot_game/glass
	name = "Magnifying glass"
	desc = "A Magnifying glass."
	use_desc = "Позволяет проверить какой патрон заряжен в пробовике."
	icon = 'modular_skyrat/modules/primitive_production/icons/prim_fun.dmi'
	icon_state = "magnifying_glass"

	use_text = "%user% использует лупу, чтобы проверить патрон в дробовике."
	use_sound = 'fenysha_events/sounds/effects/buckshot/item_magnifier.ogg'
	use_time = 4 SECONDS
	potential_target = ITEM_TARGET_SHOTGUN

/obj/item/buckshot_game/glass/is_valid_target(atom/target, mob/living/user)
	if(!istype(target, /obj/item/gun/ballistic/shotgun/buckshot_game))
		return FALSE
	var/obj/item/gun/ballistic/shotgun/buckshot_game/gun = target
	if(!gun.chambered)
		to_chat(user, span_warning("В пробовике нет патрона!"))
		return FALSE
	return TRUE

/obj/item/buckshot_game/glass/use_on_shotgun(obj/item/gun/ballistic/shotgun/buckshot_game/gun, mob/living/carbon/human/player)
	var/obj/item/ammo_casing/shotgun/buckshot/round = gun.chambered
	var/msg = "В дробовике заряжен "
	if(istype(round, /obj/item/ammo_casing/shotgun/buckshot/live))
		msg += "боевой патрон."
	else if(istype(round, /obj/item/ammo_casing/shotgun/buckshot/blank))
		msg += "холостой патрон."
	else
		msg += "неизвестный патрон."
	to_chat(player, span_notice(msg))
	qdel(src)


/obj/item/buckshot_game/beer
	name = "space beer"
	desc = "Canned beer. In space."
	icon = 'icons/obj/drinks/soda.dmi'
	icon_state = "space_beer"
	use_desc = "Позволяет передергнуть затвор дробовика."

	use_sound = 'fenysha_events/sounds/effects/buckshot/item_beer.ogg'
	use_text = "%user% использует пиво, чтобы передернуть затвор дробовика."
	use_time = 5 SECONDS
	potential_target = ITEM_TARGET_SHOTGUN

/obj/item/buckshot_game/beer/use_on_shotgun(obj/item/gun/ballistic/shotgun/buckshot_game/gun, mob/living/carbon/human/player)
	gun.rack(player)
	qdel(src)

/obj/item/buckshot_game/saw
	name = "hand saw"
	desc = "A hand saw."
	icon = 'icons/obj/weapons/sword.dmi'
	icon_state = "tanto"
	inhand_icon_state = "tantohand"
	lefthand_file = 'icons/mob/inhands/weapons/swords_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/swords_righthand.dmi'
	worn_icon_state = "knife"

	use_desc = "Позволяет отрезать ствол дробовика, двойной урон!"
	use_sound = 'fenysha_events/sounds/effects/buckshot/handsaw.ogg'
	use_text = "%user% использует пилу, чтобы отрезать ствол дробовика."
	use_time = 4 SECONDS
	potential_target = ITEM_TARGET_SHOTGUN

/obj/item/buckshot_game/saw/is_valid_target(atom/target, mob/living/user)
	if(!istype(target, /obj/item/gun/ballistic/shotgun/buckshot_game))
		return FALSE
	var/obj/item/gun/ballistic/shotgun/buckshot_game/gun = target
	if(gun.sawed_off)
		to_chat(user, span_warning("Дробовик уже отрезан!"))
		return FALSE
	return TRUE

/obj/item/buckshot_game/saw/use_on_shotgun(obj/item/gun/ballistic/shotgun/buckshot_game/gun, mob/living/carbon/human/player, del_on_fail)
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
	REMOVE_TRAIT(player, TRAIT_BUCKSHOT_SKIPTURN, REF(src))
	to_chat(player, span_notice("Вы освобождены от наручников!"))
	UnregisterSignal(party, COMSIG_BUCKSHOT_NEXT_TURN)
	. = ..()

/obj/item/restraints/handcuffs/buckshot_game/proc/apply(mob/living/carbon/target)
	target.equip_to_slot(src, ITEM_SLOT_HANDCUFFED)
	SEND_SIGNAL(target, COMSIG_MOB_HANDCUFFED)

	player = target
	ADD_TRAIT(player, TRAIT_BUCKSHOT_SKIPTURN, REF(src))
	RegisterSignal(party, COMSIG_BUCKSHOT_NEXT_TURN, PROC_REF(on_next_turn))
	addtimer(CALLBACK(src, PROC_REF(release)), breakouttime)

/obj/item/restraints/handcuffs/buckshot_game/proc/release()
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
	use_desc = "Одень на игрока, чтобы заставить его пропустить следующий ход!"

	potential_target = ITEM_TARGET_MOB
	use_sound = 'fenysha_events/sounds/effects/buckshot/handcuffs.ogg'
	use_text = "%user% надевает наручники на %itemtarget%, заставляя его пропустить следующий ход."
	use_time = 3 SECONDS
	can_be_stolen = FALSE

/obj/item/buckshot_game/handcuffs/is_valid_target(atom/target, mob/living/user)
	if(!ishuman(target))
		return FALSE
	if(target == user)
		return FALSE
	var/mob/living/carbon/human/player = target
	if(!party.is_participant(player))
		to_chat(user, span_warning("Этот игрок не участвует в игре!"))
		return FALSE
	if(player.stat == DEAD)
		to_chat(user, span_warning("Нельзя использовать наручники на мертвого игрока!"))
		return FALSE
	if(HAS_TRAIT(player, TRAIT_BUCKSHOT_SKIPTURN))
		to_chat(user, span_warning("Этот игрок уже в наручниках!"))
		return FALSE
	var/datum/component/buckshot_roulette_participant/participant = player.GetComponent(/datum/component/buckshot_roulette_participant)
	if(participant.player_completely_dead())
		to_chat(user, span_warning("Нельзя использовать наручники на игрока, который выбыл!"))
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
	use_desc = "Позволяет украсть и сразу использовать предмет у другого игрока."
	use_text = "%user% вводит адреналин и забирает чужой предмет."
	use_sound = 'fenysha_events/sounds/effects/buckshot/adrenaline.ogg'
	use_time = 2 SECONDS
	potential_target = ITEM_TARGET_ITEM
	can_be_stolen = FALSE

/obj/item/buckshot_game/adrenaline/is_valid_target(atom/target, mob/living/user)
	if(!istype(target, /obj/item/buckshot_game))
		return FALSE

	var/obj/item/buckshot_game/other_item = target
	if(other_item.owner_player == user)
		to_chat(user, span_warning("Нельзя украсть свой предмет адреналином!"))
		return FALSE
	if(!other_item.can_be_stolen)
		to_chat(user, span_warning("Этот предмет нельзя украсть адреналином!"))
		return FALSE
	if(!other_item.owner_player)
		to_chat(user, span_warning("Этот предмет не принадлежит игроку!"))
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
	desc = "A strange device that seems to invert the effects of items."
	icon = 'icons/obj/devices/syndie_gadget.dmi'
	icon_state = "desynchronizer"
	inhand_icon_state = "electronic"

	use_desc = "Меняет тип патрона заряженного в дробовике на противоположный."
	use_text = "%user% использует инвертер на патроннике меняя тип заряженного патрона."
	use_sound = 'fenysha_events/sounds/effects/buckshot/inverter.ogg'
	use_time = 4 SECONDS
	potential_target = ITEM_TARGET_SHOTGUN


/obj/item/buckshot_game/inverter/is_valid_target(atom/target, mob/living/user)
	if(!istype(target, /obj/item/gun/ballistic/shotgun/buckshot_game))
		return FALSE
	var/obj/item/gun/ballistic/shotgun/buckshot_game/gun = target
	if(!gun.chambered)
		to_chat(user, span_warning("В пробовике нет патрона!"))
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

	use_desc = "Показывает случайный патрон в дробовике."
	use_sound = 'fenysha_events/sounds/effects/buckshot/item_phone.ogg'
	use_text = "%user% использует телефон, чтобы проверить патроны в дробовике."
	use_time = 7 SECONDS
	potential_target = ITEM_TARGET_SHOTGUN

/obj/item/buckshot_game/burner_phone/is_valid_target(atom/target, mob/living/user)
	if(!istype(target, /obj/item/gun/ballistic/shotgun/buckshot_game))
		return FALSE

	var/obj/item/gun/ballistic/shotgun/buckshot_game/gun = target
	var/rounds_left = (gun.chambered ? 1 : 0) + length(gun.chambers)

	if(rounds_left < 2)
		to_chat(user, span_warning("Как печально..."))
		return FALSE

	return TRUE


/obj/item/buckshot_game/burner_phone/use_on_shotgun(obj/item/gun/ballistic/shotgun/buckshot_game/gun, mob/living/carbon/human/player)
	var/list/all_rounds = list()

	if(gun.chambered)
		all_rounds += gun.chambered
	if(length(gun.chambers))
		all_rounds += gun.chambers

	if(!length(all_rounds))
		to_chat(player, span_warning("Как печально..."))
		return

	var/index = rand(1, length(all_rounds))
	var/obj/item/ammo_casing/shotgun/buckshot/round = all_rounds[index]

	var/location_text = ""
	if(index == 1)
		location_text = "в текущем патроннике"
	else
		location_text = "в [index]-м патроне магазина"

	var/type_text = ""
	if(istype(round, /obj/item/ammo_casing/shotgun/buckshot/live))
		type_text = "боевой"
	else if(istype(round, /obj/item/ammo_casing/shotgun/buckshot/blank))
		type_text = "холостой"
	else
		type_text = "неизвестный"

	to_chat(player, span_notice("Телефон показывает: [location_text], [type_text] патрон."))
	qdel(src)

/obj/item/buckshot_game/expired_medicine
	name = "expired medicine"
	desc = "A questionable medical injector."
	icon = 'modular_skyrat/modules/deforest_medical_items/icons/stack_items.dmi'
	base_icon_state = "synth_patch"
	icon_state = "synth_patch"
	use_desc = "50/50: либо даёт 2 заряда, либо забирает 1. Если забирает последнюю жизнь - эффект смертелен."
	use_sound = 'fenysha_events/sounds/effects/buckshot/item_medicine.ogg'
	use_text = "%user% использует просроченное лекарство."
	use_time = 4.5 SECONDS
	potential_target = ITEM_TARGET_MOB

/obj/item/buckshot_game/expired_medicine/is_valid_target(atom/target, mob/living/user)
	if(!ishuman(target))
		return FALSE
	if(target != user)
		to_chat(user, span_warning("Это лекарство можно использовать только на себе!"))
		return FALSE

	var/mob/living/carbon/human/player = target
	var/datum/component/buckshot_roulette_participant/participant = player.GetComponent(/datum/component/buckshot_roulette_participant)
	if(!participant)
		to_chat(user, span_warning("Вы не участвуете в игре!"))
		return FALSE

	return TRUE

/obj/item/buckshot_game/expired_medicine/use_on_self(mob/living/carbon/human/player)
	var/datum/component/buckshot_roulette_participant/participant = player.GetComponent(/datum/component/buckshot_roulette_participant)
	if(!participant)
		return
	sleep(1.5 SECONDS)

	if(prob(50))
		participant.add_lives(2)
		to_chat(player, span_notice("Лекарство сработало. Вы получили 2 заряда."))
	else
		playsound(get_turf(player), 'fenysha_events/sounds/effects/buckshot/death_medicine.ogg', 100, 1)

		if(participant.lives <= 0)
			to_chat(player, span_warning("Лекарство оказалось смертельным. Вы выбываете из игры!"))
			player.death()
			party.start_next_turn()
		else
			participant.add_lives(-1, TRUE)
			to_chat(player, span_warning("Лекарство оказалось просроченным. Вы потеряли 1 заряд."))

	qdel(src)
