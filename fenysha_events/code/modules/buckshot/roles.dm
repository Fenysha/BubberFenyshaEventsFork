/datum/job/buckshot_player
	title = "Test subject"
	description = "You are a test subject who has been trapped in an endless simulation since yesterday evening."
	faction = FACTION_STATION
	total_positions = 5
	spawn_positions = 5
	supervisors = "Yourself"
	exp_granted_type = EXP_TYPE_CREW

	outfit = /datum/outfit/job/test_subject
	plasmaman_outfit = /datum/outfit/plasmaman

	paycheck = PAYCHECK_CREW
	paycheck_department = ACCOUNT_SRV

	// mind_traits = list(TRAIT_NAIVE)
	// liver_traits = list(TRAIT_COMEDY_METABOLISM)

	display_order = JOB_DISPLAY_ORDER_CAPTAIN
	departments_list = list(
		/datum/job_department/service,
		)

	mail_goodies = list()

	config_tag = "ASSISTANT"
	job_flags = STATION_JOB_FLAGS


/datum/outfit/job/test_subject
	name = "Test subject"
	jobtype = /datum/job/buckshot_player
	id_trim = /datum/id_trim/job/assistant
	belt = /obj/item/modular_computer/pda/assistant

	uniform = /obj/item/clothing/under/rank/prisoner/lowsec
	belt = /obj/item/modular_computer/pda
	back = /obj/item/storage/backpack/industrial/frontier_colonist/satchel
	shoes = /obj/item/clothing/shoes/jackboots/black
	box = /obj/item/storage/box/survival

/area/centcom/buckshot_club
	name = "Buckshot club"
	requires_power = FALSE
	default_gravity = STANDARD_GRAVITY
	area_flags = NOTELEPORT|NO_DEATH_MESSAGE|NO_BOH


/area/centcom/buckshot_club/outdoors
	name = "Streets"
	requires_power = FALSE
	outdoors = TRUE
	daylight = TRUE

/obj/effect/landmark/start/test_subject
	name = "Test subject"
	icon_state = JOB_ASSISTANT
