#define TRAIT_BUCKSHOT_PLAYER "trait_buckshot_player"
#define TRAIT_BUCKSHOT_DEALER "trait_buckshot_dealer"
#define TRAIT_BUCKSHOT_SKIPTURN "trait_buckshot_skipturn"

// из /datum/buckshot_roulette_party/proc/start_game() /datum/buckshot_roulette_party, rules
#define COMSIG_BUCKSHOT_GAME_STARTED "comsig_buckshot_game_started"
// из /datum/buckshot_roulette_party/proc/end_game() /datum/buckshot_roulette_party
#define COMSIG_BUCKSHOT_GAME_ENDED "comsig_buckshot_game_ended"
// из /datum/buckshot_roulette_party/proc/next_round() /datum/buckshot_roulette_party, death_round
#define COMSIG_BUCKSHOT_NEXT_ROUND "comsig_buckshot_next_round"
// из /datum/buckshot_roulette_party/proc/... /datum/buckshot_roulette_party, turns
#define COMSIG_BUCKSHOT_NEXT_TURN "comsig_buckshot_next_turn"

GLOBAL_LIST_INIT(buckshot_game_items, list(
	/obj/item/buckshot_game/cigarettes,
	/obj/item/buckshot_game/glass,
	/obj/item/buckshot_game/beer,
	/obj/item/buckshot_game/saw,
	/obj/item/buckshot_game/handcuffs,
	/obj/item/buckshot_game/adrenaline,
	/obj/item/buckshot_game/inverter,
	/obj/item/buckshot_game/expired_medicine,
	/obj/item/buckshot_game/burner_phone,
))

GLOBAL_LIST_INIT(buckshot_shell_typecache, typecacheof(list(
	/obj/item/ammo_casing/shotgun/buckshot/live,
	/obj/item/ammo_casing/shotgun/buckshot/blank,
)))
