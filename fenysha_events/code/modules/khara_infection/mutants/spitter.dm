/mob/living/basic/khara_mutant/spitter
	name = "Breathing mutant"
	desc = "A grotesque pair of human bodies, fused together to form a structure resembling a walking cannon."
	icon = 'fenysha_events/icons/mob/48x48.dmi'
	icon_state = "khara_spitter"
	icon_living = "khara_spitter"
	icon_dead = "khara_spitter"

	speak_emote = list("writhes")
	response_help_continuous = "pets"
	response_help_simple = "pet"
	response_disarm_continuous = "gently pushes aside"
	response_disarm_simple = "push aside"
	ai_controller = /datum/ai_controller/basic_controller/khara_spitter

	melee_damage_upper = 15
	melee_damage_lower = 15
	armour_penetration = 0

	shock_multiplier = 2
	baton_stun_amount = 4 SECONDS
	baton_stun_cooldown = 4 SECONDS
	shock_stun_cooldown = 3 SECONDS
	regeneration_delay = 10 SECONDS

	speed = 2
	health = 300
	maxHealth = 300
	spread_blood_radius = 1
	minimum_melee_damage_treshold = 15

	pixel_x = -12
	base_pixel_x = -12

	innate_actions = list(
		/datum/action/cooldown/mob_cooldown/knockdown_target = BB_BASIC_MOB_ABILITY_KNOCKDOWN,
		/datum/action/cooldown/mob_cooldown/khara_fog = BB_MOB_ABILITY_FOGBALL,
	)

/mob/living/basic/khara_mutant/spitter/Initialize(mapload)
	. = ..()
	create_overlay()

/mob/living/basic/khara_mutant/spitter/proc/create_overlay()
	var/mutable_appearance/breath = mutable_appearance('fenysha_events/icons/mob/48x48.dmi', "khara_spitter_overlay")
	add_overlay(breath)
	var/matrix/M1 = matrix()
	M1.Scale(1.05, 0.95)

	var/matrix/M2 = matrix()
	M2.Scale(0.95, 1.05)

	var/matrix/M_reset = matrix()

	animate(src, transform = M1, time = 2, loop = -1, easing = JUMP_EASING, flags = ANIMATION_PARALLEL)
	animate(transform = M2, time = 2, easing = JUMP_EASING)
	animate(transform = M_reset, time = 4)


/datum/ai_controller/basic_controller/khara_spitter
