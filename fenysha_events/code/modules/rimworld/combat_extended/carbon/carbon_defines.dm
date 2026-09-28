/mob/living/carbon
	/// Все активные /datum/injury на всех конечностях этого моба
	var/list/all_injuries

	/// Текущая суммарная боль (0 - PAIN_MAX)
	var/pain = 0
	/// Текущий уровень болевого шока (0 - SHOCK_MAX)
	var/shock = 0
	/// Текущий уровень сознания (0 - CONSCIOUSNESS_MAX)
	var/consciousness = CONSCIOUSNESS_MAX

	/// Кэшированная суммарная скорость кровопотери со всех конечностей
	var/total_bleed_rate = 0

	var/datum/health_ui/health_ui


/mob/living/carbon/Initialize(mapload)
	. = ..()
	health_ui = new(src)


/mob/living/carbon/Destroy()
	QDEL_NULL(health_ui)
	return ..()


/**
 * Opens the detailed health panel for the user.
 */
/mob/living/carbon/proc/open_health_ui(mob/user)
	if(!health_ui)
		health_ui = new(src)
	health_ui.ui_interact(user)
