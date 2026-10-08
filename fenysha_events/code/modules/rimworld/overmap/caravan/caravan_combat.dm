/**
 * ============================================================================
 * Caravan vs caravan combat arenas
 * ============================================================================
 *
 * When two caravans on the same overmap tile accept an attack, a temporary
 * 64×64 sub-level is allocated. Members of each side are spawned on opposite
 * edges. A 2-minute exit cooldown is applied to the arena. Once every living
 * participant has left, the arena is destroyed.
 */

/datum/rimworld_caravan_arena
	var/id
	var/static/next_id = 0

	var/datum/rimworld_caravan/side_a
	var/datum/rimworld_caravan/side_b

	var/datum/turf_reservation/sub_level/reservation

	/// All living participants currently expected to be in the arena
	var/list/mob/living/participants = list()

	var/exit_cooldown_until = 0
	var/cleaning = FALSE


/datum/rimworld_caravan_arena/New(datum/rimworld_caravan/A, datum/rimworld_caravan/B)
	id = "arena_[++next_id]"
	side_a = A
	side_b = B
	return ..()


/datum/rimworld_caravan_arena/Destroy(force)
	cleaning = TRUE
	for(var/mob/living/M as anything in participants.Copy())
		unregister_participant(M)

	if(side_a)
		side_a.active_arena = null
	if(side_b)
		side_b.active_arena = null
	side_a = null
	side_b = null

	if(reservation && !QDELETED(reservation))
		qdel(reservation)
	reservation = null
	return ..()


/datum/rimworld_caravan_arena/proc/build()
	reservation = SSsub_levels.create_sub_level(
		RIMWORLD_CARAVAN_ATTACK_SIZE,
		RIMWORLD_CARAVAN_ATTACK_SIZE,
		0,
		"Caravan Combat [id]"
	)
	if(!reservation)
		return FALSE

	var/turf/BL = reservation.get_inner_bottom_left_turf()
	var/turf/TR = reservation.get_inner_top_right_turf()
	if(!BL || !TR)
		return FALSE

	// Simple open floor arena
	for(var/turf/T as anything in block(BL, TR))
		T.ChangeTurf(/turf/open/floor/plating, flags = CHANGETURF_IGNORE_AIR)

	// Place edge markers that respect arena cooldown
	for(var/x = BL.x to TR.x)
		new /obj/effect/rimworld_arena_edge(locate(x, BL.y, BL.z), src, SOUTH)
		new /obj/effect/rimworld_arena_edge(locate(x, TR.y, BL.z), src, NORTH)
	for(var/y = BL.y + 1 to TR.y - 1)
		new /obj/effect/rimworld_arena_edge(locate(BL.x, y, BL.z), src, WEST)
		new /obj/effect/rimworld_arena_edge(locate(TR.x, y, BL.z), src, EAST)

	exit_cooldown_until = world.time + RIMWORLD_CARAVAN_ATTACK_EXIT_COOLDOWN
	return TRUE


/datum/rimworld_caravan_arena/proc/is_exit_on_cooldown()
	return world.time < exit_cooldown_until


/datum/rimworld_caravan_arena/proc/spawn_sides()
	if(!reservation)
		return FALSE

	var/turf/BL = reservation.get_inner_bottom_left_turf()
	var/turf/TR = reservation.get_inner_top_right_turf()
	if(!BL || !TR)
		return FALSE

	var/list/west_edge = list()
	var/list/east_edge = list()
	for(var/y = BL.y + 2 to TR.y - 2)
		var/turf/W = locate(BL.x + 2, y, BL.z)
		var/turf/E = locate(TR.x - 2, y, BL.z)
		if(W)
			west_edge += W
		if(E)
			east_edge += E

	deploy_side(side_a, west_edge)
	deploy_side(side_b, east_edge)
	return TRUE


/datum/rimworld_caravan_arena/proc/deploy_side(datum/rimworld_caravan/C, list/turf/spawn_turfs)
	if(!C || !length(spawn_turfs))
		return

	C.stop_travel()
	C.active_arena = src

	var/i = 1
	for(var/mob/living/M as anything in C.members.Copy())
		if(QDELETED(M))
			continue
		C.close_map_for(M)
		C.mobilize_member(M)

		var/turf/T = spawn_turfs[i]
		i = (i % length(spawn_turfs)) + 1
		M.forceMove(T)
		register_participant(M)

		to_chat(M, span_userdanger("Combat begins! You cannot leave the arena for 2 minutes."))

	// Exterior vehicle: dump it on the spawn edge
	if(C.vehicle && !QDELETED(C.vehicle) && !C.has_interior)
		C.vehicle.forceMove(spawn_turfs[1])

	// Interior vehicle stays in nullspace; occupants already in interior —
	// if they were members we already moved them. Re-link if needed.
	if(C.vehicle && C.has_interior)
		// Occupants are inside the vehicle interior; they fight from there
		// or disembark onto the arena. Mark them as participants if present.
		for(var/mob/living/occ as anything in C.vehicle.return_occupants())
			register_participant(occ)


/datum/rimworld_caravan_arena/proc/register_participant(mob/living/M)
	if(!M || (M in participants))
		return
	participants += M
	M.rimworld_arena = src
	RegisterSignal(M, COMSIG_MOVABLE_MOVED, PROC_REF(on_participant_moved))
	RegisterSignal(M, COMSIG_QDELETING, PROC_REF(on_participant_qdel))


/datum/rimworld_caravan_arena/proc/unregister_participant(mob/living/M)
	if(!M)
		return
	participants -= M
	if(M.rimworld_arena == src)
		M.rimworld_arena = null
	UnregisterSignal(M, list(COMSIG_MOVABLE_MOVED, COMSIG_QDELETING))


/datum/rimworld_caravan_arena/proc/on_participant_qdel(mob/living/source)
	SIGNAL_HANDLER
	unregister_participant(source)
	check_empty()


/datum/rimworld_caravan_arena/proc/on_participant_moved(mob/living/source, atom/old_loc, dir, forced)
	SIGNAL_HANDLER
	if(cleaning)
		return
	if(!reservation || QDELETED(reservation))
		return

	// Still inside reservation bounds?
	var/turf/T = get_turf(source)
	if(!T || !(T in reservation.get_all_turfs()))
		unregister_participant(source)
		// Returning to overmap: re-open caravan if they still have one
		if(source.rimworld_caravan)
			source.rimworld_caravan.move_member_to_holding(source)
			source.rimworld_caravan.open_map_for(source)
		check_empty()


/datum/rimworld_caravan_arena/proc/check_empty()
	if(cleaning)
		return
	// Drop dead / qdeleted
	for(var/mob/living/M as anything in participants.Copy())
		if(QDELETED(M) || M.stat == DEAD)
			unregister_participant(M)

	if(!length(participants))
		qdel(src)


/**
 * Arena-specific edge: respects the 2-minute cooldown, then lets a mob leave
 * back to their caravan holding level.
 */
/obj/effect/rimworld_arena_edge
	name = "arena edge"
	desc = "The boundary of the combat arena."
	icon = 'icons/hud/screen_gen.dmi'
	icon_state = "living5"
	alpha = 100
	anchored = TRUE
	density = FALSE
	opacity = FALSE
	mouse_opacity = MOUSE_OPACITY_ICON
	layer = ABOVE_MOB_LAYER
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF

	var/datum/rimworld_caravan_arena/arena
	var/exit_side


/obj/effect/rimworld_arena_edge/Initialize(mapload, datum/rimworld_caravan_arena/parent_arena, side)
	. = ..()
	arena = parent_arena
	exit_side = side


/obj/effect/rimworld_arena_edge/Destroy(force)
	arena = null
	return ..()


/obj/effect/rimworld_arena_edge/attack_hand(mob/living/user)
	try_leave(user)
	return TRUE


/obj/effect/rimworld_arena_edge/Bumped(atom/movable/AM)
	. = ..()
	if(isliving(AM))
		try_leave(AM)


/obj/effect/rimworld_arena_edge/proc/try_leave(mob/living/user)
	if(!arena || QDELETED(arena) || !user)
		return
	if(arena.is_exit_on_cooldown())
		var/left = max(0, arena.exit_cooldown_until - world.time)
		to_chat(user, span_warning("The arena is locked for another [round(left / 10, 0.1)]s."))
		return

	INVOKE_ASYNC(src, PROC_REF(prompt_leave), user)


/obj/effect/rimworld_arena_edge/proc/prompt_leave(mob/living/user)
	if(QDELETED(user) || QDELETED(src) || !arena)
		return

	var/choice = tgui_alert(user, "Leave the combat arena and return to the planetary map?", "Leave Arena", list("Leave", "Stay"))
	if(choice != "Leave" || QDELETED(user) || QDELETED(arena))
		return
	if(arena.is_exit_on_cooldown())
		to_chat(user, span_warning("The arena is still locked."))
		return

	var/datum/rimworld_caravan/C = user.rimworld_caravan
	if(C)
		C.move_member_to_holding(user)
		C.open_map_for(user)
	else
		// Orphaned: create a solo caravan at last known tile of either side
		var/tx = arena.side_a?.current_x || arena.side_b?.current_x
		var/ty = arena.side_a?.current_y || arena.side_b?.current_y
		var/datum/rimworld_planet/P = arena.side_a?.planet || arena.side_b?.planet
		if(P && !isnull(tx))
			var/datum/rimworld_caravan/fresh = new /datum/rimworld_caravan(P, tx, ty, user)
			fresh.move_member_to_holding(user)
			fresh.open_map_for(user)

	arena.unregister_participant(user)
	arena.check_empty()


/mob/living
	var/datum/rimworld_caravan_arena/rimworld_arena


/**
 * Kicks off combat between two caravans already on the same overmap tile.
 */
/proc/start_caravan_combat(datum/rimworld_caravan/A, datum/rimworld_caravan/B)
	if(!A || !B || QDELETED(A) || QDELETED(B))
		return FALSE
	if(A.active_arena || B.active_arena)
		return FALSE

	var/datum/rimworld_caravan_arena/arena = new(A, B)
	if(!arena.build())
		qdel(arena)
		return FALSE

	arena.spawn_sides()

	for(var/mob/living/M as anything in A.members + B.members)
		to_chat(M, span_userdanger("Caravan combat has begun!"))

	return TRUE
