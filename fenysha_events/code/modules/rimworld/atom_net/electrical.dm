#define ELECTRICAL_DEFAULT_RANGE     4
#define ELECTRICAL_BEAM_ICON         'icons/effects/beam.dmi'
#define ELECTRICAL_BEAM_STATE        "hosebeam"
#define ELECTRICAL_RECONNECT_DELAY   (5 SECONDS)

/datum/component/onet/producer/electrical
/datum/component/onet/producer/electrical/Initialize(output = 0)
	return ..(OBJECT_NET_POWER, output)

/datum/component/onet/store/electrical
/datum/component/onet/store/electrical/Initialize(capacity = 0, max_in = 0, max_out = 0, charge = 0)
	return ..(OBJECT_NET_POWER, capacity, max_in, max_out, charge)


/datum/component/onet/consumer/electrical
	var/atom/connected_atom
	var/datum/beam/beam
	var/disconnecting = FALSE
	var/draw_beam = TRUE

/datum/component/onet/consumer/electrical/Initialize(demand = 0, range = ELECTRICAL_DEFAULT_RANGE, draw_beam = TRUE)
	src.draw_beam = draw_beam
	return ..(OBJECT_NET_POWER, demand, range)

/datum/component/onet/consumer/electrical/RegisterWithParent()
	. = ..()
	RegisterSignal(parent, COMSIG_MOVABLE_MOVED, PROC_REF(on_parent_moved))

/datum/component/onet/consumer/electrical/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_MOVABLE_MOVED)
	. = ..()

/datum/component/onet/consumer/electrical/Destroy()
	connected_atom = null
	QDEL_NULL(beam)
	return ..()

/datum/component/onet/consumer/electrical/proc/reconnect()
	disconnect()
	next_try = 0
	SSobject_net.pending_connect[src] = TRUE
	try_connect()

/datum/component/onet/consumer/electrical/try_connect()
	var/turf/T = get_turf(parent)
	if(!T)
		return FALSE

	var/id = text2num(rustg_object_net_nearest(
		"[OBJECT_NET_POWER]",
		"[T.x],[T.y],[T.z],[range],[ONET_MASK_ATTACH]"
	))
	if(!id || !SSobject_net.node_atoms[id])
		return FALSE

	var/atom/target = SSobject_net.node_atoms[id]
	if(get_dist(parent, target) > range)
		return FALSE

	connected_node = id
	connected_atom = target

	var/list/L = SSobject_net.node_consumers[id]
	if(!L)
		L = SSobject_net.node_consumers[id] = list()
	L[src] = TRUE

	var/net_id = SSobject_net.node_net[id]
	if(net_id)
		set_net(SSobject_net.get_net(OBJECT_NET_POWER, net_id))
	else
		push_node_demand()

	if(draw_beam && ismovable(parent))
		var/atom/movable/AM = parent
		beam = AM.Beam(
			target,
			icon_state = ELECTRICAL_BEAM_STATE,
			icon = ELECTRICAL_BEAM_ICON,
			time = INFINITY,
			maxdistance = range,
			emissive = TRUE,
			animate = FALSE,
		)
		if(beam)
			RegisterSignal(beam, COMSIG_QDELETING, PROC_REF(on_beam_gone))

	return TRUE

/datum/component/onet/consumer/electrical/disconnect()
	if(disconnecting)
		return
	disconnecting = TRUE

	if(beam)
		UnregisterSignal(beam, COMSIG_QDELETING)
		QDEL_NULL(beam)

	if(connected_node)
		var/list/L = SSobject_net.node_consumers[connected_node]
		if(L)
			L -= src
			if(!length(L))
				SSobject_net.node_consumers[connected_node] = null

		var/old_node = connected_node
		connected_node = 0
		connected_atom = null

		var/total = 0
		if(L)
			for(var/datum/component/onet/consumer/C as anything in L)
				if(C.active)
					total += C.demand
		SSobject_net.power_set(old_node, POWER_SLOT_DEMAND, total)

	set_net(null)
	disconnecting = FALSE

/datum/component/onet/consumer/electrical/on_node_lost()
	if(beam)
		UnregisterSignal(beam, COMSIG_QDELETING)
		QDEL_NULL(beam)
	connected_node = 0
	connected_atom = null
	set_net(null)
	queue_reconnect()

/datum/component/onet/consumer/electrical/proc/on_beam_gone(datum/source)
	SIGNAL_HANDLER
	beam = null
	if(connected_node)
		disconnect()
	queue_reconnect()

/datum/component/onet/consumer/electrical/proc/on_parent_moved(atom/movable/source, atom/old_loc, dir, forced)
	SIGNAL_HANDLER
	if(!connected_atom)
		if(!SSobject_net.pending_connect[src])
			queue_reconnect()
		return
	if(QDELETED(connected_atom) || get_dist(parent, connected_atom) > range)
		disconnect()
		queue_reconnect()


// =============================================================================
// Map objects
// =============================================================================
/obj/structure/electrical_cable
	name = "power cable"
	desc = "A cable carrying power."
	icon = 'fenysha_events/icons/structures/pipes_n_cables/cable.dmi'
	icon_state = "cable-0"
	base_icon_state = "cable"
	anchored = TRUE
	smoothing_flags = SMOOTH_BITMASK | USES_SMOOTHING
	smoothing_groups = SMOOTH_GROUP_CABLE_ELECTRIC
	canSmoothWith = SMOOTH_GROUP_CABLE_ELECTRIC

/obj/structure/electrical_cable/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/onet/connector, OBJECT_NET_POWER)

/obj/structure/object_net_switch
	name = "power switch"
	desc = "Cuts the line when open."
	icon = 'fenysha_events/icons/structures/pipes_n_cables/cable.dmi'
	icon_state = "cable-0"
	base_icon_state = "cable"
	anchored = TRUE
	var/net_type = OBJECT_NET_POWER
	var/closed = TRUE

/obj/structure/object_net_switch/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/onet/switch, net_type, closed)

/obj/structure/object_net_switch/attack_hand(mob/user, list/modifiers)
	. = ..()
	var/datum/component/onet/switch/S = GetComponent(/datum/component/onet/switch)
	if(S)
		S.set_closed(!S.closed)
		to_chat(user, span_notice("You flip the switch [S.closed ? "closed" : "open"]."))
		update_appearance()
