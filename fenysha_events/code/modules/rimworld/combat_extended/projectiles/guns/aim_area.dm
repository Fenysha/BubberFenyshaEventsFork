/mob/living
	/// Current paper-doll aim area (RW_AREA_HEAD / TORSO / LEGS). Null = precise limb targeting when skill allows.
	var/rw_aim_area = RW_AREA_TORSO
	var/datum/component/rw_gun_hud/rw_gun_hud

/// Maps a body zone string to one of the three coarse aim areas.
/proc/rw_area_of_zone(zone)
	switch(zone)
		if(BODY_ZONE_HEAD, BODY_ZONE_PRECISE_EYES, BODY_ZONE_PRECISE_MOUTH)
			return RW_AREA_HEAD
		if(BODY_ZONE_L_LEG, BODY_ZONE_R_LEG)
			return RW_AREA_LEGS
	return RW_AREA_TORSO

GLOBAL_LIST_INIT(rw_area_zones, list(
	RW_AREA_HEAD = list(BODY_ZONE_HEAD),
	RW_AREA_TORSO = list(BODY_ZONE_CHEST, BODY_ZONE_L_ARM, BODY_ZONE_R_ARM),
	RW_AREA_LEGS = list(BODY_ZONE_L_LEG, BODY_ZONE_R_LEG),
))
