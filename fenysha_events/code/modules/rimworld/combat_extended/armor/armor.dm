/datum/armor
	/// Sharp protection (mm RHA)
	VAR_PROTECTED/sharp = 0
	/// Blunt protection (MPa)
	VAR_PROTECTED/blunt = 0

/datum/armor/proc/get_sharp_rating()
	if(sharp)
		return sharp
	return max(bullet * 0.1, melee * 0.05)

/datum/armor/proc/get_blunt_rating()
	if(blunt)
		return blunt
	return max(melee * 0.08, bomb * 0.05)

/// Returns a readable armor type name.
/armor_to_protection_name(armor_type)
	switch(armor_type)
		if(ACID)
			return "ACID"
		if(BIO)
			return "BIOHAZARD"
		if(BOMB)
			return "EXPLOSIVE"
		if(BULLET)
			return "BULLET"
		if(CONSUME)
			return "CONSUMING"
		if(ENERGY)
			return "ENERGY"
		if(FIRE)
			return "FIRE"
		if(LASER)
			return "LASER"
		if(MELEE)
			return "MELEE"
		if(WOUND)
			return "WOUNDING"
		if(SHARP)
			return "SHARP"
		if(BLUNT)
			return "BLUNT"
	CRASH("Unknown armor type '[armor_type]'")
