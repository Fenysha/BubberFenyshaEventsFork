/obj/item/stack/ore/rimworld
	name = "ore"
	icon = 'fenysha_events/icons/items/rimworld_ores.dmi'
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

// ===================== BASE ORES =====================

/obj/item/stack/ore/rimworld/iron
	name = "iron ore"
	icon_state = "hematite"
	singular_name = "iron ore chunk"
	points = 4
	rimworld_mat = /datum/material/rimworld_material/steel
	refined_type = /obj/item/stack/sheet/rimworld/steel
	mine_experience = 3
	scan_state = "rock_steel"
	spread_chance = 60
	merge_type = /obj/item/stack/ore/rimworld/iron
	min_vein_size = 2
	max_vein_size = 5

/obj/item/stack/ore/rimworld/copper
	name = "copper ore"
	icon_state = "malachite"
	singular_name = "copper ore chunk"
	points = 5
	rimworld_mat = /datum/material/rimworld_material/copper
	refined_type = /obj/item/stack/sheet/rimworld/copper
	mine_experience = 3
	scan_state = "rock_copper"
	spread_chance = 50
	merge_type = /obj/item/stack/ore/rimworld/copper
	min_vein_size = 2
	max_vein_size = 4

/obj/item/stack/ore/rimworld/coal
	name = "coal"
	icon_state = "blackcoal"
	singular_name = "coal chunk"
	points = 3
	rimworld_mat = /datum/material/rimworld_material/coal
	refined_type = /obj/item/stack/sheet/rimworld/coal
	mine_experience = 2
	scan_state = "rock_coal"
	spread_chance = 55
	merge_type = /obj/item/stack/ore/rimworld/coal
	min_vein_size = 3
	max_vein_size = 6

// ===================== ADVANCED / RARE =====================

/obj/item/stack/ore/rimworld/uranium
	name = "uranium ore"
	icon_state = "galena"
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
	icon_state = "gold"
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
	icon_state = "silver"
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
	icon_state = "pitchenblade"
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
