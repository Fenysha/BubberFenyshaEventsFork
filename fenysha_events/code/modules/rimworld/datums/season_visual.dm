/**
 * Tracks atoms that react to planetary season changes.
 * On Attach: registers host + optional update callback.
 * On COMSIG_RIMWORLD_PLANET_SEASON_CHANGED: invokes callback(host, hemisphere, old_season, new_season, quadrum, year)
 * for every still-valid host.
 *
 * Usage:
 *   AddElement(/datum/element/season_visual, CALLBACK(src, PROC_REF(update_season_visual)))
 */
/datum/element/season_visual
	element_flags = ELEMENT_BESPOKE | ELEMENT_DETACH_ON_HOST_DESTROY
	argument_hash_start_idx = 2

	/// host → datum/callback (update_season_visual)
	var/list/tracked = list()
	var/signals_registered = FALSE


/datum/element/season_visual/Attach(datum/target, datum/callback/update_cb)
	. = ..()
	if(!isatom(target))
		return ELEMENT_INCOMPATIBLE
	if(!update_cb)
		stack_trace("[type] requires a CALLBACK for season updates.")
		return ELEMENT_INCOMPATIBLE

	tracked[target] = update_cb
	ensure_global_signals()

	// Apply current season immediately if planet clock exists
	if(SSrimworld_planetmap)
		var/hemisphere = "north"
		if(isturf(target) || isobj(target))
			var/atom/A = target
			var/datum/planet_cell/cell = get_planet_cell(A)
			if(cell?.planet)
				var/lat = cell.planet.get_latitude(cell.x, cell.y)
				hemisphere = lat >= 0 ? "north" : "south"
		var/season = SSrimworld_planetmap.get_season_for_hemisphere(hemisphere)
		update_cb.Invoke(target, hemisphere, null, season, SSrimworld_planetmap.current_quadrum, SSrimworld_planetmap.current_year)


/datum/element/season_visual/Detach(datum/source, ...)
	tracked -= source
	. = ..()
	if(!length(tracked))
		unregister_global_signals()


/datum/element/season_visual/proc/ensure_global_signals()
	if(signals_registered || !SSrimworld_planetmap)
		return
	RegisterSignal(SSrimworld_planetmap, COMSIG_RIMWORLD_PLANET_SEASON_CHANGED, PROC_REF(on_season_changed))
	signals_registered = TRUE


/datum/element/season_visual/proc/unregister_global_signals()
	if(!signals_registered || !SSrimworld_planetmap)
		return
	UnregisterSignal(SSrimworld_planetmap, COMSIG_RIMWORLD_PLANET_SEASON_CHANGED)
	signals_registered = FALSE


/datum/element/season_visual/proc/on_season_changed(datum/source, hemisphere, old_season, new_season, quadrum, year)
	SIGNAL_HANDLER
	for(var/atom/host as anything in tracked)
		if(QDELETED(host))
			tracked -= host
			continue
		// Optional: only update hosts on matching hemisphere
		var/host_hemisphere = resolve_host_hemisphere(host)
		if(host_hemisphere && host_hemisphere != hemisphere)
			continue
		var/datum/callback/cb = tracked[host]
		cb?.Invoke(host, hemisphere, old_season, new_season, quadrum, year)


/datum/element/season_visual/proc/resolve_host_hemisphere(atom/host)
	var/datum/planet_cell/cell = get_planet_cell(host)
	if(!cell?.planet)
		return null
	var/lat = cell.planet.get_latitude(cell.x, cell.y)
	return lat >= 0 ? "north" : "south"
