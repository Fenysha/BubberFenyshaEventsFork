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
