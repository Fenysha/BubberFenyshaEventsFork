// (datum/turf_roof/roof)
#define COMSIG_TURF_ROOF_ADDED "turf_roof_added"
// (datum/turf_roof/roof)
#define COMSIG_TURF_ROOF_REMOVED "turf_roof_removed"
// returns TRUE if still supported
#define COMSIG_TURF_ROOF_SUPPORT_CHECK "turf_roof_support_check"
// called when roof collapses
#define COMSIG_TURF_ROOF_COLLAPSE "turf_roof_collapse"
// fired by walls/structures when they stop providing support
#define COMSIG_ATOM_ROOF_SUPPORT_LOST "atom_roof_support_lost"


/// Fired on the planet when the global quadrum changes. (old_quadrum, new_quadrum, year)
#define COMSIG_RIMWORLD_PLANET_QUADRUM_CHANGED "rimworld_planet_quadrum_changed"
/// Fired on the planet when the calendar year changes. (old_year, new_year)
#define COMSIG_RIMWORLD_PLANET_YEAR_CHANGED "rimworld_planet_year_changed"
/// Fired on the planet when season would change for a given hemisphere.
/// (hemisphere, old_season, new_season, quadrum, year)
/// hemisphere: "north" | "south"
#define COMSIG_RIMWORLD_PLANET_SEASON_CHANGED "rimworld_planet_season_changed"
/// Fired every time a full planetary day completes (after day counter advances).
#define COMSIG_RIMWORLD_PLANET_DAY_PASSED "rimworld_planet_day_passed"
/// Rimworld daylight: area should recompute local sun state
#define COMSIG_RIMWORLD_AREA_DAYLIGHT_UPDATE "rimworld_area_daylight_update"


#define COMSIG_RIMWORLD_CELL_POD_LANDED "rimworld_cell_pod_landed"
