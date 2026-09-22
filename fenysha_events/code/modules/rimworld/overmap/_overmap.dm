SUBSYSTEM_DEF(rimworld_planetmap)
	name = "\[RW\] Planet map"
	wait = 1 SECONDS
	ss_flags = SS_BACKGROUND | SS_KEEP_TIMING

	dependencies = list(
		/datum/controller/subsystem/mapping,
		/datum/controller/subsystem/daylight,
	)

	/// Currently loaded planet (only one is supported)
	var/datum/rimworld_planet/planet
	/// Default preset used on Initialize / when type is omitted
	var/default_planet_type = RW_PLANET_PRESET_TERRAN

	/// All currently open planetmap views
	var/list/active_views = list()

	// ── Rotation configuration (subsystem-level defaults; applied to planet) ──
	/// Whether the planet should auto-rotate every fire tick
	var/auto_rotate = TRUE
	/// Degrees added to rotation_angle each fire (when auto_rotate is TRUE)
	var/rotation_speed = 0.001
	/// Current rotation angle in degrees (0–360). Kept in sync with planet.
	var/rotation_angle = 0


/datum/controller/subsystem/rimworld_planetmap/Initialize()
	if(SSmapping.current_map.rimworld_map)
		planet = new /datum/rimworld_planet(null, default_planet_type)
		apply_rotation_settings()

		SStitle.set_lobby_type(/datum/lobby/rimworld)
		SStitle.show_title_screen()
		planet.generate()
	return SS_INIT_SUCCESS


/datum/controller/subsystem/rimworld_planetmap/fire(resumed)
	if(!planet)
		return

	if(auto_rotate && rotation_speed)
		rotation_angle = (rotation_angle + rotation_speed) % 360
		if(rotation_angle < 0)
			rotation_angle += 360
		planet.rotation_angle = rotation_angle

/**
 * Pushes current subsystem rotation settings onto the active planet.
 */
/datum/controller/subsystem/rimworld_planetmap/proc/apply_rotation_settings()
	if(!planet)
		return
	planet.auto_rotate = auto_rotate
	planet.rotation_speed = rotation_speed
	planet.rotation_angle = rotation_angle


/**
 * Enables or disables automatic planet rotation.
 */
/datum/controller/subsystem/rimworld_planetmap/proc/set_auto_rotate(enabled)
	auto_rotate = !!enabled
	if(planet)
		planet.auto_rotate = auto_rotate
	return auto_rotate


/**
 * Sets rotation speed (degrees per fire tick).
 * Negative values rotate the opposite direction.
 */
/datum/controller/subsystem/rimworld_planetmap/proc/set_rotation_speed(new_speed)
	rotation_speed = new_speed
	if(planet)
		planet.rotation_speed = rotation_speed
	return rotation_speed


/**
 * Sets the absolute rotation angle (normalized to 0-360).
 */
/datum/controller/subsystem/rimworld_planetmap/proc/set_rotation_angle(new_angle)
	rotation_angle = new_angle % 360
	if(rotation_angle < 0)
		rotation_angle += 360
	if(planet)
		planet.rotation_angle = rotation_angle
	return rotation_angle


/**
 * Returns current rotation state as a list suitable for UI / networking.
 */
/datum/controller/subsystem/rimworld_planetmap/proc/get_rotation_data()
	return list(
		"autoRotate" = auto_rotate,
		"rotationSpeed" = rotation_speed,
		"rotationAngle" = rotation_angle
	)

/**
 * Generates (or regenerates) the planet.
 * Returns the new planet datum or null on failure.
 */
/datum/controller/subsystem/rimworld_planetmap/proc/generate_planet(planet_type = RW_PLANET_PRESET_TERRAN, planet_seed = null, list/custom_params = null)
	if(planet)
		qdel(planet)

	planet = new /datum/rimworld_planet(planet_seed, planet_type, custom_params)
	apply_rotation_settings()
	if(!planet.generate())
		log_world("SSrimworld_planetmap: planet generation failed.")
		return null

	for(var/datum/planetmap_view/view as anything in active_views)
		view.bind_planet(planet)

	return planet


/**
 * Convenience: regenerate current planet with the same type/seed (or new seed if force_new_seed).
 */
/datum/controller/subsystem/rimworld_planetmap/proc/regenerate_planet(force_new_seed = FALSE)
	if(!planet)
		return generate_planet(default_planet_type)

	var/new_seed = force_new_seed ? null : planet.seed
	return generate_planet(planet.planet_type, new_seed)


/**
 * Returns the active planet (or null).
 */
/datum/controller/subsystem/rimworld_planetmap/proc/get_planet()
	return planet


/**
 * Returns whether a planet is currently loaded and has generated elevation.
 */
/datum/controller/subsystem/rimworld_planetmap/proc/is_planet_ready()
	return planet && planet.maps_generated()


/**
 * Full static + runtime map payload.
 */
/datum/controller/subsystem/rimworld_planetmap/proc/get_map_data()
	if(!planet)
		return null
	return planet.get_map_data()


/**
 * Generator / configuration data only.
 */
/datum/controller/subsystem/rimworld_planetmap/proc/get_generator_data()
	if(!planet)
		return null
	return planet.get_generator_data()


/**
 * Runtime data (objects, revision, tile images, …).
 */
/datum/controller/subsystem/rimworld_planetmap/proc/get_runtime_data()
	if(!planet)
		return null
	return planet.get_runtime_data()


/**
 * Single-tile data packet. Returns null for invalid coordinates or no planet.
 */
/datum/controller/subsystem/rimworld_planetmap/proc/get_tile_data(x, y)
	if(!planet)
		return null
	return planet.get_tile_data(x, y)


/**
 * Biome at coordinates (or null).
 */
/datum/controller/subsystem/rimworld_planetmap/proc/get_biome(x, y)
	if(!planet)
		return null
	return planet.get_biome(x, y)


/**
 * Elevation level at coordinates.
 */
/datum/controller/subsystem/rimworld_planetmap/proc/get_elevation_level(x, y)
	if(!planet)
		return null
	return planet.get_elevation_level(x, y)


/**
 * Whether the given coordinates are valid on the current hex grid.
 */
/datum/controller/subsystem/rimworld_planetmap/proc/is_valid_coordinate(x, y)
	if(!planet)
		return FALSE
	return planet.is_valid_coordinate(x, y)


/datum/controller/subsystem/rimworld_planetmap/proc/register_view(datum/planetmap_view/view)
	if(view)
		active_views |= view


/datum/controller/subsystem/rimworld_planetmap/proc/unregister_view(datum/planetmap_view/view)
	active_views -= view


/datum/controller/subsystem/rimworld_planetmap/proc/find_view(mob/user, view_type)
	for(var/datum/planetmap_view/view as anything in active_views)
		if(view.viewer == user && view.view_type == view_type)
			return view
	return null


/datum/controller/subsystem/rimworld_planetmap/proc/open_view(mob/user, datum/planetmap_view/view_path = /datum/planetmap_view/overview)
	if(!user || !planet)
		return null

	var/datum/planetmap_view/existing = find_view(user, initial(view_path.view_type))
	if(existing)
		existing.ui_interact(user)
		return existing

	var/datum/planetmap_view/view = new view_path(user, planet)
	view.ui_interact(user)
	return view


/datum/controller/subsystem/rimworld_planetmap/proc/open_admin_view(mob/user)
	return open_view(user, /datum/planetmap_view/admin)


/datum/controller/subsystem/rimworld_planetmap/proc/open_overview(mob/user)
	return open_view(user, /datum/planetmap_view/overview)


/datum/controller/subsystem/rimworld_planetmap/proc/open_caravan_view(mob/user, caravan_id = null, origin_x = null, origin_y = null)
	if(!user || !planet)
		return null

	var/datum/planetmap_view/caravan/existing = find_view(user, "caravan")
	if(existing)
		existing.ui_interact(user)
		return existing

	var/datum/planetmap_view/caravan/view = new(user, planet, caravan_id, origin_x, origin_y)
	view.ui_interact(user)
	return view


/**
 * Load overrides
 *
 * Here's things we need to override so we load ONLY what we really need.
 */

// code/controllers/subsystem/shuttle.dm
/datum/controller/subsystem/shuttle/Initialize()
	if(SSmapping.current_map.rimworld_map)
		order_number = rand(1, 9000)
		points = 0

		supply_packs = list()
		chef_groceries = list()
		shopping_list = list()
		request_list = list()
		discovered_plants = list()

		mobile_docking_ports = list()
		stationary_docking_ports = list()
		custom_shuttles = list()
		beacon_list = list()
		transit_docking_ports = list()
		assoc_mobile = list()
		assoc_stationary = list()

		transit_requesters = list()
		transit_request_failures = list()
		transit_utilized = 0

		hostile_environments = list()
		trade_blockade = list()
		hidden_shuttle_turfs = list()
		hidden_shuttle_turf_images = list()
		shuttle_purchase_requirements_met = list()
		has_purchase_shuttle_access = list()
		express_consoles = list()

		emergency = null
		arrivals = null
		backup_shuttle = null
		supply = null

		return SS_INIT_SUCCESS

	return ..()


/datum/controller/subsystem/shuttle/fire()
	if(SSmapping.current_map.rimworld_map)
		return
	return ..()


/datum/controller/subsystem/shuttle/generate_transit_dock(obj/docking_port/mobile/M)
	if(SSmapping.current_map.rimworld_map)
		return FALSE
	return ..()


/datum/controller/subsystem/shuttle/request_transit_dock(obj/docking_port/mobile/M)
	if(SSmapping.current_map.rimworld_map)
		return
	return ..()


/datum/controller/subsystem/shuttle/canEvac()
	if(SSmapping.current_map.rimworld_map || !emergency)
		return "There is no emergency shuttle on this map."
	return ..()


/datum/controller/subsystem/shuttle/check_backup_emergency_shuttle()
	if(SSmapping.current_map.rimworld_map)
		return FALSE
	return ..()


/datum/controller/subsystem/shuttle/CheckAutoEvac()
	if(SSmapping.current_map.rimworld_map)
		return
	return ..()


/datum/controller/subsystem/shuttle/autoEvac()
	if(SSmapping.current_map.rimworld_map)
		return
	return ..()


/datum/controller/subsystem/mapping/proc/initialize_rimworld_empty_world()
	if(length(z_list))
		return

	// Tracking lists — InitializeDefaultZLevels fills z_list for compiled-in zs
	z_level_to_plane_offset = list()
	z_level_to_lowest_plane_offset = list()
	z_level_to_stack = list()
	gravity_by_z_level = list()
	multiz_levels = list()

	InitializeDefaultZLevels()
	var/list/FailedZs = list()

	if(LAZYLEN(FailedZs))
		CRASH("Rimworld boot: failed to load CentCom: [FailedZs.Join(", ")]")

	require_area_resort()
	generate_station_area_list()
	calculate_default_z_level_gravities()

/datum/controller/subsystem/ticker/setup()
	if(SSmapping.current_map.rimworld_map)
		to_chat(world, span_boldannounce("Starting Rimworld session..."))
		if(!CONFIG_GET(flag/ooc_during_round))
			toggle_ooc(FALSE)

		current_state = GAME_STATE_PLAYING
		Master.SetRunLevel(RUNLEVEL_GAME)
		setup_done = TRUE
		for(var/mob/dead/new_player/player in GLOB.new_player_list)
			player.show_title_screen()
		return TRUE
	..()

/datum/controller/subsystem/ticker/check_finished()
	if(!setup_done)
		return FALSE
	if(SSmapping.current_map.rimworld_map)
		return force_ending != END_ROUND_AS_NORMAL
	..()


ADMIN_VERB(open_planet_map, R_ADMIN, "\[RW\] Open planet map", "Open the planetary admin map.", ADMIN_CATEGORY_EVENTS)
	SSrimworld_planetmap.open_admin_view(usr)
