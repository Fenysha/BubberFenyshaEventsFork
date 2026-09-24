#define TRAIN_STATION_DMM_DIR(_filename) ("_maps/modular_events/trainstation/" + _filename)

#define ZTRAIT_TRAINSTATION "Trainstation"
#define NO_TURF_MOVEMENT_1 (1<<26)

#define TRAIT_NO_STATION_UNLOAD "!no_unload"

/// Abstract station, will not be shown in the train_controller menu, will not be linked to other stations
#define TRAINSTATION_ABSCTRACT (1 << 1)
#define TRAINSTATION_NO_FORKS (1 << 2)
#define TRAINSTATION_BLOCKING (1 << 3)
#define TRAINSTATION_NO_SELECTION (1 << 4)
#define TRAINSTATION_NO_NEARSTATION (1 << 5)
#define TRAINSTATION_NO_SPAWNING (1 << 6)
#define TRAINSTATION_LOCAL_CENTER (1 << 7)
#define TRAINSTATION_START_STATION (1 << 8)
#define TRAINSTATION_FINAL_STATION (1 << 9)

#define ENVIRONMENT_UNDERGROUND (1 << 1)
#define ENVIRONMENT_RAINY (1 << 1)

#define TRAINSTATION_REGION_THUNDRA "Thundra"
#define TRAINSTATION_REGION_TEMPERATE "Temperate"
#define TRAINSTATION_REGION_DESERT "Desert"
#define TRAINSTATION_REGION_INFECTED "Infected"

#define TRAINSTATION_TYPE_CARGO "Cargo"
#define TRAINSTATION_TYPE_EMERGENCY "Emergency"
#define TRAINSTATION_TYPE_MILITARY "Military"
#define TRAINSTATION_TYPE_CITY "City"

#define THREAT_LEVEL_SAFE "Safe"
#define THREAT_LEVEL_RISKY "Risky"
#define THREAT_LEVEL_DANGEROUS "Dangerous"
#define THREAT_LEVEL_HAZARDOUS "Hazardous"
#define THREAT_LEVEL_DEADLY "Deadly"

// REGION DATA

#define TRAIN_REGION_BASETURF list( \
	TRAINSTATION_REGION_THUNDRA = /turf/open/misc/asteroid/snow/indestructible/planet, \
	TRAINSTATION_REGION_TEMPERATE = /turf/open/indestructible/grass, \
	TRAINSTATION_REGION_DESERT = /turf/open/misc/beach/sand, \
	TRAINSTATION_REGION_INFECTED = /turf/open/indestructible/meat, \
)

// SPAWNERS AND TRANSITIONS

#define GROUP_WEIGHTED_SPAWNLIST "spawnlist"
#define GROUP_SPAWN_CHANCE "spawnchance"
#define GROUP_SPAWN_RANGE "spawnrange"
#define GROUP_SPAWN_MIN_DELAY "mindelay"
#define GROUP_SPAWN_MAX_DELAY "maxdelay"

#define SPAWNER_GROUP_CENTER "spawners_center"
#define SPAWNER_GROUP_CENTER_SPECIAL "spawners_center_special"

#define SPAWNER_GROUP_NEAR_RAILS "spawners_nearrails"
#define SPAWNER_GROUP_NEAR_RAILS_2 "spawners_nearrails_second"

#define SPAWNER_GROUP_FOREIGN "spawners_foreign"
#define SPAWNER_GROUP_FOREIGN_SPECIAL "spawners_foreign_special"

#define SPAWNER_GROUP_BACKDROP "spawners_backdrop"

// It's pretty shitty, but it's works
// it's more then enough groups for any suitable cases, probably

// Real turfs, players able to move on them

#define TRANSITION_GROUP_1  "group_1"
#define TRANSITION_GROUP_2  "group_2"
#define TRANSITION_GROUP_3  "group_3"
#define TRANSITION_GROUP_4  "group_4"
#define TRANSITION_GROUP_5  "group_5"
#define TRANSITION_GROUP_6  "group_6"
#define TRANSITION_GROUP_7  "group_7"
#define TRANSITION_GROUP_8  "group_8"
#define TRANSITION_GROUP_9  "group_9"
#define TRANSITION_GROUP_10 "group_10"
#define TRANSITION_GROUP_11 "group_11" // 2 tiles

// Decorative turfs, unable to move on them
// Doesn't actually moves, fake

#define TRANSITION_GROUP_12 "group_12" // 2 tiles
#define TRANSITION_GROUP_13 "group_13" // 2 tiles
#define TRANSITION_GROUP_14 "group_14" // 2 tiles
#define TRANSITION_GROUP_15 "group_15" // 2 tiles
#define TRANSITION_GROUP_16 "group_16" // 2 tiles
#define TRANSITION_GROUP_17 "group_17" // 2 tiles

// Border of the movement parts

#define TRANSITION_GROUP_18 "group_18"

// Not used currently
#define TRANSITION_GROUP_19 "group_19"

#define TRANSITION_TOP_SIDE "train_top"
#define TRANSITION_BOTTOM_SIDE "train_bottom"
#define TRANSITION_BOTH "both"

#define MOVING_TURF_ICON "turf_icon"
#define MOVING_TURF_ICON_STATE "turf_icon_state"
#define MOVING_TURF_NAME "turf_name"
#define MOVING_TURF_DESC "turf_desc"
#define SET_TURF_DENSITY "set_turf_density"
#define SET_TURF_OPACITY "set_turf_opacity"


// Rails customization

#define RAIL_ROLE_TOP_CONNECTOR "rail_connector_top"
#define RAIL_ROLE_TOP_CORNER "rail_corner_top"
#define RAIL_ROLE_RAIL "rail"
#define RAIL_ROLE_FILLER "rail_filler"
#define RAIL_ROLE_BOTTOM_CORNER "rail_corner_bottom"
#define RAIL_ROLE_BOTTOM_CONNECTOR "rail_connector_bottom"


/proc/find_nearest_ally(atom/source, faction, range = 12)
	var/closest
	var/closest_dist = INFINITY
	for(var/mob/living/basic/M in view(range, source))
		if(M == source || !M.has_faction(faction))
			continue
		var/dist = get_dist(source, M)
		if(dist < closest_dist)
			closest = M
			closest_dist = dist
	return closest
