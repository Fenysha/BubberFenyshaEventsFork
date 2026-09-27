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

/*
 * Training XP.
 *
 * The XP cost of entering level N is:
 *
 *     RW_SKILL_XP_BASE * N^2
 *
 * This makes high levels substantially slower than low levels:
 *
 *     0 -> 1   100 XP
 *     1 -> 2   400 XP
 *     2 -> 3   900 XP
 *     ...
 *     19 -> 20 40000 XP
 *
 * 20 levels therefore require 287000 total XP.
 */
#define RW_SKILL_XP_BASE 100

/*
 * Generic training amounts.
 */
#define RW_SKILL_POINTS_NONE 0
#define RW_SKILL_POINTS_TINY 1
#define RW_SKILL_POINTS_SMALL 5
#define RW_SKILL_POINTS_MINOR 10
#define RW_SKILL_POINTS_NORMAL 25
#define RW_SKILL_POINTS_LARGE 50
#define RW_SKILL_POINTS_MAJOR 100
#define RW_SKILL_POINTS_HUGE 250
#define RW_SKILL_POINTS_MASSIVE 500

#define RW_SKILL_POINTS_TRAINING_SESSION 100

/*
 * Generic skill helpers.
 */
#define RW_GET_SKILL(target, skill_id) rw_get_skill(target, skill_id)
#define RW_GET_SKILL_POINTS(target, skill_id) rw_get_skill_points(target, skill_id)
#define RW_GET_SKILL_PROGRESS(target, skill_id) rw_get_skill_progress(target, skill_id)
#define RW_GET_SKILL_PROGRESS_PERCENT(target, skill_id) rw_get_skill_progress_percent(target, skill_id)
#define RW_GET_SKILL_POINTS_TO_NEXT_LEVEL(target, skill_id) rw_get_skill_points_to_next_level(target, skill_id)
#define RW_GET_SKILL_TITLE(target, skill_id) rw_get_target_skill_title(target, skill_id)

#define RW_HAS_SKILL(target, skill_id, level) rw_has_skill(target, skill_id, level)
#define RW_CAN_TRAIN_SKILL(target, skill_id) rw_can_train_skill(target, skill_id)

#define RW_ADD_SKILL_POINTS(target, skill_id, amount) rw_add_skill_points(target, skill_id, amount)
#define RW_TRAIN_SKILL(target, skill_id, amount) rw_train_skill(target, skill_id, amount)

/*
 * Skill rank/title table.
 *
 * Level 0 is intentionally "Unskilled".
 * Level 20 is the final "Planetary Master" rank.
 */
GLOBAL_LIST_INIT(rw_skill_titles, list(
	"Unskilled",          	// 0
	"Novice",             	// 1
	"Apprentice",         	// 2
	"Initiate",           	// 3
	"Competent",          	// 4
	"Skilled",             	// 5
	"Adept",              	// 6
	"Expert",              	// 7
	"Veteran",             	// 8
	"Professional",       	// 9
	"Master",              	// 10
	"Grandmaster",         	// 11
	"Elite",              	// 12
	"Renowned",            	// 13
	"Exceptional",         	// 14
	"Legendary",            // 15
	"Supreme",              // 16
	"Transcendent",         // 17
	"Mythic",               // 18
	"World Master",         // 19
	"Planetary Master"      // 20
))
