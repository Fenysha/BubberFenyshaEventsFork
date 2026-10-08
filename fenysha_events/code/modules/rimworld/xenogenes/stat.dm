/datum/rw_xenogene/stat/cold_blooded
	id = RW_XENOGENE_COLD_BLOODED
	name = "Cold-blooded"
	desc = "Poor internal temperature regulation. Hungrier in the cold."
	metabolic_efficiency = -1
	xenogen_flags = RW_XENOGEN_PROCESSING
	cold_hunger = 0.35

/datum/rw_xenogene/stat/body_size
	id = RW_XENOGENE_BODY_SIZE
	name = "Body size"
	desc = "Overall scale. Right-click to set a size."
	xenogen_flags = RW_XENOGEN_VISUAL
	option_kind = RW_XENOGENE_OPTION_NUMERIC
	default_option = RESIZE_DEFAULT_SIZE
	option_min = BODY_SIZE_MIN
	option_max = BODY_SIZE_MAX
	option_step = 0.01
	value_pref_type = /datum/preference/numeric/body_size

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
	maxhealth_mult = 0.8
	brute_taken_mult = 1.15

/datum/rw_xenogene/stat/delicate
	id = RW_XENOGENE_DELICATE
	name = "Delicate"
	desc = "Takes more damage from attacks."
	complexity = 1
	metabolic_efficiency = 1
	negative = TRUE
	brute_taken_mult = 1.3
	burn_taken_mult = 1.3

/datum/rw_xenogene/stat/robust
	id = RW_XENOGENE_ROBUST
	name = "Robust"
	desc = "Takes less damage from attacks."
	complexity = 1
	metabolic_efficiency = -1
	brute_taken_mult = 0.75
	burn_taken_mult = 0.75

/datum/rw_xenogene/stat/extra_pain
	id = RW_XENOGENE_EXTRA_PAIN
	name = "Extra pain"
	desc = "Feels pain more intensely."
	complexity = 1
	metabolic_efficiency = 1
	negative = TRUE
	pain_mult = 1.5

/datum/rw_xenogene/stat/reduced_pain
	id = RW_XENOGENE_REDUCED_PAIN
	name = "Reduced pain"
	desc = "Feels less pain."
	complexity = 1
	metabolic_efficiency = -1
	pain_mult = 0.55

/datum/rw_xenogene/stat/strong_melee_damage
	id = RW_XENOGENE_STRONG_MELEE_DAMAGE
	name = "Strong melee damage"
	desc = "Melee attacks deal more damage."
	complexity = 1
	metabolic_efficiency = -1
	melee_damage_mult = 1.3

/datum/rw_xenogene/stat/weak_melee_damage
	id = RW_XENOGENE_WEAK_MELEE_DAMAGE
	name = "Weak melee damage"
	desc = "Melee attacks deal less damage."
	complexity = 1
	metabolic_efficiency = 1
	negative = TRUE
	melee_damage_mult = 0.7

/datum/rw_xenogene/stat/nearsighted
	id = RW_XENOGENE_NEARSIGHTED
	name = "Nearsighted"
	desc = "Reduced ranged accuracy at distance."
	complexity = 1
	metabolic_efficiency = 1
	negative = TRUE
	ranged_spread_mult = 1.65

/datum/rw_xenogene/stat/strong_stomach
	id = RW_XENOGENE_STRONG_STOMACH
	name = "Strong stomach"
	desc = "Never suffers food poisoning."
	complexity = 1
	metabolic_efficiency = 0
	purges_food_toxins = TRUE

/datum/rw_xenogene/stat/robust_digestion
	id = RW_XENOGENE_ROBUST_DIGESTION
	name = "Robust digestion"
	desc = "Gets full nutrition from raw food and doesn't mind the taste."
	complexity = 1
	metabolic_efficiency = 0
	raw_nutrition_bonus = 8

/datum/rw_xenogene/stat/unstoppable
	id = RW_XENOGENE_UNSTOPPABLE
	name = "Unstoppable"
	desc = "Never goes into shock from pain."
	complexity = 1
	metabolic_efficiency = -1
	shock_mult = 0

/datum/rw_xenogene/stat/kill_thirst
	id = RW_XENOGENE_KILL_THIRST
	name = "Kill thirst"
	desc = "Needs to kill periodically or suffers mood penalties."
	complexity = 1
	metabolic_efficiency = 0
	negative = TRUE
	xenogen_flags = RW_XENOGEN_PROCESSING
	tracks_kill_thirst = TRUE

/datum/rw_xenogene/stat/violence_disabled
	id = RW_XENOGENE_VIOLENCE_DISABLED
	name = "Violence disabled"
	desc = "Cannot perform violent actions."
	complexity = 1
	metabolic_efficiency = 1
	negative = TRUE
	gameplay_traits = list(TRAIT_PACIFISM)

/datum/rw_xenogene/stat/dead_calm
	id = RW_XENOGENE_DEAD_CALM
	name = "Dead calm"
	desc = "Never breaks from mental stress. Very hard to drive into a mental break."
	complexity = 1
	metabolic_efficiency = 0
	prevents_mental_breaks = TRUE

/datum/rw_xenogene/stat/indoor_dweller
	id = RW_XENOGENE_INDOOR_DWELLER
	name = "Indoor dweller"
	desc = "Prefers to stay indoors. Outdoor work causes mood penalties."
	complexity = 1
	metabolic_efficiency = 0
	xenogen_flags = RW_XENOGEN_PROCESSING
	outdoor_mood = -8

/datum/rw_xenogene/stat/dark_vision
	id = RW_XENOGENE_DARK_VISION
	name = "Dark vision"
	desc = "Sees well in darkness."
	complexity = 1
	metabolic_efficiency = -1
	gameplay_traits = list(TRAIT_NIGHT_VISION)

/datum/rw_xenogene/stat/trotter_hands
	id = RW_XENOGENE_TROTTER_HANDS
	name = "Trotter hands"
	desc = "Reduced manipulation from pig-like hands."
	complexity = 1
	metabolic_efficiency = 1
	negative = TRUE
	manipulation_mult = 0.55

/datum/rw_xenogene/stat/elongated_fingers
	id = RW_XENOGENE_ELONGATED_FINGERS
	name = "Elongated fingers"
	desc = "Improved manipulation for fine work."
	complexity = 1
	metabolic_efficiency = -1
	manipulation_mult = 1.25
