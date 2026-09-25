#define RW_XENOGEN_SOURCE_INNATE (1<<0)
#define RW_XENOGEN_SOURCE_ACQUIRED (1<<1)

#define RW_XENOGEN_PROCESSING (1<<2)
#define RW_XENOGEN_VISUAL (1<<3)

#define RW_XENOGENE_OPTION_NONE "none"
#define RW_XENOGENE_OPTION_ACCESSORY "accessory"
#define RW_XENOGENE_OPTION_CHOICED "choiced"
#define RW_XENOGENE_OPTION_NUMERIC "numeric"
#define RW_XENOGENE_OPTION_TRICOLOR "tricolor"

#define RW_XENOGENE_HAIR "hair"
#define RW_XENOGENE_SMOOTH_SKIN "smooth_skin"
#define RW_XENOGENE_SCALED_SKIN "scaled_skin"
#define RW_XENOGENE_HUMAN_EYES "human_eyes"
#define RW_XENOGENE_LIZARD_EYES "lizard_eyes"
#define RW_XENOGENE_AVALI_EYES "avali_eyes"
#define RW_XENOGENE_COLD_BLOODED "cold_blooded"
#define RW_XENOGENE_FRAIL "frail"

#define RW_XENOGENE_EARS "ears"
#define RW_XENOGENE_TAIL "tail"
#define RW_XENOGENE_WINGS "wings"
#define RW_XENOGENE_FLUFF "fluff"
#define RW_XENOGENE_LEGS "legs"
#define RW_XENOGENE_BODY_SIZE "body_size"
#define RW_XENOGENE_MUTANT_COLORS "mutant_colors"
#define RW_XENOGENE_SNOUT "snout"
#define RW_XENOGENE_HORNS "horns"

#define RW_XENOGENE_CATEGORY_COSMETIC "cosmetic"
#define RW_XENOGENE_CATEGORY_STAT "stat"
#define RW_XENOGENE_CATEGORY_ABILITY "ability"

/// Genes that share a group cannot be on the same pawn. Prefer this over listing every pair.
#define RW_XENOGENE_GROUP_SKIN "skin"
#define RW_XENOGENE_GROUP_EYES "eyes"

/// Shared 64x64 xenogene sheet. Add a new state named after the gene id, then set ui_icon/icon_bg/icon_state on that datum.
#define RW_XENOGENE_ICONS 'fenysha_events/icons/rimworld/xenogenes.dmi'
#define RW_XENOGENE_ICON_FILE "fenysha_events/icons/rimworld/xenogenes.dmi"
