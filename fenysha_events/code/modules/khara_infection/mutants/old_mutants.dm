

/mob/living/basic/khara_mutant/flesh_spider
	name = "Flesh Spider"
	desc = "A strange creature made of flesh, shaped like a spider. Its eyes are black, bottomless pits without a hint of a soul."
	icon = 'icons/mob/simple/arachnoid.dmi'
	icon_state = "flesh"
	icon_living = "flesh"
	icon_dead = "flesh_dead"
	speak_emote = list("clicks")
	response_help_continuous = "pets"
	response_help_simple = "pet"
	response_disarm_continuous = "gently pushes aside"
	response_disarm_simple = "push aside"
	ai_controller = /datum/ai_controller/basic_controller/giant_spider
	health = 125
	maxHealth = 125
	spread_blood_radius = 1
	minimum_melee_damage_treshold = 5
	innate_actions = list(
		/datum/action/cooldown/mob_cooldown/boss_bone_shard = BB_MOB_ABILITY_BONESHARD
	)

/mob/living/basic/khara_mutant/flesh_spider/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_WEB_SURFER, INNATE_TRAIT)
	AddElement(/datum/element/cliff_walking)
	AddElement(/datum/element/venomous, /datum/reagent/toxin/hunterspider, 5, injection_flags = INJECT_CHECK_PENETRATE_THICK)
	AddElement(/datum/element/web_walker, /datum/movespeed_modifier/fast_web)
	AddElement(/datum/element/nerfed_pulling, GLOB.typecache_general_bad_things_to_easily_move)


/mob/living/basic/khara_mutant/flesh_spider/weaker
	health = 75
	maxHealth = 75
	melee_damage_lower = 10
	melee_damage_upper = 10




/mob/living/basic/khara_mutant/arachnid
	name = "Distorted Arachnid"
	desc = "Despite its impressive size, it prefers to attack from ambush and to strike only an already crippled victim."
	cast = KHARA_CAST_ADAPTED
	mutant_power = KHARA_POWER_STRONG
	icon = 'icons/mob/simple/jungle/arachnid.dmi'
	icon_state = "arachnid"
	icon_living = "arachnid"
	icon_dead = "arachnid_dead"
	color = COLOR_RED
	armour_penetration = 60
	melee_damage_lower = 15
	melee_damage_upper = 25
	wound_bonus = 15
	maxHealth = 350
	health = 350
	addictional_melee_damage_multiplier = 0.5
	minimum_melee_damage_treshold = 20

	regeneration_delay = 7 SECONDS
	health_regen_per_second = 10

	footstep_sounds = list(
		'fenysha_events/sounds/mobs/footsteps/dsnecro/brute_step_1.ogg',
		'fenysha_events/sounds/mobs/footsteps/dsnecro/brute_step_2.ogg',
		'fenysha_events/sounds/mobs/footsteps/dsnecro/brute_step_3.ogg',
		'fenysha_events/sounds/mobs/footsteps/dsnecro/brute_step_4.ogg',
		'fenysha_events/sounds/mobs/footsteps/dsnecro/brute_step_5.ogg',
		'fenysha_events/sounds/mobs/footsteps/dsnecro/brute_step_6.ogg'
	)


	pixel_x = -16
	base_pixel_x = -16
	mob_size = MOB_SIZE_HUGE

	speak_emote = list("roars")
	attack_sound = 'sound/items/weapons/bladeslice.ogg'
	attack_vis_effect = ATTACK_EFFECT_SLASH
	ai_controller = /datum/ai_controller/basic_controller/corrupted_arachnid

	innate_actions = list(
		/datum/action/cooldown/spell/pointed/projectile/flesh_restraints = BB_ARACHNID_RESTRAIN,
		/datum/action/cooldown/mob_cooldown/boss_leap = BB_MOB_ABILITY_LEAP,
	)

/datum/ai_controller/basic_controller/corrupted_arachnid
