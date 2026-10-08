/**
 * Base psychology need.
 * Each need has a 0–100 value that decays over time and contributes to mood.
 */
/datum/psychology_need
	var/id
	var/name = "Need"
	var/description = "A basic psychological need."
	var/value = 80
	var/default_value = 80
	/// How much the need falls per second when not satisfied.
	var/decay_rate = 0.04
	/// Total penalty when this need is completely depleted. No penalty applies above PSY_NEED_OK.
	var/mood_penalty = -9

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
 * Need value is mood-neutral while healthy, then accumulates a tiered penalty
 * between the low, medium, and critical thresholds.
 */
/datum/psychology_need/proc/get_mood_contribution()
	if(value >= PSY_NEED_OK)
		return 0
	if(value >= PSY_NEED_LOW)
		return round(mood_penalty * 0.25 * (PSY_NEED_OK - value) / (PSY_NEED_OK - PSY_NEED_LOW), 0.1)
	if(value >= PSY_NEED_CRITICAL)
		return round(mood_penalty * LERP(0.25, 0.65, (PSY_NEED_LOW - value) / (PSY_NEED_LOW - PSY_NEED_CRITICAL)), 0.1)
	return round(mood_penalty * LERP(0.65, 1, (PSY_NEED_CRITICAL - value) / PSY_NEED_CRITICAL), 0.1)

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
	description = "Hunger falls over roughly 30 minutes and improves after eating."
	decay_rate = 100 / (30 MINUTES / 10)
	default_value = PSY_NEED_MAX
	mood_penalty = -12

/datum/psychology_need/hunger/process_need(seconds_per_tick, datum/psychology/psy)
	if(!psy?.owner)
		return
	var/mob/living/L = psy.owner
	if(iscarbon(L))
		var/mob/living/carbon/C = L
		C.process_rw_hunger(seconds_per_tick, psy)
	else if(HAS_TRAIT(L, TRAIT_NOHUNGER))
		set_value(PSY_NEED_MAX)
	else
		adjust_value(-decay_rate * seconds_per_tick)

/datum/psychology_need/beauty
	id = PSY_NEED_BEAUTY
	name = "Environment"
	description = "The visual quality of your surroundings."
	decay_rate = 0 // driven by area beauty
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
	description = "General physical comfort. Resting helps recover it."
	decay_rate = 0.03
	mood_penalty = -5

/datum/psychology_need/comfort/process_need(seconds_per_tick, datum/psychology/psy)
	// Base decay; can be restored by sitting, good furniture, temperature, etc.
	// Foundation: simple decay + mild recovery if resting
	if(!psy?.owner)
		return
	var/mob/living/L = psy.owner
	if(L.resting || L.IsSleeping())
		adjust_value(0.08 * seconds_per_tick)
	else
		adjust_value(-decay_rate * seconds_per_tick)

/datum/psychology_need/rest
	id = PSY_NEED_REST
	name = "Rest"
	description = "Fatigue accumulates while awake and recovers during rest or sleep."
	decay_rate = 0.04
	mood_penalty = -10

/datum/psychology_need/rest/process_need(seconds_per_tick, datum/psychology/psy)
	if(!psy?.owner)
		return
	var/mob/living/L = psy.owner
	if(L.IsSleeping())
		adjust_value(0.15 * seconds_per_tick)
	else if(L.resting)
		adjust_value(0.05 * seconds_per_tick)
	else
		adjust_value(-decay_rate * seconds_per_tick)

/datum/psychology_need/recreation
	id = PSY_NEED_RECREATION
	name = "Recreation"
	description = "Leisure and enjoyable activities help satisfy this need."
	decay_rate = 0.04
	mood_penalty = -6

/datum/psychology_need/recreation/process_need(seconds_per_tick, datum/psychology/psy)
	// Decays until player does recreational activities (games, art, social)
	// Foundation only decays; restoration hooks come later
	adjust_value(-decay_rate * seconds_per_tick)

/datum/psychology_need/outdoors
	id = PSY_NEED_OUTDOORS
	name = "Outdoors"
	description = "Time outside satisfies this need; staying indoors slowly reduces it."
	decay_rate = 0
	mood_penalty = -3

/datum/psychology_need/outdoors/process_need(seconds_per_tick, datum/psychology/psy)
	if(!psy?.owner)
		return
	var/area/A = get_area(psy.owner)
	if(A?.outdoors)
		adjust_value(0.1 * seconds_per_tick)
	else
		adjust_value(-0.03 * seconds_per_tick)
