/obj/item/armored_weapon
	name = "\improper LTB main battle tank cannon"
	desc = "A vehicle's main turret cannon. It fires 105mm shells."
	icon = 'fenysha_events/icons/vehicles/armored/hardpoint_modules.dmi'
	icon_state = "ltb_cannon"
	w_class = WEIGHT_CLASS_GIGANTIC
	var/obj/vehicle/sealed/armored/chassis
	var/armored_weapon_flags = MODULE_PRIMARY|MODULE_FIXED_FIRE_ARC
	/// Loaded ammo; typepath until initialized
	var/obj/item/tank_ammo/ammo = /obj/item/tank_ammo/ltb
	/// Queued ammo, the first entry is loaded when the current one runs dry
	var/list/obj/item/tank_ammo/ammo_magazine = list()
	var/maximum_magazines = 0
	var/list/accepted_ammo = list(
		/obj/item/tank_ammo/ltb,
		/obj/item/tank_ammo/ltb/heavy,
		/obj/item/tank_ammo/ltb/apfds,
		/obj/item/tank_ammo/ltb/canister,
		/obj/item/tank_ammo/ltb/canister/incendiary,
	)
	var/atom/current_target
	var/mob/living/current_firer
	var/firing = FALSE

	var/fire_sound = list('fenysha_events/sounds/vehicles/armored/fire/tank_cannon1.ogg', 'fenysha_events/sounds/vehicles/armored/fire/tank_cannon2.ogg')
	/// Played to the crew inside instead of the outside sound
	var/interior_fire_sound = 'fenysha_events/sounds/vehicles/armored/weapons/ltb_fire_interior.ogg'
	var/fire_sound_vary = TRUE
	var/windup_sound
	var/windup_delay = 0
	/// Spread in degrees
	var/variance = 0
	var/projectile_delay = 5 SECONDS
	var/projectile_burst_delay = 0.2 SECONDS
	var/burst_amount = 0
	var/fire_mode = ARMORED_FIRE_SEMIAUTO
	/// How long reloading from the queued ammo takes
	var/rearm_time = 4 SECONDS

/obj/item/armored_weapon/Initialize(mapload)
	. = ..()
	if(ispath(ammo))
		ammo = new ammo(src)

/obj/item/armored_weapon/Destroy()
	if(chassis)
		detach(get_turf(chassis))
	stop_fire()
	if(isdatum(ammo))
		QDEL_NULL(ammo)
	QDEL_LIST(ammo_magazine)
	return ..()

/obj/item/armored_weapon/examine(mob/user)
	. = ..()
	. += span_notice("It is [ammo ? "loaded with \a [ammo]" : "unloaded"][length(ammo_magazine) ? ", with [length(ammo_magazine)] more queued" : ""].")

/obj/item/armored_weapon/proc/is_primary()
	return chassis?.primary_weapon == src

/// Called when the gunner presses the mouse down on a target
/obj/item/armored_weapon/proc/begin_fire(mob/living/user, atom/target, list/modifiers)
	if(firing || !chassis)
		return
	if(!ammo || ammo.current_rounds <= 0)
		playsound(user, 'sound/items/weapons/gun/general/dry_fire.ogg', 30, TRUE)
		return
	if(user.incapacitated)
		return
	if(TIMER_COOLDOWN_RUNNING(chassis, COOLDOWN_ARMORED_WEAPON(type)))
		return
	set_target(target)
	current_firer = user
	firing = TRUE
	if(user.client)
		RegisterSignal(user.client, COMSIG_CLIENT_MOUSEUP, PROC_REF(on_mouse_up))
		RegisterSignal(user.client, COMSIG_CLIENT_MOUSEDRAG, PROC_REF(on_mouse_drag))
	if(windup_delay)
		if(windup_sound)
			playsound(chassis, windup_sound, 30)
		if(!do_after(user, windup_delay, user, IGNORE_USER_LOC_CHANGE|IGNORE_HELD_ITEM|IGNORE_SLOWDOWNS, extra_checks = CALLBACK(src, PROC_REF(still_firing))))
			stop_fire()
			return
	switch(fire_mode)
		if(ARMORED_FIRE_SEMIAUTO)
			TIMER_COOLDOWN_START(chassis, COOLDOWN_ARMORED_WEAPON(type), projectile_delay)
			fire()
			if(is_primary() && interior_fire_sound)
				user.say("On the way!", forced = "tank cannon")
			stop_fire()
		if(ARMORED_FIRE_BURST)
			TIMER_COOLDOWN_START(chassis, COOLDOWN_ARMORED_WEAPON(type), projectile_delay)
			for(var/i in 1 to burst_amount)
				if(!fire())
					break
				sleep(projectile_burst_delay)
			stop_fire()
		if(ARMORED_FIRE_AUTOMATIC)
			while(firing && fire())
				TIMER_COOLDOWN_START(chassis, COOLDOWN_ARMORED_WEAPON(type), projectile_delay)
				sleep(projectile_delay)
			stop_fire()

/obj/item/armored_weapon/proc/still_firing()
	return firing && chassis && !QDELETED(current_target)

/obj/item/armored_weapon/proc/on_mouse_up(client/source, atom/object, turf/location, control, params)
	SIGNAL_HANDLER
	var/list/modifiers = params2list(params)
	var/released_secondary = !!LAZYACCESS(modifiers, RIGHT_CLICK)
	if(released_secondary == is_primary())
		return
	firing = FALSE

/obj/item/armored_weapon/proc/on_mouse_drag(client/source, atom/src_object, atom/over_object, turf/src_location, turf/over_location, src_control, over_control, params)
	SIGNAL_HANDLER
	var/atom/new_target = over_object
	if(istype(over_object, /atom/movable/screen/click_catcher))
		new_target = parse_caught_click_modifiers(params2list(params), get_turf(source.eye), source)
	if(isturf(new_target) || isturf(new_target?.loc))
		set_target(new_target)

/obj/item/armored_weapon/proc/set_target(atom/new_target)
	if(new_target == current_target || new_target == chassis || new_target == chassis?.hitbox)
		return
	if(current_target)
		UnregisterSignal(current_target, COMSIG_QDELETING)
	current_target = new_target
	if(current_target)
		RegisterSignal(current_target, COMSIG_QDELETING, PROC_REF(clean_target))

/obj/item/armored_weapon/proc/clean_target(datum/source)
	SIGNAL_HANDLER
	UnregisterSignal(current_target, COMSIG_QDELETING)
	current_target = get_turf(current_target)

/obj/item/armored_weapon/proc/stop_fire()
	firing = FALSE
	if(current_firer?.client)
		UnregisterSignal(current_firer.client, list(COMSIG_CLIENT_MOUSEUP, COMSIG_CLIENT_MOUSEDRAG))
	set_target(null)
	current_firer = null

/// Fires once. Returns TRUE if an automatic weapon should keep going
/obj/item/armored_weapon/proc/fire()
	if(!chassis || !current_target || !current_firer || current_firer.incapacitated)
		return FALSE
	if(!ammo || ammo.current_rounds <= 0)
		return FALSE
	var/turf/source_turf = (is_primary() && chassis.hitbox) ? chassis.hitbox.get_projectile_loc(src) : get_turf(chassis)
	if(!source_turf)
		return FALSE
	if((armored_weapon_flags & MODULE_FIXED_FIRE_ARC) && chassis.turret_overlay)
		var/angle_to_target = get_angle(source_turf, get_turf(current_target))
		if(abs(MODULUS(angle_to_target - dir2angle(chassis.turret_overlay.dir) + 540, 360) - 180) > ARMORED_FIRE_CONE_ALLOWED / 2)
			chassis.swivel_turret(current_target)
			return fire_mode == ARMORED_FIRE_AUTOMATIC
	else
		update_secondary_facing()

	do_fire(source_turf)
	play_fire_sound()
	chassis.log_message("fired [src] at [current_target] ([AREACOORD(current_target)]).", LOG_ATTACK)

	ammo.current_rounds--
	ammo.update_appearance(UPDATE_ICON_STATE)
	if(is_primary())
		var/atom/movable/vis_obj/tank_gun/gun_overlay = chassis.turret_overlay?.primary_overlay
		if(gun_overlay && ("[gun_overlay.base_icon_state]_fire" in icon_states(gun_overlay.icon)))
			flick("[gun_overlay.base_icon_state]_fire", gun_overlay)
		chassis.interior?.breech?.on_main_fire(ammo)
	if(ammo.current_rounds > 0)
		return TRUE
	playsound(chassis, 'sound/items/weapons/gun/general/empty_alarm.ogg', 25, TRUE)
	eject_ammo()
	if(!length(ammo_magazine))
		return FALSE
	var/obj/item/tank_ammo/next_ammo = ammo_magazine[1]
	if(next_ammo.loading_sound)
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(playsound), chassis, next_ammo.loading_sound, 40), 0.5 SECONDS)
	if(!do_after(current_firer, rearm_time, current_firer, IGNORE_USER_LOC_CHANGE|IGNORE_HELD_ITEM|IGNORE_SLOWDOWNS))
		return FALSE
	reload()
	return fire_mode == ARMORED_FIRE_AUTOMATIC

/obj/item/armored_weapon/proc/play_fire_sound()
	var/outside_sound = islist(fire_sound) ? pick(fire_sound) : fire_sound
	if(outside_sound)
		playsound(chassis, outside_sound, 80, fire_sound_vary, extrarange = 5)
	if(interior_fire_sound && chassis.interior)
		var/atom/breech = is_primary() ? chassis.interior.breech : chassis.interior.secondary_breech
		chassis.play_interior_sound(islist(interior_fire_sound) ? pick(interior_fire_sound) : interior_fire_sound, 40, fire_sound_vary, get_turf(breech))

/// Points a turretless or free-aiming secondary weapon at the target
/obj/item/armored_weapon/proc/update_secondary_facing()
	var/new_dir = get_cardinal_dir(chassis, current_target)
	var/atom/movable/vis_obj/turret_overlay/turret = chassis.turret_overlay
	if(turret?.secondary_overlay && chassis.secondary_weapon == src)
		turret.secondary_overlay.icon_state = "[icon_state]_[new_dir]"
		turret.update_appearance(UPDATE_OVERLAYS)
	else if(chassis.secondary_weapon_overlay && chassis.secondary_weapon == src)
		chassis.secondary_weapon_overlay.icon_state = "[icon_state]_[new_dir]"
		chassis.update_appearance(UPDATE_OVERLAYS)

/obj/item/armored_weapon/proc/do_fire(turf/source_turf)
	var/pellets = max(ammo.projectiles_per_round, 1)
	for(var/i in 1 to pellets)
		var/spread = rand(-variance, variance)
		if(pellets > 1)
			spread += rand(-ammo.pellet_spread, ammo.pellet_spread)
		fire_projectile_at(source_turf, ammo.projectile_type, spread)

/obj/item/armored_weapon/proc/fire_projectile_at(turf/source_turf, projectile_type, spread = 0)
	var/obj/projectile/shot = new projectile_type(source_turf)
	shot.firer = chassis
	shot.fired_from = src
	shot.aim_projectile(current_target, source_turf, null, spread)
	if(istype(shot, /obj/projectile/bullet/armored/explosive/rocket))
		shot.set_homing_target(current_target)
	shot.fire()
	return shot

/obj/item/armored_weapon/proc/eject_ammo()
	var/obj/item/tank_ammo/old_ammo = ammo
	ammo = null
	if(!old_ammo)
		return
	old_ammo.update_appearance(UPDATE_ICON_STATE)
	var/obj/structure/gun_breech/breech = is_primary() ? chassis?.interior?.breech : chassis?.interior?.secondary_breech
	if(breech)
		breech.do_eject_ammo(old_ammo)
		return
	old_ammo.forceMove(chassis ? chassis.exit_location() : drop_location())

/// Loads the first queued ammo
/obj/item/armored_weapon/proc/reload()
	if(ammo)
		eject_ammo()
	if(length(ammo_magazine))
		ammo = popleft(ammo_magazine)

/// Queues or loads new ammo. Returns FALSE if there's no room
/obj/item/armored_weapon/proc/add_ammo(obj/item/tank_ammo/new_ammo)
	if(ammo && length(ammo_magazine) >= maximum_magazines)
		return FALSE
	new_ammo.forceMove(src)
	if(ammo)
		ammo_magazine += new_ammo
	else
		ammo = new_ammo
	return TRUE

/obj/item/armored_weapon/proc/attach(obj/vehicle/sealed/armored/tank, attach_primary)
	if(attach_primary)
		tank.primary_weapon?.detach(tank.exit_location())
		tank.primary_weapon = src
		tank.turret_overlay?.update_gun_overlay(icon_state)
		tank.interior?.breech?.on_weapon_attach(src)
	else
		tank.secondary_weapon?.detach(tank.exit_location())
		tank.secondary_weapon = src
		if(tank.turret_overlay)
			// dir = SOUTH stops byond inheriting the direction from the turret
			tank.turret_overlay.secondary_overlay = image(tank.turret_icon, icon_state = "[icon_state]_[tank.turret_overlay.dir]", dir = SOUTH)
			tank.turret_overlay.update_appearance(UPDATE_OVERLAYS)
		else
			tank.secondary_weapon_overlay = image(tank.icon, icon_state = "[icon_state]_[tank.dir]", dir = SOUTH)
			tank.update_appearance(UPDATE_OVERLAYS)
	chassis = tank
	forceMove(tank)
	for(var/mob/gunner as anything in tank.return_controllers_with_flag(VEHICLE_CONTROL_EQUIPMENT))
		on_gunner_added(gunner)

/obj/item/armored_weapon/proc/detach(atom/moveto)
	stop_fire()
	for(var/mob/gunner as anything in chassis.return_controllers_with_flag(VEHICLE_CONTROL_EQUIPMENT))
		on_gunner_removed(gunner)
	if(chassis.primary_weapon == src)
		chassis.primary_weapon = null
		chassis.turret_overlay?.update_gun_overlay()
		chassis.interior?.breech?.on_weapon_detach(src)
	else
		chassis.secondary_weapon = null
		if(chassis.turret_overlay)
			chassis.turret_overlay.secondary_overlay = null
			chassis.turret_overlay.update_appearance(UPDATE_OVERLAYS)
		else
			chassis.secondary_weapon_overlay = null
			chassis.update_appearance(UPDATE_OVERLAYS)
	chassis = null
	forceMove(moveto)

/obj/item/armored_weapon/proc/on_gunner_added(mob/gunner)
	return

/obj/item/armored_weapon/proc/on_gunner_removed(mob/gunner)
	return

/obj/item/armored_weapon/secondary_weapon
	name = "secondary cupola minigun"
	desc = "A robotically controlled minigun that spews lead."
	icon_state = "cupola"
	fire_sound = 'fenysha_events/sounds/vehicles/armored/fire/tank_minigun_loop.ogg'
	interior_fire_sound = null
	windup_delay = 0.5 SECONDS
	windup_sound = 'fenysha_events/sounds/vehicles/armored/fire/tank_minigun_start.ogg'
	armored_weapon_flags = MODULE_SECONDARY
	ammo = /obj/item/tank_ammo/cupola
	accepted_ammo = list(/obj/item/tank_ammo/cupola)
	fire_mode = ARMORED_FIRE_AUTOMATIC
	projectile_delay = 0.2 SECONDS
	variance = 5
	rearm_time = 1 SECONDS

/obj/item/armored_weapon/ltaap
	name = "\improper LTA-AP chaingun"
	desc = "A hefty, large caliber chaingun."
	icon_state = "ltaap_chaingun"
	fire_sound = 'fenysha_events/sounds/vehicles/armored/fire/tank_minigun_loop.ogg'
	interior_fire_sound = null
	windup_delay = 0.5 SECONDS
	windup_sound = 'fenysha_events/sounds/vehicles/armored/fire/tank_minigun_start.ogg'
	ammo = /obj/item/tank_ammo/ltaap
	accepted_ammo = list(/obj/item/tank_ammo/ltaap, /obj/item/tank_ammo/ltaap/hv)
	fire_mode = ARMORED_FIRE_AUTOMATIC
	variance = 5
	projectile_delay = 0.1 SECONDS
	rearm_time = 3 SECONDS

/obj/item/armored_weapon/tank_autocannon
	name = "\improper Bushwhacker autocannon"
	desc = "A Bushwhacker 30mm autocannon for vehicular use."
	icon_state = "tank_autocannon"
	fire_sound = list('fenysha_events/sounds/vehicles/armored/fire/autocannon_1.ogg', 'fenysha_events/sounds/vehicles/armored/fire/autocannon_2.ogg', 'fenysha_events/sounds/vehicles/armored/fire/autocannon_3.ogg')
	interior_fire_sound = list('fenysha_events/sounds/vehicles/armored/weapons/tank_autocannon_interior_fire_1.ogg', 'fenysha_events/sounds/vehicles/armored/weapons/tank_autocannon_interior_fire_2.ogg')
	ammo = /obj/item/tank_ammo/autocannon
	accepted_ammo = list(/obj/item/tank_ammo/autocannon, /obj/item/tank_ammo/autocannon/high_explosive)
	fire_mode = ARMORED_FIRE_AUTOMATIC
	variance = 2
	projectile_delay = 0.45 SECONDS
	rearm_time = 4 SECONDS

/obj/item/armored_weapon/secondary_flamer
	name = "\improper OMR Mk.3 secondary flamer"
	desc = "A large, vehicle mounted flamer that sprays a fluid fuel mix."
	icon_state = "sflamer"
	fire_sound = 'fenysha_events/sounds/vehicles/armored/fire/tank_flamethrower.ogg'
	interior_fire_sound = null
	ammo = /obj/item/tank_ammo/secondary_flamer
	armored_weapon_flags = MODULE_SECONDARY
	fire_mode = ARMORED_FIRE_AUTOMATIC
	variance = 5
	rearm_time = 1 SECONDS
	accepted_ammo = list(/obj/item/tank_ammo/secondary_flamer)
	projectile_delay = 0.1 SECONDS

/obj/item/armored_weapon/tow
	name = "\improper TOW-III launcher"
	desc = "A single-shot, homing, vehicle-mounted TOW-III launcher designed for precision strikes against armored targets."
	icon_state = "seeker"
	fire_sound = list('fenysha_events/sounds/vehicles/armored/fire/rpg_1.ogg', 'fenysha_events/sounds/vehicles/armored/fire/rpg_2.ogg', 'fenysha_events/sounds/vehicles/armored/fire/rpg_3.ogg')
	interior_fire_sound = null
	armored_weapon_flags = MODULE_SECONDARY
	ammo = /obj/item/tank_ammo/tow_missile
	accepted_ammo = list(/obj/item/tank_ammo/tow_missile)
	maximum_magazines = 13
	projectile_delay = 2 SECONDS
	variance = 10
	rearm_time = 1 SECONDS

/obj/item/armored_weapon/microrocket_pod
	name = "microrocket pod"
	desc = "A secondary vehicle-mounted rocket launcher with 6 homing microrockets, able to fire them in rapid succession."
	icon_state = "secondary_rocket_multiple"
	fire_sound = 'fenysha_events/sounds/vehicles/armored/fire/launcher.ogg'
	interior_fire_sound = null
	armored_weapon_flags = MODULE_SECONDARY
	ammo = /obj/item/tank_ammo/microrocket_rack
	accepted_ammo = list(/obj/item/tank_ammo/microrocket_rack)
	fire_mode = ARMORED_FIRE_BURST
	projectile_delay = 2 SECONDS
	variance = 40
	burst_amount = 3
	projectile_burst_delay = 0.1 SECONDS
	rearm_time = 5 SECONDS

/obj/item/armored_weapon/bfg
	name = "\improper BFG 9500"
	desc = "A crackling energy weapon, a slightly scaled up model of the classic BFG 9000."
	icon_state = "bfg"
	fire_sound = 'fenysha_events/sounds/vehicles/armored/fire/tank_bfg.ogg'
	interior_fire_sound = 'fenysha_events/sounds/vehicles/armored/weapons/particle_fire_interior.ogg'
	ammo = /obj/item/tank_ammo/bfg
	accepted_ammo = list(/obj/item/tank_ammo/bfg)
	projectile_delay = 8 SECONDS

/// Beam weapon: scorches a 3 tile wide line, then explodes where the beam stops
/obj/item/armored_weapon/volkite_carronade
	name = "volkite carronade"
	desc = "A massive volkite weapon seen on SOM battle tanks, a devastating anti infantry weapon able to mow down whole groups of soft targets."
	icon_state = "volkite"
	fire_sound = 'fenysha_events/sounds/vehicles/armored/fire/volkite_4.ogg'
	interior_fire_sound = 'fenysha_events/sounds/vehicles/armored/weapons/volkite_fire_interior.ogg'
	windup_sound = 'fenysha_events/sounds/vehicles/armored/weapons/particle_charge.ogg'
	windup_delay = 0.6 SECONDS
	projectile_delay = 3 SECONDS
	ammo = /obj/item/tank_ammo/volkite_carronade
	accepted_ammo = list(/obj/item/tank_ammo/volkite_carronade)
	fire_sound_vary = FALSE
	var/beam_range = 15

/obj/item/armored_weapon/volkite_carronade/do_fire(turf/source_turf)
	var/turf/target_turf = get_ranged_target_turf_direct(source_turf, current_target, beam_range)
	var/list/turf/beam_turfs = get_line(source_turf, target_turf)
	var/turf/beam_end = source_turf
	var/list/turf/scorched = list()
	for(var/turf/line_turf as anything in beam_turfs)
		if(isclosedturf(line_turf))
			break
		beam_end = line_turf
		var/stopped = FALSE
		for(var/turf/nearby as anything in RANGE_TURFS(1, line_turf))
			if(nearby in scorched)
				continue
			scorched += nearby
			if(scorch_turf(nearby, source_turf, nearby == line_turf))
				stopped = TRUE
		if(stopped)
			break
	source_turf.Beam(beam_end, icon_state = "beam_incen", icon = 'fenysha_events/icons/vehicles/armored/projectiles.dmi', time = 0.6 SECONDS)
	explosion(beam_end, 0, 2, 5, flash_range = 3, explosion_cause = chassis)

/// Returns TRUE if something on the turf stops the beam
/obj/item/armored_weapon/volkite_carronade/proc/scorch_turf(turf/scorched, turf/source_turf, on_beam_line)
	. = FALSE
	var/attack_dir = get_dir(scorched, source_turf)
	for(var/atom/movable/target as anything in scorched)
		if(target == chassis || target == chassis.hitbox || isitem(target) || iseffect(target))
			continue
		if(isobj(target))
			var/obj/obj_target = target
			if(obj_target.resistance_flags & INDESTRUCTIBLE)
				continue
			var/obj_damage = on_beam_line ? 500 : 350
			if(istype(obj_target, /obj/vehicle/sealed/armored) || istype(obj_target, /obj/hitbox) || ismecha(obj_target))
				obj_damage *= 0.75
				. = TRUE
			obj_target.take_damage(obj_damage, BURN, ENERGY, TRUE, attack_dir, 20)
			continue
		if(isliving(target))
			var/mob/living/living_target = target
			living_target.apply_damage(160, BURN, spread_damage = TRUE)
			living_target.flash_act(1)
			living_target.adjust_fire_stacks(on_beam_line ? 15 : 9)
			living_target.ignite_mob()

/// Energy lance with a blinding discharge
/obj/item/armored_weapon/particle_lance
	name = "particle lance"
	desc = "A powerful energy beam weapon, able to tear apart anything in its path with a concentrated beam of charged particles."
	icon_state = "particle_beam"
	ammo = /obj/item/tank_ammo/particle_lance
	accepted_ammo = list(/obj/item/tank_ammo/particle_lance)
	fire_sound = 'fenysha_events/sounds/vehicles/armored/weapons/particle_fire.ogg'
	interior_fire_sound = 'fenysha_events/sounds/vehicles/armored/weapons/particle_fire_interior.ogg'
	windup_sound = 'fenysha_events/sounds/vehicles/armored/weapons/particle_charge.ogg'
	windup_delay = 0.6 SECONDS
	fire_sound_vary = FALSE

/obj/item/armored_weapon/particle_lance/do_fire(turf/source_turf)
	for(var/mob/living/viewer in viewers(9, source_turf))
		viewer.flash_act(1, visual = TRUE)
	return ..()

#define COILGUN_LOW_POWER 1
#define COILGUN_MED_POWER 2
#define COILGUN_HIGH_POWER 3

/obj/item/armored_weapon/coilgun
	name = "battle tank coilgun"
	desc = "The standard main weapon of SOM battle tanks, accelerating a large projectile to a tremendous speed."
	icon_state = "coilgun"
	ammo = /obj/item/tank_ammo/coilgun
	accepted_ammo = list(/obj/item/tank_ammo/coilgun)
	fire_sound = 'fenysha_events/sounds/vehicles/armored/weapons/coil_fire.ogg'
	windup_sound = 'fenysha_events/sounds/vehicles/armored/weapons/coil_charge.ogg'
	interior_fire_sound = 'fenysha_events/sounds/vehicles/armored/weapons/coilgun_fire_interior.ogg'
	windup_delay = 0.6 SECONDS
	projectile_delay = 3 SECONDS
	maximum_magazines = 3
	rearm_time = 0.5 SECONDS
	var/power_level = COILGUN_MED_POWER
	var/current_projectile_type = /obj/projectile/bullet/armored/explosive/coilgun
	var/datum/action/armored_coilgun_power/power_toggle

/obj/item/armored_weapon/coilgun/Initialize(mapload)
	. = ..()
	power_toggle = new(src)

/obj/item/armored_weapon/coilgun/Destroy()
	QDEL_NULL(power_toggle)
	return ..()

/obj/item/armored_weapon/coilgun/on_gunner_added(mob/gunner)
	power_toggle.Grant(gunner)

/obj/item/armored_weapon/coilgun/on_gunner_removed(mob/gunner)
	power_toggle.Remove(gunner)

/obj/item/armored_weapon/coilgun/do_fire(turf/source_turf)
	var/recoil = 0
	var/recoil_time = 0.9 SECONDS
	switch(power_level)
		if(COILGUN_MED_POWER)
			recoil = 15
		if(COILGUN_HIGH_POWER)
			recoil = 25
			recoil_time = 1.2 SECONDS
	if(recoil)
		var/list/kick = dir2offset(REVERSE_DIR(chassis.dir))
		animate(chassis, time = 0.3 SECONDS, flags = ANIMATION_RELATIVE|ANIMATION_END_NOW, pixel_x = kick[1] * recoil, pixel_y = kick[2] * recoil)
		animate(time = recoil_time - 0.3 SECONDS, easing = SINE_EASING, flags = ANIMATION_RELATIVE, pixel_x = -kick[1] * recoil, pixel_y = -kick[2] * recoil)
		var/obj/vehicle/sealed/armored/multitile/som_tank/hover_tank = chassis
		if(istype(hover_tank))
			addtimer(CALLBACK(hover_tank, TYPE_PROC_REF(/obj/vehicle/sealed/armored/multitile/som_tank, animate_hover)), recoil_time)
	fire_projectile_at(source_turf, current_projectile_type, rand(-variance, variance))

/// Coilgun slugs are consumed on firing
/obj/item/armored_weapon/coilgun/eject_ammo()
	QDEL_NULL(ammo)

/obj/item/armored_weapon/coilgun/proc/toggle_power_level(mob/user)
	power_level = power_level >= COILGUN_HIGH_POWER ? COILGUN_LOW_POWER : power_level + 1
	switch(power_level)
		if(COILGUN_LOW_POWER)
			current_projectile_type = /obj/projectile/bullet/armored/explosive/coilgun/low
			windup_delay = 0
			projectile_delay = 1 SECONDS
		if(COILGUN_MED_POWER)
			current_projectile_type = /obj/projectile/bullet/armored/explosive/coilgun
			windup_delay = 0.6 SECONDS
			projectile_delay = 3 SECONDS
		if(COILGUN_HIGH_POWER)
			current_projectile_type = /obj/projectile/bullet/armored/explosive/coilgun/high
			windup_delay = 1 SECONDS
			projectile_delay = 4.5 SECONDS
	balloon_alert(user, "power level [power_level]")

/datum/action/armored_coilgun_power
	name = "Toggle Coilgun Power"
	desc = "Cycle the coilgun between low, standard and high power."
	button_icon = 'fenysha_events/icons/vehicles/armored/hardpoint_modules.dmi'
	button_icon_state = "coilgun"
	check_flags = AB_CHECK_CONSCIOUS

/datum/action/armored_coilgun_power/Trigger(mob/clicker, trigger_flags)
	. = ..()
	if(!.)
		return
	var/obj/item/armored_weapon/coilgun/gun = target
	gun.toggle_power_level(owner)

#undef COILGUN_LOW_POWER
#undef COILGUN_MED_POWER
#undef COILGUN_HIGH_POWER

/obj/item/armored_weapon/secondary_mlrs
	name = "secondary MLRS"
	desc = "A pair of forward facing rocket launchers with a total of 12 homing rockets, able to fire them all in rapid succession."
	icon_state = "mlrs"
	fire_sound = 'fenysha_events/sounds/vehicles/armored/weapons/mlrs_fire.ogg'
	interior_fire_sound = 'fenysha_events/sounds/vehicles/armored/weapons/mlrs_interior.ogg'
	armored_weapon_flags = MODULE_SECONDARY|MODULE_FIXED_FIRE_ARC
	ammo = /obj/item/tank_ammo/secondary_mlrs
	accepted_ammo = list(/obj/item/tank_ammo/secondary_mlrs)
	fire_mode = ARMORED_FIRE_AUTOMATIC
	projectile_delay = 0.2 SECONDS
	variance = 40
	rearm_time = 5 SECONDS

/obj/item/armored_weapon/icc_lvrt_sarden
	name = "\improper EM-2600 'SARDEN' autocannon"
	desc = "A 30mm autocannon for the LVRT 'Fallow', loaded with 7 round clips."
	icon_state = "icc_lvrt_autocannon"
	fire_sound = list('fenysha_events/sounds/vehicles/armored/fire/autocannon_1.ogg', 'fenysha_events/sounds/vehicles/armored/fire/autocannon_2.ogg', 'fenysha_events/sounds/vehicles/armored/fire/autocannon_3.ogg')
	interior_fire_sound = list('fenysha_events/sounds/vehicles/armored/weapons/tank_autocannon_interior_fire_1.ogg', 'fenysha_events/sounds/vehicles/armored/weapons/tank_autocannon_interior_fire_2.ogg')
	ammo = /obj/item/tank_ammo/sarden_clip
	accepted_ammo = list(/obj/item/tank_ammo/sarden_clip, /obj/item/tank_ammo/sarden_clip/high_explosive)
	fire_mode = ARMORED_FIRE_AUTOMATIC
	variance = 2
	projectile_delay = 0.65 SECONDS
	rearm_time = 0.5 SECONDS

/obj/item/armored_weapon/icc_lvrt_cannon
	name = "\improper EM-2500 low velocity cannon"
	desc = "A 76mm low velocity cannon for the LVRT 'Fallow'. Slow shells with solid explosive performance."
	icon_state = "icc_lvrt_cannon"
	fire_sound = list('fenysha_events/sounds/vehicles/armored/fire/autocannon_1.ogg', 'fenysha_events/sounds/vehicles/armored/fire/autocannon_2.ogg', 'fenysha_events/sounds/vehicles/armored/fire/autocannon_3.ogg')
	interior_fire_sound = list('fenysha_events/sounds/vehicles/armored/weapons/tank_autocannon_interior_fire_1.ogg', 'fenysha_events/sounds/vehicles/armored/weapons/tank_autocannon_interior_fire_2.ogg')
	ammo = /obj/item/tank_ammo/icc_lowvel_cannon
	accepted_ammo = list(/obj/item/tank_ammo/icc_lowvel_cannon, /obj/item/tank_ammo/icc_lowvel_cannon/high_explosive)
	projectile_delay = 1.5 SECONDS
	rearm_time = 1.5 SECONDS

/obj/item/armored_weapon/icc_coaxial
	name = "EM-94 coaxial chain gun (10x26mm)"
	desc = "A belt fed coaxial machine gun that spews lead."
	icon_state = "icc_lvrt_coax"
	fire_sound = 'fenysha_events/sounds/vehicles/armored/fire/gun_mg60.ogg'
	interior_fire_sound = null
	armored_weapon_flags = MODULE_SECONDARY|MODULE_FIXED_FIRE_ARC
	ammo = /obj/item/tank_ammo/icc_coax
	accepted_ammo = list(/obj/item/tank_ammo/icc_coax)
	fire_mode = ARMORED_FIRE_AUTOMATIC
	projectile_delay = 0.15 SECONDS
	variance = 5
	rearm_time = 3 SECONDS
