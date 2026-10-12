/datum/storage
	/// Max total weight in kg this storage can hold. 0 = unlimited.
	var/max_total_weight = 0
	/// Max total rw_volume units this storage can hold. 0 = unlimited.
	var/max_total_volume = 0

/// Sum of weight_kg of all contained items (non-recursive)
/datum/storage/proc/get_total_weight_kg()
	. = 0
	var/atom/loc_resolved = real_location
	if(!loc_resolved)
		return
	for(var/obj/item/I in loc_resolved)
		. += I.weight_kg

/// Sum of rw_volume of all contained items (non-recursive)
/datum/storage/proc/get_total_volume()
	. = 0
	var/atom/loc_resolved = real_location
	if(!loc_resolved)
		return
	for(var/obj/item/I in loc_resolved)
		. += I.rw_volume

// Hook into the existing can_insert chain
// NOTE: /datum/storage/grid overrides get_total_* to use item_positions
// and does its own weight/volume checks; this base hook covers non-grid storage.
/datum/storage/can_insert(obj/item/to_insert, mob/user, messages = TRUE, force = STORAGE_NOT_LOCKED)
	. = ..()
	if(!.)
		return FALSE

	// Skip for grid — it has its own path that accounts for displacement
	if(istype(src, /datum/storage/grid))
		return TRUE

	if(max_total_weight > 0)
		if(get_total_weight_kg() + to_insert.weight_kg > max_total_weight)
			if(messages && user)
				to_chat(user, span_warning("[parent] is too heavy to hold more."))
			return FALSE

	if(max_total_volume > 0)
		if(get_total_volume() + to_insert.rw_volume > max_total_volume)
			if(messages && user)
				to_chat(user, span_warning("[parent] cannot hold more volume."))
			return FALSE

	return TRUE
