/datum/techweb_node/rw/neolithic
	tech_era = RW_TECH_ERA_NEOLITHIC


/datum/techweb_node/rw/neolithic/basic
	id = RW_TECH_BASIC_KNOWLEDGES
	rw_flags = RW_RESEARCH_STARTING

	blueprint_ids = list(
		"rw_sawbuck",

	)

	recipe_ids = list(
		"rw_planks_20",
		"rw_planks_40",
	)



/datum/techweb_node/rw/neolithic/psychoid_brewing
	id = RW_TECH_PSYCHOID_BREWING
	display_name = "Psychoid Brewing"
	description = "Learn to prepare psychoid leaves as a mild, addictive recreational tea."
	research_cost = 500
	tech_era = RW_TECH_ERA_NEOLITHIC
	group_id = "agriculture"

/datum/techweb_node/rw/neolithic/tree_sowing
	id = RW_TECH_TREE_SOWING
	display_name = "Tree Sowing"
	description = "Cultivate the local tree species instead of relying only on wild growth."
	research_cost = 1000

	tech_era = RW_TECH_ERA_NEOLITHIC
	min_skill_level = 5

	group_id = "agriculture"

/datum/techweb_node/rw/neolithic/beer_brewing
	id = RW_TECH_BEER_BREWING
	display_name = "Beer Brewing"
	description = "Ferment hops into beer using basic brewing equipment."
	research_cost = 400
	tech_era = RW_TECH_ERA_NEOLITHIC
	group_id = "food"

/datum/techweb_node/rw/neolithic/passive_cooler
	id = RW_TECH_PASSIVE_COOLER
	display_name = "Passive Cooler"
	description = "Cool enclosed rooms without using electrical power."
	research_cost = 400
	tech_era = RW_TECH_ERA_NEOLITHIC
	group_id = "infrastructure"

/datum/techweb_node/rw/neolithic/cocoa
	id = RW_TECH_COCOA
	display_name = "Cocoa"
	description = "Grow cocoa trees and produce chocolate for food and recreation."
	research_cost = 1000
	prereq_ids = list(RW_TECH_TREE_SOWING)
	tech_era = RW_TECH_ERA_NEOLITHIC
	group_id = "agriculture"

/datum/techweb_node/rw/neolithic/devilstrand
	id = RW_TECH_DEVILSTRAND
	display_name = "Devilstrand"
	description = "Cultivate a slow-growing mushroom that yields durable plant fibre."
	research_cost = 800

	tech_era = RW_TECH_ERA_NEOLITHIC
	min_skill_level = 7

	group_id = "agriculture"

/datum/techweb_node/rw/neolithic/pemmican
	id = RW_TECH_PEMMICAN
	display_name = "Pemmican"
	description = "Preserve meat and plant matter in long-lasting travel rations."
	research_cost = 500
	tech_era = RW_TECH_ERA_NEOLITHIC
	group_id = "food"

/datum/techweb_node/rw/neolithic/recurve_bow
	id = RW_TECH_RECURVE_BOW
	display_name = "Recurve Bow"
	description = "Build efficient, inexpensive bows for ranged combat."
	research_cost = 400

	tech_era = RW_TECH_ERA_NEOLITHIC
	min_skill_level = 4

	group_id = "weapons"

/datum/techweb_node/rw/neolithic/fishing
	id = RW_TECH_FISHING
	display_name = "Fishing"
	description = "Organize fishing in suitable waters as a renewable food source."
	research_cost = 600
	tech_era = RW_TECH_ERA_NEOLITHIC
	group_id = "food"
