/**
 * Rimworld skill singleton.
 *
 * This is the definition of a skill, not the actual skill state.
 * Actual levels and XP are stored by /datum/component/rw_skills.
 */
/datum/rw_skill
	abstract_type = /datum/rw_skill

	var/id
	var/name = "Skill"
	var/desc = "A colonist skill."

	/// UI ordering.
	var/sort_order = 100

	/// FALSE until the skill has actual gameplay.
	var/editable = FALSE


/**
 * Called whenever the holder's skill XP changes.
 *
 * old_points/new_points are total cumulative XP.
 */
/datum/rw_skill/proc/on_points_changed(atom/holder, old_points, new_points)
	return


/**
 * Called whenever the holder's skill level changes.
 *
 */
/datum/rw_skill/proc/on_level_changed(atom/holder, old_level, new_level)
	return


/proc/cmp_rw_skill_ui_order(list/a, list/b)
	return a["sortOrder"] - b["sortOrder"]
