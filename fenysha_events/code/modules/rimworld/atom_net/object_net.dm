SUBSYSTEM_DEF(object_net)
	name = "ObjectNet"
	wait = 1 SECONDS
	ss_flags = SS_KEEP_TIMING | SS_BACKGROUND
	runlevels = RUNLEVEL_GAME

	/// net_type -> list of pending ops strings
	var/list/pending_ops = list()
	var/next_node_id = 0
	var/list/free_ids = list()

	// Indexed by node id
	var/list/node_net       = list() // net id from Rust
	var/list/node_atoms     = list() // atom
	var/list/node_owners    = list() // /datum/component/onet
	var/list/node_type      = list() // OBJECT_NET_*
	var/list/node_consumers = list() // list of /datum/component/onet/consumer

	/// "net_type:net_id" -> /datum/object_net
	var/list/nets = list()
	var/list/processing_nets = list()
	var/list/pending_connect = list()

	var/last_tick = 0

/datum/controller/subsystem/object_net/Initialize()
	rustg_object_net_reset("[OBJECT_NET_POWER]")
	last_tick = world.time
	return SS_INIT_SUCCESS

/datum/controller/subsystem/object_net/stat_entry(msg)
	return ..("nets:[length(nets)] active:[length(processing_nets)] wait:[length(pending_connect)]")

/datum/controller/subsystem/object_net/fire(resumed)
	var/dt = max((world.time - last_tick) * 0.1, 0.1)
	last_tick = world.time

	flush_ops()
	process_pending_connects()

	var/result = rustg_power_net_tick("[dt]")
	if(length(result))
		apply_power_tick_result(result)

/datum/controller/subsystem/object_net/proc/apply_power_tick_result(result)
	for(var/entry in splittext(result, "|"))
		var/sep = findtext(entry, ">")
		if(!sep)
			continue
		var/net_id = text2num(copytext(entry, 1, sep))
		var/payload = copytext(entry, sep + 1)
		var/list/parts = splittext(payload, ",")
		if(length(parts) < 5)
			continue
		var/datum/object_net/net = get_net(OBJECT_NET_POWER, net_id)
		if(!net)
			continue
		var/old_powered = net.powered
		net.ratio   = text2num(parts[1])
		net.powered = text2num(parts[2])
		net.supply  = text2num(parts[3])
		net.demand  = text2num(parts[4])
		net.stored  = text2num(parts[5])
		if(net.powered != old_powered)
			net.notify_power_flip()

/datum/controller/subsystem/object_net/proc/get_net(net_type, net_id)
	var/key = "[net_type]:[net_id]"
	var/datum/object_net/net = nets[key]
	if(!net)
		net = new
		net.net_type = net_type
		net.id = net_id
		nets[key] = net
	return net

/datum/controller/subsystem/object_net/proc/register_node(atom/source, net_type, kind, datum/owner)
	var/id
	if(length(free_ids))
		id = free_ids[length(free_ids)]
		free_ids.len--
	else
		id = ++next_node_id
		if(length(node_net) < id)
			node_net.len = id
			node_atoms.len = id
			node_owners.len = id
			node_type.len = id
			node_consumers.len = id

	var/turf/T = get_turf(source)
	node_atoms[id]  = source
	node_owners[id] = owner
	node_type[id]   = net_type

	var/list/ops = pending_ops["[net_type]"]
	if(!ops)
		ops = pending_ops["[net_type]"] = list()
	ops += "a,[id],[kind],[T.x],[T.y],[T.z]"
	return id

/datum/controller/subsystem/object_net/proc/unregister_node(id)
	if(!id)
		return
	var/nt = node_type[id]
	var/list/ops = pending_ops["[nt]"]
	if(!ops)
		ops = pending_ops["[nt]"] = list()
	ops += "r,[id]"

	var/list/consumers = node_consumers[id]
	if(consumers)
		for(var/datum/component/onet/consumer/C as anything in consumers.Copy())
			C.on_node_lost()
	node_consumers[id] = null
	node_net[id] = null
	node_atoms[id] = null
	node_owners[id] = null
	node_type[id] = null
	free_ids += id

/datum/controller/subsystem/object_net/proc/flush_ops()
	for(var/nt_key in pending_ops)
		var/list/ops = pending_ops[nt_key]
		if(!length(ops))
			continue
		var/result = rustg_object_net_apply(nt_key, ops.Join("|"))
		ops.Cut()
		if(!length(result))
			continue
		for(var/entry in splittext(result, "|"))
			var/sep = findtext(entry, ">")
			if(!sep)
				continue
			var/id = text2num(copytext(entry, 1, sep))
			var/net_id = text2num(copytext(entry, sep + 1))
			if(id > length(node_net) || !node_atoms[id])
				continue
			node_net[id] = net_id
			var/nt = node_type[id]
			var/datum/object_net/net = get_net(nt, net_id)
			var/datum/component/onet/owner = node_owners[id]
			if(owner)
				owner.set_net(net)
			var/list/consumers = node_consumers[id]
			if(consumers)
				for(var/datum/component/onet/consumer/C as anything in consumers)
					C.set_net(net)

/datum/controller/subsystem/object_net/proc/process_pending_connects()
	if(!length(pending_connect))
		return
	for(var/datum/component/onet/consumer/C as anything in pending_connect.Copy())
		if(QDELETED(C) || C.connected_node)
			pending_connect -= C
			continue
		if(world.time < C.next_try)
			continue
		if(C.try_connect())
			pending_connect -= C
		else
			C.next_try = world.time + ONET_RECONNECT_DELAY
		CHECK_TICK

/datum/controller/subsystem/object_net/proc/power_set(id, slot, value)
	rustg_power_net_set("[id],[slot],[value]")


// -----------------------------------------------------------------------------
// Network datum
// -----------------------------------------------------------------------------
/datum/object_net
	var/net_type = 0
	var/id = 0
	var/members = 0
	var/supply = 0
	var/demand = 0
	var/ratio = 0
	var/powered = FALSE
	var/stored = 0
	var/list/consumers = list() // consumer -> TRUE (for flip notify)

/datum/object_net/Destroy()
	SSobject_net.nets -= "[net_type]:[id]"
	SSobject_net.processing_nets -= src
	consumers = null
	return ..()

/datum/object_net/proc/check_empty()
	if(members <= 0)
		qdel(src)

/datum/object_net/proc/notify_power_flip()
	for(var/datum/component/onet/consumer/C as anything in consumers)
		C.update_power_state()


// -----------------------------------------------------------------------------
// Base component
// -----------------------------------------------------------------------------
/datum/component/onet
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/datum/object_net/net
	var/node_id = 0
	var/net_type = OBJECT_NET_POWER
	var/kind = ONET_KIND_CONNECTOR

/datum/component/onet/Destroy()
	set_net(null)
	return ..()

/datum/component/onet/proc/set_net(datum/object_net/new_net)
	if(net == new_net)
		return
	var/datum/object_net/old = net
	net = null
	if(old)
		leave_net(old)
		old.members--
		old.check_empty()
	net = new_net
	if(net)
		net.members++
		join_net(net)

/datum/component/onet/proc/join_net(datum/object_net/N)
	return

/datum/component/onet/proc/leave_net(datum/object_net/N)
	return


// -----------------------------------------------------------------------------
// Connector (cables, junctions …)
// -----------------------------------------------------------------------------
/datum/component/onet/connector
	kind = ONET_KIND_CONNECTOR

/datum/component/onet/connector/Initialize(net_type = OBJECT_NET_POWER)
	if(!isatom(parent))
		return COMPONENT_INCOMPATIBLE
	src.net_type = net_type

/datum/component/onet/connector/RegisterWithParent()
	node_id = SSobject_net.register_node(parent, net_type, kind, src)

/datum/component/onet/connector/UnregisterFromParent()
	SSobject_net.unregister_node(node_id)
	node_id = 0
	set_net(null)


// -----------------------------------------------------------------------------
// Producer
// -----------------------------------------------------------------------------
/datum/component/onet/producer
	kind = ONET_KIND_PRODUCER
	var/output = 0 // W

/datum/component/onet/producer/Initialize(net_type = OBJECT_NET_POWER, output = 0)
	if(!isatom(parent))
		return COMPONENT_INCOMPATIBLE
	src.net_type = net_type
	src.output = output

/datum/component/onet/producer/RegisterWithParent()
	node_id = SSobject_net.register_node(parent, net_type, kind, src)
	if(net_type == OBJECT_NET_POWER)
		SSobject_net.power_set(node_id, POWER_SLOT_SUPPLY, output)

/datum/component/onet/producer/UnregisterFromParent()
	SSobject_net.unregister_node(node_id)
	node_id = 0
	set_net(null)

/datum/component/onet/producer/proc/give_power(watts)
	watts = max(watts, 0)
	if(output == watts)
		return
	output = watts
	if(node_id && net_type == OBJECT_NET_POWER)
		SSobject_net.power_set(node_id, POWER_SLOT_SUPPLY, output)

/datum/component/onet/producer/proc/add_power(delta)
	give_power(output + delta)

/datum/component/onet/producer/proc/get_power()
	return output

/datum/component/onet/producer/proc/is_connected()
	return !!net


// -----------------------------------------------------------------------------
// Store (battery / capacitor)
// -----------------------------------------------------------------------------
/datum/component/onet/store
	kind = ONET_KIND_STORE
	var/capacity = 0
	var/charge = 0
	var/max_in = 0
	var/max_out = 0

/datum/component/onet/store/Initialize(net_type = OBJECT_NET_POWER, capacity = 0, max_in = 0, max_out = 0, charge = 0)
	if(!isatom(parent))
		return COMPONENT_INCOMPATIBLE
	src.net_type = net_type
	src.capacity = capacity
	src.max_in = max_in
	src.max_out = max_out
	src.charge = charge

/datum/component/onet/store/RegisterWithParent()
	node_id = SSobject_net.register_node(parent, net_type, kind, src)
	if(net_type == OBJECT_NET_POWER)
		SSobject_net.power_set(node_id, POWER_SLOT_CAPACITY, capacity)
		SSobject_net.power_set(node_id, POWER_SLOT_CHARGE, charge)
		SSobject_net.power_set(node_id, POWER_SLOT_MAX_IN, max_in)
		SSobject_net.power_set(node_id, POWER_SLOT_MAX_OUT, max_out)

/datum/component/onet/store/UnregisterFromParent()
	SSobject_net.unregister_node(node_id)
	node_id = 0
	set_net(null)

/datum/component/onet/store/proc/get_charge()
	return charge

/datum/component/onet/store/proc/get_capacity()
	return capacity

/datum/component/onet/store/proc/get_fill_ratio()
	return capacity > 0 ? clamp(charge / capacity, 0, 1) : 0

/datum/component/onet/store/proc/set_charge(joules)
	charge = clamp(joules, 0, capacity)
	if(node_id && net_type == OBJECT_NET_POWER)
		SSobject_net.power_set(node_id, POWER_SLOT_CHARGE, charge)

/datum/component/onet/store/proc/is_connected()
	return !!net


/datum/component/onet/consumer
	dupe_mode = COMPONENT_DUPE_UNIQUE

	var/demand = 0
	var/active = TRUE
	var/range = ONET_DEFAULT_RANGE
	var/connected_node = 0
	var/next_try = 0
	var/last_powered = FALSE

/datum/component/onet/consumer/Initialize(net_type = OBJECT_NET_POWER, demand = 0, range = ONET_DEFAULT_RANGE)
	if(!isatom(parent))
		return COMPONENT_INCOMPATIBLE
	src.net_type = net_type
	src.demand = demand
	src.range = range

/datum/component/onet/consumer/RegisterWithParent()
	SSobject_net.pending_connect[src] = TRUE

/datum/component/onet/consumer/UnregisterFromParent()
	SSobject_net.pending_connect -= src
	disconnect()

/datum/component/onet/consumer/set_net(datum/object_net/new_net)
	if(net == new_net)
		return
	if(net)
		net.consumers -= src
	net = new_net
	if(net)
		net.consumers[src] = TRUE
	push_node_demand()
	last_powered = has_power()

// Parent-facing API
/datum/component/onet/consumer/proc/has_power()
	return net && net.powered

/datum/component/onet/consumer/proc/get_satisfaction()
	return net ? net.ratio : 0

/datum/component/onet/consumer/proc/consume(watts)
	watts = max(watts, 0)
	if(demand == watts)
		return
	demand = watts
	push_node_demand()

/datum/component/onet/consumer/proc/add_consume(delta)
	consume(demand + delta)

/datum/component/onet/consumer/proc/get_consume()
	return demand

/datum/component/onet/consumer/proc/set_powered(on)
	on = !!on
	if(on == active)
		return
	active = on
	push_node_demand()

/datum/component/onet/consumer/proc/is_active()
	return active

/datum/component/onet/consumer/proc/is_connected()
	return !!connected_node

// Internal
/datum/component/onet/consumer/proc/push_node_demand()
	if(!connected_node || net_type != OBJECT_NET_POWER)
		return
	var/total = 0
	var/list/L = SSobject_net.node_consumers[connected_node]
	if(L)
		for(var/datum/component/onet/consumer/C as anything in L)
			if(C.active)
				total += C.demand
	SSobject_net.power_set(connected_node, POWER_SLOT_DEMAND, total)

/datum/component/onet/consumer/proc/update_power_state()
	var/now = has_power()
	if(now == last_powered)
		return
	last_powered = now
	if(parent)
		SEND_SIGNAL(src, COMSIG_OBJECT_NET_POWER_FLIP, now)
		SEND_SIGNAL(parent, COMSIG_OBJECT_NET_POWER_FLIP, now)

/datum/component/onet/consumer/proc/set_demand(watts)
	consume(watts)

/// Base implementation – no visual beam.
/datum/component/onet/consumer/proc/try_connect()
	var/turf/T = get_turf(parent)
	if(!T)
		return FALSE

	var/id = text2num(rustg_object_net_nearest(
		"[net_type]",
		"[T.x],[T.y],[T.z],[range],[ONET_MASK_ATTACH]"
	))
	if(!id || !SSobject_net.node_atoms[id])
		return FALSE

	connected_node = id
	var/list/L = SSobject_net.node_consumers[id]
	if(!L)
		L = SSobject_net.node_consumers[id] = list()
	L[src] = TRUE

	var/net_id = SSobject_net.node_net[id]
	if(net_id)
		set_net(SSobject_net.get_net(net_type, net_id))
	else
		push_node_demand()
	return TRUE

/datum/component/onet/consumer/proc/disconnect()
	if(!connected_node)
		return

	var/list/L = SSobject_net.node_consumers[connected_node]
	if(L)
		L -= src
		if(!length(L))
			SSobject_net.node_consumers[connected_node] = null

	var/old_node = connected_node
	connected_node = 0

	if(net_type == OBJECT_NET_POWER)
		var/total = 0
		if(L)
			for(var/datum/component/onet/consumer/C as anything in L)
				if(C.active)
					total += C.demand
		SSobject_net.power_set(old_node, POWER_SLOT_DEMAND, total)

	set_net(null)

/datum/component/onet/consumer/proc/on_node_lost()
	connected_node = 0
	set_net(null)
	next_try = world.time + ONET_RECONNECT_DELAY
	SSobject_net.pending_connect[src] = TRUE

/datum/component/onet/consumer/proc/queue_reconnect()
	next_try = world.time + ONET_RECONNECT_DELAY
	SSobject_net.pending_connect[src] = TRUE


// -----------------------------------------------------------------------------
// Switch
// -----------------------------------------------------------------------------
/datum/component/onet/switch
	kind = ONET_KIND_SWITCH
	var/closed = TRUE

/datum/component/onet/switch/Initialize(net_type = OBJECT_NET_POWER, closed = TRUE)
	if(!isatom(parent))
		return COMPONENT_INCOMPATIBLE
	src.net_type = net_type
	src.closed = closed

/datum/component/onet/switch/RegisterWithParent()
	if(closed)
		node_id = SSobject_net.register_node(parent, net_type, kind, src)

/datum/component/onet/switch/UnregisterFromParent()
	SSobject_net.unregister_node(node_id)
	node_id = 0
	set_net(null)

/datum/component/onet/switch/proc/set_closed(new_state)
	new_state = !!new_state
	if(new_state == closed)
		return
	closed = new_state
	if(closed)
		node_id = SSobject_net.register_node(parent, net_type, kind, src)
	else
		SSobject_net.unregister_node(node_id)
		node_id = 0
		set_net(null)
