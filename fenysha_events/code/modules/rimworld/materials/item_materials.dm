GLOBAL_LIST_INIT(rimworld_sheet_recipes, list(
	new/datum/stack_recipe("floor tile", /obj/item/stack/tile/iron/base, 1, 4, 20, category = CAT_TILES),
	new/datum/stack_recipe("wall girders (anchored)", /obj/structure/girder, 2, time = 4 SECONDS, crafting_flags = CRAFT_CHECK_DENSITY | CRAFT_ONE_PER_TURF | CRAFT_ON_SOLID_GROUND, category = CAT_STRUCTURE),
	null,
))


/obj/item/stack/sheet/rimworld
	name = "rimworld sheet"
	desc = "A sheet of material from the Rim."
	icon_state = "sheet-metal"
	inhand_icon_state = "sheet-metal"
	icon = 'fenysha_events/icons/items/rimworld_materials.dmi'

	abstract_type = /obj/item/stack/sheet/rimworld
	material_flags = MATERIAL_EFFECTS | MATERIAL_GREYSCALE
	max_amount = 50
	throwforce = 10
	w_class = WEIGHT_CLASS_NORMAL
	merge_type = /obj/item/stack/sheet/rimworld
	novariants = FALSE
	usable_for_construction = TRUE
	table_type = /obj/structure/table/greyscale


	var/datum/material/rimworld_material/rimworld_mat_type = null

/obj/item/stack/sheet/rimworld/Initialize(mapload, new_amount, merge = TRUE, list/mat_override = null, mat_amt = 1)
	if(rimworld_mat_type)
		mats_per_unit = list(rimworld_mat_type = SHEET_MATERIAL_AMOUNT)
		material_type = rimworld_mat_type
	. = ..()

/obj/item/stack/sheet/rimworld/get_main_recipes()
	. = ..()
	. += GLOB.rimworld_sheet_recipes




/obj/item/stack/sheet/rimworld/steel
	name = "steel"
	singular_name = "steel sheet"
	desc = "Sheets of steel. The backbone of any colony."
	icon_state = "sheet-metal"
	inhand_icon_state = "sheet-metal"
	rimworld_mat_type = /datum/material/rimworld_material/steel
	merge_type = /obj/item/stack/sheet/rimworld/steel
	obj_flags = CONDUCTS_ELECTRICITY
	resistance_flags = FIRE_PROOF
	gulag_value = 5
	matter_amount = 4
	sniffable = TRUE

/obj/item/stack/sheet/rimworld/steel/fifty
	amount = 50

/obj/item/stack/sheet/rimworld/steel/twenty
	amount = 20

/obj/item/stack/sheet/rimworld/steel/ten
	amount = 10

/obj/item/stack/sheet/rimworld/steel/five
	amount = 5


/obj/item/stack/sheet/rimworld/plasteel
	name = "plasteel"
	singular_name = "plasteel sheet"
	desc = "An advanced composite of steel and other materials. Extremely tough."
	icon_state = "sheet-plasteel"
	inhand_icon_state = "sheet-plasteel"
	rimworld_mat_type = /datum/material/rimworld_material/plasteel
	merge_type = /obj/item/stack/sheet/rimworld/plasteel
	obj_flags = CONDUCTS_ELECTRICITY
	resistance_flags = FIRE_PROOF
	gulag_value = 10
	matter_amount = 12
	armor_type = /datum/armor/sheet_plasteel

/obj/item/stack/sheet/rimworld/plasteel/fifty
	amount = 50

/obj/item/stack/sheet/rimworld/plasteel/twenty
	amount = 20


/obj/item/stack/sheet/rimworld/uranium
	name = "uranium"
	singular_name = "uranium sheet"
	desc = "Dense, heavy sheets of uranium. Excellent for armor and blunt weapons."
	icon_state = "sheet-uranium"
	rimworld_mat_type = /datum/material/rimworld_material/uranium
	merge_type = /obj/item/stack/sheet/rimworld/uranium
	obj_flags = CONDUCTS_ELECTRICITY
	resistance_flags = FIRE_PROOF
	gulag_value = 8
	matter_amount = 8

/obj/item/stack/sheet/rimworld/uranium/fifty
	amount = 50


/obj/item/stack/sheet/rimworld/gold
	name = "gold"
	singular_name = "gold sheet"
	desc = "Sheets of pure gold. Soft, beautiful, never tarnishes."
	icon_state = "sheet-gold"
	rimworld_mat_type = /datum/material/rimworld_material/gold
	merge_type = /obj/item/stack/sheet/rimworld/gold
	obj_flags = CONDUCTS_ELECTRICITY
	gulag_value = 15
	matter_amount = 6

/obj/item/stack/sheet/rimworld/gold/fifty
	amount = 50


/obj/item/stack/sheet/rimworld/silver
	name = "silver"
	singular_name = "silver sheet"
	desc = "Sheets of silver. Soft but beautiful."
	icon_state = "sheet-silver"
	rimworld_mat_type = /datum/material/rimworld_material/silver
	merge_type = /obj/item/stack/sheet/rimworld/silver
	obj_flags = CONDUCTS_ELECTRICITY
	gulag_value = 7
	matter_amount = 5

/obj/item/stack/sheet/rimworld/silver/fifty
	amount = 50


/obj/item/stack/sheet/rimworld/bioferrite
	name = "bioferrite"
	singular_name = "bioferrite sheet"
	desc = "An exotic metal-like fibrous substance."
	icon_state = "sheet-bioferrite"
	rimworld_mat_type = /datum/material/rimworld_material/bioferrite
	merge_type = /obj/item/stack/sheet/rimworld/bioferrite
	obj_flags = CONDUCTS_ELECTRICITY
	gulag_value = 6
	matter_amount = 7

/obj/item/stack/sheet/rimworld/bioferrite/fifty
	amount = 50


/obj/item/stack/sheet/rimworld/granite
	name = "granite blocks"
	singular_name = "granite block"
	desc = "Blocks of solid granite. Very hard."
	icon_state = "stone_block"
	rimworld_mat_type = /datum/material/rimworld_material/granite
	merge_type = /obj/item/stack/sheet/rimworld/granite
	resistance_flags = FIRE_PROOF
	gulag_value = 3
	matter_amount = 3

/obj/item/stack/sheet/rimworld/marble
	name = "marble blocks"
	singular_name = "marble block"
	desc = "Blocks of solid marble. Soft and beautiful."
	icon_state = "stone_block"
	rimworld_mat_type = /datum/material/rimworld_material/marble
	merge_type = /obj/item/stack/sheet/rimworld/marble
	resistance_flags = FIRE_PROOF
	gulag_value = 3

/obj/item/stack/sheet/rimworld/limestone
	name = "limestone blocks"
	singular_name = "limestone block"
	desc = "Blocks of solid limestone."
	icon_state = "stone_block"
	rimworld_mat_type = /datum/material/rimworld_material/limestone
	merge_type = /obj/item/stack/sheet/rimworld/limestone
	resistance_flags = FIRE_PROOF
	gulag_value = 3

/obj/item/stack/sheet/rimworld/sandstone
	name = "sandstone blocks"
	singular_name = "sandstone block"
	desc = "Blocks of solid sandstone. Relatively soft."
	icon_state = "stone_block"
	rimworld_mat_type = /datum/material/rimworld_material/sandstone
	merge_type = /obj/item/stack/sheet/rimworld/sandstone
	resistance_flags = FIRE_PROOF
	gulag_value = 3

/obj/item/stack/sheet/rimworld/slate
	name = "slate blocks"
	singular_name = "slate block"
	desc = "Blocks of solid slate."
	icon_state = "stone_block"
	rimworld_mat_type = /datum/material/rimworld_material/slate
	merge_type = /obj/item/stack/sheet/rimworld/slate
	resistance_flags = FIRE_PROOF
	gulag_value = 3

/obj/item/stack/sheet/rimworld/jade
	name = "jade"
	singular_name = "jade chunk"
	desc = "A hard, green stone. Beautiful and dense."
	icon_state = "jade_crystal"
	rimworld_mat_type = /datum/material/rimworld_material/jade
	merge_type = /obj/item/stack/sheet/rimworld/jade
	resistance_flags = FIRE_PROOF
	gulag_value = 12
	matter_amount = 6

/obj/item/stack/sheet/rimworld/obsidian
	name = "obsidian"
	singular_name = "obsidian chunk"
	desc = "A dark, glossy volcanic rock. Brittle but extremely sharp."
	icon_state = "sheet-obsidian"
	rimworld_mat_type = /datum/material/rimworld_material/obsidian
	merge_type = /obj/item/stack/sheet/rimworld/obsidian
	resistance_flags = FIRE_PROOF
	gulag_value = 10
	matter_amount = 5



/obj/item/stack/sheet/rimworld/wood
	name = "wooden plank"
	singular_name = "wood plank"
	desc = "One can only guess that this is a bunch of wood."
	icon_state = "sheet-wood"
	inhand_icon_state = "sheet-wood"
	rimworld_mat_type = /datum/material/rimworld_material/wood
	merge_type = /obj/item/stack/sheet/rimworld/wood
	resistance_flags = FLAMMABLE
	gulag_value = 2
	matter_amount = 2
	pickup_sound = 'sound/items/handling/materials/wood_pick_up.ogg'
	drop_sound = 'sound/items/handling/materials/wood_drop.ogg'

/obj/item/stack/sheet/rimworld/wood/fifty
	amount = 50


/obj/item/stack/sheet/rimworld/cloth
	name = "cloth"
	singular_name = "cloth roll"
	desc = "Is it cotton? Linen? Denim? Burlap? Canvas? You can't tell."
	icon_state = "sheet-cloth"
	rimworld_mat_type = /datum/material/rimworld_material/cloth
	merge_type = /obj/item/stack/sheet/rimworld/cloth
	resistance_flags = FLAMMABLE
	force = 0
	throwforce = 0
	pickup_sound = SFX_CLOTH_PICKUP
	drop_sound = SFX_CLOTH_DROP

/obj/item/stack/sheet/rimworld/cloth/ten
	amount = 10

/obj/item/stack/sheet/rimworld/cloth/five
	amount = 5


/obj/item/stack/sheet/rimworld/devilstrand
	name = "devilstrand"
	singular_name = "devilstrand roll"
	desc = "A tough, heat-resistant fabric grown from devilstrand mushrooms."
	icon_state = "sheet-cloth"
	rimworld_mat_type = /datum/material/rimworld_material/devilstrand
	merge_type = /obj/item/stack/sheet/rimworld/devilstrand
	resistance_flags = FLAMMABLE
	force = 0
	throwforce = 0

/obj/item/stack/sheet/rimworld/hyperweave
	name = "hyperweave"
	singular_name = "hyperweave roll"
	desc = "An ultra-advanced synthetic fabric of incredible strength and beauty."
	icon_state = "sheet-cloth"
	rimworld_mat_type = /datum/material/rimworld_material/hyperweave
	merge_type = /obj/item/stack/sheet/rimworld/hyperweave
	resistance_flags = FLAMMABLE
	force = 0
	throwforce = 0

/obj/item/stack/sheet/rimworld/synthread
	name = "synthread"
	singular_name = "synthread roll"
	desc = "A synthetic fabric with balanced properties."
	icon_state = "sheet-cloth"
	rimworld_mat_type = /datum/material/rimworld_material/synthread
	merge_type = /obj/item/stack/sheet/rimworld/synthread
	resistance_flags = FLAMMABLE
	force = 0
	throwforce = 0


/obj/item/stack/sheet/rimworld/plainleather
	name = "plainleather"
	singular_name = "plainleather sheet"
	desc = "Standard leather."
	icon_state = "sheet-wetleather"
	rimworld_mat_type = /datum/material/rimworld_material/plainleather
	merge_type = /obj/item/stack/sheet/rimworld/plainleather
	resistance_flags = FLAMMABLE
	force = 0
	throwforce = 0

/obj/item/stack/sheet/rimworld/thrumbofur
	name = "thrumbofur"
	singular_name = "thrumbofur sheet"
	desc = "Incredibly tough and insulating fur from a thrumbo."
	icon_state = "sheet-leather"
	rimworld_mat_type = /datum/material/rimworld_material/thrumbofur
	merge_type = /obj/item/stack/sheet/rimworld/thrumbofur
	resistance_flags = FLAMMABLE
	force = 0
	throwforce = 0

/obj/item/stack/sheet/rimworld/human_leather
	name = "human leather"
	singular_name = "human leather sheet"
	desc = "Leather made from human skin. Controversial, but functional."
	icon_state = "sheet-hairlesshide"
	rimworld_mat_type = /datum/material/rimworld_material/human_leather
	merge_type = /obj/item/stack/sheet/rimworld/human_leather
	resistance_flags = FLAMMABLE
	force = 0
	throwforce = 0
