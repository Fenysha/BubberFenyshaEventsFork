/**
 * Medical / xenogene stats that live on the vanilla physiology datum.
 *
 * Every stat is a product (multipliers), a minimum (limits) or a sum (additive) of per-source layers, so a source
 * (gene, drug, trait) can be added and removed without knowing what else is active.
 * Source keys are free-form; genes use "xenogene_[id]". The vanilla brute_mod / burn_mod / tox_mod / bleed_mod
 * are deliberately untouched: the combat_extended damage pipeline reads the *_taken_mod fields below instead.
 */
/datum/physiology
	/// Multipliers on the final medical state (see recalculate_medical_state).
	var/pain_mod = 1
	var/shock_mod = 1
	var/consciousness_mod = 1
	/// Recovery-rate multipliers for shock and temporary consciousness loss.
	var/shock_recovery_mod = 1
	var/consciousness_recovery_mod = 1
	/// Caps applied after the modifiers above. The smallest registered limit wins.
	var/pain_limit = PAIN_MAX
	var/shock_limit = SHOCK_MAX

	/// Incoming damage multipliers, applied once per bodypart hit.
	var/brute_taken_mod = 1
	var/burn_taken_mod = 1
	var/tox_taken_mod = 1
	/// Injury bleed-rate and natural-healing multipliers.
	var/bleed_rate_mod = 1
	var/wound_heal_mod = 1
	/// Disease recovery multiplier.
	var/immunity_mod = 1
	/// Multiplier on the species / base max health. Frail uses 0.8.
	var/maxhealth_mod = 1

	/// Combat capacity multipliers.
	var/melee_damage_mod = 1
	var/ranged_spread_mod = 1
	var/manipulation_mod = 1

	/// Added to the species temperature damage limits. Positive cold = harmed by milder cold.
	var/cold_limit_mod = 0
	var/heat_limit_mod = 0
	/// Slowdown added on top of everything else. Negative is faster.
	var/movespeed_slowdown = 0

	/// maxHealth before maxhealth_mod was applied. Null while the modifier is inactive.
	var/cached_max_health

	/// stat var name -> list(source = value)
	var/list/multiplier_sources
	var/list/limit_sources
	var/list/additive_sources

/// Default of a limit stat, used when no source registers a limit.
/datum/physiology/proc/get_limit_default(stat)
	switch(stat)
		if("pain_limit")
			return PAIN_MAX
		if("shock_limit")
			return SHOCK_MAX
	return INFINITY

/datum/physiology/proc/set_multiplier(stat, source, value)
	if(isnull(source) || !isnum(value))
		return FALSE
	value = max(value, 0)
	var/list/sources = LAZYACCESS(multiplier_sources, stat)
	if(sources && sources[source] == value)
		return FALSE
	if(!sources)
		sources = list()
		LAZYSET(multiplier_sources, stat, sources)
	sources[source] = value
	recalculate_multiplier(stat)
	return TRUE

/datum/physiology/proc/remove_multiplier(stat, source)
	var/list/sources = LAZYACCESS(multiplier_sources, stat)
	if(!sources || !(source in sources))
		return FALSE
	sources -= source
	if(!length(sources))
		LAZYREMOVE(multiplier_sources, stat)
	recalculate_multiplier(stat)
	return TRUE

/datum/physiology/proc/recalculate_multiplier(stat)
	var/result = 1
	var/list/sources = LAZYACCESS(multiplier_sources, stat)
	for(var/source in sources)
		result *= sources[source]
	vars[stat] = max(result, 0)

/datum/physiology/proc/set_limit(stat, source, value)
	if(isnull(source) || !isnum(value))
		return FALSE
	value = max(value, 0)
	var/list/sources = LAZYACCESS(limit_sources, stat)
	if(sources && sources[source] == value)
		return FALSE
	if(!sources)
		sources = list()
		LAZYSET(limit_sources, stat, sources)
	sources[source] = value
	recalculate_limit(stat)
	return TRUE

/datum/physiology/proc/remove_limit(stat, source)
	var/list/sources = LAZYACCESS(limit_sources, stat)
	if(!sources || !(source in sources))
		return FALSE
	sources -= source
	if(!length(sources))
		LAZYREMOVE(limit_sources, stat)
	recalculate_limit(stat)
	return TRUE

/datum/physiology/proc/recalculate_limit(stat)
	var/result = get_limit_default(stat)
	var/list/sources = LAZYACCESS(limit_sources, stat)
	for(var/source in sources)
		result = min(result, sources[source])
	vars[stat] = max(result, 0)

/datum/physiology/proc/set_additive(stat, source, value)
	if(isnull(source) || !isnum(value))
		return FALSE
	var/list/sources = LAZYACCESS(additive_sources, stat)
	if(sources && sources[source] == value)
		return FALSE
	if(!sources)
		sources = list()
		LAZYSET(additive_sources, stat, sources)
	sources[source] = value
	recalculate_additive(stat)
	return TRUE

/datum/physiology/proc/remove_additive(stat, source)
	var/list/sources = LAZYACCESS(additive_sources, stat)
	if(!sources || !(source in sources))
		return FALSE
	sources -= source
	if(!length(sources))
		LAZYREMOVE(additive_sources, stat)
	recalculate_additive(stat)
	return TRUE

/datum/physiology/proc/recalculate_additive(stat)
	var/result = 0
	var/list/sources = LAZYACCESS(additive_sources, stat)
	for(var/source in sources)
		result += sources[source]
	vars[stat] = result

/// Drops everything one source registered. Returns the stats that changed so the owner can refresh once per stat.
/datum/physiology/proc/remove_source(source)
	var/list/changed = list()
	for(var/stat in multiplier_sources?.Copy())
		if(remove_multiplier(stat, source))
			changed += stat
	for(var/stat in limit_sources?.Copy())
		if(remove_limit(stat, source))
			changed += stat
	for(var/stat in additive_sources?.Copy())
		if(remove_additive(stat, source))
			changed += stat
	return changed
