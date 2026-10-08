/// Shared melee movement penalties and hit-resolution tuning.
#define RW_MELEE_SLOWDOWN 1
#define RW_MELEE_SLOWDOWN_MAX 3
#define RW_MELEE_SLOWDOWN_DURATION (3 SECONDS)

// === Miss / Accuracy ===
#define MELEE_MISS_BASE 8
#define MELEE_MISS_PER_SKILL_DIFF 1.5
#define MELEE_MISS_MIN 2
#define MELEE_MISS_MAX 65

#define MELEE_ZONE_HIT_BASE 80
#define MELEE_ZONE_HIT_PER_SKILL 1.5

/// Skill impact on unarmed misses; condition/capacity should dominate over skill.
#define UNARMED_MISS_PER_SKILL_DIFF 1.5
