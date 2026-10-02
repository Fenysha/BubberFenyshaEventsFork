/datum/building_blueprint/wooden_table
	id = "rw_wooden_table"
	name = "Wooden Table"
	desc = "A simple wooden table."
	architect_tab = RW_ARCHITECT_TAB_FURNITURE
	build_path = /obj/structure/table/wood
	materials = list(/obj/item/stack/sheet/mineral/wood = 2)
	construction_time = 3 SECONDS
	default_unlocked = TRUE

/datum/building_blueprint/wooden_chair
	id = "rw_wooden_chair"
	name = "Wooden Chair"
	desc = "A basic seat."
	architect_tab = RW_ARCHITECT_TAB_FURNITURE
	build_path = /obj/structure/chair/wood
	materials = list(/obj/item/stack/sheet/mineral/wood = 2)
	construction_time = 3 SECONDS
	default_unlocked = TRUE

/datum/building_blueprint/example_boiler
	id = "rw_example_boiler"
	name = "Boiler Assembly"
	desc = "Multi-tile boiler with console. Unlocked via faction research."
	architect_tab = RW_ARCHITECT_TAB_PRODUCTION
	multiblock_layout_id = "rw_mb_example_boiler"
	can_rotate = TRUE
	construction_time = 15 SECONDS
	default_unlocked = FALSE

/datum/rw_crafting_recipe/iron_rods
	id = "rw_iron_rods"
	name = "Iron Rods"
	result_path = /obj/item/stack/rods
	result_amount = 2
	requirements = list(/obj/item/stack/sheet/iron = 1)
	required_bench = /obj/machinery/rw_workbench/crafting

/datum/techweb_node/rw/construction_basics
	id = "RW_CONSTRUCTION_BASICS"
	display_name = "Basic Construction"
	description = "Simple wooden structures."
	research_cost = 200
	rw_flags = RW_RESEARCH_STARTING
	tech_era = RW_TECH_ERA_NEOLITHIC
	group_id = "construction"
	blueprint_ids = list("rw_wooden_table")

/datum/techweb_node/rw/wooden_walls
	id = "RW_WOODEN_WALLS"
	display_name = "Wooden Walls"
	description = "Sturdier wooden fortifications."
	prereq_ids = list("RW_CONSTRUCTION_BASICS")
	research_cost = 400
	tech_era = RW_TECH_ERA_NEOLITHIC
	group_id = "construction"

/datum/techweb_node/rw/thatching
	id = "RW_THATCHING"
	display_name = "Thatching"
	description = "Roofs from plant fibers."
	prereq_ids = list("RW_CONSTRUCTION_BASICS")
	research_cost = 350
	tech_era = RW_TECH_ERA_NEOLITHIC
	group_id = "construction"

/datum/techweb_node/rw/metalworking
	id = "RW_METALWORKING"
	display_name = "Metalworking"
	description = "Shaping iron into useful parts."
	prereq_ids = list("RW_CONSTRUCTION_BASICS")
	research_cost = 600
	tech_era = RW_TECH_ERA_NEOLITHIC
	group_id = "metal"
	workbench_types = list(/obj/machinery/rw_workbench/research)
	recipe_ids = list("rw_iron_rods")

/datum/techweb_node/rw/simple_weapons
	id = "RW_SIMPLE_WEAPONS"
	display_name = "Simple Weapons"
	description = "Spears and clubs."
	prereq_ids = list("RW_METALWORKING")
	research_cost = 500
	tech_era = RW_TECH_ERA_NEOLITHIC
	group_id = "metal"

/datum/techweb_node/rw/agriculture
	id = "RW_AGRICULTURE"
	display_name = "Agriculture"
	description = "Growing crops."
	research_cost = 300
	rw_flags = RW_RESEARCH_STARTING
	tech_era = RW_TECH_ERA_NEOLITHIC
	group_id = "agriculture"

/datum/techweb_node/rw/irrigation
	id = "RW_IRRIGATION"
	display_name = "Irrigation"
	description = "Watering fields."
	prereq_ids = list("RW_AGRICULTURE")
	research_cost = 450
	tech_era = RW_TECH_ERA_NEOLITHIC
	group_id = "agriculture"

/datum/techweb_node/rw/precision_tools
	id = "RW_PRECISION_TOOLS"
	display_name = "Precision Tools"
	description = "Delicate instruments. Needs an analyzer."
	prereq_ids = list("RW_METALWORKING")
	research_cost = 1500
	tech_era = RW_TECH_ERA_MEDIEVAL
	group_id = "tools"
	workbench_types = list(/obj/machinery/rw_workbench/research)
	required_attachments = list(/obj/structure/rw_bench_attachment/analyzer)
	rw_flags = RW_RESEARCH_HIDDEN

/datum/techweb_node/rw/stone_masonry
	id = "RW_STONE_MASONRY"
	display_name = "Stone Masonry"
	description = "Stone walls and arches."
	prereq_ids = list("RW_WOODEN_WALLS")
	research_cost = 900
	tech_era = RW_TECH_ERA_MEDIEVAL
	group_id = "construction"

/datum/techweb_node/rw/blacksmithing
	id = "RW_BLACKSMITHING"
	display_name = "Blacksmithing"
	description = "Forged steel tools and weapons."
	prereq_ids = list("RW_SIMPLE_WEAPONS", "RW_PRECISION_TOOLS")
	research_cost = 1200
	tech_era = RW_TECH_ERA_MEDIEVAL
	group_id = "metal"

/datum/techweb_node/rw/medicine_herbal
	id = "RW_MEDICINE_HERBAL"
	display_name = "Herbal Medicine"
	description = "Poultices and basic treatment."
	prereq_ids = list("RW_AGRICULTURE")
	research_cost = 800
	tech_era = RW_TECH_ERA_MEDIEVAL
	group_id = "medicine"

/datum/techweb_node/rw/steam_power
	id = "RW_STEAM_POWER"
	display_name = "Steam Power"
	description = "Boilers and simple engines."
	prereq_ids = list("RW_BLACKSMITHING")
	research_cost = 2000
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "power"

/datum/techweb_node/rw/machining
	id = "RW_MACHINING"
	display_name = "Machining"
	description = "Lathes and precise metal parts."
	prereq_ids = list("RW_PRECISION_TOOLS", "RW_STEAM_POWER")
	research_cost = 2200
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "tools"

/datum/techweb_node/rw/gunpowder
	id = "RW_GUNPOWDER"
	display_name = "Gunpowder"
	description = "Explosives and early firearms."
	prereq_ids = list("RW_BLACKSMITHING")
	research_cost = 1800
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "military"

/datum/techweb_node/rw/industrial_medicine
	id = "RW_INDUSTRIAL_MEDICINE"
	display_name = "Clinical Medicine"
	description = "Surgery and antiseptics."
	prereq_ids = list("RW_MEDICINE_HERBAL", "RW_MACHINING")
	research_cost = 2100
	tech_era = RW_TECH_ERA_INDUSTRIAL
	group_id = "medicine"

/datum/techweb_node/rw/electronics
	id = "RW_ELECTRONICS"
	display_name = "Electronics"
	description = "Circuits and basic computing."
	prereq_ids = list("RW_MACHINING")
	research_cost = 3000
	tech_era = RW_TECH_ERA_SPACER
	group_id = "electronics"

/datum/techweb_node/rw/space_suits
	id = "RW_SPACE_SUITS"
	display_name = "Space Suits"
	description = "Protection from vacuum."
	prereq_ids = list("RW_ELECTRONICS", "RW_INDUSTRIAL_MEDICINE")
	research_cost = 3500
	tech_era = RW_TECH_ERA_SPACER
	group_id = "space"

/datum/techweb_node/rw/orbital_comms
	id = "RW_ORBITAL_COMMS"
	display_name = "Orbital Comms"
	description = "Long-range radio and beacons."
	prereq_ids = list("RW_ELECTRONICS")
	research_cost = 3200
	tech_era = RW_TECH_ERA_SPACER
	group_id = "electronics"


/datum/techweb_node/rw/plasma_core
	id = "RW_PLASMA_CORE"
	display_name = "Plasma Core"
	description = "High-energy plasma systems."
	prereq_ids = list("RW_ELECTRONICS", "RW_STEAM_POWER")
	research_cost = 5000
	tech_era = RW_TECH_ERA_ULTRATECH
	group_id = "power"

/datum/techweb_node/rw/ai_basics
	id = "RW_AI_BASICS"
	display_name = "Artificial Intelligence"
	description = "Self-directed machine logic."
	prereq_ids = list("RW_ORBITAL_COMMS")
	research_cost = 5500
	tech_era = RW_TECH_ERA_ULTRATECH
	group_id = "electronics"

/datum/techweb_node/rw/teleportation
	id = "RW_TELEPORTATION"
	display_name = "Teleportation"
	description = "Point-to-point matter transfer."
	prereq_ids = list("RW_PLASMA_CORE", "RW_AI_BASICS")
	research_cost = 8000
	tech_era = RW_TECH_ERA_ULTRATECH
	group_id = "space"
