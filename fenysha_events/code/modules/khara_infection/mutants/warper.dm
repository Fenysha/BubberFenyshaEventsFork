/mob/living/basic/khara_mutant/warper
	name = "Warp mutant"
	desc = "A terrifying humanoid creature that was clearly a human until recently. Its whole body trembles, bending unnaturally, \
			while four appendages on its back undulate rapidly."
	icon = 'fenysha_events/icons/mob/48x48.dmi'
	icon_state = "khara_warper"
	icon_living = "khara_warper"
	icon_dead = "khara_warper"
	speak_emote = list("writhes")
	response_help_continuous = "pets"
	response_help_simple = "pet"
	response_disarm_continuous = "gently pushes aside"
	response_disarm_simple = "push aside"
	ai_controller = /datum/ai_controller/basic_controller/khara_warper
	melee_damage_upper = 20
	melee_damage_lower = 20
	armour_penetration = 40

	shock_multiplier = 1.5
	baton_stun_amount = 3 SECONDS
	baton_stun_cooldown = 3 SECONDS
	shock_stun_cooldown = 2 SECONDS
	regeneration_delay = 7 SECONDS

	pixel_x = -12
	base_pixel_x = -12

	speed = 0
	health = 250
	maxHealth = 250
	spread_blood_radius = 1
	minimum_melee_damage_treshold = 15

	innate_actions = list(
		/datum/action/cooldown/mob_cooldown/zigzag_charge = BB_MOB_ABILITY_ZIGZAG_CHARGE,
	)

/datum/ai_controller/basic_controller/khara_warper
