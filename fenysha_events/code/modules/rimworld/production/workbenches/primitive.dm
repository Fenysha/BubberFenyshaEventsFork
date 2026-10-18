// MARK: Blueprints

/datum/building_blueprint/work_spot
	id = "rw_work_spot"
	name = "Work spot"
	desc = "An improvised place for basic handcrafting. It needs no construction materials."

	architect_tab = RW_ARCHITECT_TAB_PRODUCTION

	build_path = /obj/building/production/crafting/work_spot
	materials = list()

	build_steps = 1
	construction_time = 1 SECONDS

	default_unlocked = TRUE


/datum/building_blueprint/primitive_workbench
	id = "rw_primitive_workbench"
	name = "Primitive workbench"
	desc = "A sturdy wooden bench for basic tools and hand-made parts."

	architect_tab = RW_ARCHITECT_TAB_PRODUCTION
	build_path = /obj/building/production/crafting/primitive

	materials = list(
		/obj/item/stack/sheet/rimworld/wood = 30,
		/obj/item/stack/sheet/rimworld/log = 10,
	)

	build_steps = 30
	construction_time = 3 SECONDS

	ideal_skill = 5
	required_skill = 1


/datum/building_blueprint/campfire
	id = "rw_campfire"
	name = "Campfire"
	desc = "A simple fire pit for cooking and primitive heat treatment."

	architect_tab = RW_ARCHITECT_TAB_PRODUCTION

	build_path = /obj/building/production/crafting/campfire
	materials = list(
		/obj/item/stack/sheet/rimworld/log = 4,
		/obj/item/stack/sheet/rimworld/wood = 10,
	)

	build_steps = 20
	construction_time = 2 SECONDS

	default_unlocked = TRUE


/datum/building_blueprint/creative_table
	id = "rw_creative_table"
	name = "Sculptor's table"
	desc = "A broad surface for simple sculptures and decorative work."

	architect_tab = RW_ARCHITECT_TAB_PRODUCTION

	build_path = /obj/building/production/crafting/creative_table
	multiblock_layout_id = "rw_creative_table_1x2"
	materials = list(
		/obj/item/stack/sheet/rimworld/wood = 6,
		/obj/item/stack/sheet/rimworld/log = 2,
	)
	build_steps = 8
	construction_time = 4 SECONDS


/datum/building_blueprint/stonecutting_table
	id = "rw_stonecutting_table"
	name = "Stonecutting table"
	desc = "A long, solid table for cutting blocks and shaping stone."
	architect_tab = RW_ARCHITECT_TAB_PRODUCTION
	build_path = /obj/building/production/crafting/stonecutting
	multiblock_layout_id = "rw_stonecutting_table_1x2"
	materials = list(
		/obj/item/stack/sheet/rimworld/wood = 4,
		/obj/item/stack/sheet/rimworld/granite = 4,
	)
	build_steps = 10
	construction_time = 4 SECONDS


/datum/building_blueprint/primitive_stove
	id = "rw_primitive_stove"
	name = "Primitive stove"
	desc = "A small stone-and-wood cooking hearth."
	architect_tab = RW_ARCHITECT_TAB_PRODUCTION
	build_path = /obj/building/production/crafting/primitive_stove
	materials = list(
		/obj/item/stack/sheet/rimworld/wood = 3,
		/obj/item/stack/sheet/rimworld/granite = 2,
	)
	build_steps = 6
	construction_time = 3 SECONDS


/datum/building_blueprint/butcher_table
	id = "rw_butcher_table"
	name = "Butcher table"
	desc = "A wide, reinforced work surface for preparing carcasses."
	architect_tab = RW_ARCHITECT_TAB_PRODUCTION
	build_path = /obj/building/production/crafting/butcher_table
	multiblock_layout_id = "rw_butcher_table_3x1"
	materials = list(
		/obj/item/stack/sheet/rimworld/wood = 20,
	)
	build_steps = 12
	construction_time = 5 SECONDS


/datum/building_blueprint/simple_research
	id = "rw_simple_research"
	name = "Simple research bench"
	desc = "A basic desk for early research work."
	architect_tab = RW_ARCHITECT_TAB_PRODUCTION
	build_path = /obj/building/production/research/simple
	materials = list(
		/obj/item/stack/sheet/rimworld/wood = 5,
	)
	build_steps = 8
	construction_time = 4 SECONDS

// MARK: Attachment blueprints

/datum/building_blueprint/tool_rack
	id = "rw_tool_rack"
	name = "Tool rack"
	desc = "A wall-mounted rack that keeps tools within easy reach."
	architect_tab = RW_ARCHITECT_TAB_PRODUCTION
	build_path = /obj/building/attachment/tool_rack
	materials = list(
		/obj/item/stack/sheet/rimworld/wood = 3,
	)
	build_steps = 4
	construction_time = 2 SECONDS

/datum/building_blueprint/multi_analyzer
	id = "rw_multi_analyzer"
	name = "Multi-analyzer"
	desc = "Instruments that accelerate nearby research benches."
	architect_tab = RW_ARCHITECT_TAB_PRODUCTION
	build_path = /obj/building/attachment/analyzer
	materials = list(
		/obj/item/stack/sheet/rimworld/steel = 2,
		/obj/item/stack/rw_component/electrical = 1,
		/obj/item/stack/rw_component/circuit = 1,
	)
	build_steps = 8
	construction_time = 4 SECONDS

// MARK: Component recipes (primitive)


/datum/rw_crafting_recipe/wooden_planks_10
	id = "rw_planks_10"
	name = "Wooden planks x10"
	desc = "Split logs into straight planks for building and crafting."
	category = RW_RECEPIE_CATEGORY_WOODWORK
	result_path = /obj/item/stack/sheet/rimworld/wood
	result_amount = 10
	requirements = list(/obj/item/stack/sheet/rimworld/log = 2)
	required_bench = /obj/building/production/crafting
	craft_type = RW_CRAFT_TYPE_DELIVER
	crafting_time = 3 SECONDS
	min_skill = 0
	ideal_skill = 4
	skill_xp = 1

/datum/rw_crafting_recipe/rough_sculpture
	id = "rw_rough_sculpture"
	name = "Rough stone sculpture"
	desc = "Shape a rough decorative object from a stone block."
	category = "Artistic"
	// result_path = /obj/item/stack/sheet/rimworld/stone_brick/granite
	result_amount = 1
	requirements = list(/obj/item/stack/sheet/rimworld/granite = 1)
	required_bench = /obj/building/production/crafting/creative_table
	craft_type = RW_CRAFT_TYPE_WORKPIECE
	crafting_time = 12 SECONDS
	work_steps = 8
	min_skill = 0
	ideal_skill = 5
	skill_xp = 1

// MARK: Definitions

/obj/building/production/crafting/work_spot
	name = "Work spot"
	desc = "A clear patch of ground used for primitive handcrafting."
	icon = 'fenysha_events/icons/machinery/production/production32.dmi'

	icon_state = "work_spot"

	recipe_categories = list(
		RW_RECEPIE_CATEGORY_WOODWORK,
		RW_RECEPIE_CATEGORY_PRIMITIVE,
	)


/obj/building/production/crafting/primitive
	name = "Primitive workbench"
	desc = "A wooden bench for basic hand tools and components."
	icon = 'fenysha_events/icons/machinery/production/production64.dmi'

	icon_state = "primitive_workbench"

	recipe_categories = list(
		RW_RECEPIE_CATEGORY_WOODWORK,
		RW_RECEPIE_CATEGORY_PRIMITIVE,
		RW_RECEPIE_CATEGORY_COMPONENTS_BASIC,
	)

	possible_attachments = list(/obj/building/attachment/tool_rack)

/obj/building/production/crafting/campfire
	name = "Campfire"
	desc = "An open fire for simple cooking and heat treatment."
	icon = 'fenysha_events/icons/machinery/production/production48.dmi'
	icon_state = "campfire"
	idle_power_draw = 0
	active_power_draw = 0
	fueled = TRUE
	fuel_type = /obj/item/stack/sheet/rimworld/wood
	fuel_capacity = 20
	fuel_per_tick = 1
	fuel_amount = 5
	recipe_categories = list("Cooking", "Smelting", "Primitive")

/obj/building/production/crafting/creative_table
	name = "Sculptor's table"
	desc = "A broad handcrafting surface for decorative items."
	icon = 'fenysha_events/icons/machinery/production/production48.dmi'
	icon_state = "sculpting_table"
	idle_power_draw = 0
	active_power_draw = 0
	recipe_categories = list("Artistic", "Stoneworking")
	possible_attachments = list(/obj/building/attachment/tool_rack)

/obj/building/production/crafting/stonecutting
	name = "Stonecutting table"
	desc = "A sturdy table for shaping stone blocks into bricks."
	icon = 'fenysha_events/icons/machinery/production/production48.dmi'
	icon_state = "stonecutting_table"
	idle_power_draw = 0
	active_power_draw = 0
	recipe_categories = list("Stoneworking")
	possible_attachments = list(/obj/building/attachment/tool_rack)

/obj/building/production/crafting/primitive_stove
	name = "Primitive stove"
	desc = "A basic stone hearth for simple food preparation."
	icon = 'fenysha_events/icons/machinery/production/production48.dmi'
	icon_state = "primitive_stove"
	idle_power_draw = 0
	active_power_draw = 0
	fueled = TRUE
	fuel_type = /obj/item/stack/sheet/rimworld/wood
	fuel_capacity = 15
	fuel_per_tick = 1
	fuel_amount = 3
	recipe_categories = list("Cooking", "Primitive")

/obj/building/production/crafting/butcher_table
	name = "Butcher table"
	desc = "A wide work surface for butchering and food preparation."
	icon = 'fenysha_events/icons/machinery/production/production48.dmi'
	icon_state = "butcher_table"
	idle_power_draw = 0
	active_power_draw = 0
	recipe_categories = list("Butchering", "Cooking")
	possible_attachments = list(/obj/building/attachment/tool_rack)
