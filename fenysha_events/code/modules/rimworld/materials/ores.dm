/obj/item/stack/ore/rimworld
	name = "ore"
	icon = 'fenysha_events/icons/items/rimworld_materials.dmi'
	icon_state = "ore"
	singular_name = "ore chunk"
	material_flags = MATERIAL_EFFECTS
	novariants = TRUE
	drop_sound = SFX_STONE_DROP
	pickup_sound = SFX_STONE_PICKUP
	sound_vary = TRUE
	points = 0
	refined_type = null
	mine_experience = 5
	scan_state = ""
	spread_chance = 0
	vein_type = ORE_VEIN_CLUSTER
	vein_distance = 1
	min_vein_size = 1
	max_vein_size = 2

	/// RimWorld material this ore refines into
	var/datum/material/rimworld_material/rimworld_mat = null
	/// How many sheets per ore unit
	var/sheets_per_ore = 1


/obj/item/stack/ore/rimworld/Initialize(mapload, new_amount, merge = TRUE, list/mat_override = null, mat_amt = 1)
	if(rimworld_mat)
		mats_per_unit = list(rimworld_mat = SHEET_MATERIAL_AMOUNT)
		material_type = rimworld_mat
	. = ..()


/obj/item/stack/ore/rimworld/welder_act(mob/living/user, obj/item/I)
	return


/obj/item/stack/ore/rimworld/steel
	name = "steel ore"
	icon_state = "ore_steel"
	singular_name = "steel ore chunk"
	points = 5
	rimworld_mat = /datum/material/rimworld_material/steel
	refined_type = /obj/item/stack/sheet/rimworld/steel
	mine_experience = 3
	scan_state = "rock_steel"
	spread_chance = 55
	merge_type = /obj/item/stack/ore/rimworld/steel
	min_vein_size = 2
	max_vein_size = 4

/obj/item/stack/ore/rimworld/plasteel
	name = "plasteel ore"
	icon_state = "ore_plasteel"
	singular_name = "plasteel ore chunk"
	points = 25
	rimworld_mat = /datum/material/rimworld_material/plasteel
	refined_type = /obj/item/stack/sheet/rimworld/plasteel
	mine_experience = 8
	scan_state = "rock_plasteel"
	spread_chance = 25
	merge_type = /obj/item/stack/ore/rimworld/plasteel
	vein_type = ORE_VEIN_PLAIN
	min_vein_size = 1
	max_vein_size = 2

/obj/item/stack/ore/rimworld/uranium
	name = "uranium ore"
	icon_state = "ore_uranium"
	singular_name = "uranium ore chunk"
	points = 30
	rimworld_mat = /datum/material/rimworld_material/uranium
	refined_type = /obj/item/stack/sheet/rimworld/uranium
	mine_experience = 7
	scan_state = "rock_uranium"
	spread_chance = 30
	merge_type = /obj/item/stack/ore/rimworld/uranium
	vein_type = ORE_VEIN_PLAIN
	min_vein_size = 1
	max_vein_size = 3

/obj/item/stack/ore/rimworld/gold
	name = "gold ore"
	icon_state = "ore_gold"
	singular_name = "gold ore chunk"
	points = 20
	rimworld_mat = /datum/material/rimworld_material/gold
	refined_type = /obj/item/stack/sheet/rimworld/gold
	mine_experience = 6
	scan_state = "rock_gold"
	spread_chance = 30
	merge_type = /obj/item/stack/ore/rimworld/gold
	vein_type = ORE_VEIN_BRANCH
	min_vein_size = 1
	max_vein_size = 2

/obj/item/stack/ore/rimworld/silver
	name = "silver ore"
	icon_state = "ore_silver"
	singular_name = "silver ore chunk"
	points = 12
	rimworld_mat = /datum/material/rimworld_material/silver
	refined_type = /obj/item/stack/sheet/rimworld/silver
	mine_experience = 4
	scan_state = "rock_silver"
	spread_chance = 35
	merge_type = /obj/item/stack/ore/rimworld/silver
	vein_type = ORE_VEIN_BRANCH
	min_vein_size = 1
	max_vein_size = 2

/obj/item/stack/ore/rimworld/bioferrite
	name = "bioferrite ore"
	icon_state = "ore_bioferrite"
	singular_name = "bioferrite ore chunk"
	points = 18
	rimworld_mat = /datum/material/rimworld_material/bioferrite
	refined_type = /obj/item/stack/sheet/rimworld/bioferrite
	mine_experience = 6
	scan_state = "rock_bioferrite"
	spread_chance = 25
	merge_type = /obj/item/stack/ore/rimworld/bioferrite
	min_vein_size = 1
	max_vein_size = 3
