#define RW_XENOGENE_EFFECT "rw_xenogene"

/**
 * Gameplay numbers on a xenogene. 1 / 0 means "no change" unless the flag next to it says otherwise.
 * on_gain / on_lose push the summed result onto the pawn. Tick effects need RW_XENOGEN_PROCESSING.
 */
/datum/rw_xenogene
	/// Incoming brute multiplier.
	var/brute_taken_mult = 1
	/// Incoming burn multiplier. Also covers fire from flames.
	var/burn_taken_mult = 1
	/// Pain multiplier. 1 = unchanged.
	var/pain_mult = 1
	/// null = this gene does not touch shock. 0 = shock never builds.
	var/shock_mult = null
	/// Outgoing melee damage multiplier.
	var/melee_damage_mult = 1
	/// Added to max-health multiplier (product). Frail uses 0.8.
	var/maxhealth_mult = 1
	/// SS13 slowdown added to the pawn. Negative is faster.
	var/movespeed_slowdown = 0
	/// Extra slowdown while barely dressed. Negative is faster. Needs processing.
	var/naked_movespeed = 0
	var/naked_speed_active = FALSE
	/// Permanent mood offset while the gene is on.
	var/mood_offset = 0
	/// Multiplier on injury self-heal rate.
	var/wound_heal_mult = 1
	/// Multiplier on injury bleed rate.
	var/bleed_mult = 1
	/// Multiplier on gun spread. Above 1 is less accurate.
	var/ranged_spread_mult = 1
	/// Multiplier on manipulation capacity.
	var/manipulation_mult = 1
	/// Multiplier on toxin damage taken.
	var/tox_mult = 1
	/// Added to the species cold-damage limit. Positive = harmed by milder cold.
	var/cold_limit_mod = 0
	/// Added to the species heat-damage limit. Negative = harmed by milder heat.
	var/heat_limit_mod = 0
	/// Multiplier on disease recovery chance. 1 = unchanged.
	var/immunity_mult = 1
	/// Burn per second in bright outdoors. Needs processing.
	var/uv_burn = 0
	/// Extra RimWorld hunger drain per second while below room temperature. Needs processing.
	var/cold_hunger = 0
	/// Mood while the tile's area is outdoors. Needs processing.
	var/outdoor_mood = 0
	/// Growing mood penalty until the pawn kills something. Needs processing.
	var/tracks_kill_thirst = FALSE
	var/last_kill_time = 0
	/// Psychic sensitivity contributed by this gene. Ignored unless sets_psychic_sensitivity.
	var/sets_psychic_sensitivity = FALSE
	var/psychic_sensitivity = 1
	/// Bonds to the first nearby person. Needs processing. Deaf (sensitivity 0) feels nothing.
	var/bonds_psychically = FALSE
	var/mob/living/psychic_bond
	/// Hemogen restored per second. Needs processing.
	var/hemogen_regen = 0
	/// Radius in which this gene steals hemogen from hemogenics. Needs processing.
	var/hemogen_drain_range = 0
	/// Mood penalty until the pawn deathrests. Needs processing.
	var/needs_deathrest = FALSE
	var/last_deathrest = 0
	/// Never rolls a mental break.
	var/prevents_mental_breaks = FALSE
	/// Caps human age at 18 on gain.
	var/caps_age = FALSE
	/// Skill whose passion this gene sets. Null grant means the gene does not touch passion.
	var/passion_skill
	var/passion_grant
	/// Brain-intact death becomes a regenerative coma. Needs processing.
	var/deathless = FALSE
	var/deathless_coma = FALSE
	/// After eating, strip toxin reagents.
	var/purges_food_toxins = FALSE
	/// Extra nutrition and hunger restore when the eaten item is RAW.
	var/raw_nutrition_bonus = 0
	/// TRUE once this gene's skill_bonuses are inside the pawn's skill levels.
	var/skill_bonus_applied = FALSE
	/// Action granted for the duration of the gene.
	var/ability_path
	var/datum/action/granted_ability
	/// Engine traits added with this gene as the source.
	var/list/gameplay_traits
	/// Pawn the passive effects were applied to. Cleared even if on_lose is skipped.
	var/mob/living/effect_owner
	/// Set during removal so aggregates ignore this gene while it is still in the DNA list.
	var/suppress_passives = FALSE


/datum/rw_xenogene/proc/apply_gameplay(mob/living/target)
	if(!target)
		return
	effect_owner = target
	suppress_passives = FALSE
	for(var/trait in gameplay_traits)
		ADD_TRAIT(target, trait, REF(src))
	if(ability_path && !granted_ability)
		granted_ability = new ability_path
		granted_ability.Grant(target)
	if(length(skill_bonuses))
		var/datum/psychology/skill_psy = target.get_psychology()
		if(skill_psy?.persona_loaded && !skill_bonus_applied)
			adjust_skill_bonuses(target, 1)
			skill_bonus_applied = TRUE
	if(passion_skill && !isnull(passion_grant))
		var/datum/psychology/psy = target.get_psychology()
		if(psy)
			if(passion_grant <= RW_PASSION_NONE)
				psy.set_passion(passion_skill, RW_PASSION_NONE)
			else if(psy.get_passion(passion_skill) < passion_grant)
				psy.set_passion(passion_skill, passion_grant)
	if(caps_age && ishuman(target))
		var/mob/living/carbon/human/human_target = target
		if(human_target.age > 18)
			human_target.age = 18
	if(deathless)
		RegisterSignal(target, COMSIG_LIVING_DEATH, PROC_REF(on_deathless))
	if(tracks_kill_thirst)
		last_kill_time = world.time
		RegisterSignal(SSdcs, COMSIG_GLOB_MOB_DEATH, PROC_REF(on_kill_thirst_death))
	if(purges_food_toxins || raw_nutrition_bonus)
		RegisterSignal(target, COMSIG_LIVING_EAT_FOOD, PROC_REF(on_eat_food))
	if(hemogen_regen && iscarbon(target))
		var/mob/living/carbon/carbon_target = target
		if(carbon_target.rw_hemogen <= 0)
			carbon_target.rw_hemogen = 0.5
	if(needs_deathrest)
		last_deathrest = world.time
	if(iscarbon(target))
		var/mob/living/carbon/passive_target = target
		passive_target.refresh_rw_xenogene_passives()


/datum/rw_xenogene/proc/clear_gameplay(mob/living/target)
	suppress_passives = TRUE
	QDEL_NULL(granted_ability)
	if(target && !QDELETED(target))
		for(var/trait in gameplay_traits)
			REMOVE_TRAIT(target, trait, REF(src))
		UnregisterSignal(target, list(COMSIG_LIVING_DEATH, COMSIG_LIVING_EAT_FOOD))
		var/datum/psychology/psy = target.get_psychology()
		psy?.clear_factor("xenogene_[id]")
		psy?.clear_factor("xenogene_bond")
		psy?.clear_factor("xenogene_killthirst")
		psy?.clear_factor("xenogene_indoor")
		psy?.clear_factor("xenogene_hemogen")
		psy?.clear_factor("xenogene_deathrest")
		if(iscarbon(target))
			var/mob/living/carbon/passive_target = target
			passive_target.refresh_rw_xenogene_passives()
	UnregisterSignal(SSdcs, COMSIG_GLOB_MOB_DEATH)
	deathless_coma = FALSE
	psychic_bond = null
	if(skill_bonus_applied && target && !QDELETED(target))
		adjust_skill_bonuses(target, -1)
		skill_bonus_applied = FALSE
	if(effect_owner == target)
		effect_owner = null

/datum/rw_xenogene/proc/adjust_skill_bonuses(mob/living/target, direction)
	if(!length(skill_bonuses) || !target)
		return
	var/datum/component/rw_skills/skill_comp = target.GetComponent(/datum/component/rw_skills)
	if(!skill_comp)
		return
	for(var/skill_id in skill_bonuses)
		var/delta = skill_bonuses[skill_id]
		if(!isnum(delta) || !delta)
			continue
		skill_comp.set_skill(skill_id, skill_comp.get_skill(skill_id) + delta * direction)


/datum/rw_xenogene/proc/on_deathless(mob/living/source, gibbed)
	SIGNAL_HANDLER
	if(!deathless || gibbed || deathless_coma)
		return
	var/obj/item/organ/brain/brain = source.get_organ_slot(ORGAN_SLOT_BRAIN)
	if(!brain || (brain.organ_flags & ORGAN_FAILING))
		return
	deathless_coma = TRUE
	addtimer(CALLBACK(src, PROC_REF(begin_deathless_coma), source), 1)


/datum/rw_xenogene/proc/begin_deathless_coma(mob/living/source)
	if(QDELETED(src) || source != holder || QDELETED(source))
		deathless_coma = FALSE
		return
	source.revive(NONE, 0, TRUE)
	source.Unconscious(90 SECONDS)
	to_chat(source, span_notice("Deathless archites drag you back from death. You are locked in a regenerative coma."))


/datum/rw_xenogene/proc/on_kill_thirst_death(datum/source, mob/living/died)
	SIGNAL_HANDLER
	if(!tracks_kill_thirst || !holder || died == holder)
		return
	if(died.lastattacker != holder)
		return
	last_kill_time = world.time


/datum/rw_xenogene/proc/on_eat_food(mob/living/source, atom/food)
	SIGNAL_HANDLER
	if(raw_nutrition_bonus && istype(food, /obj/item/food))
		var/obj/item/food/eaten = food
		if(eaten.foodtypes & RAW)
			source.adjust_nutrition(raw_nutrition_bonus)
			if(iscarbon(source))
				var/mob/living/carbon/eater = source
				eater.rw_hunger = min(PSY_NEED_MAX, eater.rw_hunger + raw_nutrition_bonus * 2)
	if(purges_food_toxins)
		addtimer(CALLBACK(src, PROC_REF(purge_eaten_toxins), source), 1)


/datum/rw_xenogene/proc/purge_eaten_toxins(mob/living/source)
	if(QDELETED(src) || !source?.reagents)
		return
	source.reagents.remove_reagent(/datum/reagent/toxin/bad_food, 50)


/datum/rw_xenogene/proc/wearing_little(mob/living/carbon/pawn)
	var/worn = 0
	for(var/slot in list(ITEM_SLOT_OCLOTHING, ITEM_SLOT_ICLOTHING, ITEM_SLOT_GLOVES, ITEM_SLOT_FEET, ITEM_SLOT_HEAD))
		if(pawn.get_item_by_slot(slot))
			worn++
	return worn <= 1


/datum/rw_xenogene/proc/tick_gameplay(seconds_per_tick, mob/living/pawn)
	if(!pawn || QDELETED(pawn))
		return

	if(naked_movespeed && iscarbon(pawn))
		var/mob/living/carbon/naked_pawn = pawn
		var/active = wearing_little(naked_pawn)
		if(active != naked_speed_active)
			naked_speed_active = active
			naked_pawn.refresh_rw_xenogene_passives()

	if(uv_burn > 0)
		var/turf/here = get_turf(pawn)
		var/area/here_area = get_area(here)
		if(here_area?.outdoors && here?.get_lumcount() >= 0.25)
			pawn.apply_damage(uv_burn * seconds_per_tick, BURN, BODY_ZONE_CHEST)

	if(cold_hunger && iscarbon(pawn))
		var/mob/living/carbon/cold_pawn = pawn
		if(cold_pawn.bodytemperature < T20C)
			cold_pawn.rw_hunger = max(PSY_NEED_MIN, cold_pawn.rw_hunger - cold_hunger * seconds_per_tick)

	var/datum/psychology/psy = pawn.get_psychology()

	if(outdoor_mood)
		var/area/pawn_area = get_area(pawn)
		if(pawn_area?.outdoors)
			psy?.add_factor("xenogene_indoor", id, outdoor_mood, "Outdoors (indoor dweller).")
		else
			psy?.clear_factor("xenogene_indoor")

	if(tracks_kill_thirst)
		var/elapsed = world.time - last_kill_time
		if(elapsed > 10 MINUTES)
			psy?.add_factor("xenogene_killthirst", id, -12, "Needs to kill.")
		else if(elapsed > 5 MINUTES)
			psy?.add_factor("xenogene_killthirst", id, -4, "Kill thirst is stirring.")
		else
			psy?.clear_factor("xenogene_killthirst")

	if(hemogen_regen && iscarbon(pawn))
		var/mob/living/carbon/hemo = pawn
		hemo.rw_hemogen = min(1, hemo.rw_hemogen + hemogen_regen * seconds_per_tick)
		if(hemo.rw_hemogen <= 0.05)
			psy?.add_factor("xenogene_hemogen", id, -8, "Hemogen depleted.")
		else
			psy?.clear_factor("xenogene_hemogen")

	if(needs_deathrest)
		if(!last_deathrest)
			last_deathrest = world.time
		if(world.time - last_deathrest > 12 MINUTES)
			psy?.add_factor("xenogene_deathrest", id, -10, "Needs deathrest.")
		else
			psy?.clear_factor("xenogene_deathrest")

	if(hemogen_drain_range && iscarbon(pawn))
		var/mob/living/carbon/drainer = pawn
		for(var/mob/living/carbon/other in oview(hemogen_drain_range, pawn))
			if(!other.dna?.has_rw_xenogene(RW_XENOGENE_HEMOGENIC) || other.rw_hemogen <= 0)
				continue
			var/stolen = min(0.015 * seconds_per_tick, other.rw_hemogen)
			other.rw_hemogen -= stolen
			drainer.rw_hemogen = min(1, drainer.rw_hemogen + stolen)

	if(bonds_psychically)
		var/sensitivity = 1
		if(iscarbon(pawn))
			var/mob/living/carbon/sensitive = pawn
			sensitivity = sensitive.dna?.get_rw_psychic_sensitivity()
			if(isnull(sensitivity))
				sensitivity = 1
		if(sensitivity <= 0)
			psy?.clear_factor("xenogene_bond")
		else
			if(!psychic_bond || QDELETED(psychic_bond) || psychic_bond.stat == DEAD)
				psychic_bond = null
				for(var/mob/living/carbon/human/near in oview(1, pawn))
					if(near.stat == DEAD)
						continue
					psychic_bond = near
					to_chat(pawn, span_notice("A psychic bond snaps into place with [near]."))
					break
			if(!psychic_bond)
				psy?.clear_factor("xenogene_bond")
			else if(get_dist(pawn, psychic_bond) <= 8)
				psy?.add_factor("xenogene_bond", id, round(8 * sensitivity), "Psychic bond is close.")
			else
				psy?.add_factor("xenogene_bond", id, round(-6 * sensitivity), "Psychic bond is far away.")

	if(deathless_coma && iscarbon(pawn))
		pawn.adjust_brute_loss(-1.5 * seconds_per_tick, forced = TRUE)
		pawn.adjust_fire_loss(-1.5 * seconds_per_tick, forced = TRUE)
		if(pawn.stat == STABLE && !IS_UNCONSCIOUS(pawn))
			deathless_coma = FALSE
			to_chat(pawn, span_notice("The regenerative coma lifts."))


/mob/living/carbon
	var/rw_hemogen = 0

/mob/living/carbon/human
	var/datum/species/rw_cached_species
	var/rw_cached_cold_limit
	var/rw_cached_heat_limit
	var/rw_cached_maxhealth

/mob/living/carbon/proc/rw_spend_hemogen(amount)
	if(rw_hemogen < amount)
		return FALSE
	rw_hemogen -= amount
	return TRUE


/mob/living/carbon/proc/refresh_rw_xenogene_passives()
	if(!dna)
		return
	var/datum/psychology/psy
	if(mind || client)
		psy = ensure_psychology()
	else
		psy = get_psychology()

	var/slowdown = dna.get_rw_movespeed_slowdown()
	if(slowdown)
		add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/rw_xenogene, multiplicative_slowdown = slowdown)
	else
		remove_movespeed_modifier(/datum/movespeed_modifier/rw_xenogene)

#ifndef OLD_COMBAT_SYSTEM
	var/pain = dna.get_rw_pain_mult()
	if(pain != 1)
		set_pain_modifier(RW_XENOGENE_EFFECT, pain)
	else
		remove_pain_modifier(RW_XENOGENE_EFFECT)

	var/shock = dna.get_rw_shock_mult()
	if(isnull(shock))
		remove_shock_modifier(RW_XENOGENE_EFFECT)
	else
		set_shock_modifier(RW_XENOGENE_EFFECT, shock)
#endif

	if(psy)
		for(var/gene_id in dna.rw_xenogenes)
			var/datum/rw_xenogene/gene = dna.rw_xenogenes[gene_id]
			if(!gene || QDELETED(gene) || gene.suppress_passives || !gene.mood_offset)
				psy.clear_factor("xenogene_[gene_id]")
				continue
			psy.add_factor("xenogene_[gene_id]", gene.id, gene.mood_offset, gene.name, permanent = TRUE)

	if(!ishuman(src))
		return
	var/mob/living/carbon/human/human_pawn = src
	if(!human_pawn.dna?.species)
		return

	var/datum/species/species = human_pawn.dna.species
	var/cold_mod = dna.get_rw_cold_limit_mod()
	var/heat_mod = dna.get_rw_heat_limit_mod()
	if(human_pawn.rw_cached_species != species || isnull(human_pawn.rw_cached_cold_limit))
		human_pawn.rw_cached_species = species
		human_pawn.rw_cached_cold_limit = species.bodytemp_cold_damage_limit
		human_pawn.rw_cached_heat_limit = species.bodytemp_heat_damage_limit
	species.bodytemp_cold_damage_limit = human_pawn.rw_cached_cold_limit + cold_mod
	species.bodytemp_heat_damage_limit = human_pawn.rw_cached_heat_limit + heat_mod

	var/health_mult = dna.get_rw_maxhealth_mult()
	if(health_mult != 1 || !isnull(human_pawn.rw_cached_maxhealth))
		if(isnull(human_pawn.rw_cached_maxhealth))
			human_pawn.rw_cached_maxhealth = human_pawn.maxHealth
		human_pawn.maxHealth = max(1, round(human_pawn.rw_cached_maxhealth * health_mult, 1))
		if(human_pawn.health > human_pawn.maxHealth)
			human_pawn.health = human_pawn.maxHealth


/datum/movespeed_modifier/rw_xenogene
	variable = TRUE
	multiplicative_slowdown = 0


/datum/dna/proc/rw_each_gene()
	var/list/genes = list()
	if(!length(rw_xenogenes))
		return genes
	for(var/gene_id in rw_xenogenes)
		var/datum/rw_xenogene/gene = rw_xenogenes[gene_id]
		if(!gene || QDELETED(gene) || gene.suppress_passives)
			continue
		genes += gene
	return genes

/datum/dna/proc/get_rw_product(field)
	var/result = 1
	for(var/datum/rw_xenogene/gene as anything in rw_each_gene())
		var/value = gene.vars[field]
		if(isnum(value))
			result *= value
	return result

/datum/dna/proc/get_rw_sum(field)
	var/result = 0
	for(var/datum/rw_xenogene/gene as anything in rw_each_gene())
		var/value = gene.vars[field]
		if(isnum(value))
			result += value
	return result

/datum/dna/proc/get_rw_brute_taken_mult()
	return get_rw_product("brute_taken_mult")

/datum/dna/proc/get_rw_burn_taken_mult()
	return get_rw_product("burn_taken_mult")

/datum/dna/proc/get_rw_pain_mult()
	return get_rw_product("pain_mult")

/datum/dna/proc/get_rw_melee_damage_mult()
	return get_rw_product("melee_damage_mult")

/datum/dna/proc/get_rw_maxhealth_mult()
	return get_rw_product("maxhealth_mult")

/datum/dna/proc/get_rw_wound_heal_mult()
	return get_rw_product("wound_heal_mult")

/datum/dna/proc/get_rw_bleed_mult()
	return get_rw_product("bleed_mult")

/datum/dna/proc/get_rw_ranged_spread_mult()
	return get_rw_product("ranged_spread_mult")

/datum/dna/proc/get_rw_manipulation_mult()
	return get_rw_product("manipulation_mult")

/datum/dna/proc/get_rw_tox_mult()
	return get_rw_product("tox_mult")

/datum/dna/proc/get_rw_immunity_mult()
	return get_rw_product("immunity_mult")

/datum/dna/proc/get_rw_cold_limit_mod()
	return get_rw_sum("cold_limit_mod")

/datum/dna/proc/get_rw_heat_limit_mod()
	return get_rw_sum("heat_limit_mod")

/datum/dna/proc/get_rw_movespeed_slowdown()
	var/total = get_rw_sum("movespeed_slowdown")
	for(var/datum/rw_xenogene/gene as anything in rw_each_gene())
		if(gene.naked_movespeed && gene.naked_speed_active)
			total += gene.naked_movespeed
	return total

/datum/dna/proc/get_rw_shock_mult()
	var/found = FALSE
	var/result = 1
	for(var/datum/rw_xenogene/gene as anything in rw_each_gene())
		if(isnull(gene.shock_mult))
			continue
		found = TRUE
		if(gene.shock_mult <= 0)
			return 0
		result *= gene.shock_mult
	if(!found)
		return null
	return result

/datum/dna/proc/get_rw_psychic_sensitivity()
	var/result = 1
	var/any = FALSE
	for(var/datum/rw_xenogene/gene as anything in rw_each_gene())
		if(!gene.sets_psychic_sensitivity)
			continue
		any = TRUE
		result *= gene.psychic_sensitivity
	if(!any)
		return 1
	return result

/datum/dna/proc/rw_prevents_mental_breaks()
	for(var/datum/rw_xenogene/gene as anything in rw_each_gene())
		if(gene.prevents_mental_breaks)
			return TRUE
	return FALSE


/mob/living/proc/get_rw_brute_taken_mult()
	return 1

/mob/living/carbon/get_rw_brute_taken_mult()
	return dna?.get_rw_brute_taken_mult() || 1

/mob/living/proc/get_rw_burn_taken_mult()
	return 1

/mob/living/carbon/get_rw_burn_taken_mult()
	return dna?.get_rw_burn_taken_mult() || 1

/mob/living/proc/get_rw_melee_damage_mult()
	return 1

/mob/living/carbon/get_rw_melee_damage_mult()
	return dna?.get_rw_melee_damage_mult() || 1

/mob/living/proc/get_rw_wound_heal_mult()
	return 1

/mob/living/carbon/get_rw_wound_heal_mult()
	return dna?.get_rw_wound_heal_mult() || 1

/mob/living/proc/get_rw_bleed_mult()
	return 1

/mob/living/carbon/get_rw_bleed_mult()
	return dna?.get_rw_bleed_mult() || 1

/mob/living/proc/get_rw_ranged_spread_mult()
	return 1

/mob/living/carbon/get_rw_ranged_spread_mult()
	return dna?.get_rw_ranged_spread_mult() || 1

/mob/living/proc/get_rw_manipulation_mult()
	return 1

/mob/living/carbon/get_rw_manipulation_mult()
	return dna?.get_rw_manipulation_mult() || 1

/mob/living/proc/get_rw_tox_mult()
	return 1

/mob/living/carbon/get_rw_tox_mult()
	if(!dna)
		return 1
	return dna.get_rw_tox_mult()

/mob/living/proc/get_rw_immunity_mult()
	return 1

/mob/living/carbon/get_rw_immunity_mult()
	return dna?.get_rw_immunity_mult() || 1

/mob/living/carbon/adjust_tox_loss(amount, updating_health = TRUE, forced = FALSE, required_biotype = ALL)
	if(!forced && amount > 0)
		amount *= get_rw_tox_mult()
	return ..()
