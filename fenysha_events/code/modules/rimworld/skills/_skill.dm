/**
 * Rimworld skill singleton. Not /datum/skill — those live on mind and are a different system.
 * Handlers for actions; the component stores per-mob levels.
 */
/datum/rw_skill
	abstract_type = /datum/rw_skill
	var/id
	var/name = "Skill"
	var/desc = "A colonist skill."
	/// 1..n. Shooting is 1, intellectual is last. The editor sorts by this.
	var/sort_order = 100
	/// FALSE until the skill has gameplay. Editor rows stay disabled.
	var/editable = FALSE

/datum/rw_skill/proc/on_level_changed(atom/holder, old_level, new_level)
	return

/proc/cmp_rw_skill_ui_order(list/a, list/b)
	return a["sortOrder"] - b["sortOrder"]
