#define TIME_TO_TURN (1 MINUTES)
#define SHOOT_RESULT_LIVE "live"
#define SHOOT_RESULT_BLANK "blank"

/datum/buckshot_roulette_party
	// Unique ID for this match
	var/id
	// List of all current players in the match
	VAR_PRIVATE/list/players
	// All game chairs involved in the match (weakrefs)
	VAR_PRIVATE/list/chairs
	// weakref to the shotgun
	VAR_FINAL/datum/weakref/shotgun_weakref
	// weakref to the game table
	VAR_FINAL/datum/weakref/table_weakref
	// At which round the life support system gets cut off
	VAR_FINAL/death_round_threshold = 3
	// Maximum items a player can hold at once
	VAR_FINAL/max_items_per_player = 8
	// Has the game started
	var/game_started = FALSE
	// Can a player freely exit the game
	var/can_free_exit = FALSE
	// List of players awaiting game start
	var/awaiting_players = list()
	// Is player registration in progress
	var/registration = FALSE
	// Should the table announce the rules at start
	var/should_say_rules = TRUE
	var/static/list/rules = list(
		"1. Each turn, the shotgun is loaded with live and blank shells in random order.",
		"2. Participants take turns shooting either themselves or another player.",
		"3. If you shoot yourself with a blank shell, you get to take another turn.",
		"4. Upon death, the player will be revived by the life support system, provided they have charges left.",
		"5. The last player standing wins.",
	)

	// Player lookup list by names
	var/list/player_by_names = list() // assoc list(mob/living/carbon/human => string)
	/* Gameplay state variables */

	// Current game round
	var/round = 0
	// Is the current round the final round
	var/is_last_round = FALSE
	// Has the current round started
	var/round_started = FALSE
	// Start time of the current turn
	var/current_turn_start_time = 0
	// Current player making a move
	var/current_turn_player = null
	// Last player who made a move
	var/last_turn_player = null
	// Is turn transition currently in progress
	var/turn_transition_in_progress = FALSE
	// Time limit for a player to make a move
	var/turn_time = TIME_TO_TURN
	// Total turns made in this round
	var/turns = 0

	// List of all created item boxes to clean up later
	var/list/created_item_boxes = list()
	// All items spawned by the game
	var/list/all_items
	// Items grouped by player keys
	var/list/items_by_players = list() // assoc list(mob/living/carbon/human => list(obj/item))

	// Is ammo currently being loaded into the shotgun
	var/loading_ammo = FALSE
	// Has ammo composition been announced
	var/ammo_declared = FALSE
	// Is the game paused
	var/pause = FALSE
	// Awaiting completion of shot execution (after_player_shoot timer)
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
		to_chat(user, span_warning("Player registration in progress, please wait."))
		return
	if(length(awaiting_players))
		to_chat(user, span_warning("Registering other players, please wait."))
		return
	awaiting_players = detect_candidates(user)
	if(length((awaiting_players)) < 2)
		to_chat(user, span_warning("Not enough players to start the match."))
		awaiting_players = null
		return

	var/ask = tgui_alert(user, "Start Buckshot Roulette match?", "Start Match?", list("Yes", "No"))
	if(ask != "Yes")
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
	if(HAS_TRAIT(player, TRAIT_PACIFISM))
		return FALSE
	return TRUE

/datum/buckshot_roulette_party/proc/check_ready(force_start = FALSE)
	if(game_started)
		return
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
	INVOKE_ASYNC(src, PROC_REF(start_game))


/datum/buckshot_roulette_party/proc/register_player(mob/living/carbon/human/player, name)
	for(var/datum/weakref/player_ref in players)
		var/mob/living/carbon/human/existing_player = player_ref?.resolve()
		var/datum/component/buckshot_roulette_participant/participant = existing_player?.GetComponent(/datum/component/buckshot_roulette_participant)
		if(!participant)
			continue
		if(!participant.player)
			continue
		if(participant.player != player && participant.player_name == name)
			to_chat(player, span_warning("A player with this name is already in the match! Choose a different name."))
			return FALSE

	LAZYADD(players, WEAKREF(player))
	player_by_names[player] = name
	to_chat(player, span_notice("Successfully registered for the match!"))
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
			table.say("[player_by_names[survivors[1]]] wins!")
			playsound(get_turf(table), 'fenysha_events/sounds/effects/buckshot/winner.ogg', 50, 1)
		else if(!length(survivors))
			table.say("No survivors. Game ended without a winner.")

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

/* GAMEPLAY LOGIC */

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
		table.say("[live_shell] live and [blank_shell] blank[blank_shell != 1 ? "s" : ""].")
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

	if(!last_turn_player)
		for(var/datum/weakref/ref in players)
			var/mob/living/carbon/human/candidate = ref.resolve()
			var/datum/component/buckshot_roulette_participant/P = candidate?.GetComponent(/datum/component/buckshot_roulette_participant)
			if(P && P.can_perform_turn())
				return candidate

	var/start_idx = players.Find(WEAKREF(last_turn_player))
	if(start_idx == 0)
		start_idx = length(players)

	for(var/i in 1 to length(players))
		var/idx = (start_idx + i - 1) % length(players) + 1
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

	// Re-verify game state safety after yielding execution
	if(!game_started || pause)
		turn_transition_in_progress = FALSE
		return

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
		table.say("[player_by_names[current_turn_player]]'s turn.")

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
			table.say("[player_by_names[current_turn_player]] ran out of time and missed their turn!")
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
		to_chat(player, "Shot yourself with a blank! You stay in the game and take another turn.")
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
		table.say("[items_per_player] item[items_per_player > 1 ? "s" : ""] for everyone!")

	table.create_item_boxes(items_per_player)
	var/start_time = world.time
	while(length(created_item_boxes))
		CHECK_TICK
		if(world.time - start_time > 60 SECONDS)
			table.say("Item distribution complete!")
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
			table.say("Final round! Give it all you've got!")
		else
			table.say("Round [round] begins!")
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
		table.say("Clearing shell casings...")
	clean_shells()
	sleep(2 SECONDS)
	clean_items()
	if(table)
		table.say("Round [round] finished!")

	sleep(1 SECONDS)
	if(is_last_round)
		end_game()
		return

	if(round >= death_round_threshold && !is_last_round)
		if(table)
			playsound(table, 'fenysha_events/sounds/effects/buckshot/crt_turn_off.ogg', 50, 1)
			table.say("Revival system offline! Sudden death from the next round onwards.")
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
	// weakref to the party this player participates in
	VAR_PRIVATE/datum/weakref/party_weakref
	// weakref to the resuscitation mechanism
	VAR_PRIVATE/datum/weakref/crt_weakref
	// Has this player been killed in the current party
	var/has_died_in_party = FALSE
	// Reference to the player mob
	var/mob/living/carbon/human/player
	// Registered name of the player
	var/player_name = ""
	// Score gained for round wins
	var/score = 0
	// Remaining lives
	var/lives = 3
	// Is the revival system enabled for this participant
	var/crt_enabled = TRUE
	// Is it currently the final round
	var/last_round = FALSE


	var/static/list/forbidden_names = list(
		"host",
		"admin",
		"administrator",
		"moderator",
		"system",
		"bot",
		"player",
		"guest",
		"low3",
		"god",
	)
	var/static/list/dealer_names = list(
		"dealer",
		"croupier",
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
	var/base = "Player_"
	for(var/i = 0; i < 6; i++)
		base += "[pick(GLOB.alphabet)]"
	return trimtext(base)

/datum/component/buckshot_roulette_participant/proc/register_player()
	var/datum/buckshot_roulette_party/party_instance = party_weakref?.resolve()
	if(!party_instance)
		return

	while(TRUE)
		var/input_name = null
		if(player.client)
			input_name = tgui_input_text(player, "Enter player name", "Registration", max_length = 6, timeout = 30 SECONDS)

		if(!input_name)
			input_name = generate_random_name()

		if(LOWER_TEXT(input_name) in forbidden_names)
			to_chat(player, span_warning("This name is forbidden!"))
			continue

		if((LOWER_TEXT(input_name) in dealer_names) && !HAS_TRAIT(player, TRAIT_BUCKSHOT_DEALER))
			to_chat(player, span_warning("This name is reserved!"))
			continue

		if(party_instance.register_player(player, input_name))
			player_name = input_name
			break

		sleep(10)


/datum/component/buckshot_roulette_participant/proc/can_perform_turn()
	if(player_completely_dead() || HAS_TRAIT(player, TRAIT_BUCKSHOT_SKIPTURN))
		return FALSE
	if(player.stat != CONSCIOUS || player.incapacitated)
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
		crt.say("[player_name] — ELIMINATED!")
		to_chat(player, span_userdanger("You are dead. Game over for you."))
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
		to_chat(player, span_warning("Revival system disabled! You cannot return after dying in this round!"))

/datum/component/buckshot_roulette_participant/proc/on_game_start(/datum/buckshot_roulette_party/party, rules)
	SIGNAL_HANDLER
	ADD_TRAIT(parent, TRAIT_BUCKSHOT_PLAYER, INNATE_TRAIT)
	to_chat(player, span_big("Game started! You have [lives] life[lives == 1 ? "" : "s"]."))
	SEND_SOUND(player, 'fenysha_events/sounds/effects/buckshot/crt_display_health.ogg')


/datum/component/buckshot_roulette_participant/proc/add_lives(num, silent = FALSE)
	if(!crt_enabled)
		return
	if(lives == 3)
		return
	lives += num
	var/obj/structure/crt_mechanims/crt_instance = crt_weakref?.resolve()
	if(crt_instance)
		crt_instance.update_icon_state()
	if(!silent)
		to_chat(player, span_notice("Added [num] life[num == 1 ? "" : "s"]. You now have [lives] life[lives == 1 ? "" : "s"]."))

/datum/component/buckshot_roulette_participant/proc/on_game_end()
	SIGNAL_HANDLER
	if(HAS_TRAIT(player, TRAIT_BUCKSHOT_PLAYER))
		REMOVE_TRAIT(player, TRAIT_BUCKSHOT_PLAYER, INNATE_TRAIT)
	Destroy()


/datum/component/buckshot_roulette_participant/proc/get_crt_charges()
	return lives > 0 ? lives : 0
