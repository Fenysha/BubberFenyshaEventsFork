#ifndef OLD_COMBAT_SYSTEM
/datum/injury/malnutrition
	name = "Malnutrition"
	undiagnosed_name = "malnutrition"
	desc = "Prolonged starvation has weakened the body."
	examine_desc = "shows signs of severe malnutrition"
	series = "malnutrition"
	severity = INJURY_SEVERITY_SEVERE
	injury_flags = INJURY_FLAG_INTERNAL

/datum/injury/malnutrition/get_initial_shock()
	return 0

/datum/injury/malnutrition/get_initial_consciousness_impact()
	return 0
#endif
