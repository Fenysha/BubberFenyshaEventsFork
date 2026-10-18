/datum/techweb_node/rw/cryptosleep_casket
	id = RW_TECH_CRYPTOSLEEP_CASKET
	display_name = "Cryptosleep Casket"
	description = "Build caskets that suspend living occupants for long periods."
	research_cost = 2000
	prereq_ids = list(RW_TECH_MULTI_ANALYZER)
	tech_era = RW_TECH_ERA_SPACER
	group_id = "medicine"
	required_attachments = list(/obj/building/attachment/analyzer)

/datum/techweb_node/rw/recon_armor
	id = RW_TECH_RECON_ARMOR
	display_name = "Recon Armor"
	description = "Craft light powered armor for mobile troops."
	research_cost = 6000
	prereq_ids = list(RW_TECH_FABRICATION, RW_TECH_COMPLEX_CLOTHING)
	tech_era = RW_TECH_ERA_SPACER
	group_id = "armor"
	required_attachments = list(/obj/building/attachment/analyzer)

/datum/techweb_node/rw/marine_armor
	id = RW_TECH_MARINE_ARMOR
	display_name = "Marine Armor"
	description = "Craft general-purpose powered armor for heavily equipped soldiers."
	research_cost = 6000
	prereq_ids = list(RW_TECH_RECON_ARMOR, RW_TECH_COMPLEX_CLOTHING)
	tech_era = RW_TECH_ERA_SPACER
	group_id = "armor"
	required_attachments = list(/obj/building/attachment/analyzer)

/datum/techweb_node/rw/pulse_charged_munitions
	id = RW_TECH_PULSE_CHARGED_MUNITIONS
	display_name = "Pulse-Charged Munitions"
	description = "Build weapons that fire electrically charged high-energy ammunition."
	research_cost = 3000
	prereq_ids = list(RW_TECH_FABRICATION, RW_TECH_PRECISION_RIFLING)
	tech_era = RW_TECH_ERA_SPACER
	group_id = "weapons"
	required_attachments = list(/obj/building/attachment/analyzer)

/datum/techweb_node/rw/bionic_replacements
	id = RW_TECH_BIONIC_REPLACEMENTS
	display_name = "Bionic Replacements"
	description = "Craft advanced bionic body parts for limbs, senses, and organs."
	research_cost = 2000
	prereq_ids = list(RW_TECH_FABRICATION, RW_TECH_PROSTHETICS)
	tech_era = RW_TECH_ERA_SPACER
	group_id = "medicine"
	required_attachments = list(/obj/building/attachment/analyzer)

/datum/techweb_node/rw/starflight_basics
	id = RW_TECH_STARFLIGHT_BASICS
	display_name = "Starflight Basics"
	description = "Build the structural and support components of an interstellar ship."
	research_cost = 4000
	prereq_ids = list(RW_TECH_ADVANCED_FABRICATION)
	tech_era = RW_TECH_ERA_SPACER
	group_id = "space"
	required_attachments = list(/obj/building/attachment/analyzer)

/datum/techweb_node/rw/starflight_sensors
	id = RW_TECH_STARFLIGHT_SENSORS
	display_name = "Starflight Sensors"
	description = "Build long-range sensors needed for starship navigation and threat detection."
	research_cost = 4000
	prereq_ids = list(RW_TECH_STARFLIGHT_BASICS, RW_TECH_LONG_RANGE_MINERAL_SCANNER)
	tech_era = RW_TECH_ERA_SPACER
	group_id = "space"
	required_attachments = list(/obj/building/attachment/analyzer)

/datum/techweb_node/rw/vacuum_cryptosleep_casket
	id = RW_TECH_VACUUM_CRYPTOSLEEP_CASKET
	display_name = "Vacuum Cryptosleep Casket"
	description = "Build shipboard cryptosleep caskets that tolerate vacuum exposure."
	research_cost = 2800
	prereq_ids = list(RW_TECH_STARFLIGHT_BASICS, RW_TECH_CRYPTOSLEEP_CASKET)
	tech_era = RW_TECH_ERA_SPACER
	group_id = "space"
	required_attachments = list(/obj/building/attachment/analyzer)

/datum/techweb_node/rw/starship_reactor
	id = RW_TECH_STARSHIP_REACTOR
	display_name = "Starship Reactor"
	description = "Build a reactor that can power an interstellar ship."
	research_cost = 6000
	prereq_ids = list(RW_TECH_STARFLIGHT_BASICS)
	tech_era = RW_TECH_ERA_SPACER
	group_id = "space"
	required_attachments = list(/obj/building/attachment/analyzer)

/datum/techweb_node/rw/johnson_tanaka_drive
	id = RW_TECH_JOHNSON_TANAKA_DRIVE
	display_name = "Johnson-Tanaka Drive"
	description = "Build an engine capable of interstellar travel."
	research_cost = 6000
	prereq_ids = list(RW_TECH_STARFLIGHT_BASICS)
	tech_era = RW_TECH_ERA_SPACER
	group_id = "space"
	required_attachments = list(/obj/building/attachment/analyzer)

/datum/techweb_node/rw/machine_persuasion
	id = RW_TECH_MACHINE_PERSUASION
	display_name = "Machine Persuasion"
	description = "Construct a computer core capable of coordinating a long-duration starflight."
	research_cost = 3000
	prereq_ids = list(RW_TECH_STARFLIGHT_BASICS)
	tech_era = RW_TECH_ERA_SPACER
	group_id = "space"
	required_attachments = list(/obj/building/attachment/analyzer)

/datum/techweb_node/rw/cataphract_armor
	id = RW_TECH_CATAPHRACT_ARMOR
	display_name = "Cataphract Armor"
	description = "Craft the heaviest standard powered armor for maximum protection."
	research_cost = 6000
	prereq_ids = list(RW_TECH_MARINE_ARMOR)
	tech_era = RW_TECH_ERA_SPACER
	group_id = "armor"
	required_attachments = list(/obj/building/attachment/analyzer)

/datum/techweb_node/rw/brain_wiring
	id = RW_TECH_BRAIN_WIRING
	display_name = "Brain Wiring"
	description = "Craft brain implants that alter the user's experience of pain and pleasure."
	research_cost = 2000
	prereq_ids = list(RW_TECH_MICROELECTRONICS, RW_TECH_PROSTHETICS)
	tech_era = RW_TECH_ERA_SPACER
	group_id = "bionics"
	required_attachments = list(/obj/building/attachment/analyzer)

/datum/techweb_node/rw/specialized_limbs
	id = RW_TECH_SPECIALIZED_LIMBS
	display_name = "Specialized Limbs"
	description = "Craft specialized bionic limbs intended for combat or labor."
	research_cost = 2000
	prereq_ids = list(RW_TECH_MICROELECTRONICS, RW_TECH_PROSTHETICS)
	tech_era = RW_TECH_ERA_SPACER
	group_id = "bionics"
	required_attachments = list(/obj/building/attachment/analyzer)

/datum/techweb_node/rw/compact_weaponry
	id = RW_TECH_COMPACT_WEAPONRY
	display_name = "Compact Weaponry"
	description = "Build concealed weapons that can be integrated into a body."
	research_cost = 2000
	prereq_ids = list(RW_TECH_MICROELECTRONICS, RW_TECH_PROSTHETICS)
	tech_era = RW_TECH_ERA_SPACER
	group_id = "bionics"
	required_attachments = list(/obj/building/attachment/analyzer)

/datum/techweb_node/rw/poison_synthesis
	id = RW_TECH_POISON_SYNTHESIS
	display_name = "Poison Synthesis"
	description = "Craft bionic implants that deliver synthesized venom."
	research_cost = 2000
	prereq_ids = list(RW_TECH_COMPACT_WEAPONRY)
	tech_era = RW_TECH_ERA_SPACER
	group_id = "bionics"
	required_attachments = list(/obj/building/attachment/analyzer)

/datum/techweb_node/rw/toxin_filtration
	id = RW_TECH_TOXIN_FILTRATION
	display_name = "Toxin Filtration"
	description = "Craft replacement organs that filter toxins from the body."
	research_cost = 2000
	prereq_ids = list(RW_TECH_FABRICATION, RW_TECH_PROSTHETICS)
	tech_era = RW_TECH_ERA_SPACER
	group_id = "bionics"
	required_attachments = list(/obj/building/attachment/analyzer)

/datum/techweb_node/rw/growth_vats
	id = RW_TECH_GROWTH_VATS
	display_name = "Growth Vats"
	description = "Build vats for gestating embryos and accelerating child growth."
	research_cost = 500
	prereq_ids = list(RW_TECH_MICROELECTRONICS)
	tech_era = RW_TECH_ERA_SPACER
	group_id = "biotechnology"
	required_attachments = list(/obj/building/attachment/analyzer)

/datum/techweb_node/rw/advanced_gravtech
	id = RW_TECH_ADVANCED_GRAVTECH
	display_name = "Advanced Gravtech"
	description = "Build advanced gravship components."
	research_cost = 2000
	prereq_ids = list(RW_TECH_STANDARD_GRAVTECH, RW_TECH_FABRICATION)
	tech_era = RW_TECH_ERA_SPACER
	group_id = "transport"
	required_attachments = list(/obj/building/attachment/analyzer)

/datum/techweb_node/rw/beam_weapons
	id = RW_TECH_BEAM_WEAPONS
	display_name = "Beam Weapons"
	description = "Build gamma-beam weapons that burn through armor and ignite targets."
	research_cost = 4000
	prereq_ids = list(RW_TECH_PULSE_CHARGED_MUNITIONS, RW_TECH_ADVANCED_FABRICATION)
	tech_era = RW_TECH_ERA_SPACER
	group_id = "weapons"
	required_attachments = list(/obj/building/attachment/analyzer)

/datum/techweb_node/rw/shuttle
	id = RW_TECH_SHUTTLE
	display_name = "Shuttle"
	description = "Build a shuttle for long-distance travel and orbital access."
	research_cost = 2500
	prereq_ids = list(RW_TECH_TRANSPORT_POD, RW_TECH_MULTI_ANALYZER)
	tech_era = RW_TECH_ERA_SPACER
	group_id = "transport"
	required_attachments = list(/obj/building/attachment/analyzer)
