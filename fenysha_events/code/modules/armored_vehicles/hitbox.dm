/**
 * Multitile vehicles are a 1 tile root with a big sprite. This invisible, bounds-enlarged object follows the root,
 * blocks movement onto the sprite and relays every hit to the root. It must always be forceMoved.
 */
/obj/hitbox
	density = TRUE
	anchored = TRUE
	invisibility = INVISIBILITY_MAXIMUM
	bound_x = -32
	bound_y = -32
	max_integrity = INFINITY
	move_resist = INFINITY
	resistance_flags = INDESTRUCTIBLE
	var/obj/vehicle/sealed/armored/root
	/// Assumed to be longer than it is wide
	var/vehicle_length = 96
	var/vehicle_width = 96

/obj/hitbox/Initialize(mapload, obj/vehicle/sealed/armored/new_root)
	. = ..()
	if(!istype(new_root))
		return INITIALIZE_HINT_QDEL
	bound_height = vehicle_length
	bound_width = vehicle_width
	root = new_root
	glide_size = root.glide_size
	RegisterSignal(root, COMSIG_MOVABLE_MOVED, PROC_REF(root_move))
	RegisterSignal(root, COMSIG_QDELETING, PROC_REF(root_delete))
	RegisterSignal(root, COMSIG_ATOM_DIR_CHANGE, PROC_REF(owner_turned))

/obj/hitbox/Destroy(force)
	if(!force && !QDELETED(root))
		return QDEL_HINT_LETMELIVE
	if(root?.hitbox == src)
		root.hitbox = null
	root = null
	return ..()

/obj/hitbox/proc/root_delete()
	SIGNAL_HANDLER
	qdel(src, TRUE)

/obj/hitbox/proc/root_move(atom/movable/mover, atom/oldloc, direction, forced, list/turf/old_locs)
	SIGNAL_HANDLER
	if(!mover.loc)
		moveToNullspace()
		return
	set_glide_size(root.glide_size)
	forceMove(mover.loc)

/// Returns TRUE if the child type handles non-square rotation itself
/obj/hitbox/proc/owner_turned(datum/source, old_dir, new_dir)
	SIGNAL_HANDLER
	return new_dir && new_dir != old_dir && vehicle_length != vehicle_width

/obj/hitbox/CanAllowThrough(atom/movable/mover, border_dir)
	. = ..()
	if(.)
		return
	if(mover == root)
		return TRUE
	if(isprojectile(mover))
		var/obj/projectile/proj = mover
		var/atom/fired_from = proj.fired_from
		if(proj.firer == root || (istype(fired_from) && fired_from.loc == root))
			return TRUE

/// Bumps everything in the turfs the vehicle would enter and returns COMPONENT_DRIVER_BLOCK_MOVE if anything stopped it
/obj/hitbox/proc/check_entering_turfs(list/turf/entering_turfs, direction)
	var/canstep = TRUE
	for(var/turf/entering as anything in entering_turfs)
		if(!entering)
			canstep = FALSE
			continue
		if(!entering.Enter(root))
			canstep = FALSE
		for(var/atom/movable/blocker as anything in entering.contents)
			if(blocker == root || blocker == src)
				continue
			if(blocker.CanPass(root, get_dir(blocker, root)))
				continue
			root.Bump(blocker)
			canstep = FALSE
	return canstep ? NONE : COMPONENT_DRIVER_BLOCK_MOVE

/// Called when the vehicle is off move cooldown and a driver tries to move it
/obj/hitbox/proc/on_attempt_drive(mob/living/user, direction)
	if(ISDIAGONALDIR(direction))
		return COMPONENT_DRIVER_BLOCK_MOVE
	var/is_strafing = root.is_strafing()
	if(root.dir == direction || root.dir == REVERSE_DIR(direction))
		is_strafing = FALSE
	else if(!is_strafing)
		root.setDir(direction)
		return COMPONENT_DRIVER_BLOCK_MOVE
	var/turf/centerturf = get_step(get_step(root, direction), direction)
	var/list/entering_turfs = list(centerturf)
	entering_turfs += get_step(centerturf, turn(direction, 90))
	entering_turfs += get_step(centerturf, turn(direction, -90))
	return check_entering_turfs(entering_turfs, direction)

/obj/hitbox/projectile_hit(obj/projectile/hitting_projectile, def_zone, piercing_hit = FALSE, blocked = null)
	return root.projectile_hit(hitting_projectile, def_zone, piercing_hit, blocked)

/obj/hitbox/take_damage(damage_amount, damage_type = BRUTE, damage_flag = "", sound_effect = TRUE, attack_dir, armour_penetration = 0)
	return root.take_damage(damage_amount, damage_type, damage_flag, sound_effect, attack_dir, armour_penetration)

/obj/hitbox/ex_act(severity, target)
	return root.ex_act(severity, target)

/obj/hitbox/Shake(pixelshiftx = 2, pixelshifty = 2, duration = 2.5 SECONDS, shake_interval = 0.02 SECONDS)
	return root.Shake(pixelshiftx, pixelshifty, duration, shake_interval)

/// Where main gun projectiles spawn, one tile past the hull in the turret's direction
/obj/hitbox/proc/get_projectile_loc(obj/item/armored_weapon/weapon)
	var/turf/source = get_turf(root)
	var/fire_dir = root.turret_overlay ? root.turret_overlay.dir : root.dir
	var/steps = (fire_dir & (NORTH|SOUTH)) ? vehicle_length / ICON_SIZE_Y : vehicle_width / ICON_SIZE_X
	for(var/i in 1 to CEILING(steps / 2, 1))
		source = get_step(source, fire_dir)
	return source

/obj/hitbox/medium
	vehicle_length = 64
	vehicle_width = 64
	bound_x = 0
	bound_y = -32

/obj/hitbox/medium/on_attempt_drive(mob/living/user, direction)
	if(ISDIAGONALDIR(direction))
		return COMPONENT_DRIVER_BLOCK_MOVE
	var/is_strafing = root.is_strafing()
	if(root.dir == direction || root.dir == REVERSE_DIR(direction))
		is_strafing = FALSE
	else if(!is_strafing)
		root.setDir(direction)
		return COMPONENT_DRIVER_BLOCK_MOVE
	var/turf/centerturf = get_step(root, direction)
	var/list/entering_turfs = list()
	switch(direction)
		if(NORTH)
			entering_turfs += get_step(centerturf, turn(direction, -90))
		if(SOUTH)
			centerturf = get_step(centerturf, direction)
			entering_turfs += get_step(centerturf, turn(direction, 90))
		if(EAST)
			centerturf = get_step(centerturf, direction)
			entering_turfs += get_step(centerturf, turn(direction, -90))
		if(WEST)
			entering_turfs += get_step(centerturf, turn(direction, 90))
	entering_turfs += centerturf
	return check_entering_turfs(entering_turfs, direction)

/// 3x4, rotates its bounds with the root
/obj/hitbox/rectangle
	bound_x = -32
	bound_y = -64
	vehicle_length = 128
	vehicle_width = 96

/obj/hitbox/rectangle/owner_turned(datum/source, old_dir, new_dir)
	. = ..()
	if(!.)
		return
	switch(new_dir)
		if(NORTH)
			bound_height = vehicle_length
			bound_width = vehicle_width
			bound_x = -32
			bound_y = -32
			root.pixel_x = -65
			root.pixel_y = -48
		if(SOUTH)
			bound_height = vehicle_length
			bound_width = vehicle_width
			bound_x = -32
			bound_y = -64
			root.pixel_x = -65
			root.pixel_y = -80
		if(WEST)
			bound_height = vehicle_width
			bound_width = vehicle_length
			bound_x = -64
			bound_y = -32
			root.pixel_x = -80
			root.pixel_y = -56
		if(EAST)
			bound_height = vehicle_width
			bound_width = vehicle_length
			bound_x = -32
			bound_y = -32
			root.pixel_x = -48
			root.pixel_y = -56

/obj/hitbox/rectangle/on_attempt_drive(mob/living/user, direction)
	if(ISDIAGONALDIR(direction))
		return COMPONENT_DRIVER_BLOCK_MOVE
	var/is_strafing = root.is_strafing()
	if(root.dir == direction || root.dir == REVERSE_DIR(direction))
		is_strafing = FALSE
	var/turf/centerturf = get_turf(root)
	var/dist_count = root.dir == direction ? 3 : 2
	for(var/i in 1 to dist_count)
		centerturf = get_step(centerturf, direction)
	var/list/entering_turfs = list(centerturf)
	entering_turfs += get_step(centerturf, turn(direction, 90))
	entering_turfs += get_step(centerturf, turn(direction, -90))
	if(is_strafing)
		centerturf = get_step(get_step(centerturf, root.dir), root.dir)
		entering_turfs += centerturf
	if(check_entering_turfs(entering_turfs, direction))
		return COMPONENT_DRIVER_BLOCK_MOVE
	if(root.dir != direction && root.dir != REVERSE_DIR(direction) && !is_strafing)
		root.setDir(direction)
		return COMPONENT_DRIVER_BLOCK_MOVE
	return NONE

/obj/hitbox/rectangle/som_tank/get_projectile_loc(obj/item/armored_weapon/weapon)
	return get_step(get_step(src, root.dir), root.dir)

/// 2x3 with tank controls: north/south drive forward and back, diagonals turn
/obj/hitbox/two_three
	bound_x = -32
	bound_y = -32
	vehicle_length = 96
	vehicle_width = 64

/obj/hitbox/two_three/owner_turned(datum/source, old_dir, new_dir)
	. = ..()
	if(!.)
		return
	switch(new_dir)
		if(NORTH)
			bound_height = vehicle_length
			bound_width = vehicle_width
			bound_x = 0
			bound_y = -32
			root.pixel_x = 8
			root.pixel_y = -32
		if(SOUTH)
			bound_height = vehicle_length
			bound_width = vehicle_width
			bound_x = -32
			bound_y = -32
			root.pixel_x = -24
			root.pixel_y = -32
		if(WEST)
			bound_height = vehicle_width
			bound_width = vehicle_length
			bound_x = -32
			bound_y = 0
			root.pixel_x = -40
			root.pixel_y = 0
		if(EAST)
			bound_height = vehicle_width
			bound_width = vehicle_length
			bound_x = -32
			bound_y = -32
			root.pixel_x = -40
			root.pixel_y = -32

/obj/hitbox/two_three/on_attempt_drive(mob/living/user, direction)
	var/movement_dir
	var/facing_dir = root.dir
	var/turf/centerturf = get_turf(root)
	var/list/entering_turfs = list()

	if(!ISDIAGONALDIR(direction))
		if(direction == NORTH)
			movement_dir = facing_dir
		else if(direction == SOUTH)
			movement_dir = REVERSE_DIR(facing_dir)
		else
			return COMPONENT_DRIVER_BLOCK_MOVE
		centerturf = get_step(get_step(centerturf, movement_dir), movement_dir)
		entering_turfs += centerturf
		entering_turfs += get_step(centerturf, turn(facing_dir, -90))
	else
		if(direction & WEST)
			movement_dir = turn(facing_dir, 90)
			centerturf = get_step(centerturf, movement_dir)
		else
			movement_dir = turn(facing_dir, -90)
			centerturf = get_step(get_step(centerturf, movement_dir), movement_dir)
		if(direction & NORTH)
			facing_dir = movement_dir
			entering_turfs += get_step(centerturf, root.dir)
		else
			facing_dir = REVERSE_DIR(movement_dir)
			entering_turfs += get_step(centerturf, REVERSE_DIR(root.dir))
		entering_turfs += centerturf

	if(check_entering_turfs(entering_turfs, movement_dir))
		return COMPONENT_DRIVER_BLOCK_MOVE

	if(!ISDIAGONALDIR(direction))
		root.armored_step(movement_dir)
		return COMPONENT_DRIVER_BLOCK_MOVE
	if(direction == NORTHEAST)
		root.armored_step(turn(root.dir, -45))
	else if(direction == SOUTHEAST)
		root.armored_step(turn(root.dir, -135))
	root.setDir(facing_dir)
	COOLDOWN_START(root, cooldown_vehicle_move, root.movedelay * 2)
	return COMPONENT_DRIVER_BLOCK_MOVE
