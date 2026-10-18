/*
/datum/building_blueprint/wood_floor
	id = "rw_wood_floor"
	name = "Wooden floor"
	desc = "Simple wooden planking."
	architect_tab = RW_ARCHITECT_TAB_STRUCTURE
	build_path = /turf/open/floor/rw/wood
	materials = list(/obj/item/stack/sheet/rimworld/wood = 5)
	build_steps = 10
	construction_time = 2 SECONDS
	can_rotate = FALSE
	default_unlocked = TRUE

/datum/building_blueprint/wood_parquet
	id = "rw_wood_parquet"
	name = "Wooden parquet"
	desc = "Fine wooden parquet flooring."
	architect_tab = RW_ARCHITECT_TAB_STRUCTURE
	build_path = /turf/open/floor/rw/wood/parquet
	materials = list(/obj/item/stack/sheet/rimworld/wood = 10)
	build_steps = 15
	construction_time = 2.5 SECONDS
	can_rotate = FALSE

/datum/building_blueprint/wood_parquet_fancy
	id = "rw_wood_parquet_fancy"
	name = "Fancy parquet"
	desc = "Ornate parquet pattern for prestige rooms."
	architect_tab = RW_ARCHITECT_TAB_STRUCTURE
	build_path = /turf/open/floor/rw/wood/parquet/fancy
	materials = list(/obj/item/stack/sheet/rimworld/wood = 25)
	build_steps = 30
	construction_time = 3 SECONDS
	can_rotate = FALSE

// ---------------------------------------------------------------------------
// Stone floors / paving
// ---------------------------------------------------------------------------

/datum/building_blueprint/stone_floor
	id = "rw_stone_floor"
	name = "Stone floor"
	desc = "Rough-cut stone paving."
	architect_tab = RW_ARCHITECT_TAB_STRUCTURE
	build_path = /turf/open/floor/rw/stone
	materials = list(/obj/item/stack/sheet/rimworld/granite = 1)
	build_steps = 2
	construction_time = 2 SECONDS
	can_rotate = FALSE
	default_unlocked = TRUE

/datum/building_blueprint/stone_floor/marble
	id = "rw_marble_floor"
	name = "Marble floor"
	desc = "Polished marble tiles."
	build_path = /turf/open/floor/rw/stone/marble
	materials = list(/obj/item/stack/sheet/rimworld/marble = 1)

/datum/building_blueprint/stone_floor/sandstone
	id = "rw_sandstone_floor"
	name = "Sandstone floor"
	desc = "Warm sandstone paving."
	build_path = /turf/open/floor/rw/stone/sandstone
	materials = list(/obj/item/stack/sheet/rimworld/sandstone = 1)

/datum/building_blueprint/stone_floor/slate
	id = "rw_slate_floor"
	name = "Slate floor"
	desc = "Dark slate tiles."
	build_path = /turf/open/floor/rw/stone/slate
	materials = list(/obj/item/stack/sheet/rimworld/slate = 1)

/datum/building_blueprint/stone_paving
	id = "rw_stone_paving"
	name = "Stone paving"
	desc = "Heavy outdoor paving stones."
	architect_tab = RW_ARCHITECT_TAB_STRUCTURE
	build_path = /turf/open/floor/rw/stone/paving
	materials = list(/obj/item/stack/sheet/rimworld/granite = 2)
	build_steps = 3
	construction_time = 2.5 SECONDS
	can_rotate = FALSE

// ---------------------------------------------------------------------------
// Walls (declare in turfs package for architect UI)
// ---------------------------------------------------------------------------

/datum/building_blueprint/stone_wall
	id = "rw_stone_wall"
	name = "Stone wall"
	desc = "A solid stone wall."
	architect_tab = RW_ARCHITECT_TAB_STRUCTURE
	build_path = /turf/closed/rw_wall/stone
	materials = list(/obj/item/stack/sheet/rimworld/granite = 4)
	build_steps = 8
	construction_time = 4 SECONDS
	can_rotate = FALSE

/datum/building_blueprint/stone_wall/marble
	id = "rw_marble_wall"
	name = "Marble wall"
	desc = "A polished marble wall."
	build_path = /turf/closed/rw_wall/stone/marble
	materials = list(/obj/item/stack/sheet/rimworld/marble = 4)

/datum/building_blueprint/wooden_wall
	id = "rw_wooden_wall"
	name = "Wooden wall"
	desc = "A sturdy wooden wall."
	architect_tab = RW_ARCHITECT_TAB_STRUCTURE
	build_path = /turf/closed/rw_wall/wood
	materials = list(/obj/item/stack/sheet/rimworld/wood = 4)
	build_steps = 6
	construction_time = 3 SECONDS
	can_rotate = FALSE
	default_unlocked = TRUE
*/
