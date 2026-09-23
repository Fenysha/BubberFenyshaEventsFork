#define SUB_LEVEL_MIN_SIZE 8
#define SUB_LEVEL_MAX_SIZE 255
#define SUB_LEVEL_ROOT_SIZE 255

#define SUB_LEVEL_BL_TURF(res) (length(res?.bottom_left_turfs) ? res.bottom_left_turfs[1] : null)
#define SUB_LEVEL_TR_TURF(res) (length(res?.top_right_turfs) ? res.top_right_turfs[1] : null)
#define SUB_LEVEL_BR_TURF(res) (res?.get_bottom_right_turf())
#define SUB_LEVEL_TL_TURF(res) (res?.get_top_left_turf())

#define SUB_LEVEL_MIN_X(res) (SUB_LEVEL_BL_TURF(res)?.x || 0)
#define SUB_LEVEL_MIN_Y(res) (SUB_LEVEL_BL_TURF(res)?.y || 0)
#define SUB_LEVEL_MAX_X(res) (SUB_LEVEL_TR_TURF(res)?.x || 0)
#define SUB_LEVEL_MAX_Y(res) (SUB_LEVEL_TR_TURF(res)?.y || 0)
#define SUB_LEVEL_Z(res)     (SUB_LEVEL_BL_TURF(res)?.z || 0)

#define SUB_LEVEL_CONTAINS_XYZ(res, X, Y, Z) (res && (Z) == SUB_LEVEL_Z(res) && (X) >= SUB_LEVEL_MIN_X(res) && (X) <= SUB_LEVEL_MAX_X(res) && (Y) >= SUB_LEVEL_MIN_Y(res) && (Y) <= SUB_LEVEL_MAX_Y(res))
#define SUB_LEVEL_CONTAINS_TURF(res, T)      (T && SUB_LEVEL_CONTAINS_XYZ(res, T.x, T.y, T.z))
#define SUB_LEVEL_CONTAINS_ATOM(res, A)      (A && SUB_LEVEL_CONTAINS_TURF(res, get_turf(A)))

#define SUB_LEVEL_ALL_TURFS(res)    (res?.get_all_turfs())
#define SUB_LEVEL_INNER_TURFS(res)  (res?.get_inner_turfs())
#define SUB_LEVEL_CORDON_TURFS(res) (res?.get_cordon_turfs())


/**
 * ============================================================================
 * RimWorld sub-level geometry
 * ============================================================================
 */

#define RW_SUBLEVEL_ROOT_WIDTH 255
#define RW_SUBLEVEL_ROOT_HEIGHT 255

#define RW_SUBLEVEL_BORDER_SIZE 1

#define RW_SUBLEVEL_INNER_WIDTH 125
#define RW_SUBLEVEL_INNER_HEIGHT 125

#define RW_SUBLEVEL_SLOT_WIDTH 127
#define RW_SUBLEVEL_SLOT_HEIGHT 127


/**
 * ============================================================================
 * RimWorld sub-level loader budgets
 * ============================================================================
 */

#define RW_SUBLEVEL_RESERVE_BUDGET     160
#define RW_SUBLEVEL_PLACE_BUDGET       160
#define RW_SUBLEVEL_INITIALIZE_BUDGET  2048
#define RW_SUBLEVEL_POPULATE_BUDGET    320
#define RW_SUBLEVEL_LIGHTING_BUDGET    2048
#define RW_SUBLEVEL_DAYLIGHT_BUDGET    2048
#define RW_SUBLEVEL_SMOOTH_BUDGET      1024


/**
 * ============================================================================
 * Loader phases
 * ============================================================================
 */

#define RW_CELL_LOAD_CONTINUE 0
#define RW_CELL_LOAD_COMPLETE 1
#define RW_CELL_LOAD_FAILED   2

#define RW_CELL_JOB_PREPARE     1
#define RW_CELL_JOB_RESERVE     2
#define RW_CELL_JOB_PLACE       3
#define RW_CELL_JOB_INITIALIZE  4
#define RW_CELL_JOB_POPULATE    5
#define RW_CELL_JOB_SMOOTH      6
#define RW_CELL_JOB_LIGHTING    7
#define RW_CELL_JOB_DAYLIGHT    8
#define RW_CELL_JOB_FINISH      9
