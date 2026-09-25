/area/interior
	name = "Vehicle Interior"
	icon = 'icons/area/areas_centcom.dmi'
	icon_state = "shuttle"
	requires_power = FALSE
	static_lighting = FALSE
	base_lighting_alpha = 128
	default_gravity = STANDARD_GRAVITY
	area_flags = UNIQUE_AREA|NOTELEPORT|HIDDEN_AREA
	sound_environment = SOUND_ENVIRONMENT_ROOM

/area/interior/tank
	name = "Tank Interior"

/area/interior/tank/som
	base_lighting_alpha = 90

/area/interior/apc
	name = "APC Interior"

/turf/closed/interior
	name = "vehicle interior"
	desc = "The inside of an armored hull."
	explosive_resistance = INFINITY
	rust_resistance = RUST_RESISTANCE_ABSOLUTE
	turf_flags = IS_SOLID | NO_RUST
	resistance_flags = INDESTRUCTIBLE
	baseturfs = /turf/closed/interior

/turf/closed/interior/TerraformTurf(path, new_baseturf, flags, defer_change = FALSE, ignore_air = FALSE)
	return

/turf/closed/interior/rcd_vals(mob/user, obj/item/construction/rcd/the_rcd)
	return FALSE

/// Tiles of hull art that are drawn over mobs standing below them
/turf/closed/interior/overhang
	plane = GAME_PLANE
	layer = ABOVE_ALL_MOB_LAYER

/turf/open/interior
	name = "vehicle interior"
	desc = "The floor of an armored hull."
	footstep = FOOTSTEP_PLATING
	barefootstep = FOOTSTEP_HARD_BAREFOOT
	clawfootstep = FOOTSTEP_HARD_CLAW
	heavyfootstep = FOOTSTEP_GENERIC_HEAVY
	resistance_flags = INDESTRUCTIBLE
	explosive_resistance = INFINITY
	baseturfs = /turf/open/interior
	initial_gas_mix = OPENTURF_DEFAULT_ATMOS

/turf/open/interior/TerraformTurf(path, new_baseturf, flags, defer_change = FALSE, ignore_air = FALSE)
	return

/turf/open/interior/rcd_vals(mob/user, obj/item/construction/rcd/the_rcd)
	return FALSE

/turf/open/interior/burn_tile()
	return

/turf/open/interior/break_tile()
	return

/// The hatch leading out of the vehicle
/turf/closed/interior/tank/door
	name = "exit hatch"
	desc = "Click it to climb out. Drag someone onto it to throw them out."
	icon = 'fenysha_events/icons/vehicles/armored/3x3/tank_interior.dmi'
	icon_state = "tank_interior_7"
	/// Direction mobs face when they climb in
	var/enter_dir = EAST
	var/obj/vehicle/sealed/armored/owner

/turf/closed/interior/tank/door/Destroy()
	owner = null
	return ..()

/turf/closed/interior/tank/door/link_interior(datum/interior/link)
	if(!istype(link, /datum/interior/armored))
		CRASH("invalid interior [link.type] passed to [name]")
	var/datum/interior/armored/inside = link
	inside.door = src
	owner = inside.container

/turf/closed/interior/tank/door/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if(.)
		return
	if(user.Adjacent(src))
		owner?.interior?.mob_leave(user)
	return TRUE

/turf/closed/interior/tank/door/attack_ghost(mob/dead/observer/user)
	. = ..()
	if(owner)
		user.forceMove(get_turf(owner))

/turf/closed/interior/tank/door/mouse_drop_receive(atom/dropped, mob/user, params)
	if(!owner?.interior || !isliving(user) || !user.Adjacent(src))
		return
	if(ismob(dropped))
		var/mob/thrown_out = dropped
		if(thrown_out != user && !thrown_out.Adjacent(src))
			return
		owner.interior.mob_leave(thrown_out)
		return
	if(ismovable(dropped) && is_type_in_typecache(dropped, owner.easy_load_list) && user.Adjacent(dropped))
		var/atom/movable/unloaded = dropped
		if(isitem(unloaded) && !user.temporarilyRemoveItemFromInventory(unloaded))
			return
		unloaded.forceMove(owner.exit_location(unloaded))
		balloon_alert(user, "thrown outside")

/turf/closed/interior/tank/door/proc/get_enter_location()
	return get_step(src, enter_dir)

/turf/closed/interior/tank/door/som
	icon = 'fenysha_events/icons/vehicles/armored/3x4/som_tank_interior.dmi'
	icon_state = "hatch"
	plane = FLOOR_PLANE
	enter_dir = NORTH

/turf/closed/interior/tank/door/som/Initialize(mapload)
	. = ..()
	update_appearance(UPDATE_OVERLAYS)

/turf/closed/interior/tank/door/som/update_overlays()
	. = ..()
	var/mutable_appearance/hatch_decal = mutable_appearance(icon, "hatch_decal", RUNE_LAYER, src, FLOOR_PLANE)
	hatch_decal.pixel_z = 24
	. += hatch_decal

/// A seat that hands vehicle controls to whoever sits in it and shows them the outside
/obj/structure/chair/vehicle_crew
	name = "crew seat"
	icon = 'fenysha_events/icons/vehicles/armored/3x3/tank_interior.dmi'
	icon_state = "vehicle_chair"
	resistance_flags = INDESTRUCTIBLE
	dir = EAST
	item_chair = null
	fishing_modifier = 0
	var/obj/vehicle/sealed/armored/owner
	var/control_flags = NONE
	/// Tiles added to the view radius while seated
	var/view_range_mod = 1

/obj/structure/chair/vehicle_crew/MakeRotate()
	return

/obj/structure/chair/vehicle_crew/Destroy()
	owner = null
	return ..()

/obj/structure/chair/vehicle_crew/link_interior(datum/interior/link)
	owner = link.container

/obj/structure/chair/vehicle_crew/wrench_act_secondary(mob/living/user, obj/item/weapon)
	return ITEM_INTERACT_BLOCKING

/obj/structure/chair/vehicle_crew/update_overlays()
	. = ..()
	if(has_buckled_mobs())
		. += mutable_appearance(icon, "[icon_state]_occupied", ABOVE_MOB_LAYER)

/obj/structure/chair/vehicle_crew/post_buckle_mob(mob/living/buckled)
	. = ..()
	update_appearance(UPDATE_OVERLAYS)
	if(!owner)
		return
	if(!owner.is_occupant(buckled))
		owner.add_occupant(buckled)
	if(control_flags)
		owner.add_control_flags(buckled, control_flags)
	buckled.reset_perspective(owner)
	buckled.client?.view_size.add(view_range_mod * 2)

/obj/structure/chair/vehicle_crew/post_unbuckle_mob(mob/living/unbuckled)
	. = ..()
	update_appearance(UPDATE_OVERLAYS)
	unbuckled.reset_perspective()
	unbuckled.client?.view_size.resetToDefault()
	if(owner && control_flags)
		owner.remove_control_flags(unbuckled, control_flags)

/obj/structure/chair/vehicle_crew/relaymove(mob/living/user, direction)
	return owner?.relaymove(user, direction)

/obj/structure/chair/vehicle_crew/driver
	name = "driver seat"
	control_flags = VEHICLE_CONTROL_DRIVE|VEHICLE_CONTROL_SETTINGS
	view_range_mod = 4

/obj/structure/chair/vehicle_crew/gunner
	name = "gunner seat"
	control_flags = VEHICLE_CONTROL_MELEE|VEHICLE_CONTROL_EQUIPMENT
	view_range_mod = 3

/obj/structure/chair/vehicle_crew/driver_gunner
	name = "commander seat"
	control_flags = VEHICLE_CONTROL_MELEE|VEHICLE_CONTROL_EQUIPMENT|VEHICLE_CONTROL_DRIVE|VEHICLE_CONTROL_SETTINGS
	view_range_mod = 4

/obj/structure/chair/vehicle_crew/driver/som
	icon = 'fenysha_events/icons/vehicles/armored/3x4/som_interior_small_props.dmi'
	icon_state = "driver_chair"
	dir = NORTH

/obj/structure/chair/vehicle_crew/driver/som/handle_layer()
	return

/obj/structure/chair/vehicle_crew/gunner/som
	icon = 'fenysha_events/icons/vehicles/armored/3x4/som_interior_small_props.dmi'
	icon_state = "chair"
	dir = NORTH

/obj/structure/chair/vehicle_crew/gunner/som/handle_layer()
	return

/// Plain seat with no controls
/obj/structure/chair/loader_seat
	name = "loader seat"
	icon = 'fenysha_events/icons/vehicles/armored/3x3/tank_interior.dmi'
	icon_state = "vehicle_chair"
	resistance_flags = INDESTRUCTIBLE
	dir = EAST
	item_chair = null
	fishing_modifier = 0

/obj/structure/chair/loader_seat/MakeRotate()
	return

/obj/structure/chair/loader_seat/wrench_act_secondary(mob/living/user, obj/item/weapon)
	return ITEM_INTERACT_BLOCKING

/obj/structure/chair/loader_seat/post_buckle_mob(mob/living/buckled)
	. = ..()
	update_appearance(UPDATE_OVERLAYS)

/obj/structure/chair/loader_seat/post_unbuckle_mob(mob/living/unbuckled)
	. = ..()
	update_appearance(UPDATE_OVERLAYS)

/obj/structure/chair/loader_seat/update_overlays()
	. = ..()
	if(has_buckled_mobs())
		. += mutable_appearance(icon, "[icon_state]_occupied", ABOVE_MOB_LAYER)

/obj/structure/chair/loader_seat/som
	icon = 'fenysha_events/icons/vehicles/armored/3x4/som_interior_small_props.dmi'
	icon_state = "chair"
	dir = NORTH

/obj/structure/chair/loader_seat/som/handle_layer()
	return

/// Troop bench for the transport interiors
/obj/structure/chair/vehicle_bench
	name = "vehicle seat"
	desc = "Stops you from bouncing around inside the vehicle. You don't see a seatbelt."
	icon = 'icons/obj/chairs.dmi'
	icon_state = "shuttle_chair"
	resistance_flags = INDESTRUCTIBLE
	item_chair = null
	fishing_modifier = 0

/obj/structure/chair/vehicle_bench/wrench_act_secondary(mob/living/user, obj/item/weapon)
	return ITEM_INTERACT_BLOCKING
