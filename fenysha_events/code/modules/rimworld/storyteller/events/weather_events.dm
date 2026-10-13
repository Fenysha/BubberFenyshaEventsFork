/// Positive local incident: the current weather clears.
/datum/storyteller_event/clear_skies
	id = "clear_skies"
	name = "Clear skies"
	description = "The current weather front dissipates over this planet cell."
	category = STORY_EVENT_GOOD

/datum/storyteller_event/clear_skies/is_available(datum/planet_cell/cell, datum/storyteller/storyteller)
	return ..() && cell.weather_type != "clear"

/datum/storyteller_event/clear_skies/execute(datum/planet_cell/cell, datum/storyteller/storyteller, difficulty)
	if(!cell || !cell.is_loaded())
		return FALSE
	var/success = cell.start_cell_weather("clear", 0, 5 MINUTES)
	if(success)
		log_storyteller("Clear skies started in [cell.get_name()] ([cell.id]).")
	return success

/// Neutral local incident: a bank of fog crosses the cell.
/datum/storyteller_event/fog_bank
	id = "fog_bank"
	name = "Fog bank"
	description = "A dense fog bank moves through the cell for a short time."
	category = STORY_EVENT_NEUTRAL

/datum/storyteller_event/fog_bank/is_available(datum/planet_cell/cell, datum/storyteller/storyteller)
	return ..() && cell.weather_type != "fog" && cell.get_biome() != RW_BIOME_OCEAN

/datum/storyteller_event/fog_bank/execute(datum/planet_cell/cell, datum/storyteller/storyteller, difficulty)
	if(!cell || !cell.is_loaded())
		return FALSE
	var/success = cell.start_cell_weather(RW_WEATHER_FOG, 0.55, 5 MINUTES)
	if(success)
		log_storyteller("Fog bank started in [cell.get_name()] ([cell.id]).")
	return success

/// Negative local incident: a storm is forced for one cell only.
/datum/storyteller_event/storm_front
	id = "storm_front"
	name = "Storm front"
	description = "A strong local storm develops over the cell."
	category = STORY_EVENT_BAD

/datum/storyteller_event/storm_front/is_available(datum/planet_cell/cell, datum/storyteller/storyteller)
	return ..() && cell.weather_type != RW_WEATHER_STORM

/datum/storyteller_event/storm_front/execute(datum/planet_cell/cell, datum/storyteller/storyteller, difficulty)
	if(!cell || !cell.is_loaded())
		return FALSE
	var/weather_id = RW_WEATHER_STORM
	if(cell.get_outdoor_temperature() <= 0)
		weather_id = RW_WEATHER_SNOW
	else if(cell.get_biome() == RW_BIOME_DESERT)
		weather_id = RW_WEATHER_ASH
	var/success = cell.start_cell_weather(weather_id, 0.8, 8 MINUTES)
	if(success)
		log_storyteller("Storm front ([weather_id]) started in [cell.get_name()] ([cell.id]).")
	return success

/// Major environmental incident. It is independent of faction systems.
/datum/storyteller_event/severe_weather
	id = "severe_weather"
	name = "Severe weather"
	description = "A dangerous weather system briefly overwhelms local conditions."
	category = STORY_EVENT_MAJOR

/datum/storyteller_event/severe_weather/is_available(datum/planet_cell/cell, datum/storyteller/storyteller)
	return ..() && cell.weather_type != RW_WEATHER_STORM && cell.weather_type != RW_WEATHER_SNOW && cell.weather_type != RW_WEATHER_ASH

/datum/storyteller_event/severe_weather/execute(datum/planet_cell/cell, datum/storyteller/storyteller, difficulty)
	if(!cell || !cell.is_loaded())
		return FALSE
	var/weather_id = RW_WEATHER_STORM
	if(cell.get_outdoor_temperature() <= 0)
		weather_id = RW_WEATHER_SNOW
	else if(cell.get_biome() == RW_BIOME_DESERT)
		weather_id = RW_WEATHER_ASH
	var/success = cell.start_cell_weather(weather_id, 1, 12 MINUTES)
	if(success)
		log_storyteller("Severe weather ([weather_id]) started in [cell.get_name()] ([cell.id]).")
	return success
