#define RW_RECEPIE_CATEGORY_WOODWORK 	"rw_woodwork"


#define RW_ARCHITECT_TAB_STRUCTURE		"Structure"
#define RW_ARCHITECT_TAB_FURNITURE		"Furniture"
#define RW_ARCHITECT_TAB_PRODUCTION		"Production"
#define RW_ARCHITECT_TAB_POWER			"Power"
#define RW_ARCHITECT_TAB_SECURITY		"Security"
#define RW_ARCHITECT_TAB_MISC			"Misc"

#define RW_ARCHITECT_TABS list(\
	RW_ARCHITECT_TAB_STRUCTURE,\
	RW_ARCHITECT_TAB_FURNITURE,\
	RW_ARCHITECT_TAB_PRODUCTION,\
	RW_ARCHITECT_TAB_POWER,\
	RW_ARCHITECT_TAB_SECURITY,\
	RW_ARCHITECT_TAB_MISC\
)

#define RW_SITE_HOLOGRAM 0
#define RW_SITE_FRAME 1

#define RW_HOLOGRAM_ALPHA 130

#define RW_BUILD_MODE_PLACE		"place"
#define RW_BUILD_MODE_FILL		"fill"
#define RW_BUILD_MODE_CANCEL	"cancel"

#define RW_BUILD_SWITCH_NONE	0
#define RW_BUILD_SWITCH_MODE	1
#define RW_BUILD_SWITCH_DIR		2


/// Bring all ingredients to the bench, then one timed craft starts.
#define RW_CRAFT_TYPE_DELIVER		"deliver"
/// Ingredients are absorbed into a workpiece which is then worked on step by step.
#define RW_CRAFT_TYPE_WORKPIECE		"workpiece"

#define RW_JOB_COLLECTING	0
#define RW_JOB_READY		1
#define RW_JOB_WORKPIECE	2

/// Scale of ingredient overlays lying on the workbench.
#define RW_CRAFT_OVERLAY_SCALE	0.75
/// Y offset (pixels) of the workpiece on top of the bench.
#define RW_WORKPIECE_PIXEL_Y	8

#define RW_PLAN_COLOR_OK		"#4987e4"
#define RW_PLAN_COLOR_BAD		"#fa4444"
#define RW_PLAN_COLOR_NO_RES	"#e0a030"
#define RW_PLAN_COLOR_ADMIN		"#b46cff"
