/**
 * Psychology datum — RimWorld-style mental state replacement for /datum/mood.
 *
 * Holds:
 * - current mood (short-term)
 * - mental break state
 * - needs (hunger, beauty, comfort, rest, ...)
 * - references to backstory / childhood / traits applied from prefs
 * - modifiers from traits, environment, etc.
 *
 * Created on living mobs that use the rimworld character system.
 */
/datum/psychology
	/// Owning living mob
	var/mob/living/owner

	/// Current short-term mood value (can be negative or positive)
	var/mood = 0
	/// Cached mood level string for UI ("ecstatic", "content", "stressed", etc.)
	var/mood_label = "neutral"
	/// Multiplier applied to all mood changes (traits can modify)
	var/mood_modifier = 1

	/// Active mental break controller (null when stable)
	var/datum/psychology_break/active_break

	/// Thresholds for breaks (can be modified by traits e.g. iron_willed)
	var/break_threshold_minor = PSY_MOOD_BREAK_MINOR
	var/break_threshold_major = PSY_MOOD_BREAK_MAJOR
	var/break_threshold_extreme = PSY_MOOD_BREAK_EXTREME

	/// Need id -> /datum/psychology_need
	var/list/needs = list()

	/// Active temporary mood factors (category -> /datum/psychology_factor)
	var/list/factors = list()

	/// Childhood backstory id (from prefs)
	var/childhood_id
	/// Adulthood backstory id (from prefs)
	var/adulthood_id
	/// Trait ids currently applied (from prefs + runtime)
	var/list/trait_ids = list()
	/// TRUE after load_persona has written skills. Genes gained after that adjust skills themselves.
	var/persona_loaded = FALSE

	/// Last time we processed needs / break rolls
	var/last_process = 0

/datum/psychology/New(mob/living/new_owner)
	if(!istype(new_owner))
		qdel(src)
		return
	owner = new_owner
	init_default_needs()
	START_PROCESSING(SSpsychology, src)
	RegisterSignal(owner, COMSIG_QDELETING, PROC_REF(on_owner_qdel))
	RegisterSignal(owner, COMSIG_LIVING_REVIVE, PROC_REF(on_revive))
	RegisterSignal(owner, COMSIG_MOB_STATCHANGE, PROC_REF(on_stat_change))

/datum/psychology/Destroy(force)
	STOP_PROCESSING(SSpsychology, src)
	if(owner)
		UnregisterSignal(owner, list(COMSIG_QDELETING, COMSIG_LIVING_REVIVE, COMSIG_MOB_STATCHANGE))
		if(active_break)
			end_mental_break(forced = TRUE)
	owner = null
	QDEL_NULL(active_break)
	QDEL_LIST_ASSOC_VAL(needs)
	QDEL_LIST_ASSOC_VAL(factors)
	return ..()

/datum/psychology/proc/on_owner_qdel()
	SIGNAL_HANDLER
	qdel(src)

/datum/psychology/proc/on_revive(datum/source, full_heal)
	SIGNAL_HANDLER
	if(full_heal)
		reset_to_baseline()

/datum/psychology/proc/on_stat_change(datum/source, new_stat, old_stat)
	SIGNAL_HANDLER
	if(old_stat == DEAD && new_stat != DEAD)
		START_PROCESSING(SSpsychology, src)
	else if(old_stat != DEAD && new_stat == DEAD)
		STOP_PROCESSING(SSpsychology, src)
		if(active_break)
			end_mental_break(forced = TRUE)


/**
 * Loads persona state from a neutral data payload.
 * Skill initialization is owned by Psychology.
 */
/datum/psychology/proc/load_persona(list/persona_data)
	if(!islist(persona_data))
		return
	childhood_id = persona_data["childhood"] || "childhood_none"
	adulthood_id = persona_data["adulthood"] || "adulthood_none"
	trait_ids = islist(persona_data["traits"]) ? _list_copy(persona_data["traits"]) : list()
	initialize_skills(persona_data["skills"], persona_data["passions"], trait_ids, childhood_id, adulthood_id, persona_data["xenogenes"])
	apply_trait_modifiers()
	apply_backstory_modifiers()
	recalculate_mood()
	persona_loaded = TRUE
	// Genes are applied before psychology exists, so mood and speed have to be pushed again here.
	if(iscarbon(owner))
		var/mob/living/carbon/pawn = owner
		pawn.refresh_rw_xenogene_passives()

/**
 * Applies permanent modifiers from selected traits (e.g. sanguine +12 mood, iron_willed lower thresholds).
 */
/datum/psychology/proc/apply_trait_modifiers()
	mood_modifier = 1
	break_threshold_minor = PSY_MOOD_BREAK_MINOR
	break_threshold_major = PSY_MOOD_BREAK_MAJOR
	break_threshold_extreme = PSY_MOOD_BREAK_EXTREME

	/*
	for(var/tid in trait_ids)
		var/datum/rw_trait/T = GLOB.all_rw_traits?[tid]
		if(!T)
			continue
		// Known psychology-relevant traits
		switch(tid)
			if("sanguine")
				add_factor(PSY_CATEGORY_TRAIT, "sanguine", 12, "Naturally cheerful.", permanent = TRUE)
			if("iron_willed")
				break_threshold_minor = round(PSY_MOOD_BREAK_MINOR * 0.82)
				break_threshold_major = round(PSY_MOOD_BREAK_MAJOR * 0.82)
				break_threshold_extreme = round(PSY_MOOD_BREAK_EXTREME * 0.82)
			if("neurotic") // example negative trait if present
				break_threshold_minor = round(PSY_MOOD_BREAK_MINOR * 1.15)
				break_threshold_major = round(PSY_MOOD_BREAK_MAJOR * 1.15)
				break_threshold_extreme = round(PSY_MOOD_BREAK_EXTREME * 1.15)
	*/

/datum/psychology/proc/apply_backstory_modifiers()
	// TODO: backstories can grant permanent factors or need offsets later
	return

/**
 * Resets temporary state (used on full heal / revive).
 */
/datum/psychology/proc/reset_to_baseline()
	if(active_break)
		end_mental_break(forced = TRUE)
	for(var/cat in factors)
		var/datum/psychology_factor/F = factors[cat]
		if(F && !F.permanent)
			clear_factor(cat)
	for(var/nid in needs)
		var/datum/psychology_need/N = needs[nid]
		N?.set_value(N.default_value)
	recalculate_mood()


/datum/psychology/proc/get_mood()
	return mood

/datum/psychology/proc/set_mood(amount)
	mood = amount
	update_mood_label()
	SEND_SIGNAL(owner, COMSIG_MOB_PSYCHOLOGY_MOOD_UPDATE, mood)
	return mood

/datum/psychology/proc/adjust_mood(amount)
	return set_mood(mood + amount * mood_modifier)

/datum/psychology/proc/get_mood_label()
	return mood_label

/datum/psychology/proc/update_mood_label()
	switch(mood)
		if(20 to INFINITY)
			mood_label = "ecstatic"
		if(10 to 20)
			mood_label = "happy"
		if(5 to 10)
			mood_label = "content"
		if(-5 to 5)
			mood_label = "neutral"
		if(-15 to -5)
			mood_label = "stressed"
		if(-30 to -15)
			mood_label = "miserable"
		else
			mood_label = "catatonic"

/datum/psychology/proc/get_break_severity()
	return active_break ? active_break.severity : PSY_BREAK_NONE

/datum/psychology/proc/is_in_break()
	return !!active_break?.active

/datum/psychology/proc/get_need(need_id)
	return needs[need_id]

/datum/psychology/proc/get_need_value(need_id)
	var/datum/psychology_need/N = needs[need_id]
	return N ? N.value : null

/datum/psychology/proc/set_need_value(need_id, amount)
	var/datum/psychology_need/N = needs[need_id]
	if(!N)
		return
	N.set_value(amount)
	recalculate_mood()

/datum/psychology/proc/adjust_need_value(need_id, amount)
	var/datum/psychology_need/N = needs[need_id]
	if(!N)
		return
	N.adjust_value(amount)
	recalculate_mood()

/datum/psychology/proc/get_childhood_id()
	return childhood_id

/datum/psychology/proc/get_adulthood_id()
	return adulthood_id

/datum/psychology/proc/get_trait_ids()
	return trait_ids?.Copy() || list()

/datum/psychology/proc/has_trait(trait_id)
	return (trait_id in trait_ids)

/datum/psychology/proc/add_trait_id(trait_id)
	if(!trait_ids)
		trait_ids = list()
	if(trait_id in trait_ids)
		return FALSE
	trait_ids += trait_id
	apply_trait_modifiers()
	recalculate_mood()
	return TRUE

/datum/psychology/proc/remove_trait_id(trait_id)
	if(!(trait_id in trait_ids))
		return FALSE
	trait_ids -= trait_id
	clear_factor("[PSY_CATEGORY_TRAIT]_[trait_id]")
	apply_trait_modifiers()
	recalculate_mood()
	return TRUE


/**
 * Adds or refreshes a mood factor.
 * category — unique key (e.g. "need_hunger", "trait_sanguine")
 * id — human-readable id for UI
 * amount — mood delta
 * description — shown in UI
 * timeout — world.time based expiry (0 = permanent until cleared)
 * permanent — survives reset_to_baseline
 */
/datum/psychology/proc/add_factor(category, id, amount, description, timeout = 0, permanent = FALSE)
	if(!istext(category))
		category = REF(category)
	var/datum/psychology_factor/existing = factors[category]
	if(existing)
		existing.mood_change = amount
		existing.description = description
		existing.timeout = timeout
		existing.permanent = permanent
		existing.id = id
	else
		var/datum/psychology_factor/F = new
		F.category = category
		F.id = id
		F.mood_change = amount
		F.description = description
		F.timeout = timeout
		F.permanent = permanent
		factors[category] = F
	recalculate_mood()

/datum/psychology/proc/clear_factor(category)
	if(!istext(category))
		category = REF(category)
	var/datum/psychology_factor/F = factors[category]
	if(!F)
		return
	factors -= category
	qdel(F)
	recalculate_mood()

/datum/psychology/proc/get_factor(category)
	return factors[category]


/datum/psychology/proc/recalculate_mood()
	var/total = 0
	for(var/cat in factors)
		var/datum/psychology_factor/F = factors[cat]
		if(F)
			total += F.mood_change
	// Needs contribute based on their current satisfaction
	for(var/nid in needs)
		var/datum/psychology_need/N = needs[nid]
		if(N)
			total += N.get_mood_contribution()
	set_mood(total)


/datum/psychology/process(seconds_per_tick)
	if(QDELETED(owner) || owner.stat == DEAD)
		return

	// Expire timed factors
	var/list/to_clear = list()
	for(var/cat in factors)
		var/datum/psychology_factor/F = factors[cat]
		if(F?.timeout && world.time >= F.timeout)
			to_clear += cat
	for(var/cat in to_clear)
		clear_factor(cat)

	// Update needs
	for(var/nid in needs)
		var/datum/psychology_need/N = needs[nid]
		N?.process_need(seconds_per_tick, src)

	// Mental-break rolls must use the updated needs and pain factors from this tick.
	recalculate_mood()

	// Mental break handling
	if(active_break)
		active_break.process_break(seconds_per_tick)
		// Break may have ended itself during process_break
		if(active_break && !active_break.active)
			QDEL_NULL(active_break)
	else
		try_roll_mental_break()

	recalculate_mood()
	last_process = world.time


/**
 * Rolls for a mental break if mood is below thresholds.
 * Called every process tick while not already in a break.
 */
/datum/psychology/proc/try_roll_mental_break()
	if(active_break || !owner)
		return
	if(iscarbon(owner))
		var/mob/living/carbon/pawn = owner
		if(pawn.dna?.rw_prevents_mental_breaks())
			return

	var/severity = PSY_BREAK_NONE
	var/chance = 0

	if(mood <= break_threshold_extreme)
		severity = PSY_BREAK_EXTREME
		chance = PSY_BREAK_CHANCE_EXTREME
	else if(mood <= break_threshold_major)
		severity = PSY_BREAK_MAJOR
		chance = PSY_BREAK_CHANCE_MAJOR
	else if(mood <= break_threshold_minor)
		severity = PSY_BREAK_MINOR
		chance = PSY_BREAK_CHANCE_MINOR
	else
		return

	if(!prob(chance))
		return

	start_mental_break(severity)

/**
 * Starts a mental break of the given severity via /datum/psychology_break.
 */
/datum/psychology/proc/start_mental_break(severity)
	if(active_break || severity <= PSY_BREAK_NONE)
		return FALSE

	var/datum/psychology_break/B = create_psychology_break(src, severity)
	if(!B)
		return FALSE

	active_break = B
	if(!B.start())
		QDEL_NULL(active_break)
		return FALSE
	return TRUE

/**
 * Ends the current mental break (if any) and clears the controller.
 */
/datum/psychology/proc/end_mental_break(forced = FALSE)
	if(!active_break)
		return FALSE
	active_break.end(forced)
	QDEL_NULL(active_break)
	return TRUE

/datum/psychology/proc/init_default_needs()
	needs = list()
	needs[PSY_NEED_HUNGER] = new /datum/psychology_need/hunger
	needs[PSY_NEED_BEAUTY] = new /datum/psychology_need/beauty
	needs[PSY_NEED_COMFORT] = new /datum/psychology_need/comfort
	needs[PSY_NEED_REST] = new /datum/psychology_need/rest
	needs[PSY_NEED_RECREATION] = new /datum/psychology_need/recreation
	needs[PSY_NEED_OUTDOORS] = new /datum/psychology_need/outdoors


/**
 * Returns a list suitable for TGUI "Psychology" tab.
 */
/datum/psychology/proc/build_ui_data()
	var/list/need_data = list()
	for(var/nid in needs)
		var/datum/psychology_need/N = needs[nid]
		need_data += list(list(
			"id" = nid,
			"name" = N.name,
			"description" = N.description,
			"value" = N.value,
			"max" = PSY_NEED_MAX,
			"label" = N.get_label(),
			"moodContribution" = N.get_mood_contribution(),
			"lowThreshold" = PSY_NEED_OK,
			"mediumThreshold" = PSY_NEED_LOW,
			"criticalThreshold" = PSY_NEED_CRITICAL,
		))

	var/list/factor_data = list()
	for(var/cat in factors)
		var/datum/psychology_factor/F = factors[cat]
		if(!F)
			continue
		factor_data += list(list(
			"id" = F.id,
			"description" = F.description,
			"moodChange" = F.mood_change,
			"permanent" = F.permanent,
		))

	return list(
		"mood" = mood,
		"moodScaleMin" = PSY_MOOD_SCALE_MIN,
		"moodScaleMax" = PSY_MOOD_SCALE_MAX,
		"moodLabel" = mood_label,
		"breakSeverity" = get_break_severity(),
		"inBreak" = is_in_break(),
		"breakEndsIn" = active_break ? active_break.seconds_remaining() : 0,
		"breakName" = active_break ? active_break.name : null,
		"thresholds" = list(
			"minor" = break_threshold_minor,
			"major" = break_threshold_major,
			"extreme" = break_threshold_extreme,
		),
		"needs" = need_data,
		"factors" = factor_data,
		"childhoodId" = childhood_id,
		"adulthoodId" = adulthood_id,
		"traits" = trait_ids?.Copy() || list(),
	)

/**
 * Returns persona-focused data (skills, backstory, traits) for the Persona tab.
 */
/datum/psychology/proc/build_ui_persona_data()
	return list(
		"childhoodId" = childhood_id,
		"adulthoodId" = adulthood_id,
		"traits" = trait_ids?.Copy() || list(),
		"skills" = build_skill_level_ui_data(),
		"skillData" = build_skill_ui_data(),
	)


/**
 * Fills backstory, traits, skill mirror and passions with random preset data.
 * Used for NPCs / colonists without player prefs.
 */
/datum/psychology/proc/randomize_persona()
	childhood_id = "childhood_none"
	adulthood_id = "adulthood_none"
	trait_ids = list()
	var/list/random_skills = list()
	var/list/random_passions = list()

	if(length(GLOB.all_rw_backstories))
		var/list/childhoods = list()
		var/list/adulthoods = list()
		for(var/id in GLOB.all_rw_backstories)
			var/datum/rw_backstory/story = GLOB.all_rw_backstories[id]
			if(!story)
				continue
			if(story.slot == RW_BACKSTORY_CHILDHOOD)
				childhoods += id
			else if(story.slot == RW_BACKSTORY_ADULTHOOD)
				adulthoods += id
		if(length(childhoods))
			childhood_id = pick(childhoods)
		if(length(adulthoods))
			adulthood_id = pick(adulthoods)

	if(length(GLOB.all_rw_traits))
		var/list/pool = GLOB.all_rw_traits.Copy()
		var/picks = rand(0, min(2, length(pool)))
		for(var/i in 1 to picks)
			if(!length(pool))
				break
			var/tid = pick(pool)
			pool -= tid
			trait_ids += tid

	if(length(GLOB.all_rw_skills))
		for(var/skill_id in GLOB.all_rw_skills)
			random_skills[skill_id] = 0
			random_passions[skill_id] = RW_PASSION_NONE
		var/list/skill_pool = GLOB.all_rw_skills.Copy()
		var/passion_count = rand(1, min(3, length(skill_pool)))
		for(var/i in 1 to passion_count)
			if(!length(skill_pool))
				break
			var/sid = pick(skill_pool)
			skill_pool -= sid
			random_passions[sid] = pick(RW_PASSION_INTERESTED, RW_PASSION_BURNING)

	initialize_skills(random_skills, random_passions, trait_ids, childhood_id, adulthood_id)
	apply_trait_modifiers()
	apply_backstory_modifiers()
	recalculate_mood()

