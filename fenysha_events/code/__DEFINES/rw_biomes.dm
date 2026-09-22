/**
 * ============================================================================
 * RimWorld local terrain
 * Height bands
 * ============================================================================
 *
 * Height is normalized to [0.0 .. 1.0].
 *
 * The highest threshold <= sampled height is selected.
 *
 * Tuned to match current Rust elevation_to_height + relief:
 *   Ocean   ~0.06
 *   Coast   ~0.16
 *   Lowland ~0.32
 *   Highland~0.48
 *   Mountain~0.68  (+ relief)
 *   Snow    ~0.78  (+ relief)
 *
 */

/**
 * Open terrain thresholds.
 */
#define RW_HEIGHT_BAND_KEY_0  "0.00"
#define RW_HEIGHT_BAND_KEY_1  "0.8"
#define RW_HEIGHT_BAND_KEY_2  "0.149"
#define RW_HEIGHT_BAND_KEY_3  "0.17"
#define RW_HEIGHT_BAND_KEY_4  "0.19"
#define RW_HEIGHT_BAND_KEY_5  "0.232"
#define RW_HEIGHT_BAND_KEY_6  "0.275"
#define RW_HEIGHT_BAND_KEY_7  "0.331"
#define RW_HEIGHT_BAND_KEY_8  "0.344"
#define RW_HEIGHT_BAND_KEY_9  "0.365"


#define RW_HEIGHT_BAND_KEY_SOLID "0.366"

/**
 * At or below this local (post-blend) height, a cell is treated as
 * below water level and forced to a water turf, REGARDLESS of which
 * land biome this sub-level otherwise resolved to.
 *
 * Sits between elevation_to_height(ELEV_OCEAN) = 0.06 and
 * elevation_to_height(ELEV_COAST) = 0.16 on the Rust side,
 * so it only catches cells that are genuinely blended toward
 * an ocean/coast neighbour, not normal lowland dips.
 */
#define RW_HEIGHT_WATER_MAX 0.079

/**
 * Height difference between neighbouring cells required to mark
 * a geological transition.
 */
#define RW_HEIGHT_TRANSITION_DELTA 0.04


/**
 * ============================================================================
 * Cave generator
 * ============================================================================
 *
 * String values are used because BYOND's JSON bridge serializes these
 * explicitly and Rust expects a String.
 * ============================================================================
 */

#define RW_CAVEGUN_TRUE  "caves_true"
#define RW_CAVEGUN_FALSE "caves_false"
