/mob/living/basic/khara_mutant/crusher
	name = "Scorpion"
	desc = "A huge abomination that moves on a clumsy imitation of legs; you'd best not stand in its way."
	cast = KHARA_CAST_ASSIMILATING
	mutant_power = KHARA_POWER_VERY_STRONG
	icon = 'fenysha_events/icons/mob/128x128.dmi'
	icon_state = "scorpion_khara"
	icon_living = "scorpion_khara"
	icon_dead = "scorpion_khara"

	speed = 0.5
	maxHealth = 750
	health = 750
	addictional_melee_damage_multiplier = 0.8
	minimum_melee_damage_treshold = 30

	regeneration_delay = 30 SECONDS
	health_regen_per_second = 10

	pixel_x = -46
	base_pixel_x = -46

	footstep_sounds = list(
		'fenysha_events/sounds/mobs/footsteps/dsnecro/brute_step_1.ogg',
		'fenysha_events/sounds/mobs/footsteps/dsnecro/brute_step_2.ogg',
		'fenysha_events/sounds/mobs/footsteps/dsnecro/brute_step_3.ogg',
		'fenysha_events/sounds/mobs/footsteps/dsnecro/brute_step_4.ogg',
		'fenysha_events/sounds/mobs/footsteps/dsnecro/brute_step_5.ogg',
		'fenysha_events/sounds/mobs/footsteps/dsnecro/brute_step_6.ogg'
	)

	mob_size = MOB_SIZE_HUGE
	plane = MASSIVE_OBJ_PLANE
	layer = LARGE_MOB_LAYER
	mouse_opacity = MOUSE_OPACITY_OPAQUE

	move_force = MOVE_FORCE_OVERPOWERING
	move_resist = MOVE_FORCE_OVERPOWERING
	pull_force = MOVE_FORCE_OVERPOWERING


	ai_controller = /datum/ai_controller/basic_controller/crusher
	innate_actions = list(
		/datum/action/cooldown/mob_cooldown/crush_wave = BB_MOB_ABILITY_CRUSH_WAVE,
		/datum/action/cooldown/mob_cooldown/crushing_charge = BB_MOB_ABILITY_CRUSH_CHARGE,
	)



/datum/ai_controller/basic_controller/crusher
