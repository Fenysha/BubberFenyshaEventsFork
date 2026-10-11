/obj/item/clothing/proc/get_rw_cold_insulation()
	if(!isnull(rw_cold_insulation))
		return rw_cold_insulation
	// Derive from vanilla: lower min_cold_protection_temperature = warmer.
	if(!min_cold_protection_temperature || !cold_protection)
		return 0
	var/c = RW_TO_C(min_cold_protection_temperature)
	if(c <= -100)
		return 90
	if(c <= -20)
		return 55
	if(c <= 0)
		return 35
	if(c <= 10)
		return 20
	return 10

/obj/item/clothing/proc/get_rw_heat_insulation()
	if(!isnull(rw_heat_insulation))
		return rw_heat_insulation
	if(!max_heat_protection_temperature || !heat_protection)
		return 0
	var/c = RW_TO_C(max_heat_protection_temperature)
	if(c >= 1000)
		return 80
	if(c >= 200)
		return 50
	if(c >= 100)
		return 30
	if(c >= 50)
		return 15
	return 5
