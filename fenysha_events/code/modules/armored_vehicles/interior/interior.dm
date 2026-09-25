#define INTERIOR_BUFFER_TILES 1

/// The inside of a vehicle: a map template loaded into reserved space that follows its container
/datum/interior
	var/datum/map_template/interior/template = /datum/map_template/interior
	var/atom/movable/container
	/// Invoked with (mob, interior, teleport) when a mob leaves
	var/datum/callback/exit_callback
	var/list/mob/occupants = list()
	var/datum/turf_reservation/reservation
	var/list/turf/loaded_turfs = list()
	var/area/this_area

/datum/interior/New(atom/movable/container, datum/callback/exit_callback)
	. = ..()
	src.container = container
	src.exit_callback = exit_callback
	ADD_TRAIT(container, TRAIT_HAS_INTERIOR, REF(src))
	RegisterSignal(container, COMSIG_QDELETING, PROC_REF(handle_container_del))
	INVOKE_ASYNC(src, PROC_REF(init_map))

/datum/interior/proc/init_map()
	var/datum/map_template/map = new template
	reservation = SSmapping.request_turf_block_reservation(map.width + INTERIOR_BUFFER_TILES * 2, map.height + INTERIOR_BUFFER_TILES * 2)
	if(!reservation)
		CRASH("Could not reserve space for [type]")
	var/turf/corner = reservation.bottom_left_turfs[1]
	var/turf/load_loc = locate(corner.x + INTERIOR_BUFFER_TILES, corner.y + INTERIOR_BUFFER_TILES, corner.z)
	var/list/bounds = map.load(load_loc)
	if(!bounds)
		CRASH("Failed to load [map.mappath] for [type]")
	if(QDELETED(src))
		return
	this_area = load_loc.loc
	loaded_turfs = block(
		bounds[MAP_MINX], bounds[MAP_MINY], bounds[MAP_MINZ],
		bounds[MAP_MAXX], bounds[MAP_MAXY], bounds[MAP_MAXZ],
	)
	connect_atoms()
	on_loaded()

/datum/interior/proc/on_loaded()
	return

/datum/interior/Destroy(force)
	eject_all()
	REMOVE_TRAIT(container, TRAIT_HAS_INTERIOR, REF(src))
	exit_callback = null
	this_area = null
	loaded_turfs = null
	QDEL_NULL(reservation)
	container = null
	return ..()

/datum/interior/proc/connect_atoms()
	for(var/turf/tile as anything in loaded_turfs)
		tile.link_interior(src)
		for(var/atom/subject as anything in tile.get_all_contents())
			if(subject != tile)
				subject.link_interior(src)
		CHECK_TICK

/datum/interior/proc/contains_turf(turf/checked)
	return checked in loaded_turfs

/// Throws everyone inside out of the vehicle
/datum/interior/proc/eject_all()
	for(var/mob/occupant as anything in occupants.Copy())
		mob_leave(occupant)
	for(var/turf/tile as anything in loaded_turfs)
		for(var/mob/living/stowaway in tile)
			exit_callback?.Invoke(stowaway, src, TRUE)

/// Registers a mob as inside; subtypes are responsible for moving it
/datum/interior/proc/mob_enter(mob/enterer)
	if(enterer in occupants)
		return
	RegisterSignal(enterer, COMSIG_QDELETING, PROC_REF(handle_occupant_del))
	RegisterSignal(enterer, COMSIG_MOVABLE_EXITED_AREA, PROC_REF(handle_area_leave))
	occupants += enterer

/datum/interior/proc/mob_leave(mob/leaver, teleport = TRUE)
	UnregisterSignal(leaver, list(COMSIG_QDELETING, COMSIG_MOVABLE_EXITED_AREA))
	occupants -= leaver
	exit_callback?.Invoke(leaver, src, teleport)

/datum/interior/proc/handle_occupant_del(mob/source)
	SIGNAL_HANDLER
	mob_leave(source, FALSE)

/datum/interior/proc/handle_container_del(atom/source)
	SIGNAL_HANDLER
	qdel(src)

/datum/interior/proc/handle_area_leave(mob/source, area/old_area, direction)
	SIGNAL_HANDLER
	if(get_area(source) != this_area)
		mob_leave(source, FALSE)

/// Generic linkage for atoms loaded as part of an interior
/atom/proc/link_interior(datum/interior/link)
	return

#undef INTERIOR_BUFFER_TILES

/datum/interior/armored
	template = /datum/map_template/interior/medium_tank
	/// Which way the vehicle's front points on the interior map
	var/forward_dir = EAST
	var/obj/structure/gun_breech/breech
	var/obj/structure/gun_breech/secondary_breech
	var/turf/closed/interior/tank/door/door

/datum/interior/armored/Destroy(force)
	breech = null
	secondary_breech = null
	door = null
	return ..()

/datum/interior/armored/on_loaded()
	var/obj/vehicle/sealed/armored/vehicle = container
	vehicle.on_interior_loaded(door || loaded_turfs[1])

/datum/interior/armored/mob_enter(mob/enterer)
	if(door)
		enterer.forceMove(door.get_enter_location())
		enterer.setDir(door.enter_dir)
	else
		stack_trace("[enterer.type] could not find a door when entering an interior")
		enterer.forceMove(pick(loaded_turfs))
	return ..()

/datum/interior/armored/transport
	template = /datum/map_template/interior/transport

/datum/interior/armored/medical
	template = /datum/map_template/interior/medical

/datum/interior/armored/mrap
	template = /datum/map_template/interior/mrap

/datum/interior/armored/som
	template = /datum/map_template/interior/som_tank
	forward_dir = NORTH

/datum/interior/armored/icc_lvrt
	template = /datum/map_template/interior/icc_recontank

/datum/map_template/interior
	name = "Base Interior Template"
	var/prefix = "_maps/modular_events/armored_interiors/"
	/// Map file name without the extension
	var/filename

/datum/map_template/interior/New(path, rename, cache)
	if(filename)
		mappath = "[prefix][filename].dmm"
	return ..()

/datum/map_template/interior/medium_tank
	name = "tank interior"
	filename = "tank"

/datum/map_template/interior/transport
	name = "transport APC interior"
	filename = "apc_transport"

/datum/map_template/interior/medical
	name = "medical APC interior"
	filename = "apc_medical"

/datum/map_template/interior/mrap
	name = "MRAP interior"
	filename = "mrap"

/datum/map_template/interior/som_tank
	name = "SOM tank interior"
	filename = "som_tank"

/datum/map_template/interior/icc_recontank
	name = "ICC recon vehicle interior"
	filename = "icc_recontank"
