/obj/vehicle/sealed/armored
	name = "armored vehicle"
	desc = "Yell at coderbus."
	icon = 'fenysha_events/icons/vehicles/armored/3x3/tank.dmi'
	icon_state = "tank"
	abstract_type = /obj/vehicle/sealed/armored
	layer = ABOVE_MOB_LAYER
	appearance_flags = PIXEL_SCALE|TILE_BOUND
	move_resist = INFINITY
	resistance_flags = UNACIDABLE|FREEZE_PROOF
	interaction_flags_atom = parent_type::interaction_flags_atom | INTERACT_ATOM_MOUSEDROP_IGNORE_ADJACENT
	armor_type = /datum/armor/armored_vehicle
	max_integrity = 600
	max_drivers = 1
	movedelay = 0.7 SECONDS
	light_system = OVERLAY_LIGHT_DIRECTIONAL
	light_range = 8
	light_power = 1.5
	light_on = FALSE
	enter_delay = 1 SECONDS
	var/armored_flags = ARMORED_HAS_PRIMARY_WEAPON|ARMORED_HAS_HEADLIGHTS
	/// Typepath until initialized
	var/obj/hitbox/hitbox = /obj/hitbox
	/// Typepath until initialized
	var/datum/interior/armored/interior

	var/datum/looping_sound/idle_loop = /datum/looping_sound/tank_idle
	var/datum/looping_sound/idle_inside_loop = /datum/looping_sound/tank_idle_interior
	var/datum/looping_sound/drive_loop = /datum/looping_sound/tank_drive
	var/datum/looping_sound/drive_inside_loop = /datum/looping_sound/tank_drive_interior
	var/engine_off_sound = 'fenysha_events/sounds/vehicles/armored/looping/tank_eng_stop.ogg'
	var/engine_off_interior_sound = 'fenysha_events/sounds/vehicles/armored/looping/tank_eng_interior_stop.ogg'

	/// Independently rotating turret, typepath until initialized
	var/atom/movable/vis_obj/turret_overlay/turret_overlay = /atom/movable/vis_obj/turret_overlay
	var/turret_icon = 'fenysha_events/icons/vehicles/armored/3x3/tank_gun.dmi'
	var/turret_icon_state = "turret"
	/// Used for the secondary weapon when there is no turret
	var/image/secondary_weapon_overlay
	var/atom/movable/vis_obj/tank_damage/damage_overlay
	var/damage_icon_path
	var/image/underlay

	var/obj/item/armored_weapon/primary_weapon
	var/obj/item/armored_weapon/secondary_weapon
	var/list/permitted_weapons = list()
	/// Typepaths of weapons the vehicle spawns with, primary first
	var/list/starting_weapons
	var/weapons_safety = FALSE
	var/ram_damage = 20
	/// Items that can be thrown inside by hitting or dragging them onto the entrance; typecached on init
	var/list/easy_load_list
	var/strafe = FALSE
	/// Damage multipliers by the side of the hull that was hit
	var/list/facing_modifiers = list(VEHICLE_FRONT_ARMOUR = 1, VEHICLE_SIDE_ARMOUR = 1, VEHICLE_BACK_ARMOUR = 1)
	var/obj/effect/abstract/particle_holder/smoke_holder

/datum/armor/armored_vehicle
	melee = 50
	bullet = 80
	laser = 80
	energy = 60
	bomb = 60
	bio = 100
	fire = 50
	acid = 50

/obj/vehicle/sealed/armored/Initialize(mapload)
	easy_load_list = typecacheof(easy_load_list)
	. = ..()
	set_glide_size(DELAY_TO_GLIDE_SIZE(movedelay))
	if(ispath(hitbox))
		hitbox = new hitbox(loc, src)
		hitbox.owner_turned(src, null, dir)
	if(ispath(interior))
		interior = new interior(src, CALLBACK(src, PROC_REF(interior_exit)))
	if(armored_flags & ARMORED_HAS_UNDERLAY)
		underlay = image(icon, icon_state + "_underlay", layer = layer - 0.1)
		add_overlay(underlay)
	if(damage_icon_path)
		damage_overlay = new
		damage_overlay.icon = damage_icon_path
		damage_overlay.layer = layer + 0.001
		vis_contents += damage_overlay
	if((armored_flags & ARMORED_HAS_PRIMARY_WEAPON) && ispath(turret_overlay))
		turret_overlay = new turret_overlay(null, src)
		vis_contents += turret_overlay
	else
		turret_overlay = null
	if(ispath(idle_loop))
		idle_loop = new idle_loop(src)
	if(ispath(drive_loop))
		drive_loop = new drive_loop(src)
	if(!interior)
		idle_inside_loop = null
		drive_inside_loop = null
	for(var/weapon_type in starting_weapons)
		var/obj/item/armored_weapon/weapon = new weapon_type(src)
		weapon.attach(src, !!(weapon.armored_weapon_flags & MODULE_PRIMARY))
	setDir(dir)
	update_appearance()

/obj/vehicle/sealed/armored/Destroy()
	QDEL_NULL(primary_weapon)
	QDEL_NULL(secondary_weapon)
	QDEL_NULL(damage_overlay)
	QDEL_NULL(smoke_holder)
	if(isdatum(idle_loop))
		QDEL_NULL(idle_loop)
	if(isdatum(idle_inside_loop))
		QDEL_NULL(idle_inside_loop)
	if(isdatum(drive_loop))
		QDEL_NULL(drive_loop)
	if(isdatum(drive_inside_loop))
		QDEL_NULL(drive_inside_loop)
	if(isatom(turret_overlay))
		QDEL_NULL(turret_overlay)
	if(isdatum(interior))
		QDEL_NULL(interior)
	if(isatom(hitbox))
		qdel(hitbox, TRUE)
	hitbox = null
	underlay = null
	return ..()

/// Called by the interior once its map has loaded, so interior-side sound loops have somewhere to play
/obj/vehicle/sealed/armored/proc/on_interior_loaded(atom/sound_source)
	if(ispath(idle_inside_loop))
		idle_inside_loop = new idle_inside_loop(sound_source)
	if(ispath(drive_inside_loop))
		drive_inside_loop = new drive_inside_loop(sound_source)
	if(driver_amount())
		idle_inside_loop?.start()

/obj/vehicle/sealed/armored/generate_actions()
	if(armored_flags & ARMORED_HAS_HEADLIGHTS)
		initialize_controller_action_type(/datum/action/vehicle/sealed/headlights, VEHICLE_CONTROL_SETTINGS)
	initialize_controller_action_type(/datum/action/vehicle/sealed/horn/armored, VEHICLE_CONTROL_SETTINGS)
	if(!ispath(interior))
		return ..()

/obj/vehicle/sealed/armored/examine(mob/user)
	. = ..()
	. += span_notice("To fire its main gun, left click a tile. Right click fires the secondary weapon, middle click toggles weapon safety.")
	. += span_notice("It's holding [LAZYLEN(occupants)]/[max_occupants] crew.")
	. += span_notice("There is [primary_weapon ? "\a [primary_weapon]" : "nothing"] in the primary weapon mount and [secondary_weapon ? "\a [secondary_weapon]" : "nothing"] in the secondary mount.")
	if(armored_flags & ARMORED_IS_WRECK)
		. += span_warning("It's wrecked. It could be welded back into working order.")

/obj/vehicle/sealed/armored/update_name(updates)
	. = ..()
	name = (armored_flags & ARMORED_IS_WRECK) ? "wrecked [initial(name)]" : initial(name)

/obj/vehicle/sealed/armored/update_icon_state()
	. = ..()
	icon_state = (armored_flags & ARMORED_IS_WRECK) ? "[initial(icon_state)]_wreck" : initial(icon_state)
	if(!damage_overlay)
		return
	switch(PERCENT(atom_integrity / max_integrity))
		if(0 to 20)
			damage_overlay.icon_state = "damage_veryhigh"
		if(20 to 40)
			damage_overlay.icon_state = "damage_high"
		if(40 to 70)
			damage_overlay.icon_state = "damage_medium"
		if(70 to 90)
			damage_overlay.icon_state = "damage_small"
		else
			damage_overlay.icon_state = "null"

/obj/vehicle/sealed/armored/update_overlays()
	. = ..()
	if(secondary_weapon_overlay)
		. += secondary_weapon_overlay

/obj/vehicle/sealed/armored/setDir(newdir)
	. = ..()
	if(secondary_weapon_overlay && secondary_weapon)
		secondary_weapon_overlay.icon_state = "[secondary_weapon.icon_state]_[newdir]"
		update_appearance(UPDATE_OVERLAYS)

/obj/vehicle/sealed/armored/update_integrity(new_value)
	. = ..()
	update_appearance(UPDATE_ICON_STATE)

/obj/vehicle/sealed/armored/Adjacent(atom/neighbor, atom/target, atom/movable/mover)
	if(!hitbox)
		return ..()
	for(var/turf/hull_turf as anything in hitbox.locs)
		if(hull_turf.Adjacent(neighbor, neighbor, src))
			return TRUE
	return ..()

/obj/vehicle/sealed/armored/proc/is_strafing()
	if(!strafe)
		return FALSE
	for(var/mob/driver as anything in return_drivers())
		if(driver.client?.keys_held["Alt"])
			return FALSE
	return TRUE

/obj/vehicle/sealed/armored/relaymove(mob/living/user, direction)
	if(!canmove || (armored_flags & ARMORED_IS_WRECK))
		return TRUE
	if(is_driver(user))
		if(vehicle_move(direction, user) && drive_loop && !drive_loop.is_active())
			idle_loop?.stop()
			drive_loop.start()
			idle_inside_loop?.stop()
			drive_inside_loop?.start()
		return TRUE
	if(is_equipment_controller(user))
		swivel_turret(null, direction)
	return TRUE

/obj/vehicle/sealed/armored/vehicle_move(direction, mob/living/user)
	if(!COOLDOWN_FINISHED(src, cooldown_vehicle_move))
		return FALSE
	COOLDOWN_START(src, cooldown_vehicle_move, movedelay)
	if(hitbox && (hitbox.on_attempt_drive(user, direction) & COMPONENT_DRIVER_BLOCK_MOVE))
		return FALSE
	armored_step(direction)
	return TRUE

/// Moves one tile without the usual Move checks; the hitbox already checked the way is clear
/obj/vehicle/sealed/armored/proc/armored_step(direction)
	after_move(direction)
	forceMove(get_step(src, direction))
	last_move = direction
	lastmove = world.time

/obj/vehicle/sealed/armored/proc/is_equipment_controller(mob/user)
	return LAZYACCESS(occupants, user) & VEHICLE_CONTROL_EQUIPMENT

/obj/vehicle/sealed/armored/Bump(atom/bumped)
	. = ..()
	var/mob/pilot = LAZYACCESS(return_drivers(), 1)
	bumped.vehicle_collision(src, get_dir(src, bumped), pilot)
	if(TIMER_COOLDOWN_RUNNING(src, COOLDOWN_VEHICLE_CRUSHSOUND))
		return
	visible_message(span_danger("[src] rams [bumped]!"))
	playsound(bumped, 'sound/effects/meteorimpact.ogg', 45, TRUE)
	TIMER_COOLDOWN_START(src, COOLDOWN_VEHICLE_CRUSHSOUND, 1 SECONDS)

/obj/vehicle/sealed/armored/auto_assign_occupant_flags(mob/new_occupant)
	if(interior)
		return
	if(max_occupants == 1)
		add_control_flags(new_occupant, VEHICLE_CONTROL_DRIVE|VEHICLE_CONTROL_SETTINGS|VEHICLE_CONTROL_MELEE|VEHICLE_CONTROL_EQUIPMENT)
		return
	if(driver_amount() < max_drivers)
		add_control_flags(new_occupant, VEHICLE_CONTROL_DRIVE|VEHICLE_CONTROL_SETTINGS)
	else if(!length(return_controllers_with_flag(VEHICLE_CONTROL_EQUIPMENT)))
		add_control_flags(new_occupant, VEHICLE_CONTROL_MELEE|VEHICLE_CONTROL_EQUIPMENT)

/obj/vehicle/sealed/armored/after_add_occupant(mob/new_occupant)
	. = ..()
	if(interior)
		REMOVE_TRAIT(new_occupant, TRAIT_HANDS_BLOCKED, VEHICLE_TRAIT)
	else
		new_occupant.reset_perspective(src)

/obj/vehicle/sealed/armored/after_remove_occupant(mob/old_occupant)
	. = ..()
	if(!interior && old_occupant.client?.eye == src)
		old_occupant.reset_perspective()

/obj/vehicle/sealed/armored/grant_controller_actions_by_flag(mob/controller, flag)
	. = ..()
	if(!.)
		return
	if(flag & VEHICLE_CONTROL_EQUIPMENT)
		RegisterSignal(controller, COMSIG_MOB_CLICKON, PROC_REF(on_gunner_click), TRUE)
		RegisterSignal(controller, COMSIG_MOB_LOGIN, PROC_REF(bind_gunner_client), TRUE)
		RegisterSignal(controller, COMSIG_MOB_LOGOUT, PROC_REF(unbind_gunner_client), TRUE)
		bind_gunner_client(controller)
		primary_weapon?.on_gunner_added(controller)
		secondary_weapon?.on_gunner_added(controller)
	if((flag & VEHICLE_CONTROL_DRIVE) && driver_amount() == 1)
		start_engine()

/obj/vehicle/sealed/armored/remove_controller_actions_by_flag(mob/controller, flag)
	. = ..()
	if(!.)
		return
	if(flag & VEHICLE_CONTROL_EQUIPMENT)
		unbind_gunner_client(controller)
		UnregisterSignal(controller, list(COMSIG_MOB_CLICKON, COMSIG_MOB_LOGIN, COMSIG_MOB_LOGOUT))
		primary_weapon?.on_gunner_removed(controller)
		secondary_weapon?.on_gunner_removed(controller)
	if((flag & VEHICLE_CONTROL_DRIVE) && !driver_amount())
		stop_engine()

/obj/vehicle/sealed/armored/proc/start_engine()
	START_PROCESSING(SSfastprocess, src)
	idle_loop?.start()
	idle_inside_loop?.start()

/obj/vehicle/sealed/armored/proc/stop_engine()
	STOP_PROCESSING(SSfastprocess, src)
	var/was_running = idle_loop?.is_active() || drive_loop?.is_active()
	idle_loop?.stop()
	drive_loop?.stop()
	idle_inside_loop?.stop()
	drive_inside_loop?.stop()
	if(!was_running)
		return
	playsound(src, engine_off_sound, 30)
	play_interior_sound(engine_off_interior_sound, 10, TRUE)

/// Swaps back to the idle loop once the vehicle stops moving
/obj/vehicle/sealed/armored/process(seconds_per_tick)
	if(lastmove + movedelay + 1 SECONDS > world.time)
		return
	if(!drive_loop?.is_active())
		return
	drive_loop.stop()
	idle_loop?.start()
	drive_inside_loop?.stop()
	idle_inside_loop?.start()

/obj/vehicle/sealed/armored/exit_location(mob/leaving)
	return get_step(src, REVERSE_DIR(dir))

/// Turfs the vehicle can be entered from
/obj/vehicle/sealed/armored/proc/enter_locations(atom/movable/entering_thing)
	if(Adjacent(entering_thing))
		return list(get_turf(entering_thing))
	return list()

/obj/vehicle/sealed/armored/mob_try_enter(mob/rider)
	if(!isliving(rider) || (armored_flags & ARMORED_IS_WRECK))
		return FALSE
	if(!(rider.loc in enter_locations(rider)))
		balloon_alert(rider, "not at the entrance!")
		return FALSE
	return ..()

/obj/vehicle/sealed/armored/enter_checks(mob/entering)
	. = ..()
	if(!.)
		return
	if(LAZYLEN(entering.buckled_mobs))
		balloon_alert(entering, "remove riders first!")
		return FALSE
	return !(armored_flags & ARMORED_IS_WRECK) && (entering.loc in enter_locations(entering))

/obj/vehicle/sealed/armored/mob_enter(mob/entering, silent = FALSE)
	if(!interior)
		return ..()
	if(!interior.door)
		balloon_alert(entering, "interior not ready!")
		return FALSE
	if(!silent)
		entering.visible_message(span_notice("[entering] climbs into \the [src]!"))
	add_occupant(entering)
	interior.mob_enter(entering)
	return TRUE

/obj/vehicle/sealed/armored/mob_exit(mob/leaving, silent = FALSE, randomstep = FALSE)
	if(interior && (leaving in interior.occupants))
		interior.mob_leave(leaving, FALSE)
	return ..()

/// Called when a mob leaves the interior, either through the hatch or by other means
/obj/vehicle/sealed/armored/proc/interior_exit(mob/leaver, datum/interior/inside, teleport)
	if(!teleport)
		remove_occupant(leaver)
		return
	mob_exit(leaver, TRUE)

/obj/vehicle/sealed/armored/proc/try_easy_load(atom/movable/thing_to_load, mob/living/user)
	if(isliving(thing_to_load))
		return FALSE
	if(!is_type_in_typecache(thing_to_load, easy_load_list))
		return FALSE
	if(!interior?.door)
		balloon_alert(user, "no way in!")
		return FALSE
	var/list/enter_locs = enter_locations(user)
	if(!((user.loc in enter_locs) || (thing_to_load.loc in enter_locs)))
		balloon_alert(user, "not at the entrance!")
		return FALSE
	if(isitem(thing_to_load) && !user.temporarilyRemoveItemFromInventory(thing_to_load))
		return FALSE
	thing_to_load.forceMove(interior.door.get_enter_location())
	balloon_alert(user, "loaded inside")
	return TRUE

/obj/vehicle/sealed/armored/mouse_drop_receive(atom/dropping, mob/living/user, params)
	if(dropping == user)
		return ..()
	if(!isliving(user) || !user.Adjacent(dropping))
		return
	if(ismovable(dropping))
		try_easy_load(dropping, user)

/obj/vehicle/sealed/armored/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	. = ..()
	if(.)
		return
	if(istype(tool, /obj/item/armored_weapon))
		return try_attach_weapon(user, tool, !LAZYACCESS(modifiers, RIGHT_CLICK))
	if(istype(tool, /obj/item/tank_ammo) && try_load_ammo(user, tool))
		return ITEM_INTERACT_SUCCESS
	if(try_easy_load(tool, user))
		return ITEM_INTERACT_SUCCESS
	return NONE

/obj/vehicle/sealed/armored/welder_act(mob/living/user, obj/item/tool)
	. = ITEM_INTERACT_BLOCKING
	if(user.combat_mode)
		return NONE
	if(atom_integrity >= max_integrity)
		balloon_alert(user, "not damaged!")
		return
	if(!tool.tool_start_check(user, amount = 1))
		return
	balloon_alert(user, "repairing...")
	while(atom_integrity < max_integrity)
		if(!tool.use_tool(src, user, 2 SECONDS, amount = 1, volume = 50))
			break
		repair_damage(max_integrity * 0.05)
		if((armored_flags & ARMORED_IS_WRECK) && atom_integrity >= max_integrity * 0.5)
			unwreck_vehicle()
	return ITEM_INTERACT_SUCCESS

/obj/vehicle/sealed/armored/take_damage(damage_amount, damage_type = BRUTE, damage_flag = "", sound_effect = TRUE, attack_dir, armour_penetration = 0)
	if(attack_dir)
		damage_amount *= get_armour_facing_modifier(attack_dir)
	. = ..()
	if(. > 5)
		Shake(duration = 0.5 SECONDS)

/// attack_dir points from us towards the attacker, so it's the side of the hull that was hit
/obj/vehicle/sealed/armored/proc/get_armour_facing_modifier(attack_dir)
	if(attack_dir & dir)
		return facing_modifiers[VEHICLE_FRONT_ARMOUR]
	if(attack_dir & REVERSE_DIR(dir))
		return facing_modifiers[VEHICLE_BACK_ARMOUR]
	return facing_modifiers[VEHICLE_SIDE_ARMOUR]

/obj/vehicle/sealed/armored/Shake(pixelshiftx = 2, pixelshifty = 2, duration = 2.5 SECONDS, shake_interval = 0.02 SECONDS)
	. = ..()
	var/list/crew = LAZYCOPY(occupants)
	if(interior)
		crew |= interior.occupants
	for(var/mob/living/occupant as anything in crew)
		shake_camera(occupant, duration / 10, occupant.buckled ? 0.5 : 1)

/obj/vehicle/sealed/armored/ex_act(severity, target)
	if(QDELETED(src))
		return FALSE
	switch(severity)
		if(EXPLODE_DEVASTATE)
			take_damage(500, BRUTE, BOMB, 0)
		if(EXPLODE_HEAVY)
			take_damage(80, BRUTE, BOMB, 0)
		if(EXPLODE_LIGHT)
			take_damage(10, BRUTE, BOMB, 0)
	return TRUE

/obj/vehicle/sealed/armored/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_SELF)
		return
	playsound(src, 'sound/effects/magic/lightningshock.ogg', 50, FALSE)
	take_damage(400 / severity, BURN, ENERGY)

/obj/vehicle/sealed/armored/projectile_hit(obj/projectile/hitting_projectile, def_zone, piercing_hit = FALSE, blocked = null)
	var/atom/fired_from = hitting_projectile.fired_from
	if(hitting_projectile.firer == src || (istype(fired_from) && fired_from.loc == src))
		return BULLET_ACT_FORCE_PIERCE
	return ..()

/obj/vehicle/sealed/armored/atom_destruction(damage_flag)
	playsound(src, 'sound/effects/explosion/explosion1.ogg', 100, TRUE)
	for(var/mob/living/nearby in range(7, src))
		shake_camera(nearby, 4, 2)
	if((armored_flags & ARMORED_WRECKABLE) && !(armored_flags & ARMORED_IS_WRECK))
		wreck_vehicle()
		return
	return ..()

/obj/vehicle/sealed/armored/proc/wreck_vehicle()
	armored_flags |= ARMORED_IS_WRECK
	dump_mobs(TRUE)
	interior?.eject_all()
	stop_engine()
	set_light_on(FALSE)
	update_integrity(1)
	smoke_holder = new(src, /particles/smoke/steam/bad)
	update_appearance()

/obj/vehicle/sealed/armored/proc/unwreck_vehicle()
	armored_flags &= ~ARMORED_IS_WRECK
	QDEL_NULL(smoke_holder)
	update_appearance()

/// Plays a sound to everyone inside the interior, as playsound_local
/obj/vehicle/sealed/armored/proc/play_interior_sound(soundin, vol, vary, turf/turf_source)
	if(!interior)
		return
	for(var/mob/crew as anything in interior.occupants)
		if(crew.client)
			crew.playsound_local(turf_source, soundin, vol, vary)

/obj/vehicle/sealed/armored/proc/set_safety(mob/user)
	weapons_safety = !weapons_safety
	SEND_SOUND(user, sound('sound/machines/beep/beep.ogg', volume = 25))
	balloon_alert(user, "weapons [weapons_safety ? "safe" : "ready"]")

/obj/vehicle/sealed/armored/proc/swivel_turret(atom/target, new_weapon_dir)
	if(!turret_overlay)
		return FALSE
	if(!new_weapon_dir)
		new_weapon_dir = angle2dir_cardinal(get_angle(get_turf(src), get_turf(target)))
	if(turret_overlay.dir == new_weapon_dir)
		return FALSE
	if(TIMER_COOLDOWN_RUNNING(src, COOLDOWN_TANK_SWIVEL))
		return FALSE
	playsound(src, 'fenysha_events/sounds/vehicles/armored/tankswivel.ogg', 80, TRUE)
	play_interior_sound('fenysha_events/sounds/vehicles/armored/turret_swivel_interior.ogg', 60, TRUE)
	TIMER_COOLDOWN_START(src, COOLDOWN_TANK_SWIVEL, 3 SECONDS)
	if(primary_weapon)
		TIMER_COOLDOWN_START(src, COOLDOWN_ARMORED_WEAPON(primary_weapon.type), new_weapon_dir == REVERSE_DIR(turret_overlay.dir) ? 1 SECONDS : 0.5 SECONDS)
	turret_overlay.setDir(new_weapon_dir)
	return TRUE

/obj/vehicle/sealed/armored/proc/bind_gunner_client(mob/gunner)
	SIGNAL_HANDLER
	if(gunner.client)
		RegisterSignal(gunner.client, COMSIG_CLIENT_MOUSEDOWN, PROC_REF(on_gunner_mousedown), TRUE)

/obj/vehicle/sealed/armored/proc/unbind_gunner_client(mob/gunner)
	SIGNAL_HANDLER
	if(gunner.canon_client)
		UnregisterSignal(gunner.canon_client, COMSIG_CLIENT_MOUSEDOWN)

/// Turns a world click into a target the gunner can shoot at, or null if it shouldn't be treated as a shot
/obj/vehicle/sealed/armored/proc/get_gunner_target(mob/gunner, atom/clicked, list/modifiers)
	if(istype(clicked, /atom/movable/screen/click_catcher))
		return parse_caught_click_modifiers(modifiers, get_turf(gunner.client?.eye), gunner.client)
	if(!isturf(clicked) && !isturf(clicked?.loc))
		return null
	if(clicked == src || (hitbox && clicked == hitbox))
		return null
	if(interior && (get_turf(clicked) in interior.loaded_turfs))
		return null
	return clicked

/// Stops normal click behaviour while aiming; firing itself happens on mouse down
/obj/vehicle/sealed/armored/proc/on_gunner_click(mob/gunner, atom/clicked, list/modifiers)
	SIGNAL_HANDLER
	if(LAZYACCESS(modifiers, SHIFT_CLICK) || LAZYACCESS(modifiers, CTRL_CLICK) || LAZYACCESS(modifiers, ALT_CLICK))
		return
	if(!is_equipment_controller(gunner) || !get_gunner_target(gunner, clicked, modifiers))
		return
	return COMSIG_MOB_CANCEL_CLICKON

/obj/vehicle/sealed/armored/proc/on_gunner_mousedown(client/source, atom/object, turf/location, control, params)
	SIGNAL_HANDLER
	var/mob/living/gunner = source.mob
	if(!istype(gunner) || !is_equipment_controller(gunner) || gunner.incapacitated)
		return
	var/list/modifiers = params2list(params)
	if(LAZYACCESS(modifiers, SHIFT_CLICK) || LAZYACCESS(modifiers, CTRL_CLICK) || LAZYACCESS(modifiers, ALT_CLICK))
		return
	var/atom/target = get_gunner_target(gunner, object, modifiers)
	if(!target)
		return
	if(LAZYACCESS(modifiers, MIDDLE_CLICK))
		set_safety(gunner)
		return
	if(armored_flags & ARMORED_IS_WRECK)
		return
	var/obj/item/armored_weapon/selected
	if(LAZYACCESS(modifiers, RIGHT_CLICK))
		selected = secondary_weapon
	else
		selected = primary_weapon
		if(turret_overlay && selected && (selected.armored_weapon_flags & MODULE_FIXED_FIRE_ARC) && turret_overlay.dir != get_cardinal_dir(src, target))
			swivel_turret(target)
			return
	if(!selected || weapons_safety)
		return
	INVOKE_ASYNC(selected, TYPE_PROC_REF(/obj/item/armored_weapon, begin_fire), gunner, target, modifiers)

/obj/vehicle/sealed/armored/proc/try_attach_weapon(mob/living/user, obj/item/armored_weapon/weapon, as_primary)
	if(!(weapon.type in permitted_weapons))
		balloon_alert(user, "doesn't fit!")
		return ITEM_INTERACT_BLOCKING
	if(!(weapon.armored_weapon_flags & (as_primary ? MODULE_PRIMARY : MODULE_SECONDARY)))
		balloon_alert(user, "not a [as_primary ? "primary" : "secondary"] weapon!")
		return ITEM_INTERACT_BLOCKING
	if(as_primary && !turret_overlay)
		balloon_alert(user, "no turret!")
		return ITEM_INTERACT_BLOCKING
	if(!do_after(user, 2 SECONDS, src))
		return ITEM_INTERACT_BLOCKING
	if(!user.temporarilyRemoveItemFromInventory(weapon))
		return ITEM_INTERACT_BLOCKING
	weapon.attach(src, as_primary)
	balloon_alert(user, "attached")
	return ITEM_INTERACT_SUCCESS

/// Loads ammo from outside, only for weapons without a breech inside
/obj/vehicle/sealed/armored/proc/try_load_ammo(mob/living/user, obj/item/tank_ammo/new_ammo)
	var/obj/item/armored_weapon/weapon_to_load
	if(primary_weapon && !interior?.breech && (new_ammo.type in primary_weapon.accepted_ammo))
		weapon_to_load = primary_weapon
	else if(secondary_weapon && !interior?.secondary_breech && (new_ammo.type in secondary_weapon.accepted_ammo))
		weapon_to_load = secondary_weapon
	if(!weapon_to_load)
		return FALSE
	if(weapon_to_load.ammo && length(weapon_to_load.ammo_magazine) >= weapon_to_load.maximum_magazines)
		balloon_alert(user, "already loaded!")
		return TRUE
	if(!do_after(user, weapon_to_load.rearm_time, src) || !user.temporarilyRemoveItemFromInventory(new_ammo))
		return TRUE
	weapon_to_load.add_ammo(new_ammo)
	playsound(src, new_ammo.loading_sound, 40, TRUE)
	balloon_alert(user, "loaded")
	return TRUE

/obj/vehicle/sealed/armored/crowbar_act(mob/living/user, obj/item/tool)
	return detach_weapon_act(user, primary_weapon)

/obj/vehicle/sealed/armored/wrench_act(mob/living/user, obj/item/tool)
	return detach_weapon_act(user, secondary_weapon)

/obj/vehicle/sealed/armored/proc/detach_weapon_act(mob/living/user, obj/item/armored_weapon/weapon)
	if(!weapon)
		balloon_alert(user, "nothing mounted!")
		return ITEM_INTERACT_BLOCKING
	balloon_alert(user, "detaching...")
	if(!do_after(user, 2 SECONDS, src) || weapon.chassis != src)
		return ITEM_INTERACT_BLOCKING
	weapon.detach(drop_location())
	user.put_in_hands(weapon)
	return ITEM_INTERACT_SUCCESS

/datum/action/vehicle/sealed/horn/armored
	hornsound = 'fenysha_events/sounds/vehicles/armored/armored_horn.ogg'

/atom/movable/vis_obj
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	anchored = TRUE
	appearance_flags = PIXEL_SCALE

/atom/movable/vis_obj/turret_overlay
	name = "turret"
	icon = 'fenysha_events/icons/vehicles/armored/3x3/tank_gun.dmi'
	icon_state = "turret"
	vis_flags = VIS_INHERIT_ID|VIS_INHERIT_PLANE
	var/atom/movable/vis_obj/tank_gun/primary_overlay
	var/image/secondary_overlay

/atom/movable/vis_obj/turret_overlay/Initialize(mapload, obj/vehicle/sealed/armored/parent)
	. = ..()
	icon = parent.turret_icon
	base_icon_state = parent.turret_icon_state
	icon_state = parent.turret_icon_state
	layer = parent.layer + 0.002
	setDir(parent.dir)

/atom/movable/vis_obj/turret_overlay/Destroy()
	QDEL_NULL(primary_overlay)
	secondary_overlay = null
	return ..()

/atom/movable/vis_obj/turret_overlay/proc/update_gun_overlay(gun_icon_state)
	if(primary_overlay)
		vis_contents -= primary_overlay
		QDEL_NULL(primary_overlay)
	if(!gun_icon_state)
		return
	primary_overlay = new
	primary_overlay.icon = icon
	primary_overlay.base_icon_state = gun_icon_state
	primary_overlay.icon_state = gun_icon_state
	vis_contents += primary_overlay

/atom/movable/vis_obj/turret_overlay/update_overlays()
	. = ..()
	if(secondary_overlay)
		secondary_overlay.icon_state = "[copytext(secondary_overlay.icon_state, 1, findlasttext(secondary_overlay.icon_state, "_"))]_[dir]"
		. += secondary_overlay

/atom/movable/vis_obj/turret_overlay/setDir(newdir)
	. = ..()
	if(secondary_overlay)
		update_appearance(UPDATE_OVERLAYS)

/atom/movable/vis_obj/tank_damage
	name = "damage"
	icon_state = "null"
	vis_flags = VIS_INHERIT_DIR|VIS_INHERIT_LAYER|VIS_INHERIT_ID|VIS_INHERIT_PLANE

/atom/movable/vis_obj/tank_gun
	name = "gun"
	vis_flags = VIS_INHERIT_DIR|VIS_INHERIT_LAYER|VIS_INHERIT_ID|VIS_INHERIT_PLANE
	pixel_x = -70
	pixel_y = -69
