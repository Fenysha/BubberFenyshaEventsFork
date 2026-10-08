/**
 * Base psychology need.
 * Each need has a 0–100 value that decays over time and contributes to mood.
 */
/datum/psychology_need
	var/id
	var/name = "Need"
	var/value = 80
	var/default_value = 80
	/// How much the need falls per second when not satisfied
	var/decay_rate = 0.15
	/// Mood contribution when value == 100
	var/mood_weight = PSY_NEED_MOOD_WEIGHT
	/// Mood contribution when value == 0 (usually negative)
	var/mood_penalty = -8

/datum/psychology_need/proc/set_value(amount)
	value = clamp(amount, PSY_NEED_MIN, PSY_NEED_MAX)

/datum/psychology_need/proc/adjust_value(amount)
	set_value(value + amount)

/datum/psychology_need/proc/get_label()
	switch(value)
		if(PSY_NEED_HIGH to INFINITY)
			return "satisfied"
		if(PSY_NEED_OK to PSY_NEED_HIGH)
			return "ok"
		if(PSY_NEED_LOW to PSY_NEED_OK)
			return "low"
		if(PSY_NEED_CRITICAL to PSY_NEED_LOW)
			return "critical"
		else
			return "desperate"

/**
 * Linear interpolation between mood_penalty (at 0) and mood_weight (at 100).
 */
/datum/psychology_need/proc/get_mood_contribution()
	var/t = value / PSY_NEED_MAX
	return round(mood_penalty + (mood_weight - mood_penalty) * t, 0.1)

/**
 * Called every psychology process tick.
 * Override in subtypes for environment-driven needs (beauty, comfort).
 */
/datum/psychology_need/proc/process_need(seconds_per_tick, datum/psychology/psy)
	// Default: slow decay
	adjust_value(-decay_rate * seconds_per_tick)

// ------------------------------------------------------------
// Concrete needs
// ------------------------------------------------------------

/datum/psychology_need/hunger
	id = PSY_NEED_HUNGER
	name = "Hunger"
	decay_rate = 0.25
	mood_weight = 3
	mood_penalty = -12

/datum/psychology_need/hunger/process_need(seconds_per_tick, datum/psychology/psy)
	if(!psy?.owner)
		return
	// Sync with nutrition if the mob has it
	var/mob/living/L = psy.owner
	if(HAS_TRAIT(L, TRAIT_NOHUNGER))
		set_value(PSY_NEED_MAX)
		return
	if(iscarbon(L))
		var/mob/living/carbon/C = L
		// Map nutrition (0–NUTRITION_LEVEL_FULL-ish) roughly onto 0–100
		var/nut = C.nutrition
		// Typical SS13: starving ~0, full ~NUTRITION_LEVEL_FULL (often 550+)
		var/mapped = clamp(round(nut / 5.5), PSY_NEED_MIN, PSY_NEED_MAX)
		set_value(mapped)
	else
		adjust_value(-decay_rate * seconds_per_tick)

/datum/psychology_need/beauty
	id = PSY_NEED_BEAUTY
	name = "Environment"
	decay_rate = 0 // driven by area beauty
	mood_weight = 4
	mood_penalty = -6

/datum/psychology_need/beauty/process_need(seconds_per_tick, datum/psychology/psy)
	if(!psy?.owner)
		return
	var/area/A = get_area(psy.owner)
	if(!A || A.outdoors)
		// outdoors handled by outdoors need; indoors without beauty data → neutral
		set_value(60)
		return
	// Map area beauty (uses existing BEAUTY_LEVEL_* defines) onto 0–100
	var/beauty = A.beauty
	var/mapped
	switch(beauty)
		if(-INFINITY to BEAUTY_LEVEL_HORRID)
			mapped = 5
		if(BEAUTY_LEVEL_HORRID to BEAUTY_LEVEL_BAD)
			mapped = 25
		if(BEAUTY_LEVEL_BAD to BEAUTY_LEVEL_DECENT)
			mapped = 50
		if(BEAUTY_LEVEL_DECENT to BEAUTY_LEVEL_GOOD)
			mapped = 70
		if(BEAUTY_LEVEL_GOOD to BEAUTY_LEVEL_GREAT)
			mapped = 85
		else
			mapped = 100
	// Morbid / snob traits invert or exaggerate — handled later via factors
	set_value(mapped)

/datum/psychology_need/comfort
	id = PSY_NEED_COMFORT
	name = "Comfort"
	decay_rate = 0.08
	mood_weight = 3
	mood_penalty = -5

/datum/psychology_need/comfort/process_need(seconds_per_tick, datum/psychology/psy)
	// Base decay; can be restored by sitting, good furniture, temperature, etc.
	// Foundation: simple decay + mild recovery if resting
	if(!psy?.owner)
		return
	var/mob/living/L = psy.owner
	if(L.resting || L.IsSleeping())
		adjust_value(0.4 * seconds_per_tick)
	else
		adjust_value(-decay_rate * seconds_per_tick)

/datum/psychology_need/rest
	id = PSY_NEED_REST
	name = "Rest"
	decay_rate = 0.12
	mood_weight = 4
	mood_penalty = -10

/datum/psychology_need/rest/process_need(seconds_per_tick, datum/psychology/psy)
	if(!psy?.owner)
		return
	var/mob/living/L = psy.owner
	if(L.IsSleeping())
		adjust_value(1.2 * seconds_per_tick)
	else if(L.resting)
		adjust_value(0.3 * seconds_per_tick)
	else
		adjust_value(-decay_rate * seconds_per_tick)

/datum/psychology_need/recreation
	id = PSY_NEED_RECREATION
	name = "Recreation"
	decay_rate = 0.1
	mood_weight = 3
	mood_penalty = -6

/datum/psychology_need/recreation/process_need(seconds_per_tick, datum/psychology/psy)
	// Decays until player does recreational activities (games, art, social)
	// Foundation only decays; restoration hooks come later
	adjust_value(-decay_rate * seconds_per_tick)

/datum/psychology_need/outdoors
	id = PSY_NEED_OUTDOORS
	name = "Outdoors"
	decay_rate = 0
	mood_weight = 2
	mood_penalty = -3

/datum/psychology_need/outdoors/process_need(seconds_per_tick, datum/psychology/psy)
	if(!psy?.owner)
		return
	var/area/A = get_area(psy.owner)
	if(A?.outdoors)
		adjust_value(0.5 * seconds_per_tick)
	else
		adjust_value(-0.15 * seconds_per_tick)
