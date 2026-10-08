// --- Sources ---
#define RW_XENOGEN_SOURCE_INNATE (1<<0)
#define RW_XENOGEN_SOURCE_ACQUIRED (1<<1)

// --- Flags ---
#define RW_XENOGEN_PROCESSING (1<<2)
#define RW_XENOGEN_VISUAL (1<<3)

// --- Option kinds ---
#define RW_XENOGENE_OPTION_NONE "none"
#define RW_XENOGENE_OPTION_ACCESSORY "accessory"
#define RW_XENOGENE_OPTION_CHOICED "choiced"
#define RW_XENOGENE_OPTION_NUMERIC "numeric"
#define RW_XENOGENE_OPTION_TRICOLOR "tricolor"

// --- Categories ---
#define RW_XENOGENE_CATEGORY_COSMETIC "cosmetic"
#define RW_XENOGENE_CATEGORY_STAT "stat"
#define RW_XENOGENE_CATEGORY_ABILITY "ability"
#define RW_XENOGENE_CATEGORY_ARCHITE "archite"
#define RW_XENOGENE_CATEGORY_APTITUDE "aptitude"
#define RW_XENOGENE_CATEGORY_MOOD "mood"
#define RW_XENOGENE_CATEGORY_MOVEMENT "movement"
#define RW_XENOGENE_CATEGORY_TEMPERATURE "temperature"
#define RW_XENOGENE_CATEGORY_RESISTANCE "resistance"
#define RW_XENOGENE_CATEGORY_HEALING "healing"
#define RW_XENOGENE_CATEGORY_PSYCHIC "psychic"
#define RW_XENOGENE_CATEGORY_HEMOGEN "hemogen"
#define RW_XENOGENE_CATEGORY_MISC "misc"

// --- Incompatibility groups ---
#define RW_XENOGENE_GROUP_SKIN "skin"
#define RW_XENOGENE_GROUP_EYES "eyes"
#define RW_XENOGENE_GROUP_HAIR_STYLE "hair_style"
#define RW_XENOGENE_GROUP_BODY_TYPE "body_type"
#define RW_XENOGENE_GROUP_IMMUNITY "immunity"
#define RW_XENOGENE_GROUP_WOUND_HEALING "wound_healing"
#define RW_XENOGENE_GROUP_PSYCHIC_SENSITIVITY "psychic_sensitivity"
#define RW_XENOGENE_GROUP_MOVE_SPEED "move_speed"
#define RW_XENOGENE_GROUP_MOOD "mood"
#define RW_XENOGENE_GROUP_COLD "cold"
#define RW_XENOGENE_GROUP_HEAT "heat"
#define RW_XENOGENE_GROUP_TOX "tox"
#define RW_XENOGENE_GROUP_UV "uv"
#define RW_XENOGENE_GROUP_HEMOGEN_BASE "hemogen_base"
#define RW_XENOGENE_GROUP_APT_ANIMALS "apt_animals"
#define RW_XENOGENE_GROUP_APT_MELEE "apt_melee"
#define RW_XENOGENE_GROUP_APT_SHOOTING "apt_shooting"
#define RW_XENOGENE_GROUP_APT_CONSTRUCTION "apt_construction"
#define RW_XENOGENE_GROUP_APT_MINING "apt_mining"
#define RW_XENOGENE_GROUP_APT_COOKING "apt_cooking"
#define RW_XENOGENE_GROUP_APT_PLANTS "apt_plants"
#define RW_XENOGENE_GROUP_APT_SOCIAL "apt_social"
#define RW_XENOGENE_GROUP_APT_INTELLECTUAL "apt_intellectual"
#define RW_XENOGENE_GROUP_APT_CRAFTING "apt_crafting"

// --- Icons ---
/// Shared 64x64 xenogene sheet. Add a new state named after the gene id, then set ui_icon/icon_bg/icon_state on that datum.
#define RW_XENOGENE_ICONS 'fenysha_events/icons/rimworld/xenogenes.dmi'
#define RW_XENOGENE_ICON_FILE "fenysha_events/icons/rimworld/xenogenes.dmi"

// =============================================================================
// Gene IDs — Cosmetic
// =============================================================================
#define RW_XENOGENE_HAIR "hair"
#define RW_XENOGENE_SMOOTH_SKIN "smooth_skin"
#define RW_XENOGENE_SCALED_SKIN "scaled_skin"
#define RW_XENOGENE_HUMAN_EYES "human_eyes"
#define RW_XENOGENE_LIZARD_EYES "lizard_eyes"
#define RW_XENOGENE_AVALI_EYES "avali_eyes"
#define RW_XENOGENE_EARS "ears"
#define RW_XENOGENE_TAIL "tail"
#define RW_XENOGENE_WINGS "wings"
#define RW_XENOGENE_FLUFF "fluff"
#define RW_XENOGENE_LEGS "legs"
#define RW_XENOGENE_BODY_SIZE "body_size"
#define RW_XENOGENE_MUTANT_COLORS "mutant_colors"
#define RW_XENOGENE_SNOUT "snout"
#define RW_XENOGENE_HORNS "horns"
#define RW_XENOGENE_BODY_HULK "body_hulk"
#define RW_XENOGENE_BODY_FAT "body_fat"
#define RW_XENOGENE_BODY_THIN "body_thin"
#define RW_XENOGENE_BODY_STANDARD "body_standard"
#define RW_XENOGENE_NO_HAIR "no_hair"
#define RW_XENOGENE_SHORT_HAIR_ONLY "short_hair_only"
#define RW_XENOGENE_LONG_HAIR_ONLY "long_hair_only"

// =============================================================================
// Gene IDs — Stat / Misc body
// =============================================================================
#define RW_XENOGENE_COLD_BLOODED "cold_blooded"
#define RW_XENOGENE_FRAIL "frail"
#define RW_XENOGENE_DELICATE "delicate"
#define RW_XENOGENE_ROBUST "robust"
#define RW_XENOGENE_EXTRA_PAIN "extra_pain"
#define RW_XENOGENE_REDUCED_PAIN "reduced_pain"
#define RW_XENOGENE_STRONG_MELEE_DAMAGE "strong_melee_damage"
#define RW_XENOGENE_WEAK_MELEE_DAMAGE "weak_melee_damage"
#define RW_XENOGENE_NEARSIGHTED "nearsighted"
#define RW_XENOGENE_STRONG_STOMACH "strong_stomach"
#define RW_XENOGENE_ROBUST_DIGESTION "robust_digestion"
#define RW_XENOGENE_UNSTOPPABLE "unstoppable"
#define RW_XENOGENE_KILL_THIRST "kill_thirst"
#define RW_XENOGENE_VIOLENCE_DISABLED "violence_disabled"
#define RW_XENOGENE_DEAD_CALM "dead_calm"
#define RW_XENOGENE_INDOOR_DWELLER "indoor_dweller"
#define RW_XENOGENE_DARK_VISION "dark_vision"
#define RW_XENOGENE_TROTTER_HANDS "trotter_hands"
#define RW_XENOGENE_ELONGATED_FINGERS "elongated_fingers"

// =============================================================================
// Gene IDs — Archite
// =============================================================================
#define RW_XENOGENE_SCARLESS "scarless"
#define RW_XENOGENE_GENE_IMPLANTER "gene_implanter"
#define RW_XENOGENE_PERFECT_IMMUNITY "perfect_immunity"
#define RW_XENOGENE_NON_SENESCENT "non_senescent"
#define RW_XENOGENE_AGELESS "ageless"
#define RW_XENOGENE_DEATHLESS "deathless"
#define RW_XENOGENE_ARCHITE_METABOLISM "archite_metabolism"
#define RW_XENOGENE_BREATHLESS "breathless"

// =============================================================================
// Gene IDs — Ability
// =============================================================================
#define RW_XENOGENE_FIRE_SPEW "fire_spew"
#define RW_XENOGENE_FOAM_SPRAY "foam_spray"
#define RW_XENOGENE_ANIMAL_WARCALL "animal_warcall"
#define RW_XENOGENE_ACID_SPRAY "acid_spray"

// =============================================================================
// Gene IDs — Hemogen
// =============================================================================
#define RW_XENOGENE_HEMOGENIC "hemogenic"
#define RW_XENOGENE_BLOODFEEDER "bloodfeeder"
#define RW_XENOGENE_COAGULATE "coagulate"
#define RW_XENOGENE_DEATHREST "deathrest"
#define RW_XENOGENE_LONGJUMP_LEGS "longjump_legs"
#define RW_XENOGENE_PIERCING_SPINE "piercing_spine"
#define RW_XENOGENE_HEMOGEN_DRAIN "hemogen_drain"

// =============================================================================
// Gene IDs — Healing
// =============================================================================
#define RW_XENOGENE_WEAK_IMMUNITY "weak_immunity"
#define RW_XENOGENE_STRONG_IMMUNITY "strong_immunity"
#define RW_XENOGENE_SUPER_IMMUNITY "super_immunity"
#define RW_XENOGENE_SLOW_WOUND_HEALING "slow_wound_healing"
#define RW_XENOGENE_FAST_WOUND_HEALING "fast_wound_healing"
#define RW_XENOGENE_SUPERFAST_WOUND_HEALING "superfast_wound_healing"
#define RW_XENOGENE_SUPERCLOTTING "superclotting"

// =============================================================================
// Gene IDs — Psychic
// =============================================================================
#define RW_XENOGENE_PSYCHICALLY_DEAF "psychically_deaf"
#define RW_XENOGENE_PSYCHICALLY_DULL "psychically_dull"
#define RW_XENOGENE_PSY_SENSITIVE "psy_sensitive"
#define RW_XENOGENE_SUPER_PSY_SENSITIVE "super_psy_sensitive"
#define RW_XENOGENE_PSYCHIC_BONDING "psychic_bonding"

// =============================================================================
// Gene IDs — Movement
// =============================================================================
#define RW_XENOGENE_SLOW_RUNNER "slow_runner"
#define RW_XENOGENE_FAST_RUNNER "fast_runner"
#define RW_XENOGENE_VERY_FAST_RUNNER "very_fast_runner"
#define RW_XENOGENE_NAKED_SPEED "naked_speed"

// =============================================================================
// Gene IDs — Mood
// =============================================================================
#define RW_XENOGENE_VERY_UNHAPPY "very_unhappy"
#define RW_XENOGENE_UNHAPPY "unhappy"
#define RW_XENOGENE_HAPPY "happy"
#define RW_XENOGENE_VERY_HAPPY "very_happy"

// =============================================================================
// Gene IDs — Temperature
// =============================================================================
#define RW_XENOGENE_COLD_WEAKNESS "cold_weakness"
#define RW_XENOGENE_COLD_TOLERANT "cold_tolerant"
#define RW_XENOGENE_COLD_SUPER_TOLERANT "cold_super_tolerant"
#define RW_XENOGENE_HEAT_WEAKNESS "heat_weakness"
#define RW_XENOGENE_HEAT_TOLERANT "heat_tolerant"
#define RW_XENOGENE_HEAT_SUPER_TOLERANT "heat_super_tolerant"

// =============================================================================
// Gene IDs — Resistance
// =============================================================================
#define RW_XENOGENE_TOX_RESISTANCE "tox_resistance"
#define RW_XENOGENE_TOX_IMMUNITY "tox_immunity"
#define RW_XENOGENE_MILD_UV_SENSITIVITY "mild_uv_sensitivity"
#define RW_XENOGENE_INTENSE_UV_SENSITIVITY "intense_uv_sensitivity"
#define RW_XENOGENE_FIRE_RESISTANCE "fire_resistance"
#define RW_XENOGENE_FIRE_WEAKNESS "fire_weakness"
#define RW_XENOGENE_VACUUM_RESISTANT "vacuum_resistant"

// =============================================================================
// Gene IDs — Aptitude
// =============================================================================
#define RW_XENOGENE_AWFUL_ANIMALS "awful_animals"
#define RW_XENOGENE_POOR_ANIMALS "poor_animals"
#define RW_XENOGENE_STRONG_ANIMALS "strong_animals"
#define RW_XENOGENE_GREAT_ANIMALS "great_animals"
#define RW_XENOGENE_AWFUL_MELEE "awful_melee"
#define RW_XENOGENE_POOR_MELEE "poor_melee"
#define RW_XENOGENE_STRONG_MELEE "strong_melee"
#define RW_XENOGENE_GREAT_MELEE "great_melee"
#define RW_XENOGENE_AWFUL_SHOOTING "awful_shooting"
#define RW_XENOGENE_POOR_SHOOTING "poor_shooting"
#define RW_XENOGENE_STRONG_SHOOTING "strong_shooting"
#define RW_XENOGENE_GREAT_SHOOTING "great_shooting"
#define RW_XENOGENE_AWFUL_CONSTRUCTION "awful_construction"
#define RW_XENOGENE_GREAT_CONSTRUCTION "great_construction"
#define RW_XENOGENE_AWFUL_MINING "awful_mining"
#define RW_XENOGENE_GREAT_MINING "great_mining"
#define RW_XENOGENE_AWFUL_COOKING "awful_cooking"
#define RW_XENOGENE_AWFUL_PLANTS "awful_plants"
#define RW_XENOGENE_AWFUL_SOCIAL "awful_social"
#define RW_XENOGENE_GREAT_INTELLECTUAL "great_intellectual"
#define RW_XENOGENE_GREAT_CRAFTING "great_crafting"
