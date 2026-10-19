/datum/rw_xenogene/stat/cold_blooded
	id = RW_XENOGENE_COLD_BLOODED
	name = "Cold-blooded"
	desc = "Poor internal temperature regulation. Hungrier in the cold."
	metabolic_efficiency = -1
	xenogen_flags = RW_XENOGEN_PROCESSING
	var/cold_hunger = 0.35

	incompatible_with = list(
		RW_XENOGENE_AVALI_BODY,
	)

	ui_icon = RW_XENOGENE_ICONS
	icon_state = "cold_blooded"

/datum/rw_xenogene/stat/body_size
	id = RW_XENOGENE_BODY_SIZE
	name = "Body size"
	desc = "Overall scale. Right-click to set a size."

	incompatible_with = list(
		RW_XENOGENE_AVALI_BODY,
	)

	xenogen_flags = RW_XENOGEN_VISUAL
	option_kind = RW_XENOGENE_OPTION_NUMERIC
	default_option = RESIZE_DEFAULT_SIZE
	option_min = BODY_SIZE_MIN
	option_max = BODY_SIZE_MAX
	option_step = 0.01
	value_pref_type = /datum/preference/numeric/body_size
	ui_icon = RW_XENOGENE_ICONS
	icon_state = "body_size"

/datum/rw_xenogene/stat/body_size/apply_to_preferences(datum/rimworld_preferences/prefs, enabled, value)
	if(!prefs || !value_pref_type)
		return
	prefs.rw_set_pref(value_pref_type, enabled ? sanitize_option(value) : RESIZE_DEFAULT_SIZE, force = TRUE)

/datum/rw_xenogene/stat/frail
	id = RW_XENOGENE_FRAIL
	name = "Frail"
	desc = "Weak constitution."
	negative = TRUE
	complexity = 1
	metabolic_efficiency = -1
	physiology_multipliers = list("maxhealth_mod" = 0.8, "brute_taken_mod" = 1.15)
	ui_icon = RW_XENOGENE_ICONS
	icon_state = "frail"

/datum/rw_xenogene/stat/delicate
	id = RW_XENOGENE_DELICATE
	name = "Delicate"
	desc = "Takes more damage from attacks."
	complexity = 1
	metabolic_efficiency = 1
	negative = TRUE
	physiology_multipliers = list("brute_taken_mod" = 1.3, "burn_taken_mod" = 1.3)
	ui_icon = RW_XENOGENE_ICONS
	icon_state = "delicate"

/datum/rw_xenogene/stat/robust
	id = RW_XENOGENE_ROBUST
	name = "Robust"
	desc = "Takes less damage from attacks."
	complexity = 1
	metabolic_efficiency = -1
	physiology_multipliers = list("brute_taken_mod" = 0.75, "burn_taken_mod" = 0.75)
	ui_icon = RW_XENOGENE_ICONS
	icon_state = "robust"

/datum/rw_xenogene/stat/extra_pain
	id = RW_XENOGENE_EXTRA_PAIN
	name = "Extra pain"
	desc = "Feels pain more intensely."
	complexity = 1
	metabolic_efficiency = 1
	negative = TRUE
	physiology_multipliers = list("pain_mod" = 1.5)
	ui_icon = RW_XENOGENE_ICONS
	icon_state = "extra_pain"

/datum/rw_xenogene/stat/reduced_pain
	id = RW_XENOGENE_REDUCED_PAIN
	name = "Reduced pain"
	desc = "Feels less pain."
	complexity = 1
	metabolic_efficiency = -1
	physiology_multipliers = list("pain_mod" = 0.55)
	ui_icon = RW_XENOGENE_ICONS
	icon_state = "reduced_pain"

/datum/rw_xenogene/stat/strong_melee_damage
	id = RW_XENOGENE_STRONG_MELEE_DAMAGE
	name = "Strong melee damage"
	desc = "Melee attacks deal more damage."
	complexity = 1
	metabolic_efficiency = -1
	physiology_multipliers = list("melee_damage_mod" = 1.3)
	ui_icon = RW_XENOGENE_ICONS
	icon_state = "strong_melee_damage"

/datum/rw_xenogene/stat/weak_melee_damage
	id = RW_XENOGENE_WEAK_MELEE_DAMAGE
	name = "Weak melee damage"
	desc = "Melee attacks deal less damage."
	complexity = 1
	metabolic_efficiency = 1
	negative = TRUE
	physiology_multipliers = list("melee_damage_mod" = 0.7)
	ui_icon = RW_XENOGENE_ICONS
	icon_state = "weak_melee_damage"

/datum/rw_xenogene/stat/nearsighted
	id = RW_XENOGENE_NEARSIGHTED
	name = "Nearsighted"
	desc = "Reduced ranged accuracy at distance."
	complexity = 1
	metabolic_efficiency = 1
	negative = TRUE
	physiology_multipliers = list("ranged_spread_mod" = 1.65)
	ui_icon = RW_XENOGENE_ICONS
	icon_state = "nearsighted"

/datum/rw_xenogene/stat/strong_stomach
	id = RW_XENOGENE_STRONG_STOMACH
	name = "Strong stomach"
	desc = "Never suffers food poisoning."
	complexity = 1
	metabolic_efficiency = 0
	ui_icon = RW_XENOGENE_ICONS
	icon_state = "strong_stomach"

/datum/rw_xenogene/stat/robust_digestion
	id = RW_XENOGENE_ROBUST_DIGESTION
	name = "Robust digestion"
	desc = "Gets full nutrition from raw food and doesn't mind the taste."
	complexity = 1
	metabolic_efficiency = 0
	var/raw_nutrition_bonus = 8
	ui_icon = RW_XENOGENE_ICONS
	icon_state = "robust_digestion"

/datum/rw_xenogene/stat/unstoppable
	id = RW_XENOGENE_UNSTOPPABLE
	name = "Unstoppable"
	desc = "Never goes into shock from pain."
	complexity = 1
	metabolic_efficiency = -1
	physiology_multipliers = list("shock_mod" = 0)
	ui_icon = RW_XENOGENE_ICONS
	icon_state = "unstoppable"

/datum/rw_xenogene/stat/kill_thirst
	id = RW_XENOGENE_KILL_THIRST
	name = "Kill thirst"
	desc = "Needs to kill periodically or suffers mood penalties."
	complexity = 1
	metabolic_efficiency = 0
	negative = TRUE
	xenogen_flags = RW_XENOGEN_PROCESSING
	var/last_kill_time = 0
	ui_icon = RW_XENOGENE_ICONS
	icon_state = "kill_thirst"

/datum/rw_xenogene/stat/violence_disabled
	id = RW_XENOGENE_VIOLENCE_DISABLED
	name = "Violence disabled"
	desc = "Cannot perform violent actions."
	complexity = 1
	metabolic_efficiency = 1
	negative = TRUE
	gameplay_traits = list(TRAIT_PACIFISM)
	ui_icon = RW_XENOGENE_ICONS
	icon_state = "violence_disabled"

/datum/rw_xenogene/stat/dead_calm
	id = RW_XENOGENE_DEAD_CALM
	name = "Dead calm"
	desc = "Never breaks from mental stress. Very hard to drive into a mental break."
	complexity = 1
	metabolic_efficiency = 0
	ui_icon = RW_XENOGENE_ICONS
	icon_state = "dead_calm"

/datum/rw_xenogene/stat/indoor_dweller
	id = RW_XENOGENE_INDOOR_DWELLER
	name = "Indoor dweller"
	desc = "Prefers to stay indoors. Outdoor work causes mood penalties."
	complexity = 1
	metabolic_efficiency = 0
	xenogen_flags = RW_XENOGEN_PROCESSING
	var/outdoor_mood = -8
	ui_icon = RW_XENOGENE_ICONS
	icon_state = "dead_calm"

/datum/rw_xenogene/stat/dark_vision
	id = RW_XENOGENE_DARK_VISION
	name = "Dark vision"
	desc = "Sees well in darkness."
	complexity = 1
	metabolic_efficiency = -1
	gameplay_traits = list(TRAIT_NIGHT_VISION)
	ui_icon = RW_XENOGENE_ICONS
	icon_state = "dark_vision"

/datum/rw_xenogene/stat/trotter_hands
	id = RW_XENOGENE_TROTTER_HANDS
	name = "Trotter hands"
	desc = "Reduced manipulation from pig-like hands."
	complexity = 1
	metabolic_efficiency = 1
	negative = TRUE
	physiology_multipliers = list("manipulation_mod" = 0.55)
	ui_icon = RW_XENOGENE_ICONS
	icon_state = "trotter_hands"

/datum/rw_xenogene/stat/elongated_fingers
	id = RW_XENOGENE_ELONGATED_FINGERS
	name = "Elongated fingers"
	desc = "Improved manipulation for fine work."
	complexity = 1
	metabolic_efficiency = -1
	physiology_multipliers = list("manipulation_mod" = 1.25)
	ui_icon = RW_XENOGENE_ICONS
	icon_state = "elongated_fingers"

/datum/rw_xenogene/stat/cold_blooded/on_life(seconds_per_tick, mob/living/new_holder)
	if(!iscarbon(new_holder))
		return
	var/mob/living/carbon/pawn = new_holder
	if(pawn.bodytemperature < T20C)
		pawn.rw_hunger = max(PSY_NEED_MIN, pawn.rw_hunger - cold_hunger * seconds_per_tick)

/datum/rw_xenogene/stat/kill_thirst/apply_gameplay(mob/living/target)
	. = ..()
	last_kill_time = world.time
	RegisterSignal(SSdcs, COMSIG_GLOB_MOB_DEATH, PROC_REF(on_kill_thirst_death))

/datum/rw_xenogene/stat/kill_thirst/clear_gameplay(mob/living/target)
	UnregisterSignal(SSdcs, COMSIG_GLOB_MOB_DEATH)
	target?.get_psychology()?.clear_factor("xenogene_killthirst")
	return ..()

/datum/rw_xenogene/stat/kill_thirst/proc/on_kill_thirst_death(datum/source, mob/living/died)
	SIGNAL_HANDLER
	if(!holder || died == holder || died.lastattacker != holder)
		return
	last_kill_time = world.time

/datum/rw_xenogene/stat/kill_thirst/on_life(seconds_per_tick, mob/living/new_holder)
	var/datum/psychology/psy = new_holder.get_psychology()
	var/elapsed = world.time - last_kill_time
	if(elapsed > 10 MINUTES)
		psy?.add_factor("xenogene_killthirst", id, -12, "Needs to kill.")
	else if(elapsed > 5 MINUTES)
		psy?.add_factor("xenogene_killthirst", id, -4, "Kill thirst is stirring.")
	else
		psy?.clear_factor("xenogene_killthirst")


/datum/rw_xenogene/stat/indoor_dweller/clear_gameplay(mob/living/target)
	target?.get_psychology()?.clear_factor("xenogene_indoor")
	return ..()

/datum/rw_xenogene/stat/indoor_dweller/on_life(seconds_per_tick, mob/living/new_holder)
	var/datum/psychology/psy = new_holder.get_psychology()
	var/area/A = get_area(new_holder)
	if(A && A.outdoors)
		psy?.add_factor("xenogene_indoor", id, outdoor_mood, "Outdoors (indoor dweller).")
	else
		psy?.clear_factor("xenogene_indoor")


/datum/rw_xenogene/stat/strong_stomach/apply_gameplay(mob/living/target)
	. = ..()
	RegisterSignal(target, COMSIG_LIVING_EAT_FOOD, PROC_REF(on_eat_food))

/datum/rw_xenogene/stat/strong_stomach/clear_gameplay(mob/living/target)
	if(target)
		UnregisterSignal(target, COMSIG_LIVING_EAT_FOOD)
	return ..()

/datum/rw_xenogene/stat/strong_stomach/proc/on_eat_food(mob/living/source, atom/food)
	SIGNAL_HANDLER
	addtimer(CALLBACK(src, PROC_REF(purge_eaten_toxins), source), 1)

/datum/rw_xenogene/stat/strong_stomach/proc/purge_eaten_toxins(mob/living/source)
	if(QDELETED(src) || !source?.reagents)
		return
	source.reagents.remove_reagent(/datum/reagent/toxin/bad_food, 50)

/datum/rw_xenogene/stat/robust_digestion/apply_gameplay(mob/living/target)
	. = ..()
	RegisterSignal(target, COMSIG_LIVING_EAT_FOOD, PROC_REF(on_eat_food))

/datum/rw_xenogene/stat/robust_digestion/clear_gameplay(mob/living/target)
	if(target)
		UnregisterSignal(target, COMSIG_LIVING_EAT_FOOD)
	return ..()

/datum/rw_xenogene/stat/robust_digestion/proc/on_eat_food(mob/living/source, atom/food)
	SIGNAL_HANDLER
	if(!istype(food, /obj/item/food))
		return
	var/obj/item/food/eaten = food
	if(!(eaten.foodtypes & RAW))
		return
	source.adjust_nutrition(raw_nutrition_bonus)
	if(iscarbon(source))
		var/mob/living/carbon/eater = source
		eater.rw_hunger = min(PSY_NEED_MAX, eater.rw_hunger + raw_nutrition_bonus * 2)
