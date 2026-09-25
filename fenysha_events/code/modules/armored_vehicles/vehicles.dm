/obj/vehicle/sealed/armored/multitile
	name = "\improper MT - Banteng"
	desc = "A gigantic wall of metal designed for maximum destruction. Drag yourself onto it at the rear hatch to get inside."
	icon = 'fenysha_events/icons/vehicles/armored/3x3/tank.dmi'
	icon_state = "tank"
	turret_icon = 'fenysha_events/icons/vehicles/armored/3x3/tank_gun.dmi'
	damage_icon_path = 'fenysha_events/icons/vehicles/armored/3x3/tank_damage.dmi'
	hitbox = /obj/hitbox
	interior = /datum/interior/armored
	armor_type = /datum/armor/armored_vehicle/banteng
	armored_flags = ARMORED_HAS_PRIMARY_WEAPON|ARMORED_HAS_SECONDARY_WEAPON|ARMORED_HAS_UNDERLAY|ARMORED_HAS_HEADLIGHTS|ARMORED_WRECKABLE
	pixel_x = -56
	pixel_y = -48
	max_integrity = 900
	max_occupants = 4
	movedelay = 0.75 SECONDS
	ram_damage = 100
	permitted_weapons = list(
		/obj/item/armored_weapon,
		/obj/item/armored_weapon/ltaap,
		/obj/item/armored_weapon/bfg,
		/obj/item/armored_weapon/tank_autocannon,
		/obj/item/armored_weapon/secondary_weapon,
		/obj/item/armored_weapon/secondary_flamer,
		/obj/item/armored_weapon/tow,
		/obj/item/armored_weapon/microrocket_pod,
	)
	starting_weapons = list(/obj/item/armored_weapon, /obj/item/armored_weapon/secondary_weapon)
	easy_load_list = list(/obj/item/tank_ammo)

/datum/armor/armored_vehicle/banteng
	melee = 50
	bullet = 100
	laser = 90
	energy = 60
	bomb = 60
	bio = 100
	fire = 50
	acid = 50

/obj/vehicle/sealed/armored/multitile/enter_locations(atom/movable/entering_thing)
	return list(get_step_away(get_step(src, REVERSE_DIR(dir)), src, 2))

/obj/vehicle/sealed/armored/multitile/exit_location(mob/leaving)
	return pick(enter_locations(leaving))

/// Spawns without weapons
/obj/vehicle/sealed/armored/multitile/unarmed
	starting_weapons = null

/obj/vehicle/sealed/armored/multitile/apc
	name = "\improper APC - Athena"
	desc = "A lightly armed command APC designed to carry troops across the battlefield. Drag yourself onto it at the rear hatch to get inside."
	icon = 'fenysha_events/icons/vehicles/armored/3x3/apc.dmi'
	icon_state = "apc"
	damage_icon_path = 'fenysha_events/icons/vehicles/armored/3x3/apc_damage_overlay.dmi'
	interior = /datum/interior/armored/transport
	armor_type = /datum/armor/armored_vehicle/athena
	armored_flags = ARMORED_HAS_SECONDARY_WEAPON|ARMORED_HAS_HEADLIGHTS
	turret_icon = null
	pixel_x = -48
	pixel_y = -40
	max_integrity = 600
	max_occupants = 20
	enter_delay = 0.5 SECONDS
	ram_damage = 20
	movedelay = 0.35 SECONDS
	permitted_weapons = list(
		/obj/item/armored_weapon/secondary_weapon,
		/obj/item/armored_weapon/secondary_flamer,
		/obj/item/armored_weapon/tow,
		/obj/item/armored_weapon/microrocket_pod,
	)
	starting_weapons = list(/obj/item/armored_weapon/secondary_weapon)
	easy_load_list = list(
		/obj/item/tank_ammo,
		/obj/structure/closet/crate,
	)

/datum/armor/armored_vehicle/athena
	melee = 40
	bullet = 100
	laser = 90
	energy = 60
	bomb = 60
	bio = 100
	fire = 40
	acid = 40

/obj/vehicle/sealed/armored/multitile/apc/medical
	name = "\improper APC - Athena (medical)"
	desc = "A lightly armed APC fitted out as a mobile aid station. Drag yourself onto it at the rear hatch to get inside."
	interior = /datum/interior/armored/medical

/obj/vehicle/sealed/armored/multitile/medium
	name = "\improper THV - Hades"
	desc = "A metal behemoth designed to cleave through enemy lines, with a main tank cannon capable of deploying heavy payloads."
	icon = 'fenysha_events/icons/vehicles/armored/2x2/medium_vehicles.dmi'
	icon_state = "tank"
	turret_icon = 'fenysha_events/icons/vehicles/armored/2x2/medium_vehicles.dmi'
	turret_icon_state = "tank_turret"
	hitbox = /obj/hitbox/medium
	damage_icon_path = null
	interior = null
	armored_flags = ARMORED_HAS_PRIMARY_WEAPON|ARMORED_HAS_UNDERLAY
	pixel_x = -16
	pixel_y = -32
	max_integrity = 1300
	max_occupants = 3
	starting_weapons = list(/obj/item/armored_weapon)

/obj/vehicle/sealed/armored/multitile/medium/enter_locations(atom/movable/entering_thing)
	return list(get_step(src, REVERSE_DIR(dir)))

/obj/vehicle/sealed/armored/multitile/medium/apc
	name = "\improper TAV - Nike"
	desc = "A heavily armoured vehicle with light armaments designed to ferry troops around the battlefield."
	turret_icon_state = "apc_turret"
	icon_state = "apc"
	armored_flags = ARMORED_HAS_PRIMARY_WEAPON|ARMORED_HAS_SECONDARY_WEAPON|ARMORED_HAS_UNDERLAY
	movedelay = 0.25 SECONDS
	max_occupants = 5
	starting_weapons = list(/obj/item/armored_weapon/ltaap, /obj/item/armored_weapon/secondary_weapon)

#define SOM_TANK_HOVER_HEIGHT -8

/obj/vehicle/sealed/armored/multitile/som_tank
	name = "\improper Malleus hover tank"
	desc = "A terrifying behemoth, the Malleus pattern hover tank combines excellent mobility with formidable weaponry. Drag yourself onto it at the rear hatch to get inside."
	icon = 'fenysha_events/icons/vehicles/armored/3x4/som_tank.dmi'
	turret_icon = 'fenysha_events/icons/vehicles/armored/3x4/som_tank_gun.dmi'
	damage_icon_path = 'fenysha_events/icons/vehicles/armored/3x4/tank_damage.dmi'
	icon_state = "tank"
	hitbox = /obj/hitbox/rectangle/som_tank
	interior = /datum/interior/armored/som
	resistance_flags = UNACIDABLE|FREEZE_PROOF|LAVA_PROOF
	armor_type = /datum/armor/armored_vehicle/som
	armored_flags = ARMORED_HAS_PRIMARY_WEAPON|ARMORED_HAS_SECONDARY_WEAPON|ARMORED_HAS_HEADLIGHTS|ARMORED_WRECKABLE
	pixel_x = -65
	pixel_y = -80
	max_integrity = 1200
	facing_modifiers = list(VEHICLE_FRONT_ARMOUR = 0.55, VEHICLE_SIDE_ARMOUR = 1, VEHICLE_BACK_ARMOUR = 1.6)
	permitted_weapons = list(
		/obj/item/armored_weapon/volkite_carronade,
		/obj/item/armored_weapon/particle_lance,
		/obj/item/armored_weapon/coilgun,
		/obj/item/armored_weapon/secondary_mlrs,
	)
	starting_weapons = list(/obj/item/armored_weapon/coilgun, /obj/item/armored_weapon/secondary_mlrs)
	max_occupants = 4
	movedelay = 0.3 SECONDS
	ram_damage = 80
	idle_loop = /datum/looping_sound/som_tank_idle
	idle_inside_loop = /datum/looping_sound/som_tank_idle_interior
	drive_loop = /datum/looping_sound/som_tank_drive
	drive_inside_loop = /datum/looping_sound/som_tank_drive_interior

/datum/armor/armored_vehicle/som
	melee = 90
	bullet = 95
	laser = 95
	energy = 95
	bomb = 80
	bio = 100
	fire = 100
	acid = 70

/obj/vehicle/sealed/armored/multitile/som_tank/Initialize(mapload)
	. = ..()
	add_filter("shadow", 2, drop_shadow_filter(0, SOM_TANK_HOVER_HEIGHT, 1))
	animate_hover()

/obj/vehicle/sealed/armored/multitile/som_tank/generate_actions()
	. = ..()
	initialize_controller_action_type(/datum/action/vehicle/sealed/armored_strafe, VEHICLE_CONTROL_DRIVE)

/// The turret is fixed to the hull
/obj/vehicle/sealed/armored/multitile/som_tank/setDir(newdir)
	. = ..()
	if(turret_overlay && turret_overlay.dir != newdir)
		turret_overlay.setDir(newdir)

/obj/vehicle/sealed/armored/multitile/som_tank/swivel_turret(atom/target, new_weapon_dir)
	return FALSE

/obj/vehicle/sealed/armored/multitile/som_tank/proc/animate_hover()
	if(armored_flags & ARMORED_IS_WRECK)
		animate(src)
		return
	animate(src, time = 1.2 SECONDS, loop = -1, easing = SINE_EASING, flags = ANIMATION_RELATIVE|ANIMATION_END_NOW, pixel_z = 3)
	animate(time = 1.2 SECONDS, easing = SINE_EASING, flags = ANIMATION_RELATIVE, pixel_z = -3)

/obj/vehicle/sealed/armored/multitile/som_tank/wreck_vehicle()
	. = ..()
	animate_hover()
	modify_filter("shadow", list(y = -3))

/obj/vehicle/sealed/armored/multitile/som_tank/unwreck_vehicle()
	. = ..()
	animate_hover()
	modify_filter("shadow", list(y = SOM_TANK_HOVER_HEIGHT))

#undef SOM_TANK_HOVER_HEIGHT

/datum/action/vehicle/sealed/armored_strafe
	name = "Toggle Strafing"
	desc = "Strafe sideways instead of turning. Hold Alt to turn while strafing."
	button_icon = 'icons/mob/actions/actions_mecha.dmi'
	button_icon_state = "strafe"

/datum/action/vehicle/sealed/armored_strafe/Trigger(mob/clicker, trigger_flags)
	. = ..()
	if(!.)
		return
	var/obj/vehicle/sealed/armored/armored_vehicle = vehicle_entered_target
	armored_vehicle.strafe = !armored_vehicle.strafe
	armored_vehicle.balloon_alert(owner, "strafing [armored_vehicle.strafe ? "on" : "off"]")

/obj/vehicle/sealed/armored/multitile/mrap
	name = "\improper MRAP - Sambar"
	desc = "An unarmed MRAP designed to carry troops across the battlefield quickly and safely. Drag yourself onto it at the rear hatch to get inside."
	icon = 'fenysha_events/icons/vehicles/armored/2x3/apc.dmi'
	icon_state = "apc"
	damage_icon_path = 'fenysha_events/icons/vehicles/armored/2x3/apc_damage_overlay.dmi'
	hitbox = /obj/hitbox/two_three
	interior = /datum/interior/armored/mrap
	permitted_weapons = list()
	starting_weapons = null
	armored_flags = ARMORED_HAS_HEADLIGHTS|ARMORED_HAS_UNDERLAY|ARMORED_WRECKABLE|ARMORED_SELF_WALL_DAMAGE
	turret_icon = null
	pixel_x = -24
	pixel_y = -32
	max_integrity = 900
	max_occupants = 12
	enter_delay = 0.4 SECONDS
	ram_damage = 30
	movedelay = 0.15 SECONDS
	easy_load_list = list(
		/obj/item/tank_ammo,
		/obj/structure/closet/crate,
	)

/obj/vehicle/sealed/armored/multitile/mrap/enter_locations(atom/movable/entering_thing)
	var/turf/first_turf = get_step_away(get_step(src, REVERSE_DIR(dir)), src, 2)
	return list(first_turf, get_step(first_turf, turn(dir, -90)))

/obj/vehicle/sealed/armored/multitile/icc_lvrt
	name = "\improper LVRT 'Fallow' recce vehicle"
	desc = "A fast, light reconnaissance vehicle built to scout out and poke at enemy positions. Drag yourself onto it at the rear hatch to get inside."
	icon = 'fenysha_events/icons/vehicles/armored/2x2/icc_lvrt.dmi'
	icon_state = "icc_lvrt"
	turret_icon = 'fenysha_events/icons/vehicles/armored/2x2/icc_lvrt_gun.dmi'
	turret_icon_state = "icc_lvrt_turret"
	damage_icon_path = 'fenysha_events/icons/vehicles/armored/2x2/icc_lvrt_damage.dmi'
	interior = /datum/interior/armored/icc_lvrt
	hitbox = /obj/hitbox/medium
	armor_type = /datum/armor/armored_vehicle/lvrt
	armored_flags = ARMORED_HAS_PRIMARY_WEAPON|ARMORED_HAS_SECONDARY_WEAPON|ARMORED_HAS_HEADLIGHTS|ARMORED_HAS_UNDERLAY
	permitted_weapons = list(
		/obj/item/armored_weapon/icc_lvrt_sarden,
		/obj/item/armored_weapon/icc_lvrt_cannon,
		/obj/item/armored_weapon/icc_coaxial,
	)
	starting_weapons = list(/obj/item/armored_weapon/icc_lvrt_cannon, /obj/item/armored_weapon/icc_coaxial)
	max_integrity = 450
	max_occupants = 5
	pixel_x = 0
	pixel_y = -40
	enter_delay = 0.5 SECONDS
	ram_damage = 25
	movedelay = 0.25 SECONDS
	easy_load_list = list(
		/obj/item/tank_ammo,
		/obj/structure/closet/crate,
	)

/datum/armor/armored_vehicle/lvrt
	melee = 40
	bullet = 60
	laser = 60
	energy = 60
	bomb = 40
	bio = 60
	fire = 40
	acid = 40

/obj/vehicle/sealed/armored/multitile/icc_lvrt/enter_locations(atom/movable/entering_thing)
	return list(get_step(src, REVERSE_DIR(dir)))

/datum/looping_sound/tank_idle
	mid_sounds = list(
		'fenysha_events/sounds/vehicles/armored/looping/tank_eng_idle_1.ogg' = 1,
		'fenysha_events/sounds/vehicles/armored/looping/tank_eng_idle_2.ogg' = 1,
		'fenysha_events/sounds/vehicles/armored/looping/tank_eng_idle_3.ogg' = 1,
		'fenysha_events/sounds/vehicles/armored/looping/tank_eng_idle_4.ogg' = 1,
	)
	mid_length = 2 SECONDS
	start_sound = 'fenysha_events/sounds/vehicles/armored/looping/tank_eng_start.ogg'
	start_length = 1.2 SECONDS
	volume = 50

/datum/looping_sound/tank_idle_interior
	mid_sounds = list(
		'fenysha_events/sounds/vehicles/armored/looping/tank_eng_interior_idle_1.ogg' = 2,
		'fenysha_events/sounds/vehicles/armored/looping/tank_eng_interior_idle_2.ogg' = 1,
	)
	mid_length = 2 SECONDS
	start_sound = 'fenysha_events/sounds/vehicles/armored/looping/tank_eng_interior_start.ogg'
	start_volume = 15
	start_length = 2.5 SECONDS
	volume = 15

/datum/looping_sound/tank_drive
	mid_sounds = list(
		'fenysha_events/sounds/vehicles/armored/looping/engine_rev_1.ogg' = 1,
		'fenysha_events/sounds/vehicles/armored/looping/engine_rev_2.ogg' = 1,
	)
	vary = TRUE
	mid_length = 2 SECONDS
	volume = 50

/datum/looping_sound/tank_drive_interior
	mid_sounds = list(
		'fenysha_events/sounds/vehicles/armored/looping/tank_eng_interior_loop_1.ogg' = 1,
		'fenysha_events/sounds/vehicles/armored/looping/tank_eng_interior_loop_2.ogg' = 1,
		'fenysha_events/sounds/vehicles/armored/looping/tank_eng_interior_loop_3.ogg' = 1,
	)
	mid_length = 2 SECONDS
	volume = 20

/datum/looping_sound/som_tank_idle
	mid_sounds = list('fenysha_events/sounds/vehicles/armored/hover_tank/idle_1.ogg' = 1)
	mid_length = 2 SECONDS
	volume = 50

/datum/looping_sound/som_tank_idle_interior
	mid_sounds = list(
		'fenysha_events/sounds/vehicles/armored/hover_tank/idle_interior_1.ogg' = 1,
		'fenysha_events/sounds/vehicles/armored/hover_tank/idle_interior_2.ogg' = 1,
	)
	mid_length = 2 SECONDS
	volume = 15

/datum/looping_sound/som_tank_drive
	mid_sounds = list(
		'fenysha_events/sounds/vehicles/armored/hover_tank/hover_1.ogg' = 1,
		'fenysha_events/sounds/vehicles/armored/hover_tank/hover_2.ogg' = 1,
		'fenysha_events/sounds/vehicles/armored/hover_tank/hover_3.ogg' = 1,
		'fenysha_events/sounds/vehicles/armored/hover_tank/hover_4.ogg' = 1,
	)
	mid_length = 1.2 SECONDS
	volume = 50

/datum/looping_sound/som_tank_drive_interior
	mid_sounds = list(
		'fenysha_events/sounds/vehicles/armored/hover_tank/hover_interior_1.ogg' = 1,
		'fenysha_events/sounds/vehicles/armored/hover_tank/hover_interior_2.ogg' = 1,
		'fenysha_events/sounds/vehicles/armored/hover_tank/hover_interior_3.ogg' = 1,
		'fenysha_events/sounds/vehicles/armored/hover_tank/hover_interior_4.ogg' = 1,
	)
	mid_length = 1.2 SECONDS
	volume = 20
