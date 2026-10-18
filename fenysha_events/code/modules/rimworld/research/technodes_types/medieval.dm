// RimWorld research projects: normal research-tree projects for this tech era.
// Node IDs use the RW_ prefix to avoid collisions with TG research nodes.

/datum/techweb_node/rw/complex_clothing
	id = RW_TECH_COMPLEX_CLOTHING
	display_name = "Complex Clothing"
	description = "Tailor fitted garments, coats, hats, and other advanced clothing."
	research_cost = 600
	tech_era = RW_TECH_ERA_MEDIEVAL
	group_id = "textiles"

/datum/techweb_node/rw/complex_furniture
	id = RW_TECH_COMPLEX_FURNITURE
	display_name = "Complex Furniture"
	description = "Build beds, chairs, storage furniture, tables, and other refined furnishings."
	research_cost = 300
	tech_era = RW_TECH_ERA_MEDIEVAL
	group_id = "furniture"

/datum/techweb_node/rw/carpet_making
	id = RW_TECH_CARPET_MAKING
	display_name = "Carpet Making"
	description = "Weave cloth into decorative carpets."
	research_cost = 800
	tech_era = RW_TECH_ERA_MEDIEVAL
	group_id = "textiles"

/datum/techweb_node/rw/smithing
	id = RW_TECH_SMITHING
	display_name = "Smithing"
	description = "Forge basic metal tools, weapons, and metal floor tiles."
	research_cost = 700
	tech_era = RW_TECH_ERA_MEDIEVAL
	group_id = "crafting"
	// Preserve the bundled custom metalworking recipes from the supplied test content.
	recipe_ids = list("rw_iron_rods", "rw_forged_crowbar")

/datum/techweb_node/rw/stonecutting
	id = RW_TECH_STONECUTTING
	display_name = "Stonecutting"
	description = "Cut stone chunks into blocks and produce stone floors and paved surfaces."
	research_cost = 300
	tech_era = RW_TECH_ERA_MEDIEVAL
	group_id = "construction"

/datum/techweb_node/rw/long_blades
	id = RW_TECH_LONG_BLADES
	display_name = "Long Blades"
	description = "Forge long melee weapons such as swords and spears."
	research_cost = 400
	prereq_ids = list(RW_TECH_SMITHING)
	tech_era = RW_TECH_ERA_MEDIEVAL
	group_id = "weapons"

/datum/techweb_node/rw/plate_armor
	id = RW_TECH_PLATE_ARMOR
	display_name = "Plate Armor"
	description = "Produce heavy plate armor from available rigid materials."
	research_cost = 600
	prereq_ids = list(RW_TECH_SMITHING, RW_TECH_COMPLEX_CLOTHING)
	tech_era = RW_TECH_ERA_MEDIEVAL
	group_id = "armor"

/datum/techweb_node/rw/greatbow
	id = RW_TECH_GREATBOW
	display_name = "Greatbow"
	description = "Craft heavy bows intended for powerful long-range shots."
	research_cost = 600
	prereq_ids = list(RW_TECH_RECURVE_BOW)
	tech_era = RW_TECH_ERA_MEDIEVAL
	group_id = "weapons"

/datum/techweb_node/rw/noble_apparel
	id = RW_TECH_NOBLE_APPAREL
	display_name = "Noble Apparel"
	description = "Tailor formal clothing suited to high-status colonists."
	research_cost = 400
	prereq_ids = list(RW_TECH_COMPLEX_CLOTHING)
	tech_era = RW_TECH_ERA_MEDIEVAL
	group_id = "textiles"

/datum/techweb_node/rw/royal_apparel
	id = RW_TECH_ROYAL_APPAREL
	display_name = "Royal Apparel"
	description = "Create crowns and the highest tier of formal royal garments."
	research_cost = 400
	prereq_ids = list(RW_TECH_NOBLE_APPAREL, RW_TECH_SMITHING)
	tech_era = RW_TECH_ERA_MEDIEVAL
	group_id = "textiles"

/datum/techweb_node/rw/harp
	id = RW_TECH_HARP
	display_name = "Harp"
	description = "Craft a stationary harp for musical recreation."
	research_cost = 500
	prereq_ids = list(RW_TECH_COMPLEX_FURNITURE)
	tech_era = RW_TECH_ERA_MEDIEVAL
	group_id = "recreation"

/datum/techweb_node/rw/harpsichord
	id = RW_TECH_HARPSICHORD
	display_name = "Harpsichord"
	description = "Build a more complex stationary stringed instrument."
	research_cost = 500
	prereq_ids = list(RW_TECH_HARP, RW_TECH_SMITHING)
	tech_era = RW_TECH_ERA_MEDIEVAL
	group_id = "recreation"
