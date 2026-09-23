#define RW_SKILL_RANGED "ranged"

#define RW_SKILL_MIN 0
#define RW_SKILL_MAX 20
#define RW_SKILL_MANUAL_MAX 10

#define RW_PASSION_NONE 0
#define RW_PASSION_INTERESTED 1
#define RW_PASSION_BURNING 2

#define RW_GET_SKILL(target, skill_id) rw_get_skill(target, skill_id)
#define RW_HAS_SKILL(target, skill_id, level) rw_has_skill(target, skill_id, level)
