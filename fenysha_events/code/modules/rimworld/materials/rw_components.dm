// MARK: Components

/obj/item/stack/rw_component
	name = "Component"
	desc = "A basic component."
	icon_state = "ingot_grayscale"
	inhand_icon_state = "ingot_grayscale"
	base_icon_state = "ingot_grayscale"
	icon = 'fenysha_events/icons/items/rimworld_materials.dmi'
	righthand_file = 'fenysha_events/icons/items/inhand/rimworld_materials.dmi'
	lefthand_file = 'fenysha_events/icons/items/inhand/rimworld_materials.dmi'

	abstract_type = /obj/item/stack/sheet/rimworld
	max_amount = 20

	throwforce = 0

	w_class = WEIGHT_CLASS_SMALL

	merge_type = /obj/item/stack/rw_component
	novariants = FALSE
	usable_for_construction = TRUE

	rw_base_value = 20

	var/use_material_color = FALSE
	var/require_twohands = FALSE
	var/datum/material/rimworld_material/rimworld_mat_type = null


/obj/item/stack/rw_component/copper_wire
	name = "Copper widing"
	desc = "A coil of simple copper wire. It conducts electricity very well."

	icon_state = "copper_winding"
	inhand_icon_state = "copper_winding"
	base_icon_state = "copper_winding"

	max_amount = 250
	rw_base_value = 1
	w_class = WEIGHT_CLASS_SMALL

	merge_type = /obj/item/stack/rw_component/copper_wire
	custom_materials = list(
		/obj/item/stack/sheet/rimworld/copper = SMALL_MATERIAL_AMOUNT,
	)


/obj/item/stack/rw_component/wire
	name = "Insulted copper wire"
	desc = "A coil of simple copper wire. It conducts electricity very well."

	icon_state = "wire"
	inhand_icon_state = "wire"
	base_icon_state = "wire"

	max_amount = 250
	rw_base_value = 4
	w_class = WEIGHT_CLASS_SMALL

	merge_type = /obj/item/stack/rw_component/wire


/obj/item/stack/rw_component/mechanical
	name = "Mechanical Component"
	desc = "A set of bearings, gears, and tubes for the mechanical components of complex machines."

	icon_state = "component_mechanical"
	inhand_icon_state = "component_mechanical"
	base_icon_state = "component_mechanical"

	novariants = TRUE
	max_amount = 20
	rw_base_value = 40
	w_class = WEIGHT_CLASS_NORMAL

	merge_type = /obj/item/stack/rw_component/mechanical


/obj/item/stack/rw_component/vacum_tubes
	name = "Vacuum Tube"
	desc = "A fundamental component of many computer networks."

	icon_state = "component_vtube"
	inhand_icon_state = "component_vtube"
	base_icon_state = "component_vtube"

	novariants = TRUE
	max_amount = 40
	rw_base_value = 20
	w_class = WEIGHT_CLASS_SMALL

	merge_type = /obj/item/stack/rw_component/vacum_tubes


/obj/item/stack/rw_component/electrical
	name = "Electrical Components"
	desc = "A set of transistors, resistors, and other electrical components used inside the electrical systems of machines."

	icon_state = "components_electrical"
	inhand_icon_state = "components_electrical"
	base_icon_state = "components_electrical"

	novariants = TRUE
	max_amount = 20
	rw_base_value = 67
	w_class = WEIGHT_CLASS_NORMAL

	merge_type = /obj/item/stack/rw_component/electrical


/obj/item/stack/rw_component/circuit
	name = "Simple Circuit Board"
	desc = "A simple wooden circuit board, perfect for basic machines."

	icon_state = "component_circuit"
	inhand_icon_state = "component_circuit"
	base_icon_state = "component_circuit"

	novariants = TRUE
	max_amount = 10
	rw_base_value = 111
	w_class = WEIGHT_CLASS_NORMAL

	merge_type = /obj/item/stack/rw_component/circuit


/obj/item/stack/rw_component/circuit_advanced
	name = "Advanced circuit Board"
	desc = "A advacned circuit board, ideal for advanced electronic components."

	icon_state = "component_circuit_adv"
	inhand_icon_state = "component_circuit_adv"
	base_icon_state = "component_circuit_adv"

	novariants = TRUE
	max_amount = 10
	rw_base_value = 247
	w_class = WEIGHT_CLASS_NORMAL

	merge_type = /obj/item/stack/rw_component/circuit_advanced


/obj/item/stack/rw_component/screen
	name = "Simple Screen"
	desc = "Simple screen assembly with a couple of wires inside and a basic controller."

	icon_state = "component_screen"
	inhand_icon_state = "component_screen"
	base_icon_state = "component_screen"

	novariants = TRUE
	max_amount = 5
	rw_base_value = 113
	w_class = WEIGHT_CLASS_NORMAL

	merge_type = /obj/item/stack/rw_component/screen



/obj/item/stack/rw_component/hydraulic_component
	name = "Hydraulic component"
	desc = "A set of presses, pumps, and rotors. Ideal for hydraulic machine components."

	icon_state = "component_tubes"
	inhand_icon_state = "component_tubes"
	base_icon_state = "component_tubes"

	novariants = TRUE
	max_amount = 20
	rw_base_value = 40
	w_class = WEIGHT_CLASS_NORMAL

	merge_type = /obj/item/stack/rw_component/hydraulic_component

/obj/item/stack/rw_component/pipe
	name = "Pipe components"
	desc = "A set of rivets, plates, and channels for making pipes."

	icon_state = "component_pipe"
	inhand_icon_state = "component_pipe"
	base_icon_state = "component_pipe"

	novariants = TRUE
	max_amount = 80
	rw_base_value = 10
	w_class = WEIGHT_CLASS_NORMAL

	merge_type = /obj/item/stack/rw_component/pipe

// MARK: Blueprints

/datum/rw_crafting_recipe/copper_wire
	id = "rw_copper_wire5"
	name = "Copper wire x5"
	desc = "Draw copper into thin conductive wire."

	category = RW_RECEPIE_CATEGORY_ELECTIC_BASIC

	result_path = /obj/item/stack/rw_component/copper_wire
	result_amount = 5
	requirements = list(
		/obj/item/stack/sheet/rimworld/copper = 1,
	)
	craft_type = RW_CRAFT_TYPE_DELIVER
	crafting_time = 2 SECONDS
	work_steps = 5
	min_skill = 4
	ideal_skill = 8
	skill_xp = RW_SKILL_POINTS_MINOR

/datum/rw_crafting_recipe/copper_wire/x20
	id = "rw_copper_wire20"
	name = "Copper wire x20"
	desc = "Draw copper into thin conductive wire."

	category = RW_RECEPIE_CATEGORY_ELECTIC_BASIC

	result_amount = 20
	requirements = list(
		/obj/item/stack/sheet/rimworld/copper = 4,
	)

	craft_type = RW_CRAFT_TYPE_DELIVER
	work_steps = 20


/datum/rw_crafting_recipe/insulated_wires
	id = "rw_insulated_wires"
	name = "Insulated wires x5"
	desc = "Wrap copper wire in a layer of insulating cloth."

	category = RW_RECEPIE_CATEGORY_ELECTIC_BASIC

	result_path = /obj/item/stack/rw_component/wire
	result_amount = 5

	requirements = list(
		/obj/item/stack/rw_component/copper_wire = 5,
		/obj/item/stack/sheet/rimworld/cloth = 1,
	)

	craft_type = RW_CRAFT_TYPE_DELIVER

	crafting_time = 2 SECONDS
	work_steps = 20

	min_skill = 4
	ideal_skill = 8
	skill_xp = RW_SKILL_POINTS_SMALL


/datum/rw_crafting_recipe/insulated_wires/x20
	id = "rw_insulated_wires"
	name = "Insulated wires x20"
	desc = "Wrap copper wire in a layer of insulating cloth."

	category = RW_RECEPIE_CATEGORY_ELECTIC_BASIC

	result_path = /obj/item/stack/rw_component/wire
	result_amount = 20

	requirements = list(
		/obj/item/stack/rw_component/copper_wire = 20,
		/obj/item/stack/sheet/rimworld/cloth = 4,
	)

	work_steps = 80


/datum/rw_crafting_recipe/pipe_component
	id = "rw_pipe_component5"
	name = "Pipe components x5"
	desc = "Roll steel ingots into pipe components"

	category = RW_RECEPIE_CATEGORY_COMPONENTS_BASIC

	result_amount = 5
	requirements = list(
		/obj/item/stack/sheet/rimworld/steel = 3,
	)

	min_skill = 6
	ideal_skill = 10
	skill_xp = RW_SKILL_POINTS_SMALL

	craft_type = RW_CRAFT_TYPE_DELIVER
	crafting_time = 3 SECONDS
	work_steps = 15


/datum/rw_crafting_recipe/pipe_component/x20
	id = "rw_pipe_component20"
	name = "Pipe components x20"
	desc = "Roll steel ingots into pipe components"

	result_amount = 20
	requirements = list(
		/obj/item/stack/sheet/rimworld/steel = 12,
	)

	craft_type = RW_CRAFT_TYPE_DELIVER
	work_steps = 60


/datum/rw_crafting_recipe/circuit_boards
	id = "rw_circuit_boards"
	name = "Primitive circuit boards x3"
	desc = "Route copper wiring over a simple insulating board."

	category = RW_RECEPIE_CATEGORY_ELECTIC_BASIC

	result_path = /obj/item/stack/rw_component/circuit
	result_amount = 3
	requirements = list(
		/obj/item/stack/sheet/rimworld/wood = 4,
		/obj/item/stack/rw_component/copper_wire = 10,
	)

	craft_type = RW_CRAFT_TYPE_WORKPIECE

	crafting_time = 3 SECONDS
	work_steps = 60

	min_skill = 8
	ideal_skill = 12
	skill_xp = RW_SKILL_POINTS_LARGE


/datum/rw_crafting_recipe/circuit_boards_adv
	id = "rw_circuit_boards_adv"
	name = "Advanced circuit boards x3"
	desc = "Route copper wiring over a simple insulating board."

	category = RW_RECEPIE_CATEGORY_ELECTIC_ADVANCED

	result_path = /obj/item/stack/rw_component/circuit_advanced
	result_amount = 3
	requirements = list(
		/obj/item/stack/rw_component/circuit = 3,
		/obj/item/stack/sheet/rimworld/gold = 3,
		/obj/item/stack/sheet/rimworld/silver = 3,
		/obj/item/stack/rw_component/wire = 6,
	)

	craft_type = RW_CRAFT_TYPE_WORKPIECE

	crafting_time = 3 SECONDS
	work_steps = 180

	min_skill = 12
	ideal_skill = 15
	skill_xp = RW_SKILL_POINTS_HUGE


/datum/rw_crafting_recipe/led_screen
	id = "rw_led_scren"
	name = "Advanced circuit boards x3"
	desc = "Route copper wiring over a simple insulating board."

	category = RW_RECEPIE_CATEGORY_ELECTIC_ADVANCED

	result_path = /obj/item/stack/rw_component/circuit_advanced
	result_amount = 3
	requirements = list(
		/obj/item/stack/rw_component/circuit = 3,
		/obj/item/stack/sheet/rimworld/gold = 3,
		/obj/item/stack/sheet/rimworld/silver = 3,
		/obj/item/stack/rw_component/wire = 6,
	)

	craft_type = RW_CRAFT_TYPE_WORKPIECE

	crafting_time = 3 SECONDS
	work_steps = 180

	min_skill = 12
	ideal_skill = 15
	skill_xp = RW_SKILL_POINTS_HUGE



/datum/rw_crafting_recipe/mechanical_components
	id = "rw_mechanical_components"
	name = "Mechanical components x2"
	desc = "Machine gears, linkages and fasteners from metal and primitive parts."

	category = RW_RECEPIE_CATEGORY_COMPONENTS_BASIC

	result_path = /obj/item/stack/rw_component/mechanical
	result_amount = 2

	requirements = list(
		/obj/item/stack/sheet/rimworld/steel = 11,
	)


	craft_type = RW_CRAFT_TYPE_WORKPIECE

	crafting_time = 2 SECONDS
	work_steps = 32

	min_skill = 7
	ideal_skill = 11
	skill_xp = RW_SKILL_POINTS_NORMAL


/datum/rw_crafting_recipe/electrical_components
	id = "rw_electrical_components"
	name = "Electrical components x2"
	desc = "Assemble conductors and primitive components into an electrical unit."

	category = RW_RECEPIE_CATEGORY_ELECTIC_BASIC

	result_path = /obj/item/stack/rw_component/electrical
	result_amount = 2

	requirements = list(
		/obj/item/stack/rw_component/copper_wire = 10,
		/obj/item/stack/sheet/rimworld/steel = 10,
		/obj/item/stack/sheet/rimworld/silver = 3,
	)

	craft_type = RW_CRAFT_TYPE_WORKPIECE
	crafting_time = 2 SECONDS
	work_steps = 40

	min_skill = 10
	ideal_skill = 12
	skill_xp = RW_SKILL_POINTS_NORMAL


/datum/rw_crafting_recipe/hydraulic_components
	id = "rw_hydraulic_components"
	name = "Hydraulic components x2"
	desc = "Assemble pressure-rated valves, pistons, and tubing."

	category = RW_RECEPIE_CATEGORY_COMPONENTS_BASIC

	result_path = /obj/item/stack/rw_component/hydraulic_component
	result_amount = 2
	requirements = list(
		/obj/item/stack/rw_component/pipe = 4,
		/obj/item/stack/rw_component/mechanical = 2,
		/obj/item/stack/sheet/rimworld/silver = 4,
	)

	craft_type = RW_CRAFT_TYPE_WORKPIECE
	crafting_time = 2 SECONDS
	work_steps = 32

	min_skill = 6
	ideal_skill = 10
	skill_xp = RW_SKILL_POINTS_NORMAL
