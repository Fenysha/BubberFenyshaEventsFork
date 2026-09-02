/// The looping sound datum but we check for prefs and use `conditional_pref_sound` instead of `playsound`
/datum/looping_sound/lewd
	/// What preference are we going to check with our looping sound when we play it for people?
	var/pref_to_check = /datum/preference/toggle/erp/sex_toy_sounds

/datum/looping_sound/lewd/play(soundfile, volume_override)
	var/sound/sound_to_play = sound(soundfile)
	if(direct)
		sound_to_play.channel = sound_channel || SSsounds.random_available_channel()
		sound_to_play.volume = volume_override || volume //Use volume as fallback if theres no override
		SEND_SOUND(parent, sound_to_play)
		return

	conditional_pref_sound(
		parent,
		sound_to_play,
		volume,
		vary,
		extra_range,
		falloff_exponent = falloff_exponent,
		pressure_affected = pressure_affected,
		falloff_distance = falloff_distance,
		use_reverb = use_reverb,
		ignore_walls = FALSE,
		pref_to_check = pref_to_check
	)
