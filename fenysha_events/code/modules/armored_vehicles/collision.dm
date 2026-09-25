/// Called when an armored vehicle rams into this atom
/atom/proc/vehicle_collision(obj/vehicle/sealed/armored/vehicle, facing, mob/pilot, ram_damage = vehicle.ram_damage)
	return

/obj/structure/vehicle_collision(obj/vehicle/sealed/armored/vehicle, facing, mob/pilot, ram_damage = vehicle.ram_damage)
	take_damage(ram_damage, BRUTE, MELEE, TRUE, REVERSE_DIR(facing))

/obj/machinery/vehicle_collision(obj/vehicle/sealed/armored/vehicle, facing, mob/pilot, ram_damage = vehicle.ram_damage)
	take_damage(ram_damage, BRUTE, MELEE, TRUE, REVERSE_DIR(facing))

/obj/vehicle/vehicle_collision(obj/vehicle/sealed/armored/vehicle, facing, mob/pilot, ram_damage = vehicle.ram_damage)
	take_damage(ram_damage, BRUTE, MELEE, TRUE, REVERSE_DIR(facing))

/turf/closed/wall/vehicle_collision(obj/vehicle/sealed/armored/vehicle, facing, mob/pilot, ram_damage = vehicle.ram_damage)
	if(vehicle.armored_flags & ARMORED_SELF_WALL_DAMAGE)
		vehicle.take_damage(ram_damage * 0.4, BRUTE, MELEE, TRUE, vehicle.dir)

/mob/living/vehicle_collision(obj/vehicle/sealed/armored/vehicle, facing, mob/pilot, ram_damage = vehicle.ram_damage)
	if(stat == DEAD || body_position == LYING_DOWN)
		return
	if(pilot)
		log_combat(pilot, src, "drove into", vehicle)
	// Some sideways variation so you can't chain wall-smash someone too easily
	var/throw_dir = pick(facing, turn(facing, 45), turn(facing, -45))
	throw_at(get_ranged_target_turf(src, throw_dir, 3), 3, 2, vehicle, TRUE)
	take_overall_damage(brute = ram_damage)
	return TRUE
