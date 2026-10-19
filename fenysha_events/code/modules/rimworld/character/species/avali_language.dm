/// Avali Scratch is canonically the Avali WRITING system (spoken Avali is "Core-H"); no official phonology
/// exists, so the syllables below are a placeholder chirp-and-click set. Replace freely.
/datum/language/avali_scratch
	name = "Avali Scratch"
	desc = "The tongue of the Avali: quick chirps and clicks, written as scratches on ice and stone. Pack calls carry across long distances."
	key = "K"
	space_chance = 45
	syllables = list(
		"ka", "ki", "ke", "kri", "kree", "tik", "tak", "tek", "chi", "cha",
		"chee", "rr", "rrk", "ik", "ak", "ek", "tri", "tre", "sk", "skri",
		"ch", "pi", "pa", "pik", "pak", "li", "la", "lik", "ee", "ii",
	)
	icon = 'modular_skyrat/master_files/icons/misc/language.dmi'
	icon_state = "avali_scratch"
	default_priority = 90

/datum/language_holder/avali
	understood_languages = list(
		/datum/language/common = list(LANGUAGE_ATOM),
		/datum/language/avali_scratch = list(LANGUAGE_ATOM),
	)
	spoken_languages = list(
		/datum/language/common = list(LANGUAGE_ATOM),
		/datum/language/avali_scratch = list(LANGUAGE_ATOM),
	)

/datum/language/avali_scratch/get_random_name(
	gender = NEUTER,
	name_count = default_name_count,
	syllable_min = default_name_syllable_min,
	syllable_max = default_name_syllable_max,
	force_use_syllables = FALSE,
)
	if(force_use_syllables)
		return ..()

	var/newname = ""
	for(var/i in 1 to rand(2, 3))
		newname += pick(list("chi", "chu", "ka", "ki", "kyo", "ko", "la", "li", "mi", "ni", "nu", "nyu", "se", "ri", "ro", "ru", "ryu", "sa", "si", "syo"))
	return capitalize(newname)
