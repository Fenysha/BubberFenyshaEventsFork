// RimWorld research projects: normal research-tree projects for this tech era.
// Node IDs use the RW_ prefix to avoid collisions with TG research nodes.

/datum/techweb_node/rw/artificial_metabolism
	id = RW_TECH_ARTIFICIAL_METABOLISM
	display_name = "Artificial Metabolism"
	description = "Craft advanced stomach implants that improve food processing."
	research_cost = 2000
	prereq_ids = list(RW_TECH_FABRICATION, RW_TECH_PROSTHETICS)
	tech_era = RW_TECH_ERA_ULTRATECH
	group_id = "bionics"
	required_attachments = list(/obj/building/attachment/analyzer)

/datum/techweb_node/rw/neural_computation
	id = RW_TECH_NEURAL_COMPUTATION
	display_name = "Neural Computation"
	description = "Craft brain implants that assist thought and learning."
	research_cost = 2000
	prereq_ids = list(RW_TECH_FABRICATION, RW_TECH_PROSTHETICS)
	tech_era = RW_TECH_ERA_ULTRATECH
	group_id = "bionics"
	required_attachments = list(/obj/building/attachment/analyzer)

/datum/techweb_node/rw/skin_hardening
	id = RW_TECH_SKIN_HARDENING
	display_name = "Skin Hardening"
	description = "Craft implants that harden natural skin into an armor-like layer."
	research_cost = 2000
	prereq_ids = list(RW_TECH_FABRICATION, RW_TECH_PROSTHETICS)
	tech_era = RW_TECH_ERA_ULTRATECH
	group_id = "bionics"
	required_attachments = list(/obj/building/attachment/analyzer)

/datum/techweb_node/rw/healing_factors
	id = RW_TECH_HEALING_FACTORS
	display_name = "Healing Factors"
	description = "Craft implants that improve the body's natural healing processes."
	research_cost = 2000
	prereq_ids = list(RW_TECH_FABRICATION, RW_TECH_PROSTHETICS)
	tech_era = RW_TECH_ERA_ULTRATECH
	group_id = "bionics"
	required_attachments = list(/obj/building/attachment/analyzer)

/datum/techweb_node/rw/flesh_shaping
	id = RW_TECH_FLESH_SHAPING
	display_name = "Flesh Shaping"
	description = "Craft implants for controlled changes to natural flesh."
	research_cost = 2000
	prereq_ids = list(RW_TECH_FABRICATION, RW_TECH_PROSTHETICS)
	tech_era = RW_TECH_ERA_ULTRATECH
	group_id = "bionics"
	required_attachments = list(/obj/building/attachment/analyzer)

/datum/techweb_node/rw/molecular_analysis
	id = RW_TECH_MOLECULAR_ANALYSIS
	display_name = "Molecular Analysis"
	description = "Craft molecular-analysis implants that assist immunity and food analysis."
	research_cost = 2000
	prereq_ids = list(RW_TECH_FABRICATION, RW_TECH_PROSTHETICS)
	tech_era = RW_TECH_ERA_ULTRATECH
	group_id = "bionics"
	required_attachments = list(/obj/building/attachment/analyzer)

/datum/techweb_node/rw/circadian_influence
	id = RW_TECH_CIRCADIAN_INFLUENCE
	display_name = "Circadian Influence"
	description = "Craft neural implants that modify circadian rhythms and sleep requirements."
	research_cost = 2000
	prereq_ids = list(RW_TECH_FABRICATION, RW_TECH_PROSTHETICS)
	tech_era = RW_TECH_ERA_ULTRATECH
	group_id = "bionics"
	required_attachments = list(/obj/building/attachment/analyzer)

/datum/techweb_node/rw/ultra_mechtech
	id = RW_TECH_ULTRA_MECHTECH
	display_name = "Ultra Mechtech"
	description = "Unlock advanced ultra-tier mechanoids and their supporting equipment."
	research_cost = 5000
	prereq_ids = list(RW_TECH_HIGH_MECHTECH, RW_TECH_FABRICATION)
	tech_era = RW_TECH_ERA_ULTRATECH
	group_id = "robotics"
	required_attachments = list(/obj/building/attachment/analyzer)
