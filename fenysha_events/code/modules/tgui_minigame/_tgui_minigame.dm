/**
 * Shows a fullscreen minigame over the user's map and sleeps until it closes, like tgui_alert().
 *
 * Arguments:
 * * user - who plays it
 * * game - a configured /datum/minigame. tgui_minigame owns it from here and deletes it.
 * * timeout - how long the whole thing may stay open, briefing included. 0 for no limit.
 *
 * Returns the /datum/minigame_result, or null if it couldn't be shown.
 */
/proc/tgui_minigame(mob/user, datum/minigame/game, timeout = 0)
	if(!istype(game))
		CRASH("tgui_minigame() called without a /datum/minigame")
	if(!user)
		user = usr
	if(!istype(user))
		if(istype(user, /client))
			var/client/client = user
			user = client.mob
		else
			qdel(game)
			return null
	if(isnull(user.client))
		qdel(game)
		return null
	game.start(user, timeout)
	game.wait()
	. = game.result
	qdel(game)

/datum/minigame_result
	/// One of the MINIGAME_* outcome defines
	var/outcome
	/// Validated score, in the minigame's own unit
	var/score = 0
	/// Seconds between starting play and the score being reported
	var/played_time = 0
	/// Validated game-specific numbers, see /datum/minigame/proc/validate_stats()
	var/list/stats = list()

/**
 * # minigame
 *
 * One fullscreen session: briefing, play, results. Subtypes set the interface and validate what
 * the client reports; callers fill in the header and briefing before handing it to tgui_minigame().
 */
/datum/minigame
	/// Title row text
	var/name = "Minigame"
	/// tgui interface that renders this game
	var/tgui_interface
	/// Optional atom the user has to stay next to, such as a workbench
	var/atom/movable/host
	/// Length of play; the client reports its score when it runs out. 0 for untimed.
	var/time_limit = 2 MINUTES
	/// Highest plausible score per second played, for validation
	var/max_score_rate = 30
	/// Header rows: list(list("label" = ..., "value" = ..., "chips" = list(list("text" = ..., "color" = "good"/"bad"))))
	var/list/context = list()
	/// Optional header bar the score feeds into: list("label", "title", "value", "max", "per_point", "abandon_ratio")
	var/list/progress
	/// Opening line of the briefing
	var/briefing_text
	/// Briefing rows, same shape as context
	var/list/briefing = list()
	/// Chips listed under the briefing as modifiers
	var/list/modifiers = list()
	/// Label of the decline button
	var/decline_text = "Not now"
	/// Line explaining what declining does
	var/decline_hint

	/// The player
	var/mob/user
	/// "briefing", "playing" or "results"
	var/phase = "briefing"
	/// world.time play began
	var/started_at
	var/datum/minigame_result/result
	/// Set once the session is over and the window gone
	var/closed = FALSE

/datum/minigame/New(atom/movable/host)
	src.host = host
	result = new

/datum/minigame/Destroy(force)
	stop_backdrop()
	SStgui.close_uis(src)
	host = null
	user = null
	return ..()

/datum/minigame/proc/start(mob/user, timeout)
	src.user = user
	if(timeout)
		addtimer(CALLBACK(src, PROC_REF(end), MINIGAME_INTERRUPTED), timeout)
	user.add_client_colour(/datum/client_colour/minigame_backdrop, REF(src))
	ui_interact(user)

/datum/minigame/proc/wait()
	while(!closed && !QDELETED(src))
		stoplag(1)

/// Finishes the session for good. An outcome already recorded wins over the one passed.
/datum/minigame/proc/end(outcome = MINIGAME_INTERRUPTED)
	if(closed)
		return
	if(!result.outcome)
		result.outcome = outcome
	closed = TRUE
	stop_backdrop()
	SStgui.close_uis(src)

/datum/minigame/proc/stop_backdrop()
	user?.remove_client_colour(REF(src))

/datum/minigame/proc/time_up()
	if(phase == "playing")
		end(MINIGAME_INTERRUPTED)

/// Stores what the client reported, clamped to what's possible in the time played
/datum/minigame/proc/record(score, list/stats)
	result.played_time = started_at ? (world.time - started_at) / (1 SECONDS) : 0
	result.score = validate_score(isnum(score) ? score : 0, result.played_time)
	result.stats = validate_stats(islist(stats) ? stats : list(), result.score)

/datum/minigame/proc/validate_score(score, played_time)
	return clamp(round(score), 0, round(max_score_rate * max(played_time, 1)))

/// Returns the game-specific stats worth keeping, sanitised. Override per game.
/datum/minigame/proc/validate_stats(list/stats, score)
	return list()

/// Extra static data for the game itself
/datum/minigame/proc/game_static_data()
	return list()

/datum/minigame/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new /datum/tgui/map_embedded/minigame(user, src, tgui_interface)
		ui.open()

/datum/minigame/ui_state(mob/user)
	return GLOB.always_state

/datum/minigame/ui_status(mob/user, datum/ui_state/state)
	if(closed || user != src.user || !user.client || user.stat >= HARD_CRIT)
		return UI_CLOSE
	var/mob/living/living_user = isliving(user) ? user : null
	if(living_user?.IsUnconscious())
		return UI_CLOSE
	if(isnull(host))
		return UI_INTERACTIVE
	if(QDELETED(host) || !living_user)
		return UI_CLOSE
	return living_user.shared_living_ui_distance(host) >= UI_UPDATE ? UI_INTERACTIVE : UI_CLOSE

/datum/minigame/ui_close(mob/user)
	. = ..()
	end(MINIGAME_INTERRUPTED)

/datum/minigame/ui_static_data(mob/user)
	return list(
		"name" = name,
		"time_limit" = time_limit / (1 SECONDS),
		"context" = context,
		"progress" = progress,
		"briefing_text" = briefing_text,
		"briefing" = briefing,
		"modifiers" = modifiers,
		"decline_text" = decline_text,
		"decline_hint" = decline_hint,
		"game" = game_static_data(),
	)

/datum/minigame/ui_data(mob/user)
	var/list/data = list("phase" = phase)
	if(phase == "results")
		data["result"] = list(
			"outcome" = result.outcome,
			"score" = result.score,
			"played_time" = result.played_time,
			"stats" = result.stats,
		)
	return data

/datum/minigame/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	switch(action)
		if("begin")
			if(phase != "briefing")
				return
			phase = "playing"
			started_at = world.time
			// The client reports at time_limit; this only catches a client that never does
			if(time_limit)
				addtimer(CALLBACK(src, PROC_REF(time_up)), time_limit + 10 SECONDS)
			return TRUE
		if("decline")
			if(phase != "briefing")
				return
			end(MINIGAME_DECLINED)
			return TRUE
		if("finish")
			if(phase != "playing")
				return
			record(params["score"], params["stats"])
			result.outcome = MINIGAME_COMPLETED
			phase = "results"
			return TRUE
		if("abandon")
			if(phase == "playing")
				record(params["score"], params["stats"])
				end(MINIGAME_ABANDONED)
			else if(phase == "briefing")
				end(MINIGAME_INTERRUPTED)
			else
				end(MINIGAME_COMPLETED)
			return TRUE
		if("close")
			if(phase != "results")
				return
			end(MINIGAME_COMPLETED)
			return TRUE
