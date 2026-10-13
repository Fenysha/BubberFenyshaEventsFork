/datum/rw_faction/outlanders
	id = RW_FACTION_OUTLANDERS
	desc = "A civilized society of settlers, traders and explorers who have lived on the rim for generations."
	player_faction = FALSE
	color = "#4A90D9"
	icon_state = RW_PLANET_CELL_TOWN

/datum/rw_faction/outlanders/generate_name()
	var/list/prefixes = list(
		"United",
		"Free",
		"Independent",
		"Frontier",
		"Outer",
		"Rim",
		"Colonial",
		"Federated",
		"Pan-Rim",
		"Freeholder",
	)

	var/list/nouns = list(
		"Alliance",
		"Union",
		"Confederation",
		"Coalition",
		"Republic",
		"Federation",
		"Commonwealth",
		"League",
		"Compact",
		"Territories",
		"Accord",
	)

	return "[pick(prefixes)] [pick(nouns)]"


/datum/rw_faction/rough_outlanders
	id = RW_FACTION_ROUGH_OUTLANDERS
	desc = "A hardened frontier society where survival, armed trade and personal strength are valued above law and diplomacy."
	player_faction = FALSE
	color = "#A0522D"
	icon_state = RW_PLANET_CELL_TOWN

/datum/rw_faction/rough_outlanders/generate_name()
	var/list/prefixes = list(
		"Iron",
		"Red",
		"Broken",
		"Black",
		"Free",
		"Outer",
		"Wild",
		"Frontier",
		"Forsaken",
		"Border",
		"Hard",
	)

	var/list/nouns = list(
		"Rangers",
		"Settlers",
		"Company",
		"Brotherhood",
		"Outcasts",
		"Colonists",
		"Holdouts",
		"Frontiersmen",
		"Freeholders",
		"League",
	)

	return "[pick(prefixes)] [pick(nouns)]"


/datum/rw_faction/tribals
	id = RW_FACTION_GENTLE_TRIBE
	desc = "A traditional tribal society that lives from the land and values cooperation, ancestral customs and peaceful trade."
	player_faction = FALSE
	color = "#D4B23C"
	icon_state = RW_PLANET_CELL_TOWN

/datum/rw_faction/tribals/generate_name()
	var/list/nouns = list(
		"People",
		"Tribe",
		"Clan",
		"Kin",
		"Circle",
		"Gathering",
		"Hearth",
		"Nation",
	)

	var/list/words = list(
		"River",
		"Mountain",
		"Forest",
		"Valley",
		"Stone",
		"Wind",
		"Sun",
		"Moon",
		"Rain",
		"Oak",
		"Willow",
		"Prairie",
		"Lake",
		"Autumn",
		"Spring",
	)

	return "The [pick(words)] [pick(nouns)]"


/datum/rw_faction/fierce_tribes
	id = RW_FACTION_FIERCE_TRIBE
	desc = "A proud and aggressive tribal society that fiercely protects its territory, traditions and hunting grounds."
	player_faction = FALSE
	color = "#A67C2D"
	icon_state = RW_PLANET_CELL_TOWN
	can_raid = TRUE
	raid_id = "fierce_tribe"
	raid_kinds = list(/datum/raid_pawn_kind/tribal_warrior, /datum/raid_pawn_kind/tribal_hunter, /datum/raid_pawn_kind/tribal_berserker)
	raid_strategy = RAID_STRATEGY_ASSAULT
	raid_retreat_fraction = 0.7
	raid_faction_tag = "rw_raiders_tribe"
	raid_announce_text = "Tribal warriors are charging from the %DIR%!"
	raid_retreat_text = "The tribesmen retreat into the wilderness."
	raid_defeat_text = "The tribal raid has been beaten back."
	base_tech_level = 0


/datum/rw_faction/fierce_tribes/generate_name()
	var/list/words = list(
		"Iron",
		"Stone",
		"Red",
		"Thunder",
		"Storm",
		"Mountain",
		"Black",
		"Wolf",
		"Bear",
		"Broken",
		"Horn",
		"Fire",
		"Blood",
	)

	var/list/nouns = list(
		"Warriors",
		"Clan",
		"Tribe",
		"Warband",
		"Kin",
		"People",
		"Hunters",
		"Sons",
		"Brothers",
	)

	return "The [pick(words)] [pick(nouns)]"


/datum/rw_faction/savage_tribes
	id = RW_FACTION_SAVAGE_TRIBE
	desc = "A fiercely territorial tribal people with little interest in diplomacy. Outsiders are treated as immediate threats."
	player_faction = FALSE
	color = "#B52B35"
	icon_state = RW_PLANET_CELL_TOWN
	can_raid = TRUE
	raid_id = "savage_tribe"
	raid_kinds = list(/datum/raid_pawn_kind/tribal_warrior, /datum/raid_pawn_kind/tribal_berserker)
	raid_strategy = RAID_STRATEGY_ASSAULT
	raid_retreat_fraction = 0
	raid_faction_tag = "rw_raiders_savage"
	raid_announce_text = "Savages are howling in the %DIR%! They are coming for you!"
	raid_defeat_text = "The savage horde has been destroyed."
	base_tech_level = 0

/datum/rw_faction/savage_tribes/generate_name()
	var/list/words = list(
		"Blood",
		"Bone",
		"Fang",
		"Skull",
		"Red",
		"Black",
		"Wild",
		"Dead",
		"Burning",
		"Dark",
		"Raging",
	)

	var/list/nouns = list(
		"Tribe",
		"Warband",
		"Clan",
		"Hunters",
		"Kin",
		"Raiders",
		"Pack",
		"People",
	)

	return "The [pick(words)] [pick(nouns)]"


/datum/rw_faction/pirates
	id = RW_FACTION_PIRATES
	desc = "A loose confederation of raiders, criminals and pirates who survive through plunder, extortion and violence."
	player_faction = FALSE
	color = "#C41E3A"
	icon_state = RW_PLANET_CELL_TOWN
	can_raid = TRUE
	raid_id = "pirates"
	raid_kinds = list(/datum/raid_pawn_kind/pirate_grunt, /datum/raid_pawn_kind/pirate_gunner, /datum/raid_pawn_kind/pirate_heavy)
	raid_strategy = RAID_STRATEGY_STAGE
	raid_retreat_fraction = 0.6
	raid_max_duration = 10 MINUTES
	raid_faction_tag = "rw_raiders_pirates"
	raid_announce_text = "A band of pirates is approaching from the %DIR%! They are gathering for an assault."
	raid_staged_text = "The pirates charge the colony!"
	raid_retreat_text = "The pirates have lost their nerve and are fleeing."
	raid_defeat_text = "The pirate raid has been crushed."
	base_tech_level = 2

/datum/rw_faction/pirates/generate_name()
	var/list/prefixes = list(
		"Blood",
		"Black",
		"Red",
		"Dead",
		"Broken",
		"Iron",
		"Skull",
		"Crimson",
		"Void",
		"Grave",
		"Razor",
	)

	var/list/nouns = list(
		"Pirates",
		"Raiders",
		"Reavers",
		"Freebooters",
		"Brigands",
		"Marauders",
		"Outlaws",
		"Cutthroats",
		"Bandits",
		"Scavengers",
	)

	return "The [pick(prefixes)] [pick(nouns)]"


/datum/rw_faction/mechanoids
	id = RW_FACTION_MECHANOIDS
	desc = "Hostile autonomous machine intelligences operating through mechanized warforms. Their facilities are extremely dangerous."
	player_faction = FALSE
	color = "#708090"
	icon_state = RW_PLANET_CELL_TOWN
	can_raid = TRUE
	raid_id = "mechanoids"
	raid_kinds = list(/datum/raid_pawn_kind/mech_light, /datum/raid_pawn_kind/mech_heavy)
	raid_min_points = 60
	raid_strategy = RAID_STRATEGY_ASSAULT
	raid_retreat_fraction = 0
	raid_max_duration = 0
	raid_faction_tag = "rw_raiders_mechanoid"
	raid_announce_text = "Mechanoid signatures detected to the %DIR%. They are heading for the colony!"
	raid_defeat_text = "The mechanoid cluster has been disabled."
	base_tech_level = 3

/datum/rw_faction/mechanoids/generate_name()
	var/list/prefixes = list(
		"Sigma",
		"Alpha",
		"Delta",
		"Gamma",
		"Omega",
		"Tau",
		"Lambda",
		"Xi",
		"Zeta",
		"Omicron",
		"Kappa",
		"Mu",
	)

	var/list/nouns = list(
		"Mechhive",
		"Core",
		"Cluster",
		"Network",
		"Collective",
		"Directive",
		"Node",
		"Assembly",
		"Convergence",
		"Machine",
	)

	return "[pick(prefixes)] [pick(nouns)]"


/datum/rw_faction/insectoids
	id = RW_FACTION_INSECTOIDS
	desc = "Large insectoid hives that expand through underground tunnels and overwhelm their enemies through sheer numbers."
	player_faction = FALSE
	color = "#556B2F"
	icon_state = RW_PLANET_CELL_TOWN
	can_raid = TRUE
	raid_id = "insectoids"
	raid_kinds = list(/datum/raid_pawn_kind/insect_small, /datum/raid_pawn_kind/insect_large)
	raid_strategy = RAID_STRATEGY_ASSAULT
	raid_retreat_fraction = 0
	raid_max_duration = 0
	raid_faction_tag = "rw_raiders_insect"
	raid_announce_text = "Something is skittering out of the %DIR%... insectoids!"
	raid_defeat_text = "The insectoid swarm has been exterminated."
	base_tech_level = 1

/datum/rw_faction/insectoids/generate_name()
	var/list/prefixes = list(
		"Black",
		"Amber",
		"Deep",
		"Stone",
		"Red",
		"Dark",
		"Ancient",
		"Buried",
		"Chitin",
		"Under",
	)

	var/list/nouns = list(
		"Hive",
		"Brood",
		"Nest",
		"Colony",
		"Swarm",
		"Burrow",
		"Broodhold",
		"Infestation",
	)

	return "[pick(prefixes)] [pick(nouns)]"


/datum/rw_faction/ancients
	desc = "An isolated remnant of a civilization from before the current age. Their facilities contain forgotten technology and unknown dangers."
	player_faction = FALSE
	color = "#8A7CB8"
	icon_state = RW_PLANET_CELL_TOWN

/datum/rw_faction/ancients/generate_name()
	var/static/list/prefixes = list(
		"Astra",
		"Orion",
		"Helios",
		"Nova",
		"Caelum",
		"Elysian",
		"Vesper",
		"Arc",
		"Aurel",
		"Seraph",
	)

	var/static/list/nouns = list(
		"Enclave",
		"Remnant",
		"Continuum",
		"Domain",
		"Archive",
		"Colony",
		"Ascendancy",
		"Settlement",
		"Sanctum",
	)

	return "[pick(prefixes)] [pick(nouns)]"


/datum/rw_faction/ancients/neutral
	id = RW_FACTION_ANCIENTS_NEUTRAL
	desc = "An isolated remnant of an ancient civilization whose people survived the collapse in sealed underground facilities. They rarely interfere with outsiders."

/datum/rw_faction/ancients/neutral/generate_name()
	var/list/names = list(
		"Astra Enclave",
		"Vesper Remnant",
		"Elysian Continuum",
		"Orion Archive",
		"Caelum Sanctum",
		"Nova Domain",
		"Helios Enclave",
		"Seraph Remnant",
	)

	return pick(names)


/datum/rw_faction/ancients/hostile
	id = RW_FACTION_ANCIENTS_HOSTILE
	desc = "A surviving ancient faction whose isolation has made it fiercely hostile toward outsiders. Their sealed facilities conceal dangerous technology."

/datum/rw_faction/ancients/hostile/generate_name()
	var/list/names = list(
		"The Vengeful",
		"The Last Legion",
		"The Old Guard",
		"The Eternal Host",
		"The Iron Remnant",
		"The Ascended",
		"The Silent Dominion",
		"The Forgotten",
	)

	return pick(names)


/datum/rw_faction/player/admin
	id = "admin"
	desc = "The administrative faction for the player. This faction is not meant to be interacted with by the player."
	player_faction = TRUE

	color = "#1100ff"
	icon_state = RW_PLANET_CELL_TOWN
