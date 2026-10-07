/datum/injury/proc/get_ui_data()
	var/has_treatments = length(treatable_by) || length(treatable_tools)
	return list(
		"id" = unique_id,
		"name" = name,
		"undiagnosed_name" = undiagnosed_name || name,
		"severity" = severity,
		"severity_text" = severity_text(),
		"desc" = desc,
		"examine_desc" = examine_desc,
		"bleed_rate" = get_bleed_rate(),
		"pain" = get_pain(),
		"disabling" = !!disabling,
		"can_treat" = has_treatments && treatment_quality < INJURY_TREATMENT_EXCELLENT,
		"series" = series,
		"treatment_quality" = treatment_quality,
		"treatment_effectiveness" = treatment_effectiveness,
		"healing_progress" = healing_progress,
		"treated" = treatment_quality > INJURY_TREATMENT_NONE,
	)

/datum/injury/proc/severity_text()
	switch(severity)
		if(INJURY_SEVERITY_MINOR)
			return "Minor"
		if(INJURY_SEVERITY_MODERATE)
			return "Moderate"
		if(INJURY_SEVERITY_SEVERE)
			return "Severe"
		if(INJURY_SEVERITY_CRITICAL)
			return "Critical"
		if(INJURY_SEVERITY_LOSS)
			return "Loss"
	return "Unknown"

/datum/injury/proc/treatment_text()
	switch(treatment_quality)
		if(INJURY_TREATMENT_NONE)
			return "Untreated"
		if(INJURY_TREATMENT_POOR)
			return "Poorly treated"
		if(INJURY_TREATMENT_ADEQUATE)
			return "Treated"
		if(INJURY_TREATMENT_EXCELLENT)
			return "Expertly treated"
	return "Unknown"

/datum/injury/proc/get_examine_text(mob/user)
	if(!owner || !limb)
		return null
	return "[owner.p_Their()] [limb.plaintext_zone] [examine_desc]."

/datum/injury/proc/get_self_examine_text(self_aware = FALSE)
	var/shown_name = (self_aware || !undiagnosed_name) ? name : undiagnosed_name
	var/status = ""
	if(treatment_quality > INJURY_TREATMENT_NONE)
		status = " ([treatment_text()])"
	if(healing_progress > 0.05)
		status += " — healing ([round(healing_progress * 100)]%)"
	return "It's suffering from [shown_name][status]."

/datum/injury/proc/get_scanner_data(mob/user)
	return list(
		"name" = name,
		"severity" = severity_text(),
		"description" = desc,
		"treatment" = get_treatment_text(),
		"treatment_quality" = treatment_text(),
		"healing_progress" = round(healing_progress * 100),
		"bleed_rate" = get_bleed_rate(),
		"pain" = get_pain(),
	)

/datum/injury/proc/get_treatment_text()
	if(treatment_quality >= INJURY_TREATMENT_EXCELLENT)
		return "Already optimally treated."
	if(treatable_by || treatable_tools)
		return "Can be treated with appropriate medical supplies."
	return "See a doctor."

/datum/injury/proc/show_application_message()
	if(!owner || !limb)
		return
	owner.visible_message(
		span_danger("[owner]'s [limb.plaintext_zone] [occur_text()]!"),
		span_userdanger("Your [limb.plaintext_zone] [occur_text()]!"),
	)

/datum/injury/proc/can_be_seen_by(mob/user)
	if(!user || !owner)
		return FALSE

	if(user == owner)
		return visibility > INJURY_VISIBILITY_NONE

	if(isobserver(user) || HAS_TRAIT(user, TRAIT_VIEW_FULL_HEALTH))
		return visibility > INJURY_VISIBILITY_NONE

	if(injury_flags & INJURY_FLAG_EXTERNAL)
		return TRUE

	if(visibility >= INJURY_VISIBILITY_MEDICAL)
		return TRUE

	return FALSE

/datum/injury/proc/severity_to_text()
	switch(severity)
		if(INJURY_SEVERITY_MINOR)
			return "minor"
		if(INJURY_SEVERITY_MODERATE)
			return "moderate"
		if(INJURY_SEVERITY_SEVERE)
			return "severe"
		if(INJURY_SEVERITY_CRITICAL)
			return "critical"
		if(INJURY_SEVERITY_LOSS)
			return "loss"
	return "unknown"

/datum/injury/proc/occur_text()
	return "is injured"
