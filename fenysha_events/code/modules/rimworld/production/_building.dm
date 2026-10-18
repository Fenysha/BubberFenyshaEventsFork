/obj/building
	name = "building"
	desc = "A constructed object."
	icon = 'fenysha_events/icons/machinery/production/production48.dmi'
	anchored = TRUE
	density = FALSE
	layer = OBJ_LAYER

	/// Faction that owns this building (research / recipe access).
	var/datum/rw_faction/player/owner_faction

	/// Power demand in watts while idle. 0 = no electrical consumer.
	var/idle_power_draw = 0
	/// Power demand in watts while actively working.
	var/active_power_draw = 0
	/// Current draw mode.
	var/power_mode = POWER_USE_IDLE

	/// Cached electrical consumer component (null if unpowered type).
	var/datum/component/onet/consumer/electrical/power_comp

	/// If TRUE this machine consumes fuel instead of / in addition to power.
	var/fueled = FALSE
	/// Typepath of accepted fuel item (stack preferred).
	var/fuel_type
	/// Current fuel units remaining.
	var/fuel_amount = 0
	/// Maximum fuel that can be stored.
	var/fuel_capacity = 0
	/// Fuel consumed per production tick while active.
	var/fuel_per_tick = 0

	/// Range in tiles to look for attachments.
	var/attachment_range = 1
	/// Typepaths of attachments this building can benefit from.
	var/list/possible_attachments = list()

	/// Soft flags (broken, unpowered, unfueled …).
	var/building_stat = NONE

	/// Registered with SSproduction when it needs periodic work.
	var/processing = FALSE

/obj/building/Initialize(mapload)
	. = ..()
	if(idle_power_draw > 0 || active_power_draw > 0)
		setup_power()
	if(owner_faction)
		set_owner_faction(owner_faction)

/obj/building/Destroy()
	stop_processing()
	set_owner_faction(null)
	power_comp = null
	return ..()

/obj/building/proc/setup_power()
	if(power_comp)
		return
	var/demand = (power_mode == POWER_USE_ACTIVE) ? active_power_draw : idle_power_draw
	power_comp = AddComponent(/datum/component/onet/consumer/electrical, demand, ELECTRICAL_DEFAULT_RANGE, TRUE)
	RegisterSignal(src, COMSIG_OBJECT_NET_POWER_FLIP, PROC_REF(on_power_state_changed))

/obj/building/proc/set_power_mode(mode)
	if(power_mode == mode)
		return
	power_mode = mode
	if(!power_comp)
		return
	var/demand = (mode == POWER_USE_ACTIVE) ? active_power_draw : idle_power_draw
	power_comp.consume(demand)

/obj/building/proc/on_power_state_changed(datum/source, powered)
	SIGNAL_HANDLER
	if(powered)
		building_stat &= ~BUILDING_NOPOWER
	else
		building_stat |= BUILDING_NOPOWER
	update_appearance(UPDATE_ICON)

/obj/building/proc/is_powered()
	if(idle_power_draw <= 0 && active_power_draw <= 0)
		return TRUE
	return power_comp?.has_power()

/obj/building/proc/is_operational()
	return !QDELETED(src) && anchored && !(building_stat & (BUILDING_BROKEN | BUILDING_NOPOWER | BUILDING_NOFUEL))

/obj/building/proc/set_owner_faction(datum/rw_faction/player/new_faction)
	if(owner_faction?.techweb)
		owner_faction.techweb.benches -= src
	owner_faction = new_faction
	if(owner_faction?.techweb)
		owner_faction.techweb.benches |= src

/obj/building/proc/get_crafting_faction(mob/living/user)
	if(!istype(user))
		return null
	if(owner_faction)
		return owner_faction.is_member(user) ? owner_faction : null
	if(istype(user.rw_faction, /datum/rw_faction/player))
		return user.rw_faction
	return null

// ---------------------------------------------------------------------------
// Fuel
// ---------------------------------------------------------------------------

/obj/building/proc/needs_fuel()
	return fueled && fuel_type && fuel_capacity > 0

/obj/building/proc/has_fuel(amount = 1)
	if(!needs_fuel())
		return TRUE
	return fuel_amount >= amount

/obj/building/proc/consume_fuel(amount)
	if(!needs_fuel())
		return TRUE
	if(fuel_amount < amount)
		fuel_amount = 0
		building_stat |= BUILDING_NOFUEL
		return FALSE
	fuel_amount -= amount
	if(fuel_amount <= 0)
		building_stat |= BUILDING_NOFUEL
	return TRUE

/obj/building/proc/refuel(obj/item/I, mob/user)
	if(!needs_fuel() || !fuel_type || !istype(I, fuel_type))
		return FALSE
	var/space = fuel_capacity - fuel_amount
	if(space <= 0)
		if(user)
			balloon_alert(user, "tank full")
		return FALSE

	var/added = 0
	if(istype(I, /obj/item/stack))
		var/obj/item/stack/S = I
		added = min(S.amount, space)
		if(added <= 0 || !S.use(added))
			return FALSE
	else
		if(I.loc == user && !user.temporarilyRemoveItemFromInventory(I))
			return FALSE
		qdel(I)
		added = 1

	fuel_amount = min(fuel_capacity, fuel_amount + added)
	building_stat &= ~BUILDING_NOFUEL
	if(user)
		balloon_alert(user, "+[added] fuel ([fuel_amount]/[fuel_capacity])")
	update_appearance(UPDATE_ICON)
	return TRUE

/obj/building/attackby(obj/item/I, mob/living/user, params)
	if(needs_fuel() && istype(I, fuel_type))
		refuel(I, user)
		return TRUE
	return ..()

// ---------------------------------------------------------------------------
// Attachments
// ---------------------------------------------------------------------------

/obj/building/proc/get_nearby_attachments()
	var/list/found = list()
	for(var/obj/building/attachment/A in range(attachment_range, src))
		if(!A.is_functional())
			continue
		if(length(possible_attachments) && !is_type_in_list(A, possible_attachments))
			continue
		found += A
	return found

/// Multiplier applied to work time / research progress. 1.0 = baseline.
/obj/building/proc/get_speed_multiplier()
	var/mult = 1
	for(var/obj/building/attachment/A as anything in get_nearby_attachments())
		mult += A.speed_bonus
	return max(0.1, mult)

/obj/building/proc/check_skill(mob/living/user, skill_id, min_level, silent = FALSE)
	if(!skill_id || min_level <= 0)
		return TRUE
	if(rw_has_skill(user, skill_id, min_level))
		return TRUE
	if(!silent)
		balloon_alert(user, "needs [rw_get_skill_name(skill_id)] [min_level]")
	return FALSE

// ---------------------------------------------------------------------------
// Processing (SSproduction)
// ---------------------------------------------------------------------------

/obj/building/proc/start_processing()
	if(processing)
		return
	processing = TRUE
	SSproduction.register_building(src)

/obj/building/proc/stop_processing()
	if(!processing)
		return
	processing = FALSE
	SSproduction.unregister_building(src)

/// Called by SSproduction each fire. Override in subtypes that need ticks.
/obj/building/proc/process_building(seconds_per_tick)
	return

/// Convenience: start consuming active power + fuel and register for ticks.
/obj/building/proc/begin_work()
	set_power_mode(POWER_USE_ACTIVE)
	start_processing()

/obj/building/proc/end_work()
	set_power_mode(POWER_USE_IDLE)
	stop_processing()


// =============================================================================
// Production buildings (workbenches, research tables, powered machines)
// =============================================================================

/obj/building/production
	name = "production building"
	desc = "A workstation."

	var/can_do_crafting = FALSE
	/// Explicit recipe IDs this bench offers (overrides categories).
	var/list/recipe_ids = list()
	/// Recipe categories offered when recipe_ids is empty.
	var/list/recipe_categories = list()

/obj/building/production/proc/accepts_recipe(datum/rw_crafting_recipe/recipe)
	if(!can_do_crafting || !istype(recipe))
		return FALSE
	if(recipe.required_bench && !istype(src, recipe.required_bench))
		return FALSE
	if(length(recipe_ids))
		return recipe.id in recipe_ids
	if(length(recipe_categories))
		return recipe.category in recipe_categories
	return TRUE


// =============================================================================
// Attachments – sit next to production buildings and modify their speed
// =============================================================================

/obj/building/attachment
	name = "bench attachment"
	desc = "Equipment that improves nearby workstations."
	density = TRUE
	anchored = TRUE

	/// Added to get_speed_multiplier() of nearby production buildings.
	var/speed_bonus = 0
	/// Added to research multiplier (research benches).
	var/research_bonus = 0

/obj/building/attachment/proc/is_functional()
	return !QDELETED(src) && anchored && !(building_stat & BUILDING_BROKEN)

/obj/building/attachment/analyzer
	name = "multi-analyzer"
	desc = "A set of instruments that speeds up research."
	research_bonus = 0.5
	speed_bonus = 0.1

/obj/building/attachment/tool_rack
	name = "tool rack"
	desc = "Organized tools within arm's reach. Speeds up manual crafting."
	speed_bonus = 0.25

/obj/building/attachment/power_tool_dock
	name = "power tool dock"
	desc = "A powered tool station that markedly accelerates industrial work."
	idle_power_draw = 30
	active_power_draw = 80
	speed_bonus = 0.4
