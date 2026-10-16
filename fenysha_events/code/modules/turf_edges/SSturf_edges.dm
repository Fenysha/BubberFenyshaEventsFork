/**
 * Queues and batch-processes open-turf edge overlays.
 * Mirrors SSicon_smooth: load jobs can suppress / defer work, then flush once
 * every neighbour exists.
 */
SUBSYSTEM_DEF(turf_edges)
	name = "Turf Edges"
	wait = 1
	priority = 40
	ss_flags = SS_BACKGROUND | SS_POST_FIRE_TIMING

	/// When FALSE, queue_edges() only stores turfs; fire() does nothing.
	var/edges_enabled = TRUE

	/// Turfs waiting for a rebuild. Values are TRUE (assoc set).
	var/list/queue = list()

	/// Mapload / cell-load sources that hold deferred work until released.
	/// source_key -> list(turf = TRUE)
	var/list/deferred_by_source = list()

	var/list/current_run = list()


/datum/controller/subsystem/turf_edges/stat_entry(msg)
	msg = "Q:[length(queue)] D:[length(deferred_by_source)] En:[edges_enabled]"
	return ..()


/datum/controller/subsystem/turf_edges/fire(resumed)
	if(!edges_enabled)
		return

	if(!resumed)
		current_run = queue.Copy()
		queue.Cut()

	while(length(current_run))
		var/turf/open/T = current_run[length(current_run)]
		current_run.len--

		if(QDELETED(T) || !istype(T))
			continue

		T.rebuild_edges()

		if(MC_TICK_CHECK)
			return


/// Enqueue a turf for edge rebuild. No-op when edges are globally disabled
/// and the caller did not pass a defer source (raw suppress during placement).
/datum/controller/subsystem/turf_edges/proc/queue_edges(turf/open/T, source = null)
	if(!istype(T))
		return

	if(source)
		var/list/bucket = deferred_by_source[source]
		if(!bucket)
			bucket = list()
			deferred_by_source[source] = bucket
		bucket[T] = TRUE
		return

	if(!edges_enabled)
		return

	queue[T] = TRUE


/// Drop every deferred entry for this source without rebuilding.
/datum/controller/subsystem/turf_edges/proc/discard_deferred(source)
	if(!source)
		return
	deferred_by_source -= source


/// Move deferred turfs into the live queue (or rebuild immediately when forced).
/datum/controller/subsystem/turf_edges/proc/release_deferred(source, force_immediate = FALSE)
	if(!source)
		return

	var/list/bucket = deferred_by_source[source]
	deferred_by_source -= source
	if(!bucket)
		return

	if(force_immediate)
		for(var/turf/open/T as anything in bucket)
			if(QDELETED(T) || !istype(T))
				continue
			T.rebuild_edges()
		return

	for(var/turf/open/T as anything in bucket)
		if(QDELETED(T) || !istype(T))
			continue
		queue[T] = TRUE


/// Soft disable: new queues are ignored until enable_edges().
/datum/controller/subsystem/turf_edges/proc/disable_edges()
	edges_enabled = FALSE


/datum/controller/subsystem/turf_edges/proc/enable_edges()
	edges_enabled = TRUE


/// Drain the live queue in a tight loop (used by the cell loader smooth pass).
/// Takes one batch off the queue per call (a single Cut) instead of Cut(1,2) per turf, which was O(n^2).
/// Returns TRUE when the queue is empty.
/datum/controller/subsystem/turf_edges/proc/process_budget(budget = 512)
	if(!edges_enabled)
		return TRUE

	var/total = length(queue)
	if(!total)
		return TRUE

	var/count = min(total, budget)
	var/list/batch = queue.Copy(1, count + 1)
	queue.Cut(1, count + 1)

	var/i = 0
	for(var/turf/open/T as anything in batch)
		i++
		if(!QDELETED(T) && istype(T))
			T.rebuild_edges()
		if(TICK_CHECK)
			// Hand the unprocessed rest back; order inside the set does not matter.
			for(var/j in (i + 1) to length(batch))
				var/turf/open/leftover = batch[j]
				if(leftover)
					queue[leftover] = TRUE
			break

	return !length(queue)


/// Remove a turf from every queue (Destroy / ChangeTurf safety).
/datum/controller/subsystem/turf_edges/proc/remove_from_queues(turf/open/T)
	if(!T)
		return
	queue -= T
	for(var/source in deferred_by_source)
		var/list/bucket = deferred_by_source[source]
		if(bucket)
			bucket -= T
