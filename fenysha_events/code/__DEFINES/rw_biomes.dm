/// Generic continuous height bands [0.0 - 1.0].
/// Keys for open_turf_by_height / open_turf_by_height_transition.
/// Highest key still <= sample height wins.

#define RW_HEIGHT_BAND_KEY_0  "0.00"
#define RW_HEIGHT_BAND_KEY_1  "0.10"
#define RW_HEIGHT_BAND_KEY_2  "0.18"
#define RW_HEIGHT_BAND_KEY_3  "0.26"
#define RW_HEIGHT_BAND_KEY_4  "0.34"
#define RW_HEIGHT_BAND_KEY_5  "0.42"
#define RW_HEIGHT_BAND_KEY_6  "0.50"
#define RW_HEIGHT_BAND_KEY_7  "0.58"
#define RW_HEIGHT_BAND_KEY_8  "0.66"
#define RW_HEIGHT_BAND_KEY_9  "0.74"
#define RW_HEIGHT_BAND_KEY_10 "0.82"

/// Solid / closed terrain from this height up (ignored when is_cave).
#define RW_HEIGHT_BAND_KEY_SOLID "0.86"

#define RW_HEIGHT_TRANSITION_DELTA  (0.10)
