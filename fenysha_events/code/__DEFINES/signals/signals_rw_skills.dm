/// (skill_id, required_level) — return COMPONENT_RW_SKILL_CHECK_PASS if the holder meets the level.
#define COMSIG_RW_SKILL_CHECK "rw_skill_check"
	#define COMPONENT_RW_SKILL_CHECK_PASS (1<<0)

#define COMSIG_RW_SKILL_POINTS_CHANGED "rw_skill_points_changed" // skill_id, old_points, new_points, old_level, new_level
#define COMSIG_RW_SKILL_LEVEL_CHANGED "rw_skill_level_changed" // skill_id, old_level, new_level
