#define KHARA_REGEN_FILTER "khara_healing_glow"

/obj/effect/particle_effect/fluid/smoke/chem/khara
	opacity = FALSE
	alpha = 190

/datum/effect_system/fluid_spread/smoke/chem/khara
	effect_type = /obj/effect/particle_effect/fluid/smoke/chem/khara

/datum/component/infection_attack
	var/chance_on_infection = 10
	var/only_with_wounds = TRUE
	var/disease

/datum/component/infection_attack/Initialize(disease, chance_on_infection = 10, only_with_wounds = TRUE)
	if(!isliving(parent))
		return COMPONENT_INCOMPATIBLE
	src.chance_on_infection = chance_on_infection
	if(!ispath(disease, /datum/disease))
		return COMPONENT_INCOMPATIBLE
	src.disease = disease
	src.only_with_wounds = only_with_wounds
	RegisterSignal(parent, COMSIG_LIVING_UNARMED_ATTACK, PROC_REF(on_parent_attack), TRUE)

/datum/component/infection_attack/proc/on_parent_attack(mob/living/attacker, atom/attacked, proximity)
	SIGNAL_HANDLER
	if(!ishuman(attacked) || !proximity)
		return
	var/mob/living/carbon/human/human = attacked

	// If the wound check is enabled and there are no wounds, no infection occurs
	if(!human.all_wounds && only_with_wounds)
		return

	var/infect_chance = 10
	if(human.all_wounds && islist(human.all_wounds))
		for(var/datum/wound/wound in human.all_wounds)
			if(wound.severity >= WOUND_SEVERITY_MODERATE)
				infect_chance += 10

	infect_chance = clamp(infect_chance, 10, 40)

	if(prob(infect_chance))
		human.ForceContractDisease(new disease, del_on_fail = TRUE)


/datum/component/projectile_evade

	var/projectile_evade_chance = 100
	var/projectile_evade_cooldown = 2 SECONDS
	var/projectile_evade_steps = 1
	var/datum/callback/callback_check = null
	COOLDOWN_DECLARE(projectile_evade_cd)


/datum/component/projectile_evade/Initialize(evade_chance = 100, evade_cooldown = 2 SECONDS, evade_steps = 1, callback_check = null)
	if(!ismovable(parent))
		return COMPONENT_INCOMPATIBLE
	if(callback_check)
		src.callback_check = callback_check
	src.projectile_evade_chance = evade_chance
	src.projectile_evade_cooldown = evade_cooldown
	src.projectile_evade_steps = evade_steps

/datum/component/projectile_evade/RegisterWithParent()
	. = ..()
	RegisterSignal(parent, COMSIG_ATOM_PRE_BULLET_ACT, PROC_REF(on_projectile_hit))

/datum/component/projectile_evade/UnregisterFromParent()
	. = ..()
	UnregisterSignal(parent, list(COMSIG_ATOM_PRE_BULLET_ACT))

/datum/component/projectile_evade/proc/on_projectile_hit(atom/source, obj/projectile/hitting_projectile, def_zone, piercing_hit)
	SIGNAL_HANDLER

	if(QDELETED(parent) || !COOLDOWN_FINISHED(src, projectile_evade_cd))
		return

	if(projectile_evade_chance < 100 && !prob(projectile_evade_chance))
		return

	if(callback_check && !callback_check.Invoke(source, hitting_projectile, def_zone, piercing_hit))
		return

	INVOKE_ASYNC(src, PROC_REF(do_strafe_evade), source, hitting_projectile)
	COOLDOWN_START(src, projectile_evade_cd, projectile_evade_cooldown)
	return COMPONENT_BULLET_PIERCED

/datum/component/projectile_evade/proc/do_strafe_evade(atom/movable/source, obj/projectile/proj)
	var/evade_dir = angle2dir(proj.dir)

	if(proj.dir & (proj.dir - 1))
		evade_dir = prob(50) ? turn(proj.dir, 90) : turn(proj.dir, -90)
	else
		evade_dir = prob(50) ? turn(proj.dir, 90) : turn(proj.dir, -90)

	source.visible_message(span_warning("[source] straifes!"))
	var/step_count = 0
	while(step_count <= projectile_evade_steps)
		var/turf/next_turf = get_step(source, evade_dir)
		if(!next_turf || next_turf.density || next_turf.is_blocked_turf(TRUE))
			evade_dir = turn(evade_dir, 180)
			next_turf = get_step(source, evade_dir)
			if(!next_turf || next_turf.density || next_turf.is_blocked_turf(TRUE))
				break
		new /obj/effect/temp_visual/decoy/fading/halfsecond(source.loc, source)
		source.forceMove(next_turf)
		step_count++
		CHECK_TICK
		sleep(0.1)
	new /obj/effect/temp_visual/decoy/fading/halfsecond(source.loc, source)
	playsound(source, 'sound/effects/bang.ogg', 50, TRUE, -1)



/proc/is_khara_creature(datum/thing)
	return istype(thing, /mob/living/basic/khara_mutant) || HAS_TRAIT(thing, TRAIT_KHARAMUTANT)

/obj/effect/mob_spawn/ghost_role/flesh_spider
	name = "Flesh Cocoon"
	desc = "A huge, pulsating plant..."
	icon = 'icons/mob/simple/meteor_heart.dmi'
	icon_state = "flesh_pod"
	mob_type = /mob/living/basic/khara_mutant/flesh_spider
	density = FALSE
	uses = 1
	deletes_on_zero_uses_left = FALSE
	prompt_name = "carnivorous trap"
	you_are_text = "You are a spider of flesh and blood."
	flavour_text = "You are a spider of flesh and blood! Defend your nest at any cost and devour everyone who dares to come close!"
	important_text = "Under no circumstances leave your nest!"
	faction = list(FACTION_KHARA)
	light_range = 2
	light_power = 3

/obj/effect/mob_spawn/ghost_role/flesh_spider/Initialize(mapload)
	. = ..()
	set_light(light_range, light_power, LIGHT_COLOR_FLARE)

/obj/effect/mob_spawn/ghost_role/flesh_spider/pre_ghost_take(mob/dead/observer/user)
	icon_state = "flesh_pod_open"
	for(var/turf/blood_turf in view(src, 2))
		new /obj/effect/decal/cleanable/blood(blood_turf)
		for(var/mob/living/mob_in_turf in blood_turf)
			mob_in_turf.visible_message(span_danger("[mob_in_turf] is splattered with blood!"), span_userdanger("You are splattered with blood!"))
			mob_in_turf.add_blood_DNA(list("Non-human DNA" = random_human_blood_type()), list(/datum/disease/khara))
			playsound(mob_in_turf, 'sound/effects/splat.ogg', 50, TRUE, extrarange = SILENCED_SOUND_EXTRARANGE)
	return ..()


/mob/living/basic/khara_mutant
	name = "Khara Mutant"
	desc = "A vile, blood-soaked abomination..."
	mob_biotypes = MOB_ORGANIC|MOB_BUG|MOB_SPECIAL
	speak_emote = list("growls")
	damage_coeff = list(BRUTE = 1.3, BURN = 0.7, TOX = 0, STAMINA = 1, OXY = 0)
	basic_mob_flags = FLAMMABLE_MOB|REMAIN_DENSE_WHILE_DEAD
	status_flags = CANSTUN
	speed = 1
	maxHealth = 250
	health = 250
	armour_penetration = 30
	melee_damage_lower = 20
	melee_damage_upper = 20
	wound_bonus = 20
	obj_damage = 50
	melee_attack_cooldown = CLICK_CD_MELEE
	attack_verb_continuous = "bites into"
	attack_verb_simple = "bite into"
	attack_sound = 'sound/items/weapons/bite.ogg'
	attack_vis_effect = ATTACK_EFFECT_SLASH
	unsuitable_cold_damage = 10
	unsuitable_heat_damage = 0
	maximum_survivable_temperature = SPACE_SUIT_MAX_TEMP_PROTECT
	minimum_survivable_temperature = T0C - 25
	combat_mode = TRUE
	faction = list(FACTION_KHARA)
	pass_flags = PASSTABLE
	unique_name = TRUE
	lighting_cutoff_red = 22
	lighting_cutoff_green = 5
	lighting_cutoff_blue = 5

	max_stamina = 250
	stamina_crit_threshold = 90
	stamina_recovery = 5
	max_stamina_slowdown = 12
	unsuitable_cold_damage = 10
	habitable_atmos = null

	/// This mutant's caste
	var/cast = KHARA_CAST_LESSER
	/// Reference to this mutant's hivemind component
	VAR_FINAL/datum/component/khara_hivemind/hivemind_link = null
	/// This mutant's power
	var/mutant_power = KHARA_POWER_WEAK

	/// The minimum melee damage required to pierce this mutant
	var/minimum_melee_damage_treshold = 10
	/// Additional melee damage modifier, where 1 means 2x damage
	var/addictional_melee_damage_multiplier = 1

	/// How this mob are protected against electrocute act. Since it's one of the weaknes of khara
	var/shock_multiplier = 1
	var/baton_stun_amount = 4 SECONDS

	/// How long it takes before we can stun this mob by any possible way
	var/shock_stun_cooldown = 3 SECONDS
	var/baton_stun_cooldown = 5 SECONDS

	/// Footstep sounds of this mob
	var/footstep_sounds = list(
		'fenysha_events/sounds/mobs/footsteps/dsnecro/lurker_footstep_1.ogg',
		'fenysha_events/sounds/mobs/footsteps/dsnecro/lurker_footstep_2.ogg',
		'fenysha_events/sounds/mobs/footsteps/dsnecro/lurker_footstep_3.ogg',
		'fenysha_events/sounds/mobs/footsteps/dsnecro/lurker_footstep_4.ogg',
		'fenysha_events/sounds/mobs/footsteps/dsnecro/lurker_footstep_5.ogg',
		'fenysha_events/sounds/mobs/footsteps/dsnecro/lurker_footstep_6.ogg',
		'fenysha_events/sounds/mobs/footsteps/dsnecro/lurker_footstep_7.ogg'
	)

	/// Whether this mutant should burst on death
	var/gib_on_death = TRUE
	/// The radius of blood spray when the mutant dies
	var/spread_blood_radius = 3

	var/spread_miasma_amount = 12
	var/spread_miasma_chance = 5
	var/spreads_miasma = FALSE

	/// Regeneration settings
	var/regeneration_delay = 4 SECONDS
	var/health_regen_per_second = 4
	var/regen_outline_colour = COLOR_PINK
	var/list/ignore_damage_types = list(STAMINA)
	VAR_PRIVATE/regeneration_start_timer
	var/is_regenerating = FALSE

	/// This mutant's abilities
	var/list/innate_actions
	/// The default abilities of all mutants
	VAR_PRIVATE/list/default_actions = list(
		/datum/action/cooldown/mob_cooldown/consume = BB_MOB_ABILITY_CONSUME
	)

	var/apply_filter = FALSE
	var/spread_minimal_cooldown = 5 SECONDS

	COOLDOWN_DECLARE(spread_cd)
	COOLDOWN_DECLARE(shock_stun_cd)
	COOLDOWN_DECLARE(baton_stun_cd)

/mob/living/basic/khara_mutant/Initialize(mapload)
	. = ..()
	add_traits(list(TRAIT_NO_TELEPORT, TRAIT_LAVA_IMMUNE, TRAIT_ASHSTORM_IMMUNE, TRAIT_NO_FLOATING_ANIM, TRAIT_THERMAL_VISION, TRAIT_KHARAMUTANT), MEGAFAUNA_TRAIT)
	AddElement(/datum/element/prevent_attacking_of_types, GLOB.typecache_general_bad_hostile_attack_targets, "it's pointless!")
	AddElement(/datum/element/footstep_callback, CALLBACK(src, PROC_REF(get_footstep_sounds)), 0.5, -8, FALSE)
	AddElement(/datum/element/ai_retaliate)

	AddComponent(/datum/component/seethrough_mob)
	AddComponent(\
		/datum/component/blood_walk,\
		blood_type = /obj/effect/decal/cleanable/blood/bubblegum,\
		blood_spawn_chance = 15,\
	)
	AddComponent(\
		/datum/component/infection_attack, \
		disease = /datum/disease/khara,\
		chance_on_infection = 10, \
		only_with_wounds = TRUE, \
	)
	AddComponent(\
		/datum/component/morph_engine_tracker, \
		engine = GLOB.main_morph_engine, \
	)

	hivemind_link = AddComponent(\
		/datum/component/khara_hivemind, \
		cast = src.cast, \
	)
	if(apply_filter)
		apply_wibbly_filters(src)
	give_powers()

	if(innate_actions && islist(innate_actions))
		grant_actions_by_list(innate_actions)
	subscribe_to_signals()
	update_sight()

/mob/living/basic/khara_mutant/Destroy()
	stop_regenerating()
	if(regeneration_start_timer)
		deltimer(regeneration_start_timer)
	unsubscribe_from_signals()
	return ..()

/mob/living/basic/khara_mutant/proc/subscribe_to_signals()
	RegisterSignal(src, COMSIG_MOB_BATONED, PROC_REF(on_batoned))

/mob/living/basic/khara_mutant/proc/unsubscribe_from_signals()
	UnregisterSignal(src, list(COMSIG_MOB_BATONED))

/mob/living/basic/khara_mutant/apply_damage(damage, damagetype, def_zone, blocked, forced, spread_damage, wound_bonus, exposed_wound_bonus, sharpness, attack_direction, attacking_item, wound_clothing)
	. = ..()
	if(. && !(damagetype in ignore_damage_types))
		reset_regeneration_timer()

/mob/living/basic/khara_mutant/proc/reset_regeneration_timer()
	stop_regenerating()
	regeneration_start_timer = addtimer(CALLBACK(src, PROC_REF(start_regenerating)), regeneration_delay, TIMER_UNIQUE|TIMER_OVERRIDE|TIMER_STOPPABLE)

/mob/living/basic/khara_mutant/proc/should_regen()
	if(stat == DEAD)
		return FALSE
	if(health >= maxHealth)
		return FALSE
	if(on_fire || !COOLDOWN_FINISHED(src, shock_stun_cd) || !COOLDOWN_FINISHED(src, baton_stun_cd))
		return FALSE
	return TRUE

/mob/living/basic/khara_mutant/proc/start_regenerating()
	if(!should_regen())
		return
	visible_message(span_notice("[src]'s wounds begin to knit closed!"))
	is_regenerating = TRUE
	regeneration_start_timer = null

	if(!regen_outline_colour)
		return
	add_filter(KHARA_REGEN_FILTER, 2, list("type" = "outline", "color" = regen_outline_colour, "alpha" = 0, "size" = 1))
	var/filter = get_filter(KHARA_REGEN_FILTER)
	animate(filter, alpha = 200, time = 0.5 SECONDS, loop = -1, flags = ANIMATION_PARALLEL)
	animate(alpha = 0, time = 0.5 SECONDS)

/mob/living/basic/khara_mutant/proc/stop_regenerating()
	is_regenerating = FALSE
	var/filter = get_filter(KHARA_REGEN_FILTER)
	if(filter)
		animate(filter, flags = ANIMATION_PARALLEL)
		remove_filter(KHARA_REGEN_FILTER)

/mob/living/basic/khara_mutant/Life(seconds_per_tick, times_fired)
	. = ..()
	if(spreads_miasma && SPT_PROB(spread_miasma_chance, seconds_per_tick) && COOLDOWN_FINISHED(src, spread_cd))
		COOLDOWN_START(src, spread_cd, spread_minimal_cooldown)
		spread_miasma()

	if(is_regenerating)
		if(!should_regen())
			stop_regenerating()
			return

		var/heal_mod = stat
		if(health_regen_per_second && adjust_brute_loss(-1 * heal_mod * health_regen_per_second * seconds_per_tick, updating_health = FALSE))
			updatehealth()

/mob/living/basic/khara_mutant/proc/give_powers()
	PRIVATE_PROC(TRUE)
	grant_actions_by_list(default_actions)

	if(mutant_power >= KHARA_POWER_STRONG)
		grant_actions_by_list(list(
			/datum/action/cooldown/mob_cooldown/mech_crush = BB_MOB_ABILITY_CRUSH_MECH
		))

/mob/living/basic/khara_mutant/attack_hand(mob/living/carbon/human/user, list/modifiers)
	return ATTACK_FAILED

/mob/living/basic/khara_mutant/attacked_by(obj/item/attacking_item, mob/living/user, list/modifiers, list/attack_modifiers)
	if((attacking_item.force < minimum_melee_damage_treshold) && !HAS_TRAIT(attacking_item, TRAIT_ALWAYS_PENETRAIT_KHARA))
		attacking_item.visible_message("[attacking_item] bounces off the body of [src], unable to pierce it.")
		user.do_attack_animation(src, used_item = attacking_item)
		return ATTACK_FAILED

	. = ..()

	if(!.)
		return
	var/addictional_damage = . * addictional_melee_damage_multiplier

	apply_damage(
		damage = addictional_damage,
		damagetype = attacking_item.damtype,
		def_zone = check_zone(user.zone_selected),
		blocked = FALSE,
		sharpness = attacking_item.get_sharpness(),
		attack_direction = get_dir(user, src),
		attacking_item = attacking_item,
	)

/mob/living/basic/khara_mutant/electrocute_act(shock_damage, source, siemens_coeff, flags)
	. = ..()
	if(!COOLDOWN_FINISHED(src, shock_stun_cd))
		return

	var/stun_amount = abs(shock_damage >= 10 ? shock_damage * shock_multiplier : 0)
	if(stun_amount)
		Stun(stun_amount)
		COOLDOWN_START(src, shock_stun_cd, shock_stun_cooldown)

/mob/living/basic/khara_mutant/proc/on_batoned(mob/living/basic/khara_mutant/mutant, mob/living/user, obj/item/melee/baton/baton)
	SIGNAL_HANDLER

	if(!COOLDOWN_FINISHED(src, baton_stun_cd))
		return

	Stun(baton_stun_amount)
	COOLDOWN_START(src, baton_stun_cd, baton_stun_cooldown)

/mob/living/basic/khara_mutant/melee_attack(atom/target, list/modifiers, ignore_cooldown)
	if(is_khara_creature(target))
		to_chat(src, span_warning("You cannot attack your own kind!"))
		return ATTACK_FAILED
	. = ..()

/mob/living/basic/khara_mutant/say(message, bubble_type, list/spans, sanitize, datum/language/language, ignore_spam, forced, filterproof, message_range, datum/saymode/saymode, list/message_mods)
	if(hivemind_link && client)
		var/datum/action/cooldown/khara_hivemind_talk/hivemind = hivemind_link.action
		hivemind.talk_to_hivemind(message)
	return

/mob/living/basic/khara_mutant/proc/spread_miasma()
	do_chem_smoke(spread_miasma_amount / 2, src, get_turf(src), /datum/reagent/toxin/khara, 10, log = FALSE, amount = spread_miasma_amount, smoke_type = /datum/effect_system/fluid_spread/smoke/chem/khara)

/mob/living/basic/khara_mutant/death(gibbed)
	if(gib_on_death)
		inflate_gib()
	. = ..()

/mob/living/basic/khara_mutant/gib()
	for(var/turf/blood_turf in circle_range(src, spread_blood_radius))
		new /obj/effect/decal/cleanable/blood(blood_turf)
		for(var/mob/living/mob_in_turf in blood_turf)
			mob_in_turf.visible_message(span_danger("[mob_in_turf] is splattered with blood!"), span_userdanger("You are splattered with blood!"))
			mob_in_turf.add_blood_DNA(list("Non-human DNA" = random_human_blood_type()), list(/datum/disease/khara))
			playsound(mob_in_turf, 'sound/effects/splat.ogg', 50, TRUE, extrarange = SILENCED_SOUND_EXTRARANGE)
	return ..()

/mob/living/basic/khara_mutant/proc/get_footstep_sounds()
	PRIVATE_PROC(TRUE)
	return footstep_sounds
