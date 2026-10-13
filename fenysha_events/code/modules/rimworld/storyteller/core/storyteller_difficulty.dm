/// Difficulty presets. This list is the single source of truth: the vote UI is built from it
/// and the server validates every ballot against it. Keep it sorted by value, ascending.
GLOBAL_LIST_INIT(storyteller_difficulty_levels, list(
	list(
		"value" = 0.3,
		"label" = "Extended",
		"tooltip" = "Peaceful mode - minimal threats, more positive events",
		"min_players" = 0,
	),
	list(
		"value" = 0.7,
		"label" = "Adventure story",
		"tooltip" = "Easy mode - moderate events, balance between good and bad",
		"min_players" = 0,
	),
	list(
		"value" = 1.0,
		"label" = "Strive to survive",
		"tooltip" = "Standard mode - balanced events and threats",
		"min_players" = 15,
	),
	list(
		"value" = 2.0,
		"label" = "Blood and dust",
		"tooltip" = "Hard mode - frequent threats and event escalation. Recommended for experienced players who want to struggle to survive.",
		"min_players" = 30,
	),
	list(
		"value" = 5.0,
		"label" = "Losing is Fun",
		"tooltip" = "Extreme mode - maximum difficulty and constant threats. For lovers of tragedy and digital masochists.",
		"min_players" = 50,
	),
))

/// Returns the preset entry whose value is closest to the given number.
/proc/storyteller_snap_level(value)
	var/list/best
	var/best_delta = INFINITY
	for(var/list/level as anything in GLOB.storyteller_difficulty_levels)
		var/delta = abs(level["value"] - value)
		if(delta < best_delta)
			best_delta = delta
			best = level
	return best

/// Closest preset value to the given number.
/proc/storyteller_snap_difficulty(value)
	var/list/level = storyteller_snap_level(value)
	return level ? level["value"] : STORYTELLER_DEFAULT_DIFFICULTY
