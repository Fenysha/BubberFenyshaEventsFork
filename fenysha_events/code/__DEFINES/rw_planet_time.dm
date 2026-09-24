#define RW_DAYS_PER_QUADRUM       15
#define RW_QUADRUMS_PER_YEAR      4
#define RW_DAYS_PER_YEAR          (RW_DAYS_PER_QUADRUM * RW_QUADRUMS_PER_YEAR) // 60

#define RW_STARTING_YEAR          5500
#define RW_STARTING_DAY_OF_YEAR   1

/// Quadrum keys (strings — safe as assoc list keys in DM)
#define RW_QUADRUM_APRIMAY        "0"
#define RW_QUADRUM_JUGUST         "1"
#define RW_QUADRUM_SEPTOBER       "2"
#define RW_QUADRUM_DECEMBARY      "3"

#define RW_QUADRUM_NAMES list( \
	"Aprimay", \
	"Jugust", \
	"Septober", \
	"Decembary" \
)

#define RW_SEASON_SPRING          "spring"
#define RW_SEASON_SUMMER          "summer"
#define RW_SEASON_FALL            "fall"
#define RW_SEASON_WINTER          "winter"

#define RW_HOURS_PER_DAY          24
/// Day arc around solar noon (0-1). 0.5 ≈ 12h daylight.
#define RW_DEFAULT_DAYLIGHT_FRACTION 0.5

#define RIMWORLD_DAYLIGHT_UPDATE_INTERVAL (2 SECONDS)


/// Seasonal tints applied via modulate_color_towards / apply_tint_from_base
#define RW_SEASON_TINT_SPRING  "#A8E070" // bright green
#define RW_SEASON_TINT_SUMMER  "#5B8C3E" // deep green (near identity for grass)
#define RW_SEASON_TINT_FALL    "#D4953A" // orange / amber
#define RW_SEASON_TINT_WINTER  "#C8D4E0" // cool grey-blue

/// How hard the seasonal tint pulls from base_color (0–1)
#define RW_SEASON_TINT_AMOUNT_SPRING 0.05
#define RW_SEASON_TINT_AMOUNT_SUMMER 0.05
#define RW_SEASON_TINT_AMOUNT_FALL   0.3
#define RW_SEASON_TINT_AMOUNT_WINTER 0.1

