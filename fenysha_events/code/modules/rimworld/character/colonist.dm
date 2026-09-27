/**
 * Marks the preference slot when this colonist dies in the current round.
 */
/datum/component/rw_colonist
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/owner_ckey
	var/slot

/datum/component/rw_colonist/Initialize(new_ckey, new_slot)
	if(!isliving(parent))
		return COMPONENT_INCOMPATIBLE
	owner_ckey = new_ckey
	slot = new_slot
	var/client/owner = GLOB.directory[owner_ckey]
	owner?.rw_prefs?.remember_spawned_body(parent, slot)

/datum/component/rw_colonist/RegisterWithParent()
	RegisterSignal(parent, COMSIG_LIVING_DEATH, PROC_REF(on_death))
	RegisterSignal(parent, COMSIG_MOB_STATCHANGE, PROC_REF(on_stat_change))

/datum/component/rw_colonist/UnregisterFromParent()
	UnregisterSignal(parent, list(COMSIG_LIVING_DEATH, COMSIG_MOB_STATCHANGE))

/datum/component/rw_colonist/proc/on_stat_change(datum/source, new_stat)
	SIGNAL_HANDLER
	if(new_stat == DEAD)
		on_death(source)

/datum/component/rw_colonist/proc/on_death(datum/source)
	SIGNAL_HANDLER
	if(!owner_ckey || !slot)
		return
	var/client/owner = GLOB.directory[owner_ckey]
	if(!owner?.rw_prefs)
		return
	owner.rw_prefs.remember_spawned_body(parent, slot)
	owner.rw_prefs.mark_slot_lost(slot)
