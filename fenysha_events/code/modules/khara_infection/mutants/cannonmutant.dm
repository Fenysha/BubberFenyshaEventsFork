/mob/living/basic/khara_mutant/cannon_mutant
	name = "Cannon mutant"
	desc = "A grotesque pair of human bodies, fused together to form a structure resembling a walking cannon."
	icon = 'fenysha_events/icons/mob/48x64.dmi'
	icon_state = "khara_cannonmutant"
	icon_living = "khara_cannonmutant"
	icon_dead = "khara_cannonmutant"

	speak_emote = list("writhes")
	response_help_continuous = "pets"
	response_help_simple = "pet"
	response_disarm_continuous = "gently pushes aside"
	response_disarm_simple = "push aside"
	ai_controller = /datum/ai_controller/basic_controller/khara_cannonmutant

	melee_damage_upper = 0
	melee_damage_lower = 0
	armour_penetration = 0

	shock_multiplier = 2
	baton_stun_amount = 4 SECONDS
	baton_stun_cooldown = 4 SECONDS
	shock_stun_cooldown = 3 SECONDS
	regeneration_delay = 10 SECONDS

	speed = 1.5
	health = 250
	maxHealth = 250
	spread_blood_radius = 1
	minimum_melee_damage_treshold = 10

	pixel_x = -12
	base_pixel_x = -12

	innate_actions = list(
		/datum/action/cooldown/mob_cooldown/knockdown_target = BB_BASIC_MOB_ABILITY_KNOCKDOWN,
		/datum/action/cooldown/mob_cooldown/artillery = BB_MOB_ABILITY_ARTILERY,
	)

/datum/ai_controller/basic_controller/khara_cannonmutant
