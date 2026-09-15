/mob/living/basic/khara_mutant/spreader
	name = "Spreader"
	desc = "A huge abomination resembling a living lung. It belches colossal volumes of fog laden with Khara miasma."
	cast = KHARA_CAST_ASSIMILATING
	mutant_power = KHARA_POWER_VERY_STRONG
	icon = 'fenysha_events/icons/mob/256x256.dmi'
	icon_state = "spreader"
	icon_living = "spreader"
	icon_dead = "spreader"

	speed = 12
	maxHealth = 3000
	health = 3000

	regeneration_delay = 30 SECONDS
	health_regen_per_second = 10
	minimum_melee_damage_treshold = 30
	addictional_melee_damage_multiplier = 0.7

	pixel_x = -112
	base_pixel_x = -112
	pixel_y = -16
	base_pixel_y = -16

	footstep_sounds = list(
		'fenysha_events/sounds/mobs/footsteps/dsnecro/tripod_footstep_1.ogg',
		'fenysha_events/sounds/mobs/footsteps/dsnecro/tripod_footstep_2.ogg',
		'fenysha_events/sounds/mobs/footsteps/dsnecro/tripod_footstep_3.ogg',
		'fenysha_events/sounds/mobs/footsteps/dsnecro/tripod_footstep_4.ogg',
		'fenysha_events/sounds/mobs/footsteps/dsnecro/tripod_footstep_5.ogg',
		'fenysha_events/sounds/mobs/footsteps/dsnecro/tripod_footstep_6.ogg'
	)

	mob_size = MOB_SIZE_HUGE
	plane = MASSIVE_OBJ_PLANE
	layer = LARGE_MOB_LAYER
	mouse_opacity = MOUSE_OPACITY_OPAQUE

	move_force = MOVE_FORCE_OVERPOWERING
	move_resist = MOVE_FORCE_OVERPOWERING
	pull_force = MOVE_FORCE_OVERPOWERING

	spread_miasma_amount = 40
	spreads_miasma = TRUE
	spread_miasma_chance = 100
	spread_minimal_cooldown = 50 SECONDS

	ai_controller = /datum/ai_controller/basic_controller/boss_spreader
	innate_actions = list(
		/datum/action/cooldown/mob_cooldown/boss_bone_shard = BB_MOB_ABILITY_BONESHARD,
		/datum/action/cooldown/mob_cooldown/throw_spider = BB_MOB_ABILITY_MEAT_BALL,
		/datum/action/cooldown/mob_cooldown/rumble = BB_MOB_ABILITY_RUMBLE,
		/datum/action/cooldown/mob_cooldown/artillery = BB_MOB_ABILITY_ARTILERY,
		/datum/action/cooldown/mob_cooldown/khara_fog/extreme = BB_MOB_ABILITY_FOGBALL,
	)


/mob/living/basic/khara_mutant/spreader/Initialize(mapload)
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(start_spread)), 10 SECONDS)

/mob/living/basic/khara_mutant/spreader/proc/start_spread()
	SSweather.run_weather(/datum/weather/khara_infection)

/mob/living/basic/khara_mutant/spreader/Destroy()
	for(var/datum/weather/weather in SSweather.processing)
		if(istype(weather, /datum/weather/khara_infection) && (z in weather.impacted_z_levels))
			weather.wind_down()
			break
	. = ..()



/datum/ai_controller/basic_controller/boss_spreader
