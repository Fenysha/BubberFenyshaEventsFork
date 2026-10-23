/// Slide-and-fuse notebook: matching findings merge into the next tier, Breakthroughs cash in.
/datum/minigame/synthesis
	name = "Insight Synthesis"
	tgui_interface = "MinigameSynthesis"
	time_limit = 0
	max_score_rate = 30
	briefing_text = "Fuse matching findings into deeper understanding before the session ends."
	briefing = list(
		list("label" = "Goal", "value" = "Combine notes together, same tier notes fuse into the next tier, and each breakthrough advances your understanding."),
		list("label" = "Clarity", "value" = "Moves that do nothing drain your clarity, low clarity reduces your payout and spawns Doubt tiles, which a combine next to them dissolves"),
		list("label" = "Session", "value" = "Until the notebook is full, or finish early whenever you like. You always keep everything you earned, even if you don't fill it."),
	)
	/// Observation tiles placed at the start
	var/head_start = 0

/// Skilled researchers start with a few findings already on the page
/datum/minigame/synthesis/proc/apply_skill(skill_name, level, ideal)
	head_start = clamp(round((level - ideal) / 3), 0, 2)
	if(head_start)
		modifiers += list(list("text" = "[skill_name] [level]: +[head_start] starting Observation", "color" = "good"))
	else if(level < ideal)
		modifiers += list(list("text" = "[skill_name] [level]: below ideal [ideal]", "color" = "bad"))

/datum/minigame/synthesis/game_static_data()
	return list("head_start" = head_start)

/datum/minigame/synthesis/validate_stats(list/stats, score)
	var/merges = isnum(stats["merges"]) ? stats["merges"] : 0
	var/best_tier = isnum(stats["best_tier"]) ? stats["best_tier"] : 1
	var/wasted = isnum(stats["wasted"]) ? stats["wasted"] : 0
	return list(
		"merges" = clamp(round(merges), 0, round(score / 2) + 1),
		"best_tier" = clamp(round(best_tier), 1, 7),
		"wasted" = max(round(wasted), 0),
	)
