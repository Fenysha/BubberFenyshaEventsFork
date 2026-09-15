
// Don't fear the Reaper!
/mob/living/basic/khara_mutant/reaper
	name = "Reaper"
	desc = "A horrifying abomination on thin, blood-soaked legs. Its limbs move chaotically and unnaturally."
	cast = KHARA_CAST_ADAPTED
	mutant_power = KHARA_POWER_STRONG
	icon = 'fenysha_events/icons/mob/64x64.dmi'
	icon_state = "reaper"
	icon_living = "reaper"
	icon_dead = "reaper_dead"
	armour_penetration = 30
	melee_damage_lower = 30
	melee_damage_upper = 30
	wound_bonus = 35
	maxHealth = 150
	health = 150

	speed = 0
	regeneration_delay = 15 SECONDS
	health_regen_per_second = 10
	addictional_melee_damage_multiplier = 0.7
	minimum_melee_damage_treshold = 15

	pixel_x = -16
	base_pixel_x = -16
	mob_size = MOB_SIZE_HUGE

	speak_emote = list("roars")
	attack_sound = 'sound/items/weapons/bladeslice.ogg'
	attack_vis_effect = null
	ai_controller = /datum/ai_controller/basic_controller/khara_reaper

	innate_actions = list(
		/datum/action/cooldown/mob_cooldown/aoe_slash = BB_MOB_AILITY_SLASH,
		/datum/action/cooldown/mob_cooldown/boss_charge/weak = BB_MOB_ABILITY_FAST_CHARGE,
	)

/mob/living/basic/khara_mutant/reaper/melee_attack(atom/target, list/modifiers, ignore_cooldown)
	if(isliving(target))
		new /obj/effect/temp_visual/slash(get_turf(target), target, world.icon_size / 2, world.icon_size / 2, COLOR_RED)
	. = ..()
	if(!. || !ishuman(target) || !prob(70))
		return

	var/mob/living/carbon/human/victim = target
	var/obj/item/bodypart/to_cut = null
	for(var/obj/item/bodypart/part in victim.bodyparts)
		if(part.max_damage >= LIMB_MAX_HP_CORE)
			continue
		if(part.brute_dam >= (part.max_damage * 0.8))
			to_cut = part
			break
	if(!to_cut)
		return
	new /obj/effect/temp_visual/slash(get_turf(target), target, world.icon_size / 2, world.icon_size / 2, COLOR_RED)
	do_attack_animation(target)
	to_cut.dismember(silent=FALSE)


/mob/living/basic/khara_mutant/reaper/ghost
	name = "???"
	desc = "???"

	icon = 'fenysha_events/icons/mob/ebaka.dmi'
	icon_state = "ebaka"

	apply_filter = FALSE
	melee_damage_lower = 50
	melee_damage_upper = 50
	armour_penetration = 100
	alpha = 200

	maxHealth = 50000
	health = 50000
	ai_controller = null

	innate_actions = list(
		/datum/action/cooldown/noclip = null,
		/datum/action/cooldown/mob_cooldown/aoe_slash/extreme = BB_MOB_AILITY_SLASH,
		/datum/action/cooldown/mob_cooldown/boss_charge = BB_MOB_ABILITY_FAST_CHARGE,
	)


/datum/ai_controller/basic_controller/khara_reaper
