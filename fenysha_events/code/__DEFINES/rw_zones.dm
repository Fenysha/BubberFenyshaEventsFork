#define RW_ZERO_C 273.15
#define RW_TO_C(K) ((K) - RW_ZERO_C)
#define RW_TO_K(C) ((C) + RW_ZERO_C)


#define ZONE_VIEW_OFF 0
#define ZONE_VIEW_ZONES 1
#define ZONE_VIEW_BEAUTY 2
#define ZONE_VIEW_CLEAN 3
#define ZONE_VIEW_TEMP 4
#define ZONE_VIEW_MODE_COUNT 4

/// Radius (tiles) of the per-turf number overlay in beauty/clean/temp modes.
#define ZONE_VIEW_NUMBER_RADIUS 6

/// A zone recalculates its stats at least this often (deciseconds).
#define RW_ZONE_STATS_PERIOD (20 SECONDS)
/// Minimum delay between two recalcs when something marked the zone dirty.
#define RW_ZONE_STATS_MIN_DELAY (3 SECONDS)


/// Joules needed to heat one tile of room air by 1 degree C (gameplay value).
#define RW_ZONE_HEAT_CAPACITY 1000
/// Heat leak per border tile (1/s) through a plain wall.
#define RW_LEAK_WALL 0.0006
#define RW_LEAK_DOOR_CLOSED 0.004
#define RW_LEAK_DOOR_OPEN 0.05
/// Tile of the border that is neither wall nor door (a real gap).
#define RW_LEAK_GAP 0.08

#define RW_CLIMATE_MIN_C -90
#define RW_CLIMATE_MAX_C 50


#define RW_TAG_BED "bed"
#define RW_TAG_MEDICAL_BED "medical_bed"
#define RW_TAG_PRISON_BED "prison_bed"
#define RW_TAG_TABLE "table"
#define RW_TAG_CHAIR "chair"
#define RW_TAG_STOVE "stove"
#define RW_TAG_FRIDGE "fridge"
#define RW_TAG_WORKBENCH "workbench"
#define RW_TAG_RESEARCH "research"
#define RW_TAG_RECREATION "recreation"
#define RW_TAG_THRONE "throne"
#define RW_TAG_GRAVE "grave"
#define RW_TAG_SHELF "shelf"
#define RW_TAG_PLANT "plant"

/// Maps a number onto a label using an ascending threshold list: list(limit = "label", ...)
/proc/rw_label_for(value, list/table)
	for(var/limit in table)
		if(value <= text2num(limit))
			return table[limit]
	// Past the last threshold: use the last label. (table[N] on an assoc list returns the Nth KEY.)
	return table[table[length(table)]]

GLOBAL_LIST_INIT(rw_beauty_labels, list(
	"-5" = "hideous",
	"-2.5" = "very ugly",
	"-0.8" = "ugly",
	"0.8" = "neutral",
	"2.5" = "pretty",
	"5" = "beautiful",
	"9" = "very beautiful",
	"1000" = "breathtaking",
))

GLOBAL_LIST_INIT(rw_clean_labels, list(
	"-2.5" = "filthy",
	"-1" = "dirty",
	"-0.25" = "slightly dirty",
	"0.25" = "average",
	"0.8" = "clean",
	"1000" = "spotless",
))

GLOBAL_LIST_INIT(rw_impressive_labels, list(
	"20" = "dull",
	"40" = "mediocre",
	"65" = "decent",
	"90" = "slightly impressive",
	"120" = "somewhat impressive",
	"170" = "very impressive",
	"1000" = "extremely impressive",
))

GLOBAL_LIST_INIT(rw_temp_labels, list(
	"-30" = "deadly cold",
	"-10" = "freezing",
	"5" = "cold",
	"16" = "cool",
	"26" = "comfortable",
	"35" = "warm",
	"45" = "hot",
	"1000" = "scorching",
))



GLOBAL_LIST_INIT(rw_room_tag_by_type, list(
	/obj/structure/bed = list(RW_TAG_BED = 1),
	/obj/structure/chair = list(RW_TAG_CHAIR = 1),
	/obj/structure/table = list(RW_TAG_TABLE = 1),
	/obj/machinery/oven = list(RW_TAG_STOVE = 1),
	/obj/machinery/microwave = list(RW_TAG_STOVE = 1),
	/obj/machinery/grill = list(RW_TAG_STOVE = 1),
	/obj/machinery/smartfridge = list(RW_TAG_FRIDGE = 1),
	/obj/structure/closet/secure_closet/freezer = list(RW_TAG_FRIDGE = 1),
))
