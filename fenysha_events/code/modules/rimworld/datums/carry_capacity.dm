/datum/component/carry_capacity
	dupe_mode = COMPONENT_DUPE_UNIQUE

	var/max_weight = DEFAULT_MAX_CARRY_WEIGHT
	var/max_volume = DEFAULT_MAX_CARRY_VOLUME

	var/current_weight = 0
	var/current_volume = 0

	/// Cached slowdown modifier we applied
	var/applied_slowdown = 0

/datum/component/carry_capacity/Initialize(max_weight = DEFAULT_MAX_CARRY_WEIGHT, max_volume = DEFAULT_MAX_CARRY_VOLUME)
	if(!isliving(parent))
		return COMPONENT_INCOMPATIBLE
	src.max_weight = max_weight
	src.max_volume = max_volume
	recalculate()

/datum/component/carry_capacity/RegisterWithParent()
	RegisterSignal(parent, COMSIG_MOB_EQUIPPED_ITEM, PROC_REF(on_equip))
	RegisterSignal(parent, COMSIG_MOB_UNEQUIPPED_ITEM, PROC_REF(on_unequip))
	// Also listen to storage changes if the mob has open storages
	RegisterSignal(parent, COMSIG_ATOM_ENTERED, PROC_REF(on_atom_entered)) // coarse, but works for hands etc.

/datum/component/carry_capacity/UnregisterFromParent()
	UnregisterSignal(parent, list(
		COMSIG_MOB_EQUIPPED_ITEM,
		COMSIG_MOB_UNEQUIPPED_ITEM,
		COMSIG_ATOM_ENTERED,
	))
	remove_slowdown()

/datum/component/carry_capacity/proc/on_equip(datum/source, obj/item/item, slot)
	SIGNAL_HANDLER
	recalculate()

/datum/component/carry_capacity/proc/on_unequip(datum/source, obj/item/item, slot)
	SIGNAL_HANDLER
	recalculate()

/datum/component/carry_capacity/proc/on_atom_entered(datum/source, atom/movable/arrived)
	SIGNAL_HANDLER
	if(isitem(arrived))
		recalculate()

/datum/component/carry_capacity/proc/recalculate()
	var/mob/living/L = parent
	current_weight = 0
	current_volume = 0

	// Hands
	for(var/obj/item/I in L.held_items)
		if(I)
			add_item_recursive(I)

	// Equipped slots (including the three ALWAYS slots later)
	if(iscarbon(L))
		var/mob/living/carbon/C = L
		for(var/obj/item/I in C.get_all_contents_type(/obj/item)) // depends on your inventory_slot system
			current_weight += I.weight_kg
			current_volume += I.rw_volume
	update_slowdown()

/datum/component/carry_capacity/proc/add_item_recursive(obj/item/I)
	current_weight += I.weight_kg
	current_volume += I.rw_volume
	// Contents of storages
	if(I.atom_storage)
		for(var/obj/item/nested in I.atom_storage.return_inv(recursive = TRUE))
			current_weight += nested.weight_kg
			current_volume += nested.rw_volume

/datum/component/carry_capacity/proc/update_slowdown()
	var/mob/living/L = parent
	var/new_slow = 0
	if(current_weight > max_weight)
		// Simple linear slowdown for now — you will expand this
		var/over = current_weight - max_weight
		new_slow = min(over * 0.15, 3) // clamp so it doesn't become unusable immediately

	if(new_slow == applied_slowdown)
		return

	remove_slowdown()
	if(new_slow > 0)
		L.add_movespeed_modifier(/datum/movespeed_modifier/carry_overload, update = TRUE)
		// If your movespeed_modifier system supports variable values, set it here
		applied_slowdown = new_slow

/datum/component/carry_capacity/proc/remove_slowdown()
	if(applied_slowdown <= 0)
		return
	var/mob/living/L = parent
	L.remove_movespeed_modifier(/datum/movespeed_modifier/carry_overload)
	applied_slowdown = 0

/// Placeholder movespeed modifier — define properly in your movespeed system
/datum/movespeed_modifier/carry_overload
	multiplicative_slowdown = 0.4
	id = "carry_overload"
