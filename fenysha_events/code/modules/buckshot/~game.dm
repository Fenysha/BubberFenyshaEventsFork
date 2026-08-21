#define TIME_TO_TURN (1 MINUTES)
#define SHOOT_RESULT_LIVE "live"
#define SHOOT_RESULT_BLANK "blank"

/datum/buckshot_roulette_party
	// Уникальное айди этой партии
	var/id
	// Список всех текущих игроков партии
	VAR_PRIVATE/list/players
	// Все игровые места, что задействованны в партии (weakrefs)
	VAR_PRIVATE/list/chairs
	// weakref на дробовик
	VAR_FINAL/datum/weakref/shotgun_weakref
	// weakref на игровой стол
	VAR_FINAL/datum/weakref/table_weakref
	// На каком раунде происходит обрезание системы жизнеобеспечения
	VAR_FINAL/death_round_teshoold = 3
	// Сколько предметов может иметь игрок на руках, как максимум
	VAR_FINAL/max_items_per_player = 8
	// Стартовала ли игра
	var/game_started = FALSE
	// Может ли игрок свобдно выойти из игры
	var/can_free_exit = FALSE
	// Список игроков, ожидающих начала игры
	var/awaiting_players = list()
	// Идёт ли регистрация игроков
	var/registration = FALSE
	// Должен ли стол озвучивать правила в начале игры
	var/should_say_rules = TRUE
	var/static/list/rules = list(
		"1. Каждый ход дробовик заряжается боевыми и холостыми патронами в случайном порядке.",
		"2. Участвующие по очереди стреляют либо в себя, либо в другого игрока.",
		"3. Если при выстреле в себя патрон был холостым - игрок продолжает ход.",
		"4. В случае смерти игрок будет воскрешён системой жизнеобеспечения, но только пока у игрока есть дополнительные заряды.",
		"5. Побеждает последний оставшийся в живых игрок.",
	)

	// Список игрок с ключами по именам
	var/list/player_by_names = list() // assoc list(mob/living/carbon/human => string)
	/* Переменные относящиеся к процессу игры*/

	// Текущий раунд игры
	var/round = 0
	// Является ли текущий раунд последним
	var/is_last_round = FALSE
	// Начался ли текущий раунд
	var/round_started = FALSE
	// Время начала текущего хода
	var/current_turn_start_time = 0
	// Текущий игрок, который делает ход
	var/current_turn_player = null
	// Последний игрок, который сделал ход
	var/last_turn_player = null
	// Идет ли передача хода
	var/turn_transition_in_progress = FALSE
	// Время за которое игрок должен сделать ход
	var/turn_time = TIME_TO_TURN
	// Количество совршенных ходов в этом раунде
	var/turns = 0

	// Список всех созданных коробок с предметами, чтобы потом их удалить
	var/list/created_item_boxes = list()
	// Все предметы розданные игрой
	var/list/all_items
	// Предметы собранные по игрокам ключам
	var/list/items_by_players = list() // assoc list(mob/living/carbon/human => list(obj/item))

	// Идет ли загрузка патронов в дробовик
	var/loading_ammo = FALSE
	// Обьявлены ли типы патронов
	var/ammo_declared = FALSE
	// Стоит ли игра на паузе
	var/pause = FALSE
	// Ожидается завершение выстрела (таймер after_player_shoot)
	var/shoot_pending = FALSE

/datum/buckshot_roulette_party/New(obj/structure/table/game_table)
	. = ..()
	table_weakref = WEAKREF(game_table)
	id = generate_uuid()
	detect_game_objects()

/datum/buckshot_roulette_party/proc/detect_game_objects()
	chairs = list()
	var/obj/structure/table/table = table_weakref?.resolve()
	if(!table)
		return
	for(var/obj/structure/chair/buckshot/chair_instance in orange(2, table))
		if(!chair_instance.party)
			var/datum/weakref/chair_weakref = WEAKREF(chair_instance)
			chairs += chair_weakref
			chair_instance.party = src

/datum/buckshot_roulette_party/proc/generate_uuid()
	return "[num2hex(rand(0,65535),4)]-[num2hex(rand(0,65535),4)]-[num2hex(rand(0,65535),4)]"


/datum/buckshot_roulette_party/proc/attempt_start_game(mob/user)
	if(game_started)
		return
	if(registration)
		to_chat(user, span_warning("Идёт регистрация игроков, подожди немного."))
		return
	if(length(awaiting_players))
		to_chat(user, span_warning("Идёт регистрация других игроков, подожди немного."))
		return
	awaiting_players = detect_candidates(user)
	if(length((awaiting_players)) < 2)
		to_chat(user, span_warning("Недостаточно игроков для начала партии."))
		awaiting_players = null
		return

	var/ask = tgui_alert(user, "Начать партию buckshot Roulette?", "Начать партию?", list("Да", "Нет"))
	if(ask != "Да")
		awaiting_players = null
		return

	can_free_exit = FALSE
	registration = TRUE
	for(var/mob/living/carbon/human/player in awaiting_players)
		var/obj/structure/crt_mechanims/ctr = get_ctr_for_player(player)
		player.AddComponent(/datum/component/buckshot_roulette_participant, src, ctr)
	addtimer(CALLBACK(src, PROC_REF(check_ready), TRUE), 2 MINUTES)

/datum/buckshot_roulette_party/proc/detect_candidates(mob/user)
	if(game_started)
		return
	if(!length(chairs))
		detect_game_objects()
	var/list/to_register = list()
	for(var/datum/weakref/chair_weakref in chairs)
		var/obj/structure/chair/buckshot/chair_instance = chair_weakref?.resolve()
		if(!chair_instance)
			continue
		var/mob/living/carbon/human/player = chair_instance.get_current_player()
		if(!player)
			continue
		if(!can_be_participant(player))
			continue
		to_register += player
	return to_register

/datum/buckshot_roulette_party/proc/can_be_participant(mob/living/carbon/human/player)
	if(WEAKREF(player) in players)
		return FALSE
	if(!ishuman(player))
		return FALSE
	// Проверка клиента
	if(HAS_TRAIT(player, TRAIT_PACIFISM))
		return FALSE
	return TRUE

/datum/buckshot_roulette_party/proc/check_ready(force_start = FALSE)
	if(game_started)
		return
	// Проверка, что все игроки зарегистрированы
	for(var/datum/weakref/chair_weakref in chairs)
		var/obj/structure/chair/buckshot/chair_instance = chair_weakref?.resolve()
		if(!chair_instance)
			continue
		var/mob/living/carbon/human/player = chair_instance.get_current_player()
		if(!player)
			continue
		var/found = FALSE
		for(var/datum/weakref/player_ref in players)
			var/mob/living/carbon/human/existing_player = player_ref?.resolve()
			var/datum/component/buckshot_roulette_participant/participant = existing_player?.GetComponent(/datum/component/buckshot_roulette_participant)
			if(!participant)
				continue
			if(participant.player == player)
				found = TRUE
				break
		if(!found && !force_start)
			return

	awaiting_players = null
	registration = FALSE
	// Все игроки зарегистрированы, стартуем игру
	INVOKE_ASYNC(src, PROC_REF(start_game))


/datum/buckshot_roulette_party/proc/register_player(mob/living/carbon/human/player, name)
	// Проверка на уникальность имени
	for(var/datum/weakref/player_ref in players)
		var/mob/living/carbon/human/existing_player = player_ref?.resolve()
		var/datum/component/buckshot_roulette_participant/participant = existing_player?.GetComponent(/datum/component/buckshot_roulette_participant)
		if(!participant)
			continue
		if(!participant.player)
			continue
		if(participant.player != player && participant.player_name == name)
			to_chat(player, span_warning("Игрок с таким именем уже в этой партии! Выбери другое имя."))
			return FALSE

	LAZYADD(players, WEAKREF(player))
	player_by_names[player] = name
	to_chat(player, span_notice("Ты успешно зарегистрирован в партии!"))
	check_ready()
	return TRUE

/datum/buckshot_roulette_party/proc/is_participant(mob/living/carbon/human/player)
	if(!ishuman(player))
		return FALSE
	for(var/datum/weakref/player_ref in players)
		var/mob/living/carbon/human/existing_player = player_ref?.resolve()
		if(existing_player == player)
			return TRUE
	return FALSE

/datum/buckshot_roulette_party/proc/start_game()
	if(game_started)
		return
	var/obj/structure/table/table = table_weakref?.resolve()
	if(!table)
		return
	playsound(table, 'fenysha_events/sounds/effects/buckshot/defib_bootup.ogg', 50, 1)
	if(should_say_rules)
		for(var/rule in rules)
			table.say(rule)
			sleep(3 SECONDS)
		sleep(3 SECONDS)
	next_round()
	game_started = TRUE
	SEND_SIGNAL(src, COMSIG_BUCKSHOT_GAME_STARTED, rules)
	START_PROCESSING(SSobj, src)

/datum/buckshot_roulette_party/proc/end_game()
	if(!game_started)
		return
	STOP_PROCESSING(SSobj, src)
	var/obj/structure/table/table = table_weakref?.resolve()
	var/list/survivors = list()
	for(var/datum/weakref/player_ref in players)
		var/mob/living/carbon/human/player = player_ref?.resolve()
		var/datum/component/buckshot_roulette_participant/participant = player?.GetComponent(/datum/component/buckshot_roulette_participant)
		if(participant && !participant.player_completely_dead())
			survivors += player
	SEND_SIGNAL(src, COMSIG_BUCKSHOT_GAME_ENDED)
	game_started = FALSE
	can_free_exit = TRUE
	return_shotgun_to_table()
	clean_items()
	clean_shells()

	var/obj/item/gun/ballistic/shotgun/buckshot_game/shotgun = shotgun_weakref?.resolve()
	if(shotgun)
		qdel(shotgun)
	shotgun_weakref = null
	if(table)
		if(length(survivors) == 1)
			table.say("[player_by_names[survivors[1]]] побеждает!")
			playsound(get_turf(table), 'fenysha_events/sounds/effects/buckshot/winner.ogg', 50, 1)
		else if(!length(survivors))
			table.say("Никто не выжил. Игра окончена без победителя.")

	player_by_names = list()
	players = list()
	last_turn_player = null
	current_turn_player = null
	current_turn_start_time = 0
	round = 0
	is_last_round = FALSE
	shoot_pending = FALSE
	pause = FALSE

/datum/buckshot_roulette_party/proc/get_players()
	var/list/to_return = list()
	for(var/datum/weakref/player_ref in players)
		var/mob/living/carbon/human/player = player_ref?.resolve()
		if(player)
			to_return += player
	return to_return

/* ПРОЦЕСС ИГРЫ */

/datum/buckshot_roulette_party/proc/create_shotgun()
	var/obj/structure/table/table = table_weakref?.resolve()
	if(!table)
		return null
	var/obj/item/gun/ballistic/shotgun/buckshot_game/shotgun = new(get_turf(table), src)
	shotgun_weakref = WEAKREF(shotgun)
	return shotgun


/datum/buckshot_roulette_party/proc/get_ctr_for_player(mob/living/carbon/human/player)
	var/obj/structure/table/buckshot/table = table_weakref?.resolve()
	if(!table)
		return null
	return table.get_ctr_for_player(player)

/datum/buckshot_roulette_party/proc/get_shotgun()
	if(!shotgun_weakref)
		return create_shotgun()
	return shotgun_weakref?.resolve()

/datum/buckshot_roulette_party/proc/load_ammo()
	ammo_declared = FALSE
	loading_ammo = TRUE
	var/obj/structure/table/buckshot/table = table_weakref?.resolve()
	var/obj/item/gun/ballistic/shotgun/buckshot_game/shotgun = get_shotgun()
	return_shotgun_to_table()
	table.on_shotgun_begin_reload(shotgun)

	var/base = clamp(length(players) + 1, 4, 8)
	var/extra = min(round, 4)
	var/total_ammo = clamp(base + extra, 4, 8)

	var/live_shell = rand(max(1, total_ammo - 4), total_ammo - 2)
	var/blank_shell = total_ammo - live_shell
	if(total_ammo == 1)
		live_shell = 1

	if(shotgun)
		shotgun.load_rounds(live_shell, blank_shell)
	if(table)
		table.say("[live_shell] боев[live_shell != 1 ? "ых" : "ой"] и [blank_shell] холос[blank_shell != 1 ? "тых" : "той"].")
	table.on_shotgun_reloaded(shotgun)
	sleep(1 SECONDS)
	ammo_declared = TRUE
	loading_ammo = FALSE
	if(current_turn_player)
		table.move_shotgun_to_player(shotgun, current_turn_player)

/datum/buckshot_roulette_party/proc/shotgun_has_ammo(obj/item/gun/ballistic/shotgun/buckshot_game/shotgun)
	if(!shotgun)
		return FALSE
	if(shotgun.chambered && is_type_in_typecache(shotgun.chambered, GLOB.buckshot_shell_typecache))
		return TRUE
	for(var/obj/item/ammo_casing/casing in shotgun.chambers)
		if(is_type_in_typecache(casing, GLOB.buckshot_shell_typecache))
			return TRUE
	return FALSE

/datum/buckshot_roulette_party/proc/ammo_depleted()
	if(!ammo_declared || shoot_pending)
		return FALSE
	var/obj/item/gun/ballistic/shotgun/buckshot_game/shotgun = get_shotgun()
	return !shotgun_has_ammo(shotgun)

/datum/buckshot_roulette_party/proc/any_awaiting_revival()
	for(var/datum/weakref/player_ref in players)
		var/mob/living/carbon/human/player = player_ref?.resolve()
		if(!player || player.stat != DEAD)
			continue
		var/datum/component/buckshot_roulette_participant/participant = player.GetComponent(/datum/component/buckshot_roulette_participant)
		if(participant?.lives > 0 && !participant.has_died_in_party)
			return TRUE
	return FALSE

/datum/buckshot_roulette_party/proc/can_advance_game_state()
	if(shoot_pending || turn_transition_in_progress || loading_ammo)
		return FALSE
	if(any_awaiting_revival())
		return FALSE
	return TRUE

/datum/buckshot_roulette_party/proc/return_shotgun_to_table()
	var/obj/structure/table/buckshot/table = table_weakref?.resolve()
	if(!table)
		return
	var/obj/item/gun/ballistic/shotgun/buckshot_game/shotgun = get_shotgun()
	if(!shotgun)
		return
	if(istype(shotgun.loc, /mob/living/carbon/human))
		var/mob/living/carbon/human/holder = shotgun.loc
		holder.drop_all_held_items()
	shotgun.forceMove(get_turf(table))
	table.on_shotgun_return_to_table(shotgun)


/datum/buckshot_roulette_party/proc/pick_next_player()
	if(!length(players))
		return null

	// Если никто ещё не ходил — начинаем с первого живого
	if(!last_turn_player)
		for(var/datum/weakref/ref in players)
			var/mob/living/carbon/human/candidate = ref.resolve()
			var/datum/component/buckshot_roulette_participant/P = candidate?.GetComponent(/datum/component/buckshot_roulette_participant)
			if(P && P.can_perform_turn())
				return candidate

	// Иначе ищем следующего живого игрока по кругу
	var/start_idx = players.Find(WEAKREF(last_turn_player))
	if(start_idx == 0) // текущий игрок уже удалён из списка или не найден
		start_idx = length(players)

	for(var/i in 1 to length(players))
		var/idx = (start_idx + i - 1) % length(players) + 1 // +1 потому что список с 1
		var/datum/weakref/ref = players[idx]
		var/mob/living/carbon/human/candidate = ref?.resolve()
		if(!candidate)
			continue

		var/datum/component/buckshot_roulette_participant/P = candidate.GetComponent(/datum/component/buckshot_roulette_participant)
		if(P && P.can_perform_turn())
			return candidate
	return null

/datum/buckshot_roulette_party/proc/start_next_turn()
	if(turn_transition_in_progress || !can_advance_game_state())
		return
	turn_transition_in_progress = TRUE
	turns += 1

	return_shotgun_to_table()
	sleep(2 SECONDS)

	current_turn_player = pick_next_player()
	if((round > 1) && ((turns % 6) == 0) && turns != 0)
		give_items(TRUE, FALSE)

	if(!current_turn_player)
		turn_transition_in_progress = FALSE
		return

	last_turn_player = current_turn_player
	current_turn_start_time = world.time

	var/obj/structure/table/buckshot/table = table_weakref?.resolve()
	if(table)
		table.say("Ходит [player_by_names[current_turn_player]].")

	var/obj/item/gun/ballistic/shotgun/buckshot_game/shotgun = get_shotgun()
	if(shotgun)
		if(shotgun.shotingself)
			shotgun.shotingself = FALSE
		table.move_shotgun_to_player(shotgun, current_turn_player)

	SEND_SIGNAL(src, COMSIG_BUCKSHOT_NEXT_TURN, turns)
	turn_transition_in_progress = FALSE

/datum/buckshot_roulette_party/proc/turn_timeout()
	if(!current_turn_player)
		return FALSE
	var/elapsed_time = world.time - current_turn_start_time
	if(elapsed_time >= turn_time)
		var/obj/structure/table/table = table_weakref?.resolve()
		if(table)
			table.say("[player_by_names[current_turn_player]] не сделал выбор вовремя и пропускает ход!")
		return TRUE
	return FALSE

/datum/buckshot_roulette_party/proc/after_player_shoot(mob/living/carbon/human/player, target_player, shot_result)
	var/obj/item/gun/ballistic/shotgun/buckshot_game/shotgun = get_shotgun()
	if(shotgun)
		shotgun.rack(player)
	var/datum/component/buckshot_roulette_participant/participant = player.GetComponent(/datum/component/buckshot_roulette_participant)
	if(participant)
		if(shot_result == SHOOT_RESULT_BLANK)
			handle_blank_shot(player, target_player)
		else if(shot_result == SHOOT_RESULT_LIVE)
			handle_live_shot(player, target_player)
	shoot_pending = FALSE

/datum/buckshot_roulette_party/proc/handle_blank_shot(mob/living/carbon/human/player, mob/living/carbon/human/target_player)
	if(target_player == player)
		to_chat(player, "Холостой выстрел в себя! Ты остаёшься в игре и продолжаешь ход.")
		return
	current_turn_player = null

/datum/buckshot_roulette_party/proc/handle_live_shot(mob/living/carbon/human/player, mob/living/carbon/human/target_player)
	var/datum/component/buckshot_roulette_participant/target_participant = target_player.GetComponent(/datum/component/buckshot_roulette_participant)
	if(!target_participant)
		return
	return_shotgun_to_table()
	current_turn_player = null

/datum/buckshot_roulette_party/proc/check_round_end()
	var/players_alive = 0
	for(var/datum/weakref/player_ref in players)
		var/mob/living/carbon/human/player = player_ref?.resolve()
		var/datum/component/buckshot_roulette_participant/participant = player?.GetComponent(/datum/component/buckshot_roulette_participant)
		if(!participant)
			continue
		if(!participant.player_completely_dead())
			players_alive += 1
	if(players_alive <= 1)
		return TRUE
	return FALSE

/datum/buckshot_roulette_party/proc/clean_shells()
	var/obj/structure/table/buckshot/table = table_weakref?.resolve()
	var/list/do_delete = list()
	for(var/obj/item/ammo_casing/shotgun/buckshot/casing in range(4, table))
		do_delete += casing
		casing.forceMove(get_turf(table))
	sleep(1 SECONDS)
	if(length(do_delete))
		QDEL_LIST(do_delete)

/datum/buckshot_roulette_party/proc/can_give_item_to_player(mob/living/carbon/human/player)
	if(!is_participant(player))
		return FALSE
	var/datum/component/buckshot_roulette_participant/participant = player.GetComponent(/datum/component/buckshot_roulette_participant)
	if(!participant)
		return FALSE
	if(participant.player_completely_dead())
		return FALSE
	var/list/player_items = items_by_players[player]
	if(player_items && (length(player_items) >= max_items_per_player))
		return FALSE
	return TRUE

/datum/buckshot_roulette_party/proc/item_gived(obj/item/item, mob/living/carbon/human/player)
	LAZYADD(all_items, item)
	if(!items_by_players[player])
		items_by_players[player] = list()
	LAZYADD(items_by_players[player], item)

/datum/buckshot_roulette_party/proc/give_items(announce = TRUE, initial = TRUE)
	var/players_count = length(players)
	var/items_per_player = clamp(1 * (round - 1), 2, 6)
	if(initial)
		items_per_player *= 2

	var/create_count = items_per_player * players_count
	var/obj/structure/table/buckshot/table = table_weakref?.resolve()

	if(announce)
		table.say("По [items_per_player] предмет[items_per_player > 4 ? "ов" :  "а"] каждому!")

	table.create_item_boxes(items_per_player)
	var/start_time = world.time
	while(length(created_item_boxes))
		CHECK_TICK
		if(world.time - start_time > 60 SECONDS)
			table.say("Выдача предметов завершена!")
			break
		if(length(all_items) >= create_count)
			break
	clean_item_boxes()

/datum/buckshot_roulette_party/proc/clean_item_boxes()
	if(!length(created_item_boxes))
		return
	for(var/obj/item/box in created_item_boxes)
		if(box)
			qdel(box)
	created_item_boxes = list()


/datum/buckshot_roulette_party/proc/clean_items()
	// Удаляем все выданные предметы
	QDEL_LIST(all_items)
	all_items = list()
	items_by_players = list()

/datum/buckshot_roulette_party/proc/next_round()
	round += 1
	ammo_declared = FALSE
	current_turn_player = null
	var/obj/structure/table/table = table_weakref?.resolve()
	SEND_SIGNAL(src, COMSIG_BUCKSHOT_NEXT_ROUND, is_last_round)
	sleep(3 SECONDS)
	if(table)
		if(is_last_round)
			table.say("Последний раунд! Дайте жару!")
		else
			table.say("Раунд [round] начинается!")
		playsound(table, 'fenysha_events/sounds/effects/buckshot/new_round.ogg', 50, 1)
	sleep(2 SECONDS)
	if(round > 1)
		give_items()
	sleep(2 SECONDS)
	pause = FALSE

/datum/buckshot_roulette_party/proc/end_round()
	pause = TRUE
	shoot_pending = FALSE
	turns = 0
	var/obj/structure/table/table = table_weakref?.resolve()
	return_shotgun_to_table()
	current_turn_player = null
	sleep(1 SECONDS)
	if(table)
		table.say("Чистим гильзы...")
	clean_shells()
	sleep(2 SECONDS)
	clean_items()
	if(table)
		table.say("Раунд [round] окончен!")

	sleep(1 SECONDS)
	if(is_last_round)
		end_game()
		return

	if(round >= death_round_teshoold && !is_last_round)
		if(table)
			playsound(table, 'fenysha_events/sounds/effects/buckshot/crt_turn_off.ogg', 50, 1)
			table.say("Система реанимации отключена! Следующий раунд — на вылет.")
			sleep(3 SECONDS)
		is_last_round = TRUE

	sleep(2 SECONDS)
	next_round()

/datum/buckshot_roulette_party/process(seconds_per_tick)
	if(!game_started)
		return
	if(pause || loading_ammo || turn_transition_in_progress)
		return
	if(!get_shotgun())
		create_shotgun()
	if(!ammo_declared && !loading_ammo)
		load_ammo()
		return
	if(!can_advance_game_state())
		return
	if(check_round_end())
		end_round()
		return
	if(ammo_depleted())
		load_ammo()
		return
	if((!current_turn_player || turn_timeout()) && can_advance_game_state())
		start_next_turn()


/datum/component/buckshot_roulette_participant
	// weakref на партию, в которой участвует этот игрок
	VAR_PRIVATE/datum/weakref/party_weakref
	// weakref на систему реанимации
	VAR_PRIVATE/datum/weakref/crt_weakref
	// Был ли этот игрок уже убит в текущей партии
	var/has_died_in_party = FALSE
	// Ссылка на текущего игрока
	var/mob/living/carbon/human/player
	// Имя текущего игрока
	var/player_name = ""
	// Количество очков за победу игрокв раунде
	var/srcore = 0
	// Количество жизней игрока
	var/lives = 3
	// Включена ли система реанимации для этого игрока
	var/crt_enabled = TRUE
	// Последний ли сейчас раунд
	var/last_round = FALSE


	var/static/list/forbiden_names = list(
		"ведущий",
		"администратор",
		"Модератор",
		"система",
		"бот",
		"игрок",
		"гость",
		"low3",
		"god",
		"бог",
	)
	var/static/list/dealer_names = list(
		"дилер",
		"крупье",
		"dealer",
	)


/datum/component/buckshot_roulette_participant/Initialize( \
	datum/buckshot_roulette_party/party, \
	obj/structure/crt_mechanims/crt_instance)


	if(!party || !crt_instance)
		return COMPONENT_INCOMPATIBLE
	if(!ishuman(parent))
		return COMPONENT_INCOMPATIBLE
	player = parent
	party_weakref = WEAKREF(party)
	crt_weakref = WEAKREF(crt_instance)
	crt_instance.set_participant(src)
	INVOKE_ASYNC(src, PROC_REF(register_player))

/datum/component/buckshot_roulette_participant/Destroy()
	UnregisterFromParent()
	. = ..()


/datum/component/buckshot_roulette_participant/RegisterWithParent()
	. = ..()
	var/datum/buckshot_roulette_party/party_instance = party_weakref?.resolve()
	RegisterSignal(player, COMSIG_LIVING_DEATH, PROC_REF(on_player_death), TRUE)
	RegisterSignal(party_instance, COMSIG_BUCKSHOT_GAME_STARTED, PROC_REF(on_game_start), TRUE)
	RegisterSignal(party_instance, COMSIG_BUCKSHOT_GAME_ENDED, PROC_REF(on_game_end), TRUE)
	RegisterSignal(party_instance, COMSIG_BUCKSHOT_NEXT_ROUND, PROC_REF(on_next_round), TRUE)

/datum/component/buckshot_roulette_participant/UnregisterFromParent()
	. = ..()
	var/datum/buckshot_roulette_party/party_instance = party_weakref?.resolve()
	UnregisterSignal(player, list(COMSIG_LIVING_DEATH))
	UnregisterSignal(party_instance, list(COMSIG_BUCKSHOT_GAME_STARTED, COMSIG_BUCKSHOT_GAME_ENDED, COMSIG_BUCKSHOT_NEXT_ROUND))


/datum/component/buckshot_roulette_participant/proc/generate_random_name()
	var/base = "Игрок_"
	for(var/i = 0; i < 6; i++)
		base += "[pick(GLOB.alphabet)]"
	return trimtext(base)

/datum/component/buckshot_roulette_participant/proc/register_player()
	var/datum/buckshot_roulette_party/party_instance = party_weakref?.resolve()
	if(!party_instance)
		return

	var/player_name = null
	if(player.client)
		player_name = tgui_input_text(player, "Введи имя игрока", "Регистрация", max_length = 6, timeout = 30 SECONDS)
	else
		player_name = generate_random_name()

	if(!player_name)
		return register_player()

	if(LOWER_TEXT(player_name) in forbiden_names)
		to_chat(player, span_warning("Это имя запрещено!"))
		return register_player()

	if((LOWER_TEXT(player_name) in dealer_names) && !HAS_TRAIT(player, TRAIT_BUCKSHOT_DEALER))
		to_chat(player, span_warning("Это имя уже занято!"))
		return register_player()

	if(!party_instance.register_player(player, player_name))
		var/obj/structure/crt_mechanims/crt = crt_weakref?.resolve()
		if(crt)
			crt.set_participant(src)
		CHECK_TICK
		sleep(1)
		register_player()


/datum/component/buckshot_roulette_participant/proc/can_perform_turn()
	if(player_completely_dead() || HAS_TRAIT(player, TRAIT_BUCKSHOT_SKIPTURN))
		return FALSE
	return TRUE

/datum/component/buckshot_roulette_participant/proc/player_completely_dead()
	var/datum/buckshot_roulette_party/party = party_weakref?.resolve()
	if(!party || !party.game_started)
		return TRUE
	return has_died_in_party


/datum/component/buckshot_roulette_participant/proc/on_player_death(mob/living/player, gibbed)
	SIGNAL_HANDLER
	var/datum/buckshot_roulette_party/party = party_weakref?.resolve()
	var/obj/structure/crt_mechanims/crt = crt_weakref?.resolve()
	if(!party || !crt)
		return

	if(lives <= 0)
		has_died_in_party = TRUE
		crt.say("[player_name] — ВЫБЫЛ!")
		to_chat(player, span_userdanger("Ты мёртв. Игра для тебя окончена."))
		return

	var/obj/item/gun/ballistic/shotgun/buckshot_game/shotgun = party.get_shotgun()
	if(shotgun && shotgun.sawed_off)
		lives -= 2
	else
		lives -= 1

	lives = max(0, lives)
	crt.update_icon_state()
	playsound(crt, 'fenysha_events/sounds/effects/buckshot/defib_reduce_health.ogg', 60, TRUE)
	addtimer(CALLBACK(crt, TYPE_PROC_REF(/obj/structure/crt_mechanims, revive_player)), 2 SECONDS)

/datum/component/buckshot_roulette_participant/proc/on_next_round(datum/buckshot_roulette_party/party, death_round)
	SIGNAL_HANDLER
	lives = 3
	has_died_in_party = FALSE
	var/obj/structure/crt_mechanims/crt_instance = crt_weakref?.resolve()
	if(crt_instance)
		crt_instance.update_icon_state()
		if(player.stat == DEAD && lives > 0)
			addtimer(CALLBACK(crt_instance, TYPE_PROC_REF(/obj/structure/crt_mechanims, revive_player)), 5)
	if(death_round)
		to_chat(player, span_warning("Система реанимации отключена! В этом раунде ты не сможешь вернуться к жизни после смерти!"))

/datum/component/buckshot_roulette_participant/proc/on_game_start(/datum/buckshot_roulette_party/party, rules)
	SIGNAL_HANDLER
	ADD_TRAIT(parent, TRAIT_BUCKSHOT_PLAYER, INNATE_TRAIT)
	to_chat(player, span_big("Игра началась! У тебя [lives] жизн[lives == 1 ? "ь" : "ей"]."))
	SEND_SOUND(player, 'fenysha_events/sounds/effects/buckshot/crt_display_health.ogg')


/datum/component/buckshot_roulette_participant/proc/add_lives(num, silent = FALSE)
	if(!crt_enabled)
		return
	lives += num
	var/obj/structure/crt_mechanims/crt_instance = crt_weakref?.resolve()
	if(crt_instance)
		crt_instance.update_icon_state()
	if(!silent)
		to_chat(player, span_notice("Тебе добавлено [num] жизн[lives == 1 ? "ь" : "ей"]. У тебя теперь [lives] жизн[lives == 1 ? "ь" : "ей"]."))

/datum/component/buckshot_roulette_participant/proc/on_game_end()
	SIGNAL_HANDLER
	if(HAS_TRAIT(player, TRAIT_BUCKSHOT_PLAYER))
		REMOVE_TRAIT(player, TRAIT_BUCKSHOT_PLAYER, INNATE_TRAIT)
	Destroy()


/datum/component/buckshot_roulette_participant/proc/get_crt_charges()
	return lives > 0 ? lives : 0
