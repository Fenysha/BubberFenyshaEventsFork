// Psychology / mental health system defines (RimWorld-inspired rewrite of mood)

/// Mood thresholds for mental breaks (lower = worse)
#define PSY_MOOD_BREAK_MINOR -10
#define PSY_MOOD_BREAK_MAJOR -25
#define PSY_MOOD_BREAK_EXTREME -40

/// Mental break severity
#define PSY_BREAK_NONE 0
#define PSY_BREAK_MINOR 1
#define PSY_BREAK_MAJOR 2
#define PSY_BREAK_EXTREME 3

/// Chance per psychology tick to roll a break when below threshold (base %)
#define PSY_BREAK_CHANCE_MINOR 2
#define PSY_BREAK_CHANCE_MAJOR 5
#define PSY_BREAK_CHANCE_EXTREME 12

/// Duration of mental breaks (in seconds)
#define PSY_BREAK_DURATION_MINOR 30 SECONDS
#define PSY_BREAK_DURATION_MAJOR 60 SECONDS
#define PSY_BREAK_DURATION_EXTREME 120 SECONDS

/// Need ids
#define PSY_NEED_HUNGER "hunger"
#define PSY_NEED_BEAUTY "beauty"
#define PSY_NEED_COMFORT "comfort"
#define PSY_NEED_REST "rest"
#define PSY_NEED_RECREATION "recreation"
#define PSY_NEED_OUTDOORS "outdoors"

/// Need value range
#define PSY_NEED_MIN 0
#define PSY_NEED_MAX 100
#define PSY_NEED_CRITICAL 15
#define PSY_NEED_LOW 35
#define PSY_NEED_OK 60
#define PSY_NEED_HIGH 85

/// How often the psychology subsystem processes (seconds)
#define PSY_PROCESS_INTERVAL 2

/// Base mood contribution from a need at full satisfaction
#define PSY_NEED_MOOD_WEIGHT 4

/// Category keys for mood-like events inside psychology
#define PSY_CATEGORY_NEED "need"
#define PSY_CATEGORY_TRAIT "trait"
#define PSY_CATEGORY_BREAK "break"
#define PSY_CATEGORY_ENVIRONMENT "environment"
#define PSY_CATEGORY_SOCIAL "social"
#define PSY_CATEGORY_PAIN "pain"
#define PSY_CATEGORY_FOOD "food"


/// Trait applied while the mob is in a mental break and has no player control
#define TRAIT_PSY_NO_CONTROL "psy_no_control"
/// Source string for psychology-applied traits
#define PSYCHOLOGY_TRAIT "psychology"
