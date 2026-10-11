/mob/living/carbon/human
	/// Base comfort range of the unclothed body. Species / genes can adjust these.
	var/rw_base_comfort_min = 16
	var/rw_base_comfort_max = 26
	/// Extra degrees from traits / xenogenes. Negative = more tolerant of cold.
	var/rw_cold_tolerance_bonus = 0
	var/rw_heat_tolerance_bonus = 0

	/// Cached result of get_rw_comfort_range(); rebuilt when equipment changes.
	var/list/rw_comfort_cache
	var/rw_comfort_cache_time = -999

	/// Seconds of continuous deep cold per limb zone.
	var/list/rw_frost_exposure
	var/rw_last_thermal_stage = 0
	var/rw_thermal_message_cd = 0
