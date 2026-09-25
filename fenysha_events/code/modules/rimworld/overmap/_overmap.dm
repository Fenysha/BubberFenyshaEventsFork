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

	var/auto_rotate = TRUE
	/// Degrees per fire tick when auto_rotate is TRUE
	var/rotation_speed = 0.25
	/// 0-360, kept in sync with planet
	var/rotation_angle = 0

	/// 0-based days since epoch (day 1 of starting year)
	var/total_days = 0
	var/current_year = RW_STARTING_YEAR
	/// 1..60
	var/day_of_year = RW_STARTING_DAY_OF_YEAR
	/// String key "0".."3" (RW_QUADRUM_*)
	var/current_quadrum = RW_QUADRUM_APRIMAY
	/// 1..15
	var/day_of_quadrum = 1
	/// 0..24, derived from rotation_angle
	var/time_of_day = 0
	var/time_scale = 1
	/// If FALSE, rotation still updates but calendar does not advance
	var/advance_calendar = TRUE
	var/daylight_fraction = RW_DEFAULT_DAYLIGHT_FRACTION


/datum/controller/subsystem/rimworld_planetmap/Initialize()
	if(SSmapping.current_map.rimworld_map)
		planet = new /datum/rimworld_planet(null, default_planet_type)
		apply_rotation_settings()
		sync_time_to_planet()

		SStitle.set_lobby_type(/datum/lobby/rimworld)
		SStitle.show_title_screen()
		planet.generate()
	return SS_INIT_SUCCESS


/datum/controller/subsystem/rimworld_planetmap/fire(resumed)
	if(!planet)
		return

	if(auto_rotate && rotation_speed)
		var/delta = rotation_speed * time_scale
		var/old_angle = rotation_angle
		rotation_angle = rotation_angle + delta
		if(rotation_angle >= 360)
			rotation_angle -= 360
		else if(rotation_angle < 0)
			rotation_angle += 360
		planet.rotation_angle = rotation_angle

		time_of_day = (rotation_angle / 360) * RW_HOURS_PER_DAY
		planet.time_of_day = time_of_day

		if(advance_calendar)
			var/crossed = FALSE
			if(delta > 0 && old_angle + delta >= 360)
				crossed = TRUE
			else if(delta < 0 && old_angle + delta < 0)
				crossed = TRUE
			if(crossed)
				advance_day(sign(delta))


/datum/controller/subsystem/rimworld_planetmap/proc/sync_time_to_planet()
	if(!planet)
		return
	planet.auto_rotate = auto_rotate
	planet.rotation_speed = rotation_speed
	planet.rotation_angle = rotation_angle
	planet.time_of_day = time_of_day
	planet.total_days = total_days
	planet.current_year = current_year
	planet.day_of_year = day_of_year
	planet.current_quadrum = current_quadrum
	planet.day_of_quadrum = day_of_quadrum
	planet.daylight_fraction = daylight_fraction


/datum/controller/subsystem/rimworld_planetmap/proc/apply_rotation_settings()
	if(!planet)
		return
	planet.auto_rotate = auto_rotate
	planet.rotation_speed = rotation_speed
	planet.rotation_angle = rotation_angle


/datum/controller/subsystem/rimworld_planetmap/proc/advance_day(direction = 1)
	if(!direction)
		return

	var/old_year = current_year
	var/old_quadrum = current_quadrum
	var/old_season_north = get_season_for_hemisphere("north")
	var/old_season_south = get_season_for_hemisphere("south")

	total_days += direction
	if(total_days < 0)
		total_days = 0

	recompute_calendar_from_total_days()
	sync_time_to_planet()

	SEND_SIGNAL(src, COMSIG_RIMWORLD_PLANET_DAY_PASSED, total_days, current_year, day_of_year)
	if(planet)
		SEND_SIGNAL(planet, COMSIG_RIMWORLD_PLANET_DAY_PASSED, total_days, current_year, day_of_year)

	if(current_quadrum != old_quadrum)
		SEND_SIGNAL(src, COMSIG_RIMWORLD_PLANET_QUADRUM_CHANGED, old_quadrum, current_quadrum, current_year)
		if(planet)
			SEND_SIGNAL(planet, COMSIG_RIMWORLD_PLANET_QUADRUM_CHANGED, old_quadrum, current_quadrum, current_year)

	if(current_year != old_year)
		SEND_SIGNAL(src, COMSIG_RIMWORLD_PLANET_YEAR_CHANGED, old_year, current_year)
		if(planet)
			SEND_SIGNAL(planet, COMSIG_RIMWORLD_PLANET_YEAR_CHANGED, old_year, current_year)

	var/new_season_north = get_season_for_hemisphere("north")
	var/new_season_south = get_season_for_hemisphere("south")
	if(new_season_north != old_season_north)
		SEND_SIGNAL(src, COMSIG_RIMWORLD_PLANET_SEASON_CHANGED, "north", old_season_north, new_season_north, current_quadrum, current_year)
		if(planet)
			SEND_SIGNAL(planet, COMSIG_RIMWORLD_PLANET_SEASON_CHANGED, "north", old_season_north, new_season_north, current_quadrum, current_year)
	if(new_season_south != old_season_south)
		SEND_SIGNAL(src, COMSIG_RIMWORLD_PLANET_SEASON_CHANGED, "south", old_season_south, new_season_south, current_quadrum, current_year)
		if(planet)
			SEND_SIGNAL(planet, COMSIG_RIMWORLD_PLANET_SEASON_CHANGED, "south", old_season_south, new_season_south, current_quadrum, current_year)


/datum/controller/subsystem/rimworld_planetmap/proc/recompute_calendar_from_total_days()
	var/absolute = total_days
	current_year = RW_STARTING_YEAR + (absolute / RW_DAYS_PER_YEAR)
	var/doy = (absolute % RW_DAYS_PER_YEAR) + 1
	day_of_year = doy
	var/quadrum_index = (doy - 1) / RW_DAYS_PER_QUADRUM // 0..3
	current_quadrum = num2text(quadrum_index)
	day_of_quadrum = ((doy - 1) % RW_DAYS_PER_QUADRUM) + 1


/datum/controller/subsystem/rimworld_planetmap/proc/get_season_for_hemisphere(hemisphere)
	var/list/north_map = list(
		RW_QUADRUM_APRIMAY = RW_SEASON_SPRING,
		RW_QUADRUM_JUGUST = RW_SEASON_SUMMER,
		RW_QUADRUM_SEPTOBER = RW_SEASON_FALL,
		RW_QUADRUM_DECEMBARY = RW_SEASON_WINTER,
	)
	var/list/south_map = list(
		RW_QUADRUM_APRIMAY = RW_SEASON_FALL,
		RW_QUADRUM_JUGUST = RW_SEASON_WINTER,
		RW_QUADRUM_SEPTOBER = RW_SEASON_SPRING,
		RW_QUADRUM_DECEMBARY = RW_SEASON_SUMMER,
	)
	var/key = current_quadrum
	if(isnum(key))
		key = num2text(key)
	if(hemisphere == "south")
		return south_map[key]
	return north_map[key]


/datum/controller/subsystem/rimworld_planetmap/proc/get_quadrum_name(quadrum = null)
	if(isnull(quadrum))
		quadrum = current_quadrum
	var/idx = isnum(quadrum) ? quadrum : text2num(quadrum)
	if(isnull(idx) || idx < 0 || idx >= RW_QUADRUMS_PER_YEAR)
		return "Unknown"
	return RW_QUADRUM_NAMES[idx + 1]


/datum/controller/subsystem/rimworld_planetmap/proc/get_calendar_data()
	return list(
		"totalDays" = total_days,
		"year" = current_year,
		"dayOfYear" = day_of_year,
		"quadrum" = current_quadrum,
		"quadrumName" = get_quadrum_name(),
		"dayOfQuadrum" = day_of_quadrum,
		"timeOfDay" = time_of_day,
		"rotationAngle" = rotation_angle,
		"seasonNorth" = get_season_for_hemisphere("north"),
		"seasonSouth" = get_season_for_hemisphere("south"),
		"timeScale" = time_scale,
		"daysPerYear" = RW_DAYS_PER_YEAR,
		"daysPerQuadrum" = RW_DAYS_PER_QUADRUM,
	)


/datum/controller/subsystem/rimworld_planetmap/proc/timeskip_days(days)
	if(!days)
		return
	var/steps = abs(days)
	var/dir = days > 0 ? 1 : -1
	for(var/i in 1 to steps)
		advance_day(dir)


/datum/controller/subsystem/rimworld_planetmap/proc/set_calendar(year, day_of_year_target = 1, hour = null)
	year = max(RW_STARTING_YEAR, year)
	day_of_year_target = clamp(day_of_year_target, 1, RW_DAYS_PER_YEAR)
	var/target_total = (year - RW_STARTING_YEAR) * RW_DAYS_PER_YEAR + (day_of_year_target - 1)
	var/delta = target_total - total_days
	if(delta)
		timeskip_days(delta)
	if(!isnull(hour))
		set_time_of_day(hour)


/datum/controller/subsystem/rimworld_planetmap/proc/set_time_of_day(hour)
	hour = hour % RW_HOURS_PER_DAY
	if(hour < 0)
		hour += RW_HOURS_PER_DAY
	time_of_day = hour
	rotation_angle = (hour / RW_HOURS_PER_DAY) * 360
	if(planet)
		planet.time_of_day = time_of_day
		planet.rotation_angle = rotation_angle
	return time_of_day


/datum/controller/subsystem/rimworld_planetmap/proc/set_quadrum(quadrum, keep_day_of_quadrum = TRUE)
	var/idx = isnum(quadrum) ? quadrum : text2num(quadrum)
	if(isnull(idx))
		return FALSE
	idx = clamp(idx, 0, RW_QUADRUMS_PER_YEAR - 1)
	var/target_doy = idx * RW_DAYS_PER_QUADRUM + (keep_day_of_quadrum ? day_of_quadrum : 1)
	target_doy = clamp(target_doy, 1, RW_DAYS_PER_YEAR)
	set_calendar(current_year, target_doy)
	return TRUE


/datum/controller/subsystem/rimworld_planetmap/proc/set_season_north(season)
	var/target_quadrum
	switch(season)
		if(RW_SEASON_SPRING)
			target_quadrum = RW_QUADRUM_APRIMAY
		if(RW_SEASON_SUMMER)
			target_quadrum = RW_QUADRUM_JUGUST
		if(RW_SEASON_FALL)
			target_quadrum = RW_QUADRUM_SEPTOBER
		if(RW_SEASON_WINTER)
			target_quadrum = RW_QUADRUM_DECEMBARY
		else
			return FALSE
	return set_quadrum(target_quadrum)


/datum/controller/subsystem/rimworld_planetmap/proc/set_time_scale(scale)
	time_scale = max(0, scale)
	return time_scale


/datum/controller/subsystem/rimworld_planetmap/proc/set_advance_calendar(enabled)
	advance_calendar = !!enabled
	return advance_calendar


/datum/controller/subsystem/rimworld_planetmap/proc/set_auto_rotate(enabled)
	auto_rotate = !!enabled
	if(planet)
		planet.auto_rotate = auto_rotate
	return auto_rotate


/datum/controller/subsystem/rimworld_planetmap/proc/set_rotation_speed(new_speed)
	rotation_speed = new_speed
	if(planet)
		planet.rotation_speed = rotation_speed
	return rotation_speed


/datum/controller/subsystem/rimworld_planetmap/proc/set_rotation_angle(new_angle)
	rotation_angle = new_angle % 360
	if(rotation_angle < 0)
		rotation_angle += 360
	time_of_day = (rotation_angle / 360) * RW_HOURS_PER_DAY
	if(planet)
		planet.rotation_angle = rotation_angle
		planet.time_of_day = time_of_day
	return rotation_angle


/datum/controller/subsystem/rimworld_planetmap/proc/get_rotation_data()
	return list(
		"autoRotate" = auto_rotate,
		"rotationSpeed" = rotation_speed,
		"rotationAngle" = rotation_angle,
	)


/datum/controller/subsystem/rimworld_planetmap/proc/generate_planet(planet_type = RW_PLANET_PRESET_TERRAN, planet_seed = null, list/custom_params = null)
	if(planet)
		qdel(planet)

	planet = new /datum/rimworld_planet(planet_seed, planet_type, custom_params)
	apply_rotation_settings()
	sync_time_to_planet()
	if(!planet.generate())
		log_world("SSrimworld_planetmap: planet generation failed.")
		return null

	for(var/datum/planetmap_view/view as anything in active_views)
		view.bind_planet(planet)

	return planet


/datum/controller/subsystem/rimworld_planetmap/proc/regenerate_planet(force_new_seed = FALSE)
	if(!planet)
		return generate_planet(default_planet_type)
	var/new_seed = force_new_seed ? null : planet.seed
	return generate_planet(planet.planet_type, new_seed)


/datum/controller/subsystem/rimworld_planetmap/proc/get_planet()
	return planet


/datum/controller/subsystem/rimworld_planetmap/proc/is_planet_ready()
	return planet && planet.maps_generated()


/datum/controller/subsystem/rimworld_planetmap/proc/get_map_data()
	if(!planet)
		return null
	return planet.get_map_data()


/datum/controller/subsystem/rimworld_planetmap/proc/get_generator_data()
	if(!planet)
		return null
	return planet.get_generator_data()


/datum/controller/subsystem/rimworld_planetmap/proc/get_runtime_data()
	if(!planet)
		return null
	return planet.get_runtime_data()


/datum/controller/subsystem/rimworld_planetmap/proc/get_tile_data(x, y)
	if(!planet)
		return null
	return planet.get_tile_data(x, y)


/datum/controller/subsystem/rimworld_planetmap/proc/get_biome(x, y)
	if(!planet)
		return null
	return planet.get_biome(x, y)


/datum/controller/subsystem/rimworld_planetmap/proc/get_elevation_level(x, y)
	if(!planet)
		return null
	return planet.get_elevation_level(x, y)


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

/datum/controller/subsystem/rimworld_planetmap/proc/clear_view(mob/user, datum/planetmap_view/view)
	if(!QDELETED(view) && (view in active_views))
		active_views -= view

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

/datum/controller/subsystem/rimworld_planetmap/proc/open_settlement_view(mob/user, observer = FALSE)
	if(!user || !planet)
		return null
	var/datum/planetmap_view/settlement/existing = find_view(user, "settlement")
	if(existing)
		existing.ui_interact(user)
		return existing
	var/datum/planetmap_view/settlement/view = new(user, planet, observer ? "observer" : "start")
	view.ui_interact(user)
	return view

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


/datum/controller/subsystem/rimworld_planetmap/proc/create_observer(mob/dead/new_player/user)
	set waitfor = FALSE

	if(QDELETED(user) || !user.client || !isnewplayer(user))
		return

	var/less_input_message
	if(SSlag_switch.measures[DISABLE_DEAD_KEYLOOP])
		less_input_message = " - Notice: Observer freelook is currently disabled."

	var/this_is_like_playing_right = tgui_alert(user, "Are you sure you wish to observe?[less_input_message]", "Observe", list("Yes", "No"))
	if(QDELETED(user) || !user.client || this_is_like_playing_right != "Yes" || !isnewplayer(user))
		return

	user.hide_title_screen()
	var/turf/spawn_point = get_observer_spawn_turf()
	var/mob/dead/observer/observer = new(spawn_point)
	observer.started_as_observer = TRUE

	to_chat(user, span_notice("Now teleporting."))
	if(!spawn_point)
		to_chat(user, span_notice("Teleporting failed. Ahelp an admin please"))
		stack_trace("There's no freaking observer landmark available on this map or you're making observers before the map is initialised")

	observer.PossessByPlayer(user.key)
	observer.client = user.client
	observer.set_ghost_appearance()

	if(observer.client && observer.client.prefs)
		observer.real_name = observer.client.prefs.read_preference(/datum/preference/name/real_name)
		observer.name = observer.real_name
		observer.client.init_verbs()
		observer.persistent_client.time_of_death = world.time

	observer.update_appearance()
	observer.stop_sound_channel(CHANNEL_LOBBYMUSIC)
	deadchat_broadcast(" has observed.", "<b>[observer.real_name]</b>", follow_target = observer, turf_target = get_turf(observer), message_type = DEADCHAT_DEATHRATTLE)
	QDEL_NULL(user.mind)
	qdel(user)
	return


/datum/controller/subsystem/rimworld_planetmap/proc/get_observer_spawn_turf()
	if(planet)
		for(var/datum/planet_cell/cell as anything in shuffle(assoc_to_values(planet.cells)))
			var/turf/center = cell?.is_loaded() && cell.reservation.get_center_turf()
			if(center)
				return center

	var/obj/effect/landmark/observer_start/landmark = locate() in GLOB.landmarks_list
	if(landmark)
		return get_turf(landmark)

	for(var/z_level in SSmapping.levels_by_trait(ZTRAIT_CENTCOM))
		var/turf/centcom_turf = locate(rand(1, world.maxx), rand(1, world.maxy), z_level)
		if(centcom_turf)
			return centcom_turf

	// Nothing generated yet; anywhere beats nullspace, the planet map can jump them later
	return locate(round(world.maxx * 0.5, 1), round(world.maxy * 0.5, 1), 1)

/datum/controller/subsystem/mapping/get_station_center()
	if(current_map?.rimworld_map && !length(levels_by_trait(ZTRAIT_STATION)))
		return SSrimworld_planetmap.get_observer_spawn_turf()
	return ..()

/mob/dead/observer/Initialize(mapload)
	var/atom/initial_loc = loc
	. = ..()
	if(!SSmapping.current_map?.rimworld_map || ismob(initial_loc))
		return
	// Parent drops non-body spawns at arrivals/station center, which doesn't exist here
	var/turf/target = get_turf(initial_loc) || SSrimworld_planetmap.get_observer_spawn_turf()
	if(target && get_turf(src) != target)
		abstract_move(target)

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
	z_level_to_plane_offset = list()
	z_level_to_lowest_plane_offset = list()
	z_level_to_stack = list()
	gravity_by_z_level = list()
	multiz_levels = list()
	InitializeDefaultZLevels()
	var/list/FailedZs = list()

	// LoadGroup(
	// 	FailedZs,
	// 	"CentCom",
	// 	"map_files/generic",
	// 	"CentCom_minimal.dmm",
	// 	traits = list(list(
	// 		ZTRAIT_CENTCOM = TRUE,
	// 		ZTRAIT_GRAVITY = 1,
	// 	)),
	// 	default_traits = list(
	// 		ZTRAIT_CENTCOM = TRUE,
	// 		ZTRAIT_GRAVITY = 1,
	// 	),
	// 	silent = FALSE,
	// 	height_autosetup = FALSE
	// )

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
	return ..()


/datum/controller/subsystem/ticker/check_finished()
	if(!setup_done)
		return FALSE
	if(SSmapping.current_map.rimworld_map)
		return force_ending != END_ROUND_AS_NORMAL
	return ..()


ADMIN_VERB(open_planet_map, R_ADMIN, "\[RW\] Open planet map", "Open the planetary admin map.", ADMIN_CATEGORY_EVENTS)
	SSrimworld_planetmap.open_admin_view(usr)

/atom/movable/screen/ghost/planet_map
	name = "Planet map"
	icon = 'icons/hud/implants.dmi'
	icon_state = "minimap"
	screen_loc = ui_ghost_spawners_menu

/atom/movable/screen/ghost/planet_map/Click(location, control, params)
	. = ..()
	var/mob/dead/observer/ghost = usr
	SSrimworld_planetmap.open_settlement_view(ghost, TRUE)

/datum/hud/ghost/initialize_screen_objects()
	add_screen_object(/atom/movable/screen/ghost/orbit, HUD_GHOST_ORBIT)
	add_screen_object(/atom/movable/screen/ghost/planet_map, "ghost_planetmap")
	add_screen_object(/atom/movable/screen/ghost/reenter_corpse, HUD_GHOST_REENTER_CORPSE)
	add_screen_object(/atom/movable/screen/ghost/teleport, HUD_GHOST_TELEPORT)
	add_screen_object(/atom/movable/screen/ghost/settings, HUD_GHOST_SETTINGS)
	add_screen_object(/atom/movable/screen/language_menu, HUD_MOB_LANGUAGE_MENU, HUD_GROUP_STATIC, ui_style, ui_ghost_language_menu)

	var/list/hudboxes = valid_subtypesof(/atom/movable/screen/ghost/hudbox)
	for(var/i in 1 to length(hudboxes))
		add_screen_object(hudboxes[i], HUD_KEY_GHOST_HUDBOX(i), ui_loc = position_hudbox(i - 1))
