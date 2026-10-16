// MARK: Blueprints & recepies
/datum/building_blueprint/sawbuck
	id = "rw_sawbuck"
	name = "Wooden sawhorses"
	desc = "Primitive wooden sawhorses made from several logs."
	architect_tab = RW_ARCHITECT_TAB_PRODUCTION

	build_path = /obj/machinery/rw_workbench/crafting/sawbuck
	materials = list(/obj/item/stack/sheet/rimworld/log = 4)

	build_steps = 40
	construction_time = 3 SECONDS

	default_unlocked = TRUE


/datum/rw_crafting_recipe/planks_20
	id = "rw_planks_20"
	name = "Wooden planks x20"
	desc = "Chop the logs into planks."

	category = RW_RECEPIE_CATEGORY_WOODWORK

	result_path = /obj/item/stack/sheet/rimworld/wood
	result_amount = 20
	requirements = list(/obj/item/stack/sheet/rimworld/log = 4)

	craft_type = RW_CRAFT_TYPE_DELIVER
	crafting_time = 3 SECONDS
	work_steps = 12

	min_skill = 0

/datum/rw_crafting_recipe/planks_40
	id = "rw_planks_40"
	name = "Wooden planks x40"
	desc = "Chop the logs into planks."

	category = RW_RECEPIE_CATEGORY_WOODWORK

	result_path = /obj/item/stack/sheet/rimworld/wood
	result_amount = 40
	requirements = list(/obj/item/stack/sheet/rimworld/log = 8)

	craft_type = RW_CRAFT_TYPE_DELIVER
	crafting_time = 3 SECONDS
	work_steps = 24

	min_skill = 0

// MARK: Defenition
/obj/machinery/rw_workbench/crafting/sawbuck
	name = "Sawhorses"
	desc = "Primitive wooden sawhorses made from several logs. They are suitable for cutting raw logs into planks."

	icon = 'fenysha_events/icons/machinery/production/production48.dmi'
	icon_state = "sawbuck"

	recipe_categories = list(
		RW_RECEPIE_CATEGORY_WOODWORK,
	)

/obj/machinery/rw_workbench/crafting/sawbuck/Initialize(mapload)
	. = ..()
	SET_BASE_PIXEL(-8, 0)
