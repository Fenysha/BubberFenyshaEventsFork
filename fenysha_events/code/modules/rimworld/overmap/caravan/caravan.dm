/**
 * ============================================================================
 * RimWorld caravan system
 * ============================================================================
 *
 * A caravan is a group of players (and optionally a vehicle) travelling on the
 * planetary overmap. While on the overmap members live on a tiny holding
 * sub-level and are immobilised; movement is driven through the caravan map UI.
 */

#define RIMWORLD_CARAVAN_TRAIT "rimworld_caravan"
#define RIMWORLD_CARAVAN_HOLDING_SIZE 7
#define RIMWORLD_CARAVAN_ATTACK_SIZE 64
#define RIMWORLD_CARAVAN_ATTACK_EXIT_COOLDOWN (2 MINUTES)

GLOBAL_LIST_EMPTY(rimworld_caravans)

/datum/rimworld_caravan
	var/id
	var/static/next_id = 0

	var/datum/rimworld_planet/planet

	/// Living members of this caravan
	var/list/mob/living/members = list()

	/// Who created the caravan / controls movement
	var/mob/living/leader

	/// Optional vehicle this caravan is tied to (may be in nullspace)
	var/obj/vehicle/sealed/vehicle
	var/has_interior = FALSE

	/// Tiny holding sub-level for foot caravans / disembarked players
	var/datum/turf_reservation/sub_level/holding_level

	var/origin_x
	var/origin_y
	var/current_x
	var/current_y
	var/destination_x
	var/destination_y

	var/moving = FALSE
	var/move_progress = 0

	/// Remaining path as list of list(x, y), next step through the goal. Rust route, DM A* if Rust has none.
	var/list/path

	/// Cached planetary-map portrait (base64 PNG, no data: prefix)
	var/cached_map_icon_b64
	var/cached_map_icon_at = 0

	/// Side the caravan last left a cell from (NORTH/SOUTH/EAST/WEST), for re-entry
	var/exit_side

	/// Open caravan map views bound to this caravan
	var/list/datum/planetmap_view/caravan/bound_views = list()

	/// Pending merge request: requester caravan id -> TRUE
	var/list/pending_merge_from = list()

	/// Pending attack request: requester caravan id -> TRUE
	var/list/pending_attack_from = list()

	/// If this caravan is currently inside a combat arena
	var/datum/rimworld_caravan_arena/active_arena


/datum/rimworld_caravan/New(datum/rimworld_planet/new_planet, origin_x, origin_y, mob/living/creator)
	id = "caravan_[++next_id]"
	planet = new_planet
	src.origin_x = origin_x
	src.origin_y = origin_y
	current_x = origin_x
	current_y = origin_y

	if(planet)
		LAZYADD(planet.caravans, src)

	GLOB.rimworld_caravans[id] = src

	if(creator)
		set_leader(creator)
		add_member(creator)

	return ..()


/datum/rimworld_caravan/Destroy(force)
	for(var/mob/living/M as anything in members.Copy())
		remove_member(M, disband = TRUE)

	release_holding_level()

	if(vehicle && !QDELETED(vehicle))
		unregister_vehicle()

	if(planet)
		LAZYREMOVE(planet.caravans, src)
		planet = null

	GLOB.rimworld_caravans -= id

	for(var/datum/planetmap_view/caravan/V as anything in bound_views.Copy())
		if(!QDELETED(V))
			V.caravan = null
			qdel(V)
	bound_views.Cut()

	active_arena = null
	leader = null
	return ..()


/datum/rimworld_caravan/proc/set_leader(mob/living/new_leader)
	if(!new_leader)
		return
	leader = new_leader


/datum/rimworld_caravan/proc/is_leader(mob/living/M)
	return M && M == leader


/datum/rimworld_caravan/proc/add_member(mob/living/M)
	if(!M || (M in members))
		return FALSE

	members += M
	M.rimworld_caravan = src
	immobilize_member(M)

	if(!leader)
		set_leader(M)

	return TRUE


/datum/rimworld_caravan/proc/remove_member(mob/living/M, disband = FALSE)
	if(!M || !(M in members))
		return FALSE

	members -= M
	if(M.rimworld_caravan == src)
		M.rimworld_caravan = null

	mobilize_member(M)

	if(leader == M)
		leader = length(members) ? members[1] : null

	if(!disband && !length(members) && !vehicle)
		qdel(src)

	return TRUE


/datum/rimworld_caravan/proc/immobilize_member(mob/living/M)
	if(!M)
		return
	ADD_TRAIT(M, TRAIT_IMMOBILIZED, RIMWORLD_CARAVAN_TRAIT)
	ADD_TRAIT(M, TRAIT_HANDS_BLOCKED, RIMWORLD_CARAVAN_TRAIT)


/datum/rimworld_caravan/proc/mobilize_member(mob/living/M)
	if(!M)
		return
	REMOVE_TRAIT(M, TRAIT_IMMOBILIZED, RIMWORLD_CARAVAN_TRAIT)
	REMOVE_TRAIT(M, TRAIT_HANDS_BLOCKED, RIMWORLD_CARAVAN_TRAIT)


/**
 * Ensures the tiny holding sub-level exists and returns a spawn turf.
 */
/datum/rimworld_caravan/proc/ensure_holding_level()
	if(holding_level && !QDELETED(holding_level))
		return get_holding_spawn_turf()

	holding_level = SSsub_levels.create_sub_level(
		RIMWORLD_CARAVAN_HOLDING_SIZE,
		RIMWORLD_CARAVAN_HOLDING_SIZE,
		0,
		"Caravan [id]"
	)

	if(!holding_level)
		return null

	var/turf/BL = holding_level.get_inner_bottom_left_turf()
	var/turf/TR = holding_level.get_inner_top_right_turf()
	if(!BL || !TR)
		return null

	for(var/turf/T as anything in block(BL, TR))
		T.ChangeTurf(/turf/open/floor/plating, flags = CHANGETURF_IGNORE_AIR)

	return get_holding_spawn_turf()


/datum/rimworld_caravan/proc/get_holding_spawn_turf()
	if(!holding_level || QDELETED(holding_level))
		return null
	var/turf/BL = holding_level.get_inner_bottom_left_turf()
	var/turf/TR = holding_level.get_inner_top_right_turf()
	if(!BL || !TR)
		return null
	return locate(
		round((BL.x + TR.x) / 2),
		round((BL.y + TR.y) / 2),
		BL.z
	)


/datum/rimworld_caravan/proc/release_holding_level()
	if(holding_level && !QDELETED(holding_level))
		qdel(holding_level)
	holding_level = null


/datum/rimworld_caravan/proc/move_member_to_holding(mob/living/M)
	if(!M)
		return FALSE
	var/turf/spawn_turf = ensure_holding_level()
	if(!spawn_turf)
		return FALSE
	M.forceMove(spawn_turf)
	immobilize_member(M)
	return TRUE


/**
 * Opens (or reuses) the caravan map UI for a member.
 */
/datum/rimworld_caravan/proc/open_map_for(mob/user)
	if(!user || !planet)
		return null

	var/datum/planetmap_view/caravan/existing = SSrimworld_planetmap.find_view(user, "caravan")
	if(existing)
		existing.bind_caravan(src)
		existing.ui_interact(user)
		return existing

	var/datum/planetmap_view/caravan/view = new(user, planet, id, origin_x, origin_y)
	view.bind_caravan(src)
	view.prevent_close = TRUE
	view.auto_reopen_on_login = TRUE
	if(user.client)
		user.client.forced_planetmap_view = view
	view.ui_interact(user)
	bound_views |= view
	return view


/datum/rimworld_caravan/proc/close_map_for(mob/user)
	var/datum/planetmap_view/caravan/view = SSrimworld_planetmap.find_view(user, "caravan")
	if(!view)
		return
	bound_views -= view
	if(user?.client?.forced_planetmap_view == view)
		user.client.forced_planetmap_view = null
	view.prevent_close = FALSE
	view.auto_reopen_on_login = FALSE
	qdel(view)


// ── Movement ─────────────────────────────────────────────────────────────────

/**
 * Base movement speed multiplier. Higher = faster.
 * Applied on top of biome speed_modifier (which is a cost: higher = slower).
 */
/datum/rimworld_caravan/proc/get_move_speed()
	if(vehicle && !has_interior)
		return 2.5
	if(vehicle && has_interior)
		return 1.5
	return 1


/**
 * Whether this caravan can cross biomes marked passable = FALSE
 * (e.g. ocean via flying vehicles — stub for now).
 */
/datum/rimworld_caravan/proc/can_traverse_impassable()
	return FALSE


/**
 * Travel cost to ENTER tile (x,y). null = impassable.
 * Biome speed_modifier: less = faster, more = slower (see _rwbiome.dm).
 */
/datum/rimworld_caravan/proc/tile_enter_cost(x, y)
	if(!planet?.is_valid_coordinate(x, y))
		return null

	var/biome_key = planet.get_biome(x, y)
	var/list/biomes = planet.get_possible_biomes()
	var/biome_type = biomes?[biome_key]
	if(!biome_type)
		// Unknown biome — treat as normal land
		return 1 / max(0.05, get_move_speed())

	// Ocean etc.: passable = FALSE, passable_flying = TRUE
	if(!biome_type:passable && !(biome_type:passable_flying && can_traverse_impassable()))
		return null

	var/speed_mod = biome_type:speed_modifier
	if(!speed_mod || speed_mod <= 0)
		speed_mod = 1

	// Cost in "tile-seconds": biome cost / caravan speed
	return speed_mod / max(0.05, get_move_speed())


/datum/rimworld_caravan/proc/set_destination(dest_x, dest_y)
	if(!planet?.is_valid_coordinate(dest_x, dest_y))
		return FALSE
	// Cannot set destination on impassable tile
	if(isnull(tile_enter_cost(dest_x, dest_y)))
		return FALSE
	destination_x = dest_x
	destination_y = dest_y
	if(dest_x == current_x && dest_y == current_y)
		path = null
		refresh_bound_views()
		return TRUE
	if(!build_travel_path())
		destination_x = null
		destination_y = null
		path = null
		refresh_bound_views()
		return FALSE
	refresh_bound_views()
	return TRUE

/**
 * Cell-by-cell overland route from the current tile to the destination.
 * Prefers Rust (roads cheap, water blocked). Falls back to the DM A* when Rust
 * has no route or a step is impassable for this caravan.
 * Stores the steps AFTER the current tile. Returns FALSE when there is no route.
 */
/datum/rimworld_caravan/proc/build_travel_path()
	path = null
	if(!planet || isnull(destination_x) || isnull(destination_y))
		return FALSE
	if(destination_x == current_x && destination_y == current_y)
		return FALSE

	var/list/route
	try
		route = planet.find_path(current_x, current_y, destination_x, destination_y, TRUE)
	catch
		route = null

	if(!rust_route_walkable(route))
		route = planet.find_caravan_path(current_x, current_y, destination_x, destination_y, src)

	if(!length(route))
		return FALSE

	var/list/first = route[1]
	if(islist(first) && first[1] == current_x && first[2] == current_y)
		route.Cut(1, 2)
	if(!length(route))
		return FALSE

	path = route
	return TRUE

/datum/rimworld_caravan/proc/rust_route_walkable(list/route)
	if(!islist(route) || !length(route))
		return FALSE
	for(var/step in route)
		if(!islist(step) || length(step) < 2)
			return FALSE
		if(step[1] == current_x && step[2] == current_y)
			continue
		if(isnull(tile_enter_cost(step[1], step[2])))
			return FALSE
	return TRUE

/// Current tile plus every remaining step, for the globe trail.
/datum/rimworld_caravan/proc/get_route_ui()
	var/list/route = list()
	if(isnull(current_x) || isnull(current_y))
		return route
	if(!length(path) && isnull(destination_x))
		return route
	route += list(list("x" = current_x, "y" = current_y))
	for(var/step in path)
		if(!islist(step) || length(step) < 2)
			continue
		route += list(list("x" = step[1], "y" = step[2]))
	return route


/datum/rimworld_caravan/proc/start_travel()
	if(isnull(destination_x) || isnull(destination_y))
		return FALSE
	if(destination_x == current_x && destination_y == current_y)
		return FALSE
	if(active_arena)
		return FALSE
	if(isnull(tile_enter_cost(destination_x, destination_y)))
		for(var/mob/living/M as anything in members)
			to_chat(M, span_warning("That tile is impassable."))
		return FALSE

	if(!build_travel_path())
		for(var/mob/living/M as anything in members)
			to_chat(M, span_warning("No route to ([destination_x], [destination_y])."))
		return FALSE

	moving = TRUE
	move_progress = 0
	for(var/mob/living/M as anything in members)
		to_chat(M, span_notice("Caravan departs for ([destination_x], [destination_y]). [length(path)] tiles."))
	refresh_bound_views()
	return TRUE


/datum/rimworld_caravan/proc/stop_travel()
	moving = FALSE
	move_progress = 0
	if(!isnull(destination_x) && (destination_x != current_x || destination_y != current_y))
		build_travel_path()
	else
		path = null
	refresh_bound_views()


/**
 * Advance along the precomputed path.
 * delta_ds — elapsed time in deciseconds.
 * move_progress accumulates until >= next tile cost, then steps.
 */
/datum/rimworld_caravan/proc/process_movement(delta_ds)
	if(!moving)
		return
	if(isnull(destination_x) || isnull(destination_y))
		stop_travel()
		return
	if(current_x == destination_x && current_y == destination_y)
		arrive_at_destination()
		return
	if(delta_ds <= 0)
		return

	if(!length(path))
		// Path exhausted or never built — try rebuild once
		if(!build_travel_path())
			stop_travel()
			for(var/mob/living/M as anything in members)
				to_chat(M, span_warning("The caravan lost its route."))
			return

	// Seconds elapsed this tick
	move_progress += delta_ds / 10

	var/safety = 32
	while(moving && length(path) && safety-- > 0)
		var/list/next = path[1]
		var/nx = next[1]
		var/ny = next[2]
		var/cost = tile_enter_cost(nx, ny)
		if(isnull(cost))
			// Tile became impassable mid-route
			if(!build_travel_path())
				stop_travel()
				for(var/mob/living/M as anything in members)
					to_chat(M, span_warning("The route is blocked."))
				return
			var/list/rebuilt = length(path) ? path[1] : null
			if(!islist(rebuilt) || (rebuilt[1] == nx && rebuilt[2] == ny))
				stop_travel()
				for(var/mob/living/M as anything in members)
					to_chat(M, span_warning("The route is blocked."))
				return
			continue

		if(move_progress < cost)
			break

		move_progress -= cost
		path.Cut(1, 2)
		current_x = nx
		current_y = ny

		if(current_x == destination_x && current_y == destination_y)
			arrive_at_destination()
			return

	refresh_bound_views()


/datum/rimworld_caravan/proc/arrive_at_destination()
	if(!isnull(destination_x) && !isnull(destination_y))
		current_x = destination_x
		current_y = destination_y
	destination_x = null
	destination_y = null
	moving = FALSE
	move_progress = 0
	path = null
	for(var/mob/living/M as anything in members)
		to_chat(M, span_notice("The caravan has arrived at ([current_x], [current_y])."))
	refresh_bound_views()


/datum/rimworld_caravan/proc/refresh_bound_views()
	for(var/datum/planetmap_view/caravan/V as anything in bound_views)
		if(QDELETED(V))
			continue
		V.destination_x = destination_x
		V.destination_y = destination_y
		SStgui.update_uis(V)


// ── Merge ────────────────────────────────────────────────────────────────────

/**
 * Leader of this caravan requests to merge into target (target's leader must accept).
 */
/datum/rimworld_caravan/proc/request_merge(datum/rimworld_caravan/target)
	if(!target || target == src || QDELETED(target))
		return FALSE
	if(target.current_x != current_x || target.current_y != current_y)
		return FALSE
	if(active_arena || target.active_arena)
		return FALSE

	target.pending_merge_from[id] = TRUE

	if(target.leader)
		to_chat(target.leader, span_notice("Caravan [id] requests to merge with your caravan. Open the caravan map to accept or deny."))
	for(var/mob/living/M as anything in members)
		to_chat(M, span_notice("Merge request sent to caravan [target.id]."))
	return TRUE


/datum/rimworld_caravan/proc/accept_merge(requester_id)
	if(!pending_merge_from[requester_id])
		return FALSE

	pending_merge_from -= requester_id
	var/datum/rimworld_caravan/other = GLOB.rimworld_caravans[requester_id]
	if(!other || QDELETED(other))
		return FALSE
	if(other.current_x != current_x || other.current_y != current_y)
		return FALSE

	// Absorb other into this (leader stays this.leader)
	for(var/mob/living/M as anything in other.members.Copy())
		other.remove_member(M, disband = TRUE)
		add_member(M)
		if(!vehicle)
			move_member_to_holding(M)
		open_map_for(M)

	if(other.vehicle && !vehicle)
		register_vehicle(other.vehicle, other.has_interior)
		other.unregister_vehicle()

	qdel(other)

	for(var/mob/living/M as anything in members)
		to_chat(M, span_notice("Caravans merged. Leader: [leader]."))
	return TRUE


/datum/rimworld_caravan/proc/deny_merge(requester_id)
	if(!pending_merge_from[requester_id])
		return FALSE
	pending_merge_from -= requester_id
	var/datum/rimworld_caravan/other = GLOB.rimworld_caravans[requester_id]
	if(other)
		for(var/mob/living/M as anything in other.members)
			to_chat(M, span_warning("Merge request denied by caravan [id]."))
	return TRUE


/**
 * Split selected members into a new caravan. Only leader may split.
 * members_to_split: list of mobs that leave.
 */
/datum/rimworld_caravan/proc/split_members(list/mob/living/members_to_split, mob/living/new_leader)
	if(!is_leader(usr) && !is_leader(new_leader))
		// allow explicit new_leader argument from UI later
		if(!new_leader)
			return null

	var/list/leaving = list()
	for(var/mob/living/M as anything in members_to_split)
		if(M in members)
			leaving += M

	if(!length(leaving))
		return null

	if(!new_leader || !(new_leader in leaving))
		new_leader = leaving[1]

	var/datum/rimworld_caravan/fresh = new /datum/rimworld_caravan(planet, current_x, current_y, null)
	fresh.current_x = current_x
	fresh.current_y = current_y
	fresh.exit_side = exit_side

	for(var/mob/living/M as anything in leaving)
		remove_member(M, disband = TRUE)
		fresh.add_member(M)
		fresh.move_member_to_holding(M)
		fresh.open_map_for(M)

	fresh.set_leader(new_leader)

	if(!length(members) && !vehicle)
		qdel(src)

	return fresh


// ── Attack ───────────────────────────────────────────────────────────────────

/datum/rimworld_caravan/proc/request_attack(datum/rimworld_caravan/target)
	if(!target || target == src || QDELETED(target))
		return FALSE
	if(target.current_x != current_x || target.current_y != current_y)
		return FALSE
	if(active_arena || target.active_arena)
		return FALSE

	target.pending_attack_from[id] = TRUE
	if(target.leader)
		to_chat(target.leader, span_userdanger("Caravan [id] challenges you to combat! Open the caravan map to accept or deny."))
	for(var/mob/living/M as anything in members)
		to_chat(M, span_notice("Attack request sent to caravan [target.id]."))
	return TRUE


/datum/rimworld_caravan/proc/accept_attack(requester_id)
	if(!pending_attack_from[requester_id])
		return FALSE
	pending_attack_from -= requester_id

	var/datum/rimworld_caravan/other = GLOB.rimworld_caravans[requester_id]
	if(!other || QDELETED(other))
		return FALSE
	if(other.current_x != current_x || other.current_y != current_y)
		return FALSE

	return start_caravan_combat(src, other)


/datum/rimworld_caravan/proc/deny_attack(requester_id)
	if(!pending_attack_from[requester_id])
		return FALSE
	pending_attack_from -= requester_id
	var/datum/rimworld_caravan/other = GLOB.rimworld_caravans[requester_id]
	if(other)
		for(var/mob/living/M as anything in other.members)
			to_chat(M, span_warning("Attack request denied by caravan [id]."))
	return TRUE


// ── Enter tile ───────────────────────────────────────────────────────────────

/**
 * All (or selected) members enter the planet cell at current_x/current_y.
 * Spawns them on the logical arrival edge (exit_side) or a random edge.
 */
/datum/rimworld_caravan/proc/enter_current_tile(list/mob/living/who = null)
	if(active_arena)
		return FALSE
	if(!planet?.is_valid_coordinate(current_x, current_y))
		return FALSE

	var/list/entering = who || members.Copy()
	if(!length(entering))
		return FALSE

	var/datum/planet_cell/cell = planet.get_or_create_cell(current_x, current_y, FALSE)
	if(!cell)
		return FALSE

	// Load then spawn — callback signature: Invoke(cell, success)
	cell.ensure_loaded(null, CALLBACK(src, PROC_REF(on_cell_ready_for_entry), entering.Copy()))
	return TRUE


/datum/rimworld_caravan/proc/on_cell_ready_for_entry(list/mob/living/entering, datum/planet_cell/cell, success)
	if(!success || !cell?.is_loaded())
		for(var/mob/living/M as anything in entering)
			to_chat(M, span_warning("Failed to load the map cell."))
		return

	var/list/edge_turfs = get_cell_edge_turfs(cell, exit_side)
	if(!length(edge_turfs))
		edge_turfs = get_cell_edge_turfs(cell, null)

	var/i = 1
	for(var/mob/living/M as anything in entering)
		if(QDELETED(M) || !(M in members))
			continue
		var/turf/T = edge_turfs[i]
		i = (i % length(edge_turfs)) + 1

		close_map_for(M)
		mobilize_member(M)
		M.forceMove(T)
		remove_member(M, disband = TRUE)
		to_chat(M, span_notice("You leave the caravan and enter the local map."))

	// Vehicle with interior: bring it back from nullspace onto the edge
	if(vehicle && !QDELETED(vehicle) && has_interior)
		var/turf/park = edge_turfs[1]
		vehicle.forceMove(park)
		unregister_vehicle()

	if(!length(members) && !vehicle)
		qdel(src)


/**
 * Returns turfs along one edge of a loaded cell. side = null → random edge.
 */
/proc/get_cell_edge_turfs(datum/planet_cell/cell, side)
	if(!cell?.is_loaded())
		return list()

	var/turf/BL = cell.reservation.get_inner_bottom_left_turf()
	var/turf/TR = cell.reservation.get_inner_top_right_turf()
	if(!BL || !TR)
		return list()

	if(isnull(side))
		side = pick(NORTH, SOUTH, EAST, WEST)

	var/list/result = list()
	switch(side)
		if(NORTH)
			for(var/x = BL.x to TR.x)
				var/turf/T = locate(x, TR.y, BL.z)
				if(T && !T.density)
					result += T
		if(SOUTH)
			for(var/x = BL.x to TR.x)
				var/turf/T = locate(x, BL.y, BL.z)
				if(T && !T.density)
					result += T
		if(EAST)
			for(var/y = BL.y to TR.y)
				var/turf/T = locate(TR.x, y, BL.z)
				if(T && !T.density)
					result += T
		if(WEST)
			for(var/y = BL.y to TR.y)
				var/turf/T = locate(BL.x, y, BL.z)
				if(T && !T.density)
					result += T

	return result


// ── Vehicle binding ──────────────────────────────────────────────────────────

/datum/rimworld_caravan/proc/register_vehicle(obj/vehicle/sealed/V, interior = FALSE)
	if(!V)
		return
	vehicle = V
	has_interior = interior
	V.rimworld_caravan = src


/datum/rimworld_caravan/proc/unregister_vehicle()
	if(vehicle && !QDELETED(vehicle))
		vehicle.rimworld_caravan = null
	vehicle = null
	has_interior = FALSE


/**
 * Base64 PNG of the icon shown on the planetary map for this caravan.
 * Prefers vehicle (via get_caravan_map_icon), then leader appearance.
 * Cached briefly — getFlatIcon is expensive.
 */
/datum/rimworld_caravan/proc/get_map_icon_b64()
	if(cached_map_icon_b64 && (world.time < cached_map_icon_at + 5 SECONDS))
		return cached_map_icon_b64

	var/icon/flat
	if(vehicle && !QDELETED(vehicle))
		flat = vehicle.get_caravan_map_icon()

	if(!flat)
		var/atom/source = leader
		if(!source && length(members))
			source = members[1]
		if(source)
			flat = getFlatIcon(source, SOUTH, start = FALSE)

	if(!flat)
		cached_map_icon_b64 = null
		return null

	cached_map_icon_b64 = icon2base64(flat)
	cached_map_icon_at = world.time
	return cached_map_icon_b64


// ── Helpers ──────────────────────────────────────────────────────────────────

/proc/get_rimworld_caravan(id)
	return GLOB.rimworld_caravans[id]


/proc/get_caravans_at(datum/rimworld_planet/planet, tile_x, tile_y)
	var/list/result = list()
	if(!planet)
		return result
	for(var/datum/rimworld_caravan/C as anything in planet.caravans)
		if(C.current_x == tile_x && C.current_y == tile_y)
			result += C
	return result


/**
 * Creates a foot caravan for a single player leaving a local cell.
 */
/proc/create_foot_caravan(mob/living/M, datum/planet_cell/cell, exit_side)
	if(!M || !cell?.planet)
		return null

	var/datum/rimworld_caravan/C = new /datum/rimworld_caravan(cell.planet, cell.x, cell.y, M)
	C.exit_side = exit_side
	C.move_member_to_holding(M)
	C.open_map_for(M)
	to_chat(M, span_notice("You leave the local map and join the planetary caravan network."))
	return C


// Mob / vehicle back-references
/mob/living
	var/datum/rimworld_caravan/rimworld_caravan

/obj/vehicle/sealed
	var/datum/rimworld_caravan/rimworld_caravan

/datum/rimworld_planet
	var/list/caravans = list()


// ── Pathfinding (A*) ─────────────────────────────────────────────────────────

/**
 * A* route across the geodesic hex grid.
 * Returns list of list(x, y) from the step AFTER start through goal inclusive.
 * Empty list = no route.
 *
 * Tile costs come from caravan.tile_enter_cost (biome speed_modifier / caravan speed).
 * Impassable biomes (passable = FALSE) are skipped unless the caravan can fly.
 */
/datum/rimworld_planet/proc/find_caravan_path(sx, sy, gx, gy, datum/rimworld_caravan/C)
	if(!C || !is_valid_coordinate(sx, sy) || !is_valid_coordinate(gx, gy))
		return list()
	if(sx == gx && sy == gy)
		return list()
	if(isnull(C.tile_enter_cost(gx, gy)))
		return list()

	var/list/came_from = list()
	var/list/g_score = list()
	var/list/closed = list()
	var/list/open_keys = list()
	var/list/open_f = list()

	var/start_key = "[sx]:[sy]"
	g_score[start_key] = 0
	open_keys += start_key
	open_f[start_key] = caravan_path_heuristic(sx, sy, gx, gy)

	var/max_iters = 80000
	var/iters = 0

	while(length(open_keys) && iters++ < max_iters)
		// Pop lowest f
		var/best_key
		var/best_f = 1e30
		for(var/k in open_keys)
			var/f = open_f[k]
			if(f < best_f)
				best_f = f
				best_key = k

		if(!best_key)
			break

		open_keys -= best_key

		var/list/parts = splittext(best_key, ":")
		var/cx = text2num(parts[1])
		var/cy = text2num(parts[2])

		if(cx == gx && cy == gy)
			return reconstruct_caravan_path(came_from, best_key, start_key)

		closed[best_key] = TRUE

		for(var/list/n as anything in get_neighbors(cx, cy))
			var/nx = n[1]
			var/ny = n[2]
			var/nkey = "[nx]:[ny]"
			if(closed[nkey])
				continue

			var/step_cost = C.tile_enter_cost(nx, ny)
			if(isnull(step_cost))
				continue

			var/tentative = g_score[best_key] + step_cost
			var/old_g = g_score[nkey]
			if(!isnull(old_g) && tentative >= old_g)
				continue

			came_from[nkey] = best_key
			g_score[nkey] = tentative
			open_f[nkey] = tentative + caravan_path_heuristic(nx, ny, gx, gy)
			if(!(nkey in open_keys))
				open_keys += nkey

	return list()


/**
 * Admissible heuristic: angular distance on the unit sphere between tile centres,
 * scaled so it is never larger than true path cost for speed_modifier >= ~0.5.
 */
/datum/rimworld_planet/proc/caravan_path_heuristic(x1, y1, x2, y2)
	var/list/a = get_tile_center(x1, y1)
	var/list/b = get_tile_center(x2, y2)
	if(!a || !b)
		return abs(x1 - x2) + abs(y1 - y2)
	var/dot = clamp(rw_vec_dot(a, b), -1, 1)
	// acos(dot) in radians; multiply by grid_frequency ≈ tiles along a great-circle quarter
	var/angle = arccos(dot)
	return (angle / 180) * PI * grid_frequency * 0.35


/datum/rimworld_planet/proc/reconstruct_caravan_path(list/came_from, end_key, start_key)
	var/list/rev = list()
	var/key = end_key
	while(key && key != start_key)
		var/list/parts = splittext(key, ":")
		rev += list(list(text2num(parts[1]), text2num(parts[2])))
		key = came_from[key]

	// reverse
	var/list/path = list()
	for(var/i = length(rev); i >= 1; i--)
		path += list(rev[i])
	return path
