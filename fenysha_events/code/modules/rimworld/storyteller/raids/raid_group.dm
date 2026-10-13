/mob/living
	var/datum/raid_group/rw_raid_group

/datum/raid_group
	var/static/next_id = 0
	var/id
	var/datum/planet_cell/cell
	var/datum/raid_faction_def/def
	var/points = 0
	/// Tech level of the attacking faction at launch time (filters pawn kinds).
	var/attacker_tech_level = 0
	var/state = RAID_STATE_ATTACKING
	var/list/mob/living/members = list()
	var/initial_count = 0
	var/arrival_side
	var/datum/rimworld_planet_object/settlement/origin
	var/launched_at = 0
	var/state_changed_at = 0
	var/no_target_since = 0
	var/list/turf/exit_turfs = list()
	var/finished = FALSE

/datum/raid_group/New(datum/planet_cell/new_cell, datum/raid_faction_def/new_def, new_points)
	. = ..()
	id = "raid_[++next_id]"
	cell = new_cell
	def = new_def
	points = new_points

/datum/raid_group/Destroy(force)
	for(var/mob/living/pawn as anything in members.Copy())
		release_member(pawn)
	members = null
	exit_turfs = null
	if(SSraid_groups)
		SSraid_groups.groups -= src
	cell = null
	def = null
	origin = null
	return ..()

/// Spawns the raid. Returns FALSE (and spawns nothing) if it cannot happen right now.
/datum/raid_group/proc/launch()
	if(!cell?.is_loaded() || !def)
		return FALSE

	origin = def.find_origin(cell)
	if(def.requires_settlement && !origin)
		return FALSE

	if(!attacker_tech_level)
		attacker_tech_level = def.get_attacker_tech_level(cell)

	var/list/kind_types = def.roll_pawn_kinds(points, attacker_tech_level)
	if(!length(kind_types))
		return FALSE

	arrival_side = pick_arrival_side()
	var/list/entry_turfs = get_entry_turfs()
	if(!length(entry_turfs))
		return FALSE

	// Raiders arrive as one cluster, not spread along the whole edge.
	var/cluster_size = min(length(entry_turfs), max(6, round(length(kind_types) / 2)))
	var/cluster_start = rand(1, length(entry_turfs) - cluster_size + 1)
	var/spawned = 0
	for(var/kind_type in kind_types)
		var/datum/raid_pawn_kind/kind = GLOB.raid_pawn_kinds[kind_type]
		if(!kind)
			continue
		var/turf/where = entry_turfs[cluster_start + (spawned % cluster_size)]
		var/mob/living/pawn = kind.spawn_pawn(where, src)
		if(!istype(pawn))
			continue
		register_member(pawn)
		spawned++

	initial_count = length(members)
	if(!initial_count)
		return FALSE

	launched_at = world.time
	set_state(def.strategy == RAID_STRATEGY_STAGE ? RAID_STATE_STAGING : RAID_STATE_ATTACKING)
	SSraid_groups.groups += src

	announce_to_colonists(replacetext(def.announce_text, "%DIR%", dir2text(arrival_side)))
	log_storyteller("Raid [id] ([def.name]) launched on [cell.get_name()]: [initial_count] pawns, [points] points, tech [attacker_tech_level], arriving from the [dir2text(arrival_side)].")
	message_admins("Storyteller raid: [def.name], [initial_count] raiders ([points] pts, tech [attacker_tech_level]) on cell [cell.get_name()].")
	return TRUE

/// The raid arrives from the side facing its origin settlement.
/datum/raid_group/proc/pick_arrival_side()
	if(origin)
		var/dx = origin.x - cell.x
		var/dy = origin.y - cell.y
		if(dx != 0 && abs(dx) >= abs(dy))
			return dx > 0 ? EAST : WEST
		if(dy != 0)
			return dy > 0 ? NORTH : SOUTH
	return pick(NORTH, SOUTH, EAST, WEST)

/// Free turfs a few tiles inside the arrival edge. Map-edge turfs themselves are avoided on purpose:
/// they open the "leave to the planet map" prompt for any living mob that steps on them.
/datum/raid_group/proc/get_entry_turfs()
	var/list/result = list()
	var/inward = turn(arrival_side, 180)
	for(var/turf/edge as anything in get_cell_edge_turfs(cell, arrival_side))
		var/turf/candidate = edge
		for(var/i in 1 to RAID_ENTRY_DEPTH)
			var/turf/next = get_step(candidate, inward)
			if(!next)
				break
			candidate = next
		if(candidate.density || candidate.is_blocked_turf())
			continue
		result += candidate
	return result

/datum/raid_group/proc/register_member(mob/living/pawn)
	members += pawn
	pawn.rw_raid_group = src
	if(islist(pawn.rw_faction))
		pawn.rw_faction.raid_faction_tag |= def.faction_tag
	RegisterSignal(pawn, COMSIG_QDELETING, PROC_REF(on_member_qdel))

/datum/raid_group/proc/release_member(mob/living/pawn)
	members -= pawn
	if(QDELETED(pawn))
		return
	UnregisterSignal(pawn, COMSIG_QDELETING)
	if(pawn.rw_raid_group == src)
		pawn.rw_raid_group = null
	pawn.rw_raid_released()

/datum/raid_group/proc/on_member_qdel(datum/source, force)
	SIGNAL_HANDLER
	members -= source

/datum/raid_group/proc/set_state(new_state)
	state = new_state
	state_changed_at = world.time

/datum/raid_group/proc/announce_to_colonists(text, danger = TRUE)
	if(!cell || !text)
		return
	for(var/mob/living/colonist as anything in cell.get_colonists())
		to_chat(colonist, danger ? span_userdanger(text) : span_notice(text))

/datum/raid_group/proc/prune_members()
	for(var/mob/living/pawn as anything in members.Copy())
		if(QDELETED(pawn) || pawn.stat == DEAD)
			release_member(pawn)

/// Called once per second by SSraid_groups.
/datum/raid_group/proc/tick()
	if(finished)
		return
	if(!cell || QDELETED(cell) || !cell.is_loaded())
		finish(RAID_RESULT_ABORTED)
		return

	prune_members()
	if(!length(members))
		finish(state == RAID_STATE_RETREATING ? RAID_RESULT_RETREATED : RAID_RESULT_DEFEATED)
		return

	switch(state)
		if(RAID_STATE_STAGING)
			if(world.time >= state_changed_at + RAID_STAGING_TIME)
				set_state(RAID_STATE_ATTACKING)
				announce_to_colonists(def.staged_text)
		if(RAID_STATE_ATTACKING)
			think_attack()
		if(RAID_STATE_RETREATING)
			think_retreat()

/datum/raid_group/proc/should_retreat()
	if(def.retreat_fraction > 0 && initial_count > 0)
		if((initial_count - length(members)) / initial_count >= def.retreat_fraction)
			return TRUE
	if(def.max_duration > 0 && world.time >= launched_at + def.max_duration)
		return TRUE
	return FALSE

/datum/raid_group/proc/think_attack()
	var/list/colonists = cell.get_colonists()
	if(!length(colonists))
		// Nobody to fight (everyone left or died): give up after a while.
		if(!no_target_since)
			no_target_since = world.time
		else if(world.time >= no_target_since + RAID_NO_TARGET_GRACE)
			begin_retreat()
		return
	no_target_since = 0

	if(should_retreat())
		begin_retreat()
		return

	for(var/mob/living/pawn as anything in members)
		var/mob/living/target = find_target(pawn, colonists)
		if(target)
			pawn.rw_raid_attack_tick(target)

/datum/raid_group/proc/find_target(mob/living/pawn, list/colonists)
	var/turf/pawn_turf = get_turf(pawn)
	if(!pawn_turf)
		return null
	var/mob/living/best
	var/best_dist = INFINITY
	for(var/mob/living/colonist as anything in colonists)
		if(QDELETED(colonist) || colonist.stat == DEAD)
			continue
		var/turf/colonist_turf = get_turf(colonist)
		if(!colonist_turf || colonist_turf.z != pawn_turf.z)
			continue
		var/dist = get_dist(pawn_turf, colonist_turf)
		if(dist < best_dist)
			best_dist = dist
			best = colonist
	return best

/datum/raid_group/proc/begin_retreat()
	if(state == RAID_STATE_RETREATING)
		return
	set_state(RAID_STATE_RETREATING)
	exit_turfs = get_cell_edge_turfs(cell, arrival_side)
	if(!length(exit_turfs))
		exit_turfs = get_cell_edge_turfs(cell, null)
	announce_to_colonists(def.retreat_text, FALSE)
	log_storyteller("Raid [id] is retreating ([length(members)]/[initial_count] pawns left).")

/datum/raid_group/proc/think_retreat()
	if(!length(exit_turfs))
		finish(RAID_RESULT_RETREATED)
		return
	for(var/mob/living/pawn as anything in members.Copy())
		var/turf/nearest_exit
		var/nearest_dist = INFINITY
		for(var/turf/exit as anything in exit_turfs)
			var/dist = get_dist(pawn, exit)
			if(dist < nearest_dist)
				nearest_dist = dist
				nearest_exit = exit
		if(!nearest_exit)
			continue
		if(nearest_dist <= RAID_EXIT_DISTANCE)
			pawn.visible_message(span_notice("[pawn] flees the area."))
			release_member(pawn)
			qdel(pawn)
			continue
		pawn.rw_raid_move_to(nearest_exit, RAID_EXIT_DISTANCE)

/datum/raid_group/proc/finish(result)
	if(finished)
		return
	finished = TRUE
	if(result == RAID_RESULT_DEFEATED)
		announce_to_colonists(def.defeat_text, FALSE)
	log_storyteller("Raid [id] ([def.name]) finished: [result].")
	qdel(src)

// ---------------------------------------------------------------------------
// Subsystem
// ---------------------------------------------------------------------------

SUBSYSTEM_DEF(raid_groups)
	name = "Storyteller Raids"
	wait = 1 SECONDS
	runlevels = RUNLEVEL_GAME
	ss_flags = SS_BACKGROUND | SS_KEEP_TIMING

	var/list/datum/raid_group/groups = list()
	var/list/datum/raid_group/currentrun = list()

/datum/controller/subsystem/raid_groups/stat_entry(msg)
	return ..("G:[length(groups)]")

/datum/controller/subsystem/raid_groups/fire(resumed)
	if(!resumed)
		currentrun = groups.Copy()
	var/list/current = currentrun
	while(length(current))
		var/datum/raid_group/group = current[length(current)]
		current.len--
		if(QDELETED(group))
			groups -= group
			continue
		group.tick()
		if(MC_TICK_CHECK)
			return

/// Called every second while the raider should attack `target`.
/mob/living/proc/rw_raid_attack_tick(atom/target)
	if(!target || QDELETED(target) || incapacitated)
		return
	var/obj/item/held = get_active_held_item()
	var/uses_gun = istype(held, /obj/item/gun)
	var/dist = get_dist(src, target)
	if(!combat_mode)
		set_combat_mode(TRUE, TRUE)
	if(dist <= 1 || (uses_gun && dist <= 7 && (target in view(7, src))))
		walk(src, 0)
		face_atom(target)
		ClickOn(target)
		return
	walk_to(src, target, uses_gun ? 4 : 1, 2)

/// Called every second while the raider retreats.
/mob/living/proc/rw_raid_move_to(turf/destination, stop_distance = 0)
	if(!destination || incapacitated)
		return
	walk_to(src, destination, stop_distance, 2)

/// Called when the raider leaves its group (dead, retreated, raid over).
/mob/living/proc/rw_raid_released()
	walk(src, 0)
