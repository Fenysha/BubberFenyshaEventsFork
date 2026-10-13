/// A small personality profile. It chooses the broad tone of events, not individual event weights.
/datum/storyteller_mood
	var/name = "Classic"
	var/desc = "A balanced mixture of incidents."
	var/style = "classic"
	var/interval_multiplier = 1.0

/datum/storyteller_mood/proc/pick_category(difficulty = STORYTELLER_DEFAULT_DIFFICULTY)
	var/category = pick_base_category()
	// Low difficulty softens the storyteller, high difficulty escalates it.
	if(difficulty < 0.5 && (category == STORY_EVENT_BAD || category == STORY_EVENT_MAJOR) && prob(70))
		return pick(STORY_EVENT_GOOD, STORY_EVENT_NEUTRAL)
	if(difficulty >= 2 && category == STORY_EVENT_BAD && prob(min(50, (difficulty - 1) * 15)))
		return STORY_EVENT_MAJOR
	return category

/datum/storyteller_mood/proc/pick_base_category()
	switch(style)
		if("gentle")
			if(prob(70))
				return pick(STORY_EVENT_GOOD, STORY_EVENT_NEUTRAL)
			return pick(STORY_EVENT_NEUTRAL, STORY_EVENT_BAD)
		if("random")
			return pick(STORY_EVENT_GOOD, STORY_EVENT_NEUTRAL, STORY_EVENT_BAD, STORY_EVENT_MAJOR)
		if("harsh")
			if(prob(35))
				return STORY_EVENT_MAJOR
			return pick(STORY_EVENT_BAD, STORY_EVENT_BAD, STORY_EVENT_NEUTRAL)
		if("challenge")
			if(prob(25))
				return STORY_EVENT_MAJOR
			return pick(STORY_EVENT_GOOD, STORY_EVENT_NEUTRAL, STORY_EVENT_BAD)
	return pick(STORY_EVENT_GOOD, STORY_EVENT_NEUTRAL, STORY_EVENT_BAD)

/datum/storyteller_mood/proc/get_interval_multiplier()
	return max(0.25, interval_multiplier)

/datum/storyteller_mood/chill
	name = "Chill"
	desc = "A calm pace with more positive and neutral incidents."
	style = "gentle"
	interval_multiplier = 1.5

/datum/storyteller_mood/classic
	name = "Classic"
	desc = "A steady mixture of positive, neutral and negative incidents."
	style = "classic"
	interval_multiplier = 1.0

/datum/storyteller_mood/gambit
	name = "Gambit"
	desc = "Highly unpredictable, with occasional major incidents."
	style = "random"
	interval_multiplier = 1.0

/datum/storyteller_mood/catastrophe
	name = "Catastrophe"
	desc = "A relentless sequence of difficult events and occasional major incidents."
	style = "harsh"
	interval_multiplier = 0.75

/datum/storyteller_mood/challenge
	name = "Challenge"
	desc = "A mixed pace with somewhat more frequent major incidents."
	style = "challenge"
	interval_multiplier = 0.9
