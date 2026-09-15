/datum/material/rimworld_material
	abstract_type = /datum/material/rimworld_material
	name = "rimworld material"
	desc = "A material from the RimWorld universe."
	init_flags = MATERIAL_INIT_MAPLOAD
	mat_flags = MATERIAL_EFFECTS | MATERIAL_AFFECT_STATISTICS
	track_flags = MATERIAL_TRACK_CONTACT | MATERIAL_TRACK_IMPACT

	value_per_unit = 1
	tradable = TRUE
	tradable_base_quantity = 100
	mat_rust_resistance = RUST_RESISTANCE_ORGANIC
	mineral_rarity = MATERIAL_RARITY_COMMON
	points_per_unit = 1
	points_per_boulder_unit = 1

	var/stuff_category = RIMWORLD_STUFF_METALLIC

	var/list/rimworld_stats = null

/datum/material/rimworld_material/Initialize(_id, ...)
	. = ..()
	if(isnull(rimworld_stats))
		rimworld_stats = list()

	rimworld_stats[RIMWORLD_STAT_BEAUTY_FACTOR]		||= RIMWORLD_DEFAULT_BEAUTY_FACTOR
	rimworld_stats[RIMWORLD_STAT_BEAUTY_OFFSET]		||= RIMWORLD_DEFAULT_BEAUTY_OFFSET
	rimworld_stats[RIMWORLD_STAT_HP_FACTOR]			||= RIMWORLD_DEFAULT_HP_FACTOR
	rimworld_stats[RIMWORLD_STAT_FLAMMABILITY]		||= RIMWORLD_DEFAULT_FLAMMABILITY
	rimworld_stats[RIMWORLD_STAT_ARMOR_SHARP]		||= RIMWORLD_DEFAULT_ARMOR_SHARP
	rimworld_stats[RIMWORLD_STAT_ARMOR_BLUNT]		||= RIMWORLD_DEFAULT_ARMOR_BLUNT
	rimworld_stats[RIMWORLD_STAT_ARMOR_HEAT]		||= RIMWORLD_DEFAULT_ARMOR_HEAT
	rimworld_stats[RIMWORLD_STAT_MELEE_SHARP]		||= RIMWORLD_DEFAULT_MELEE_SHARP
	rimworld_stats[RIMWORLD_STAT_MELEE_BLUNT]		||= RIMWORLD_DEFAULT_MELEE_BLUNT
	rimworld_stats[RIMWORLD_STAT_MELEE_COOLDOWN]	||= RIMWORLD_DEFAULT_MELEE_COOLDOWN
	rimworld_stats[RIMWORLD_STAT_INSULATION_COLD]	||= RIMWORLD_DEFAULT_INSULATION_COLD
	rimworld_stats[RIMWORLD_STAT_INSULATION_HEAT]	||= RIMWORLD_DEFAULT_INSULATION_HEAT
	rimworld_stats[RIMWORLD_STAT_WORK_TO_MAKE]		||= RIMWORLD_DEFAULT_WORK_TO_MAKE
	rimworld_stats[RIMWORLD_STAT_WORK_TO_BUILD]		||= RIMWORLD_DEFAULT_WORK_TO_BUILD
	rimworld_stats[RIMWORLD_STAT_DOOR_SPEED]		||= RIMWORLD_DEFAULT_DOOR_SPEED
	rimworld_stats[RIMWORLD_STAT_REST_EFFECT]		||= RIMWORLD_DEFAULT_REST_EFFECT
	rimworld_stats[RIMWORLD_STAT_MARKET_VALUE]		||= value_per_unit

	if(isnull(mat_properties))
		mat_properties = list()

	var/hp = rimworld_stats[RIMWORLD_STAT_HP_FACTOR]
	var/armor_sharp = rimworld_stats[RIMWORLD_STAT_ARMOR_SHARP]
	var/armor_blunt = rimworld_stats[RIMWORLD_STAT_ARMOR_BLUNT]
	var/armor_heat = rimworld_stats[RIMWORLD_STAT_ARMOR_HEAT]
	var/melee_sharp = rimworld_stats[RIMWORLD_STAT_MELEE_SHARP]
	var/flammability = rimworld_stats[RIMWORLD_STAT_FLAMMABILITY]

	mat_properties[MATERIAL_DENSITY]		= clamp(round(4 + (hp - 1) * 3 + (armor_blunt - 0.45) * 4), 1, 10)
	mat_properties[MATERIAL_HARDNESS]		= clamp(round(4 + (armor_sharp - 0.9) * 5 + (melee_sharp - 1) * 3), 1, 10)
	mat_properties[MATERIAL_FLEXIBILITY]	= (stuff_category in list(RIMWORLD_STUFF_FABRIC, RIMWORLD_STUFF_LEATHERY)) ? 7 : (stuff_category == RIMWORLD_STUFF_WOODY ? 5 : 3)
	mat_properties[MATERIAL_INTEGRITY]		= clamp(round(hp * 5), 1, 10)
	mat_properties[MATERIAL_FLAMMABILITY]	= clamp(round(flammability * 5), 0, 10)
	mat_properties[MATERIAL_ELECTRICAL]		= (stuff_category == RIMWORLD_STUFF_METALLIC) ? 6 : 2
	mat_properties[MATERIAL_THERMAL]		= clamp(round(5 + (armor_heat - 0.6) * 3), 1, 10)
	mat_properties[MATERIAL_CHEMICAL]		= (stuff_category in list(RIMWORLD_STUFF_STONY, RIMWORLD_STUFF_METALLIC)) ? 6 : 4
	mat_properties[MATERIAL_REFLECTIVITY]	= (name in list("gold", "silver", "plasteel")) ? 7 : 3

	for(var/prop_id in mat_properties)
		var/datum/material_property/property = SSmaterials.properties[prop_id]
		if(property)
			property.attach_to(src)


/datum/material/rimworld_material/proc/get_rimworld_stat(stat_key)
	return rimworld_stats?[stat_key]

/datum/material/rimworld_material/proc/get_beauty_factor()
	return get_rimworld_stat(RIMWORLD_STAT_BEAUTY_FACTOR)

/datum/material/rimworld_material/proc/get_beauty_offset()
	return get_rimworld_stat(RIMWORLD_STAT_BEAUTY_OFFSET)

/datum/material/rimworld_material/proc/get_hp_factor()
	return get_rimworld_stat(RIMWORLD_STAT_HP_FACTOR)

/datum/material/rimworld_material/proc/get_flammability_factor()
	return get_rimworld_stat(RIMWORLD_STAT_FLAMMABILITY)

/datum/material/rimworld_material/proc/get_armor_sharp()
	return get_rimworld_stat(RIMWORLD_STAT_ARMOR_SHARP)

/datum/material/rimworld_material/proc/get_armor_blunt()
	return get_rimworld_stat(RIMWORLD_STAT_ARMOR_BLUNT)

/datum/material/rimworld_material/proc/get_armor_heat()
	return get_rimworld_stat(RIMWORLD_STAT_ARMOR_HEAT)

/datum/material/rimworld_material/proc/get_melee_sharp()
	return get_rimworld_stat(RIMWORLD_STAT_MELEE_SHARP)

/datum/material/rimworld_material/proc/get_melee_blunt()
	return get_rimworld_stat(RIMWORLD_STAT_MELEE_BLUNT)

/datum/material/rimworld_material/proc/get_melee_cooldown()
	return get_rimworld_stat(RIMWORLD_STAT_MELEE_COOLDOWN)

/datum/material/rimworld_material/proc/get_insulation_cold()
	return get_rimworld_stat(RIMWORLD_STAT_INSULATION_COLD)

/datum/material/rimworld_material/proc/get_insulation_heat()
	return get_rimworld_stat(RIMWORLD_STAT_INSULATION_HEAT)

/datum/material/rimworld_material/proc/get_market_value()
	return get_rimworld_stat(RIMWORLD_STAT_MARKET_VALUE)
