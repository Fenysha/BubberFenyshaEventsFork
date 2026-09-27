#define RW_SKILL_RANGED "ranged"
#define RW_SKILL_MELEE "melee"
#define RW_SKILL_CONSTRUCTION "construction"
#define RW_SKILL_MINING "mining"
#define RW_SKILL_COOKING "cooking"
#define RW_SKILL_PLANTS "plants"
#define RW_SKILL_ANIMALS "animals"
#define RW_SKILL_CRAFTING "crafting"
#define RW_SKILL_ARTISTIC "artistic"
#define RW_SKILL_MEDICAL "medical"
#define RW_SKILL_SOCIAL "social"
#define RW_SKILL_INTELLECTUAL "intellectual"

/// UI order, shooting through intellectual.
#define RW_SKILL_ORDER_RANGED 1
#define RW_SKILL_ORDER_MELEE 2
#define RW_SKILL_ORDER_CONSTRUCTION 3
#define RW_SKILL_ORDER_MINING 4
#define RW_SKILL_ORDER_COOKING 5
#define RW_SKILL_ORDER_PLANTS 6
#define RW_SKILL_ORDER_ANIMALS 7
#define RW_SKILL_ORDER_CRAFTING 8
#define RW_SKILL_ORDER_ARTISTIC 9
#define RW_SKILL_ORDER_MEDICAL 10
#define RW_SKILL_ORDER_SOCIAL 11
#define RW_SKILL_ORDER_INTELLECTUAL 12

#define RW_SKILL_MIN 0
#define RW_SKILL_MAX 20
#define RW_SKILL_MANUAL_MAX 10

#define RW_PASSION_NONE 0
#define RW_PASSION_INTERESTED 1
#define RW_PASSION_BURNING 2

#define RW_GET_SKILL(target, skill_id) rw_get_skill(target, skill_id)
#define RW_HAS_SKILL(target, skill_id, level) rw_has_skill(target, skill_id, level)
